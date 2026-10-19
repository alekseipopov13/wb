import SwiftUI

/// Витрина настоящих компонентов: повторяемая вставка в начало и все аватары.
struct FavouritesComponentsPreviewScreen: View {
    let onClose: () -> Void
    @State private var mode = UserDefaults.standard.bool(forKey: "demoFavouritesAvatars") ? 1 : 0
    @State private var shortcuts = Self.initialCards
    @State private var addition: FavouritesAddition?
    @State private var generation = 0

    private static var initialCards: [PaymentShortcut] {
        [PaymentShortcut.history.first { $0.id == "history-internet" }!]
        + ["electricity", "mother", "mts"].compactMap { id in PaymentShortcut.catalogue.first { $0.id == id } }
    }

    private var hasAdded: Bool { shortcuts.contains { $0.id == "history-transfer" } }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Picker("Компонент", selection: $mode) {
                    Text("Добавление").tag(0)
                    Text("Иконки").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)

                ScrollView {
                    if mode == 0 {
                        FavouritesAnimatedCollection(
                            items: shortcuts.map(FavouritesCollectionItem.shortcut),
                            arrangement: .grid, addition: addition
                        ) { item, _ in
                            if case .shortcut(let shortcut) = item {
                                PaymentShortcutCard(shortcut: shortcut, savedProgress: 1)
                            }
                        }
                        .id(generation)
                        .padding(16)
                    } else {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 24) {
                            ForEach(PaymentShortcut.catalogue) { shortcut in
                                VStack(spacing: 8) {
                                    FavouritesEditorAvatar(shortcut: shortcut)
                                    Text(shortcut.title)
                                        .font(PaymentsHubFont.regular(13))
                                        .multilineTextAlignment(.center)
                                        .frame(height: 34, alignment: .top)
                                }
                            }
                        }
                        .padding(16)
                    }
                }
                .scrollClipDisabled()
            }
            .safeAreaInset(edge: .bottom) {
                if mode == 0 {
                    VStack(spacing: 12) {
                        WBPrimaryButton(title: "Добавить Александру", isEnabled: !hasAdded) {
                            let shortcut = PaymentShortcut.history.first { $0.id == "history-transfer" }!
                            shortcuts.insert(shortcut, at: 0)
                            addition = FavouritesAddition(shortcutID: shortcut.id)
                        }
                        .accessibilityIdentifier("favourites.preview.add")
                        Button("Сбросить") {
                            shortcuts = Self.initialCards
                            addition = nil
                            generation += 1
                        }
                        .accessibilityIdentifier("favourites.preview.reset")
                    }
                    .padding(16)
                    .background(WBColor.bgBase)
                }
            }
            .background(WBColor.bgBase.ignoresSafeArea())
            .navigationTitle("Компоненты избранного")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Закрыть", action: onClose) } }
        }
    }
}
