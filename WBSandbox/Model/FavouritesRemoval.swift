import Foundation

/// Одна отменяемая операция. Соседи сохраняют место карточки даже после
/// других изменений списка; истёкший тост уже не может воскресить удалённое.
struct FavouritesRemoval<Item: Identifiable>: Identifiable {
    let id = UUID()
    let item: Item
    let index: Int
    let previousID: Item.ID?
    let nextID: Item.ID?
    let expiresAt: Date
    static var duration: TimeInterval { 5 }

    static func remove(_ id: Item.ID, from items: inout [Item], now: Date = .now) -> Self? {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return nil }
        let removal = Self(
            item: items[index], index: index,
            previousID: index > 0 ? items[index - 1].id : nil,
            nextID: index + 1 < items.count ? items[index + 1].id : nil,
            expiresAt: now.addingTimeInterval(duration)
        )
        items.remove(at: index)
        return removal
    }

    @discardableResult
    func restore(in items: inout [Item], now: Date = .now) -> Bool {
        guard now < expiresAt, !items.contains(where: { $0.id == item.id }) else { return false }
        let insertion: Int
        if let next = items.firstIndex(where: { $0.id == nextID }) {
            insertion = next
        } else if let previous = items.firstIndex(where: { $0.id == previousID }) {
            insertion = previous + 1
        } else {
            insertion = min(index, items.count)
        }
        items.insert(item, at: insertion)
        return true
    }
}
