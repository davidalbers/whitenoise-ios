import SwiftUI

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
