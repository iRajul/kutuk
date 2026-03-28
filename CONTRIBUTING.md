# Contributing to Kutuk

Thanks for your interest in contributing to Kutuk! Here's how to get started.

## Development Setup

1. **Requirements**: Xcode 15+ and macOS 14+
2. Clone the repo and open `kutuk.xcodeproj` in Xcode
3. Build and run with `Cmd+R`, or use `make build` from the terminal

## Building from Terminal

```bash
# Build the app
make build

# Create distributable app bundle (ad-hoc signed)
make dist-app

# Create DMG installer
make dmg

# Clean build artifacts
make clean
```

## Project Structure

- `kutuk/` — Main source directory
  - `kutukApp.swift` — App entry point
  - `Views/` — SwiftUI menu bar UI
  - `Services/` — Keyboard monitoring, audio engine, hotkey management
  - `Settings/` — UserDefaults persistence
  - `Models/` — Data models (sound packs, hotkey shortcuts)
  - `Resources/Sounds/` — Sound pack WAV files
  - `Assets.xcassets/` — App and menu bar icons

## Adding a Sound Pack

1. Create a new folder under `kutuk/Resources/Sounds/` with your pack ID
2. Add WAV files following the naming convention: `{packId}_{keyType}_{event}_{variation}.wav`
3. Register the pack in `SoundPack.swift`

## Submitting Changes

1. Fork the repo and create a feature branch
2. Make your changes
3. Test the app locally (`make build && make dist-app`)
4. Open a pull request with a clear description

## Code Style

- Follow standard Swift conventions
- Use SwiftUI for all UI components
- Keep services loosely coupled via the coordinator pattern

## Reporting Issues

Open a GitHub issue with steps to reproduce, expected behavior, and your macOS version.
