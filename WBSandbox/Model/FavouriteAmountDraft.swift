import Foundation

/// Сумма шаблона отделена от суммы исходной операции: «Без суммы» не стирает
/// подсказку из истории, а ручной ввод не переписывает её новым значением.
struct FavouriteAmountDraft {
    let operationAmount: Decimal?
    private(set) var withoutAmount: Bool
    private var input: AmountInput
    private var hasInput: Bool

    init(savedAmount: Decimal, operationAmount: Decimal? = nil) {
        self.operationAmount = operationAmount.flatMap { $0 > 0 ? $0 : nil }
            ?? (savedAmount > 0 ? savedAmount : nil)
        withoutAmount = savedAmount <= 0
        input = AmountInput(max(0, savedAmount))
        hasInput = savedAmount > 0
    }

    var value: Decimal { withoutAmount ? 0 : input.decimal }
    var isValid: Bool { withoutAmount || (hasInput && input.decimal > 0 && input.decimal <= 1_000_000) }
    var displayValue: String {
        withoutAmount || !hasInput ? "" : input.displayInteger + (input.displayFraction ?? "")
    }
    var quickAmounts: [Decimal] {
        ([operationAmount].compactMap { $0 } + [500, 1000]).reduce(into: []) { values, amount in
            if !values.contains(amount) { values.append(amount) }
        }
    }

    mutating func select(_ amount: Decimal?) {
        guard let amount else { withoutAmount = true; return }
        withoutAmount = false
        input = AmountInput(amount)
        hasInput = true
    }

    mutating func setText(_ text: String) {
        guard !withoutAmount else { return }
        var next = AmountInput(0)
        for character in text {
            if character.isASCII && character.isNumber { next.append(digit: String(character)) }
            else if character == "," || character == "." { next.appendSeparator() }
        }
        input = next
        hasInput = text.contains { $0.isNumber || $0 == "," || $0 == "." }
    }
}
