import Foundation
import CoreGraphics

@main
enum CheckFavouritesInsertion {
    static func main() {
        func check(_ condition: @autoclosure () -> Bool, _ message: String) { precondition(condition(), message) }
        let old = ["a", "b", "c", "d", "e", "history"]
        let first = ["new"] + old
        let delays = old.map { FavouritesInsertionOrder.delay(for: $0, previous: old, next: first, insertedID: "new") }
        check(delays.first == 0 && abs(delays.last! - 0.425) < 0.000001, "Сдвиг начинается с ближайшего соседа и ограничен по времени")
        check(zip(delays, delays.dropFirst()).allSatisfy { $0 <= $1 }, "Хвост идёт последовательно")
        let middle = ["a", "b", "new", "c", "d", "e", "history"]
        check(FavouritesInsertionOrder.delay(for: "a", previous: old, next: middle, insertedID: "new") == 0,
              "Карточки до вставки не получают искусственную задержку")
        check(FavouritesInsertionOrder.delay(for: "c", previous: old, next: middle, insertedID: "new") == 0,
              "Первый сосед после вставки начинает сразу")
        check(FavouritesInsertionOrder.delay(for: "d", previous: old, next: middle, insertedID: "new") > 0,
              "Вставка в середину тоже продолжает волну")
        let grid = FavouritesCollectionArrangement.grid
        let row = FavouritesCollectionArrangement.row
        check(!row.animatesChange(previous: old, next: first, hasAddition: true),
              "Добавление в ленту не запускает анимацию")
        check(!row.animatesChange(previous: old, next: ["new"] + old.dropLast(), hasAddition: true),
              "Замена заполненного слота тоже не возвращает анимацию добавления")
        check(row.animatesChange(previous: old, next: old, hasAddition: true),
              "Отклик уже видимой рекомендации сохраняется")
        check(row.animatesChange(previous: old, next: Array(old.dropFirst()), hasAddition: false),
              "Удаление из ленты сохраняет плавный сдвиг")
        check(grid.animatesChange(previous: old, next: first, hasAddition: true),
              "Добавление в сетку сохраняет анимацию")
        for width: CGFloat in [320, 358, 370, 398, 700] {
            let w = grid.cardWidth(in: width)
            let right = grid.center(at: 1, width: width)
            let wrapped = grid.center(at: 2, width: width)
            check(abs(right.x + w / 2 - width) < 0.000001, "Правая карточка остаётся в контейнере")
            check(wrapped.x == w / 2 && wrapped.y > right.y, "Перенос в следующую строку сохраняет порядок")
        }
        check(row.width(count: 7) == 878 && row.height(count: 7) == 102, "Шесть операций и кнопка истории сохраняют геометрию Figma")
        check(grid.height(count: 0) == 0 && grid.height(count: 5) == 340, "Первое добавление и новая строка сетки")
        let source = grid.center(at: 1, width: 370)
        let target = grid.center(at: 2, width: 370)
        check(FavouritesInsertionPath.point(from: source, to: target, arrangement: .grid, progress: 0) == source,
              "Первый кадр должен сохранять старую позицию")
        check(FavouritesInsertionPath.point(from: source, to: target, arrangement: .grid, progress: 1) == target,
              "Финальный кадр должен попасть в следующий слот")
        var last = source
        for frame in 1...60 {
            let point = FavouritesInsertionPath.point(from: source, to: target, arrangement: .grid, progress: Double(frame) / 60)
            check(point != source && (frame == 60 || point != target), "Существуют промежуточные позиции, а не подмена слотов")
            check(hypot(point.x - last.x, point.y - last.y) < 12, "Траектория не должна прыгать между кадрами")
            last = point
        }
        let afterFirstRemoval = Array(old.dropFirst())
        let removalDelays = afterFirstRemoval.map {
            FavouritesRemovalOrder.delay(for: $0, previous: old, next: afterFirstRemoval)
        }
        check(removalDelays[0] == FavouritesRemovalOrder.vacancyDelay,
              "Сдвиг ждёт, пока удаляемая карточка начнёт схлопываться")
        check(zip(removalDelays, removalDelays.dropFirst()).allSatisfy { $0 < $1 },
              "Удаление сдвигает соседей цепочкой, а не одновременно")
        let afterMiddleRemoval = old.filter { $0 != "c" }
        check(FavouritesRemovalOrder.delay(for: "a", previous: old, next: afterMiddleRemoval) == 0,
              "Карточки перед удалённой не сдвигаются")
        check(FavouritesRemovalOrder.delay(for: "d", previous: old, next: afterMiddleRemoval) == FavouritesRemovalOrder.vacancyDelay,
              "После удаления из середины первым движется ближайший сосед")
        let long = (0..<40).map(String.init)
        check(FavouritesRemovalOrder.delay(for: "39", previous: long, next: Array(long.dropFirst())) <= 0.545,
              "Длинный хвост удаления ограничен по времени")
        let multiple = old.filter { $0 != "b" && $0 != "c" }
        check(FavouritesRemovalOrder.delay(for: "d", previous: old, next: multiple) == FavouritesRemovalOrder.vacancyDelay,
              "Несколько удалённых подряд не создают пустые задержки")
        check(FavouritesRemovalOrder.delay(for: "a", previous: ["a"], next: []) == 0,
              "Удаление последней карточки не требует движения соседей")
        for frame in 0...60 {
            let p = Double(frame) / 60
            let insertion = FavouritesInsertionPath.point(from: source, to: target, arrangement: .grid, progress: 1-p)
            let removal = FavouritesInsertionPath.point(from: target, to: source, arrangement: .grid, progress: p)
            check(hypot(insertion.x-removal.x, insertion.y-removal.y) < 0.000001,
                  "Удаление проходит ту же непрерывную дугу в обратную сторону")
        }
        print("Favourites collection: insertion/removal cascade, middle changes, delay caps, reverse row wrap and fixed geometry passed")
    }
}
