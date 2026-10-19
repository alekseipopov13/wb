import SwiftUI

/// The real removal model, cascading collection reflow, toast and undo.
struct FavouritesRemovalDemoScreen: View {
    let onClose: () -> Void
    @State private var store = PaymentsFavouritesStore()
    @State private var removal: FavouritesRemoval<PaymentShortcut>?
    @State private var generation = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        FavouritesAnimationDemoShell(title: "Удаление и отмена",
                                    instruction: "Уберите Ростелеком: карточка схлопнется, а соседи сдвинутся цепочкой. «Отменить» плавно вернёт её на своё место без покачивания.", onClose: onClose) {
            ScrollView {
                FavouritesAnimatedCollection(items: store.saved.map(FavouritesCollectionItem.shortcut), arrangement: .grid, addition: nil) { item, _ in
                    if case .shortcut(let shortcut) = item { PaymentShortcutCard(shortcut: shortcut, savedProgress: 1) }
                }
                .id(generation)
                .padding(16)
            }
        } controls: {
            VStack(spacing: 12) {
                if let removal {
                    FavouritesSnackbar(expiresAt: removal.expiresAt, onUndo: undo)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                FavouritesAnimationDemoActions(title: "Убрать Ростелеком", isEnabled: store.saved.contains { $0.id == "rostelecom" }) {
                    guard let card = store.saved.first(where: { $0.id == "rostelecom" }) else { return }
                    Haptics.impact(.soft, intensity: 0.55)
                    withAnimation(SandboxMotion.favouritesRemoval(reduceMotion: reduceMotion)) { removal = store.remove(card) }
                } onReset: {
                    removal = nil
                    store = PaymentsFavouritesStore()
                    generation += 1
                }
            }
        }
        .task(id: removal?.id) {
            guard let current = removal else { return }
            do { try await Task.sleep(for: .seconds(max(0, current.expiresAt.timeIntervalSinceNow))) } catch { return }
            guard removal?.id == current.id else { return }
            withAnimation(.easeOut(duration: 0.2)) { removal = nil }
        }
    }

    private func undo() {
        guard let removal else { return }
        withAnimation(SandboxMotion.favouritesRemoval(reduceMotion: reduceMotion)) {
            if store.restore(removal) { Haptics.impact(.soft, intensity: 0.4) }
            self.removal = nil
        }
    }
}
