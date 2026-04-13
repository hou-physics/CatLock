import SwiftUI

struct OverlayView: View {
    var onUnlock: () -> Void
    var onButtonFrameChange: (CGRect) -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                Button(action: onUnlock) {
                    VStack(spacing: 15) {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 50))
                        Text("点击解锁")
                            .font(.largeTitle)
                            .bold()
                    }
                    .padding(50)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(30)
                    .shadow(radius: 20)
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

                Spacer()

                VStack(spacing: 8) {
                    Text("系统将不会进入休眠，请确保任务运行期间电量充足。")
                        .font(.callout)
                        .foregroundColor(.white.opacity(0.7))

                    Text("按 Ctrl+Option+Command+L 解锁")
                        .font(.callout)
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.bottom, 40)
            }
        }
    }
}
