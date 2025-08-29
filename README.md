Chill — macOS Menu Bar Sitting Timer
===================================

Purpose
- Track how long you’ve been sitting. The menu bar shows a mm:ss (or hh:mm:ss) timer inside a color capsule that transitions from green → yellow/orange → red as time passes. If the system is idle (no keyboard/mouse) for more than 5 minutes, the session auto-resets to 00:00 on first input thereafter.

Highlights
- SwiftUI + AppKit (MenuBarExtra on macOS 13+).
- 1s tick with low-overhead `DispatchSourceTimer`.
- Idle detection using common HID events; ends current session after idle > N seconds (default 300), and starts a new session on input.
- Preferences for color thresholds (15/45 minutes by default) and idle reset.
- Start/Pause/Reset from the menu. Tooltips show “Sitting: Xm • Idle: Ym”.
- State persisted in `UserDefaults` (thresholds, idle reset, session state).
- Debug hooks (Debug build): simulate idle; fast-forward +5m/+15m/+1h.

Requirements
- macOS 13.0 or later (MenuBarExtra). The project sets LSUIElement to run as a menu bar–only app (no Dock icon).

Project Structure
- Xcode project: `chill.xcodeproj`
- Sources under `chill/`
  - `chillApp.swift`: App entry + MenuBarExtra label/menu
  - `SittingTimer.swift`: State machine, timer, idle detection, persistence
  - `ColorScale.swift`: Color interpolation utility
  - `StatusItemView.swift`: Menu bar label with capsule background
  - `PreferencesView.swift`: Thresholds + idle reset + debug tools
  - `Info.plist`, `Assets.xcassets`

Build & Run
1. Open `chill.xcodeproj` in Xcode 14+.
2. Select the `chill` scheme and run. The app appears in the menu bar as a time capsule.
3. By default, the timer starts immediately and increments every second.

Usage
- Start/Pause: Toggle from the menu.
- Reset: Sets the timer to 00:00 (if running, starts a fresh session from now; if paused, clears paused time).
- Preferences: Adjust thresholds and idle reset minutes. Values persist across launches.
- Idle session end: If idleSeconds > 300s (or your configured value), the current session ends and freezes; on first input a new session begins from 0.

Debug (Debug build only)
- Preferences → Debug:
  - Simulate idle > threshold: Forces idle state so you can verify auto-reset.
  - Fast-forward buttons: Adds elapsed time (+5m, +15m, +1h) to hit color thresholds quickly.

Acceptance Criteria Mapping
- Launch shows `00:00` with greenish background and increments every second.
- Leaving Mac untouched >5m: on first input, timer resets to `00:00` and color resets to green.
- Background color transitions smoothly from green → yellow/orange → red as elapsed crosses thresholds (defaults 15/45m). Thresholds are editable and persisted.
- Start/Pause/Reset are available in the menu. Quit and relaunch preserves preferences/state.

Notes & Known Limitations
- Minimum deployment is macOS 13 (MenuBarExtra). A legacy NSStatusBar fallback can be added for macOS 12 by introducing an NSStatusItem controller and hosting SwiftUI in the status item button.
- App icon is not required for a menu bar utility; Xcode may show a warning if an AppIcon is not set.
