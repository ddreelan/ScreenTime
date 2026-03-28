import SwiftUI

struct SplashView: View {
    @State private var ringProgress: CGFloat = 0
    @State private var textOpacity: Double = 0

    var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(red: 0.05, green: 0.1, blue: 0.25)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // Animated ring (matches TimeRingView style)
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 20)

                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(
                            Color.blue,
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    Image(systemName: "hourglass")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
                .frame(width: 140, height: 140)

                // App name and tagline
                VStack(spacing: 8) {
                    Text("ScreenTime")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)

                    Text("Take control of your time")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                .opacity(textOpacity)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0)) {
                ringProgress = 1.0
            }
            withAnimation(.easeIn(duration: 0.8)) {
                textOpacity = 1.0
            }
        }
    }
}
