# Reminder

A full-screen reminder app for macOS built with Swift and SwiftUI. When a reminder fires, it takes over your entire screen so you can't miss it.

## Features

- Full-screen overlay alert always on the primary display
- Light and dark mode support
- 12-hour and 24-hour clock support
- Alert at the scheduled time or 1 minute early
- Menu bar icon showing the next upcoming reminder and time remaining — app stays running when the main window is closed
- **Fuego mode** — instead of a dismiss button, random words are shown and you must type them correctly to dismiss
- Configurable dismiss countdown (0–20s) before the button or text field becomes active
- Reminders persist across launches

## Requirements

- macOS 13 or later
- Swift 5.9+ / Xcode 15+

## Build & Run

```bash
# Build and run directly
swift build -c release
.build/release/Reminder

# Build a distributable .app bundle
./build-app.sh
```

## Usage

1. Enter a name and time in the form
2. Choose whether to alert at the scheduled time or 1 minute before
3. Optionally check **Fuego** to require typing random words to dismiss
4. Click **Add**

When a reminder fires, the full-screen alert appears on the primary display on top of everything. In standard mode, press Return or click Dismiss. In Fuego mode, type the displayed words into the text field — the alert closes automatically when they match.

Use the **Test** button to trigger the alert immediately using the current form values.

### Settings

Open **Reminder > Settings** (or press `⌘,`) to configure:

- **Clock format** — 12-hour or 24-hour display
- **Fuego words** — how many words are required to dismiss a Fuego alert (1–10, default 3)
- **Dismiss countdown** — seconds before the dismiss button or Fuego field becomes active (0–20, default 5)

## Data

Reminders are saved to:

```
~/Library/Application Support/Reminder/reminders.json
```

## Project Structure

```
Sources/Reminder/
├── App.swift          — app entry point, delegate, and menu bar
├── Models.swift       — Reminder model, ReminderStore (persistence + timer)
├── ContentView.swift  — main window UI (form + reminder list)
├── AlertView.swift    — full-screen alert UI, Fuego word challenge
├── AlertWindow.swift  — NSWindow subclass for the full-screen overlay
└── SettingsView.swift — Settings window (clock format, Fuego word count, countdown)
```
