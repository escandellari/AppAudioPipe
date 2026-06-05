# AppAudioPipe PRD

## Goal

Route/copy audio from a selected macOS app, initially Pocket Bard, to a selected virtual output device, initially VB-Cable, so Kenku FM can stream it through a Discord bot.

## Problem

macOS does not provide built-in per-app output routing. Paid tools such as SoundSource can route Pocket Bard to VB-Cable while keeping Discord on headphones, but the project needs a focused free alternative for this one workflow.

## Target workflow

```text
Pocket Bard audio
        ↓
AppAudioPipe
        ↓
VB-Cable
        ↓
Kenku FM
        ↓
Discord bot
```

Discord voice monitoring should continue through normal headphones/speakers, configured directly in Discord where possible.

## MVP scope

- List candidate source apps/windows available to ScreenCaptureKit.
- List CoreAudio output devices.
- Select one source app/window, initially Pocket Bard.
- Select one output device, initially VB-Cable.
- Start/stop piping captured audio to the selected output device.
- Show a basic indication that audio is flowing.
- Provide clear errors for missing permissions, missing source app, missing output device, or unsupported audio format.

## Non-goals

- Full SoundSource replacement.
- Per-app EQ, effects, volume boost, or profiles.
- Custom virtual audio driver.
- System-wide routing of all app audio.
- Multi-app routing.
- Windows/Linux support.
- Discord or Kenku FM automation.

## Success criteria

- Pocket Bard appears as a selectable source or can be captured via a selectable window/process.
- VB-Cable appears as a selectable output device.
- Pocket Bard audio reaches VB-Cable.
- Kenku FM can receive and play the VB-Cable audio.
- Discord voice input/output can remain on the user’s microphone/headphones without rebroadcasting Discord call audio.
- The first version requires no custom audio driver installation beyond VB-Cable/BlackHole.

## Technical approach

Start with a narrow Swift/macOS technical prototype:

- Use CoreAudio to enumerate output devices.
- Use ScreenCaptureKit to enumerate and capture app/window audio.
- Use an audio output path targeting a selected CoreAudio device.
- Prefer copying captured audio to VB-Cable over true per-app redirection.

Expected architecture:

```text
SCContentFilter for Pocket Bard/window
        ↓
SCStream audio sample buffers
        ↓
PCM conversion / buffering
        ↓
CoreAudio or AVAudioEngine output to VB-Cable
```

## Known limitations

- The MVP may copy audio rather than suppress local Pocket Bard playback.
- ScreenCaptureKit permissions are required and may be easier to manage from a packaged app than a raw CLI.
- VB-Cable may require stereo output; format conversion may be necessary.
- Device sample rates, channel counts, and buffer timing may need explicit handling.

## Open questions

- Does Pocket Bard appear reliably in ScreenCaptureKit app/window enumeration?
- Can ScreenCaptureKit capture only Pocket Bard audio reliably?
- Is app-only audio capture available and stable enough on macOS 26.5 for this workflow?
- Does VB-Cable accept the captured format directly, or do we need resampling/channel conversion?
- Is a CLI proof sufficient first, or is a minimal signed app required to handle permissions cleanly?

## Next milestone

Build the smallest proof of audio flow:

1. Confirm ScreenCaptureKit permission and source enumeration.
2. Select Pocket Bard or another test app/window.
3. Capture audio sample buffers.
4. Log audio levels to prove capture.
5. Output captured audio to VB-Cable.
