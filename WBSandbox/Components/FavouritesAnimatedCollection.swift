import SwiftUI

enum FavouritesCollectionItem: Identifiable {
    case shortcut(PaymentShortcut)
    case allFavourites
    case history

    var id: String {
        switch self {
        case .shortcut(let shortcut): shortcut.id
        case .allFavourites: "favourites-all-folder"
        case .history: "favourites-add-from-history"
        }
    }
}

/// Одна механика для ленты и сетки: стабильные id, непрерывное перемещение
/// настоящих карточек и небольшая задержка каждого следующего соседа.
struct FavouritesAnimatedCollection<Card: View>: View {
    let items: [FavouritesCollectionItem]
    let arrangement: FavouritesCollectionArrangement
    let addition: FavouritesAddition?
    var isActive = true
    @ViewBuilder let card: (FavouritesCollectionItem, Int) -> Card

    @State private var presented: [FavouritesCollectionItem]
    @State private var consumedAddition: UUID?
    @State private var batch: Batch?
    @State private var containerWidth: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    private struct Batch {
        let id = UUID()
        let previous: [String]
        let next: [String]
        let inserted: Set<String>
        let removed: Set<String>
        let highlight: String?
        let startedAt = Date.now
        let sources: [String: CGPoint]
        let visibility: [String: Double]
    }

    init(items: [FavouritesCollectionItem], arrangement: FavouritesCollectionArrangement,
         addition: FavouritesAddition?, isActive: Bool = true,
         @ViewBuilder card: @escaping (FavouritesCollectionItem, Int) -> Card) {
        self.items = items
        self.arrangement = arrangement
        self.addition = addition
        self.isActive = isActive
        self.card = card
        _presented = State(initialValue: items)
        // Открытие раздела с уже существующим списком не повторяет добавление.
        _consumedAddition = State(initialValue: addition?.id)
    }

    var body: some View {
        GeometryReader { proxy in
            TimelineView(.animation(paused: batch == nil || !isActive || reduceMotion || scenePhase != .active)) { context in
                ZStack(alignment: .topLeading) {
                    ForEach(Array(presented.enumerated()), id: \.element.id) { index, snapshot in
                        let item = items.first { $0.id == snapshot.id } ?? snapshot
                        let center = center(for: item.id, index: index, width: proxy.size.width, date: context.date)
                        let visibility = visibility(for: item.id, date: context.date)
                        card(item, batch?.next.firstIndex(of: item.id) ?? index)
                            .frame(width: arrangement.cardWidth(in: proxy.size.width), height: arrangement.cardHeight)
                            .modifier(FavouritesInsertionAppearance(
                                token: token(for: item.id),
                                isNew: batch?.inserted.contains(item.id) == true,
                                delay: arrangement == .row ? 0.34 : 0.27,
                                isActive: isActive
                            ))
                            .scaleEffect(max(0.04, visibility))
                            .opacity(visibility)
                            .allowsHitTesting(batch?.removed.contains(item.id) != true)
                            .accessibilityHidden(batch?.removed.contains(item.id) == true)
                            .id(item.id)
                            .position(center)
                            // Координаты уже интерполированы общим временем.
                            // Вложенные transaction/TimelineView не могут отменить путь.
                            .transaction { $0.animation = nil }
                            .transition(.identity)
                    }
                }
            }
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { containerWidth = $0 }
        }
        // Пока хвост цепочки движется, не обрезаем последнюю строку.
        .frame(width: arrangement.width(count: layoutCount), height: arrangement.height(count: layoutCount))
        .onChange(of: items.map(\.id)) { _, _ in reconcile() }
        .onChange(of: addition?.id) { _, _ in reconcile() }
        .onChange(of: isActive) { _, active in if active { reconcile() } }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { reconcile() } else { settle() }
        }
        .onChange(of: reduceMotion) { _, value in if value { settle(); reconcile() } }
        .task(id: batch?.id) {
            guard let current = batch else { return }
            do { try await Task.sleep(for: .seconds(1.35)) } catch { return }
            if batch?.id == current.id { settle() }
        }
    }

    private var layoutCount: Int {
        guard let batch else { return presented.count }
        return max(presented.count, max(batch.previous.count, batch.next.count))
    }

    private func center(for id: String, index: Int, width: CGFloat, date: Date) -> CGPoint {
        let target = arrangement.center(at: batch?.next.firstIndex(of: id) ?? index, width: width)
        guard let batch, !reduceMotion, isActive, let source = batch.sources[id] else { return target }
        guard !batch.removed.contains(id) else { return source }
        let delay = batch.removed.isEmpty
            ? FavouritesInsertionOrder.delay(for: id, previous: batch.previous, next: batch.next, insertedID: batch.highlight)
            : FavouritesRemovalOrder.delay(for: id, previous: batch.previous, next: batch.next)
        let elapsed = max(0, date.timeIntervalSince(batch.startedAt) - delay)
        let progress = SandboxMotion.CardInsertion.travel.value(time: elapsed).progress
        return FavouritesInsertionPath.point(from: source, to: target, arrangement: arrangement, progress: progress)
    }

    private func visibility(for id: String, date: Date) -> Double {
        guard let batch, !reduceMotion else { return 1 }
        let start = batch.visibility[id] ?? 1
        let target: Double = batch.removed.contains(id) ? 0 : 1
        let progress = SandboxMotion.CardRemoval.timeline.value(time: max(0, date.timeIntervalSince(batch.startedAt))).progress
        return start + (target - start) * progress
    }

    private func token(for id: String) -> UUID? {
        guard let batch, batch.inserted.contains(id) || batch.highlight == id else { return nil }
        // Быстрая отмена продолжает незавершённое схлопывание обратно;
        // второй эффект появления поверх него не запускаем.
        if let visibility = batch.visibility[id], visibility < 0.999 { return nil }
        return batch.id
    }

    private func settle() {
        withTransaction(Transaction(animation: nil)) {
            presented = items
            batch = nil
        }
    }

    private func reconcile() {
        guard isActive, scenePhase == .active else { return }
        let previous = batch?.next ?? presented.map(\.id)
        let next = items.map(\.id)
        let pending = addition.flatMap { $0.id == consumedAddition ? nil : $0 }
        guard previous != next || pending != nil else { return }
        if let pending { consumedAddition = pending.id }
        let inserted = Set(next).subtracting(previous)
        let removed = Set(presented.map(\.id)).subtracting(next)
        let highlight = pending.flatMap { next.contains($0.shortcutID) ? $0.shortcutID : nil }
        // При быстрой отмене/новой вставке берём текущие промежуточные точки,
        // сохраняя непрерывность уже движущихся карточек.
        let now = Date.now
        let sources = Dictionary(uniqueKeysWithValues: presented.enumerated().map { index, item in
            (item.id, center(for: item.id, index: index, width: containerWidth, date: now))
        })
        let visibility = Dictionary(uniqueKeysWithValues: presented.map {
            ($0.id, self.visibility(for: $0.id, date: now))
        })
        // Новые элементы ленты обновляются без постановочной вставки.
        // Отклик уже видимой рекомендации и удаление остаются своими действиями.
        let animate = !reduceMotion && arrangement.animatesChange(previous: previous, next: next, hasAddition: pending != nil)
        let animatedHighlight = arrangement == .grid || inserted.isEmpty ? highlight : nil
        let outgoing = presented.filter { removed.contains($0.id) }
        withTransaction(Transaction(animation: nil)) {
            batch = animate
                ? Batch(previous: previous, next: next,
                        inserted: arrangement == .grid ? inserted.filter { sources[$0] == nil } : [],
                        removed: removed,
                        highlight: animatedHighlight ?? (arrangement == .grid ? next.first { inserted.contains($0) } : nil),
                        sources: sources, visibility: visibility)
                : nil
            presented = items + (animate ? outgoing : [])
        }
    }
}

private struct FavouritesInsertionAppearance: ViewModifier {
    let token: UUID?
    let isNew: Bool
    let delay: Double
    let isActive: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var startedAt: Date?
    @State private var finished = false

    private var plays: Bool { token != nil && isActive && !reduceMotion && scenePhase == .active }

    func body(content: Content) -> some View {
        TimelineView(.animation(paused: !plays || finished || startedAt == nil)) { context in
            let elapsed = startedAt.map { max(0, context.date.timeIntervalSince($0)) } ?? 0
            let timeline = isNew ? SandboxMotion.CardInsertion.timeline : SandboxMotion.CardInsertion.promotion
            let pose = !plays || finished ? SandboxMotion.CardInsertion.restingPose : timeline.value(time: elapsed)
            content
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(WBColor.bgBase.opacity(pose.light))
                        .allowsHitTesting(false)
                }
                .shadow(color: Color(hex: 0xBFA5FF).opacity(pose.light * 0.65), radius: 16)
                .scaleEffect(x: pose.scale * pose.aspect, y: pose.scale / pose.aspect)
                .opacity(plays && isNew && startedAt == nil && !finished ? 0 : 1)
                .transaction { $0.animation = nil }
        }
        .task(id: plays ? token : nil) {
            startedAt = nil
            finished = false
            guard plays else { return }
            do {
                try await Task.sleep(for: .seconds(delay))
                startedAt = .now
                try await Task.sleep(for: .seconds(SandboxMotion.CardInsertion.timeline.duration))
                finished = true
            } catch { return }
        }
    }
}
