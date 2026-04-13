# CatLock v2 Design Spec

## Overview

CatLock is a macOS menu bar app that locks the keyboard and mouse to prevent accidental input (e.g., from cats). v2 adds: reliable global hotkey, customizable shortcut settings, privacy mode, localization (25 languages), and a warm-cute visual refresh inspired by DESIGN.md.

## Architecture

```
CatLockApp (@main, SwiftUI App)
├── AppDelegate
│   ├── applicationDidFinishLaunching: setup shortcut event tap
│   └── applicationShouldTerminate: cleanup via prepareForTermination()
├── LockManager (singleton, ObservableObject)
│   ├── lock() / unlock()
│   ├── Shortcut event tap (always-on, lightweight, keyDown only)
│   ├── Lock event tap (active when locked, full keyboard+mouse intercept)
│   ├── OverlayManager → OverlayView (lock screen overlay)
│   └── PowerManager (IOPMAssertion to prevent sleep)
├── SettingsManager (singleton, ObservableObject, UserDefaults-backed)
│   ├── shortcutModifiers: NSEvent.ModifierFlags (default: Cmd+Shift)
│   ├── shortcutKeyCode: UInt16 (default: 37, L key)
│   └── privacyMode: Bool (default: false)
├── UI
│   ├── MainWindowView (lock button + status + settings gear)
│   ├── SettingsView (shortcut recorder + privacy toggle + reset)
│   └── MenuBarMenu (lock/unlock + settings + quit)
├── Localization
│   └── Localizable.xcstrings (25 languages)
└── Assets
    ├── Color sets (Parchment, Terracotta, etc.)
    └── AppIcon (SF Symbols placeholder, design spec for future replacement)
```

## 1. Global Hotkey Fix

### Problem
`NSEvent.addGlobalMonitorForEvents` is unreliable — it fails when the app is not focused and cannot intercept events.

### Solution
Replace the NSEvent-based shortcut monitors with a dedicated CGEvent tap that is always active (even when the app is in background). This tap only listens for `keyDown` events and checks for the configured shortcut. It is separate from the lock event tap (which intercepts all keyboard+mouse when locked).

### Implementation
- **Shortcut event tap**: created in `applicationDidFinishLaunching`, lives for the entire app lifetime. Listens for `keyDown` only. When the shortcut is detected, toggles lock state. Uses `.listenOnly` tap option so it doesn't block other events.
- **Lock event tap**: created on `lock()`, destroyed on `unlock()`. Intercepts all keyboard + mouse events. Uses `.defaultTap` to swallow events.
- Remove `setupShortcutMonitors()`, `removeShortcutMonitors()`, `localMonitor`, `globalMonitor`.

### Shortcut matching
Both taps read the current shortcut from `SettingsManager.shared`. The shortcut event tap toggles (lock if unlocked, unlock if locked). The lock event tap also recognizes the shortcut to unlock.

## 2. Settings System

### SettingsManager (new file)
```swift
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @Published var shortcutModifiers: NSEvent.ModifierFlags  // default: [.command, .shift]
    @Published var shortcutKeyCode: UInt16                    // default: 37 (L)
    @Published var privacyMode: Bool                          // default: false

    func resetToDefaults()
    func save()  // persists to UserDefaults
    func shortcutDisplayString() -> String  // e.g. "Cmd+Shift+L" or equivalent symbols
}
```

UserDefaults keys:
- `catlock.shortcut.modifiers` (UInt stored as raw value)
- `catlock.shortcut.keyCode` (UInt16)
- `catlock.privacy.mode` (Bool)

### SettingsView (new file)
A SwiftUI view presented as a separate window or sheet.

**Layout:**
```
┌─────────────────────────────────────┐
│  Settings / 设置                     │
│                                     │
│  Keyboard Shortcut                  │
│  ┌─────────────────────┐            │
│  │  Cmd + Shift + L    │ [Record]   │
│  └─────────────────────┘            │
│                        [Reset Default]│
│                                     │
│  Privacy Mode                       │
│  [toggle]  Full-screen black overlay│
│            when locked              │
│                                     │
└─────────────────────────────────────┘
```

**Shortcut recorder behavior:**
1. User clicks "Record" button
2. Button text changes to "Press shortcut..." and enters recording state
3. The next key combination the user presses is captured
4. Validates: must include at least one modifier (Cmd/Ctrl/Option/Shift) + one non-modifier key
5. If valid, saves and updates display. If invalid (e.g., single letter), shows brief error
6. Press Escape to cancel recording

**Implementation:** Use a local NSEvent monitor (keyDown) during recording mode to capture the key combination. This is only active while the "Record" button is in recording state.

## 3. Lock Screen UI Changes

### Layout change
Move hint text from screen bottom to directly below the unlock button:

```
┌──────────────────────────────────┐
│         (semi-transparent        │
│          or black overlay)       │
│                                  │
│          [cat icon]              │
│                                  │
│     ┌──────────────────┐         │
│     │   🔓 Unlock      │         │
│     │   Click to unlock │         │
│     └──────────────────┘         │
│                                  │
│   System will not sleep.         │
│   Press Cmd+Shift+L to unlock    │
│                                  │
│                                  │
└──────────────────────────────────┘
```

### Privacy mode
- When `SettingsManager.shared.privacyMode` is true: `Color.black.opacity(1.0)`
- When false: `Color.black.opacity(0.4)` (current behavior)

### Dynamic shortcut text
The "Press X to unlock" text reads from `SettingsManager.shared.shortcutDisplayString()` so it always reflects the current shortcut.

## 4. Visual Style (Warm-Cute)

### Color palette (from DESIGN.md)
Define as SwiftUI Color extensions or Asset Catalog color sets:
- `Color.parchment` = `#f5f4ed` (main background)
- `Color.ivory` = `#faf9f5` (card surface)
- `Color.terracotta` = `#c96442` (primary button, accent)
- `Color.nearBlack` = `#141413` (primary text)
- `Color.oliveGray` = `#5e5d59` (secondary text)
- `Color.warmSand` = `#e8e6dc` (secondary button bg)
- `Color.borderCream` = `#f0eee6` (borders)

### Typography
- Headlines: Georgia (serif fallback for Anthropic Serif), weight .medium
- Body/UI: system font (San Francisco)
- Keep it simple — no custom font loading

### Cute elements
- Main window: SF Symbol `cat.fill` as hero image, tinted terracotta
- Lock screen: large `cat.fill` above the unlock button
- Menu bar icon: `cat.fill` (unlocked) / custom composed icon with lock badge (locked)
- Rounded corners: 12px on buttons, 16px on cards
- Soft shadows matching DESIGN.md whisper shadow

### Icon design spec (for future replacement)
A separate section in this doc or a companion file describing the ideal icon:
- Concept: a sitting cat silhouette with a small padlock hanging from its tail or collar
- Style: organic, hand-drawn feeling, terracotta + black on transparent
- Sizes needed: 16x16, 32x32, 128x128, 256x256, 512x512 (1x and 2x)
- Menu bar variant: simplified single-color silhouette, 18px height

## 5. Localization

### Approach
Use Xcode String Catalog (`.xcstrings` format, single file).

### Languages (24 + English)
en, zh-Hans, zh-Hant, de, fr, it, es, ja, ko, nl, pt-BR, tr, th, ar, fa, he, el, pl, cs, sv, fi, nb, ru, uk

### Strings to translate (~20)
UI strings:
- "CatLock" (app name, keep as-is in all languages)
- "Lock Keyboard" (main button)
- "Unlock" / "Click to unlock" (lock screen)
- "Lock" / "Unlock" (menu bar)
- "Settings..." (menu bar)
- "Quit CatLock" (menu bar)
- "Keyboard Shortcut" (settings)
- "Record" / "Press shortcut..." (settings)
- "Reset Default" (settings)
- "Privacy Mode" (settings)
- "Full-screen black overlay when locked" (settings description)
- "System will not sleep. Ensure sufficient battery." (lock screen)
- "Press %@ to unlock" (lock screen, with shortcut placeholder)
- "Accessibility permission required" (permission alert title)
- "CatLock needs accessibility permission to intercept keyboard and mouse input." (permission alert body)
- "Open System Settings" (permission alert button)
- "Cancel" (permission alert button)

### RTL support
Arabic, Persian, and Hebrew are RTL languages. SwiftUI handles RTL layout automatically with `.environment(\.layoutDirection, .rightToLeft)`. No special handling needed as long as we use standard SwiftUI layout (VStack, HStack) and localized strings.

## 6. Permission Flow

Keep the current behavior — no change needed:
1. User clicks "Lock Keyboard" button
2. `LockManager.lock()` checks `AXIsProcessTrusted()`
3. If not trusted: show `NSAlert` explaining the need, with button to open System Settings
4. If trusted: proceed with locking

This naturally handles first-launch: the very first time the user tries to lock, they get the permission prompt. Subsequent uses skip it (permission persists).

## 7. Menu Bar Updates

```
MenuBarMenu:
├── Lock Cmd+Shift+L    (when unlocked, shows current shortcut)
│   OR
├── Unlock Cmd+Shift+L  (when locked, shows current shortcut)
├── ─────────
├── Settings...
├── ─────────
├── Quit CatLock
```

The shortcut text after "Lock"/"Unlock" dynamically reflects `SettingsManager.shared.shortcutDisplayString()`.

## Files to Create
1. `SettingsManager.swift` — UserDefaults-backed settings
2. `SettingsView.swift` — settings window UI
3. `ShortcutRecorder.swift` — shortcut recording component (or inline in SettingsView)
4. `Theme.swift` — color palette + style constants
5. `Localizable.xcstrings` — string catalog with all 25 languages

## Files to Modify
1. `LockManager.swift` — replace NSEvent monitors with always-on CGEvent tap, read shortcut from SettingsManager
2. `CatLockApp.swift` — add settings window, update menu bar, apply theme
3. `OverlayView.swift` — move hints near button, add privacy mode, add cat icon, apply theme
4. `OverlayManager.swift` — pass privacy mode to overlay
5. `AppDelegate.swift` (in CatLockApp.swift) — create shortcut event tap on launch
6. `AccessibilityHelper.swift` — use localized strings

## Files Unchanged
1. `PowerManager.swift` — no changes needed
