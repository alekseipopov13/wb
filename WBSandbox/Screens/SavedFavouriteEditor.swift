import SwiftUI

/// Figma 60820:462281 / 60571:215360; панель действий — 60571:215378.
struct SavedFavouriteEditor: View {
    enum Mode {
        case create
        // Editing always supplies both actions; a caller cannot accidentally
        // hide the removal button by omitting an optional callback.
        case edit(onRemove: () -> Void)

        var isCreating: Bool {
            if case .create = self { return true }
            return false
        }
    }
    let shortcut: PaymentShortcut
    let mode: Mode
    let onSave: (PaymentShortcut) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var amount: FavouriteAmountDraft
    @FocusState private var focus: String?

    init(shortcut: PaymentShortcut, mode: Mode, onSave: @escaping (PaymentShortcut) -> Void) {
        self.shortcut = shortcut
        self.mode = mode
        self.onSave = onSave
        _name = State(initialValue: shortcut.title)
        _amount = State(initialValue: FavouriteAmountDraft(savedAmount: shortcut.amount, operationAmount: shortcut.operationAmount))
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && amount.isValid
    }
    private var priceText: Binding<String> {
        Binding(get: { amount.displayValue }, set: { amount.setText($0) })
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    VStack(spacing: -12) {
                        FavouritesEditorAvatar(shortcut: shortcut)
                        PipInput(
                            field: FormField(id: "name", label: "Название", kind: .input(.text(1...40)), facet: .payeeName),
                            format: .text(1...40), value: $name, focus: $focus,
                            placeholder: "Название", error: nil,
                            floatingLabel: true, textFont: PaymentsHubFont.regular(17),
                            labelFont: PaymentsHubFont.regular(13), accessibilityID: "saved.editor.name",
                            externalOutlineColor: WBColor.bgBase
                        )
                        .onChange(of: name) { _, value in name = String(value.prefix(40)) }
                        .zIndex(1)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        PipPriceInput(value: priceText, focus: $focus, isEnabled: !amount.withoutAmount,
                                      error: !amount.isValid && focus != "amount" ? "Укажите сумму до 1 000 000 ₽" : nil)
                        FavouritesAmountChips(amount: $amount) {
                            if focus == "amount" { focus = nil }
                        }
                    }
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .foregroundStyle(WBColor.textPrimary)
        .background(WBColor.bgBase.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 8) {
                WBPrimaryButton(title: mode.isCreating ? "Добавить" : "Сохранить",
                                titleFont: PaymentsHubFont.medium(17), isEnabled: isValid) {
                    focus = nil
                    var updated = shortcut
                    updated.title = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    updated.amount = amount.value
                    updated.operationAmount = amount.operationAmount
                    onSave(updated)
                }
                .accessibilityIdentifier("saved.editor.save")
                if case .edit(let onRemove) = mode {
                    Button {
                        focus = nil
                        onRemove()
                    } label: {
                        Text("Убрать")
                            .font(PaymentsHubFont.medium(17))
                            .frame(maxWidth: .infinity).frame(height: 52)
                            .background(WBColor.bgLevel2, in: RoundedRectangle(cornerRadius: 20))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("saved.editor.remove")
                }
            }
            .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 8)
            .background(WBColor.bgBase)
        }
        .onAppear { if mode.isCreating { focus = "name" } }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button { focus = nil; dismiss() } label: {
                    Image("dsChevronLeft24").renderingMode(.template)
                        .frame(width: 24, height: 24).frame(width: 44, height: 44)
                }
                .accessibilityLabel("Назад")
                .accessibilityIdentifier("saved.editor.back")
                Spacer(minLength: 0)
            }
            .frame(height: 48).padding(.horizontal, 4)
            Text(mode.isCreating ? "Добавить в избранное" : "Изменить")
                .font(PaymentsHubFont.bold(24))
                .frame(height: 29, alignment: .leading)
                .padding(.horizontal, 16).padding(.top, 4).padding(.bottom, 8)
                .accessibilityAddTraits(.isHeader)
        }
        .buttonStyle(.plain)
    }

}
