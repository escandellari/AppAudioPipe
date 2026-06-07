import Foundation

public enum OutputSelectionError: Error, Sendable, Equatable, CustomStringConvertible {
    case missing(String)
    case notOutputCapable(String)

    public var description: String {
        switch self {
        case .missing(let query):
            return "No output device matched '\(query)'. Run `swift run AppAudioPipe` to list output devices, then retry with an exact device name."
        case .notOutputCapable(let name):
            return "The selected device '\(name)' is not output-capable. Run `swift run AppAudioPipe` to list output devices, then choose an output device."
        }
    }
}

public struct OutputSelection: Sendable {
    public init() {}

    public func select(query rawQuery: String, from devices: [AudioDevice]) -> Result<AudioDevice, OutputSelectionError> {
        let query = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if let exact = devices.first(where: { $0.name == query }) {
            return exact.hasOutput ? .success(exact) : .failure(.notOutputCapable(exact.name))
        }
        if let folded = devices.first(where: { $0.name.compare(query, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame }) {
            return folded.hasOutput ? .success(folded) : .failure(.notOutputCapable(folded.name))
        }
        return .failure(.missing(query))
    }
}
