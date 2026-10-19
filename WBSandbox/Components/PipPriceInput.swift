import SwiftUI

/// InputPrice / Large использует общую основу InputText: лейбл, фокус,
/// disabled и обводка едины. Отличия цены — валюта и десятичная клавиатура.
struct PipPriceInput: View {
    @Binding var value: String
    var focus: FocusState<String?>.Binding
    var isEnabled = true
    var error: String?

    var body: some View {
        PipInput(
            field: FormField(id: "amount", label: "Сумма", kind: .input(.text(0...20)), facet: .services),
            format: .text(0...20), value: $value, focus: focus,
            placeholder: "Сумма", error: error,
            floatingLabel: true, isEnabled: isEnabled, currency: "₽", keyboard: .decimalPad,
            textFont: PaymentsHubFont.regular(17), labelFont: PaymentsHubFont.regular(13),
            accessibilityID: "saved.editor.amount"
        )
    }
}
