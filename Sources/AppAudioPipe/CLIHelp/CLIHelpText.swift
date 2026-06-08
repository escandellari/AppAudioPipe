public enum CLIHelpText {
    public static func render() -> String {
        """
        AppAudioPipe

        Usage:
          swift run AppAudioPipe
              List output devices, then capturable apps and windows.
          swift run AppAudioPipe --capture-source "Pocket Bard"
              Capture a source and print audio-level proof.
          swift run AppAudioPipe --capture-source "Pocket Bard" --output "VB-Cable"
              Copy captured source audio to the selected output device.
          swift run AppAudioPipe --help
              Show this help.

        Source selection:
          Use the exact visible app/window name or process ID from `swift run AppAudioPipe`.

        Output selection:
          Use the exact output device name from `swift run AppAudioPipe`.

        macOS permissions:
          If sources are missing or ScreenCaptureKit access fails, grant Screen & System Audio Recording permission to Terminal/AppAudioPipe in System Settings, then rerun the command.

        Pocket Bard → VB-Cable → Kenku FM:
          Pipe Pocket Bard to VB-Cable, configure Kenku FM to receive VB-Cable, and keep Discord voice input/output on your real microphone/headphones.

        Current limitations:
          Audio is copied to the selected output; this does not guarantee local mute or exclusive per-app redirection.
        """
    }
}
