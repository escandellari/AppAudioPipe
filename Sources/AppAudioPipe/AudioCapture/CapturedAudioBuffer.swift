import AVFoundation
import CoreMedia
import Foundation

public struct CapturedAudioBuffer: Sendable, Equatable {
    public let samples: [Float]
    public let format: CapturedPCMFormat
    public let frameCount: Int

    public init(samples: [Float], format: CapturedPCMFormat, frameCount: Int) {
        self.samples = samples
        self.format = format
        self.frameCount = frameCount
    }
}

public enum CapturedAudioBufferConversionError: Error, LocalizedError, Sendable, Equatable {
    case unsupportedAudioFormat(String)

    public var errorDescription: String? {
        switch self {
        case .unsupportedAudioFormat(let message): message
        }
    }
}

public func capturedAudioBuffer(from sampleBuffer: CMSampleBuffer) throws -> CapturedAudioBuffer {
    guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer),
          let streamDescriptionPointer = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)
    else { throw CapturedAudioBufferConversionError.unsupportedAudioFormat("Missing audio format description.") }

    let streamDescription = streamDescriptionPointer.pointee
    let formatID = streamDescription.mFormatID
    let flags = streamDescription.mFormatFlags
    let bytesPerFrame = Int(streamDescription.mBytesPerFrame)
    let bitsPerChannel = Int(streamDescription.mBitsPerChannel)
    let channels = Int(streamDescription.mChannelsPerFrame)
    let frameCount = CMSampleBufferGetNumSamples(sampleBuffer)
    guard formatID == kAudioFormatLinearPCM, bytesPerFrame > 0, frameCount > 0 else {
        throw CapturedAudioBufferConversionError.unsupportedAudioFormat("Only linear PCM audio sample buffers are supported.")
    }

    var blockBuffer: CMBlockBuffer?
    var neededSize = 0
    let bufferCount = max(1, channels)
    let audioBufferList = AudioBufferList.allocate(maximumBuffers: bufferCount)
    defer { audioBufferList.unsafeMutablePointer.deallocate() }

    let status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, bufferListSizeNeededOut: &neededSize, bufferListOut: audioBufferList.unsafeMutablePointer, bufferListSize: AudioBufferList.sizeInBytes(maximumBuffers: bufferCount), blockBufferAllocator: kCFAllocatorDefault, blockBufferMemoryAllocator: kCFAllocatorDefault, flags: 0, blockBufferOut: &blockBuffer)
    guard status == noErr else { throw CapturedAudioBufferConversionError.unsupportedAudioFormat("Could not access audio buffer list (OSStatus \(status)).") }

    if flags & kAudioFormatFlagIsFloat != 0, bitsPerChannel == 32 {
        return CapturedAudioBuffer(samples: floatSamples(from: audioBufferList), format: CapturedPCMFormat(sampleRate: streamDescription.mSampleRate, channelCount: channels, sampleType: .float32), frameCount: frameCount)
    }

    if flags & kAudioFormatFlagIsSignedInteger != 0, bitsPerChannel == 16 {
        return CapturedAudioBuffer(samples: int16Samples(from: audioBufferList), format: CapturedPCMFormat(sampleRate: streamDescription.mSampleRate, channelCount: channels, sampleType: .int16), frameCount: frameCount)
    }

    throw CapturedAudioBufferConversionError.unsupportedAudioFormat("Unsupported PCM layout: bitsPerChannel=\(bitsPerChannel), flags=\(flags).")
}

public func normalizedSamples(from sampleBuffer: CMSampleBuffer) throws -> [Float] {
    try capturedAudioBuffer(from: sampleBuffer).samples
}

private func floatSamples(from audioBufferList: UnsafeMutableAudioBufferListPointer) -> [Float] {
    audioBufferList.flatMap { audioBuffer -> [Float] in
        guard let data = audioBuffer.mData else { return [] }
        let sampleCount = Int(audioBuffer.mDataByteSize) / MemoryLayout<Float>.size
        let samples = data.bindMemory(to: Float.self, capacity: sampleCount)
        return (0..<sampleCount).map { samples[$0] }
    }
}

private func int16Samples(from audioBufferList: UnsafeMutableAudioBufferListPointer) -> [Float] {
    audioBufferList.flatMap { audioBuffer -> [Float] in
        guard let data = audioBuffer.mData else { return [] }
        let sampleCount = Int(audioBuffer.mDataByteSize) / MemoryLayout<Int16>.size
        let samples = data.bindMemory(to: Int16.self, capacity: sampleCount)
        return (0..<sampleCount).map { Float(samples[$0]) / Float(Int16.max) }
    }
}
