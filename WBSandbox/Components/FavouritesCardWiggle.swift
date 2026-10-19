import SwiftUI

/// Размерозависимый, несинхронный wiggle: принцип JiggleKit (MIT),
/// https://github.com/visfitness/JiggleKit. Реализация локальная; углы широких
/// карточек проходят всего 1.6 pt, вертикальное движение — 0.35 pt.
struct FavouritesCardWiggle: ViewModifier {
    let enabled: Bool
    let seed: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var size = CGSize(width: 175, height: 108)
    @State private var startedAt: Date?

    private var active: Bool { enabled && !reduceMotion && scenePhase == .active }
    private var variation: Double { Double(seed.utf8.reduce(0) { ($0 + Int($1)) % 97 }) / 97 }
    private var direction: Double { variation < 0.5 ? -1 : 1 }
    private var angle: Double {
        let radius = max(1, hypot(size.width / 2, size.height / 2))
        return 2 * asin(1.6 / (2 * radius)) * 180 / .pi * direction
    }

    func body(content: Content) -> some View {
        // repeatForever может пережить удаление и восстановление той же id
        // через transition. Здесь поза зависит только от времени и режима:
        // у восстановленной карточки вне редактирования всегда нулевой наклон.
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !active)) { context in
            let elapsed = startedAt.map { max(0, context.date.timeIntervalSince($0)) } ?? 0
            let ramp = active ? min(1, elapsed / 0.16) : 0
            let phase = variation * 2 * .pi
            let rotation = ramp * angle * sin(elapsed * .pi / (0.18 + variation * 0.035) + phase)
            let offset = ramp * 0.35 * sin(elapsed * .pi / (0.22 + variation * 0.025) + phase)
            content
                .rotationEffect(.degrees(rotation))
                .offset(y: offset)
                // Обновления времени и восстановление не запускают implicit
                // анимацию трансформаций. Переход самой ячейки остаётся снаружи.
                .transaction { $0.animation = nil }
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
        .onChange(of: active, initial: true) { _, value in startedAt = value ? .now : nil }
    }
}
