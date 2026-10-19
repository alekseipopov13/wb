import SwiftUI

/// 04. Header tap with saved cards visible: the actual geometry flight.
struct FavouritesHeaderFlightDemoScreen: View {
    let onClose: () -> Void
    var body: some View {
        FavouritesPaymentsScreen(feedVariant: .allFavouritesFolder, animationDemo: .headerFromEnd, onBack: onClose)
    }
}
