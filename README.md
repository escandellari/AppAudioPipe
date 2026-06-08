# AppAudioPipe

AppAudioPipe is an early Swift command-line prototype for exploring per-application audio capture and routing on macOS. The intended direction is documented in [PRD.md](PRD.md), with investigation notes in [TECHNICAL_SPIKE.md](TECHNICAL_SPIKE.md). For the local Pocket Bard/Kenku/Discord routing checklist and recovery steps, see [SETUP.md](SETUP.md).

## Current status

This repository contains a repeatably runnable diagnostic and pipe-proof CLI. It can list CoreAudio output devices and ScreenCaptureKit capturable apps/windows, capture one visible source as an audio-level proof, or copy that source's audio to a selected output device such as VB-Cable.

It does not require Pocket Bard, Kenku FM, Discord, or VB-Cable to build, test, or run the default diagnostics.

## Requirements

- macOS 14 or later
- Swift/Xcode command line tools compatible with the package toolchain
- Screen & System Audio Recording permission for Terminal/AppAudioPipe when macOS prompts for ScreenCaptureKit access
- VB-Cable installed and visible as an output device for the pipe workflow
- Pocket Bard running, visible, and producing audio for the concrete workflow below
- Kenku FM and Discord configured manually by the user

If ScreenCaptureKit enumeration fails, grant Screen & System Audio Recording permission in System Settings and run the command again.

## Build

```bash
swift build
```

## Run

Show CLI help:

```bash
swift run AppAudioPipe --help
```

List output devices, then capturable applications/windows:

```bash
swift run AppAudioPipe
```

Expected output starts with the AppAudioPipe diagnostic banner, followed by live output-device and ScreenCaptureKit source diagnostics.

## Pocket Bard → VB-Cable → Kenku FM workflow

### 1. Prepare macOS permissions

Open Pocket Bard and make sure it is visible to macOS and producing audio. If macOS asks for capture permissions, grant Screen & System Audio Recording permission to Terminal/AppAudioPipe, then rerun AppAudioPipe.

### 2. List sources and outputs

```bash
swift run AppAudioPipe
```

Use the exact visible app/window name or process ID from the source listing. Use the exact output device name from the output-device listing.

### 3. Capture Pocket Bard as a proof

```bash
swift run AppAudioPipe --capture-source "Pocket Bard"
```

This confirms AppAudioPipe can identify and capture the selected source before routing it to an output device.

### 4. Start the AppAudioPipe pipe

```bash
swift run AppAudioPipe --capture-source "Pocket Bard" --output "VB-Cable"
```

Keep this command running while you want copied Pocket Bard audio sent to VB-Cable.

### 5. Configure Kenku FM to receive VB-Cable

In Kenku FM, configure/select VB-Cable as the audio input/source, then confirm Kenku receives audio while the AppAudioPipe pipe is running. Exact Kenku FM UI labels can vary by version.

### 6. Keep Discord on real mic/headphones

For this workflow, keep Discord voice input set to your real microphone and Discord output set to your real headphones/speakers. Do not set Discord input/output to VB-Cable unless you intentionally want different routing.

### Troubleshooting

- Run `swift run AppAudioPipe --help` for concise command usage and permission notes.
- Run `swift run AppAudioPipe` again after changing permissions or connecting VB-Cable.
- If Pocket Bard is not found, use the exact app/window name or process ID shown by the listing command.
- If VB-Cable is not found, use the exact output device name shown by the listing command and confirm VB-Cable is installed.

## Test

```bash
swift test
```

## Current limitations and non-goals

- Not a SoundSource replacement.
- Audio is copied to the selected output; this slice does not guarantee muting Pocket Bard locally or exclusive per-app redirection.
- There is no Discord/Kenku automation; configure those apps manually.
- There is no packaged or signed macOS app.
- There is no menu bar UI yet.
