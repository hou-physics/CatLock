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

    private var permissionTimer: Timer?

    private init() {
        hasAccessibility = AccessibilityHelper.checkPermission()
        overlayManager.onUnlock = { [weak self] in
            DispatchQueue.main.async {
                self?.unlock()
            }
        }
        // Periodically re-check accessibility permission (user may grant it in System Settings)
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            let granted = AccessibilityHelper.checkPermission()
            if granted != self.hasAccessibility {
                self.hasAccessibility = granted
            }
        }
    }

    // MARK: - Shortcut Monitors (for unlocked state)

    func setupShortcutMonitors() {
        // Local: fires when CatLock itself is the active app
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.isLockShortcut(event) == true {
                self?.lock()
                return nil
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

        hasAccessibility = AccessibilityHelper.checkPermission()
        if !hasAccessibility {
            AccessibilityHelper.showPermissionAlert()
            return
        }

        guard createEventTap() else { return }

        overlayManager.showOverlays()
        PowerManager.disableSleep()
        isLocked = true
    }

    func unlock() {
        guard isLocked else { return }

        destroyEventTap()
        overlayManager.hideOverlays()
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

// MARK: - C Callback (free function)

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
        if type == .keyDown {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            let flags = event.flags
            let hasControl = flags.contains(.maskControl)
            let hasOption = flags.contains(.maskAlternate)
            let hasCommand = flags.contains(.maskCommand)
            let hasShift = flags.contains(.maskShift)

            if hasControl && hasOption && hasCommand && !hasShift && keyCode == 37 {
                DispatchQueue.main.async {
                    manager.unlock()
                }
                return nil
            }
        }
        return nil
    }

    // Mouse click events — swallow ALL clicks, trigger unlock if in button area
    if type == .leftMouseDown || type == .leftMouseUp
        || type == .rightMouseDown || type == .rightMouseUp
        || type == .otherMouseDown || type == .otherMouseUp {
        // Only trigger unlock on mouseDown (not mouseUp) to avoid double-firing
        if type == .leftMouseDown {
            let location = event.location
            if manager.isClickInsideUnlockButton(location) {
                DispatchQueue.main.async {
                    manager.unlock()
                }
            }
        }
        return nil // swallow ALL mouse clicks
    }

    return Unmanaged.passUnretained(event)
}
