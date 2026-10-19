import SwiftUI

/// Figma 60982:634117 — только явно сохранённые операции.
struct SavedFavouritesScreen: View {
    let store: PaymentsFavouritesStore
    let onBack: () -> Void
    let onOpen: (PaymentsHubRoute) -> Void
    let onAddFromHistory: () -> Void
    var hiddenCardIDs: Set<String> = []
    var capturesTransitionFrames = false
    var showsReminders = true
    var showsEditingActions = true
    var isActive = true

    @State private var isEditing = false
    @State private var editingShortcut: PaymentShortcut?
    @State private var removal: FavouritesRemoval<PaymentShortcut>?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            header
            ZStack {
                ScrollView(showsIndicators: false) {
                    FavouritesAnimatedCollection(
                        items: store.saved.map(FavouritesCollectionItem.shortcut),
                        arrangement: .grid, addition: store.lastAddition,
                        isActive: isActive
                    ) { item, _ in
                        if case .shortcut(let shortcut) = item {
                            ZStack(alignment: .topTrailing) {
                                Group {
                                    if showsEditingActions {
                                        Button {
                                            Haptics.tap()
                                            if isEditing { editingShortcut = shortcut }
                                            else { onOpen(shortcut.route) }
                                        } label: { savedCard(shortcut) }
                                    } else {
                                        savedCard(shortcut)
                                    }
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("saved.card.\(shortcut.id)")
                                .accessibilityValue(isEditing ? "" : (shortcut.upcomingPaymentMessage ?? ""))
                                .accessibilityHint(showsEditingActions ? (isEditing ? "Изменить избранное" : "Перейти к оплате") : "")

                                if isEditing {
                                    Button { remove(shortcut) } label: {
                                        Image("favRemove").renderingMode(.template)
                                            .frame(width: 16, height: 16)
                                            .foregroundStyle(.white)
                                            .frame(width: 24, height: 24)
                                            .background(WBColor.controlsSecondary, in: Circle())
                                            .overlay(Circle().strokeBorder(WBColor.bgBase, lineWidth: 2))
                                            .frame(width: 44, height: 44)
                                            .contentShape(Circle())
                                    }
                                    .buttonStyle(.plain)
                                    .offset(x: 14, y: -14)
                                    .accessibilityLabel("Удалить \(shortcut.title) из избранного")
                                    .accessibilityIdentifier("saved.remove.\(shortcut.id)")
                                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                                    .zIndex(1)
                                }
                            }
                            .modifier(FavouritesCardWiggle(enabled: isEditing && editingShortcut == nil, seed: shortcut.id))
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        }
                    }
                    .padding(WBSpace.x4)
                }
                .scrollClipDisabled()
                .accessibilityHidden(store.saved.isEmpty)

                if store.saved.isEmpty { emptyState }
            }
        }
        .foregroundStyle(WBColor.textPrimary)
        .background(WBColor.bgBase.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                if let removal {
                    FavouritesSnackbar(expiresAt: removal.expiresAt, onUndo: undoRemoval)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 12)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else if isEditing {
                    FavouritesSnackbar()
                        .padding(.horizontal, 8)
                        .padding(.bottom, 12)
                        .transition(.opacity)
                }

                if !isEditing && showsEditingActions {
                    WBPrimaryButton(title: "Добавить из истории", titleSize: 17, titleFont: PaymentsHubFont.medium(17), action: onAddFromHistory)
                        .accessibilityIdentifier("saved.addFromHistory")
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                }
            }
            .background(WBColor.bgBase)
        }
        .fullScreenCover(item: $editingShortcut) { shortcut in
            SavedFavouriteEditor(shortcut: shortcut, mode: .edit(onRemove: {
                editingShortcut = nil
                remove(shortcut)
            })) { updated in
                store.update(updated)
                editingShortcut = nil
            }
        }
        .task(id: removal?.id) {
            guard let current = removal else { return }
            do {
                try await Task.sleep(for: .seconds(max(0, current.expiresAt.timeIntervalSinceNow)))
            } catch { return }
            guard removal?.id == current.id else { return }
            withAnimation(.easeOut(duration: 0.2)) { removal = nil }
        }
        .accessibilityAction(.escape) {
            if isEditing { setEditing(false) } else { onBack() }
        }
    }

    /// Figma 60530:420059: центр свободной области между navbar и sticky bar.
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image("favArchive").renderingMode(.template)
                .frame(width: 24, height: 24)
                .frame(width: 56, height: 56)
                .background(WBColor.bgLevel2, in: RoundedRectangle(cornerRadius: 16))
                .accessibilityHidden(true)
            Text("Здесь будут ваши избранные")
                .font(WBFont.hauss(15, .regular))
                .foregroundStyle(WBColor.textSecondary)
                .multilineTextAlignment(.center)
                .frame(minHeight: 20)
                .accessibilityIdentifier("saved.empty")
        }
        .padding(.horizontal, 24).padding(.vertical, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Button(action: onBack) {
                    Image("dsChevronLeft24")
                        .renderingMode(.template)
                        .frame(width: 24, height: 24)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Назад")
                .accessibilityIdentifier("saved.back")
                Spacer(minLength: 0)
                if showsEditingActions && (!store.saved.isEmpty || isEditing) {
                    Button { setEditing(!isEditing) } label: {
                        Group {
                            if isEditing { DSIconView(icon: .checkmark) }
                            else { Image("favPencil").renderingMode(.template) }
                        }
                            .frame(width: 24, height: 24)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel(isEditing ? "Готово" : "Редактировать избранное")
                    .accessibilityIdentifier("saved.edit")
                }
            }
            .frame(height: 48)
            .padding(.horizontal, 4)

            Text("Избранное")
                .font(PaymentsHubFont.bold(24))
                .frame(height: 29, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 8)
                .accessibilityAddTraits(.isHeader)
        }
        .buttonStyle(.plain)
    }

    private func savedCard(_ shortcut: PaymentShortcut) -> some View {
        PaymentShortcutCard(shortcut: shortcut, savedProgress: 1)
            .frame(height: 108)
            .background {
                if capturesTransitionFrames {
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: SavedFavouritesFramesKey.self,
                            value: [shortcut.id: proxy.frame(in: .named(FavouritesDeckLayout.coordinateSpace))]
                        )
                    }
                }
            }
            .overlay(alignment: .topLeading) {
                if showsReminders && !isEditing, let message = shortcut.upcomingPaymentMessage {
                    FavouritesUpcomingPaymentMessage(message: message, cardHeight: 108)
                        .accessibilityHidden(true)
                }
            }
            .opacity(hiddenCardIDs.contains(shortcut.id) ? 0 : 1)
    }

    private func setEditing(_ value: Bool) {
        Haptics.impact(.soft, intensity: 0.4)
        withAnimation(SandboxMotion.favouritesEditing(reduceMotion: reduceMotion)) { isEditing = value }
    }

    private func remove(_ shortcut: PaymentShortcut) {
        Haptics.impact(.soft, intensity: 0.55)
        withAnimation(SandboxMotion.favouritesRemoval(reduceMotion: reduceMotion)) {
            removal = store.remove(shortcut)
            // Состояние после удаления из макета: обычная сетка и кнопка истории.
            isEditing = false
        }
        UIAccessibility.post(notification: .announcement, argument: "Убрали из избранного. Можно отменить в течение пяти секунд")
    }

    private func undoRemoval() {
        guard let removal else { return }
        withAnimation(SandboxMotion.favouritesRemoval(reduceMotion: reduceMotion)) {
            if store.restore(removal) { Haptics.impact(.soft, intensity: 0.4) }
            self.removal = nil
        }
    }
}

struct PaymentShortcutAvatar: View {
    let shortcut: PaymentShortcut

    var body: some View {
        Image(shortcut.asset)
            .frame(width: 32, height: 32)
            .clipShape(Circle())
            .accessibilityHidden(true)
    }
}

struct PaymentShortcutListRow: View {
    let shortcut: PaymentShortcut

    var body: some View {
        HStack(spacing: 12) {
            PaymentShortcutAvatar(shortcut: shortcut)
            VStack(alignment: .leading, spacing: 2) {
                Text(shortcut.title).foregroundStyle(WBColor.textPrimary)
                Text(shortcut.accountDetail)
                    .font(WBFont.description)
                    .foregroundStyle(WBColor.textSecondary)
            }
            Spacer(minLength: 0)
        }
    }
}

struct FavouritesHistoryScreen: View {
    let store: PaymentsFavouritesStore
    let onClose: () -> Void
    let onAdd: (PaymentShortcut) -> Void
    @State private var creatingShortcut: PaymentShortcut?
    @State private var pendingFavourite: PaymentShortcut?

    var body: some View {
        NavigationStack {
            List {
                if store.historyItems.isEmpty {
                    ContentUnavailableView {
                        Label("Пока нет операций", systemImage: "clock")
                    } description: {
                        Text("После первого перевода или платежа его можно будет добавить в избранное")
                    }
                } else {
                    ForEach(store.historyItems) { shortcut in
                        Button {
                            creatingShortcut = shortcut
                        } label: {
                            HStack {
                                PaymentShortcutListRow(shortcut: shortcut)
                                if store.contains(shortcut) {
                                    DSIconView(icon: .checkmark)
                                }
                            }
                        }
                        .disabled(store.contains(shortcut))
                        .accessibilityIdentifier("history.add.\(shortcut.id)")
                    }
                }
            }
            .navigationTitle("Добавить из истории")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть", systemImage: "xmark", action: onClose)
                }
            }
            .fullScreenCover(item: $creatingShortcut, onDismiss: {
                guard let pendingFavourite else { return }
                self.pendingFavourite = nil
                onAdd(pendingFavourite)
                onClose()
            }) { shortcut in
                SavedFavouriteEditor(shortcut: shortcut, mode: .create) { updated in
                    pendingFavourite = updated
                    creatingShortcut = nil
                }
            }
        }
    }
}
