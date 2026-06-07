import Testing
@testable import AppAudioPipe

@Suite("Audio pipe command")
struct AudioPipeCommandTests {
    @Test func noArgumentsStillParseToDiagnostics() {
        #expect(CaptureCommand.parse([]) == .diagnostics)
    }

    @Test func captureSourceAndOutputParseToPipe() {
        #expect(CaptureCommand.parse(["--capture-source", "Pocket Bard", "--output", "VB-Cable"]) == .pipe(captureSource: "Pocket Bard", output: "VB-Cable"))
    }

    @Test func missingOutputArgumentReturnsUsageError() {
        if case .invalid(let message) = CaptureCommand.parse(["--capture-source", "Pocket Bard", "--output"]) {
            #expect(message.contains("Usage:"))
            #expect(message.contains("--output"))
        } else { Issue.record("Expected invalid command") }
    }

    @Test func existingCaptureOnlyFlowRemainsSupported() {
        #expect(CaptureCommand.parse(["--capture-source", "Pocket Bard"]) == .captureSource("Pocket Bard"))
    }
}
