import SwiftUI

/// Экран 2 концепции с этапами: сумма и оплата. Макеты 48133:30406 (все счета),
/// 48142:113773 (один счёт) и 48142:114753 (произвольная сумма).
///
/// Здесь ничего не заполняют. Экран отвечает на два вопроса: сколько списывают и
/// куда это уйдёт, — поэтому сумма стоит одна на весь экран, а под ней две плитки
/// «откуда → куда». Данные пришли с экрана этапов; менять их возвращаются туда.
///
/// Клавиатура появляется только у произвольной суммы: у выставленного счёта сумма
/// не редактируется, и мигающая каретка над ней обещала бы обратное.
struct ServiceAmountScreen: View {
    @Bindable var model: ServiceFormModel
    var appliesDemoLaunchState = false
    var onBack: () -> Void = {}
    /// Завершить весь платёжный сценарий и вернуться в каталог типов переводов.
    var onFinish: () -> Void = {}
    var onOpenSpec: () -> Void = {}

    @State private var isUrgent = false
    @State private var isFinishing = false

    private var spec: ServiceSpec { model.spec }
    private var recipient: ProviderCard { model.headerProvider }
    /// Произвольная сумма бывает не только после кнопки «Ввести произвольную
    /// сумму» у начисления. Перевод по реквизитам изначально не имеет счёта от
    /// поставщика, поэтому его свободную сумму тоже вводят прямо здесь.
    private var isEditableAmount: Bool {
        model.isCustomAmount || (spec.bills.isEmpty && model.isAmountEditable)
    }

    var body: some View {
        PipTransactionLayout(
            title: model.payTitle,
            buttonTitle: shortfall == nil ? spec.ctaTitle : "Пополнить на",
            buttonSubtitle: shortfall.map(Money.rub) ?? feeNote,
            buttonFill: shortfall == nil ? WBColor.ctaFill : WBColor.ctaTopUp,
            onBack: onBack,
            onPay: pay
        ) {
            VStack(spacing: WBSpace.x2) {
                PipTransactionAmount(input: Binding(
                    get: { model.amount },
                    set: { model.amount = $0; model.isAmountTouched = true }
                ), isEditable: isEditableAmount)
                if let error = model.amountError {
                    Text(error)
                        .font(WBFont.description)
                        .foregroundStyle(WBColor.declined)
                }
            }
        } details: {
            VStack(spacing: WBSpace.x2) {
                if isEditableAmount, !model.quickAmounts.isEmpty {
                    SuggestionChips(values: model.quickAmounts.map(Money.rub), onLightBackground: false) { picked in
                        if let amount = model.quickAmounts.first(where: { Money.rub($0) == picked }) {
                            model.applyQuickAmount(amount)
                        }
                    }
                }
                tiles
                if spec.id == "requisites-budget" { urgentTransfer }
                Text(recipient.timing)
                    .font(WBFont.description)
                    .foregroundStyle(WBColor.textSecondary)
            }
        }
        .sheet(isPresented: $model.isMethodSheetPresented) {
            AccountPickerSheet(
                accounts: model.accounts,
                selectedID: model.selectedAccountID
            ) { id in
                model.selectedAccountID = id
                model.isMethodSheetPresented = false
            }
        }
        .fullScreenCover(isPresented: $model.isOutcomePresented) {
            OutcomeScreen(
                scenario: model.outcomeScenario,
                amount: model.total + urgentFee,
                badge: amountFeeBadge,
                onClose: finishFlow
            )
        }
        .onAppear {
            // Сумма выставленного счёта приходит с прошлого экрана и правке не
            // подлежит; произвольную набирают здесь, поэтому поле сразу в фокусе.
            if model.isCustomAmount {
                model.startCustomAmount()
            } else if !isEditableAmount {
                model.applyQuickAmount(model.stagesAmount)
            }
            if appliesDemoLaunchState && SandboxSettings.startsWithOutcome {
                Task {
                    try? await Task.sleep(for: .milliseconds(250))
                    model.isOutcomePresented = true
                }
            }
        }
    }

    private func finishFlow() {
        guard !isFinishing else { return }
        isFinishing = true
        model.isOutcomePresented = false
        // Сначала закрываем экран результата, затем внешний payment-cover.
        // Одновременное снятие двух fullScreenCover даёт короткий белый кадр.
        Task {
            try? await Task.sleep(for: .milliseconds(320))
            onFinish()
            isFinishing = false
        }
    }

    // MARK: - Сумма

    private func pay() {
        model.didAttemptSubmit = true
        guard model.baseAmount > 0, model.amountError == nil else { return }
        if model.total + urgentFee > (model.selectedAccount?.balance ?? 0) {
            model.isMethodSheetPresented = true
        } else {
            model.isOutcomePresented = true
        }
    }

    /// Вторая строка кнопки: комиссия считается от набранной суммы, поэтому
    /// «Без комиссии» и «Комиссия 5,89 ₽» — одно и то же место, а не два разных.
    private var feeNote: String {
        amountFeeBadge.text
    }

    private var urgentFee: Decimal { isUrgent ? 199 : 0 }

    private var shortfall: Decimal? {
        guard model.baseAmount > 0, let balance = model.selectedAccount?.balance else { return nil }
        let missing = model.total + urgentFee - balance
        return missing > 0 ? missing : nil
    }

    private var amountFeeBadge: BadgeSpec {
        let value = model.feeValue + urgentFee
        guard value > 0 else { return spec.fee.badge(for: model.subtotal) }
        return BadgeSpec(text: "Комиссия \(Money.plain(value))\(Money.nbsp)₽", style: .greenSoft)
    }

    // MARK: - Откуда и куда

    /// Две плитки со стрелкой между ними: слева счёт списания, справа поставщик.
    /// Стрелка нужна не для красоты — она отвечает на «в какую сторону уйдут
    /// деньги» до нажатия кнопки.
    private var tiles: some View {
        PipTransactionRouteCards(
            source: model.selectedAccount.map(PipTransactionCardData.account) ?? .empty("Откуда"),
            destination: PipTransactionCardData(
                title: recipient.title,
                subtitle: model.paymentDestinationSubtitle,
                icon: recipient.icon
            ),
            onTapSource: { model.isMethodSheetPresented = true },
            onTapDestination: onOpenSpec
        )
    }

    private var urgentTransfer: some View {
        HStack(spacing: WBSpace.x3) {
            VStack(alignment: .leading, spacing: WBSpace.x1) {
                Text("Перевести срочно")
                    .font(WBFont.body)
                    .foregroundStyle(WBColor.textPrimary)
                Text("Зачисление за пару минут")
                    .font(WBFont.description)
                    .foregroundStyle(WBColor.textSecondary)
            }
            Spacer(minLength: 0)
            Text("+199 ₽")
                .font(WBFont.description)
                .foregroundStyle(WBColor.textSecondary)
            Toggle("", isOn: $isUrgent)
                .labelsHidden()
                .tint(WBColor.textAccent)
        }
        .padding(.horizontal, WBSpace.x3)
    }

}
