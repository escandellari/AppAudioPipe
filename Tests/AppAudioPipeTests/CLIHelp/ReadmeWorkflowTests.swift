import Foundation
import Testing

@Suite("README workflow")
struct ReadmeWorkflowTests {
    @Test func readmeDocumentsPocketBardWorkflow() throws {
        let readme = try readmeText()

        #expect(readme.contains("## Pocket Bard → VB-Cable → Kenku FM workflow"))
        #expect(readme.contains("swift run AppAudioPipe"))
        #expect(readme.contains("swift run AppAudioPipe --capture-source \"Pocket Bard\""))
        #expect(readme.contains("swift run AppAudioPipe --capture-source \"Pocket Bard\" --output \"VB-Cable\""))
    }

    @Test func readmeDocumentsKenkuAndDiscordGuidance() throws {
        let readme = try readmeText()

        #expect(readme.contains("Kenku FM"))
        #expect(readme.contains("VB-Cable as the audio input"))
        #expect(readme.contains("real microphone"))
        #expect(readme.contains("real headphones"))
    }

    @Test func readmeDocumentsCopiedAudioLimitation() throws {
        let readme = try readmeText()

        #expect(readme.contains("Audio is copied to the selected output"))
        #expect(readme.contains("does not guarantee muting Pocket Bard locally"))
    }

    private func readmeText() throws -> String {
        let readmeURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("README.md")
        return try String(contentsOf: readmeURL, encoding: .utf8)
    }
}
