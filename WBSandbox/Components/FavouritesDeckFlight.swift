import SwiftUI

/// Положение каждой настоящей карточки в стопке, до поворота и масштабирования.
struct FavouritesCardPose {
    var frame: CGRect
    var scale: CGFloat = 1
    var rotation: Double = 0
    var borderOpacity: Double = 0
}

enum FavouritesDeckLayout {
    static let coordinateSpace = "favourites-deck-scene"
    static let cardSize = CGSize(width: 122, height: 102)

    /// Figma 60982:633273: 114/122 при +4°, 106/122 при −8°.
    static func hiddenPose(index: Int, behind frame: CGRect, pull: CGFloat) -> FavouritesCardPose {
        let nearest = index == 0
        return FavouritesCardPose(
            frame: frame.offsetBy(dx: (nearest ? 7 : 11) + (nearest ? 24 : 44) * pull,
                                  dy: (nearest ? -13 : 11) + (nearest ? -10 : 6) * pull),
            scale: nearest ? 114.0 / 122 : 106.0 / 122,
            rotation: nearest ? 4 + 8 * Double(pull) : -8 - 6 * Double(pull),
            borderOpacity: 1
        )
    }
}

struct FavouritesCardFlight: Identifiable {
    let shortcut: PaymentShortcut
    let source: FavouritesCardPose
    let destination: CGRect
    let isLinkedAccount: Bool
    let layer: Double
    var id: String { shortcut.id }
}

/// Геометрия летит из ленты в реальные координаты сетки: экран не подменяется
/// отдельным пушем после жеста. Тексты и сумма переходят в формат избранного.
struct FavouritesDeckFlightCard: View, Animatable {
    let flight: FavouritesCardFlight
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        let source = flight.source
        let destination = flight.destination
        let p = min(1, max(0, progress))
        PaymentShortcutCard(
            shortcut: flight.shortcut,
            savedProgress: p,
            isLinkedAccount: flight.isLinkedAccount,
            borderOpacity: source.borderOpacity * Double(1 - p)
        )
        .frame(width: mix(source.frame.width, destination.width),
               height: mix(source.frame.height, destination.height))
        .scaleEffect(source.scale + (1 - source.scale) * progress)
        .rotationEffect(.degrees(source.rotation * Double(1 - p)))
        .shadow(color: .black.opacity(0.07 * sin(Double(p) * .pi)), radius: 12, y: 4)
        .position(x: mix(source.frame.midX, destination.midX), y: mix(source.frame.midY, destination.midY))
        .zIndex(flight.layer)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func mix(_ start: CGFloat, _ end: CGFloat) -> CGFloat {
        start + (end - start) * progress
    }
}
