# AppAudioPipe

AppAudioPipe is an early Swift command-line prototype for exploring per-application audio capture and routing on macOS. The intended direction is documented in [PRD.md](PRD.md), with investigation notes in [TECHNICAL_SPIKE.md](TECHNICAL_SPIKE.md).

## Current status

This repository currently contains a repeatably runnable diagnostic CLI. It prints an AppAudioPipe banner, lists CoreAudio output devices, and asks ScreenCaptureKit for visible shareable applications/windows.

It does not require Pocket Bard or VB-Cable to build or run the current diagnostics.

## Requirements

- macOS 14 or later
- Swift/Xcode command line tools compatible with the package toolchain
- Screen & System Audio Recording permission may be required by macOS for ScreenCaptureKit source listing

If ScreenCaptureKit enumeration fails, grant the permission in System Settings and run the command again.

## Build

```bash
swift build
```

## Run

```bash
swift run AppAudioPipe
```

Expected output starts with the AppAudioPipe diagnostic banner, followed by live device and ScreenCaptureKit source diagnostics.

## Test

```bash
swift test
```

## Current limitations and non-goals

- Not a SoundSource replacement.
- There is no routing/capture pipeline yet; the CLI only prints diagnostics.
- There is no app selection, output routing, or VB-Cable piping yet.
- There is no packaged or signed macOS app.
- There is no menu bar UI yet.
