import Foundation
import ScreenCaptureKit


@main
struct AppAudioPipe {
    static func main() async {
        print(DiagnosticText.banner)
        print("\n" + AudioDeviceListing(devices: audioDevices()).renderOutputDevicesSection())

        print("\nShareable apps/windows visible to ScreenCaptureKit:")
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
            let apps = content.applications.sorted { $0.applicationName < $1.applicationName }
            for app in apps {
                print("- pid=\(app.processID) \(app.applicationName) bundle=\(app.bundleIdentifier)")
            }
        } catch {
            print("ScreenCaptureKit enumeration failed: \(error)")
            print("Grant Screen & System Audio Recording permission if macOS asks for it.")
        }
    }
}
