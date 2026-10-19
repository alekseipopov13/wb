import SwiftUI

/// Shared showcase chrome, data and controls; motion comes from live components.
struct FavouritesAnimationDemoShell<Content: View, Controls: View>: View {
    let title: String
    let instruction: String
    let onClose: () -> Void
    @ViewBuilder let content: () -> Content
    @ViewBuilder let controls: () -> Controls

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text(instruction)
                    .font(PaymentsHubFont.regular(15))
                    .foregroundStyle(WBColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                content().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                controls().padding(16).background(WBColor.bgBase)
            }
            .foregroundStyle(WBColor.textPrimary)
            .background(WBColor.bgBase.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Закрыть", action: onClose)
                        .accessibilityIdentifier("favourites.animation.close")
                }
            }
        }
    }
}

struct FavouritesAnimationDemoActions: View {
    let title: String
    var isEnabled = true
    let onPlay: () -> Void
    let onReset: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            WBPrimaryButton(title: title, titleFont: PaymentsHubFont.medium(17), isEnabled: isEnabled, action: onPlay)
                .accessibilityIdentifier("favourites.animation.play")
            Button("Сбросить", action: onReset)
                .font(PaymentsHubFont.medium(15))
                .frame(minHeight: 36)
                .accessibilityIdentifier("favourites.animation.reset")
        }
    }
}

enum FavouritesAnimationSamples {
    static var cards: [PaymentShortcut] {
        [PaymentShortcut.history.first { $0.id == "history-internet" }!]
        + ["electricity", "mother", "mts"].compactMap { id in PaymentShortcut.catalogue.first { $0.id == id } }
    }
    static var newCard: PaymentShortcut { PaymentShortcut.history.first { $0.id == "history-transfer" }! }
}
