import Foundation

public enum SourceSelectionError: Error, Sendable, Equatable, CustomStringConvertible {
    case notFound(String)

    public var description: String {
        switch self {
        case .notFound(let query):
            return "No capturable app or window matched '\(query)'. Run `swift run AppAudioPipe` to list visible sources, then retry with an exact name or process ID."
        }
    }
}

public struct SourceSelection: Sendable {
    public init() {}

    public func select(query rawQuery: String, from sources: [CaptureSource]) -> Result<CaptureSource, SourceSelectionError> {
        let query = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let visibleSources = CaptureSourceListing(state: .sources(sources)).visibleSources

        if let pid = Int32(query) {
            if let match = visibleSources.first(where: { $0.processID == pid || ($0.kind == .application && Int32($0.id) == pid) }) {
                return .success(match)
            }
            return .failure(.notFound(query))
        }

        if let match = visibleSources.first(where: { $0.name == query }) {
            return .success(match)
        }

        return .failure(.notFound(query))
    }
}
