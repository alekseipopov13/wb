import SwiftUI

/// Большая иконка шаблона. Цвет подложки продолжает фон исходной круглой
/// миниатюры до полного квадрата; единственный внешний контур задаётся здесь.
struct FavouritesEditorAvatar: View {
    let shortcut: PaymentShortcut

    private var background: Color {
        switch shortcut.asset {
        case "favVTB": Color(hex: 0x009FDF)
        case "favTBank": Color(hex: 0xFFDD2D)
        case "favAlfa": Color(hex: 0xEF3124)
        case "favMegafon": Color(hex: 0x00B956)
        case "favMTS": Color(hex: 0xFF0032)
        case "favWalletTopUp": Color(hex: 0x038F5D)
        default: WBColor.bgLevel2
        }
    }

    var body: some View {
        Image(shortcut.editorAsset)
            .resizable()
            .scaledToFit()
            .frame(width: 80, height: 80)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
            .rotationEffect(.degrees(-5))
            .frame(width: 86.668, height: 86.668)
            .accessibilityHidden(true)
    }
}
