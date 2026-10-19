import Foundation
import CoreGraphics

/// Figma 61104:47356 / 60529:168953. Ось — центр нижней точки хвостика.
enum FavouritesReminderGeometry {
    static let size = CGSize(width: 108, height: 52)
    static let pin = CGPoint(x: 1.763961554, y: 56.356145501)
    static let restingRotation: Double = -8
    static let referenceCardHeight: CGFloat = 118
    private static let figmaOrigin = CGPoint(x: 12, y: 11.509765625)

    /// Перенос из Figma (поворот от верхнего левого угла) к оси на хвостике.
    /// Это постоянная раскладка, а не анимация координат плашки.
    static var origin: CGPoint {
        let rotated = pin.applying(CGAffineTransform(rotationAngle: restingRotation * .pi / 180))
        return CGPoint(x: figmaOrigin.x + rotated.x - pin.x,
                       y: figmaOrigin.y + rotated.y - pin.y)
    }

    static func transform(scale: Double, rotation: Double) -> CGAffineTransform {
        transform(scaleX: scale, scaleY: scale, rotation: rotation)
    }

    static func transform(scaleX: Double, scaleY: Double, rotation: Double) -> CGAffineTransform {
        CGAffineTransform(translationX: pin.x, y: pin.y)
            .rotated(by: (restingRotation + rotation) * .pi / 180)
            .scaledBy(x: scaleX, y: scaleY)
            .translatedBy(x: -pin.x, y: -pin.y)
    }

    /// Напоминание не увеличивает карточку и сохраняет зазор над её подписью.
    static func origin(cardHeight: CGFloat) -> CGPoint {
        CGPoint(x: origin.x, y: origin.y + min(0, cardHeight - referenceCardHeight))
    }
}
