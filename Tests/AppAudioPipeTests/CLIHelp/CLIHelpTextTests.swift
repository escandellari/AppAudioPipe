import Testing
@testable import AppAudioPipe

@Suite("CLI help text")
struct CLIHelpTextTests {
    @Test func helpIncludesListCaptureAndPipeUsage() {
        let help = CLIHelpText.render()

        #expect(help.contains("swift run AppAudioPipe"))
        #expect(help.contains("List output devices"))
        #expect(help.contains("--capture-source \"Pocket Bard\""))
        #expect(help.contains("--capture-source \"Pocket Bard\" --output \"VB-Cable\""))
    }

    @Test func helpIncludesSelectionGuidance() {
        let help = CLIHelpText.render()

        #expect(help.contains("exact visible app/window name or process ID"))
        #expect(help.contains("exact output device name"))
    }

    @Test func helpIncludesPermissionTroubleshooting() {
        let help = CLIHelpText.render()

        #expect(help.contains("Screen & System Audio Recording"))
        #expect(help.contains("Terminal/AppAudioPipe"))
        #expect(help.contains("rerun"))
    }

    @Test func helpIncludesWorkflowAndLimitations() {
        let help = CLIHelpText.render()

        #expect(help.contains("Kenku FM"))
        #expect(help.contains("Discord"))
        #expect(help.contains("real microphone/headphones"))
        #expect(help.contains("Audio is copied"))
        #expect(help.contains("does not guarantee local mute"))
    }

    @Test func parserMapsHelpFlagsToHelp() {
        #expect(CaptureCommand.parse(["--help"]) == .help)
        #expect(CaptureCommand.parse(["-h"]) == .help)
    }
}
