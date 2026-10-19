import SwiftUI

/// 06. Grid insertion: stable cards travel in a cascade, including row wrapping.
struct FavouritesGridInsertionDemoScreen: View {
    let onClose: () -> Void
    @State private var cards = FavouritesAnimationSamples.cards
    @State private var addition: FavouritesAddition?
    @State private var generation = 0

    var body: some View {
        FavouritesAnimationDemoShell(title: "Добавление в сетку",
                                    instruction: "Добавьте Александру в начало. Остальные карточки сдвинутся цепочкой, сохраняя порядок и проходя между строками по дуге.", onClose: onClose) {
            ScrollView {
                FavouritesAnimatedCollection(items: cards.map(FavouritesCollectionItem.shortcut), arrangement: .grid, addition: addition) { item, _ in
                    if case .shortcut(let shortcut) = item { PaymentShortcutCard(shortcut: shortcut, savedProgress: 1) }
                }
                .id(generation)
                .padding(16)
            }
            .scrollClipDisabled()
        } controls: {
            FavouritesAnimationDemoActions(title: "Добавить Александру", isEnabled: addition == nil) {
                let card = FavouritesAnimationSamples.newCard
                cards.insert(card, at: 0)
                addition = FavouritesAddition(shortcutID: card.id)
            } onReset: {
                cards = FavouritesAnimationSamples.cards
                addition = nil
                generation += 1
            }
        }
    }
}
