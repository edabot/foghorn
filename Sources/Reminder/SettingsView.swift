import SwiftUI

struct SettingsView: View {
    @AppStorage("use24hr") private var use24hr = false
    @AppStorage("fuegoWordCount") private var fuegoWordCount = 3
    @AppStorage("alertCountdown") private var alertCountdown = 5

    var body: some View {
        Form {
            Picker("Clock format", selection: $use24hr) {
                Text("12-hour  (2:30 PM)").tag(false)
                Text("24-hour  (14:30)").tag(true)
            }
            .pickerStyle(.radioGroup)

            Picker("Fuego words", selection: $fuegoWordCount) {
                ForEach(1...10, id: \.self) { n in
                    Text("\(n)").tag(n)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: 160)

            Picker("Dismiss countdown", selection: $alertCountdown) {
                ForEach(0...20, id: \.self) { n in
                    Text(n == 0 ? "None" : "\(n)s").tag(n)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: 160)
        }
        .padding(24)
        .frame(width: 320)
    }
}
