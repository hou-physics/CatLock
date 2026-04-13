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
        alert.messageText = String(localized: "permission_alert_title")
        alert.informativeText = String(localized: "permission_alert_body")
        alert.alertStyle = .warning
        alert.addButton(withTitle: String(localized: "permission_alert_open"))
        alert.addButton(withTitle: String(localized: "permission_alert_cancel"))

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
