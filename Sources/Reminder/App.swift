import SwiftUI
import AppKit

@main
struct ReminderApp: App {
    @StateObject private var store = ReminderStore()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .onAppear { appDelegate.store = store }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }

        MenuBarExtra {
            MenuBarMenuContent()
                .environmentObject(store)
        } label: {
            Image(systemName: "bell.fill")
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
        }
    }
}

struct MenuBarMenuContent: View {
    @EnvironmentObject var store: ReminderStore
    @AppStorage("use24hr") private var use24hr = false

    private var next: Reminder? {
        store.reminders.first(where: { !$0.fired })
    }

    var body: some View {
        if let reminder = next {
            Text(reminder.name)
                .font(.headline)
            Text(reminder.formattedTime(use24hr: use24hr))
                .foregroundColor(.secondary)
            Text(timeUntil(reminder.fireDate))
                .foregroundColor(.secondary)
        } else {
            Text("No upcoming reminders")
                .foregroundColor(.secondary)
        }

        Divider()

        Button("Open Reminders") {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows.first(where: { !($0 is AlertNSWindow) && $0.canBecomeMain })?
                .makeKeyAndOrderFront(nil)
        }

        Divider()

        Button("Quit") { NSApp.terminate(nil) }
    }

    private func timeUntil(_ date: Date) -> String {
        let mins = Int(date.timeIntervalSinceNow / 60)
        if mins <= 0 { return "Now" }
        if mins < 60 { return "in \(mins)m" }
        let h = mins / 60; let m = mins % 60
        return m == 0 ? "in \(h)h" : "in \(h)h \(m)m"
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var store: ReminderStore?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
