import SwiftUI

/// 07. An already visible recommendation becomes saved without moving its slot.
struct FavouritesPromotionDemoScreen: View {
    let onClose: () -> Void
    @State private var addition: FavouritesAddition?
    @State private var generation = 0

    private var cards: [PaymentShortcut] { Array(FavouritesAnimationSamples.cards.prefix(3)) }

    var body: some View {
        FavouritesAnimationDemoShell(title: "Сохранение рекомендации",
                                    instruction: "«Домашний интернет» уже виден в ленте. При сохранении карточка слегка сожмётся и пружинит на своём месте.", onClose: onClose) {
            ScrollView(.horizontal, showsIndicators: false) {
                FavouritesAnimatedCollection(items: cards.map(FavouritesCollectionItem.shortcut), arrangement: .row, addition: addition) { item, _ in
                    if case .shortcut(let shortcut) = item { PaymentShortcutCard(shortcut: shortcut) }
                }
                .id(generation)
                .padding(16)
                .padding(.vertical, 24)
            }
            .scrollClipDisabled()
        } controls: {
            FavouritesAnimationDemoActions(title: "Сохранить домашний интернет", isEnabled: addition == nil) {
                addition = FavouritesAddition(shortcutID: cards[0].id)
            } onReset: {
                addition = nil
                generation += 1
            }
        }
    }
}
