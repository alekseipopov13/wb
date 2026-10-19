import SwiftUI

/// One set of amount actions for the editor and its isolated motion example.
struct FavouritesAmountChips: View {
    @Binding var amount: FavouriteAmountDraft
    var onDisable: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("Без суммы", selected: amount.withoutAmount, id: "none") {
                    amount.select(nil)
                    onDisable()
                }
                ForEach(amount.quickAmounts, id: \.self) { value in
                    chip(Money.rub(value), selected: !amount.withoutAmount && amount.value == value,
                         id: NSDecimalNumber(decimal: value).stringValue) {
                        amount.select(value)
                    }
                }
            }
        }
        .scrollClipDisabled()
    }

    private func chip(_ title: String, selected: Bool, id: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            withAnimation(reduceMotion ? nil : SandboxMotion.fieldState, action)
        } label: {
            Text(title).font(PaymentsHubFont.regular(15))
                .foregroundStyle(selected ? Color(hex: 0xEFEFF5) : WBColor.textPrimary)
                .padding(.horizontal, 12).frame(height: 38)
                .background(selected ? WBColor.ctaFill : WBColor.bgLevel2,
                            in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("saved.editor.chip.\(id)")
    }
}
