import SwiftUI

/// WB snackbar, Figma 60757:461795 / 60757:460169.
struct FavouritesSnackbar: View {
    var expiresAt: Date?
    var onUndo: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            if let expiresAt {
                TimelineView(.periodic(from: .now, by: 0.1)) { context in
                    let remaining = max(0, expiresAt.timeIntervalSince(context.date))
                    ZStack {
                        Circle().stroke(WBColor.textAccent.opacity(0.3), lineWidth: 1.4)
                        Circle()
                            .trim(from: 0, to: min(1, remaining / 5))
                            .stroke(WBColor.textAccent, style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text("\(Int(ceil(remaining)))")
                            .font(PaymentsHubFont.medium(10))
                            .foregroundStyle(WBColor.textAccent)
                    }
                }
                .frame(width: 20, height: 20)
                .accessibilityHidden(true)
            } else {
                Image("favInfo").renderingMode(.template)
                    .resizable().frame(width: 20, height: 20)
                    .accessibilityHidden(true)
            }
            Text(expiresAt == nil ? "Нажмите на карточку, чтобы изменить её" : "Убрали из избранного")
                .font(PaymentsHubFont.regular(15))
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            if let onUndo {
                Button(action: onUndo) {
                    Text("Отменить")
                        .font(PaymentsHubFont.medium(15))
                        .padding(.horizontal, 8)
                        .frame(height: 28)
                        .background(WBColor.ctaFill, in: RoundedRectangle(cornerRadius: 12))
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("saved.undoRemoval")
                .padding(.vertical, -8)
            }
        }
        .foregroundStyle(Color(hex: 0xF6F6F9))
        .padding(.leading, 16)
        .padding(.trailing, expiresAt == nil ? 16 : 12)
        .padding(.vertical, 12)
        .background(Color(hex: 0x18181B), in: RoundedRectangle(cornerRadius: 20))
        .accessibilityIdentifier(expiresAt == nil ? "saved.editHint" : "saved.removalToast")
    }
}
