import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var timer: SittingTimer

    @AppStorage("Chill.yellowThreshold") private var yellowThreshold: Int = 45*60
    @AppStorage("Chill.redThreshold") private var redThreshold: Int = 90*60
    @AppStorage("Chill.idleResetSeconds") private var idleResetSeconds: Int = 300

    var showHeader: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showHeader {
                Text("Preferences")
                    .font(.headline)
            }

            // Session first
            GroupBox("Session") {
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
                            Text("\(minutes)m").tag(minutes)
                        }
                    }
                    .labelsHidden()
                    .frame(width: optionWidth)
                }
                .padding(6)
            }

            // Color thresholds second
            GroupBox("Color thresholds") {
                VStack(alignment: .leading, spacing: 10) {
                    thresholdRow(
                        title: "Yellow at:",
                        selection: Binding(
                            get: { yellowThreshold / 60 },
                            set: { newMinutes in
                                yellowThreshold = newMinutes * 60
                                if redThreshold <= yellowThreshold { redThreshold = yellowThreshold + 5*60 }
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
                                redThreshold = max((yellowThreshold/60) + 5, newMinutes) * 60
                                timer.updateThresholds(yellow: yellowThreshold, red: redThreshold)
                            }
                        ),
                        options: redOptions(minYellow: yellowThreshold/60)
                    )
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
    func thresholdRow(title: String, selection: Binding<Int>, options: [Int]) -> some View {
        HStack {
            Text(title)
            Spacer()
            Picker("", selection: selection) {
                ForEach(options, id: \.self) { minutes in
                    Text("\(minutes)m").tag(minutes)
                }
            }
            .labelsHidden()
            .frame(width: optionWidth)
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

private let optionWidth: CGFloat = 96


