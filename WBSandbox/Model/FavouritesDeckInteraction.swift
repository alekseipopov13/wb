import Foundation

/// Порог с гистерезисом: обычный скролл и инерционный отскок не открывают экран.
struct FavouritesDeckInteraction {
    enum Feedback: Equatable {
        case none, spread, ready, disarmed
    }

    static let triggerDistance: CGFloat = 72
    static let disarmDistance: CGFloat = 54

    private(set) var distance: CGFloat = 0
    private(set) var isArmed = false
    private var feedbackStep = 0

    var progress: CGFloat { min(1, max(0, distance / Self.triggerDistance)) }

    mutating func update(distance: CGFloat, isInteracting: Bool, hasOverflow: Bool) -> Feedback {
        guard hasOverflow else { reset(); return .none }
        self.distance = max(0, distance)
        guard isInteracting else { return .none }
        let wasArmed = isArmed
        if self.distance >= Self.triggerDistance { isArmed = true }
        if self.distance < Self.disarmDistance { isArmed = false }
        if isArmed && !wasArmed {
            feedbackStep = 3
            return .ready
        }
        if !isArmed && wasArmed { return .disarmed }
        let step = Int(progress * 3)
        if step > feedbackStep {
            feedbackStep = step
            return .spread
        }
        return .none
    }

    var shouldOpenOnRelease: Bool { isArmed && distance >= Self.disarmDistance }

    mutating func reset() {
        distance = 0
        isArmed = false
        feedbackStep = 0
    }
}
