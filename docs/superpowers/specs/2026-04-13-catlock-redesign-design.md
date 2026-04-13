# CatLock Redesign — Design Spec

## Overview

CatLock is a macOS menu bar app that locks the keyboard and mouse to prevent cats (or other unintended input) from disrupting running tasks. Users lock with a button or global shortcut, and unlock via an overlay button or the same shortcut.

## Requirements

### Functional

1. **One-click lock**: Menu bar "锁定" button or global shortcut (Ctrl+Option+Command+L) activates lock
2. **Keyboard blocked**: All keyboard input is intercepted and discarded during lock
3. **Mouse clicks blocked**: All mouse clicks are intercepted except clicks on the unlock button
4. **Mouse movement allowed**: Pointer can move freely during lock
5. **Overlay UI**: Semi-transparent overlay on all screens with a centered unlock button
6. **Unlock**: Click the unlock button OR press Ctrl+Option+Command+L to unlock
7. **Prevent sleep**: System will not sleep during lock (screen dimming follows user settings). On unlock, sleep behavior returns to normal
8. **Sleep warning**: Overlay displays: "系统将不会进入休眠，请确保任务运行期间电量充足。"
9. **Menu bar app**: Runs as a menu bar icon (no Dock icon, no main window)
10. **Accessibility permission**: On launch, check permission. If missing, show alert + open System Settings. Menu bar shows status.

### Non-Functional

- macOS 13+ (Ventura) — for `MenuBarExtra` API
- Swift / SwiftUI
- No third-party dependencies

## Architecture

### File Structure

```
CatLock/
├── CatLockApp.swift          # App entry, MenuBarExtra, no main window
├── LockManager.swift         # Core: event tap, lock state, global shortcut
├── OverlayManager.swift      # Create/destroy overlay windows per screen
├── OverlayView.swift         # SwiftUI: semi-transparent overlay + unlock button + tips
├── AccessibilityHelper.swift # Permission check, alert, open System Settings
└── PowerManager.swift        # IOPMAssertion: prevent/restore sleep
```

`ContentView.swift` — delete (unused).

### Component Responsibilities

**CatLockApp**
- `MenuBarExtra` with lock icon (`lock.fill` / `lock.open.fill`)
- Menu items: Lock/Unlock toggle, shortcut hint, Quit
- No `WindowGroup`, no Dock icon (`LSUIElement = true` in Info.plist)

**LockManager** (singleton, `ObservableObject`)
- `@Published var isLocked: Bool`
- `lock()`: check accessibility → create event tap → show overlays → disable sleep → set `isLocked = true`
- `unlock()`: disable event tap → hide overlays → restore sleep → set `isLocked = false`
- Event tap callback: filter events based on lock state
- Global shortcut detection: `addLocalMonitorForEvents` + `addGlobalMonitorForEvents` when unlocked; event tap handles it when locked

**OverlayManager**
- `showOverlays()`: for each `NSScreen`, create a borderless `NSWindow` at `.screenSaver` level with `canJoinAllSpaces` + `fullScreenAuxiliary` collection behavior
- `hideOverlays()`: close and release all overlay windows
- Report unlock button screen-coordinate rect to LockManager for click hit-testing

**OverlayView** (SwiftUI)
- Full-screen `ZStack`: black background at 0.4 opacity
- Centered unlock button: white rounded rect, lock icon + "点击解锁" text
- Below button: "系统将不会进入休眠，请确保任务运行期间电量充足。" (small, semi-transparent white)
- Bottom: "按 Ctrl+Option+Command+L 解锁" (small, semi-transparent white)
- Uses `GeometryReader` to report button frame to OverlayManager

**AccessibilityHelper**
- `checkPermission() -> Bool`: calls `AXIsProcessTrusted()`
- `requestPermission()`: calls `AXIsProcessTrustedWithOptions` with prompt, then opens System Settings Privacy URL
- `showPermissionAlert()`: `NSAlert` explaining why permission is needed, with "打开系统设置" button

**PowerManager**
- `disableSleep()`: `IOPMAssertionCreateWithName(.PreventUserIdleSystemSleep)` — prevents system sleep, allows screen dimming
- `restoreSleep()`: `IOPMAssertionRelease` — releases assertion
- If app is force-killed, macOS automatically reclaims the assertion

## Event Tap Design

### Events Intercepted

| Event Type | During Lock |
|------------|-------------|
| `keyDown`, `keyUp`, `flagsChanged` | Check for unlock shortcut → match: unlock. No match: return nil (swallow) |
| `leftMouseDown`, `rightMouseDown`, `otherMouseDown` | Check click coords vs unlock button rect → inside: return event (pass through). Outside: return nil |
| `leftMouseUp`, `rightMouseUp`, `otherMouseUp` | Same as mouseDown — pass through if in button rect |
| `mouseMoved`, `scrollWheel` | Not included in `eventsOfInterest` — naturally pass through, never intercepted |
| `tapDisabledByTimeout` | Re-enable the tap (macOS safety mechanism) |

### Event Tap Lifecycle

1. **Lock**: `CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap, ...)` → add to RunLoop → enable
2. **Unlock**: `CGEvent.tapEnable(tap, false)` → `CFMachPortInvalidate(tap)` → `CFRunLoopRemoveSource(...)` → nil references
3. **Timeout recovery**: on `.tapDisabledByTimeout`, call `CGEvent.tapEnable(tap, true)`

### Unlock Button Hit-Testing

- OverlayView uses `GeometryReader` to measure button frame in window coordinates
- OverlayManager converts to screen coordinates using window's frame origin
- LockManager stores the union of all unlock button rects (one per screen)
- Event tap callback reads button rects via `userInfo` pointer to LockManager
- Mouse event coordinates compared against button rects to decide pass-through

## Global Shortcut (Ctrl+Option+Command+L)

- **Unlocked state**: `NSEvent.addLocalMonitorForEvents` (when app is active) + `NSEvent.addGlobalMonitorForEvents` (when app is in background) detect the shortcut and call `lock()`
- **Locked state**: event tap callback checks every `keyDown` for modifier flags `[.control, .option, .command]` + keyCode 37 (L) and calls `unlock()`
- Same shortcut toggles both states

## Lock/Unlock Flow

```
User triggers lock (menu click or Ctrl+Opt+Cmd+L)
  │
  ├─ AccessibilityHelper.checkPermission()
  │   ├─ No → showPermissionAlert() → return (do not lock)
  │   └─ Yes ↓
  ├─ PowerManager.disableSleep()
  ├─ Create CGEvent tap (keyboard + mouse clicks)
  ├─ Add tap to RunLoop, enable
  ├─ OverlayManager.showOverlays()
  └─ isLocked = true

User triggers unlock (overlay button click or Ctrl+Opt+Cmd+L)
  │
  ├─ Disable + invalidate event tap
  ├─ Remove RunLoop source
  ├─ OverlayManager.hideOverlays()
  ├─ PowerManager.restoreSleep()
  └─ isLocked = false
```

## Info.plist Changes

- `LSUIElement`: `true` (no Dock icon)
- App Sandbox: disabled (CGEvent tap requires unsandboxed execution)
- Hardened Runtime: enabled, with `com.apple.security.accessibility` entitlement if needed
