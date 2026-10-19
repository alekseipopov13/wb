import Foundation

/// Рекомендации ПиП не становятся избранным автоматически.
/// В ленте максимум шесть операций; кнопка истории добавляется представлением.
enum PaymentsFeedPolicy {
    struct Usage: Equatable {
        let id: String
        let count: Int
        let lastUsed: Int
    }

    static func cardIDs(openBanking: Bool, history: [Usage], savedIDs: [String]) -> [String] {
        let fixed = (openBanking ? ["self-vtb"] : [])
            + (history.isEmpty ? ["wallet-top-up"] : [])
            + ["my-phone"]
        let excluded = Set(fixed + ["wallet-top-up"])
        let usage = Dictionary(history.map { ($0.id, $0) }, uniquingKeysWith: { lhs, rhs in
            Usage(id: lhs.id, count: lhs.count + rhs.count, lastUsed: max(lhs.lastUsed, rhs.lastUsed))
        })
        func ranked(_ ids: [String]) -> [String] {
            var seen = Set<String>()
            let unique = ids.filter { seen.insert($0).inserted }
            let order = Dictionary(uniqueKeysWithValues: unique.enumerated().map { ($1, $0) })
            return unique.sorted {
                let lhs = usage[$0], rhs = usage[$1]
                if (lhs?.count ?? 0) != (rhs?.count ?? 0) { return (lhs?.count ?? 0) > (rhs?.count ?? 0) }
                if (lhs?.lastUsed ?? 0) != (rhs?.lastUsed ?? 0) { return (lhs?.lastUsed ?? 0) > (rhs?.lastUsed ?? 0) }
                return order[$0, default: 0] < order[$1, default: 0]
            }
        }
        let saved = Array(ranked(savedIDs.filter { !excluded.contains($0) }).prefix(2))
        let savedSet = Set(savedIDs)
        let recent = ranked(history.map(\.id).filter { !excluded.contains($0) && !savedSet.contains($0) })
        return fixed + Array(recent.prefix(max(0, 6 - fixed.count - saved.count))) + saved
    }
}
