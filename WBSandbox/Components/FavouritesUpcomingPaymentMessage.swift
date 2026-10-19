import SwiftUI

/// Общее сообщение WB, появляющееся из «прибитого» хвостика.
/// В Figma задан только финальный кадр; хореография — по описанию пользователя.
struct FavouritesUpcomingPaymentMessage: View {
    let message: String
    var cardHeight: CGFloat = FavouritesReminderGeometry.referenceCardHeight
    var replayID = 0
    /// Видимость запускает только первое появление. Уход за край не удаляет
    /// сообщение и не обнуляет уже начатую анимацию.
    var isReadyToAppear = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var startedAt: Date?
    @State private var finished = false
    @State private var hasBecomeReady = false

    private var fixedElapsed: Double? {
        UserDefaults.standard.string(forKey: "demoReminderElapsed").flatMap(Double.init)
    }

    var body: some View {
        TimelineView(.animation(paused: finished || startedAt == nil || reduceMotion || scenePhase != .active || fixedElapsed != nil)) { context in
            let elapsed = fixedElapsed ?? startedAt.map { max(0, context.date.timeIntervalSince($0)) } ?? 0
            let pose = reduceMotion || finished
                ? SandboxMotion.TailMessage.restingPose
                : SandboxMotion.TailMessage.timeline.value(time: elapsed)
            let origin = FavouritesReminderGeometry.origin(cardHeight: cardHeight)
            WBMessageBubble(
                message: message,
                position: .left,
                tailImage: Image("favUpcomingPaymentTail"),
                metrics: .favouriteReminder,
                style: .init(
                    font: PaymentsHubFont.regular(13),
                    textColor: WBColor.textPrimary,
                    bubbleBackground: WBColor.bgBase,
                    bubbleStroke: WBColor.strokeSecondary
                )
            )
            .frame(width: FavouritesReminderGeometry.size.width, height: FavouritesReminderGeometry.size.height)
            // Невырожденная матрица: Core Animation может отрисовать scale=0
            // как identity и дать вспышку полноразмерной плашки до роста.
            // Вытягивание и обратное сжатие сохраняют площадь: X = s·a, Y = s/a.
            .projectionEffect(ProjectionTransform(FavouritesReminderGeometry.transform(
                scaleX: max(0.0001, pose.scale * pose.aspect),
                scaleY: max(0.0001, pose.scale / pose.aspect),
                rotation: pose.rotation
            )))
            .opacity(pose.scale > 0 ? 1 : 0)
            .offset(x: origin.x, y: origin.y)
            // Матрица уже содержит всю хореографию. Родительская анимация
            // удаления/перелёта не должна повторно интерполировать её кадры.
            .transaction { $0.animation = nil }
        }
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(message.replacingOccurrences(of: "\n", with: ", "))
        .accessibilityIdentifier("favourites.upcomingPayment")
        .onChange(of: isReadyToAppear, initial: true) { _, ready in
            if ready { hasBecomeReady = true }
        }
        .task(id: hasBecomeReady ? replayID : nil) {
            guard hasBecomeReady, fixedElapsed == nil else { return }
            finished = false
            startedAt = nil
            guard !reduceMotion else { finished = true; return }
            do {
                try await Task.sleep(for: SandboxMotion.TailMessage.delay)
                startedAt = .now
                try await Task.sleep(for: .seconds(SandboxMotion.TailMessage.timeline.duration))
                finished = true
            } catch { return }
        }
        .onChange(of: reduceMotion) { _, value in if value { finished = true } }
        .onChange(of: scenePhase) { _, value in if value != .active { finished = true } }
    }
}
