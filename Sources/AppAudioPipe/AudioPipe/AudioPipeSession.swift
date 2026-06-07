import CoreMedia
import Foundation
import ScreenCaptureKit

public enum AudioPipeError: Error, LocalizedError, Sendable, Equatable {
    case unsupportedFormat(String)
    case outputStartFailed(String)
    case noSamples(String)

    public var errorDescription: String? {
        switch self {
        case .unsupportedFormat(let message), .outputStartFailed(let message), .noSamples(let message): message
        }
    }
}

public struct AudioPipeSession: Sendable {
    private let observationSeconds: UInt64

    public init(observationSeconds: UInt64 = 12) {
        self.observationSeconds = observationSeconds
    }

    public func run(captureSource query: String, output outputQuery: String) async -> [String] {
        do {
            let outputDevice = try OutputSelection().select(query: outputQuery, from: audioDevices()).get()
            let catalog = try await ScreenCaptureKitCaptureCatalog.load()
            let source = try SourceSelection().select(query: query, from: catalog.sources).get()
            let filter = try catalog.filter(for: source)
            let sourceLabel = renderSourceLabel(source)
            let observer = AudioPipeObserver(sourceLabel: sourceLabel, outputDevice: outputDevice)
            let writer = AVAudioEngineOutputWriter()
            let streamOutput = ScreenCaptureKitPipeOutput(observer: observer, writer: writer)
            let stream = SCStream(filter: filter, configuration: AudioCaptureSession.configuration(), delegate: streamOutput)

            try stream.addStreamOutput(streamOutput, type: .audio, sampleHandlerQueue: DispatchQueue(label: "AppAudioPipe.pipe-samples"))
            try await stream.startCapture()
            await observer.record("Starting audio pipe from \(sourceLabel) to output '\(outputDevice.name)' [\(outputDevice.id)]")
            try await Task.sleep(nanoseconds: observationSeconds * 1_000_000_000)
            try? await stream.stopCapture()
            writer.stop()
            return await observer.finish()
        } catch {
            return [renderPipeError(error)]
        }
    }

    private func renderSourceLabel(_ source: CaptureSource) -> String {
        switch source.kind {
        case .application: "app '\(source.name)' pid=\(source.processID ?? Int32(source.id))"
        case .window: "window '\(source.name)' id=\(source.id)"
        }
    }
}

private actor AudioPipeObserver {
    private var lines: [String] = []
    private var receivedSamples = false
    private var writerStarted = false
    private var terminalError: String?
    private var lastPrint = ContinuousClock.now
    private let sourceLabel: String
    private let outputDevice: AudioDevice

    init(sourceLabel: String, outputDevice: AudioDevice) {
        self.sourceLabel = sourceLabel
        self.outputDevice = outputDevice
    }

    func record(_ line: String) { lines.append(line) }

    func recordSample(_ buffer: CapturedAudioBuffer, writer: AVAudioEngineOutputWriter) {
        guard terminalError == nil else { return }
        receivedSamples = true
        do {
            if !writerStarted {
                switch AudioFormatCompatibility().validate(buffer.format) {
                case .success: break
                case .failure(let error): throw AudioPipeError.unsupportedFormat("Unsupported captured format for output '\(outputDevice.name)' [\(outputDevice.id)]: \(error.description)")
                }
                try writer.startWithTimeout(device: outputDevice, format: buffer.format)
                writerStarted = true
            }
            let written = writer.enqueue(buffer)
            let now = ContinuousClock.now
            guard now - lastPrint >= .milliseconds(500) else { return }
            lastPrint = now
            let level = AudioLevel.calculate(buffer.samples)
            lines.append("pipe audio rms=\(String(format: "%.4f", level.rms)) peak=\(String(format: "%.4f", level.peak)) written=\(written)")
        } catch {
            terminalError = renderPipeError(error)
            lines.append(terminalError!)
        }
    }

    func recordStop(error: Error) { lines.append(renderPipeError(mapScreenCaptureKitError(error))) }

    func finish() -> [String] {
        if !receivedSamples {
            lines.append("No audio sample buffers arrived for \(sourceLabel). Play audio in the selected source, check Screen & System Audio Recording permission, or choose another visible source.")
        }
        return lines
    }
}

private final class ScreenCaptureKitPipeOutput: NSObject, SCStreamOutput, SCStreamDelegate, @unchecked Sendable {
    private let observer: AudioPipeObserver
    private let writer: AVAudioEngineOutputWriter

    init(observer: AudioPipeObserver, writer: AVAudioEngineOutputWriter) {
        self.observer = observer
        self.writer = writer
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .audio else { return }
        do {
            let buffer = try capturedAudioBuffer(from: sampleBuffer)
            Task { await observer.recordSample(buffer, writer: writer) }
        } catch {
            Task { await observer.record(renderPipeError(error)) }
        }
    }

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        Task { await observer.recordStop(error: error) }
    }
}

private func renderPipeError(_ error: Error) -> String {
    if let error = error as? OutputSelectionError { return error.description }
    if let error = error as? SourceSelectionError { return error.description }
    if let localized = error as? LocalizedError, let description = localized.errorDescription { return description }
    return "Audio pipe failed: \(String(describing: error))"
}
