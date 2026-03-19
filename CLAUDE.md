# Reminder

Full-screen reminder app for macOS, built with Swift/SwiftUI.

## Build & Run

```bash
# Run from terminal
swift build -c release
.build/release/Reminder

# Build a distributable .app bundle
./build-app.sh
# → produces Reminder.app (double-click to open)
```

## Structure

- `Package.swift` — Swift Package Manager config, targets macOS 13+
- `Sources/Reminder/`
  - `App.swift` — app entry point, `NSApplicationDelegate`
  - `Models.swift` — `Reminder` model, `ReminderStore` (persistence + timer)
  - `ContentView.swift` — main window UI (add form + reminder list)
  - `AlertView.swift` — SwiftUI view shown inside the full-screen alert window; handles both standard and Fuego mode
  - `AlertWindow.swift` — `NSWindow` subclass that creates the full-screen overlay
  - `SettingsView.swift` — Settings window (clock format, Fuego word count)

## How It Works

- Reminders are saved to `~/Library/Application Support/Reminder/reminders.json`
- A `Timer` fires every 5 seconds to check if any reminder is due (within a 10-second window)
- When a reminder fires, `AlertWindow.swift` creates a borderless `NSWindow` at `.screenSaver` level covering the full screen
- The alert can be dismissed with the Dismiss button or the Return key
- Alert timing options: at the scheduled time, or 1 minute before

## Reminder Fields

- `name` — display label
- `hour` / `minute` — scheduled time (24-hour internally)
- `timing` — `.atTime` or `.oneBefore` (fires 1 minute early)
- `fuego` — bool; enables Fuego mode for that reminder

## Fuego Mode

When `fuego = true`, the alert shows N random words (configured in Settings, 1–10, default 3) and a text field. The alert dismisses only when the user types the words correctly (space-separated, case-insensitive). The text field receives focus automatically.

## Settings (`@AppStorage` keys)

- `use24hr` — bool, clock display format
- `fuegoWordCount` — int (1–10), number of words required in Fuego mode
