import Foundation

public enum CapturedSampleType: Sendable, Equatable {
    case float32
    case int16
}

public struct CapturedPCMFormat: Sendable, Equatable {
    public let sampleRate: Double
    public let channelCount: Int
    public let sampleType: CapturedSampleType

    public init(sampleRate: Double, channelCount: Int, sampleType: CapturedSampleType) {
        self.sampleRate = sampleRate
        self.channelCount = channelCount
        self.sampleType = sampleType
    }
}

public enum AudioFormatCompatibilityError: Error, Sendable, Equatable, CustomStringConvertible {
    case unsupportedChannelCount(Int)

    public var description: String {
        switch self {
        case .unsupportedChannelCount(let count):
            return "Unsupported captured audio channel count \(count). This pipe supports stereo (2-channel) PCM only."
        }
    }
}

public struct AudioFormatCompatibility: Sendable {
    public init() {}

    public func validate(_ format: CapturedPCMFormat) -> Result<CapturedPCMFormat, AudioFormatCompatibilityError> {
        guard format.channelCount == 2 else { return .failure(.unsupportedChannelCount(format.channelCount)) }
        return .success(format)
    }
}
