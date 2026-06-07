import AVFoundation
import AudioToolbox
import CoreAudio
import Foundation

public final class AVAudioEngineOutputWriter: @unchecked Sendable {
    private let engine = AVAudioEngine()
    private let queue = DispatchQueue(label: "AppAudioPipe.output-fifo")
    private var fifo: [Float] = []
    private let maxSamples = 48_000 * 2
    private var format: AVAudioFormat?

    public init() {}

    public func start(device: AudioDevice, format pcmFormat: CapturedPCMFormat) throws {
        guard case .success = AudioFormatCompatibility().validate(pcmFormat) else {
            throw AudioPipeError.unsupportedFormat("Unsupported format for output '\(device.name)' [\(device.id)]: \(AudioFormatCompatibilityError.unsupportedChannelCount(pcmFormat.channelCount).description)")
        }
        guard let avFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: pcmFormat.sampleRate, channels: AVAudioChannelCount(pcmFormat.channelCount), interleaved: false) else {
            throw AudioPipeError.unsupportedFormat("Could not create AVAudioFormat for \(pcmFormat.channelCount)-channel PCM at \(pcmFormat.sampleRate) Hz.")
        }
        self.format = avFormat

        let source = AVAudioSourceNode(format: avFormat) { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            self?.render(frameCount: Int(frameCount), audioBufferList: audioBufferList)
            return noErr
        }
        engine.attach(source)
        engine.connect(source, to: engine.mainMixerNode, format: avFormat)
        try setOutputDevice(device.id)
        do { try engine.start() } catch {
            throw AudioPipeError.outputStartFailed("Could not start output device '\(device.name)' [\(device.id)]: \(error.localizedDescription)")
        }
    }

    public func startWithTimeout(device: AudioDevice, format pcmFormat: CapturedPCMFormat, timeout: TimeInterval = 3) throws {
        let semaphore = DispatchSemaphore(value: 0)
        let resultBox = OutputStartResultBox()
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            resultBox.store(Result { try self.start(device: device, format: pcmFormat) })
            semaphore.signal()
        }
        guard semaphore.wait(timeout: .now() + timeout) == .success else {
            throw AudioPipeError.outputStartFailed("Could not start output device '\(device.name)' [\(device.id)]: timed out while starting audio output.")
        }
        try resultBox.load()?.get()
    }

    public func enqueue(_ buffer: CapturedAudioBuffer) -> Int {
        queue.sync {
            if fifo.count + buffer.samples.count > maxSamples {
                fifo.removeFirst(min(fifo.count, fifo.count + buffer.samples.count - maxSamples))
            }
            fifo.append(contentsOf: buffer.samples)
            return buffer.frameCount
        }
    }

    public func stop() {
        engine.stop()
        engine.reset()
    }

    private func render(frameCount: Int, audioBufferList: UnsafeMutablePointer<AudioBufferList>) {
        let channelCount = Int(format?.channelCount ?? 2)
        let needed = frameCount * channelCount
        let samples = queue.sync { () -> [Float] in
            let count = min(needed, fifo.count)
            let output = Array(fifo.prefix(count))
            fifo.removeFirst(count)
            return output + Array(repeating: 0, count: needed - count)
        }
        let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
        for channel in 0..<buffers.count {
            let audioBuffer = buffers[channel]
            guard let data = audioBuffer.mData else { continue }
            let out = data.bindMemory(to: Float.self, capacity: frameCount)
            for frame in 0..<frameCount { out[frame] = samples[frame * channelCount + channel] }
        }
    }

    private func setOutputDevice(_ deviceID: AudioDeviceID) throws {
        let outputUnit = engine.outputNode.audioUnit!
        var mutableDeviceID = deviceID
        let status = AudioUnitSetProperty(outputUnit, kAudioOutputUnitProperty_CurrentDevice, kAudioUnitScope_Global, 0, &mutableDeviceID, UInt32(MemoryLayout<AudioDeviceID>.size))
        guard status == noErr else { throw AudioPipeError.outputStartFailed("Could not select output device [\(deviceID)] (OSStatus \(status)).") }
    }
}

private final class OutputStartResultBox: @unchecked Sendable {
    private let lock = NSLock()
    private var result: Result<Void, Error>?

    func store(_ result: Result<Void, Error>) {
        lock.lock()
        self.result = result
        lock.unlock()
    }

    func load() -> Result<Void, Error>? {
        lock.lock()
        let result = self.result
        lock.unlock()
        return result
    }
}
