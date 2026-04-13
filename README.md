# CatLock

**English** | [中文](docs/README_zh.md) | [Deutsch](docs/README_de.md)

A lightweight macOS menu bar app that locks your keyboard and mouse — because cats have opinions about your work.

<p align="center">
  <img src="docs/pics/main-interface.png" alt="CatLock main interface" width="280">
</p>

Press a customizable shortcut (default `Cmd+Shift+L`) from any app to instantly lock all input. A fullscreen overlay appears with a single unlock button. Press the shortcut again or click the button to unlock.

## Features

- **Global hotkey** — Works from any app, even when CatLock is in the background
- **Customizable shortcut** — Record any key combination you like
- **Privacy mode** — Black out the entire screen while locked
- **Menu bar app** — Lives in your menu bar, stays out of your way
- **25 languages** — Auto-detects your system language
- **Sleep prevention** — Keeps your Mac awake so long-running tasks aren't interrupted

## Lock Mode

When locked, a translucent overlay covers your screen. Your desktop stays visible, but all keyboard and mouse input is blocked.

<p align="center">
  <img src="docs/pics/normal-lock-mode.png" alt="Normal lock mode" width="600">
</p>

## Privacy Mode

Need to step away? Turn on Privacy Mode in Settings — the overlay goes fully opaque, hiding everything on screen.

<p align="center">
  <img src="docs/pics/privacy-mode.png" alt="Privacy mode" width="600">
</p>

## Settings

Customize your shortcut and toggle Privacy Mode from the Settings panel.

<p align="center">
  <img src="docs/pics/settings.png" alt="Settings" width="320">
</p>

## Why CatLock?

Your cat walks across the keyboard. Your toddler discovers the delete key. You're wiping down the keyboard and accidentally trigger a shortcut that rearranges your desktop. CatLock intercepts all input at the system level — while locked, no events reach any application.

## How It Works

CatLock uses macOS CGEvent taps to intercept keyboard and mouse events before they reach any application. A lightweight listen-only tap runs at all times to detect the shortcut. When locked, a second tap blocks all input except the unlock shortcut. This requires Accessibility permission, which CatLock will prompt you to grant on first use.

## Install

1. Download the latest `.dmg` from [Releases](../../releases)
2. Open the `.dmg` and drag CatLock to your Applications folder
3. Open CatLock. macOS will show a warning — click **Done** (not "Move to Trash")
4. Go to **System Settings → Privacy & Security**, scroll down, and click **Open Anyway**
5. CatLock will ask for Accessibility permission — click the button to grant it in System Settings

> **Why the warning?** CatLock is open-source and free. The warning appears because the app is not signed with a paid Apple Developer certificate ($99/year). The source code is fully available for review in this repository.

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

GPL-3.0
