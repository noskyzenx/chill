import Foundation
import Combine
import CoreGraphics

final class SittingTimer: ObservableObject {
    enum TimerState: String, Codable { case running, paused, idle }

    struct Thresholds: Equatable, Codable {
        var yellow: Int // seconds
        var red: Int    // seconds
    }

    // MARK: - Published state
    @Published private(set) var state: TimerState = .running
    @Published private(set) var displayedElapsed: Int = 0
    @Published private(set) var idleSeconds: Int = 0
    @Published private(set) var thresholds: Thresholds = .init(yellow: 15*60, red: 45*60)
    @Published var idleResetSeconds: Int = 300

    // Debug hooks
    @Published var debugSimulateIdle: Bool = false

    // MARK: - Internal
    private var sessionStart: Date?
    private var pausedElapsed: Int = 0
    private var timer: DispatchSourceTimer?

    // MARK: - Defaults
    private let defaults = UserDefaults.standard
    private enum Keys {
        static let yellow = "Chill.yellowThreshold"
        static let red = "Chill.redThreshold"
        static let idleReset = "Chill.idleResetSeconds"
        static let state = "Chill.state"
        static let sessionStart = "Chill.sessionStart" // timeIntervalSince1970 (Double)
        static let pausedElapsed = "Chill.pausedElapsed"
    }

    // MARK: - Init
    init() {
        // Register sensible defaults
        defaults.register(defaults: [
            Keys.yellow: 45*60,
            Keys.red: 90*60,
            Keys.idleReset: 300,
            Keys.state: TimerState.running.rawValue,
            Keys.pausedElapsed: 0
        ])

        // Load persisted preferences
        let y = defaults.integer(forKey: Keys.yellow)
        let r = defaults.integer(forKey: Keys.red)
        thresholds = .init(yellow: y, red: r)
        idleResetSeconds = defaults.integer(forKey: Keys.idleReset)

        // Load persisted state
        if let stateRaw = defaults.string(forKey: Keys.state), let s = TimerState(rawValue: stateRaw) {
            state = s
        }
        pausedElapsed = max(0, defaults.integer(forKey: Keys.pausedElapsed))
        if let epoch = defaults.object(forKey: Keys.sessionStart) as? Double {
            sessionStart = Date(timeIntervalSince1970: epoch)
        }

        // Ensure a session start exists if running
        if state == .running && sessionStart == nil {
            let now = Date()
            sessionStart = now
            defaults.set(now.timeIntervalSince1970, forKey: Keys.sessionStart)
        }

        // Initialize displayedElapsed from persisted values
        switch state {
        case .running:
            if let start = sessionStart { displayedElapsed = max(0, Int(Date().timeIntervalSince(start))) }
        case .paused:
            displayedElapsed = pausedElapsed
        case .idle:
            displayedElapsed = 0
        }

        startTicking()
    }

    // MARK: - Public API
    var isRunning: Bool { state == .running }

    var tooltip: String {
        let idleM = idleSeconds / 60
        return "Sitting: \(formatCompact(displayedElapsed)) • Idle: \(idleM)m"
    }

    func updateThresholds(yellow: Int, red: Int) {
        let y = max(60, yellow)
        let r = max(y + 60, red)
        thresholds = .init(yellow: y, red: r)
        defaults.set(y, forKey: Keys.yellow)
        defaults.set(r, forKey: Keys.red)
    }

    func updateIdleReset(seconds: Int) {
        idleResetSeconds = max(60, seconds)
        defaults.set(idleResetSeconds, forKey: Keys.idleReset)
    }

    func start() {
        switch state {
        case .running:
            return
        case .paused:
            let start = Date().addingTimeInterval(TimeInterval(-pausedElapsed))
            sessionStart = start
            defaults.set(start.timeIntervalSince1970, forKey: Keys.sessionStart)
            state = .running
            defaults.set(state.rawValue, forKey: Keys.state)
        case .idle:
            let start = Date()
            sessionStart = start
            defaults.set(start.timeIntervalSince1970, forKey: Keys.sessionStart)
            state = .running
            defaults.set(state.rawValue, forKey: Keys.state)
        }
    }

    func pause() {
        guard state != .paused else { return }
        pausedElapsed = displayedElapsed
        defaults.set(pausedElapsed, forKey: Keys.pausedElapsed)
        sessionStart = nil
        defaults.removeObject(forKey: Keys.sessionStart)
        state = .paused
        defaults.set(state.rawValue, forKey: Keys.state)
    }

    func reset() {
        displayedElapsed = 0
        switch state {
        case .running:
            let start = Date()
            sessionStart = start
            defaults.set(start.timeIntervalSince1970, forKey: Keys.sessionStart)
        case .paused:
            pausedElapsed = 0
            defaults.set(0, forKey: Keys.pausedElapsed)
        case .idle:
            // Nothing extra; remain idle showing 00:00
            break
        }
    }

    func fastForward(by seconds: Int) {
        guard seconds != 0 else { return }
        switch state {
        case .running:
            if let start = sessionStart {
                let newStart = start.addingTimeInterval(TimeInterval(-seconds))
                sessionStart = newStart
                defaults.set(newStart.timeIntervalSince1970, forKey: Keys.sessionStart)
                displayedElapsed = max(0, Int(Date().timeIntervalSince(newStart)))
            }
        case .paused:
            pausedElapsed = max(0, pausedElapsed + seconds)
            displayedElapsed = pausedElapsed
            defaults.set(pausedElapsed, forKey: Keys.pausedElapsed)
        case .idle:
            // remain idle at 0
            break
        }
    }

    // MARK: - Timer
    private func startTicking() {
        let t = DispatchSource.makeTimerSource(queue: .main)
        t.schedule(deadline: .now(), repeating: .seconds(1), leeway: .milliseconds(200))
        t.setEventHandler { [weak self] in
            self?.tick()
        }
        t.resume()
        timer = t
    }

    private func tick() {
        // Update idle: seconds since last user input (approx by min across common HID event types)
        let realIdle = Int(systemIdleSeconds())
        let simulated = debugSimulateIdle ? (idleResetSeconds + 1) : nil
        let idle = simulated ?? realIdle
        if idleSeconds != idle { idleSeconds = idle }

        // End session after prolonged idle; start a new one on user activity
        if state != .paused {
            if idle >= idleResetSeconds {
                if state != .idle {
                    state = .idle
                    defaults.set(state.rawValue, forKey: Keys.state)
                    // Freeze the displayed elapsed at the moment session ended
                    sessionStart = nil
                    defaults.removeObject(forKey: Keys.sessionStart)
                }
            } else if state == .idle {
                // User input resumed after idle → begin a new session
                let start = Date()
                sessionStart = start
                defaults.set(start.timeIntervalSince1970, forKey: Keys.sessionStart)
                state = .running
                defaults.set(state.rawValue, forKey: Keys.state)
            }
        }

        // Advance the timer
        switch state {
        case .running:
            if let start = sessionStart {
                let newElapsed = max(0, Int(Date().timeIntervalSince(start)))
                if displayedElapsed != newElapsed { displayedElapsed = newElapsed }
            }
        case .paused:
            // hold displayedElapsed
            break
        case .idle:
            // keep displayedElapsed frozen
            break
        }
    }

    private func systemIdleSeconds() -> Double {
        let types: [CGEventType] = [
            .mouseMoved, .leftMouseDown, .rightMouseDown, .otherMouseDown,
            .leftMouseDragged, .rightMouseDragged, .otherMouseDragged,
            .scrollWheel, .keyDown, .flagsChanged
        ]
        var minInterval = CGEventSource.secondsSinceLastEventType(.hidSystemState, eventType: .mouseMoved)
        for t in types {
            let v = CGEventSource.secondsSinceLastEventType(.hidSystemState, eventType: t)
            if v < minInterval { minInterval = v }
        }
        return max(0, minInterval)
    }
}
