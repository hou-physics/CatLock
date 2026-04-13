import SwiftUI

struct OverlayView: View {
    var onUnlock: () -> Void
    var onButtonFrameChange: (CGRect) -> Void
    var isPrivacyMode: Bool

    var body: some View {
        ZStack {
            // Background — full black in privacy mode, semi-transparent otherwise
            Color.black.opacity(isPrivacyMode ? 1.0 : 0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                // Cat icon
                Image(systemName: "cat.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.terracotta.opacity(0.8))
                    .padding(.bottom, 10)

                // Unlock button
                Button(action: onUnlock) {
                    VStack(spacing: 12) {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 40))
                        Text(String(localized: "overlay_unlock"))
                            .font(.system(.title2, design: .serif))
                            .fontWeight(.medium)
                    }
                    .padding(40)
                    .background(Color.ivory)
                    .foregroundColor(.nearBlack)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.15), radius: 20)
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

                // Hints — directly below unlock button
                VStack(spacing: 6) {
                    Text(String(localized: "overlay_sleep_warning"))
                        .font(.callout)
                        .foregroundColor(.white.opacity(0.7))

                    Text(String(localized: "overlay_shortcut_hint \(SettingsManager.shared.shortcutDisplayString())"))
                        .font(.callout)
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.top, 16)

                Spacer()
            }
        }
    }
}
