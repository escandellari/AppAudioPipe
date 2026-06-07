import Foundation
import Testing
@testable import AppAudioPipe

@Suite("DiagnosticText")
struct DiagnosticTextTests {
    @Test func bannerIsStableAndUserReadable() {
        #expect(DiagnosticText.banner == "AppAudioPipe diagnostic prototype")
        #expect(DiagnosticText.banner.contains("AppAudioPipe"))
        #expect(DiagnosticText.banner.contains("diagnostic"))
    }
}

@Suite("README smoke")
struct ReadmeSmokeTests {
    @Test func readmeDocumentsPrototypeUsageAndLimitations() throws {
        let readmeURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("README.md")
        let readme = try String(contentsOf: readmeURL, encoding: .utf8)

        #expect(readme.contains("swift build"))
        #expect(readme.contains("swift run AppAudioPipe"))
        #expect(readme.contains("swift test"))
        #expect(readme.contains("macOS"))
        #expect(readme.contains("Screen & System Audio Recording"))
        #expect(readme.contains("no routing/capture pipeline yet"))
        #expect(readme.contains("PRD.md"))
        #expect(readme.contains("TECHNICAL_SPIKE.md"))
    }
}
