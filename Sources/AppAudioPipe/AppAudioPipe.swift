import Foundation

@main
struct AppAudioPipe {
    static func main() async {
        print(DiagnosticText.banner)
        print("\n" + AudioDeviceListing(devices: audioDevices()).renderOutputDevicesSection())

        let captureSourceState = await ScreenCaptureKitSourceProvider().listingState()
        print("\n" + CaptureSourceListing(state: captureSourceState).renderSection())
    }
}
