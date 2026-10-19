import SwiftUI

/// Одна карточка для ленты, стопки и сетки. При перелёте меняется представление
/// реквизита и суммы, а аватарка остаётся на своём месте внутри карточки.
struct PaymentShortcutCard: View {
    let shortcut: PaymentShortcut
    var savedProgress: CGFloat = 0
    var isLinkedAccount = false
    var borderOpacity: Double = 0

    private var progress: CGFloat { min(1, max(0, savedProgress)) }
    private var isWallet: Bool { shortcut.id == "wallet-top-up" }
    private var hasOnlyTitle: Bool { isWallet || shortcut.isGenericMobile }
    private var feedTitle: String {
        if isWallet { return "Пополнить\nкошелёк" }
        if shortcut.isGenericMobile { return "Пополнить\nсвой телефон" }
        return shortcut.title
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                PaymentShortcutAvatar(shortcut: shortcut)
                Spacer(minLength: 0)
                if let amount = shortcut.amountLabel {
                    Text(amount)
                        .font(PaymentsHubFont.medium(13))
                        .foregroundStyle(WBColor.textSecondary)
                        .lineLimit(1)
                        .frame(height: 17)
                        .opacity(Double(progress))
                }
            }

            Spacer(minLength: 0)

            ZStack(alignment: .topLeading) {
                feedLabels.opacity(Double(1 - progress))
                savedLabels.opacity(Double(progress))
            }
            .frame(height: (hasOnlyTitle ? 34 : 33) + (hasOnlyTitle ? 5 : 6) * progress, alignment: .topLeading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(WBColor.bgLevel2)
                .overlay {
                    if isLinkedAccount {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.dynamic(light: 0xDFF3FF, dark: 0x173244))
                            .opacity(Double(1 - progress))
                    }
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(WBColor.bgBase, lineWidth: 2)
                .opacity(borderOpacity)
        }
        .contentShape(RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityTitle)
    }

    private var feedLabels: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(feedTitle)
                .font(WBFont.descriptionAccent)
                .lineLimit(hasOnlyTitle ? 2 : 1)
                .frame(height: hasOnlyTitle ? 34 : 17, alignment: .leading)
            if !hasOnlyTitle {
                Text(shortcut.feedSubtitle)
                    .font(WBFont.caption)
                    .foregroundStyle(WBColor.textSecondary)
                    .lineLimit(1)
                    .frame(height: 14, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var savedLabels: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(shortcut.title)
                .font(PaymentsHubFont.medium(15))
                .lineLimit(1)
                .frame(height: 20, alignment: .leading)
            Text(shortcut.accountDetail)
                .font(PaymentsHubFont.regular(13))
                .foregroundStyle(WBColor.textSecondary)
                .lineLimit(1)
                .frame(height: 17, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var accessibilityTitle: String {
        if progress < 0.5 {
            return [shortcut.title, shortcut.feedSubtitle].filter { !$0.isEmpty }.joined(separator: ", ")
        }
        return [shortcut.title, shortcut.accountDetail, shortcut.amountLabel].compactMap { $0 }.joined(separator: ", ")
    }
}

struct FavouritesFeedFramesKey: PreferenceKey {
    static var defaultValue: [String: CGRect] { [:] }
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

struct SavedFavouritesFramesKey: PreferenceKey {
    static var defaultValue: [String: CGRect] { [:] }
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}
