# Reminder

A full-screen reminder app for macOS built with Swift and SwiftUI. When a reminder fires, it takes over your entire screen so you can't miss it.

## Features

- Full-screen overlay alert at the scheduled time
- 12-hour and 24-hour clock support
- Alert 1 minute early option
- **Fuego mode** — instead of a dismiss button, a set of random words is displayed and you must type them correctly to close the alert
- Configurable Fuego word count (1–10) in Settings
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
3. Optionally check **Fuego** to require typing a set of random words to dismiss the alert
4. Click **Add**

When a reminder fires, the full-screen alert appears on top of everything. In standard mode, press Return or click Dismiss. In Fuego mode, type the displayed words into the text field — the alert closes automatically when they match.

### Settings

Open **Reminder > Settings** (or press `⌘,`) to configure:

- **Clock format** — 12-hour or 24-hour display
- **Fuego words** — how many words are required to dismiss a Fuego alert (1–10, default 3)

## Data

Reminders are saved to:

```
~/Library/Application Support/Reminder/reminders.json
```

## Project Structure

```
Sources/Reminder/
├── App.swift          — app entry point and delegate
├── Models.swift       — Reminder model, ReminderStore (persistence + timer)
├── ContentView.swift  — main window UI (form + reminder list)
├── AlertView.swift    — full-screen alert UI, Fuego word challenge
└── AlertWindow.swift  — NSWindow subclass for the full-screen overlay
```
