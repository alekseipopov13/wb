import Foundation

@main
enum CheckFavouritesFeed {
    static func main() {
        typealias Usage = PaymentsFeedPolicy.Usage
        func feed(_ banking: Bool, _ history: [Usage], _ saved: [String] = []) -> [String] {
            PaymentsFeedPolicy.cardIDs(openBanking: banking, history: history, savedIDs: saved)
        }
        func check(_ condition: @autoclosure () -> Bool, _ message: String) {
            precondition(condition(), message)
        }

        check(feed(false, []) == ["wallet-top-up", "my-phone"], "Новый клиент: только кошелёк и общая мобильная связь")
        check(feed(true, []) == ["self-vtb", "wallet-top-up", "my-phone"], "ВТБ первым при Open Banking")

        let history: [Usage] = (0..<10).map { .init(id: "operation-\($0)", count: 10 - $0, lastUsed: $0) }
        check(feed(true, history) == ["self-vtb", "my-phone", "operation-0", "operation-1", "operation-2", "operation-3"], "Частотность и лимит рекомендаций")
        check(!feed(false, history).contains("self-vtb"), "Без Open Banking нет закреплённой ВТБ")
        check(!feed(true, history).contains("wallet-top-up"), "Пополнение исчезает после первой операции")

        let saved = ["operation-5", "operation-4", "operation-9"]
        let full = feed(true, history, saved)
        check(full == ["self-vtb", "my-phone", "operation-0", "operation-1", "operation-4", "operation-5"], "Последние два места — самые частые избранные")

        let tied = [Usage(id: "old", count: 5, lastUsed: 2), Usage(id: "new", count: 5, lastUsed: 3)]
        check(feed(false, tied) == ["my-phone", "new", "old"], "При равной частоте более свежая операция раньше")
        let repeated = [Usage(id: "same", count: 2, lastUsed: 2), Usage(id: "same", count: 3, lastUsed: 3)]
        check(feed(true, repeated, ["same", "same"]) == ["self-vtb", "my-phone", "same"], "Повторные операции не создают дубликатов карточки")

        for banking in [false, true] {
            for count in 0...10 {
                for savedCount in 0...10 {
                    let operations = Array(history.prefix(count))
                    let favourites = history.prefix(savedCount).map(\.id)
                    let result = feed(banking, operations, favourites)
                    check(result.count <= 6, "В ленте не больше шести карточек")
                    check(Set(result).count == result.count, "Карточки уникальны")
                    check(result.filter { favourites.contains($0) }.count <= 2, "В ленте не больше двух избранных")
                    if !operations.isEmpty { check(!result.contains("wallet-top-up"), "Кошелёк только до первой операции") }
                    if banking { check(result.first == "self-vtb", "ВТБ сохраняет первое место") }
                }
            }
        }
        print("Favourites feed: scenarios and 242 combinations passed")
    }
}
