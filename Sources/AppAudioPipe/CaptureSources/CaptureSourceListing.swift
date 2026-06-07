import Foundation

public enum CaptureSourceKind: Sendable, Equatable {
    case application
    case window
}

public struct CaptureSource: Sendable, Equatable {
    public let kind: CaptureSourceKind
    public let id: UInt32
    public let name: String
    public let owningApplicationName: String?
    public let processID: Int32?
    public let bundleIdentifier: String?

    public init(
        kind: CaptureSourceKind,
        id: UInt32,
        name: String,
        owningApplicationName: String? = nil,
        processID: Int32? = nil,
        bundleIdentifier: String? = nil
    ) {
        self.kind = kind
        self.id = id
        self.name = name
        self.owningApplicationName = owningApplicationName
        self.processID = processID
        self.bundleIdentifier = bundleIdentifier
    }
}

public enum CaptureSourceListingState: Sendable, Equatable {
    case sources([CaptureSource])
    case permissionDenied
    case failed(String)
}

public struct CaptureSourceListing: Sendable {
    public let state: CaptureSourceListingState

    public init(state: CaptureSourceListingState) {
        self.state = state
    }

    public var visibleSources: [CaptureSource] {
        guard case .sources(let sources) = state else { return [] }

        return sources
            .filter(isUserIdentifiable)
            .sorted(by: compareSources)
    }

    public func renderSection() -> String {
        var lines = ["Capturable apps/windows visible to ScreenCaptureKit:"]

        switch state {
        case .sources:
            let sources = visibleSources
            if sources.isEmpty {
                lines.append("No capturable apps/windows are currently visible to ScreenCaptureKit.")
                lines.append("Open the target app or window, then rerun this command.")
            } else {
                lines.append(contentsOf: sources.map(renderRow))
            }
        case .permissionDenied:
            lines.append("ScreenCaptureKit enumeration was denied by macOS.")
            lines.append("Enable Screen & System Audio Recording for Terminal or AppAudioPipe in System Settings → Privacy & Security → Screen & System Audio Recording, then rerun this command.")
        case .failed(let message):
            lines.append("ScreenCaptureKit enumeration failed: \(message)")
        }

        return lines.joined(separator: "\n")
    }

    private func isUserIdentifiable(_ source: CaptureSource) -> Bool {
        !source.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func compareSources(_ lhs: CaptureSource, _ rhs: CaptureSource) -> Bool {
        if lhs.kind != rhs.kind {
            return lhs.kind == .application
        }

        let comparison = lhs.name.localizedCaseInsensitiveCompare(rhs.name)
        if comparison == .orderedSame {
            return lhs.id < rhs.id
        }
        return comparison == .orderedAscending
    }

    private func renderRow(for source: CaptureSource) -> String {
        switch source.kind {
        case .application:
            var row = "- app pid=\(source.id) \(source.name)"
            if let bundleIdentifier = source.bundleIdentifier, !bundleIdentifier.isEmpty {
                row += " bundle=\(bundleIdentifier)"
            }
            return row
        case .window:
            var row = "- window id=\(source.id) \(source.name)"
            if let owningApplicationName = source.owningApplicationName, !owningApplicationName.isEmpty {
                row += " app=\(owningApplicationName)"
            }
            if let processID = source.processID {
                row += " pid=\(processID)"
            }
            return row
        }
    }
}
