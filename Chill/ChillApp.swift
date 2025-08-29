import SwiftUI
import AppKit

@main
struct ChillApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var timer: SittingTimer

    init() {
        let t = SittingTimer()
        _timer = StateObject(wrappedValue: t)
        appDelegate.timer = t
    }

    var body: some Scene {
        Settings {
            PreferencesView()
                .environmentObject(timer)
                .frame(width: 360)
                .padding()
        }
    }
}

private struct MenuBarLabel: View {
    @EnvironmentObject var timer: SittingTimer

    var body: some View {
        StatusItemView(elapsedSeconds: timer.displayedElapsed,
                        idleSeconds: timer.idleSeconds,
                        thresholds: timer.thresholds)
            .help(timer.tooltip)
    }
}

private struct MenuContent: View {
    @EnvironmentObject var timer: SittingTimer

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "figure.seated.side")
                Text("Sitting: \(formatCompact(timer.displayedElapsed)) • Idle: \(formatMinutes(timer.idleSeconds))")
                    .font(.system(.body, design: .rounded))
            }
            .padding(.bottom, 2)

            HStack(spacing: 8) {
                if timer.state == .running {
                    Button {
                        timer.pause()
                    } label: {
                        Label("Pause", systemImage: "pause.fill")
                    }
                } else {
                    Button {
                        timer.start()
                    } label: {
                        Label("Start", systemImage: "play.fill")
                    }
                }

                Button(role: .destructive) {
                    timer.reset()
                } label: {
                    Label("Reset", systemImage: "gobackward")
                }
            }

            Divider()

            PreferencesView(showHeader: true)
                .environmentObject(timer)

            Divider()

            Button {
                NSApp.terminate(nil)
            } label: {
                Label("Quit Chill", systemImage: "power")
            }
        }
        .padding(12)
    }
}

func formatCompact(_ seconds: Int) -> String {
    if seconds < 60 { return "0m" }
    let totalMinutes = seconds / 60
    if totalMinutes < 60 { return "\(totalMinutes)m" }
    let h = totalMinutes / 60
    let m = totalMinutes % 60
    return m == 0 ? "\(h)h" : "\(h)h\(m)m"
}

func formatMinutes(_ seconds: Int) -> String {
    let m = seconds / 60
    return "\(m)m"
}
