import Foundation

@main
struct AppAudioPipe {
    static func main() async {
        switch CaptureCommand.parse(CommandLine.arguments.dropFirst()) {
        case .diagnostics:
            await runDiagnostics()
        case .help:
            print(CLIHelpText.render())
        case .captureSource(let query):
            let lines = await AudioCaptureSession().run(captureSource: query)
            print(lines.joined(separator: "\n"))
        case .pipe(let query, let output):
            let lines = await AudioPipeSession().run(captureSource: query, output: output)
            print(lines.joined(separator: "\n"))
        case .invalid(let message):
            print(message)
        }
    }

    private static func runDiagnostics() async {
        print(DiagnosticText.banner)
        print("\n" + AudioDeviceListing(devices: audioDevices()).renderOutputDevicesSection())

        let captureSourceState = await ScreenCaptureKitSourceProvider().listingState()
        print("\n" + CaptureSourceListing(state: captureSourceState).renderSection())
    }
}
