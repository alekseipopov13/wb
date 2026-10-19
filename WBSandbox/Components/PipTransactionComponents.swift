import SwiftUI

/// Данные одной карточки маршрута. Оформление общее для всех сценариев ПиП.
struct PipTransactionCardData {
    var title: String
    var subtitle: String
    var icon: RowIcon
    var background: Color = WBColor.bgMinus1
    var isPlaceholder = false
    var paymentMark: RowIcon?

    static func account(_ account: Account) -> Self {
        Self(
            title: account.amountTitle,
            subtitle: account.subtitle,
            icon: account.icon,
            background: account.id.hasPrefix("wb-") || account.id.hasPrefix("wallet-")
                ? WBColor.bgAccentSecondaryLight : WBColor.bgMinus1
        )
    }

    static func empty(_ title: String) -> Self {
        Self(
            title: title,
            subtitle: "Счёт или банк",
            icon: .logo("dsPlusBold15", size: CGSize(width: 0.625, height: 0.625),
                        background: WBColor.controlsSecondary, radius: 0.3, offset: .zero, foreground: .white),
            background: WBColor.bgLevel2,
            isPlaceholder: true
        )
    }
}

/// Эталон из «Между счетами»: 96 pt, иконка 24, две строки 13/17, радиус 16.
struct PipTransactionCard: View {
    let data: PipTransactionCardData
    var attentionProgress: CGFloat = 0

    private var iconPop: CGFloat {
        guard data.isPlaceholder else { return 0 }
        let progress = min(1, max(0, attentionProgress))
        return max(0, sin(progress * .pi * 1.65)) * max(0, 1 - progress * 0.36)
    }

    var body: some View {
        WBPaymentInfoCard(background: data.background) {
            HStack(spacing: WBSpace.x2) {
                RowIconView(icon: data.icon, size: 24)
                    .scaleEffect(1 + iconPop * 0.055)
                Spacer(minLength: 0)
                if let mark = data.paymentMark { RowIconView(icon: mark, size: 16) }
            }
        } title: {
            Text(data.title)
                .font(WBFont.descriptionAccent)
                .foregroundStyle(WBColor.textPrimary)
                .lineLimit(1)
        } subtitle: {
            Text(data.subtitle)
                .font(WBFont.description)
                .foregroundStyle(WBColor.textPrimary)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Две одинаковые карточки и стрелка на зазоре 12 pt. Действия независимы:
/// счёт открывает выбор, получатель может быть статичным или редактируемым.
struct PipTransactionRouteCards: View {
    let source: PipTransactionCardData
    let destination: PipTransactionCardData
    var sourceAttentionProgress: CGFloat = 0
    var destinationAttentionProgress: CGFloat = 0
    var onTapSource: (() -> Void)?
    var onTapDestination: (() -> Void)?

    var body: some View {
        ZStack {
            HStack(spacing: WBSpace.x3) {
                card(source, role: "Откуда", progress: sourceAttentionProgress, action: onTapSource)
                card(destination, role: "Куда", progress: destinationAttentionProgress, action: onTapDestination)
            }

            Circle()
                .fill(WBColor.bgBase)
                .frame(width: 24, height: 24)
                .overlay {
                    Image("dsArrowRight16")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(WBColor.textPrimary)
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .frame(height: 96)
    }

    @ViewBuilder
    private func card(
        _ data: PipTransactionCardData,
        role: String,
        progress: CGFloat,
        action: (() -> Void)?
    ) -> some View {
        if let action {
            Button(action: action) {
                PipTransactionCard(data: data, attentionProgress: progress)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(role): \(data.title), \(data.subtitle)")
            .accessibilityIdentifier("transaction-\(role == "Откуда" ? "source" : "destination")")
            .frame(maxWidth: .infinity)
            .modifier(PipTransactionAttentionEffect(progress: progress))
        } else {
            PipTransactionCard(data: data, attentionProgress: progress)
                .frame(maxWidth: .infinity)
        }
    }
}

/// Единая компоновка транзакционного шага: шапка, сумма по центру,
/// маршрут и основная кнопка внизу. Safe area управляет и клавиатурой.
struct PipTransactionLayout<Amount: View, Details: View>: View {
    let title: String
    var buttonTitle = "Продолжить"
    var buttonSubtitle = ""
    var buttonFill = WBColor.ctaFill
    var onBack: () -> Void
    var onPay: () -> Void
    @ViewBuilder var amount: Amount
    @ViewBuilder var details: Details

    var body: some View {
        VStack(spacing: 0) {
            WBNavBar(title: title, onLeading: onBack)

            amount
                .padding(.horizontal, WBSpace.x4)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            details
                .padding(.horizontal, WBSpace.x4)
                .padding(.bottom, WBSpace.x2)

            Button {
                Haptics.tap()
                onPay()
            } label: {
                VStack(spacing: 0) {
                    Text(buttonTitle)
                        .font(WBFont.hauss(17, .medium))
                        .frame(height: 20)
                    if !buttonSubtitle.isEmpty {
                        Text(buttonSubtitle)
                            .font(WBFont.description)
                            .foregroundStyle(Color(hex: 0xF6F6F9).opacity(0.64))
                            .frame(height: 17)
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(buttonFill, in: RoundedRectangle(cornerRadius: WBRadius.x5, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("transaction-continue")
            .padding(.horizontal, WBSpace.x2)
            .padding(.top, WBSpace.x2)
            .padding(.bottom, WBSpace.x3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WBColor.bgBase, ignoresSafeAreaEdges: .all)
    }
}

/// Ввод и просмотр используют одну типографику; готовое начисление не вызывает
/// клавиатуру. AmountInput сохраняет запятую и копейки во время набора.
struct PipTransactionAmount: View {
    @Binding var input: AmountInput
    var isEditable: Bool
    var focusesOnAppear = true
    var focus: FocusState<Bool>.Binding?
    private var amountFocus: FocusState<Bool>.Binding { focus ?? $isFocused }
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: WBSpace.x1_5) {
            if isEditable {
                // TextField.fixedSize() измеряет плейсхолдер «0» и на новых iOS
                // сжимает введённые цифры. Ширину задаёт текст той же суммы.
                Text(input.displayInteger + (input.displayFraction ?? ""))
                    .hidden()
                    .padding(.trailing, 3)
                    .overlay {
                        TextField("0", text: Binding(
                            get: { input.displayInteger + (input.displayFraction ?? "") },
                            set: { input = AmountInput(raw: $0) }
                        ))
                        .font(WBFont.balance)
                        .textFieldStyle(.plain)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .tint(WBColor.textAccent)
                        .focused(amountFocus)
                        .accessibilityLabel("Сумма")
                        .accessibilityIdentifier("transaction-amount")
                    }
            } else {
                Text(Money.plain(input.decimal))
                    .contentTransition(.numericText())
                    .accessibilityLabel("Сумма \(Money.rub(input.decimal))")
            }

            Text("₽")
                .foregroundStyle(WBColor.textSecondary)
        }
        .font(WBFont.balance)
        .foregroundStyle(WBColor.textPrimary)
        .lineLimit(1)
        .frame(height: 44)
        .contentShape(Rectangle())
        .onTapGesture { if isEditable { amountFocus.wrappedValue = true } }
        .onAppear { if isEditable && focusesOnAppear { amountFocus.wrappedValue = true } }
    }
}

/// Мягкое внимание к освободившейся карточке при выборе одного счёта в обе роли.
struct PipTransactionAttentionEffect: GeometryEffect {
    var progress: CGFloat
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let p = min(1, max(0, progress))
        let spring = -13 * exp(-1.45 * p) * sin(3 * .pi * p)
        let settle = p < 0.82 ? 1 : max(0, 1 - pow((p - 0.82) / 0.18, 2))
        return ProjectionTransform(CGAffineTransform(translationX: spring * settle, y: 0))
    }
}
