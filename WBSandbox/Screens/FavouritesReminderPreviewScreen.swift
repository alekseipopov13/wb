import SwiftUI

struct FavouritesReminderPreviewScreen: View {
    let onClose: () -> Void
    @State private var replayID = 0

    private var shortcut: PaymentShortcut {
        PaymentShortcut.catalogue.first { $0.id == "rostelecom" }!
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer(minLength: 0)
                PaymentShortcutCard(shortcut: shortcut)
                    .frame(width: FavouritesDeckLayout.cardSize.width, height: FavouritesDeckLayout.cardSize.height)
                    .overlay(alignment: .topLeading) {
                        FavouritesUpcomingPaymentMessage(message: shortcut.upcomingPaymentMessage ?? "",
                                                         cardHeight: FavouritesDeckLayout.cardSize.height,
                                                         replayID: replayID)
                    }
                Spacer(minLength: 0)
                WBPrimaryButton(title: "Повторить появление") { replayID += 1 }
                    .accessibilityIdentifier("favourites.reminderReplay")
            }
            .padding(24)
            .background(WBColor.bgBase.ignoresSafeArea())
            .navigationTitle("Скоро оплата")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Закрыть", action: onClose) }
            }
        }
    }
}
