import SwiftUI

/// 02. Real end-of-feed gesture, threshold, haptics and card-to-grid flight.
struct FavouritesDeckPullDemoScreen: View {
    let onClose: () -> Void
    var body: some View {
        FavouritesPaymentsScreen(feedVariant: .allFavouritesFolder, animationDemo: .pull, onBack: onClose)
    }
}
