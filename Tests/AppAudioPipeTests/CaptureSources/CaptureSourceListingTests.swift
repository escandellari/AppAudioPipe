import Testing
@testable import AppAudioPipe

@Suite("CaptureSourceListing")
struct CaptureSourceListingTests {
    @Test func rendersApplicationAndWindowRows() {
        let listing = CaptureSourceListing(state: .sources([
            .init(kind: .application, id: 42, name: "Pocket Bard", processID: 42, bundleIdentifier: "com.example.PocketBard"),
            .init(kind: .window, id: 99, name: "Mixer", owningApplicationName: "Pocket Bard", processID: 42),
        ]))

        let text = listing.renderSection()

        #expect(text.contains("Capturable apps/windows visible to ScreenCaptureKit:"))
        #expect(text.contains("- app pid=42 Pocket Bard bundle=com.example.PocketBard"))
        #expect(text.contains("- window id=99 Mixer app=Pocket Bard pid=42"))
    }

    @Test func keepsPocketBardLikeSourcesVisible() {
        let listing = CaptureSourceListing(state: .sources([
            .init(kind: .application, id: 7, name: "Pocket Bard", processID: 7, bundleIdentifier: "com.pocketbard.app"),
            .init(kind: .window, id: 8, name: "Pocket Bard Audio", owningApplicationName: "Pocket Bard", processID: 7),
        ]))

        let text = listing.renderSection()

        #expect(text.contains("Pocket Bard"))
        #expect(text.contains("Pocket Bard Audio"))
    }

    @Test func emptySuitableSourcesExplainNoVisibleSources() {
        let listing = CaptureSourceListing(state: .sources([
            .init(kind: .application, id: 1, name: "   ", processID: 1),
            .init(kind: .window, id: 2, name: "", owningApplicationName: "Hidden", processID: 1),
        ]))

        let text = listing.renderSection()

        #expect(text.contains("No capturable apps/windows are currently visible to ScreenCaptureKit."))
        #expect(text.contains("Open the target app or window, then rerun this command."))
        #expect(!text.contains("- app"))
        #expect(!text.contains("- window"))
    }

    @Test func permissionDeniedRendersActionableGuidance() {
        let listing = CaptureSourceListing(state: .permissionDenied)

        let text = listing.renderSection()

        #expect(text.contains("ScreenCaptureKit enumeration was denied by macOS."))
        #expect(text.contains("System Settings → Privacy & Security → Screen & System Audio Recording"))
        #expect(text.contains("Terminal or AppAudioPipe"))
        #expect(text.contains("rerun this command"))
    }

    @Test func ordersApplicationsBeforeWindowsThenByNameAndID() {
        let listing = CaptureSourceListing(state: .sources([
            .init(kind: .window, id: 3, name: "Alpha Window"),
            .init(kind: .application, id: 20, name: "beta"),
            .init(kind: .application, id: 10, name: "Alpha"),
            .init(kind: .application, id: 5, name: "alpha"),
            .init(kind: .window, id: 2, name: "Zed Window"),
        ]))

        #expect(listing.visibleSources.map(\.id) == [5, 10, 20, 3, 2])
    }
}
