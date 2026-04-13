import Cocoa
import Combine

class LockManager: ObservableObject {

    static let shared = LockManager()

    @Published var isLocked = false
    @Published var hasAccessibility = false

    let overlayManager = OverlayManager()

    // Always-on shortcut tap (listenOnly) — detects shortcut in any app
    nonisolated(unsafe) var shortcutTap: CFMachPort?
    nonisolated(unsafe) var shortcutRunLoopSource: CFRunLoopSource?

    // Lock event tap (defaultTap) — swallows all input when locked
    nonisolated(unsafe) var lockEventTap: CFMachPort?
    nonisolated(unsafe) var lockRunLoopSource: CFRunLoopSource?

    private var permissionTimer: Timer?

    private init() {
        hasAccessibility = AccessibilityHelper.checkPermission()
        overlayManager.onUnlock = { [weak self] in
            DispatchQueue.main.async {
                self?.unlock()
            }
        }
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            let granted = AccessibilityHelper.checkPermission()
            if granted != self.hasAccessibility {
                self.hasAccessibility = granted
            }
        }
    }

    // MARK: - Always-On Shortcut Tap

    func createShortcutTap() {
        guard hasAccessibility else { return }
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        let unmanagedSelf = Unmanaged.passUnretained(self).toOpaque()

        shortcutTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: shortcutTapCallback,
            userInfo: unmanagedSelf
        )

        guard let tap = shortcutTap else { return }
        shortcutRunLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), shortcutRunLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    private func destroyShortcutTap() {
        if let tap = shortcutTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        if let source = shortcutRunLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        shortcutTap = nil
        shortcutRunLoopSource = nil
    }

    // MARK: - Termination Cleanup

    func prepareForTermination() {
        destroyLockEventTap()
        destroyShortcutTap()
        permissionTimer?.invalidate()
        permissionTimer = nil
        isLocked = false
        overlayManager.hideOverlays()
        PowerManager.restoreSleep()
    }

    // MARK: - Lock / Unlock

    func lock() {
        guard !isLocked else { return }

        hasAccessibility = AccessibilityHelper.checkPermission()
        if !hasAccessibility {
            AccessibilityHelper.showPermissionAlert()
            return
        }

        // Ensure shortcut tap is running (may not be if permission was just granted)
        if shortcutTap == nil {
            createShortcutTap()
        }

        guard createLockEventTap() else { return }

        overlayManager.showOverlays()
        PowerManager.disableSleep()
        isLocked = true
    }

    func unlock() {
        guard isLocked else { return }

        destroyLockEventTap()
        PowerManager.restoreSleep()
        isLocked = false

        DispatchQueue.main.async { [overlayManager] in
            overlayManager.hideOverlays()
        }
    }

    // MARK: - Lock Event Tap

    private func createLockEventTap() -> Bool {
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

        lockEventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: lockEventTapCallback,
            userInfo: unmanagedSelf
        )

        guard let tap = lockEventTap else { return false }

        lockRunLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), lockRunLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        return true
    }

    private func destroyLockEventTap() {
        if let tap = lockEventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        if let source = lockRunLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        lockEventTap = nil
        lockRunLoopSource = nil
    }

    // MARK: - Hit Testing

    nonisolated func isClickInsideUnlockButton(_ cgPoint: CGPoint) -> Bool {
        guard let mainScreen = NSScreen.screens.first else { return false }
        let screenHeight = mainScreen.frame.height
        let nsPoint = CGPoint(x: cgPoint.x, y: screenHeight - cgPoint.y)
        for rect in overlayManager.unlockButtonRects {
            if rect.contains(nsPoint) {
                return true
            }
        }
        return false
    }
}

// MARK: - Shortcut Tap Callback (always-on, listenOnly)

private func shortcutTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo = userInfo else { return Unmanaged.passUnretained(event) }
    let manager = Unmanaged<LockManager>.fromOpaque(userInfo).takeUnretainedValue()

    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let tap = manager.shortcutTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
        return Unmanaged.passUnretained(event)
    }

    if type == .keyDown && SettingsManager.shared.matchesCGEvent(event) {
        DispatchQueue.main.async {
            if manager.isLocked {
                manager.unlock()
            } else {
                manager.lock()
            }
        }
    }

    // listenOnly — always pass the event through
    return Unmanaged.passUnretained(event)
}

// MARK: - Lock Event Tap Callback (active only when locked)

private func lockEventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo = userInfo else { return Unmanaged.passUnretained(event) }
    let manager = Unmanaged<LockManager>.fromOpaque(userInfo).takeUnretainedValue()

    if !manager.isLocked {
        return Unmanaged.passUnretained(event)
    }

    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let tap = manager.lockEventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
        return Unmanaged.passUnretained(event)
    }

    // Keyboard events — swallow all except the unlock shortcut
    if type == .keyDown || type == .keyUp || type == .flagsChanged {
        if type == .keyDown && SettingsManager.shared.matchesCGEvent(event) {
            DispatchQueue.main.async {
                manager.unlock()
            }
            return nil
        }
        return nil
    }

    // Mouse events — swallow all, check unlock button on mouseDown
    if type == .leftMouseDown || type == .leftMouseUp
        || type == .rightMouseDown || type == .rightMouseUp
        || type == .otherMouseDown || type == .otherMouseUp {
        if type == .leftMouseDown {
            let location = event.location
            if manager.isClickInsideUnlockButton(location) {
                DispatchQueue.main.async {
                    manager.unlock()
                }
            }
        }
        return nil
    }

    return Unmanaged.passUnretained(event)
}
