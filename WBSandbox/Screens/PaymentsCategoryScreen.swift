import SwiftUI

/// Компактный ввод реквизита для категорий, у которых ещё нет сложной формы.
/// Подтверждение и сумма используют общий транзакционный экран песочницы.
struct PaymentsCategoryScreen: View {
    let category: PaymentHubCategory
    let onBack: () -> Void

    @State private var reference = ""
    @State private var proceedsToAmount = false

    private var title: String { category.title.replacingOccurrences(of: "\n", with: " ") }

    private var transaction: TransactionConfig {
        var config = TransferModes.utilities
        config.id = "category-\(category.rawValue)"
        config.demoName = title
        config.title = title
        config.initialAmount = 0
        config.message = nil
        config.destination = DetailRow(
            id: config.id,
            icon: .asset(category.asset),
            top: .primary(title),
            bottom: .secondary(reference.trimmingCharacters(in: .whitespacesAndNewlines))
        )
        config.success.counterparty = title
        config.success.icon = .asset(category.asset)
        config.success.chip = nil
        return config
    }

    private var isValid: Bool {
        let value = reference.trimmingCharacters(in: .whitespacesAndNewlines)
        switch category {
        case .mobile: return (10...11).contains(value.filter(\.isNumber).count)
        case .patent: return value.count == 12 && value.allSatisfy(\.isNumber)
        default: return value.count >= 3
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(category.referenceLabel, text: $reference)
                        .keyboardType(category == .mobile ? .phonePad : category == .patent ? .numberPad : .default)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text(category.referenceLabel)
                }

                Section {
                    Button("Продолжить") { proceedsToAmount = true }
                        .disabled(!isValid)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Назад", systemImage: "chevron.left", action: onBack)
                }
            }
            .fullScreenCover(isPresented: $proceedsToAmount) {
                TransactionHost(config: transaction, onBack: { proceedsToAmount = false })
            }
        }
    }
}
