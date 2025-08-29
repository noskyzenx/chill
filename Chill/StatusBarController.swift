import AppKit
import SwiftUI
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    var timer: SittingTimer?
    private var statusController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let timer else { return }
        statusController = StatusBarController(timer: timer)
    }
}

final class StatusBarController: NSObject, NSMenuDelegate {
    private let timer: SittingTimer
    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    private var cancellables = Set<AnyCancellable>()
    private var hosting: NSHostingView<StatusBarSwiftUILabel>?
    private var preferencesWC: NSWindowController?

    init(timer: SittingTimer) {
        self.timer = timer
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        if let button = statusItem.button {
            let hosting = NSHostingView(rootView: StatusBarSwiftUILabel(timer: timer))
            self.hosting = hosting
            hosting.translatesAutoresizingMaskIntoConstraints = false
            button.addSubview(hosting)
            NSLayoutConstraint.activate([
                hosting.leadingAnchor.constraint(equalTo: button.leadingAnchor),
                hosting.trailingAnchor.constraint(equalTo: button.trailingAnchor),
                hosting.topAnchor.constraint(equalTo: button.topAnchor),
                hosting.bottomAnchor.constraint(equalTo: button.bottomAnchor)
            ])
            button.toolTip = timer.tooltip
            DispatchQueue.main.async { [weak self] in self?.updateLength() }
        }

        // Build menu
        menu.delegate = self
        statusItem.menu = menu

        // Update tooltip when values change
        timer.$displayedElapsed
            .combineLatest(timer.$idleSeconds)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, _ in
                guard let self else { return }
                self.statusItem.button?.toolTip = timer.tooltip
                self.updateLength()
            }
            .store(in: &cancellables)
    }

    // MARK: - Menu
    func menuNeedsUpdate(_ menu: NSMenu) {
        rebuildMenu()
    }

    private func rebuildMenu() {
        menu.removeAllItems()

        // Header
        let header = NSMenuItem()
        let headerView = NSHostingView(rootView: headerSwiftUIView())
        headerView.frame = NSRect(x: 0, y: 0, width: 280, height: 28)
        header.view = headerView
        menu.addItem(header)
        menu.addItem(.separator())

        // Start/Pause
        let toggle = NSMenuItem(title: timer.isRunning ? "Pause" : "Start", action: #selector(toggleStartPause), keyEquivalent: "")
        toggle.target = self
        menu.addItem(toggle)

        // Reset
        let reset = NSMenuItem(title: "Reset", action: #selector(doReset), keyEquivalent: "")
        reset.target = self
        menu.addItem(reset)

        menu.addItem(.separator())

        // Preferences
        let prefs = NSMenuItem(title: "Preferences…", action: #selector(showPreferences), keyEquivalent: ",")
        prefs.keyEquivalentModifierMask = [.command]
        prefs.target = self
        menu.addItem(prefs)

        // Quit
        let quit = NSMenuItem(title: "Quit Chill", action: #selector(quit), keyEquivalent: "q")
        quit.keyEquivalentModifierMask = [.command]
        quit.target = self
        menu.addItem(quit)
    }

    private func headerSwiftUIView() -> some View {
        HStack(spacing: 6) {
            Image(systemName: "figure.seated.side")
            Text("Sitting: \(formatCompact(timer.displayedElapsed)) • Idle: \(timer.idleSeconds/60)m")
        }
        .font(.system(size: 12, weight: .regular, design: .rounded))
        .padding(.horizontal, 8)
    }

    // MARK: - Actions
    @objc private func toggleStartPause() { timer.isRunning ? timer.pause() : timer.start() }
    @objc private func doReset() { timer.reset() }
    @objc private func showPreferences() {
        if preferencesWC == nil {
            preferencesWC = makePreferencesWindow()
        }
        if let wc = preferencesWC {
            wc.showWindow(nil)
            wc.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    @objc private func quit() { NSApp.terminate(nil) }
}

// SwiftUI view used inside NSStatusItem button
private struct StatusBarSwiftUILabel: View {
    @ObservedObject var timer: SittingTimer

    var body: some View {
        StatusItemView(
            elapsedSeconds: timer.displayedElapsed,
            idleSeconds: timer.idleSeconds,
            thresholds: timer.thresholds
        )
        .help(timer.tooltip)
    }
}

private extension StatusBarController {
    func updateLength() {
        guard let hosting else { return }
        hosting.layoutSubtreeIfNeeded()
        let size = hosting.fittingSize
        // Add a couple of pixels padding to avoid clipping
        statusItem.length = max(24, size.width + 2)
    }

    func makePreferencesWindow() -> NSWindowController {
        let root = PreferencesView().environmentObject(timer)
        let vc = NSHostingController(rootView: root)
        let window = NSWindow(contentViewController: vc)
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.title = "Chill Preferences"
        window.setContentSize(NSSize(width: 380, height: 320))
        window.center()
        window.isReleasedWhenClosed = false
        let wc = NSWindowController(window: window)
        return wc
    }
}
