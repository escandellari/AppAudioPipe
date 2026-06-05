import CoreAudio
import Foundation
import ScreenCaptureKit

struct AudioDevice: Sendable {
    let id: AudioDeviceID
    let name: String
    let hasOutput: Bool
}

func propertyAddress(_ selector: AudioObjectPropertySelector,
                     _ scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal,
                     _ element: AudioObjectPropertyElement = kAudioObjectPropertyElementMain) -> AudioObjectPropertyAddress {
    AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: element)
}

func stringProperty(objectID: AudioObjectID, selector: AudioObjectPropertySelector) -> String? {
    var address = propertyAddress(selector)
    var size = UInt32(MemoryLayout<CFString>.size)
    var value: CFString = "" as CFString
    let status = AudioObjectGetPropertyData(objectID, &address, 0, nil, &size, &value)
    guard status == noErr else { return nil }
    return value as String
}

func hasOutputStreams(deviceID: AudioDeviceID) -> Bool {
    var address = propertyAddress(kAudioDevicePropertyStreams, kAudioDevicePropertyScopeOutput)
    var size: UInt32 = 0
    guard AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &size) == noErr else { return false }
    return size > 0
}

func audioDevices() -> [AudioDevice] {
    var address = propertyAddress(kAudioHardwarePropertyDevices)
    var size: UInt32 = 0
    guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size) == noErr else { return [] }

    let count = Int(size) / MemoryLayout<AudioDeviceID>.size
    var ids = Array(repeating: AudioDeviceID(), count: count)
    guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &ids) == noErr else { return [] }

    return ids.map { id in
        AudioDevice(
            id: id,
            name: stringProperty(objectID: id, selector: kAudioObjectPropertyName) ?? "Unknown device",
            hasOutput: hasOutputStreams(deviceID: id)
        )
    }
}

@main
struct AppAudioPipe {
    static func main() async {
        print("AppAudioPipe spike")
        print("\nOutput devices:")
        for device in audioDevices().filter(\.hasOutput) {
            print("- [\(device.id)] \(device.name)")
        }

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
