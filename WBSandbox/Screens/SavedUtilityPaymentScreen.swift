import SwiftUI

/// Из сохранённого ЖКУ сразу запрашиваем только меняющиеся за месяц данные.
/// После их ввода сумма и подтверждение открываются на общем TransactionHost.
struct SavedUtilityPaymentScreen: View {
    let shortcut: PaymentShortcut
    let details: SavedUtilityDetails
    let onBack: () -> Void
    @State private var reading = ""
    @State private var period = Date()
    @State private var touched = false
    @State private var proceedsToAmount = false
    @FocusState private var readingFocused: Bool

    private var error: String? { details.readingError(reading) }
    private var transaction: TransactionConfig {
        var config = shortcut.transaction
        let consumption = max(0, (Int(reading) ?? details.previousReading) - details.previousReading)
        config.destination?.bottom = .secondary("лс \(details.account) · \(SavedUtilityDetails.period(for: period))\nПоказания: \(reading) кВт⋅ч · расход \(consumption) кВт⋅ч")
        return config
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) {
                    Image("dsChevronLeft24").renderingMode(.template)
                        .frame(width: 24, height: 24).frame(width: 44, height: 44)
                }
                .accessibilityLabel("Назад")
                .accessibilityIdentifier("saved.utility.back")
                Spacer()
            }
            .padding(.horizontal, 4)
            .frame(height: 48)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(shortcut.title).font(PaymentsHubFont.bold(24))
                    PaymentShortcutListRow(shortcut: shortcut)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Лицевой счёт").font(PaymentsHubFont.regular(13)).foregroundStyle(WBColor.textSecondary)
                        Text(details.account).font(PaymentsHubFont.regular(17))
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Данные за месяц").font(PaymentsHubFont.medium(19))
                        DatePicker("Период оплаты", selection: $period, displayedComponents: .date)
                            .environment(\.locale, Locale(identifier: "ru_RU"))
                            .font(PaymentsHubFont.regular(15))
                            .accessibilityIdentifier("saved.utility.period")
                        VStack(alignment: .leading, spacing: 6) {
                            FormFieldBox(hasError: touched && error != nil) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Текущие показания, кВт⋅ч")
                                        .font(PaymentsHubFont.regular(13)).foregroundStyle(WBColor.textSecondary)
                                    TextField("Введите показания", text: $reading)
                                        .font(PaymentsHubFont.regular(17))
                                        .keyboardType(.numberPad)
                                        .focused($readingFocused)
                                        .onChange(of: reading) { _, value in reading = String(value.filter(\.isNumber).prefix(6)) }
                                        .accessibilityIdentifier("saved.utility.reading")
                                }
                                .padding(.vertical, 10)
                            }
                            Text(touched && error != nil ? error! : "Предыдущие показания: \(details.previousReading) кВт⋅ч")
                                .font(PaymentsHubFont.regular(13))
                                .foregroundStyle(touched && error != nil ? WBColor.declined : WBColor.textSecondary)
                        }
                    }
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .foregroundStyle(WBColor.textPrimary)
        .background(WBColor.bgBase.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            WBPrimaryButton(title: "Продолжить", titleFont: PaymentsHubFont.medium(17)) {
                touched = true
                guard error == nil else { readingFocused = true; return }
                readingFocused = false
                proceedsToAmount = true
            }
            .accessibilityIdentifier("saved.utility.continue")
            .padding(16)
            .background(WBColor.bgBase)
        }
        .fullScreenCover(isPresented: $proceedsToAmount) {
            TransactionHost(config: transaction, onBack: { proceedsToAmount = false })
        }
    }
}
