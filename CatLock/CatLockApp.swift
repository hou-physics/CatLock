import SwiftUI

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

    func applicationWillTerminate(_ notification: Notification) {
        LockManager.shared.unlock()
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
