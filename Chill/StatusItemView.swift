import SwiftUI

struct StatusItemView: View {
    var elapsedSeconds: Int
    var idleSeconds: Int
    var thresholds: SittingTimer.Thresholds

    var body: some View {
        let color = ColorScale.colorFor(elapsedSeconds: elapsedSeconds, thresholds: thresholds)
        Text(formatCompact(elapsedSeconds))
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(color.opacity(0.92))
            )
            .foregroundStyle(.white)
            .shadow(color: Color.black.opacity(0.15), radius: 1, x: 0, y: 1)
            .padding(.horizontal, 4)
            .animation(.easeInOut(duration: 0.25), value: elapsedSeconds)
    }
}
