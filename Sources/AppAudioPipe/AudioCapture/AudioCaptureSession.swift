import AVFoundation
import CoreMedia
import Foundation
import ScreenCaptureKit

public struct AudioCaptureSession: Sendable {
    private let observationSeconds: UInt64

    public init(observationSeconds: UInt64 = 12) {
        self.observationSeconds = observationSeconds
    }

    public func run(captureSource query: String) async -> [String] {
        do {
            let catalog = try await ScreenCaptureKitCaptureCatalog.load()
            let source = try SourceSelection().select(query: query, from: catalog.sources).get()
            let filter = try catalog.filter(for: source)
            let sourceLabel = renderSourceLabel(source)

            let observer = AudioSampleObserver(sourceLabel: sourceLabel)
            let output = ScreenCaptureKitAudioOutput(observer: observer)
            let stream = SCStream(filter: filter, configuration: Self.configuration(), delegate: output)

            try stream.addStreamOutput(output, type: .audio, sampleHandlerQueue: DispatchQueue(label: "AppAudioPipe.audio-samples"))
            try await stream.startCapture()
            await observer.record("Starting audio capture for \(sourceLabel)")
            try await Task.sleep(nanoseconds: observationSeconds * 1_000_000_000)
            try? await stream.stopCapture()

            return await observer.finish()
        } catch {
            return [renderCaptureError(error)]
        }
    }

    static func configuration() -> SCStreamConfiguration {
        let configuration = SCStreamConfiguration()
        configuration.capturesAudio = true
        configuration.sampleRate = 48_000
        configuration.channelCount = 2
        configuration.excludesCurrentProcessAudio = true
        configuration.width = 2
        configuration.height = 2
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: 1)
        return configuration
    }

    private func renderSourceLabel(_ source: CaptureSource) -> String {
        switch source.kind {
        case .application:
            return "app '\(source.name)' pid=\(source.processID ?? Int32(source.id))"
        case .window:
            return "window '\(source.name)' id=\(source.id)"
        }
    }
}

struct ScreenCaptureKitCaptureCatalog: @unchecked Sendable {
    let sources: [CaptureSource]
    private let applicationsByPID: [Int32: SCRunningApplication]
    private let windowsByID: [UInt32: SCWindow]
    private let display: SCDisplay?

    static func load() async throws -> ScreenCaptureKitCaptureCatalog {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
            let appPairs = content.applications.map { app in
                (app.processID, app)
            }
            let windowPairs = content.windows.map { window in
                (window.windowID, window)
            }
            let sources = content.applications.map(mapApplication) + content.windows.map(mapWindow)
            return ScreenCaptureKitCaptureCatalog(
                sources: sources,
                applicationsByPID: Dictionary(uniqueKeysWithValues: appPairs),
                windowsByID: Dictionary(uniqueKeysWithValues: windowPairs),
                display: content.displays.first
            )
        } catch {
            throw mapScreenCaptureKitError(error)
        }
    }

    func filter(for source: CaptureSource) throws -> SCContentFilter {
        switch source.kind {
        case .window:
            guard let window = windowsByID[source.id] else { throw CaptureSessionError.missingRawSource(source.name) }
            return SCContentFilter(desktopIndependentWindow: window)
        case .application:
            guard let processID = source.processID, let application = applicationsByPID[processID] else {
                throw CaptureSessionError.missingRawSource(source.name)
            }
            guard let display else { throw CaptureSessionError.noDisplayAvailable }
            return SCContentFilter(display: display, including: [application], exceptingWindows: [])
        }
    }

    private static func mapApplication(_ application: SCRunningApplication) -> CaptureSource {
        CaptureSource(kind: .application, id: UInt32(application.processID), name: application.applicationName, processID: application.processID, bundleIdentifier: application.bundleIdentifier)
    }

    private static func mapWindow(_ window: SCWindow) -> CaptureSource {
        CaptureSource(kind: .window, id: window.windowID, name: window.title ?? "", owningApplicationName: window.owningApplication?.applicationName, processID: window.owningApplication?.processID, bundleIdentifier: window.owningApplication?.bundleIdentifier)
    }
}

private actor AudioSampleObserver {
    private var lines: [String] = []
    private var receivedSamples = false
    private var lastPrint = ContinuousClock.now
    private let sourceLabel: String

    init(sourceLabel: String) { self.sourceLabel = sourceLabel }

    func record(_ line: String) { lines.append(line) }

    func recordSample(levelLine: String?) {
        receivedSamples = true
        guard let levelLine else { return }
        let now = ContinuousClock.now
        guard now - lastPrint >= .milliseconds(500) else { return }
        lastPrint = now
        lines.append(levelLine)
    }

    func recordStop(error: Error) {
        lines.append(renderCaptureError(error))
    }

    func finish() -> [String] {
        if !receivedSamples {
            lines.append("No audio sample buffers arrived for \(sourceLabel). Play audio in the selected source, check Screen & System Audio Recording permission, or choose another visible source.")
        }
        return lines
    }
}

private final class ScreenCaptureKitAudioOutput: NSObject, SCStreamOutput, SCStreamDelegate, @unchecked Sendable {
    private let observer: AudioSampleObserver

    init(observer: AudioSampleObserver) {
        self.observer = observer
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .audio else { return }
        let line: String?
        do {
            line = try AudioLevel.calculate(normalizedSamples(from: sampleBuffer)).render()
        } catch {
            line = "Unsupported audio sample format: \(error.localizedDescription)"
        }
        Task { await observer.recordSample(levelLine: line) }
    }

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        Task { await observer.recordStop(error: mapScreenCaptureKitError(error)) }
    }
}

private enum CaptureSessionError: Error, LocalizedError {
    case permissionDenied
    case missingRawSource(String)
    case noDisplayAvailable
    case unsupportedAudioFormat(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "ScreenCaptureKit capture was denied by macOS. Enable Screen & System Audio Recording for Terminal or AppAudioPipe in System Settings → Privacy & Security → Screen & System Audio Recording, then rerun this command."
        case .missingRawSource(let name):
            return "The selected source '\(name)' disappeared before capture could start. Run `swift run AppAudioPipe` to list visible sources, then retry."
        case .noDisplayAvailable:
            return "ScreenCaptureKit returned no displays, so application audio capture cannot start."
        case .unsupportedAudioFormat(let message):
            return message
        }
    }
}

private func renderCaptureError(_ error: Error) -> String {
    if case let selectionError as SourceSelectionError = error { return selectionError.description }
    if let localized = error as? LocalizedError, let description = localized.errorDescription { return description }
    return "Audio capture failed: \(String(describing: error))"
}

func mapScreenCaptureKitError(_ error: Error) -> Error {
    let nsError = error as NSError
    if nsError.domain == SCStreamErrorDomain && nsError.code == -3801 {
        return CaptureSessionError.permissionDenied
    }
    return error
}
