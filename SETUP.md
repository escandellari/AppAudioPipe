# AppAudioPipe local audio setup

This guide captures the working Pocket Bard → AppAudioPipe → BlackHole/Kenku FM → Discord setup and how to recover normal laptop audio afterward.

## Target workflow

```text
Pocket Bard
  → AppAudioPipe
  → BlackHole 2ch
  → Kenku FM bot
  → Discord voice channel
```

Keep Discord itself on your normal devices:

- Discord input: your real microphone
- Discord output: your real headphones/speakers

Do not set Discord input or output to BlackHole for the normal workflow.

## Install and verify BlackHole

Install BlackHole 2ch, then restart your Mac if the installer requests it.

After restart, confirm BlackHole appears in:

- Audio MIDI Setup
- System Settings → Sound → Input
- System Settings → Sound → Output

In this repository, list AppAudioPipe devices and sources:

```bash
swift run AppAudioPipe
```

Confirm the output-device list includes something like:

```text
- [109] BlackHole 2ch (virtual audio device)
```

Use the exact device name shown by the output-device list.

## Start the pipe

Open Pocket Bard and start playback. Then run:

```bash
swift run AppAudioPipe --capture-source "Pocket Bard" --output "BlackHole 2ch"
```

Leave the command running while you want Pocket Bard audio copied to BlackHole.

Healthy output looks like:

```text
Starting audio pipe from app 'Pocket Bard' pid=... to output 'BlackHole 2ch' [...]
pipe audio rms=0.1234 peak=0.5678 written=960
```

`rms`, `peak`, and `written` mean AppAudioPipe is receiving Pocket Bard samples and queueing them for the selected output.

## Configure Kenku FM

In Kenku FM:

1. Select/configure BlackHole 2ch as Kenku's audio input/source.
2. Connect the Kenku bot to the Discord voice channel.
3. Confirm Kenku receives audio while AppAudioPipe is running.

If Kenku does not show BlackHole:

- Quit and reopen Kenku FM.
- Confirm BlackHole appears in Audio MIDI Setup.
- Grant Kenku FM microphone permission in System Settings → Privacy & Security → Microphone.

## Configure Discord

In Discord voice settings:

- Input Device: your real microphone
- Output Device: your real headphones/speakers

If music struggles when you talk, try disabling Discord processing that can duck or suppress audio:

- Echo Cancellation
- Noise Suppression
- Automatic Gain Control
- Attenuation / lowering other apps when you speak

Also check that the Kenku bot is not muted/deafened and that its user volume is up.

## Stop AppAudioPipe

If AppAudioPipe is running in the terminal, press:

```text
Ctrl + C
```

To check whether AppAudioPipe is still running:

```bash
ps aux | grep '[A]ppAudioPipe'
```

If nothing prints, AppAudioPipe is not running.

To stop any remaining music/Discord path, stop the relevant app instead:

- Stop Pocket Bard playback, or quit Pocket Bard.
- Disconnect the Kenku bot from Discord, or quit Kenku FM.
- Leave the Discord voice channel if needed.

The BlackHole driver may appear in process lists as `Core Audio Driver (BlackHole2ch.driver)`. That is normal and is not AppAudioPipe.

## Restore normal laptop audio

If you cannot hear anything after experimenting:

1. Open System Settings → Sound → Output.
2. Select your real speakers/headphones, such as MacBook Pro Speakers.
3. Open System Settings → Sound → Input.
4. Select your real microphone.
5. In Discord, set input to your real microphone and output to your real headphones/speakers.
6. Quit or disconnect Kenku FM if its bot is still connected.
7. Stop and restart Pocket Bard playback.

You do not need AppAudioPipe to hear Pocket Bard locally. Normal local playback should come from macOS output being set to your speakers/headphones.

## Common troubleshooting

### AppAudioPipe prints audio levels, but Kenku/Discord hears nothing

Check whether BlackHole input shows signal in System Settings → Sound → Input while AppAudioPipe runs. If the meter moves, AppAudioPipe and BlackHole are probably working; check Kenku and Discord routing.

### BlackHole does not appear in Kenku

Restart Kenku FM and confirm it has microphone permission.

### Discord cannot hear other people

Discord output is probably set to BlackHole. Set Discord output back to real headphones/speakers.

### Other people hear your mic instead of music

Discord input is probably set to BlackHole or Kenku is not being used as the bot source. Set Discord input back to your real microphone, and configure BlackHole inside Kenku FM.

### Pocket Bard is not found

Run:

```bash
swift run AppAudioPipe
```

Use the exact visible app/window name or process ID from the source listing.
