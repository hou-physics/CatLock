import SwiftUI

@main
struct CatLockApp: App {
    @StateObject private var lockManager = LockManager.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Main window — shown on launch, closing it hides to background
        Window("CatLock", id: "main") {
            MainWindowView(lockManager: lockManager)
        }
        .defaultSize(width: 300, height: 200)

        // Menu bar icon
        MenuBarExtra {
            MenuBarMenu(lockManager: lockManager)
        } label: {
            Image(systemName: lockManager.isLocked ? "lock.fill" : "lock.open.fill")
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        LockManager.shared.createShortcutTap()
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Clean up BEFORE windows start closing — this prevents the event tap
        // from blocking the termination sequence and causing a spinning cursor.
        LockManager.shared.prepareForTermination()
        return .terminateNow
    }

    // Closing the window should not quit the app
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

// MARK: - Main Window

struct MainWindowView: View {
    @ObservedObject var lockManager: LockManager

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)

            Text("CatLock")
                .font(.title)
                .bold()

            Button(action: { lockManager.lock() }) {
                Text("锁定键盘")
                    .frame(width: 120)
            }
            .controlSize(.large)
            .disabled(lockManager.isLocked || !lockManager.hasAccessibility)

            if !lockManager.hasAccessibility {
                Text("请先授权辅助功能权限")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            Text("⌃⌥⌘L 快捷键锁定/解锁")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(30)
    }
}

// MARK: - Menu Bar Menu

struct MenuBarMenu: View {
    @ObservedObject var lockManager: LockManager

    var body: some View {
        if lockManager.isLocked {
            Button("解锁  ⌃⌥⌘L") {
                lockManager.unlock()
            }
        } else {
            Button("锁定  ⌃⌥⌘L") {
                lockManager.lock()
            }
            .disabled(!lockManager.hasAccessibility)
        }

        if !lockManager.hasAccessibility {
            Divider()
            Button("授权辅助功能权限...") {
                AccessibilityHelper.showPermissionAlert()
            }
        }

        Divider()

        Button("退出 CatLock") {
            LockManager.shared.prepareForTermination()
            NSApplication.shared.terminate(nil)
        }
    }
}
