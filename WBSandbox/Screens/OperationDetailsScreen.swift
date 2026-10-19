import SwiftUI

/// Figma 60571:136539 — детали операции МТС в обработке.
/// Добавление в избранное — Pop из примера с сердцем в Pow, в цвете text/icon Primary.
struct OperationDetailsScreen: View {
    let onBack: () -> Void

    @State private var route: Route?
    @State private var favourite: PaymentShortcut?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum Route: String, Identifiable {
        case repeatPayment, favourite
        var id: String { rawValue }
    }

    private var shortcut: PaymentShortcut {
        var value = PaymentShortcut.catalogue.first { $0.id == "mts" }!
        value.amount = Decimal(string: "868.95")!
        value.operationAmount = value.amount
        return value
    }

    private static let details: [(label: String, value: String)] = [
        ("Статус", "В обработке"),
        ("Комиссия", "10 ₽"),
        ("Счёт списания", "··1321"),
        ("Поставщик", "МТС и МГТС"),
        ("Лицевой счёт", "111122223333"),
        ("Категория операции", "Оплата интернета, телефона, ТВ"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            navigationHeader
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        summary
                        actions
                    }
                    .padding(.top, 8)
                    detailsPanel
                }
            }
            .accessibilityIdentifier("operation.details.scroll")
            // Нижние 50 pt панели уже включают место под home indicator.
            .ignoresSafeArea(.container, edges: .bottom)
        }
        .foregroundStyle(WBColor.textPrimary)
        .background {
            GeometryReader { proxy in
                Color(hex: 0xDAD7FF)
                Image("opDetailsBackground")
                    .resizable()
                    .frame(width: proxy.size.width, height: proxy.size.width * 461 / 390)
                    .accessibilityHidden(true)
            }
            .ignoresSafeArea()
        }
        .buttonStyle(.plain)
        .fullScreenCover(item: $route) { destination in
            switch destination {
            case .repeatPayment:
                TransactionHost(config: shortcut.transaction, onBack: { route = nil })
            case .favourite:
                SavedFavouriteEditor(shortcut: favourite ?? shortcut, mode: favourite == nil ? .create : .edit(onRemove: {
                    favourite = nil
                    route = nil
                })) { updated in
                    favourite = updated
                    route = nil
                }
            }
        }
        .accessibilityAction(.escape, onBack)
    }

    private var navigationHeader: some View {
        HStack(spacing: 0) {
            Button(action: onBack) {
                Image("dsChevronLeft24")
                    .renderingMode(.template)
                    .frame(width: 24, height: 24)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Назад")
            .accessibilityIdentifier("operation.details.back")

            Text("В обработке")
                .font(PaymentsHubFont.medium(17))
                .frame(maxWidth: .infinity)
                .frame(height: 20)
                .accessibilityAddTraits(.isHeader)

            Color.clear.frame(width: 44, height: 44).accessibilityHidden(true)
        }
        .padding(.horizontal, 4)
        .frame(height: 48)
    }

    private var summary: some View {
        VStack(spacing: 12) {
            Image("opDetailsMTS")
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(WBColor.textSecondary.opacity(0.045), lineWidth: 1)
                }
                .overlay(alignment: .bottomTrailing) {
                    Image("opDetailsClock")
                        .frame(width: 20, height: 20)
                        .padding(2)
                        .background(WBColor.controlsSecondary, in: Circle())
                        .overlay { Circle().stroke(WBColor.bgBase, lineWidth: 2) }
                        .offset(x: 2)
                }
                .accessibilityHidden(true)

            VStack(spacing: 0) {
                Text("МТС и МГТС")
                    .font(WBFont.bodyAccent)
                    .frame(height: 20)
                Text("6 июня в 10:11")
                    .font(WBFont.body)
                    .foregroundStyle(WBColor.textSecondary)
                    .frame(height: 20)
            }
            Text("–868,95 ₽")
                .font(WBFont.balance)
                .lineLimit(1)
                .frame(height: 44)
                .accessibilityIdentifier("operation.details.amount")
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
        .padding(.vertical, 16)
    }

    private var actions: some View {
        HStack(spacing: 8) {
            Button { route = .repeatPayment } label: {
                actionLabel("Повторить", asset: "opDetailsRepeat")
            }
            .accessibilityIdentifier("operation.details.repeat")

            ShareLink(item: receiptText) {
                actionLabel("Справка", asset: "opDetailsReceipt")
            }
            .accessibilityIdentifier("operation.details.receipt")

            Button {
                if favourite == nil {
                    // Commit the action immediately; the visual effect only
                    // reflects the saved state and does not delay the action.
                    favourite = shortcut
                } else {
                    route = .favourite
                }
            } label: {
                actionLabel(favourite == nil ? "В избранное" : "В избранном") {
                    OperationFavouriteIcon(isFavourite: favourite != nil)
                }
            }
            .accessibilityIdentifier("operation.details.favourite")
            .accessibilityValue(favourite == nil ? "Не добавлено" : "Добавлено")
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func actionLabel(_ title: String, asset: String) -> some View {
        actionLabel(title) {
            Image(asset)
                .renderingMode(.template)
                .frame(width: 24, height: 24)
        }
    }

    private func actionLabel<Icon: View>(_ title: String, @ViewBuilder icon: () -> Icon) -> some View {
        VStack(spacing: 8) {
            icon()
                .padding(16)
                .background(WBColor.bgBase, in: RoundedRectangle(cornerRadius: 16))
            Text(title)
                .font(WBFont.descriptionAccent)
                .contentTransition(.opacity)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: title)
                .lineLimit(1)
                .frame(height: 17)
        }
        .frame(width: 108)
        .contentShape(Rectangle())
    }

    private var detailsPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Детали операции")
                .font(WBFont.title3Bold)
                .frame(height: 20, alignment: .leading)
                .padding(.top, 1)
                .frame(height: 24, alignment: .topLeading)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 4)
                .accessibilityAddTraits(.isHeader)

            List {
                ForEach(Self.details, id: \.label) { row in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.label)
                            .font(WBFont.description)
                            .foregroundStyle(WBColor.textSecondary)
                            .frame(height: 17)
                        Text(row.value)
                            .font(WBFont.title3)
                            .frame(height: 20)
                            .padding(.vertical, 2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(WBColor.bgBase)
                    .accessibilityElement(children: .combine)
                }
            }
            .listStyle(.plain)
            .listRowSpacing(0)
            .environment(\.defaultMinListRowHeight, 0)
            .contentMargins(.all, 0, for: .scrollContent)
            .scrollContentBackground(.hidden)
            .scrollDisabled(true)
            .frame(height: CGFloat(Self.details.count) * 59)

            Color.clear.frame(height: 50).accessibilityHidden(true)
        }
        .padding(.top, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(WBColor.bgBase, in: UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24))
    }

    private var receiptText: String {
        (["МТС и МГТС", "6 июня в 10:11", "Сумма: –868,95 ₽"]
         + Self.details.map { "\($0.label): \($0.value)" }).joined(separator: "\n")
    }
}
