import SwiftUI
import Observation

enum PaymentsHubRoute: Identifiable {
    case phone, requisites, betweenAccounts, crossBorder, qr, utilities, internet, uin
    case shortcut(PaymentShortcut)
    case walletTopUp
    case category(PaymentHubCategory)

    var id: String {
        switch self {
        case .phone: "phone"
        case .requisites: "requisites"
        case .betweenAccounts: "between-accounts"
        case .crossBorder: "cross-border"
        case .qr: "qr"
        case .utilities: "utilities"
        case .internet: "internet"
        case .uin: "uin"
        case .shortcut(let shortcut): "shortcut-\(shortcut.id)"
        case .walletTopUp: "wallet-top-up"
        case .category(let category): "category-\(category.rawValue)"
        }
    }
}

struct PaymentShortcut: Identifiable {
    let id: String
    var title: String
    let subtitle: String
    let asset: String
    var amount: Decimal = 0
    var isPayment = false
    var detail: String?
    var utility: SavedUtilityDetails?
    var operationAmount: Decimal?
    /// Напоминание поставщика; обычные избранные и рекомендации его не имеют.
    var upcomingPaymentMessage: String?

    var route: PaymentsHubRoute {
        if id == "wallet-top-up" { return .walletTopUp }
        if id == "my-phone" && detail == nil { return .category(.mobile) }
        return .shortcut(self)
    }

    var accountDetail: String { detail ?? subtitle }
    var amountLabel: String? { amount > 0 ? Money.rub(amount) : nil }
    var feedSubtitle: String { subtitle.contains("₽") ? (amountLabel ?? accountDetail) : subtitle }
    var editorAsset: String {
        switch asset {
        case "favRostelecom": "favRostelecomEditor"
        case "favMTS": "favMTSEditor"
        default: asset
        }
    }
    var isGenericMobile: Bool { id == "my-phone" && detail == nil }

    var transaction: TransactionConfig {
        var config = isPayment ? TransferModes.utilities : TransferModes.byPhone
        config.id = id
        config.demoName = title
        config.title = isPayment ? title : "Перевести"
        config.initialAmount = amount
        config.message = nil
        config.destination = DetailRow(
            id: id, icon: .asset(asset),
            top: .primary(title), bottom: .secondary(accountDetail)
        )
        config.success.counterparty = title
        config.success.icon = .asset(asset)
        config.success.chip = nil
        return config
    }

    static let catalogue: [PaymentShortcut] = [
        .init(id: "self-vtb", title: "Себе", subtitle: "+7 910 282-11-13", asset: "favVTB"),
        .init(id: "my-phone", title: "Мой телефон", subtitle: "+7 913 654-11-56", asset: "favMegafon", isPayment: true, detail: "+7 913 654-11-56"),
        .init(id: "self-tbank", title: "Себе", subtitle: "+7 910 282-11-13", asset: "favTBank"),
        .init(id: "self-alfa", title: "Себе", subtitle: "+7 910 282-11-13", asset: "favAlfa"),
        .init(id: "electricity", title: "ЖКУ электричество", subtitle: "лс 8888888888", asset: "favElectricity", isPayment: true, detail: "Тула, Литейная 68", utility: .init(account: "8888888888", previousReading: 1284)),
        .init(id: "rostelecom", title: "Ростелеком", subtitle: "420 ₽", asset: "favRostelecom", amount: 420, isPayment: true, detail: "+7 900 123-45-67", upcomingPaymentMessage: "Скоро оплата\n15 октября"),
        .init(id: "mts", title: "МТС и МГТС", subtitle: "111122223333", asset: "favMTS", isPayment: true, operationAmount: Decimal(string: "868.95")),
        .init(id: "mother", title: "Маме", subtitle: "1 000 ₽", asset: "favAlfa", amount: 1000, detail: "+7 953 375-12-95"),
        .init(id: "wallet-top-up", title: "Пополнить кошелёк", subtitle: "", asset: "favWalletTopUp"),
    ]

    static let history: [PaymentShortcut] = [
        .init(id: "history-phone", title: "Мобильная связь", subtitle: "+7 925 310-22-44", asset: "favMegafon", amount: 500, isPayment: true),
        .init(id: "history-internet", title: "Домашний интернет", subtitle: "лс 1234567890", asset: "favRostelecom", amount: 650, isPayment: true),
        .init(id: "history-transfer", title: "Александру", subtitle: "+7 910 220-33-44", asset: "favTBank", amount: 1500),
    ]

    static let genericMobile = PaymentShortcut(
        id: "my-phone", title: "Пополнить свой телефон", subtitle: "", asset: "favMegafon", isPayment: true
    )
}

enum FavouritesDemoScenario: String, CaseIterable {
    case full, empty, openBanking, recents
}

/// Один владелец данных для ленты ПиП, экрана избранного и добавления из истории.
@Observable
final class PaymentsFavouritesStore {
    let openBanking: Bool
    private(set) var saved: [PaymentShortcut]
    private(set) var history: [PaymentsFeedPolicy.Usage]
    private(set) var lastAddition: FavouritesAddition?

    init(scenario: FavouritesDemoScenario = .full) {
        openBanking = scenario == .full || scenario == .openBanking || scenario == .recents
        saved = scenario == .full
            ? ["rostelecom", "electricity", "mts", "mother"].compactMap { id in PaymentShortcut.catalogue.first { $0.id == id } }
            : []
        history = scenario == .full || scenario == .recents ? [
            .init(id: "self-tbank", count: 20, lastUsed: 12),
            .init(id: "self-alfa", count: 12, lastUsed: 11),
            .init(id: "rostelecom", count: 8, lastUsed: 10),
            .init(id: "mother", count: 6, lastUsed: 9),
            .init(id: "electricity", count: 4, lastUsed: 8),
            .init(id: "mts", count: 3, lastUsed: 7),
            .init(id: "history-phone", count: 2, lastUsed: 6),
            .init(id: "history-internet", count: 1, lastUsed: 5),
            .init(id: "history-transfer", count: 1, lastUsed: 4),
        ] : []
    }

    var feed: [PaymentShortcut] {
        PaymentsFeedPolicy.cardIDs(openBanking: openBanking, history: history, savedIDs: saved.map(\.id)).compactMap { id in
            if id == "my-phone" && history.isEmpty { return .genericMobile }
            return shortcut(id)
        }
    }

    var hiddenFavourites: [PaymentShortcut] {
        let visible = Set(feed.map(\.id))
        return saved.filter { !visible.contains($0.id) }
    }

    var historyItems: [PaymentShortcut] {
        history.sorted { $0.lastUsed > $1.lastUsed }.compactMap { shortcut($0.id) }
    }

    func contains(_ shortcut: PaymentShortcut) -> Bool { saved.contains { $0.id == shortcut.id } }
    func add(_ shortcut: PaymentShortcut) {
        guard !contains(shortcut) else { return }
        saved.insert(shortcut, at: 0)
        lastAddition = FavouritesAddition(shortcutID: shortcut.id)
    }
    func remove(at offsets: IndexSet) { saved.remove(atOffsets: offsets) }
    func move(from offsets: IndexSet, to destination: Int) { saved.move(fromOffsets: offsets, toOffset: destination) }
    func remove(_ shortcut: PaymentShortcut) -> FavouritesRemoval<PaymentShortcut>? {
        FavouritesRemoval.remove(shortcut.id, from: &saved)
    }
    @discardableResult
    func restore(_ removal: FavouritesRemoval<PaymentShortcut>) -> Bool {
        removal.restore(in: &saved)
    }
    func update(_ shortcut: PaymentShortcut) {
        guard let index = saved.firstIndex(where: { $0.id == shortcut.id }) else { return }
        saved[index] = shortcut
    }

    private func shortcut(_ id: String) -> PaymentShortcut? {
        saved.first { $0.id == id }
            ?? (PaymentShortcut.catalogue + PaymentShortcut.history).first { $0.id == id }
    }
}

enum PaymentHubCategory: String, CaseIterable, Identifiable {
    case qr, mobile, utilities, internet, uin, patent, games, foreign

    var id: String { rawValue }

    var title: String {
        switch self {
        case .qr: "По QR-коду"
        case .mobile: "Мобильную\nсвязь"
        case .utilities: "ЖКУ"
        case .internet: "Интернет,\nтелефон, ТВ"
        case .uin: "По УИН"
        case .patent: "Трудовой\nпатент"
        case .games: "Игры и досуг"
        case .foreign: "Зарубежные\nсервисы"
        }
    }

    var asset: String {
        switch self {
        case .qr: "favArtQR"
        case .mobile: "favArtMobile"
        case .utilities: "favArtUtilities"
        case .internet: "favArtInternet"
        case .uin: "favArtUIN"
        case .patent: "favArtPatent"
        case .games: "favArtGames"
        case .foreign: "favArtForeign"
        }
    }

    var route: PaymentsHubRoute {
        switch self {
        case .qr: .qr
        case .utilities: .utilities
        case .internet: .internet
        case .uin: .uin
        default: .category(self)
        }
    }

    var referenceLabel: String {
        switch self {
        case .mobile: "Номер телефона"
        case .patent: "ИНН получателя патента"
        case .games: "Аккаунт или ID игрока"
        default: "Аккаунт или лицевой счёт"
        }
    }
}
