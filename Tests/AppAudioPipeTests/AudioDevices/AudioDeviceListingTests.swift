import Testing
@testable import AppAudioPipe

@Suite("AudioDeviceListing")
struct AudioDeviceListingTests {
    @Test func includesOutputDevicesAndExcludesInputOnlyDevices() {
        let listing = AudioDeviceListing(devices: [
            .init(id: 30, name: "Studio Mic", hasOutput: false),
            .init(id: 20, name: "Headphones", hasOutput: true),
            .init(id: 10, name: "MacBook Pro Speakers", hasOutput: true),
        ])

        let text = listing.renderOutputDevicesSection()

        #expect(text.contains("Output devices:"))
        #expect(text.contains("- [20] Headphones"))
        #expect(text.contains("- [10] MacBook Pro Speakers"))
        #expect(!text.contains("Studio Mic"))
    }

    @Test func hintsKnownVirtualDevicesWithoutHidingOrdinaryOutputs() {
        let listing = AudioDeviceListing(devices: [
            .init(id: 1, name: "VB-Cable", hasOutput: true),
            .init(id: 2, name: "VB Cable", hasOutput: true),
            .init(id: 3, name: "BlackHole 2ch", hasOutput: true),
            .init(id: 4, name: "MacBook Pro Speakers", hasOutput: true),
        ])

        let text = listing.renderOutputDevicesSection()

        #expect(text.contains("- [1] VB-Cable (virtual audio device)"))
        #expect(text.contains("- [2] VB Cable (virtual audio device)"))
        #expect(text.contains("- [3] BlackHole 2ch (virtual audio device)"))
        #expect(text.contains("- [4] MacBook Pro Speakers"))
    }

    @Test func rendersDeterministicOrderingByNameThenID() {
        let listing = AudioDeviceListing(devices: [
            .init(id: 30, name: "z Speaker", hasOutput: true),
            .init(id: 20, name: "Alpha Speaker", hasOutput: true),
            .init(id: 10, name: "alpha speaker", hasOutput: true),
        ])

        #expect(listing.outputDevices.map(\.id) == [10, 20, 30])
    }

    @Test func emptyOutputListExplainsRoutingCannotStart() {
        let listing = AudioDeviceListing(devices: [
            .init(id: 30, name: "Studio Mic", hasOutput: false),
        ])

        let text = listing.renderOutputDevicesSection()

        #expect(text.contains("Output devices:"))
        #expect(text.contains("No output-capable CoreAudio devices found."))
        #expect(text.contains("Audio routing cannot start until macOS reports an output-capable device."))
    }
}
