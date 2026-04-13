import Cocoa
import SwiftUI

class OverlayManager {

    private var windows: [NSWindow] = []
    nonisolated(unsafe) var unlockButtonRects: [CGRect] = []
    var onUnlock: (() -> Void)?

    func showOverlays() {
        hideOverlays()
        unlockButtonRects.removeAll()

        for screen in NSScreen.screens {
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            window.level = .screenSaver
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = false
            window.ignoresMouseEvents = false
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

            let screenOrigin = screen.frame.origin
            let overlayView = OverlayView(
                onUnlock: { [weak self] in
                    self?.onUnlock?()
                },
                onButtonFrameChange: { [weak self] localFrame in
                    // Convert window-local frame to screen coordinates
                    let screenRect = CGRect(
                        x: screenOrigin.x + localFrame.origin.x,
                        y: screenOrigin.y + localFrame.origin.y,
                        width: localFrame.width,
                        height: localFrame.height
                    )
                    self?.updateButtonRect(for: window, rect: screenRect)
                }
            )
            window.contentView = NSHostingView(rootView: overlayView)
            window.setFrame(screen.frame, display: true)
            window.makeKeyAndOrderFront(nil)

            windows.append(window)
        }
    }

    func hideOverlays() {
        for window in windows {
            window.close()
        }
        windows.removeAll()
        unlockButtonRects.removeAll()
    }

    private func updateButtonRect(for window: NSWindow, rect: CGRect) {
        // Keep one rect per window — find and replace or append
        let index = windows.firstIndex(of: window)
        guard let idx = index else { return }
        if idx < unlockButtonRects.count {
            unlockButtonRects[idx] = rect
        } else {
            // Pad with .zero if needed, then set
            while unlockButtonRects.count <= idx {
                unlockButtonRects.append(.zero)
            }
            unlockButtonRects[idx] = rect
        }
    }
}
