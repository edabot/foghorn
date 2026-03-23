import SwiftUI
import AppKit

// MARK: - Time input field that blocks invalid characters before they appear

struct TimeTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var use24hr: Bool

    func makeNSView(context: Context) -> NSTextField {
        let tf = NSTextField()
        tf.placeholderString = placeholder
        tf.bezelStyle = .roundedBezel
        tf.isBordered = true
        tf.backgroundColor = .textBackgroundColor
        tf.font = .systemFont(ofSize: NSFont.systemFontSize)
        tf.delegate = context.coordinator
        return tf
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
        context.coordinator.parent = self
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: TimeTextField

        init(_ parent: TimeTextField) { self.parent = parent }

        // Fires after text changes — directly fix the field editor string in the same
        // run loop iteration so AppKit coalesces both changes into one display pass.
        func controlTextDidChange(_ obj: Notification) {
            guard let tf = obj.object as? NSTextField,
                  let textView = tf.currentEditor() as? NSTextView else { return }
            let current = textView.string
            let filtered = filter(current)
            if filtered != current {
                let sel = textView.selectedRange()
                textView.string = filtered
                let loc = min(sel.location, filtered.utf16.count)
                textView.setSelectedRange(NSRange(location: loc, length: 0))
            }
            parent.text = filtered
        }

        // Filter: only digits + at most one colon after a valid hour, max 2 digits each side
        private func filter(_ s: String) -> String {
            var result = ""
            var hourDigits = 0
            var colonSeen = false
            var minDigits = 0
            for c in s {
                if c.isNumber {
                    if !colonSeen {
                        if hourDigits < 2 { result.append(c); hourDigits += 1 }
                    } else {
                        if minDigits < 2 { result.append(c); minDigits += 1 }
                    }
                } else if c == ":" && !colonSeen {
                    if let hour = Int(result) {
                        let valid = parent.use24hr ? 0...23 : 1...12
                        if valid.contains(hour) { result.append(c); colonSeen = true }
                    }
                }
            }
            return result
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var store: ReminderStore
    @AppStorage("use24hr") private var use24hr = false

    @State private var name = ""
    @State private var timeStr = ""
    @State private var ampm = Calendar.current.component(.hour, from: Date()) < 12 ? "AM" : "PM"
    @State private var timing: AlertTiming = .atTime
    @State private var fuego = false
    @State private var errorMsg = ""
    @State private var editingID: UUID? = nil

    private var isEditing: Bool { editingID != nil }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                Color(red: 0.1, green: 0.1, blue: 0.18)
                Text("Reminders")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(height: 56)

            // Form
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Name")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        TextField("Meeting, appointment…", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 210)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(use24hr ? "Time (HH:MM)" : "Time (H:MM)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        HStack(spacing: 6) {
                            TimeTextField(text: $timeStr,
                                          placeholder: use24hr ? "14:30" : "2:30",
                                          use24hr: use24hr)
                                .frame(width: 70, height: 22)
                            if !use24hr {
                                Picker("", selection: $ampm) {
                                    Text("AM").tag("AM")
                                    Text("PM").tag("PM")
                                }
                                .labelsHidden()
                                .frame(width: 60)
                            }
                        }
                    }

                    VStack(spacing: 6) {
                        Spacer()
                        Button(action: commitForm) {
                            Text(isEditing ? "Save" : "Add")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(isEditing ? Color.blue : Color(red: 0.91, green: 0.27, blue: 0.38))
                        if isEditing {
                            Button("Cancel", action: resetForm)
                                .font(.system(size: 12))
                                .buttonStyle(.plain)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(height: isEditing ? 68 : 52)
                }

                HStack(spacing: 20) {
                    Picker("Alert", selection: $timing) {
                        ForEach(AlertTiming.allCases, id: \.self) { t in
                            Text(t.label).tag(t)
                        }
                    }
                    .pickerStyle(.radioGroup)
                    .horizontalRadioGroupLayout()

                    Spacer()

                    Toggle(isOn: $fuego) {
                        Text("Fuego")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .toggleStyle(.checkbox)

                    Button("Test") {
                        let now = Date()
                        let nowComps = Calendar.current.dateComponents([.hour, .minute], from: now)
                        let parts = timeStr.split(separator: ":")
                        let scheduledHour: Int?
                        let scheduledMinute: Int?
                        if parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]) {
                            scheduledHour = use24hr ? h : (ampm == "PM" ? (h == 12 ? 12 : h + 12) : (h == 12 ? 0 : h))
                            scheduledMinute = m
                        } else if parts.count == 1, let h = Int(parts[0]) {
                            scheduledHour = use24hr ? h : (ampm == "PM" ? (h == 12 ? 12 : h + 12) : (h == 12 ? 0 : h))
                            scheduledMinute = 0
                        } else {
                            scheduledHour = nil
                            scheduledMinute = nil
                        }
                        let fake = Reminder(
                            name: name.trimmingCharacters(in: .whitespaces).isEmpty ? "Test" : name.trimmingCharacters(in: .whitespaces),
                            hour: scheduledHour ?? nowComps.hour ?? 0,
                            minute: scheduledMinute ?? nowComps.minute ?? 0,
                            fireDate: now,
                            timing: .atTime,
                            fuego: fuego
                        )
                        showAlertWindow(for: fake, use24hr: use24hr) {}
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                }

                if !errorMsg.isEmpty {
                    Text(errorMsg)
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.91, green: 0.27, blue: 0.38))
                }
            }
            .padding(16)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // List
            VStack(alignment: .leading, spacing: 8) {
                Text("Upcoming")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .padding(.bottom, 2)

                if store.reminders.isEmpty {
                    Text("No reminders yet.")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ForEach(store.reminders) { reminder in
                        ReminderRow(
                            reminder: reminder,
                            use24hr: use24hr,
                            isBeingEdited: editingID == reminder.id,
                            onEdit: { startEditing($0) }
                        )
                        .environmentObject(store)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 460, height: 500)
        .onChange(of: store.pendingAlert) { alert in
            guard let alert else { return }
            showAlertWindow(for: alert, use24hr: use24hr) {
                store.pendingAlert = nil
            }
        }
    }

    private func startEditing(_ reminder: Reminder) {
        editingID = reminder.id
        name = reminder.name
        timing = reminder.timing
        fuego = reminder.fuego
        errorMsg = ""
        if use24hr {
            timeStr = reminder.minute == 0
                ? "\(reminder.hour)"
                : String(format: "%02d:%02d", reminder.hour, reminder.minute)
        } else {
            let h = reminder.hour == 0 ? 12 : (reminder.hour > 12 ? reminder.hour - 12 : reminder.hour)
            ampm = reminder.hour < 12 ? "AM" : "PM"
            timeStr = reminder.minute == 0 ? "\(h)" : String(format: "%d:%02d", h, reminder.minute)
        }
    }

    private func resetForm() {
        editingID = nil
        name = ""
        timeStr = ""
        ampm = Calendar.current.component(.hour, from: Date()) < 12 ? "AM" : "PM"
        timing = .atTime
        fuego = false
        errorMsg = ""
    }

    private func commitForm() {
        errorMsg = ""
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { errorMsg = "Please enter a name."; return }

        let parts = timeStr.split(separator: ":")
        let rawHour: Int
        let minute: Int
        if parts.count == 1, let h = Int(parts[0]) {
            rawHour = h; minute = 0
        } else if parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]), (0...59).contains(m) {
            rawHour = h; minute = m
        } else {
            errorMsg = use24hr ? "Time must be HH:MM or HH (e.g. 14 or 14:30)." : "Time must be H:MM or H (e.g. 2 or 2:30)."
            return
        }

        let hour: Int
        if use24hr {
            guard (0...23).contains(rawHour) else { errorMsg = "Hour must be 0–23."; return }
            hour = rawHour
        } else {
            guard (1...12).contains(rawHour) else { errorMsg = "Hour must be 1–12."; return }
            hour = ampm == "AM" ? (rawHour == 12 ? 0 : rawHour) : (rawHour == 12 ? 12 : rawHour + 12)
        }

        if let id = editingID {
            store.update(id: id, name: trimmedName, hour: hour, minute: minute, timing: timing, fuego: fuego)
        } else {
            store.add(name: trimmedName, hour: hour, minute: minute, timing: timing, fuego: fuego)
        }
        resetForm()
    }
}

struct ReminderRow: View {
    @EnvironmentObject var store: ReminderStore
    let reminder: Reminder
    let use24hr: Bool
    let isBeingEdited: Bool
    let onEdit: (Reminder) -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(reminder.name)
                    .font(.system(size: 14, weight: .semibold))
                HStack(spacing: 4) {
                    Text("\(reminder.formattedTime(use24hr: use24hr))  ·  \(reminder.timing.label)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    if reminder.fuego {
                        Text("🔥")
                            .font(.system(size: 11))
                    }
                }
            }
            Spacer()
            if reminder.fired {
                Text("Done")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.15))
                    .clipShape(Capsule())
            }
            Button { onEdit(reminder) } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isBeingEdited ? .blue : .secondary)
            }
            .buttonStyle(.plain)
            .padding(.leading, 8)

            Button { store.delete(id: reminder.id) } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.leading, 6)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(isBeingEdited ? Color.blue.opacity(0.07) : Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isBeingEdited ? Color.blue.opacity(0.4) : Color.clear, lineWidth: 1)
        )
    }
}
