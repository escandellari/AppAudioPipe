import Foundation

public struct AudioLevel: Sendable, Equatable {
    public let rms: Double
    public let peak: Double

    public var isSilent: Bool { rms == 0 && peak == 0 }

    public init(rms: Double, peak: Double) {
        self.rms = rms
        self.peak = peak
    }

    public static func calculate<S: Sequence>(_ samples: S) -> AudioLevel where S.Element == Float {
        var count = 0
        var sumSquares = 0.0
        var peak = 0.0

        for sample in samples {
            let value = Double(sample)
            let magnitude = abs(value)
            peak = max(peak, magnitude)
            sumSquares += value * value
            count += 1
        }

        guard count > 0 else { return AudioLevel(rms: 0, peak: 0) }
        return AudioLevel(rms: sqrt(sumSquares / Double(count)), peak: peak)
    }

    public func render() -> String {
        "audio level rms=\(String(format: "%.4f", rms)) peak=\(String(format: "%.4f", peak))"
    }
}
