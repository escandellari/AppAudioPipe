import Testing
@testable import AppAudioPipe

@Suite("CaptureCommand")
struct CaptureCommandTests {
    @Test func noArgumentsParseToDiagnostics() {
        #expect(CaptureCommand.parse([]) == .diagnostics)
    }

    @Test func captureSourcePreservesQuery() {
        #expect(CaptureCommand.parse(["--capture-source", "Pocket Bard"]) == .captureSource("Pocket Bard"))
    }

    @Test func missingCaptureSourceReturnsUsageError() {
        if case .invalid(let message) = CaptureCommand.parse(["--capture-source"]) {
            #expect(message.contains("Usage:"))
        } else {
            Issue.record("Expected invalid command")
        }
    }

    @Test func invalidArgumentsReturnUsageError() {
        if case .invalid(let message) = CaptureCommand.parse(["--unknown"]) {
            #expect(message.contains("Invalid arguments"))
            #expect(message.contains("--capture-source"))
        } else {
            Issue.record("Expected invalid command")
        }
    }
}
