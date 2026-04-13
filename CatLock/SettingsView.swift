import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = SettingsManager.shared
    @State private var isRecording = false
    @State private var recordingText = ""
    @State private var keyMonitor: Any?

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            Text(String(localized: "settings_title"))
                .font(.system(.title2, design: .serif))
                .fontWeight(.medium)
                .foregroundColor(.nearBlack)

            // Shortcut section
            VStack(alignment: .leading, spacing: 12) {
                Text(String(localized: "shortcut_label"))
                    .font(.headline)
                    .foregroundColor(.nearBlack)

                HStack(spacing: 12) {
                    // Shortcut display
                    Text(isRecording ? recordingText : settings.shortcutDisplayString())
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .frame(minWidth: 140)
                        .background(Color.ivory)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isRecording ? Color.terracotta : Color.borderCream, lineWidth: 1)
                        )

                    // Record button
                    Button(action: toggleRecording) {
                        Text(isRecording
                             ? String(localized: "shortcut_stop")
                             : String(localized: "shortcut_record"))
                            .frame(width: 70)
                    }
                    .controlSize(.regular)

                    // Reset button
                    Button(String(localized: "shortcut_reset")) {
                        settings.resetToDefaults()
                    }
                    .controlSize(.regular)
                }
            }

            Divider()

            // Privacy mode section
            VStack(alignment: .leading, spacing: 8) {
                Toggle(isOn: $settings.privacyMode) {
                    Text(String(localized: "privacy_label"))
                        .font(.headline)
                        .foregroundColor(.nearBlack)
                }

                Text(String(localized: "privacy_description"))
                    .font(.caption)
                    .foregroundColor(.stoneGray)
            }

            Spacer()
        }
        .padding(24)
        .frame(width: 400, height: 280)
        .background(Color.parchment)
        .onDisappear {
            stopRecording()
        }
    }

    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            isRecording = true
            recordingText = String(localized: "shortcut_recording")
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                return handleRecordingKeyEvent(event)
            }
        }
    }

    private func stopRecording() {
        isRecording = false
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }

    private func handleRecordingKeyEvent(_ event: NSEvent) -> NSEvent? {
        // Escape cancels recording
        if event.keyCode == 53 {
            stopRecording()
            return nil
        }

        let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        // Must have at least one modifier
        guard !mods.intersection([.command, .control, .option, .shift]).isEmpty else {
            return nil
        }

        // Must be a non-modifier key (not just Shift/Cmd/etc alone)
        let modifierKeyCodes: Set<UInt16> = [54, 55, 56, 57, 58, 59, 60, 61, 62, 63]
        guard !modifierKeyCodes.contains(event.keyCode) else {
            return nil
        }

        // Valid shortcut — save it
        settings.shortcutKeyCode = event.keyCode
        settings.shortcutModifierRawValue = mods.rawValue
        stopRecording()

        return nil
    }
}
