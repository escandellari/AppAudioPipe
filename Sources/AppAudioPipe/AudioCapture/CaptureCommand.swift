import Foundation

public enum CaptureCommand: Sendable, Equatable {
    case diagnostics
    case help
    case captureSource(String)
    case pipe(captureSource: String, output: String)
    case invalid(String)

    public static let usage = "Usage: swift run AppAudioPipe [--help] [--capture-source <app-or-window-name-or-pid> [--output <output-device-name>]]"

    public static func parse(_ arguments: ArraySlice<String>) -> CaptureCommand {
        let args = Array(arguments)
        guard !args.isEmpty else { return .diagnostics }
        if args.count == 1, args[0] == "--help" || args[0] == "-h" { return .help }
        guard args.count == 2 || args.count == 4, args[0] == "--capture-source" else {
            return .invalid("Invalid arguments. \(usage)")
        }

        let query = args[1].trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return .invalid("Missing capture source. \(usage)")
        }

        guard args.count == 4 else { return .captureSource(query) }
        guard args[2] == "--output" else { return .invalid("Invalid arguments. \(usage)") }
        let output = args[3].trimmingCharacters(in: .whitespacesAndNewlines)
        guard !output.isEmpty else { return .invalid("Missing output device. \(usage)") }
        return .pipe(captureSource: query, output: output)
    }
}
