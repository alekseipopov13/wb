import Foundation

@main
enum CheckFavouriteAmount {
    static func main() {
        func check(_ value: @autoclosure () -> Bool, _ message: String) { precondition(value(), message) }
        let operation = Decimal(string: "868.95")!
        var draft = FavouriteAmountDraft(savedAmount: operation)
        check(draft.value == operation && draft.displayValue == "868,95", "Сумма операции предзаполнена с копейками")
        check(draft.quickAmounts == [operation, 500, 1000], "Сумма операции вторым чипсом после «Без суммы»")
        draft.select(nil)
        check(draft.withoutAmount && draft.displayValue.isEmpty && draft.value == 0 && draft.isValid, "«Без суммы» отключает ввод и сохраняет ноль")
        draft.setText("999")
        check(draft.value == 0 && draft.withoutAmount, "Выключенный инпут не принимает ввод")
        check(draft.operationAmount == operation, "«Без суммы» не стирает исходную операцию")
        draft.select(1000)
        check(!draft.withoutAmount && draft.value == 1000 && draft.displayValue == "1\u{00A0}000", "Чип включает сумму и форматирует разряды")
        draft.setText("1 234,56")
        check(draft.value == Decimal(string: "1234.56")! && draft.isValid, "Ручная сумма с группировкой и копейками")
        check(draft.operationAmount == operation, "Ручная сумма не меняет подсказку из истории")
        draft.setText("1 234,")
        check(draft.displayValue == "1\u{00A0}234,", "Запятая остаётся при вводе копеек")
        draft.setText("")
        check(!draft.isValid && !draft.withoutAmount, "Пустое включённое поле просит сумму")
        draft.setText("1000001")
        check(!draft.isValid, "Лимит суммы")
        draft.select(nil)
        let reopened = FavouriteAmountDraft(savedAmount: draft.value, operationAmount: draft.operationAmount)
        check(reopened.withoutAmount && reopened.quickAmounts.first == operation, "Историческая сумма сохраняется после повторного открытия")
        let duplicate = FavouriteAmountDraft(savedAmount: 1000)
        check(duplicate.quickAmounts == [1000, 500], "Одинаковые быстрые суммы не дублируются")
        print("Favourite amount: prefill, disabled input, chips, decimals, limits and history preservation passed")
    }
}
