# AppAudioPipe technical spike

Goal: route/copy audio from one chosen macOS app, e.g. Pocket Bard, to one chosen virtual output, e.g. VB-Cable, so Kenku FM can use it as a Discord bot source.

## Environment checked

- macOS 26.5
- Swift 6.3.2
- Architecture: arm64
- VB-Cable is installed and visible as a CoreAudio output device.

## Current prototype

A Swift Package has been scaffolded at:

```text
/Users/elisascandellari/devel/AppAudioPipe
```

It currently:

- enumerates CoreAudio output devices
- enumerates ScreenCaptureKit-shareable apps/windows, once permission is granted

Run it with:

```bash
cd /Users/elisascandellari/devel/AppAudioPipe
swift run AppAudioPipe
```

Observed output devices:

```text
MacBook Pro Speakers
VB-Cable
```

ScreenCaptureKit app enumeration failed because macOS has not granted capture permission to the terminal/app yet.

## Recommended architecture

For the first useful version, do **not** build a full SoundSource clone.

Build a narrow app-audio pipe:

```text
Pocket Bard process/window audio
        ↓
ScreenCaptureKit / process-audio capture
        ↓
AVAudioEngine/CoreAudio output node
        ↓
VB-Cable
        ↓
Kenku FM
        ↓
Discord bot
```

This is more achievable than a virtual audio driver/router.

## MVP

1. List running apps.
2. Select source app/window: Pocket Bard.
3. Select destination output: VB-Cable.
4. Capture source audio.
5. Play captured audio into the selected CoreAudio output device.
6. Add a simple level meter/log line so we know audio is flowing.

## Known limitation

This approach likely **copies** Pocket Bard audio to VB-Cable rather than fully redirecting it. Pocket Bard may still play locally. For your use case, that is probably acceptable, because you may want to hear it too.

True redirect/mute-per-app requires a deeper virtual-device/CoreAudio-driver approach.

## Next technical step

Grant capture permission, then implement the first capture loop:

- create an `SCContentFilter` for Pocket Bard or its window
- create an `SCStreamConfiguration` with audio capture enabled
- receive audio sample buffers from `SCStreamOutput`
- convert them into PCM buffers
- feed those buffers to an audio output path targeting VB-Cable

## Permission note

When running from Terminal, macOS may require permission for Terminal or the built binary under:

```text
System Settings → Privacy & Security → Screen & System Audio Recording
```

If it does not appear, building a small signed `.app` wrapper may be the simplest way to trigger and manage permissions cleanly.
