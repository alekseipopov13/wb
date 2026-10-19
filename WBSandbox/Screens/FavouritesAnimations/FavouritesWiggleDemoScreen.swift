import SwiftUI

/// 08. Only the actual editing wiggle; deleting and navigation are absent.
struct FavouritesWiggleDemoScreen: View {
    let onClose: () -> Void
    @State private var isEditing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        FavouritesAnimationDemoShell(title: "Режим редактирования",
                                    instruction: "Включите редактирование. Карточки слегка и несинхронно покачиваются; после «Готово» полностью останавливаются.", onClose: onClose) {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                    ForEach(FavouritesAnimationSamples.cards) { shortcut in
                        PaymentShortcutCard(shortcut: shortcut, savedProgress: 1)
                            .frame(height: 108)
                            .overlay(alignment: .topTrailing) {
                                if isEditing {
                                    Image("favRemove").renderingMode(.template)
                                        .frame(width: 16, height: 16).foregroundStyle(.white)
                                        .frame(width: 24, height: 24)
                                        .background(WBColor.controlsSecondary, in: Circle())
                                        .overlay { Circle().strokeBorder(WBColor.bgBase, lineWidth: 2) }
                                        .offset(x: 4, y: -4)
                                        .accessibilityHidden(true)
                                }
                            }
                            .modifier(FavouritesCardWiggle(enabled: isEditing, seed: shortcut.id))
                    }
                }
                .padding(16)
            }
            .scrollClipDisabled()
        } controls: {
            FavouritesAnimationDemoActions(title: isEditing ? "Готово" : "Редактировать") {
                Haptics.impact(.soft, intensity: 0.4)
                withAnimation(SandboxMotion.favouritesEditing(reduceMotion: reduceMotion)) { isEditing.toggle() }
            } onReset: { isEditing = false }
        }
    }
}
