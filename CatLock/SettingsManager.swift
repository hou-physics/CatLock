import Cocoa
import Combine

class SettingsManager: ObservableObject {

    static let shared = SettingsManager()

    // MARK: - Published Settings

    @Published var shortcutKeyCode: UInt16 {
        didSet { UserDefaults.standard.set(Int(shortcutKeyCode), forKey: "catlock.shortcut.keyCode") }
    }

    @Published var shortcutModifierRawValue: UInt {
        didSet { UserDefaults.standard.set(shortcutModifierRawValue, forKey: "catlock.shortcut.modifiers") }
    }

    @Published var privacyMode: Bool {
        didSet { UserDefaults.standard.set(privacyMode, forKey: "catlock.privacy.mode") }
    }

    // MARK: - Defaults

    static let defaultKeyCode: UInt16 = 37          // L key
    static let defaultModifiers: UInt = NSEvent.ModifierFlags([.command, .shift]).rawValue

    // MARK: - Computed

    var shortcutModifiers: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: shortcutModifierRawValue)
    }

    var shortcutCGFlags: (command: Bool, shift: Bool, control: Bool, option: Bool) {
        let mods = shortcutModifiers
        return (
            command: mods.contains(.command),
            shift: mods.contains(.shift),
            control: mods.contains(.control),
            option: mods.contains(.option)
        )
    }

    // MARK: - Init

    private init() {
        let defaults = UserDefaults.standard

        if defaults.object(forKey: "catlock.shortcut.keyCode") != nil {
            self.shortcutKeyCode = UInt16(defaults.integer(forKey: "catlock.shortcut.keyCode"))
        } else {
            self.shortcutKeyCode = Self.defaultKeyCode
        }

        if defaults.object(forKey: "catlock.shortcut.modifiers") != nil {
            self.shortcutModifierRawValue = UInt(defaults.integer(forKey: "catlock.shortcut.modifiers"))
        } else {
            self.shortcutModifierRawValue = Self.defaultModifiers
        }

        self.privacyMode = defaults.bool(forKey: "catlock.privacy.mode")
    }

    // MARK: - Actions

    func resetToDefaults() {
        shortcutKeyCode = Self.defaultKeyCode
        shortcutModifierRawValue = Self.defaultModifiers
        privacyMode = false
    }

    func shortcutDisplayString() -> String {
        var parts: [String] = []
        let mods = shortcutModifiers
        if mods.contains(.control) { parts.append("Ctrl") }
        if mods.contains(.option)  { parts.append("Opt") }
        if mods.contains(.shift)   { parts.append("Shift") }
        if mods.contains(.command) { parts.append("Cmd") }
        parts.append(keyCodeToString(shortcutKeyCode))
        return parts.joined(separator: "+")
    }

    func shortcutSymbolString() -> String {
        var s = ""
        let mods = shortcutModifiers
        if mods.contains(.control) { s += "\u{2303}" }
        if mods.contains(.option)  { s += "\u{2325}" }
        if mods.contains(.shift)   { s += "\u{21E7}" }
        if mods.contains(.command) { s += "\u{2318}" }
        s += keyCodeToString(shortcutKeyCode)
        return s
    }

    func matchesCGEvent(_ event: CGEvent) -> Bool {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        guard keyCode == Int64(shortcutKeyCode) else { return false }

        let flags = event.flags
        let expected = shortcutCGFlags

        let hasCommand = flags.contains(.maskCommand)
        let hasShift = flags.contains(.maskShift)
        let hasControl = flags.contains(.maskControl)
        let hasOption = flags.contains(.maskAlternate)

        return hasCommand == expected.command
            && hasShift == expected.shift
            && hasControl == expected.control
            && hasOption == expected.option
    }

    // MARK: - Key Code Mapping

    private func keyCodeToString(_ keyCode: UInt16) -> String {
        let map: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 37: "L",
            38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/",
            45: "N", 46: "M", 47: ".",
            36: "Return", 48: "Tab", 49: "Space", 51: "Delete", 53: "Esc",
            96: "F5", 97: "F6", 98: "F7", 99: "F3", 100: "F8",
            101: "F9", 109: "F10", 103: "F11", 111: "F12",
            118: "F4", 120: "F2", 122: "F1",
            123: "\u{2190}", 124: "\u{2192}", 125: "\u{2193}", 126: "\u{2191}",
        ]
        return map[keyCode] ?? "Key\(keyCode)"
    }
}
