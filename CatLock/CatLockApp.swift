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
        .defaultSize(width: 320, height: 400)
        .windowStyle(.hiddenTitleBar)

        Window(String(localized: "settings_title"), id: "settings") {
            SettingsView()
        }
        .defaultSize(width: 400, height: 280)
        .windowResizability(.contentSize)

        Window(String(localized: "about_title"), id: "about") {
            AboutView()
        }
        .defaultSize(width: 360, height: 380)
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)

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
            // Drag area to replace hidden title bar
            Color.clear.frame(height: 8)

            // Cat icon
            Image(systemName: "cat.fill")
                .font(.system(size: 56))
                .foregroundColor(.terracotta)

            // App name
            Text(String(localized: "app_name"))
                .font(.system(.title, design: .serif))
                .fontWeight(.medium)
                .foregroundColor(.nearBlack)

            if lockManager.hasAccessibility {
                // Lock button — custom style so it looks correct even when unfocused
                Button(action: { lockManager.lock() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                        Text(String(localized: "main_lock_button"))
                    }
                    .font(.body.weight(.medium))
                    .foregroundColor(.white)
                    .frame(width: 180)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(lockManager.isLocked ? Color.stoneGray : Color.terracotta)
                    )
                }
                .buttonStyle(.plain)
                .disabled(lockManager.isLocked)

                // Shortcut hint
                Text(String(localized: "main_shortcut_hint \(settings.shortcutSymbolString())"))
                    .font(.caption)
                    .foregroundColor(.stoneGray)
            } else {
                // Permission setup — shown when accessibility not granted
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.shield")
                        .font(.system(size: 28))
                        .foregroundColor(.terracotta)

                    Text(String(localized: "main_permission_warning"))
                        .font(.callout)
                        .foregroundColor(.nearBlack)
                        .multilineTextAlignment(.center)

                    Button(action: {
                        AccessibilityHelper.requestPermission()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "gear")
                            Text(String(localized: "permission_alert_open"))
                        }
                        .font(.body.weight(.medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.terracotta)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 8)
            }

            Spacer().frame(height: 4)

            // Bottom row: Settings + About
            HStack(spacing: 24) {
                Button(action: { openWindow(id: "settings") }) {
                    HStack(spacing: 6) {
                        Image(systemName: "gearshape")
                        Text(String(localized: "settings_title"))
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.oliveGray)
                .font(.callout)

                Button(action: { openWindow(id: "about") }) {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                        Text(String(localized: "about_title"))
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.oliveGray)
                .font(.callout)
            }

            Spacer().frame(height: 12)
        }
        .padding(.horizontal, 30)
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

        Button(String(localized: "menu_show_app")) {
            openWindow(id: "main")
            NSApp.activate(ignoringOtherApps: true)
        }

        Button(String(localized: "settings_title")) {
            openWindow(id: "settings")
            NSApp.activate(ignoringOtherApps: true)
        }

        Button(String(localized: "about_title")) {
            openWindow(id: "about")
            NSApp.activate(ignoringOtherApps: true)
        }

        Divider()

        Button(String(localized: "menu_quit")) {
            LockManager.shared.prepareForTermination()
            NSApplication.shared.terminate(nil)
        }
    }
}

// MARK: - About Window

struct AboutView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Drag area
            Color.clear.frame(height: 12)

            // App icon
            Image(systemName: "cat.fill")
                .font(.system(size: 44))
                .foregroundColor(.terracotta)

            Spacer().frame(height: 12)

            // App name
            Text("CatLock")
                .font(.system(.title2, design: .serif))
                .fontWeight(.medium)
                .foregroundColor(.nearBlack)

            // Credit
            Text("support @kvitroar")
                .font(.system(size: 11))
                .foregroundColor(.stoneGray)
                .padding(.top, 2)

            Spacer().frame(height: 24)

            // Quote
            VStack(spacing: 8) {
                Text(String(localized: "about_quote"))
                    .font(.system(size: 13, design: .serif))
                    .italic()
                    .foregroundColor(.oliveGray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                Text(String(localized: "about_quote_source"))
                    .font(.system(size: 11))
                    .foregroundColor(.stoneGray)
            }
            .padding(.horizontal, 30)

            Spacer()

            // Copyright
            Text("\u{00A9} 2026 kvitroar. All rights reserved.")
                .font(.system(size: 10))
                .foregroundColor(.stoneGray)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.parchment)
    }
}
