import Testing
@testable import AppAudioPipe

@Suite("SourceSelection")
struct SourceSelectionTests {
    @Test func exactApplicationAndWindowNamesResolve() throws {
        let sources: [CaptureSource] = [
            .init(kind: .application, id: 42, name: "Pocket Bard", processID: 42),
            .init(kind: .window, id: 9, name: "Mixer", owningApplicationName: "Pocket Bard", processID: 42),
        ]

        let app = try SourceSelection().select(query: "Pocket Bard", from: sources).get()
        let window = try SourceSelection().select(query: "Mixer", from: sources).get()

        #expect(app.kind == .application)
        #expect(window.kind == .window)
    }

    @Test func processIDResolves() throws {
        let source = try SourceSelection().select(query: "123", from: [
            .init(kind: .application, id: 123, name: "Pocket Bard", processID: 123),
        ]).get()

        #expect(source.name == "Pocket Bard")
    }

    @Test func missingSourceReturnsClearError() {
        let result = SourceSelection().select(query: "Missing", from: [])

        if case .failure(let error) = result {
            #expect(error.description.contains("Missing"))
            #expect(error.description.contains("list visible sources"))
        } else {
            Issue.record("Expected missing-source failure")
        }
    }
}
