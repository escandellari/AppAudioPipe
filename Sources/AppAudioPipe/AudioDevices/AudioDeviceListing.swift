import CoreAudio
import Foundation

public struct AudioDevice: Sendable, Equatable {
    public let id: AudioDeviceID
    public let name: String
    public let hasOutput: Bool

    public init(id: AudioDeviceID, name: String, hasOutput: Bool) {
        self.id = id
        self.name = name
        self.hasOutput = hasOutput
    }
}

public struct AudioDeviceListing: Sendable {
    public let devices: [AudioDevice]

    public init(devices: [AudioDevice]) {
        self.devices = devices
    }

    public var outputDevices: [AudioDevice] {
        devices
            .filter(\.hasOutput)
            .sorted { lhs, rhs in
                let comparison = lhs.name.localizedCaseInsensitiveCompare(rhs.name)
                if comparison == .orderedSame {
                    return lhs.id < rhs.id
                }
                return comparison == .orderedAscending
            }
    }

    public func renderOutputDevicesSection() -> String {
        var lines = ["Output devices:"]
        let outputs = outputDevices

        if outputs.isEmpty {
            lines.append("No output-capable CoreAudio devices found.")
            lines.append("Audio routing cannot start until macOS reports an output-capable device.")
        } else {
            lines.append(contentsOf: outputs.map(renderRow))
        }

        return lines.joined(separator: "\n")
    }

    private func renderRow(for device: AudioDevice) -> String {
        let hint = isKnownVirtualDeviceName(device.name) ? " (virtual audio device)" : ""
        return "- [\(device.id)] \(device.name)\(hint)"
    }

    private func isKnownVirtualDeviceName(_ name: String) -> Bool {
        let lowercasedName = name.localizedLowercase
        return lowercasedName.contains("vb-cable")
            || lowercasedName.contains("vb cable")
            || lowercasedName.contains("blackhole")
    }
}
