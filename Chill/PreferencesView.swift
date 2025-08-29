// This is a new file, so there is no old code to replace.
import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var timer: SittingTimer

    @AppStorage("Chill.yellowThreshold") private var yellowThreshold: Int = 45*60
    @AppStorage("Chill.redThreshold") private var redThreshold: Int = 90*60
    @AppStorage("Chill.idleResetSeconds") private var idleResetSeconds: Int = 300

    var showHeader: Bool = false
    @State private var customYellowText: String = ""
    @State private var customRedText: String = ""
    @State private var customIdleText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showHeader {
                Text("Preferences")
                    .font(.headline)
            }

            // Session first
            GroupBox("Session") {
                VStack(alignment: .leading, spacing: 10) {
                    Text("End session when idle for:")
                    ClassicMenu(
                        title: "\(idleResetSeconds/60)m",
                        width: optionWidth,
                        options: idleOptions().map { "\($0)m" }
                    ) { label in
                        if let m = Int(label.dropLast()) {
                            idleResetSeconds = m * 60
                            timer.updateIdleReset(seconds: idleResetSeconds)
                        }
                    }
                    HStack(spacing: 8) {
                        Text("Custom (min):")
                        TextField("", text: $customIdleText)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 64)
                            .onSubmit { applyCustomIdle() }
                        Button("Set") { applyCustomIdle() }
                            .controlSize(.small)
                    }
                }
                .padding(6)
            }

            // Color thresholds second
            GroupBox("Color thresholds") {
                VStack(alignment: .leading, spacing: 10) {
                    thresholdRow(
                        title: "Yellow at:",
                        minutes: yellowThreshold / 60,
                        options: yellowOptions(),
                        onSelect: { m in
                            yellowThreshold = m * 60
                            if redThreshold <= yellowThreshold { redThreshold = yellowThreshold + 5*60 }
                            timer.updateThresholds(yellow: yellowThreshold, red: redThreshold)
                        }
                    )
                    HStack(spacing: 8) {
                        Text("Custom (min):")
                        TextField("", text: $customYellowText)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 64)
                            .onSubmit { applyCustomYellow() }
                        Button("Set") { applyCustomYellow() }
                            .controlSize(.small)
                    }
                    thresholdRow(
                        title: "Red at:",
                        minutes: redThreshold / 60,
                        options: redOptions(minYellow: yellowThreshold/60),
                        onSelect: { m in
                            redThreshold = max((yellowThreshold/60) + 5, m) * 60
                            timer.updateThresholds(yellow: yellowThreshold, red: redThreshold)
                        }
                    )
                    HStack(spacing: 8) {
                        Text("Custom (min):")
                        TextField("", text: $customRedText)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 64)
                            .onSubmit { applyCustomRed() }
                        Button("Set") { applyCustomRed() }
                            .controlSize(.small)
                    }
                }
                .padding(6)
            }

            #if DEBUG
            GroupBox("Debug") {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Simulate idle > threshold", isOn: $timer.debugSimulateIdle)
                    HStack(spacing: 8) {
                        Button("+5m") { timer.fastForward(by: 5*60) }
                        Button("+15m") { timer.fastForward(by: 15*60) }
                        Button("+1h") { timer.fastForward(by: 60*60) }
                    }
                }
                .padding(6)
            }
            #endif
        }
        .onAppear {
            // Ensure model mirrors persisted defaults when view opens
            timer.updateThresholds(yellow: yellowThreshold, red: redThreshold)
            timer.updateIdleReset(seconds: idleResetSeconds)
        }
    }
}

private extension PreferencesView {
    func thresholdRow(title: String, minutes: Int, options: [Int], onSelect: @escaping (Int) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
            ClassicMenu(
                title: "\(minutes)m",
                width: optionWidth,
                options: options.map { "\($0)m" }
            ) { label in
                if let m = Int(label.dropLast()) { onSelect(m) }
            }
        }
    }

    func yellowOptions() -> [Int] {
        [5,10,15,20,25,30,35,40,45,50,55,60,75,90,105,120,150,180,210,240]
    }

    func redOptions(minYellow: Int) -> [Int] {
        let start = max(minYellow + 5, 10)
        let base: [Int] = [start, start+5, start+10, start+15, start+20, start+25, start+30, start+45, start+60, start+90, start+120, start+180]
        return Array(Set(base)).sorted()
    }

    func idleOptions() -> [Int] { [1,2,3,5,10,15,20,30,45,60] }
}

private struct ClassicMenu: View {
    var title: String
    var width: CGFloat = 96
    var options: [String]
    var onSelect: (String) -> Void

    var body: some View {
        Menu {
            ForEach(options, id: \.self) { label in
                Button(label) { onSelect(label) }
            }
        } label: {
            ClassicButton(text: title, width: width)
        }
        .menuStyle(.borderlessButton)
    }
}

private let optionWidth: CGFloat = 120

// MARK: - Helpers
private extension PreferencesView {
    func applyCustomYellow() {
        guard let m = Int(customYellowText.trimmingCharacters(in: .whitespaces)), m >= 1 else { return }
        yellowThreshold = m * 60
        if redThreshold <= yellowThreshold { redThreshold = yellowThreshold + 5*60 }
        timer.updateThresholds(yellow: yellowThreshold, red: redThreshold)
        customYellowText = ""
    }

    func applyCustomRed() {
        guard let m = Int(customRedText.trimmingCharacters(in: .whitespaces)), m >= 1 else { return }
        redThreshold = max((yellowThreshold/60) + 5, m) * 60
        timer.updateThresholds(yellow: yellowThreshold, red: redThreshold)
        customRedText = ""
    }

    func applyCustomIdle() {
        guard let m = Int(customIdleText.trimmingCharacters(in: .whitespaces)), m >= 1 else { return }
        idleResetSeconds = m * 60
        timer.updateIdleReset(seconds: idleResetSeconds)
        customIdleText = ""
    }
}

private struct ClassicButton: View {
    let text: String
    let width: CGFloat
    @State private var isHover = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 5, style: .continuous)
        HStack(spacing: 6) {
            Text(text)
                .lineLimit(1)
                .truncationMode(.tail)
            Image(systemName: "chevron.up.chevron.down")
                .font(.caption2)
                .opacity(0.9)
        }
        .font(.system(size: 12, weight: .semibold, design: .rounded))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(width: width, alignment: .center)
        .background(
            ZStack {
                shape.fill(isHover ? Color.primary.opacity(0.1) : Color.clear)
                shape.stroke(Color.primary.opacity(0.2), lineWidth: 1)
            }
        )
        .animation(.easeInOut(duration: 0.15), value: isHover)
        .onHover { isHover = $0 }
        .contentShape(shape)
    }
}
