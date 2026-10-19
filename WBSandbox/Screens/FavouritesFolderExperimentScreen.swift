import SwiftUI

/// Изолированная копия сценария: «Избранное → Новый вариант».
/// Общие оплаты, редактор и сетка остаются теми же; меняется только лента.
struct FavouritesFolderExperimentScreen: View {
    let onBack: () -> Void

    var body: some View {
        FavouritesPaymentsScreen(feedVariant: .allFavouritesFolder, onBack: onBack)
    }
}

enum FavouritesFeedVariant {
    case original
    case allFavouritesFolder
}

/// Figma 61122:47466. Счётчик относится ко всему разделу, включая карточки,
/// которые уже видны в ленте, поэтому папка корректна и с одним скрытым избранным.
struct FavouritesFolderCard: View {
    let favourites: [PaymentShortcut]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            FavouritesFolderAvatarCluster(favourites: favourites)
            Spacer(minLength: 0)
            Text("Все\nизбранные · \(favourites.count)")
                .font(WBFont.descriptionAccent)
                .lineSpacing(1.5)
                .frame(height: 34, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(WBSpace.x3)
        .frame(width: 122, height: 102)
        .background(WBColor.bgLevel2, in: RoundedRectangle(cornerRadius: WBRadius.x5))
        .overlay {
            RoundedRectangle(cornerRadius: WBRadius.x5)
                .strokeBorder(WBColor.bgBase, lineWidth: 2)
                .allowsHitTesting(false)
        }
        .contentShape(RoundedRectangle(cornerRadius: WBRadius.x5))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Все избранные, \(favourites.count)")
    }
}

/// Геометрия группы из Figma сохранена, содержимое берётся из первых четырёх
/// карточек полного избранного. При меньшем количестве лишних кружков нет.
private struct FavouritesFolderAvatarCluster: View {
    let favourites: [PaymentShortcut]

    private static let slots: [(size: CGFloat, center: CGPoint)] = [
        (20, CGPoint(x: 10, y: 10)),
        (12, CGPoint(x: 26, y: 6)),
        (14, CGPoint(x: 7, y: 22)),
        (18, CGPoint(x: 23, y: 22)),
    ]

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(favourites.prefix(4).enumerated()), id: \.element.id) { index, favourite in
                let slot = Self.slots[index]
                PaymentShortcutAvatar(shortcut: favourite)
                    .scaleEffect(slot.size / 32)
                    .frame(width: slot.size, height: slot.size)
                    .background(WBColor.bgLevel2, in: Circle())
                    .overlay {
                        Circle().stroke(WBColor.bgBase, lineWidth: slot.size * 0.075)
                    }
                    .position(slot.center)
            }
        }
        .frame(width: 32, height: 32)
        .accessibilityHidden(true)
    }
}
