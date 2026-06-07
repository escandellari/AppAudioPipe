import Foundation

public enum CaptureCommand: Sendable, Equatable {
    case diagnostics
    case captureSource(String)
    case invalid(String)

    public static let usage = "Usage: swift run AppAudioPipe [--capture-source <app-or-window-name-or-pid>]"

    public static func parse(_ arguments: ArraySlice<String>) -> CaptureCommand {
        let args = Array(arguments)
        guard !args.isEmpty else { return .diagnostics }
        guard args.count == 2, args[0] == "--capture-source" else {
            return .invalid("Invalid arguments. \(usage)")
        }

        let query = args[1].trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return .invalid("Missing capture source. \(usage)")
        }

        return .captureSource(query)
    }
}
