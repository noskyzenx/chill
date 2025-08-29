# Chill - Your Minimalist Sitting Timer for macOS

Chill is a subtle yet powerful menu bar application for macOS designed to help you be more mindful of your sitting time. It tracks how long you've been at your desk and provides a gentle, color-coded reminder to take a break.

![Chill Screenshot](https://user-images.githubusercontent.com/12345/67890.png) <!--- Placeholder for a screenshot -->

## Features

*   **Minimalist Menu Bar UI:** A simple timer in your menu bar that stays out of your way.
*   **Color-Coded Timer:** The timer's background color changes from green to yellow to red as your sitting time increases, giving you a quick visual cue.
*   **Automatic Idle Detection:** Chill automatically detects when you're away from your computer and resets the timer for your next session.
*   **Customizable Thresholds:** You can easily customize the time thresholds for the color changes to fit your personal goals.
*   **Start, Pause, and Reset:** Control the timer directly from the menu bar.
*   **Lightweight and Efficient:** Chill is a native Swift application with minimal resource usage.
*   **Persistence:** Your settings and timer state are saved across app launches.

## How to Use

1.  **Launch Chill:** The timer will appear in your menu bar and start counting up immediately.
2.  **Monitor Your Sitting Time:** The timer shows the elapsed time, and the color will change as you reach your defined thresholds.
3.  **Control the Timer:** Click the timer in the menu bar to reveal options to pause, start, or reset the timer.
4.  **Automatic Reset:** If you're idle for a configurable amount of time, the timer will automatically reset when you become active again.

## Customization

You can customize Chill's behavior through the **Preferences** window:

*   **Yellow at:** Set the time when the timer turns yellow. (Options: 15m, 30m, 45m, 60m)
*   **Red at:** Set the time when the timer turns red. (Options: 30m to 180m in 15m increments)
*   **End session when idle for:** Configure how long you need to be idle before the session automatically ends. (Options: 1m to 10m)

## Building from Source

1.  Clone this repository.
2.  Open `Chill.xcodeproj` in Xcode.
3.  Select the `Chill` scheme and run the application.

## Contributions

Contributions are welcome! If you have ideas for new features or improvements, feel free to open an issue or submit a pull request.