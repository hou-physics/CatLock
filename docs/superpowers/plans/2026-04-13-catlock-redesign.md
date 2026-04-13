# CatLock Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rewrite CatLock as a menu-bar-only macOS app that reliably locks keyboard and mouse input using CGEvent Tap, with overlay UI and sleep prevention.

**Architecture:** Six focused Swift files — CatLockApp (MenuBarExtra entry), LockManager (event tap + state), OverlayManager (multi-screen windows), OverlayView (SwiftUI overlay UI), AccessibilityHelper (permission handling), PowerManager (IOPMAssertion sleep control). The project uses `PBXFileSystemSynchronizedRootGroup` so Xcode auto-discovers new files in `CatLock/`.

**Tech Stack:** Swift 5, SwiftUI, AppKit (NSWindow), CoreGraphics (CGEvent), IOKit (IOPMAssertion). macOS 13+. No third-party dependencies.

**Important build note:** The project has `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, meaning all types are implicitly `@MainActor`. The CGEvent tap callback is a C function pointer and cannot capture `@MainActor`-isolated state directly — it must use `nonisolated` access patterns via `userInfo` pointer and `Unmanaged`.

---

### File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `CatLock/CatLockApp.swift` | **Rewrite** | MenuBarExtra entry, no WindowGroup |
| `CatLock/LockManager.swift` | **Rewrite** | Event tap, lock state, shortcut detection |
| `CatLock/OverlayManager.swift` | **Create** | Multi-screen NSWindow lifecycle |
| `CatLock/OverlayView.swift` | **Create** | SwiftUI overlay + unlock button + tips |
| `CatLock/AccessibilityHelper.swift` | **Create** | Permission check, alert, System Settings link |
| `CatLock/PowerManager.swift` | **Create** | IOPMAssertion create/release |
| `CatLock/ContentView.swift` | **Delete** | Unused |
| `CatLock.xcodeproj/project.pbxproj` | **Modify** | Add `INFOPLIST_KEY_LSUIElement = YES` |

---

### Task 1: Project Cleanup & LSUIElement Configuration

**Files:**
- Delete: `CatLock/ContentView.swift`
- Modify: `CatLock.xcodeproj/project.pbxproj` (Debug + Release target build settings)

- [ ] **Step 1: Delete unused ContentView.swift**

```bash
rm CatLock/ContentView.swift
```

- [ ] **Step 2: Add LSUIElement to build settings**

In `CatLock.xcodeproj/project.pbxproj`, add the following key to BOTH the Debug and Release `XCBuildConfiguration` sections for the **target** (the ones that contain `ASSETCATALOG_COMPILER_APPICON_NAME`):

```
INFOPLIST_KEY_LSUIElement = YES;
```

This tells macOS the app has no Dock icon (agent app / menu bar only).

- [ ] **Step 3: Build to verify project compiles**

```bash
cd /Users/hou.astro/Desktop/CatLock && xcodebuild -scheme CatLock -configuration Debug build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **` (will have errors because CatLockApp.swift references old code — that's expected at this point, just verify the pbxproj change didn't break the project structure)

Note: The build may fail because CatLockApp.swift still references `LockManager` and `MainView`. That is fine — we will rewrite those files in subsequent tasks. The goal here is just to confirm the pbxproj edit is valid.

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "chore: remove unused ContentView, add LSUIElement for menu bar app"
```

---

### Task 2: AccessibilityHelper

**Files:**
- Create: `CatLock/AccessibilityHelper.swift`

- [ ] **Step 1: Create AccessibilityHelper.swift**

```swift
import Cocoa

enum AccessibilityHelper {

    static func checkPermission() -> Bool {
        return AXIsProcessTrusted()
    }

    static func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    static func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "CatLock 需要辅助功能权限"
        alert.informativeText = "为了拦截键盘和鼠标输入，CatLock 需要辅助功能权限。请在系统设置中授权。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "打开系统设置")
        alert.addButton(withTitle: "取消")

        if alert.runModal() == .alertFirstButtonReturn {
            openAccessibilitySettings()
        }
    }

    private static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add CatLock/AccessibilityHelper.swift && git commit -m "feat: add AccessibilityHelper for permission check and alert"
```

---

### Task 3: PowerManager

**Files:**
- Create: `CatLock/PowerManager.swift`

- [ ] **Step 1: Create PowerManager.swift**

```swift
import IOKit.pwr_mgt

enum PowerManager {

    private static var assertionID: IOPMAssertionID = IOPMAssertionID(0)
    private static var assertionActive = false

    static func disableSleep() {
        guard !assertionActive else { return }
        let reason = "CatLock: keyboard locked, preventing sleep" as CFString
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &assertionID
        )
        if result == kIOReturnSuccess {
            assertionActive = true
        }
    }

    static func restoreSleep() {
        guard assertionActive else { return }
        IOPMAssertionRelease(assertionID)
        assertionActive = false
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add CatLock/PowerManager.swift && git commit -m "feat: add PowerManager for sleep prevention via IOPMAssertion"
```

---

### Task 4: OverlayView

**Files:**
- Create: `CatLock/OverlayView.swift`

- [ ] **Step 1: Create OverlayView.swift**

```swift
import SwiftUI

struct OverlayView: View {
    var onUnlock: () -> Void
    var onButtonFrameChange: (CGRect) -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                Button(action: onUnlock) {
                    VStack(spacing: 15) {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 50))
                        Text("点击解锁")
                            .font(.largeTitle)
                            .bold()
                    }
                    .padding(50)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(30)
                    .shadow(radius: 20)
                }
                .buttonStyle(.plain)
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear {
                                let frame = geo.frame(in: .global)
                                onButtonFrameChange(frame)
                            }
                            .onChange(of: geo.frame(in: .global)) { _, newFrame in
                                onButtonFrameChange(newFrame)
                            }
                    }
                )

                Spacer()

                VStack(spacing: 8) {
                    Text("系统将不会进入休眠，请确保任务运行期间电量充足。")
                        .font(.callout)
                        .foregroundColor(.white.opacity(0.7))

                    Text("按 Ctrl+Option+Command+L 解锁")
                        .font(.callout)
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.bottom, 40)
            }
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add CatLock/OverlayView.swift && git commit -m "feat: add OverlayView with unlock button, sleep warning, shortcut hint"
```

---

### Task 5: OverlayManager

**Files:**
- Create: `CatLock/OverlayManager.swift`

- [ ] **Step 1: Create OverlayManager.swift**

```swift
import Cocoa
import SwiftUI

class OverlayManager {

    private var windows: [NSWindow] = []
    var unlockButtonRects: [CGRect] = []
    var onUnlock: (() -> Void)?

    func showOverlays() {
        hideOverlays()
        unlockButtonRects.removeAll()

        for screen in NSScreen.screens {
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            window.level = .screenSaver
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = false
            window.ignoresMouseEvents = false
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

            let screenOrigin = screen.frame.origin
            let overlayView = OverlayView(
                onUnlock: { [weak self] in
                    self?.onUnlock?()
                },
                onButtonFrameChange: { [weak self] localFrame in
                    // Convert window-local frame to screen coordinates
                    let screenRect = CGRect(
                        x: screenOrigin.x + localFrame.origin.x,
                        y: screenOrigin.y + localFrame.origin.y,
                        width: localFrame.width,
                        height: localFrame.height
                    )
                    self?.updateButtonRect(for: window, rect: screenRect)
                }
            )
            window.contentView = NSHostingView(rootView: overlayView)
            window.setFrame(screen.frame, display: true)
            window.makeKeyAndOrderFront(nil)

            windows.append(window)
        }
    }

    func hideOverlays() {
        for window in windows {
            window.close()
        }
        windows.removeAll()
        unlockButtonRects.removeAll()
    }

    private func updateButtonRect(for window: NSWindow, rect: CGRect) {
        // Keep one rect per window — find and replace or append
        let index = windows.firstIndex(of: window)
        guard let idx = index else { return }
        if idx < unlockButtonRects.count {
            unlockButtonRects[idx] = rect
        } else {
            // Pad with .zero if needed, then set
            while unlockButtonRects.count <= idx {
                unlockButtonRects.append(.zero)
            }
            unlockButtonRects[idx] = rect
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add CatLock/OverlayManager.swift && git commit -m "feat: add OverlayManager for multi-screen overlay windows"
```

---

### Task 6: LockManager — Core Event Tap Logic

**Files:**
- Rewrite: `CatLock/LockManager.swift`

This is the most complex file. The CGEvent tap callback is a C function pointer, so it cannot capture Swift context directly. We pass `self` via `userInfo` and use `Unmanaged` to access it. The callback must be `nonisolated` (not on MainActor) because it's called from the CGEvent tap infrastructure.

- [ ] **Step 1: Rewrite LockManager.swift**

```swift
import Cocoa
import Combine

class LockManager: ObservableObject {

    static let shared = LockManager()

    @Published var isLocked = false
    @Published var hasAccessibility = false

    let overlayManager = OverlayManager()

    // Event tap state — accessed from the C callback via Unmanaged pointer.
    // These are only mutated on the main thread (lock/unlock), and read
    // from the event tap callback. The callback runs on the main RunLoop
    // (we add the source to CFRunLoopGetMain), so there is no data race.
    nonisolated(unsafe) var eventTap: CFMachPort?
    nonisolated(unsafe) var runLoopSource: CFRunLoopSource?

    private var localMonitor: Any?
    private var globalMonitor: Any?

    private init() {
        hasAccessibility = AccessibilityHelper.checkPermission()
        overlayManager.onUnlock = { [weak self] in
            self?.unlock()
        }
    }

    // MARK: - Shortcut Monitors (for unlocked state)

    func setupShortcutMonitors() {
        // Local: fires when CatLock itself is the active app
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.isLockShortcut(event) == true {
                self?.lock()
                return nil // swallow the event
            }
            return event
        }

        // Global: fires when another app is active
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.isLockShortcut(event) == true {
                self?.lock()
            }
        }
    }

    private func removeShortcutMonitors() {
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
    }

    private func isLockShortcut(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        return flags == [.control, .option, .command] && event.keyCode == 37
    }

    // MARK: - Lock / Unlock

    func lock() {
        guard !isLocked else { return }

        // Check accessibility
        hasAccessibility = AccessibilityHelper.checkPermission()
        if !hasAccessibility {
            AccessibilityHelper.showPermissionAlert()
            return
        }

        // 1. Create event tap
        guard createEventTap() else { return }

        // 2. Show overlays
        overlayManager.showOverlays()

        // 3. Prevent sleep
        PowerManager.disableSleep()

        isLocked = true
    }

    func unlock() {
        guard isLocked else { return }

        // 1. Destroy event tap
        destroyEventTap()

        // 2. Hide overlays
        overlayManager.hideOverlays()

        // 3. Restore sleep
        PowerManager.restoreSleep()

        isLocked = false
    }

    // MARK: - Event Tap

    private func createEventTap() -> Bool {
        let keyEvents = (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.keyUp.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)
        let mouseEvents = (1 << CGEventType.leftMouseDown.rawValue)
            | (1 << CGEventType.leftMouseUp.rawValue)
            | (1 << CGEventType.rightMouseDown.rawValue)
            | (1 << CGEventType.rightMouseUp.rawValue)
            | (1 << CGEventType.otherMouseDown.rawValue)
            | (1 << CGEventType.otherMouseUp.rawValue)
        let mask = CGEventMask(keyEvents | mouseEvents)

        let unmanagedSelf = Unmanaged.passUnretained(self).toOpaque()

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: eventTapCallback,
            userInfo: unmanagedSelf
        )

        guard let tap = eventTap else { return false }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        return true
    }

    private func destroyEventTap() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    // MARK: - Hit Testing

    /// Check if a CGEvent mouse location falls inside any unlock button rect.
    /// CGEvent uses top-left origin; NSScreen/SwiftUI use bottom-left origin.
    /// We convert the CG point to NS coordinates before comparing.
    nonisolated func isClickInsideUnlockButton(_ cgPoint: CGPoint) -> Bool {
        guard let mainScreen = NSScreen.screens.first else { return false }
        let screenHeight = mainScreen.frame.height
        // Convert CG (top-left origin) to NS (bottom-left origin)
        let nsPoint = CGPoint(x: cgPoint.x, y: screenHeight - cgPoint.y)
        for rect in overlayManager.unlockButtonRects {
            if rect.contains(nsPoint) {
                return true
            }
        }
        return false
    }
}

// MARK: - C Callback (free function, not a method)

/// The event tap callback. Runs on the main RunLoop thread.
/// - Returns the event to pass it through, or nil to swallow it.
private func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo = userInfo else { return Unmanaged.passUnretained(event) }
    let manager = Unmanaged<LockManager>.fromOpaque(userInfo).takeUnretainedValue()

    // Handle tap disabled by timeout — re-enable
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let tap = manager.eventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
        return Unmanaged.passUnretained(event)
    }

    // Keyboard events
    if type == .keyDown || type == .keyUp || type == .flagsChanged {
        // Check for unlock shortcut on keyDown
        if type == .keyDown {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            let flags = event.flags
            let hasControl = flags.contains(.maskControl)
            let hasOption = flags.contains(.maskAlternate)
            let hasCommand = flags.contains(.maskCommand)
            let hasShift = flags.contains(.maskShift)

            // Check Ctrl+Option+Command+L (without Shift)
            if hasControl && hasOption && hasCommand && !hasShift && keyCode == 37 {
                DispatchQueue.main.async {
                    manager.unlock()
                }
                return nil
            }
        }
        // Swallow all other keyboard events
        return nil
    }

    // Mouse click events — check if inside unlock button
    if type == .leftMouseDown || type == .leftMouseUp
        || type == .rightMouseDown || type == .rightMouseUp
        || type == .otherMouseDown || type == .otherMouseUp {
        let location = event.location
        if manager.isClickInsideUnlockButton(location) {
            return Unmanaged.passUnretained(event)
        }
        return nil // swallow clicks outside unlock button
    }

    // All other events — pass through
    return Unmanaged.passUnretained(event)
}
```

- [ ] **Step 2: Commit**

```bash
git add CatLock/LockManager.swift && git commit -m "feat: rewrite LockManager with CGEvent tap for keyboard+mouse interception"
```

---

### Task 7: CatLockApp — MenuBarExtra Entry Point

**Files:**
- Rewrite: `CatLock/CatLockApp.swift`

- [ ] **Step 1: Rewrite CatLockApp.swift**

```swift
import SwiftUI

@main
struct CatLockApp: App {
    @StateObject private var lockManager = LockManager.shared

    var body: some Scene {
        MenuBarExtra {
            MenuBarMenu(lockManager: lockManager)
        } label: {
            Image(systemName: lockManager.isLocked ? "lock.fill" : "lock.open.fill")
        }
    }
}

struct MenuBarMenu: View {
    @ObservedObject var lockManager: LockManager

    var body: some View {
        if lockManager.isLocked {
            Button("解锁") {
                lockManager.unlock()
            }
        } else {
            Button("锁定") {
                lockManager.lock()
            }
            .disabled(!lockManager.hasAccessibility)
        }

        Divider()

        Text("⌃⌥⌘L")
            .foregroundColor(.secondary)

        if !lockManager.hasAccessibility {
            Divider()
            Button("授权辅助功能权限...") {
                AccessibilityHelper.showPermissionAlert()
            }
        }

        Divider()

        Button("退出 CatLock") {
            NSApplication.shared.terminate(nil)
        }
    }
}
```

- [ ] **Step 2: Set up shortcut monitors on launch**

The `LockManager.init` already sets up the overlay callback. We need to call `setupShortcutMonitors()` when the app finishes launching. Add to `CatLockApp`:

```swift
@main
struct CatLockApp: App {
    @StateObject private var lockManager = LockManager.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarMenu(lockManager: lockManager)
        } label: {
            Image(systemName: lockManager.isLocked ? "lock.fill" : "lock.open.fill")
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        LockManager.shared.setupShortcutMonitors()
    }
}
```

The complete file should include `CatLockApp`, `AppDelegate`, and `MenuBarMenu` as shown above.

- [ ] **Step 3: Build the project**

```bash
cd /Users/hou.astro/Desktop/CatLock && xcodebuild -scheme CatLock -configuration Debug build 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

If there are compiler errors, fix them before proceeding. Common issues:
- `nonisolated(unsafe)` requires Swift 5.10+ — the project uses Swift 5.0, may need to use `@unchecked Sendable` or adjust isolation
- `onChange(of:)` two-parameter closure requires macOS 14+ — may need to use the single-parameter version

- [ ] **Step 4: Commit**

```bash
git add CatLock/CatLockApp.swift && git commit -m "feat: rewrite CatLockApp as MenuBarExtra with AppDelegate for shortcut setup"
```

---

### Task 8: Build, Fix Compiler Errors, Integration Test

**Files:**
- May modify any file from Tasks 1–7

- [ ] **Step 1: Full build**

```bash
cd /Users/hou.astro/Desktop/CatLock && xcodebuild -scheme CatLock -configuration Debug build 2>&1
```

Fix any compiler errors. Known potential issues:

1. **`nonisolated(unsafe)` not available in Swift 5.0**: Replace with wrapping the property access through a helper, or mark the class as `@unchecked Sendable` where needed.

2. **CGEventFlags manipulation in callback**: The flags checking code may need simplification. The correct pattern is:
```swift
let currentFlags = event.flags
let hasControl = currentFlags.contains(.maskControl)
let hasOption = currentFlags.contains(.maskAlternate)
let hasCommand = currentFlags.contains(.maskCommand)
let hasShift = currentFlags.contains(.maskShift)
if hasControl && hasOption && hasCommand && !hasShift && keyCode == 37 { ... }
```

3. **`onChange(of:)` API differences**: If targeting macOS 13, use the single-value onChange:
```swift
.onChange(of: geo.frame(in: .global)) { newFrame in
    onButtonFrameChange(newFrame)
}
```

- [ ] **Step 2: Fix all compiler errors and rebuild until BUILD SUCCEEDED**

- [ ] **Step 3: Run the app manually**

```bash
open /Users/hou.astro/Desktop/CatLock/build/Build/Products/Debug/CatLock.app
```

Or run from Xcode. Manual test checklist:

1. App launches with lock icon in menu bar, no Dock icon
2. Menu shows "锁定", shortcut hint, accessibility status, "退出 CatLock"
3. Click "锁定" → overlay appears on all screens, keyboard is blocked
4. Mouse pointer can move freely
5. Clicking anywhere except the unlock button does nothing
6. Click unlock button → overlay disappears, keyboard works again
7. Press Ctrl+Option+Command+L → locks
8. Press Ctrl+Option+Command+L again → unlocks
9. During lock, verify system does not sleep (check with `pmset -g assertions` in another terminal session)
10. After unlock, verify sleep assertion is released

- [ ] **Step 4: Commit any fixes**

```bash
git add -A && git commit -m "fix: resolve compiler errors and integration issues"
```

---

### Task 9: Coordinate System Fix & Button Hit-Test Verification

The coordinate system conversion between CGEvent (top-left origin), NSScreen (bottom-left origin), and SwiftUI (top-left within window) is the most likely source of bugs. This task specifically verifies and fixes it.

**Files:**
- May modify: `CatLock/LockManager.swift`, `CatLock/OverlayManager.swift`

- [ ] **Step 1: Add debug logging for button rect coordinates**

Temporarily add print statements to verify coordinate conversion:

In `OverlayManager.swift` `onButtonFrameChange` closure:
```swift
print("[CatLock] Button local frame: \(localFrame)")
print("[CatLock] Button screen rect: \(screenRect)")
```

In `LockManager.swift` `isClickInsideUnlockButton`:
```swift
print("[CatLock] Click CG point: \(cgPoint)")
print("[CatLock] Click NS point: \(nsPoint)")
print("[CatLock] Button rects: \(overlayManager.unlockButtonRects)")
```

- [ ] **Step 2: Run the app, click the unlock button, check console output**

Verify:
- The button rect is a reasonable rectangle (not zero, not full screen)
- The click NS point falls inside the button rect when you click the button
- The click NS point falls outside when you click elsewhere

If coordinates are wrong, the most likely fix is in the conversion logic. NSScreen frames have origin at bottom-left of the primary display. SwiftUI GeometryReader `.global` coordinate space has origin at top-left of the window.

The correct conversion from SwiftUI window-local to screen coordinates:
```swift
let windowFrame = window.frame
let screenRect = CGRect(
    x: windowFrame.origin.x + localFrame.origin.x,
    y: windowFrame.origin.y + windowFrame.height - localFrame.origin.y - localFrame.height,
    width: localFrame.width,
    height: localFrame.height
)
```

(SwiftUI's `.global` y increases downward from window top; NSScreen y increases upward from screen bottom.)

- [ ] **Step 3: Fix coordinate conversion if needed and verify button click works**

- [ ] **Step 4: Remove debug print statements**

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "fix: correct coordinate conversion for unlock button hit-testing"
```

---

### Task 10: Final Polish & Cleanup

**Files:**
- May modify any file

- [ ] **Step 1: Verify the complete flow end-to-end**

Run through the full test checklist from Task 8 Step 3 one more time after all fixes.

- [ ] **Step 2: Check for resource leaks**

Verify in `LockManager.unlock()`:
- Event tap is disabled, invalidated, source removed from RunLoop, references set to nil
- All overlay windows are closed and released
- IOPMAssertion is released

- [ ] **Step 3: Verify app exits cleanly**

Click "退出 CatLock" from menu bar. Verify:
- App exits (no zombie process)
- If locked when quitting, unlock first then quit — or add cleanup in `applicationWillTerminate`

If needed, add to `AppDelegate`:
```swift
func applicationWillTerminate(_ notification: Notification) {
    LockManager.shared.unlock()
}
```

- [ ] **Step 4: Final commit**

```bash
git add -A && git commit -m "chore: final cleanup and exit handling"
```
