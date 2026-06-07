import SwiftUI

struct DurationPicker: View {
    @Binding var duration: TimeInterval
    var isEnabled: Bool = true

    @State private var hours: Int
    @State private var minutes: Int

    init(duration: Binding<TimeInterval>, isEnabled: Bool = true) {
        _duration = duration
        self.isEnabled = isEnabled
        _hours = State(initialValue: duration.wrappedValue.secondsToHours())
        _minutes = State(initialValue: duration.wrappedValue.secondsToMins())
    }

    var body: some View {
        HStack(spacing: 0) {
            Picker("Hours", selection: $hours) {
                ForEach(0 ..< 24, id: \.self) { Text("\($0) hr").tag($0) }
            }
            .pickerStyle(.wheel)

            Picker("Minutes", selection: $minutes) {
                ForEach(0 ..< 60, id: \.self) { Text("\($0) min").tag($0) }
            }
            .pickerStyle(.wheel)
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.35)
        .onChange(of: hours) { sync() }
        .onChange(of: minutes) { sync() }
        .onChange(of: duration) {
            let hrs = duration.secondsToHours()
            let mins = duration.secondsToMins()
            if hours != hrs { hours = hrs }
            if minutes != mins { minutes = mins }
        }
    }

    private func sync() {
        duration = TimeInterval(hours * 3600 + minutes * 60)
    }
}

private extension Double {
    func secondsToHours() -> Int {
        Int(self) / 3600
    }

    func secondsToMins() -> Int {
        (Int(self) % 3600) / 60
    }
}

struct CustomTimerSheet: View {
    @Binding var duration: TimeInterval
    let onSet: () -> Void
    let onCancel: () -> Void

    @Environment(ThemeColors.self) private var themeColors

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(uiColor: .systemFill))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 16)

            Text("Timer")
                .font(.title3).fontWeight(.semibold)
                .foregroundColor(themeColors.text)
                .padding(.bottom, 8)

            DurationPicker(duration: $duration, isEnabled: true)
                .frame(height: 200)
                .padding(.horizontal, 16)

            HStack(spacing: 12) {
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.body).fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(themeColors.accent)
                        .cornerRadius(12)
                        .foregroundColor(themeColors.text)
                }
                Button(action: onSet) {
                    Text("Set timer")
                        .font(.body).fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(themeColors.text)
                        .cornerRadius(12)
                        .foregroundColor(Color(uiColor: .systemBackground))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .presentationDetents([.height(440)])
        .presentationDragIndicator(.hidden)
    }
}
