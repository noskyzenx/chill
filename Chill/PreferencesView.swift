import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var timer: SittingTimer

    @AppStorage("Chill.yellowThreshold") private var yellowThreshold: Int = 45 * 60
    @AppStorage("Chill.redThreshold") private var redThreshold: Int = 90 * 60
    @AppStorage("Chill.idleResetSeconds") private var idleResetSeconds: Int = 5 * 60

    var showHeader: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if showHeader {
                Text("Preferences")
                    .font(.headline)
                    .padding(.bottom, 10)
            }

            // Session first
            GroupBox("Session") {
                HoverableRow {
                    HStack {
                        Text("End session when idle for:")
                        Spacer()
                        Picker("", selection: Binding(
                            get: { idleResetSeconds / 60 },
                            set: { newMinutes in
                                idleResetSeconds = newMinutes * 60
                                timer.updateIdleReset(seconds: idleResetSeconds)
                            }
                        )) {
                            ForEach(idleOptions(), id: \.self) { minutes in
                                Text(formatMinutesToHoursAndMinutes(minutes)).tag(minutes)
                            }
                        }
                        .labelsHidden()
                        .frame(width: optionWidth)
                    }
                    .padding(6)
                }
            }

            // Color thresholds second
            GroupBox("Color thresholds") {
                VStack(alignment: .leading, spacing: 15) {
                    thresholdRow(
                        title: "Yellow at:",
                        selection: Binding(
                            get: { yellowThreshold / 60 },
                            set: { newMinutes in
                                yellowThreshold = newMinutes * 60
                                if redThreshold <= yellowThreshold { redThreshold = yellowThreshold + 15 * 60 }
                                timer.updateThresholds(yellow: yellowThreshold, red: redThreshold)
                            }
                        ),
                        options: yellowOptions()
                    )
                    thresholdRow(
                        title: "Red at:",
                        selection: Binding(
                            get: { redThreshold / 60 },
                            set: { newMinutes in
                                redThreshold = max((yellowThreshold / 60) + 15, newMinutes) * 60
                                timer.updateThresholds(yellow: yellowThreshold, red: redThreshold)
                            }
                        ),
                        options: redOptions(minYellow: yellowThreshold / 60)
                    )
                }
                .padding()
            }

            #if DEBUG
            GroupBox("Debug") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Simulate idle > threshold", isOn: $timer.debugSimulateIdle)
                    HStack(spacing: 10) {
                        Button("+5m") { timer.fastForward(by: 5 * 60) }
                        .buttonStyle(HoverButtonStyle())
                        Button("+15m") { timer.fastForward(by: 15 * 60) }
                        .buttonStyle(HoverButtonStyle())
                        Button("+1h") { timer.fastForward(by: 60 * 60) }
                        .buttonStyle(HoverButtonStyle())
                    }
                }
                .padding()
            }
            #endif
        }
        .onAppear {
            // Ensure model mirrors persisted defaults when view opens
            timer.updateThresholds(yellow: yellowThreshold, red: redThreshold)
            timer.updateIdleReset(seconds: idleResetSeconds)
        }
        .padding()
    }
}

private extension PreferencesView {
    func thresholdRow(title: String, selection: Binding<Int>, options: [Int]) -> some View {
        HoverableRow {
            HStack {
                Text(title)
                Spacer()
                Picker("", selection: selection) {
                    ForEach(options, id: \.self) { minutes in
                        Text(formatMinutesToHoursAndMinutes(minutes)).tag(minutes)
                    }
                }
                .labelsHidden()
                .frame(width: optionWidth)
            }
            .padding(6)
        }
    }

    func yellowOptions() -> [Int] {
        [15, 30, 45, 60]
    }

    func redOptions(minYellow: Int) -> [Int] {
        let start = minYellow + 15
        return Array(stride(from: start, to: 181, by: 15))
    }

    func idleOptions() -> [Int] { Array(1...10) }
    
    func formatMinutesToHoursAndMinutes(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        }
        let h = minutes / 60
        let m = minutes % 60
        if m == 0 {
            return "\(h)h"
        }
        return "\(h)h\(m)m"
    }
}

private struct HoverableRow<Content: View>: View {
    @State private var isHovered = false
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(isHovered ? Color.gray.opacity(0.15) : Color.clear)
            .cornerRadius(5)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isHovered = hovering
                }
            }
    }
}

struct HoverButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isHovered ? Color.gray.opacity(0.25) : Color.clear)
            .contentShape(Rectangle())
            .cornerRadius(5)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

private let optionWidth: CGFloat = 120