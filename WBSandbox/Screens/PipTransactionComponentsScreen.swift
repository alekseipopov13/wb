import SwiftUI

/// Живые экземпляры общих компонентов, а не отдельная копия их оформления.
struct PipTransactionComponentsScreen: View {
    var onClose: () -> Void
    @State private var sourceID = "wb-1321"
    @State private var showsPicker = false
    @State private var isDestinationEmpty = false

    private var accounts: [Account] { TransferModes.sharedAccounts }
    private var source: PipTransactionCardData {
        accounts.first { $0.id == sourceID }.map(PipTransactionCardData.account) ?? .empty("Откуда")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: WBSpace.x6) {
                    VStack(alignment: .leading, spacing: WBSpace.x3) {
                        Text("Маршрут платежа").font(WBFont.title3Bold)
                        PipTransactionRouteCards(
                            source: source,
                            destination: isDestinationEmpty ? .empty("Куда") : PipTransactionCardData(
                                title: "Ростелеком",
                                subtitle: "Лицевой счёт ··1234",
                                icon: .asset("favRostelecom")
                            ),
                            onTapSource: { showsPicker = true }
                        )
                        Toggle("Пустой получатель", isOn: $isDestinationEmpty)
                            .tint(WBColor.textAccent)
                    }
                    VStack(alignment: .leading, spacing: WBSpace.x3) {
                        Text("Между счетами").font(WBFont.title3Bold)
                        PipTransactionRouteCards(
                            source: .account(accounts[1]),
                            destination: .account(accounts[0])
                        )
                    }
                    VStack(alignment: .leading, spacing: WBSpace.x3) {
                        Text("Пустые состояния").font(WBFont.title3Bold)
                        PipTransactionRouteCards(source: .empty("Откуда"), destination: .empty("Куда"))
                    }
                    Text("PipTransactionCard · PipTransactionRouteCards\n96 pt · иконка 24 pt · отступ 12 pt · радиус 16 pt\nОбщие для телефона, QR, реквизитов и оплаты услуг.")
                        .font(WBFont.description)
                        .foregroundStyle(WBColor.textSecondary)
                }
                .padding(WBSpace.x4)
            }
            .background(WBColor.bgBase, ignoresSafeAreaEdges: .all)
            .navigationTitle("Карточки транзакции")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Закрыть", action: onClose) }
            }
            .sheet(isPresented: $showsPicker) {
                AccountPickerSheet(accounts: accounts, selectedID: sourceID) { id in
                    sourceID = id
                    showsPicker = false
                }
            }
        }
    }
}
