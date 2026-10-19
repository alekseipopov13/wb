import Foundation
import CoreGraphics

@main
struct CheckFavouritesReminder {
    static func main() {
        let pin = FavouritesReminderGeometry.pin
        let origin = FavouritesReminderGeometry.origin
        func close(_ a: CGPoint, _ b: CGPoint, _ label: String) {
            precondition(hypot(a.x - b.x, a.y - b.y) < 0.000001, label)
        }
        // Squash/stretch также вращаются вокруг той же опоры, а не центра тела.
        for (scaleX, scaleY) in [(0.08, 0.2), (0.68, 1.1), (1.12, 0.94), (1.0, 1.0)] {
            for angle in [-9.0, 0.0, 3.8] {
                close(pin.applying(FavouritesReminderGeometry.transform(scaleX: scaleX, scaleY: scaleY, rotation: angle)),
                      pin, "Деформация сдвигает хвостик")
            }
        }
        // Центр маленькой точки хвостика неподвижен во время роста и поворота,
        // в том числе при пружинном перелёте масштаба и угла.
        for scale in [0.0, 0.05, 0.4, 0.9, 1.0, 1.05] {
            for angle in [-1.5, 0.0, 2.0, 4.5] {
                close(pin.applying(FavouritesReminderGeometry.transform(scale: scale, rotation: angle)), pin,
                      "Хвостик смещается при scale=\(scale), rotation=\(angle)")
            }
        }
        let rest = FavouritesReminderGeometry.transform(scale: 1, rotation: 0)
        let topLeft = CGPoint.zero.applying(rest)
        close(CGPoint(x: topLeft.x + origin.x, y: topLeft.y + origin.y),
              CGPoint(x: 12, y: 11.509765625), "Финальная поза не совпадает с Figma")
        let freeCorner = CGPoint(x: 108, y: 0)
        let lowered = freeCorner.applying(FavouritesReminderGeometry.transform(scale: 1, rotation: 4.5))
        let settled = freeCorner.applying(rest)
        precondition(lowered.y > settled.y + 7, "Свободный край должен опускаться от поворота")
        let initial = freeCorner.applying(FavouritesReminderGeometry.transform(scale: 0, rotation: 0))
        close(initial, pin, "Рост начинается не из хвостика")
        print("Favourites reminder: pinned tail, scale overshoot, rotation and exact Figma resting pose passed")
    }
}
