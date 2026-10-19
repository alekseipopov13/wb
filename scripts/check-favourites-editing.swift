import Foundation

@main
enum CheckFavouritesEditing {
    struct Item: Identifiable { let id: String }

    static func main() {
        let now = Date(timeIntervalSince1970: 1000)
        func check(_ value: @autoclosure () -> Bool, _ message: String) { precondition(value(), message) }
        var items = ["a", "b", "c", "d"].map(Item.init)
        let removal = FavouritesRemoval.remove("b", from: &items, now: now)!
        check(items.map(\.id) == ["a", "c", "d"], "Удаление сразу обновляет данные")
        check(removal.restore(in: &items, now: now.addingTimeInterval(4.99)), "До истечения таймера можно отменить")
        check(items.map(\.id) == ["a", "b", "c", "d"], "Карточка возвращается на своё место")
        check(!removal.restore(in: &items, now: now), "Повторная отмена не создаёт дубликат")

        let expired = FavouritesRemoval.remove("b", from: &items, now: now)!
        check(!expired.restore(in: &items, now: now.addingTimeInterval(5)), "На границе пяти секунд отмена недоступна")
        check(items.map(\.id) == ["a", "c", "d"], "Истёкшее удаление сохраняется")

        let removed = FavouritesRemoval.remove("c", from: &items, now: now)!
        items.insert(Item(id: "new"), at: 0)
        check(removed.restore(in: &items, now: now), "Отмена после изменения списка")
        check(items.map(\.id) == ["new", "a", "c", "d"], "Приоритет соседей вместо устаревшего индекса")
        check(FavouritesRemoval.remove("unknown", from: &items, now: now) == nil, "Отсутствующее избранное не создаёт тост")

        var single = [Item(id: "last")]
        let last = FavouritesRemoval.remove("last", from: &single, now: now)!
        check(single.isEmpty, "Можно удалить последнее избранное")
        check(last.restore(in: &single, now: now), "Последнее избранное восстанавливается")

        let utility = SavedUtilityDetails(account: "8888888888", previousReading: 1284)
        check(utility.readingError("") != nil, "Показания каждый месяц надо ввести заново")
        check(utility.readingError("1283") != nil, "Не принимаем показания меньше предыдущих")
        check(utility.readingError("1284") == nil, "Нулевой расход допустим")
        check(utility.readingError("1350") == nil, "Новые показания допустимы")
        check(utility.readingError("abc") != nil && utility.readingError("1000000") != nil, "Формат показаний проверяется")
        print("Favourites editing: undo order, expiry, duplicates, last removal and monthly readings passed")
    }
}
