# CatLock

A lightweight macOS menu bar app that locks your keyboard and mouse to prevent accidental input from cats, kids, or cleaning.

Press a customizable shortcut (default: `Cmd+Shift+L`) from any app to instantly lock all keyboard and mouse input. A fullscreen overlay appears with a single unlock button. Press the shortcut again or click the button to unlock. That's it.

## Features

- **Global hotkey** — Works from any app, even when CatLock is in the background
- **Customizable shortcut** — Record any key combination in Settings
- **Privacy mode** — Optional fully opaque overlay that hides your screen content
- **Menu bar app** — Lives in your menu bar, stays out of your way
- **25 languages** — Auto-detects your system language
- **Sleep prevention** — Keeps your Mac awake while locked so long-running tasks aren't interrupted

## Why CatLock?

Your cat walks across the keyboard. Your toddler mashes keys while you step away. You're cleaning the keyboard and accidentally trigger shortcuts. CatLock solves all of these by intercepting input at the system level — no events reach any application while locked.

## How It Works

CatLock uses macOS CGEvent taps to intercept keyboard and mouse events before they reach any application. A lightweight listen-only tap runs at all times to detect the shortcut. When locked, a second tap swallows all input except the unlock shortcut. This requires Accessibility permission, which CatLock will prompt you to grant on first use.

## Install

Download the latest `.dmg` from [Releases](../../releases), open it, and drag CatLock to your Applications folder.

## Build from Source

```
git clone https://github.com/hou-physics/CatLock.git
cd CatLock
xcodebuild -scheme CatLock -configuration Release build
```

The built app will be in `~/Library/Developer/Xcode/DerivedData/CatLock-*/Build/Products/Release/CatLock.app`.

## Requirements

- macOS 14.0 or later
- Accessibility permission (prompted on first use)

## License

MIT
