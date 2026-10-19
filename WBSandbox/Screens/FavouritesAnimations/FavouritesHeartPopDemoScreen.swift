import SwiftUI

/// 11. Only the live Pow Pop component from OperationDetailsScreen.
struct FavouritesHeartPopDemoScreen: View {
    let onClose: () -> Void
    @State private var isFavourite = false

    var body: some View {
        FavouritesAnimationDemoShell(title: "Сердце · Pow Pop",
                                    instruction: "Нажмите «В избранное»: кольцо, частицы и заполненное сердце остаются в цвете text/icon Primary. Сбросьте, чтобы повторить.", onClose: onClose) {
            Button {
                Haptics.tap()
                isFavourite.toggle()
            } label: {
                VStack(spacing: 8) {
                    OperationFavouriteIcon(isFavourite: isFavourite)
                        .padding(16)
                        .background(WBColor.bgBase, in: RoundedRectangle(cornerRadius: 16))
                    Text(isFavourite ? "В избранном" : "В избранное")
                        .font(WBFont.descriptionAccent)
                        .frame(height: 17)
                }
                .frame(width: 108)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("favourites.animation.heart")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(WBColor.bgLevel2)
        } controls: {
            WBPrimaryButton(title: "Сбросить") { isFavourite = false }
                .accessibilityIdentifier("favourites.animation.reset")
        }
    }
}
