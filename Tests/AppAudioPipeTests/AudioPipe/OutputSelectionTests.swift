import Testing
@testable import AppAudioPipe

@Suite("OutputSelection")
struct OutputSelectionTests {
    @Test func exactOutputDeviceNamesResolve() throws {
        let device = try OutputSelection().select(query: "VB-Cable", from: devices()).get()
        #expect(device.name == "VB-Cable")
    }

    @Test func caseInsensitiveOutputDeviceNamesResolve() throws {
        let device = try OutputSelection().select(query: "vb-cable", from: devices()).get()
        #expect(device.name == "VB-Cable")
    }

    @Test func inputOnlyDevicesAreNotSelected() {
        if case .failure(let error) = OutputSelection().select(query: "Mic", from: devices()) {
            #expect(error.description.contains("not output-capable"))
        } else { Issue.record("Expected input-only failure") }
    }

    @Test func missingOutputRendersClearError() {
        if case .failure(let error) = OutputSelection().select(query: "Missing", from: devices()) {
            #expect(error.description.contains("Missing"))
            #expect(error.description.contains("swift run AppAudioPipe"))
            #expect(error.description.contains("output devices"))
        } else { Issue.record("Expected missing failure") }
    }

    private func devices() -> [AudioDevice] {
        [AudioDevice(id: 1, name: "Mic", hasOutput: false), AudioDevice(id: 2, name: "VB-Cable", hasOutput: true)]
    }
}
