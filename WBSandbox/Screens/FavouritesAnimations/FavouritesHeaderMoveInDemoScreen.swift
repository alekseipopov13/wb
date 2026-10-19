import SwiftUI

/// 03. Header tap while all saved cards are outside the visible feed.
struct FavouritesHeaderMoveInDemoScreen: View {
    let onClose: () -> Void
    var body: some View {
        FavouritesPaymentsScreen(feedVariant: .allFavouritesFolder, animationDemo: .headerFromStart, onBack: onClose)
    }
}
