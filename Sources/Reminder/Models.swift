import Foundation

enum AlertTiming: String, Codable, CaseIterable {
    case atTime = "at"
    case oneBefore = "before"

    var label: String {
        switch self {
        case .atTime: return "At time"
        case .oneBefore: return "1 minute before"
        }
    }
}

struct Reminder: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var hour: Int       // 0–23
    var minute: Int
    var fireDate: Date
    var timing: AlertTiming
    var fired: Bool = false
    var fuego: Bool = false

    func formattedTime(use24hr: Bool) -> String {
        if use24hr {
            return String(format: "%02d:%02d", hour, minute)
        } else {
            let period = hour < 12 ? "AM" : "PM"
            let h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
            return String(format: "%d:%02d %@", h, minute, period)
        }
    }
}

class ReminderStore: ObservableObject {
    @Published var reminders: [Reminder] = []
    @Published var pendingAlert: Reminder?

    private let saveURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = dir.appendingPathComponent("Reminder")
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("reminders.json")
    }()

    init() {
        load()
        startTimer()
    }

    func add(name: String, hour: Int, minute: Int, timing: AlertTiming, fuego: Bool) {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: Date())
        comps.hour = hour
        comps.minute = minute
        comps.second = 0

        var fireDate = cal.date(from: comps) ?? Date()
        if timing == .oneBefore {
            fireDate = fireDate.addingTimeInterval(-60)
        }
        if fireDate <= Date() {
            fireDate = fireDate.addingTimeInterval(86400)
        }

        let reminder = Reminder(name: name, hour: hour, minute: minute, fireDate: fireDate, timing: timing, fuego: fuego)
        reminders.append(reminder)
        reminders.sort { $0.fireDate < $1.fireDate }
        save()
    }

    func update(id: UUID, name: String, hour: Int, minute: Int, timing: AlertTiming, fuego: Bool) {
        guard let i = reminders.firstIndex(where: { $0.id == id }) else { return }
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: Date())
        comps.hour = hour
        comps.minute = minute
        comps.second = 0
        var fireDate = cal.date(from: comps) ?? Date()
        if timing == .oneBefore { fireDate = fireDate.addingTimeInterval(-60) }
        if fireDate <= Date() { fireDate = fireDate.addingTimeInterval(86400) }
        reminders[i] = Reminder(id: id, name: name, hour: hour, minute: minute, fireDate: fireDate, timing: timing, fired: false, fuego: fuego)
        reminders.sort { $0.fireDate < $1.fireDate }
        save()
    }

    func delete(at offsets: IndexSet) {
        reminders.remove(atOffsets: offsets)
        save()
    }

    func delete(id: UUID) {
        reminders.removeAll { $0.id == id }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let decoded = try? JSONDecoder().decode([Reminder].self, from: data) else { return }
        reminders = decoded
    }

    private func save() {
        try? JSONEncoder().encode(reminders).write(to: saveURL)
    }

    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.checkReminders()
        }
    }

    private func checkReminders() {
        let now = Date()
        for i in reminders.indices {
            guard !reminders[i].fired else { continue }
            let delta = now.timeIntervalSince(reminders[i].fireDate)
            if delta >= 0 && delta < 10 {
                reminders[i].fired = true
                pendingAlert = reminders[i]
                save()
                break
            }
        }
    }
}
