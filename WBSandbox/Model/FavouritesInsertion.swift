import Foundation
import CoreGraphics

/// Одно добавление, которое каждая видимая коллекция воспроизводит один раз.
struct FavouritesAddition: Identifiable, Equatable {
    let id = UUID()
    let shortcutID: String
}

/// Геометрия общая для появления карточки и каскадного сдвига её соседей.
enum FavouritesCollectionArrangement: Equatable {
    case row
    case grid

    var cardHeight: CGFloat { self == .row ? 102 : 108 }
    var spacing: CGFloat { self == .row ? 4 : 8 }
    var columns: Int { self == .row ? 1 : 2 }

    func animatesChange(previous: [String], next: [String], hasAddition: Bool) -> Bool {
        if self == .grid { return true }
        // В заполненной ленте добавление заменяет один из старых слотов.
        // Такая замена тоже относится к отключённой анимации добавления.
        if hasAddition { return previous == next }
        return previous.contains { !next.contains($0) }
    }

    func width(count: Int) -> CGFloat? {
        self == .row ? max(0, CGFloat(count) * 126 - 4) : nil
    }

    func height(count: Int) -> CGFloat {
        guard count > 0 else { return 0 }
        if self == .row { return cardHeight }
        return CGFloat((count + columns - 1) / columns) * (cardHeight + spacing) - spacing
    }

    func cardWidth(in width: CGFloat) -> CGFloat {
        self == .row ? 122 : max(0, (width - spacing) / 2)
    }

    func center(at index: Int, width: CGFloat) -> CGPoint {
        let w = cardWidth(in: width)
        let column = self == .row ? index : index % columns
        let row = self == .row ? 0 : index / columns
        return CGPoint(x: w / 2 + CGFloat(column) * (w + spacing),
                       y: cardHeight / 2 + CGFloat(row) * (cardHeight + spacing))
    }
}

enum FavouritesInsertionOrder {
    static let cascadeStep: Double = 0.085
    static let maximumDelay: Double = 0.425
    /// Сначала ближайший сосед, затем следующие. Задержка ограничена даже в
    /// длинном списке: карточки за экраном не ждут завершения всей «змейки».
    static func delay(for id: String, previous: [String], next: [String], insertedID: String?) -> Double {
        guard let oldIndex = previous.firstIndex(of: id),
              let newIndex = next.firstIndex(of: id), oldIndex != newIndex,
              let insertedID, let insertionIndex = next.firstIndex(of: insertedID) else { return 0 }
        let distance = max(0, abs(newIndex - insertionIndex) - 1)
        return min(maximumDelay, Double(distance) * cascadeStep)
    }
}

enum FavouritesRemovalOrder {
    /// Освобождаем место, затем ближайший сосед подхватывает движение.
    /// Индексы берём до удаления: у него больше нет позиции в новом списке.
    static let vacancyDelay: Double = 0.12

    static func delay(for id: String, previous: [String], next: [String]) -> Double {
        guard let oldIndex = previous.firstIndex(of: id),
              let newIndex = next.firstIndex(of: id), oldIndex != newIndex,
              let vacancy = previous.indices.first(where: { !next.contains(previous[$0]) && $0 < oldIndex })
        else { return 0 }
        let distance = previous[(vacancy + 1)..<oldIndex].filter { next.contains($0) }.count
        return vacancyDelay + min(FavouritesInsertionOrder.maximumDelay,
                                  Double(distance) * FavouritesInsertionOrder.cascadeStep)
    }
}

enum FavouritesInsertionPath {
    /// Сосед в той же строке идёт вправо. При переносе на следующую строку
    /// дуга сначала ведёт вниз у правого края, затем к началу новой строки.
    static func point(from source: CGPoint, to target: CGPoint,
                      arrangement: FavouritesCollectionArrangement, progress: Double) -> CGPoint {
        let p = CGFloat(min(1, max(0, progress)))
        guard arrangement == .grid, abs(source.y - target.y) > 1,
              abs(source.x - target.x) > 1 else {
            return CGPoint(x: source.x + (target.x - source.x) * p,
                           y: source.y + (target.y - source.y) * p)
        }
        let control = CGPoint(x: max(source.x, target.x) + 12, y: (source.y + target.y) / 2)
        let q = 1 - p
        return CGPoint(x: q * q * source.x + 2 * q * p * control.x + p * p * target.x,
                       y: q * q * source.y + 2 * q * p * control.y + p * p * target.y)
    }
}
