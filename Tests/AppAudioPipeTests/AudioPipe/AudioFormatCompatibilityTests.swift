import Testing
@testable import AppAudioPipe

@Suite("AudioFormatCompatibility")
struct AudioFormatCompatibilityTests {
    @Test func supportedStereoPCMAccepts() throws {
        let format = CapturedPCMFormat(sampleRate: 48_000, channelCount: 2, sampleType: .float32)
        let accepted = try AudioFormatCompatibility().validate(format).get()
        #expect(accepted == format)
    }

    @Test func unsupportedChannelCountsAreRejectedClearly() {
        let format = CapturedPCMFormat(sampleRate: 48_000, channelCount: 6, sampleType: .float32)
        if case .failure(let error) = AudioFormatCompatibility().validate(format) {
            #expect(error.description.contains("channel count 6"))
            #expect(error.description.contains("stereo"))
        } else { Issue.record("Expected unsupported channel failure") }
    }
}
