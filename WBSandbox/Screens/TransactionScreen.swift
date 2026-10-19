import SwiftUI

/// Общий транзакционный шаг ПиП. Сценарий передаёт данные и действия,
/// компоновка и карточки совпадают с эталоном «Между счетами».
struct TransactionScreen: View {
    @Bindable var model: TransactionModel
    var onBack: () -> Void = {}
    @State private var isDestinationPickerPresented = false
    @State private var didAttemptPay = false

    private var config: TransactionConfig { model.config }

    var body: some View {
        PipTransactionLayout(
            title: config.title,
            buttonTitle: buttonTitle,
            buttonSubtitle: buttonSubtitle,
            buttonFill: model.shortfall == nil ? WBColor.ctaFill : WBColor.ctaTopUp,
            onBack: onBack,
            onPay: pay
        ) {
            VStack(spacing: WBSpace.x2) {
                PipTransactionAmount(input: $model.amount, isEditable: model.isAmountEditable)
                if let extra = model.availableExtra, model.isExtraOn(extra) {
                    WBBadgeView(badge: extra.badge)
                }
                if let points = model.qrBonusPoints { WBBonusBadgeView(points: points) }
                if let message = config.message {
                    MessageZone(
                        message: message,
                        isCommentFilled: model.isCommentFilled,
                        commentText: model.commentText,
                        gifts: model.attachedGifts,
                        showsGiftButton: model.showsGiftButton,
                        onTapComment: { model.toggleComment() },
                        onTapGift: { model.addGift() },
                        onRemoveGift: { model.removeGift($0) }
                    )
                }
                if didAttemptPay && model.amountValue <= 0 {
                    Text("Введите сумму")
                        .font(WBFont.description)
                        .foregroundStyle(WBColor.declined)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                if config.ambient != nil {
                    AmbientMoundsField(mood: model.ambientMood)
                        .allowsHitTesting(false)
                }
            }
        } details: {
            VStack(spacing: WBSpace.x2) {
                suggestions
                PipTransactionRouteCards(
                    source: source,
                    destination: destination,
                    onTapSource: { model.isAccountSheetPresented = true },
                    onTapDestination: config.allowsAccountSwap ? { isDestinationPickerPresented = true } : nil
                )
                ForEach(config.toggles) { toggle($0) }
                if let offer = model.upsell {
                    UpsellZone(offer: offer, isOn: Binding(
                        get: { model.isToggleOn(offer.id) },
                        set: { model.setUpsell(offer, $0) }
                    ))
                }
                if let note = config.deliveryNote {
                    Text(note)
                        .font(WBFont.description)
                        .foregroundStyle(WBColor.textSecondary)
                }
            }
        }
        .sheet(isPresented: $model.isAccountSheetPresented) {
            AccountSheet(model: model)
                .presentationDetents([.height(560)])
                .presentationCornerRadius(WBRadius.x6)
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isDestinationPickerPresented) {
            AccountPickerSheet(
                accounts: model.availableAccounts.filter { $0.id != model.selectedAccountID },
                selectedID: model.destinationAccountID ?? ""
            ) { id in
                model.destinationAccountID = id
                isDestinationPickerPresented = false
            }
        }
        .fullScreenCover(isPresented: $model.isOutcomePresented) {
            OutcomeScreen(
                scenario: outcomeScenario,
                amount: model.amountValue,
                badge: model.feeBadge,
                onClose: { model.isOutcomePresented = false }
            )
        }
    }

    private var destination: PipTransactionCardData {
        guard let row = model.destinationRow else { return .empty("Куда") }
        return PipTransactionCardData(title: row.top.value, subtitle: row.bottom?.value ?? "", icon: row.icon)
    }

    private var source: PipTransactionCardData {
        var card = model.selectedAccount.map(PipTransactionCardData.account) ?? .empty("Откуда")
        card.paymentMark = model.selectedRail.mark
        return card
    }

    private var buttonTitle: String {
        if model.shortfall != nil { return "Пополнить на" }
        return config.ctaTitle
    }

    private var buttonSubtitle: String {
        if let shortfall = model.shortfall { return Money.rub(shortfall) }
        return model.feeBadge.text
    }

    private func pay() {
        didAttemptPay = true
        guard model.amountValue > 0 else { return }
        if model.shortfall != nil {
            model.isAccountSheetPresented = true
        } else {
            model.isOutcomePresented = true
        }
    }

    private var outcomeScenario: OutcomeScenario {
        var result = config.success
        result.subtitle = "Со счёта " + (model.selectedAccount?.subtitle ?? "")
        if let row = model.destinationRow {
            result.counterparty = config.accounts.first { $0.id == model.destinationAccountID }?.subtitle ?? row.top.value
            result.icon = row.icon
        }
        if config.message?.kind == .comment {
            result.chip = model.commentText.isEmpty ? nil : model.commentText
        }
        return OutcomeScenario(
            id: config.id + "-processing",
            demoName: config.demoName,
            outcome: .processing,
            source: config,
            override: result
        )
    }

    @ViewBuilder
    private var suggestions: some View {
        switch config.suggestSlot {
        case .amounts(let values):
            if model.isAmountEditable {
                SuggestionChips(values: values.map(Money.rub), onLightBackground: false) { picked in
                    if let index = values.firstIndex(where: { Money.rub($0) == picked }) {
                        model.applyQuickAmount(values[index])
                    }
                }
            }
        case .automation(let row): toggle(row)
        case .promo(let banner): PromoZone(banner: banner)
        case .none: EmptyView()
        }
    }

    private func toggle(_ row: ToggleRow) -> some View {
        ToggleRowView(row: row, isOn: Binding(
            get: { model.isToggleOn(row.id) },
            set: { model.setToggle(row.id, $0) }
        ))
    }
}
