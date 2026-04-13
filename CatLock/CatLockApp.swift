import SwiftUI

@main
struct CatLockApp: App {
    @StateObject private var lockManager = LockManager.shared
    @StateObject private var settings = SettingsManager.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Window(String(localized: "app_name"), id: "main") {
            MainWindowView(lockManager: lockManager, settings: settings)
        }
        .defaultSize(width: 320, height: 340)

        Window(String(localized: "settings_title"), id: "settings") {
            SettingsView()
        }
        .defaultSize(width: 400, height: 280)
        .windowResizability(.contentSize)

        MenuBarExtra {
            MenuBarMenu(lockManager: lockManager, settings: settings)
        } label: {
            Image(systemName: lockManager.isLocked ? "cat.fill" : "cat")
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        LockManager.shared.createShortcutTap()
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        LockManager.shared.prepareForTermination()
        return .terminateNow
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

// MARK: - Main Window

struct MainWindowView: View {
    @ObservedObject var lockManager: LockManager
    @ObservedObject var settings: SettingsManager
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 20) {
            // Cat icon
            Image(systemName: "cat.fill")
                .font(.system(size: 56))
                .foregroundColor(.terracotta)
                .padding(.top, 8)

            // App name
            Text(String(localized: "app_name"))
                .font(.system(.title, design: .serif))
                .fontWeight(.medium)
                .foregroundColor(.nearBlack)

            // Lock button
            Button(action: { lockManager.lock() }) {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                    Text(String(localized: "main_lock_button"))
                }
                .frame(width: 160)
                .padding(.vertical, 4)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .tint(.terracotta)
            .disabled(lockManager.isLocked || !lockManager.hasAccessibility)

            // Permission warning
            if !lockManager.hasAccessibility {
                Text(String(localized: "main_permission_warning"))
                    .font(.caption)
                    .foregroundColor(.red)
            }

            // Shortcut hint
            Text(String(localized: "main_shortcut_hint \(settings.shortcutSymbolString())"))
                .font(.caption)
                .foregroundColor(.stoneGray)

            Spacer().frame(height: 4)

            // Settings button
            Button(action: { openWindow(id: "settings") }) {
                HStack(spacing: 6) {
                    Image(systemName: "gearshape")
                    Text(String(localized: "settings_title"))
                }
            }
            .buttonStyle(.plain)
            .foregroundColor(.oliveGray)
            .font(.callout)
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.parchment)
    }
}

// MARK: - Menu Bar Menu

struct MenuBarMenu: View {
    @ObservedObject var lockManager: LockManager
    @ObservedObject var settings: SettingsManager
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        if lockManager.isLocked {
            Button(String(localized: "menu_unlock \(settings.shortcutSymbolString())")) {
                lockManager.unlock()
            }
        } else {
            Button(String(localized: "menu_lock \(settings.shortcutSymbolString())")) {
                lockManager.lock()
            }
            .disabled(!lockManager.hasAccessibility)
        }

        if !lockManager.hasAccessibility {
            Divider()
            Button(String(localized: "menu_grant_permission")) {
                AccessibilityHelper.showPermissionAlert()
            }
        }

        Divider()

        Button(String(localized: "settings_title")) {
            openWindow(id: "settings")
            NSApp.activate(ignoringOtherApps: true)
        }

        Divider()

        Button(String(localized: "menu_quit")) {
            LockManager.shared.prepareForTermination()
            NSApplication.shared.terminate(nil)
        }
    }
}
