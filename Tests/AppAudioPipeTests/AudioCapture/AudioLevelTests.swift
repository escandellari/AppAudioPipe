import Testing
@testable import AppAudioPipe

@Suite("AudioLevel")
struct AudioLevelTests {
    @Test func emptyAndZeroSamplesAreSilent() {
        #expect(AudioLevel.calculate([Float]()).isSilent)
        #expect(AudioLevel.calculate([0, 0, 0] as [Float]).rms == 0)
        #expect(AudioLevel.calculate([0, 0, 0] as [Float]).peak == 0)
    }

    @Test func nonZeroSamplesReportActivity() {
        let level = AudioLevel.calculate([0.5, -0.5, 0.25] as [Float])

        #expect(level.rms > 0)
        #expect(level.peak == 0.5)
        #expect(!level.isSilent)
    }
}
