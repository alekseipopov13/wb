import SwiftUI

/// Общие роли движения. Эталон характера — OutcomeScreen и раскрытие открытки.
enum SandboxMotion {
    /// Состояния поля: непрерывное движение без заметного отскока.
    static let fieldState = Animation.spring(response: 0.34, dampingFraction: 0.86)

    static let cardReflow = Animation.spring(response: 0.46, dampingFraction: 0.86)

    static func favouritesEditing(reduceMotion: Bool) -> Animation {
        .easeInOut(duration: reduceMotion ? 0.1 : 0.2)
    }

    static func favouritesRemoval(reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.32, dampingFraction: 0.9)
    }

    enum CardInsertion {
        struct TravelPose { var progress: Double = 0 }
        /// Медленный старт даёт следующему соседу время подхватить движение.
        /// Точное время общее для всей цепочки, включая перенос между строками.
        static let travel = KeyframeTimeline(initialValue: TravelPose()) {
            KeyframeTrack(\.progress) {
                CubicKeyframe(1, duration: 0.58, startVelocity: 0, endVelocity: 0)
            }
        }

        struct Pose {
            var scale: Double = 0.04
            var aspect: Double = 0.84
            var light: Double = 0
        }

        static let timeline = KeyframeTimeline(initialValue: Pose()) {
            KeyframeTrack(\.scale) {
                SpringKeyframe(1, duration: 0.46, spring: .init(response: 0.34, dampingRatio: 0.66))
                LinearKeyframe(1, duration: 0.26)
            }
            KeyframeTrack(\.aspect) {
                CubicKeyframe(1.045, duration: 0.24, startVelocity: 0, endVelocity: 0)
                SpringKeyframe(1, duration: 0.48, spring: .init(response: 0.28, dampingRatio: 0.74))
            }
            KeyframeTrack(\.light) {
                CubicKeyframe(0.22, duration: 0.16, startVelocity: 0, endVelocity: 0)
                CubicKeyframe(0, duration: 0.56, startVelocity: 0, endVelocity: 0)
            }
        }

        /// Уже видимая рекомендация может стать избранным. Она остаётся на
        /// экране, слегка сжимается и получает тот же пружинный отклик.
        static let promotion = KeyframeTimeline(initialValue: Pose(scale: 1, aspect: 1)) {
            KeyframeTrack(\.scale) {
                CubicKeyframe(0.9, duration: 0.12, startVelocity: 0, endVelocity: 0)
                SpringKeyframe(1, duration: 0.6, spring: .init(response: 0.32, dampingRatio: 0.7))
            }
            KeyframeTrack(\.aspect) {
                CubicKeyframe(1.04, duration: 0.12, startVelocity: 0, endVelocity: 0)
                SpringKeyframe(1, duration: 0.6, spring: .init(response: 0.28, dampingRatio: 0.74))
            }
            KeyframeTrack(\.light) {
                CubicKeyframe(0.22, duration: 0.18, startVelocity: 0, endVelocity: 0)
                CubicKeyframe(0, duration: 0.54, startVelocity: 0, endVelocity: 0)
            }
        }

        static let restingPose = Pose(scale: 1, aspect: 1)
    }

    enum CardRemoval {
        struct Pose { var progress: Double = 0 }
        static let timeline = KeyframeTimeline(initialValue: Pose()) {
            KeyframeTrack(\.progress) {
                CubicKeyframe(1, duration: 0.24, startVelocity: 0, endVelocity: 0)
            }
        }
    }

    /// Появление сообщения из закреплённого хвостика.
    /// Рост, деформация и поворот перекрываются, сохраняя инерцию одного объекта.
    enum TailMessage {
        struct Pose {
            var scale: Double = 0
            var aspect: Double = 0.68
            var rotation: Double = -9
        }

        static let delay: Duration = .milliseconds(100)
        static let timeline = KeyframeTimeline(initialValue: Pose()) {
            KeyframeTrack(\.scale) {
                SpringKeyframe(1, duration: 0.54, spring: .init(response: 0.38, dampingRatio: 0.66))
                LinearKeyframe(1, duration: 0.44)
            }
            KeyframeTrack(\.aspect) {
                CubicKeyframe(1.06, duration: 0.3, startVelocity: 0, endVelocity: 0)
                SpringKeyframe(1, duration: 0.68, spring: .init(response: 0.32, dampingRatio: 0.72))
            }
            KeyframeTrack(\.rotation) {
                CubicKeyframe(3.8, duration: 0.38, startVelocity: 0, endVelocity: 0)
                SpringKeyframe(0, duration: 0.6, spring: .init(response: 0.36, dampingRatio: 0.7))
            }
        }

        static let restingPose = Pose(scale: 1, aspect: 1, rotation: 0)
    }
}
