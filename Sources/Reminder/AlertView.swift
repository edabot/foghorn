import SwiftUI
import AppKit

private let wordList: [String] = [
    "apple", "brave", "cloud", "dance", "eagle", "frost", "grace", "honey",
    "ivory", "jolly", "kneel", "lemon", "maple", "noble", "ocean", "piano",
    "quiet", "river", "stone", "tiger", "ultra", "vivid", "waltz", "xenon",
    "yacht", "zebra", "amber", "blaze", "cider", "dwell", "ember", "fable",
    "gloom", "haste", "inlet", "joust", "karma", "lunar", "mirth", "nifty",
    "orbit", "plume", "quirk", "radar", "snake", "thorn", "umbra", "vapor",
    "wheat", "exile", "young", "zonal"
]

private func randomWords(count: Int = 3) -> [String] {
    var pool = wordList
    var chosen: [String] = []
    for _ in 0..<min(count, pool.count) {
        let i = Int.random(in: 0..<pool.count)
        chosen.append(pool[i])
        pool.remove(at: i)
    }
    return chosen
}

struct AlertView: View {
    let reminder: Reminder
    let use24hr: Bool
    let onDismiss: () -> Void

    @AppStorage("fuegoWordCount") private var fuegoWordCount = 3
    @AppStorage("alertCountdown") private var alertCountdown = 5
    @State private var countdown = 0
    @State private var typed = ""
    @State private var words: [String] = []
    @FocusState private var fieldFocused: Bool

    private var target: String { words.joined(separator: " ") }
    private var accent: Color { Color(red: 0.91, green: 0.27, blue: 0.38) }

    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.18)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 28) {
                    Text("REMINDER")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .tracking(6)
                        .foregroundColor(accent)

                    Text(reminder.name)
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.35)
                        .lineLimit(3)
                        .padding(.horizontal, 80)

                    Text(reminder.formattedTime(use24hr: use24hr))
                        .font(.system(size: 40, weight: .light, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.5))
                }

                Spacer()

                if reminder.fuego {
                    fuegoSection
                } else {
                    VStack(spacing: 16) {
                        if countdown > 0 {
                            Text("\(countdown)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.5))
                                .monospacedDigit()
                                .frame(height: 60)
                        } else {
                            Button(action: onDismiss) {
                                Text("Dismiss")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(width: 220, height: 60)
                                    .background(accent)
                                    .clipShape(RoundedRectangle(cornerRadius: 30))
                            }
                            .buttonStyle(.plain)
                            .keyboardShortcut(.return, modifiers: [])
                        }
                    }
                    .padding(.bottom, 80)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { countdown = alertCountdown }
        .task {
            while countdown > 0 {
                try? await Task.sleep(for: .seconds(1))
                if countdown > 0 {
                    countdown -= 1
                    if countdown == 0 { fieldFocused = true }
                }
            }
        }
    }

    private var fuegoSection: some View {
        VStack(spacing: 24) {
            Text("Type these words to dismiss:")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(Color.white.opacity(0.6))

            HStack(spacing: 16) {
                ForEach(words, id: \.self) { word in
                    Text(word)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            ZStack {
                TextField("", text: $typed)
                    .font(.system(size: 22, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.plain)
                    .frame(width: 380, height: 52)
                    .background(Color.white.opacity(countdown > 0 ? 0.04 : 0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(accent.opacity(0.6), lineWidth: 1.5)
                    )
                    .focused($fieldFocused)
                    .disabled(countdown > 0)
                    .onChange(of: typed) { val in
                        if val.lowercased() == target {
                            onDismiss()
                        }
                    }
                    .onAppear {
                        if words.isEmpty { words = randomWords(count: fuegoWordCount) }
                        countdown = alertCountdown
                        if countdown == 0 { fieldFocused = true }
                    }

                if countdown > 0 {
                    Text("\(countdown)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.4))
                        .monospacedDigit()
                }
            }
        }
        .padding(.bottom, 80)
    }

}
