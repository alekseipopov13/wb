import SwiftUI
import CoreText

/// Разводящая ПиП, Figma 60919:530144 (390 × 844).
/// Системные status bar и home indicator остаются нативными; контент скроллится.
struct FavouritesPaymentsScreen: View {
    let onBack: () -> Void
    private let feedVariant: FavouritesFeedVariant
    private let animationDemo: FavouritesTransitionDemo?

    @State private var store: PaymentsFavouritesStore
    @State private var showsSaved = false
    @State private var route: PaymentsHubRoute?
    @State private var sheet: FavouritesSheet?
    @State private var pendingFavourite: PaymentShortcut?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var deckPull = FavouritesDeckInteraction()
    @State private var feedIsInteracting = false
    @State private var lastRestedAtTrailingEdge = false
    @State private var explicitEdgeScroll = false
    @State private var latestFeedGeometry: FavouritesFeedScrollGeometry?
    @State private var feedScrollPosition = ScrollPosition(x: 0)
    @State private var sceneProgress: CGFloat = 0
    @State private var sceneSize: CGSize = .zero
    @State private var feedFrames: [String: CGRect] = [:]
    @State private var preparingPresentation = false
    @State private var wantsDeckFlight = false
    @State private var isTransitioning = false
    @State private var flights: [FavouritesCardFlight] = []
    @State private var preparedDemoScroll = false
    @State private var demoPullReplay = 0
    @State private var demoPullPlaying = false

    init(scenario: FavouritesDemoScenario = .full,
         feedVariant: FavouritesFeedVariant = .original,
         animationDemo: FavouritesTransitionDemo? = nil, onBack: @escaping () -> Void) {
        self.onBack = onBack
        self.feedVariant = feedVariant
        self.animationDemo = animationDemo
        _store = State(initialValue: PaymentsFavouritesStore(scenario: scenario))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                hubContent
                    .opacity(usesSlideTransition ? 1 : Double(1 - sceneProgress))
                    .offset(x: usesSlideTransition ? -sceneSize.width * 0.22 * sceneProgress : 0)
                    .allowsHitTesting(!showsSaved && !isTransitioning)
                    .accessibilityHidden(showsSaved)

                if showsSaved {
                    SavedFavouritesScreen(
                        store: store,
                        onBack: closeSaved,
                        onOpen: { route = $0 },
                        onAddFromHistory: { sheet = .history },
                        hiddenCardIDs: preparingPresentation && wantsDeckFlight
                            ? Set(store.saved.map(\.id)) : Set(flights.map(\.id)),
                        capturesTransitionFrames: true,
                        showsReminders: animationDemo == nil && !isTransitioning && !preparingPresentation,
                        showsEditingActions: animationDemo == nil,
                        isActive: !isTransitioning && !preparingPresentation && sheet == nil
                    )
                    .opacity(usesSlideTransition ? 1 : Double(sceneProgress))
                    .offset(x: usesSlideTransition ? sceneSize.width * (1 - sceneProgress) : 0)
                    .allowsHitTesting(!isTransitioning)
                    .accessibilityHidden(isTransitioning)
                    .onAppear {
                        if preparingPresentation && !wantsDeckFlight {
                            DispatchQueue.main.async { animatePresentation() }
                        }
                    }
                    .transition(.identity)
                }

                if !flights.isEmpty {
                    ZStack(alignment: .topLeading) {
                        ForEach(flights) { flight in
                            FavouritesDeckFlightCard(flight: flight, progress: sceneProgress)
                        }
                    }
                    .onAppear {
                        // Сначала монтируем карточки в исходной геометрии,
                        // затем запускаем перелёт отдельной транзакцией.
                        DispatchQueue.main.async { animatePresentation() }
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(WBColor.bgBase.ignoresSafeArea())
            .coordinateSpace(name: FavouritesDeckLayout.coordinateSpace)
            .clipped()
            .onAppear { sceneSize = geometry.size }
            .onChange(of: geometry.size) { _, size in sceneSize = size }
            .onPreferenceChange(FavouritesFeedFramesKey.self) { feedFrames = $0 }
            .onPreferenceChange(SavedFavouritesFramesKey.self) { frames in
                if preparingPresentation && wantsDeckFlight && !frames.isEmpty {
                    prepareFlight(to: frames)
                }
            }
        }
        .foregroundStyle(WBColor.textPrimary)
        .background(WBColor.bgBase.ignoresSafeArea())
        .sheet(item: $sheet, onDismiss: completeFavouriteAddition) { _ in
            FavouritesHistoryScreen(store: store, onClose: { sheet = nil }, onAdd: { pendingFavourite = $0 })
        }
        .fullScreenCover(item: $route) { destination in
            destinationScreen(destination)
        }
        .accessibilityAction(.escape) {
            if showsSaved { closeSaved() } else { onBack() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                feedIsInteracting = false
                explicitEdgeScroll = false
                deckPull.reset()
                demoPullPlaying = false
            }
        }
        .task(id: demoPullReplay) {
            guard animationDemo == .pull, demoPullReplay > 0 else { return }
            demoPullPlaying = true
            // The button supplies the same 72 pt input as the live gesture;
            // geometry, thresholds, flight and destination remain shared.
            withAnimation(.easeOut(duration: 0.36)) {
                _ = deckPull.update(distance: FavouritesDeckInteraction.triggerDistance,
                                    isInteracting: true, hasOverflow: hasExpandableDeck)
            }
            Haptics.key(intensity: 0.32)
            do { try await Task.sleep(for: .milliseconds(400)) } catch { return }
            let shouldOpen = demoPullPlaying && scenePhase == .active
            demoPullPlaying = false
            guard shouldOpen else { return }
            openSaved(fromDeck: true)
        }
    }

    private var pullProgress: CGFloat { reduceMotion ? 0 : deckPull.progress }
    private var hasHiddenFavourites: Bool { !store.hiddenFavourites.isEmpty }
    private var showsFolder: Bool { feedVariant == .allFavouritesFolder && !store.saved.isEmpty }
    private var hasExpandableDeck: Bool { showsFolder || hasHiddenFavourites }
    private var deckFrameID: String? { showsFolder ? FavouritesCollectionItem.allFavourites.id : store.feed.last?.id }
    private var feedItems: [FavouritesCollectionItem] {
        store.feed.map(FavouritesCollectionItem.shortcut) + (showsFolder ? [.allFavourites] : []) + [.history]
    }
    private var hiddenFlightIDs: Set<String> { Set(flights.map(\.id)) }
    private var usesSlideTransition: Bool { !reduceMotion && !wantsDeckFlight }

    private var hubContent: some View {
        VStack(spacing: 0) {
            navigationHeader
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    favouritesSection
                    if let animationDemo {
                        Text(animationDemo.instruction)
                            .font(PaymentsHubFont.regular(15))
                            .foregroundStyle(WBColor.textSecondary)
                            .padding(16)
                            .padding(.top, 24)
                        if animationDemo == .pull {
                            WBPrimaryButton(title: "Показать раскрытие", isEnabled: !demoPullPlaying && !isTransitioning) {
                                demoPullReplay += 1
                            }
                            .accessibilityIdentifier("favourites.animation.play")
                            .padding(16)
                        }
                    } else {
                        transfersSection
                        paymentsSection
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .background(WBColor.bgBase.ignoresSafeArea())
    }

    private var navigationHeader: some View {
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
                Spacer(minLength: 0)
            }
            .frame(height: 48)

            Text(animationDemo?.title ?? "Переводы и платежи")
                .font(WBFont.hauss(24, .bold))
                .frame(height: 29, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, WBSpace.x4)
                .padding(.top, WBSpace.x1)
                .padding(.bottom, WBSpace.x2)
                .accessibilityAddTraits(.isHeader)
        }
        .buttonStyle(.plain)
    }

    private var favouritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button { openSaved(fromDeck: false) } label: {
                HStack(alignment: .top) {
                    sectionTitle("Избранное")
                    Spacer(minLength: 8)
                    if !store.history.isEmpty || !store.saved.isEmpty {
                        Image("favChevronRight")
                            .renderingMode(.template)
                            .frame(width: 7.333333, height: 16)
                            .padding(.top, 3)
                    }
                }
                .frame(height: 25, alignment: .top)
                .contentShape(Rectangle())
            }
            .accessibilityIdentifier("favourites.all")
            .disabled(animationDemo == .pull)
            .padding(.horizontal, WBSpace.x4)

            ScrollView(.horizontal, showsIndicators: false) {
                FavouritesAnimatedCollection(
                    items: feedItems,
                    arrangement: .row, addition: store.lastAddition,
                    isActive: !showsSaved && !isTransitioning && sheet == nil
                ) { item, index in
                    switch item {
                    case .shortcut(let shortcut):
                        Group {
                            if animationDemo == nil {
                                Button { route = shortcut.route } label: { feedCard(shortcut) }
                            } else {
                                feedCard(shortcut)
                            }
                        }
                        // Сдвигаем от последнего места, не меняя contentSize:
                        // иначе раздвигание само меняло бы величину overscroll.
                        .offset(x: -CGFloat(store.feed.count + (showsFolder ? 1 : 0) - index) * 20 * pullProgress)
                        .zIndex(hasHiddenFavourites && shortcut.id == deckFrameID ? 1 : 0)
                        .accessibilityIdentifier("favourites.card.\(shortcut.id)")
                    case .allFavourites:
                        Group {
                            if animationDemo == nil {
                                Button { openSaved(fromDeck: true) } label: { allFavouritesFolder }
                            } else {
                                allFavouritesFolder
                            }
                        }
                            .offset(x: -20 * pullProgress)
                            .zIndex(1)
                            .accessibilityIdentifier("favourites.folder")
                            .accessibilityHint(animationDemo == nil ? "Открыть все избранные. Можно раскрыть протяжкой в конце ленты" : "")
                    case .history:
                        Group {
                            if animationDemo == nil {
                                Button { sheet = .history } label: { addFromHistoryCard }
                            } else {
                                addFromHistoryCard
                            }
                        }
                        .accessibilityIdentifier("favourites.addFromHistory")
                    }
                }
                .padding(.horizontal, WBSpace.x4)
            }
            .scrollPosition($feedScrollPosition)
            .scrollClipDisabled()
            .scrollBounceBehavior(.always, axes: .horizontal)
            .onScrollGeometryChange(for: FavouritesFeedScrollGeometry.self) { FavouritesFeedScrollGeometry($0) } action: { _, geometry in
                latestFeedGeometry = geometry
                if let animationDemo, !preparedDemoScroll, geometry.endOffset > 0 {
                    preparedDemoScroll = true
                    if animationDemo.startsAtEnd { feedScrollPosition.scrollTo(x: geometry.endOffset) }
                }
                // Programmatic positioning does not necessarily emit an idle
                // phase. Match the settled end state of a manually scrolled feed.
                if animationDemo?.startsAtEnd == true && geometry.isAtTrailingEdge && !feedIsInteracting {
                    lastRestedAtTrailingEdge = true
                }
                guard animationDemo == nil || animationDemo == .pull else { return }
                guard !showsSaved && !isTransitioning else { return }
                let distance = geometry.overscroll
                let feedback = deckPull.update(distance: distance, isInteracting: feedIsInteracting || explicitEdgeScroll, hasOverflow: hasExpandableDeck)
                switch feedback {
                case .spread: Haptics.key(intensity: 0.32)
                case .ready: Haptics.impact(.rigid, intensity: 0.55)
                case .disarmed: Haptics.key(intensity: 0.2)
                case .none: break
                }
                if explicitEdgeScroll && deckPull.shouldOpenOnRelease && scenePhase == .active {
                    explicitEdgeScroll = false
                    openSaved(fromDeck: true)
                }
            }
            .onScrollPhaseChange { oldPhase, newPhase, context in
                // Мышь, трекпад и accessibility-scroll могут давать сразу
                // decelerating. Считаем намерением только НОВЫЙ жест у края,
                // к которому предыдущая прокрутка уже успела остановиться.
                if oldPhase == .idle && newPhase == .decelerating {
                    explicitEdgeScroll = lastRestedAtTrailingEdge && hasExpandableDeck
                }
                if newPhase == .interacting {
                    feedIsInteracting = true
                    explicitEdgeScroll = false
                } else if oldPhase == .interacting {
                    feedIsInteracting = false
                    guard !showsSaved && !isTransitioning else { return }
                    if deckPull.shouldOpenOnRelease && scenePhase == .active {
                        openSaved(fromDeck: true)
                    } else {
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) { deckPull.reset() }
                    }
                }
                if newPhase == .idle {
                    lastRestedAtTrailingEdge = (latestFeedGeometry ?? FavouritesFeedScrollGeometry(context.geometry)).isAtTrailingEdge
                    explicitEdgeScroll = false
                    if !showsSaved && !isTransitioning { deckPull.reset() }
                }
            }

        }
        .padding(.top, WBSpace.x6)
        .buttonStyle(.plain)
    }

    private func feedCard(_ shortcut: PaymentShortcut) -> some View {
        let isDeck = hasHiddenFavourites && shortcut.id == deckFrameID
        return ZStack {
            if isDeck {
                hiddenDeckCards
            }
            PaymentShortcutCard(
                shortcut: shortcut,
                isLinkedAccount: store.openBanking && shortcut.id == "self-vtb",
                borderOpacity: isDeck ? 1 : 0
            )
            .frame(width: 122, height: feedCardHeight)
            .overlay(alignment: .topLeading) {
                if animationDemo == nil && !showsSaved && !isTransitioning && store.contains(shortcut),
                   let message = shortcut.upcomingPaymentMessage {
                    FavouritesUpcomingPaymentMessage(message: message, cardHeight: feedCardHeight,
                                                     isReadyToAppear: isFeedCardVisible(shortcut.id))
                        .accessibilityHidden(true)
                }
            }
            .opacity(hiddenFlightIDs.contains(shortcut.id) ? 0 : 1)
        }
        .frame(width: 122, height: feedCardHeight)
        .background {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: FavouritesFeedFramesKey.self,
                    value: [shortcut.id: proxy.frame(in: .named(FavouritesDeckLayout.coordinateSpace))]
                )
            }
        }
        .zIndex(isDeck ? 1 : 0)
        .accessibilityValue(store.contains(shortcut) ? (shortcut.upcomingPaymentMessage ?? "") : "")
        .accessibilityActions {
            if isDeck {
                Button("Раскрыть всё избранное") { openSaved(fromDeck: true) }
            }
        }
    }

    private var feedCardHeight: CGFloat {
        FavouritesDeckLayout.cardSize.height
    }

    private var allFavouritesFolder: some View {
        ZStack {
            hiddenDeckCards
            FavouritesFolderCard(favourites: store.saved)
        }
        .frame(width: 122, height: feedCardHeight)
        .background {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: FavouritesFeedFramesKey.self,
                    value: [FavouritesCollectionItem.allFavourites.id: proxy.frame(in: .named(FavouritesDeckLayout.coordinateSpace))]
                )
            }
        }
    }

    private var hiddenDeckCards: some View {
        ForEach(Array(store.hiddenFavourites.prefix(2).enumerated().reversed()), id: \.element.id) { index, hidden in
            let pose = FavouritesDeckLayout.hiddenPose(
                index: index,
                behind: CGRect(x: 0, y: 0, width: 122, height: feedCardHeight),
                pull: pullProgress
            )
            PaymentShortcutCard(shortcut: hidden, borderOpacity: 1)
                .frame(width: 122, height: feedCardHeight)
                .scaleEffect(pose.scale)
                .rotationEffect(.degrees(pose.rotation))
                .offset(x: pose.frame.minX, y: pose.frame.minY)
                .opacity(hiddenFlightIDs.contains(hidden.id) ? 0 : 1)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                .zIndex(-Double(index + 1))
        }
    }

    private func completeFavouriteAddition() {
        guard let pendingFavourite else { return }
        self.pendingFavourite = nil
        store.add(pendingFavourite)
    }

    private func isFeedCardVisible(_ id: String) -> Bool {
        guard let frame = feedFrames[id], sceneSize != .zero else { return false }
        let intersection = frame.intersection(CGRect(origin: .zero, size: sceneSize))
        return !intersection.isNull && intersection.width >= frame.width * 0.5
    }

    private func openSaved(fromDeck: Bool) {
        guard !showsSaved && !isTransitioning else { return }
        let viewport = CGRect(origin: .zero, size: sceneSize)
        let hasVisibleSavedCard = store.saved.contains { shortcut in
            feedFrames[shortcut.id].map { $0.intersects(viewport) } ?? false
        }
        // Заголовок и протяжка используют один перелёт. Если лента ещё в начале
        // и все сохранённые карточки за экраном, открываем сетку через Move In.
        wantsDeckFlight = !reduceMotion && !store.saved.isEmpty && (fromDeck || hasVisibleSavedCard)
        isTransitioning = true
        preparingPresentation = true
        showsSaved = true
        if fromDeck { Haptics.impact(.medium, intensity: 0.7) } else { Haptics.tap() }
    }

    private func captureSourcePoses() -> [String: FavouritesCardPose] {
        let anchor = deckFrameID.flatMap { feedFrames[$0] }
            ?? CGRect(x: sceneSize.width - 138, y: 150, width: 122, height: feedCardHeight)
        let hiddenOrder = Dictionary(uniqueKeysWithValues: store.hiddenFavourites.enumerated().map { ($1.id, $0) })
        return Dictionary(uniqueKeysWithValues: store.saved.map { shortcut in
            if let frame = feedFrames[shortcut.id] {
                return (shortcut.id, FavouritesCardPose(frame: frame, borderOpacity: shortcut.id == store.feed.last?.id && hasHiddenFavourites ? 1 : 0))
            }
            return (shortcut.id, FavouritesDeckLayout.hiddenPose(index: hiddenOrder[shortcut.id, default: 2], behind: anchor, pull: pullProgress))
        })
    }

    private func prepareFlight(to frames: [String: CGRect]) {
        guard preparingPresentation && flights.isEmpty else { return }
        let sources = captureSourcePoses()
        // Не поднимаем карточки из строк, которые находятся под нижней панелью.
        let visibleGrid = CGRect(x: 0, y: 0, width: sceneSize.width, height: max(0, sceneSize.height - 76))
        flights = store.saved.compactMap { shortcut in
            guard let destination = frames[shortcut.id], destination.intersects(visibleGrid),
                  let source = sources[shortcut.id] else { return nil }
            return FavouritesCardFlight(
                shortcut: shortcut, source: source, destination: destination,
                isLinkedAccount: store.openBanking && shortcut.id == "self-vtb",
                layer: source.scale == 1 ? 20 : 10 + Double(source.scale)
            )
        }
        if flights.isEmpty { animatePresentation() }
    }

    private func animatePresentation() {
        guard preparingPresentation else { return }
        preparingPresentation = false
        let animation: Animation = reduceMotion ? .easeOut(duration: 0.15)
            : wantsDeckFlight ? .spring(response: 0.56, dampingFraction: 0.86) : .spring(response: 0.42, dampingFraction: 1)
        withAnimation(animation, completionCriteria: .removed) {
            sceneProgress = 1
        } completion: {
            flights = []
            isTransitioning = false
            deckPull.reset()
            if wantsDeckFlight { Haptics.impact(.soft, intensity: 0.3) }
        }
    }

    private func closeSaved() {
        guard showsSaved && !isTransitioning else { return }
        isTransitioning = true
        Haptics.tap()
        withAnimation(.easeInOut(duration: reduceMotion ? 0.15 : 0.24), completionCriteria: .removed) {
            sceneProgress = 0
        } completion: {
            showsSaved = false
            isTransitioning = false
        }
    }

    private var addFromHistoryCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image("favPlus")
                .frame(width: 20, height: 20)
                .frame(width: 32, height: 32)
                .background(WBColor.bgLevel2, in: Circle())
            Spacer(minLength: 0)
            Text("Добавить\nиз истории")
                .font(WBFont.descriptionAccent)
                .lineSpacing(1.5)
                .frame(height: 34, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(WBSpace.x3)
        .frame(width: 122, height: feedCardHeight)
        .background(WBColor.bgBase, in: RoundedRectangle(cornerRadius: WBRadius.x5))
        .overlay {
            RoundedRectangle(cornerRadius: WBRadius.x5)
                .strokeBorder(WBColor.strokeSecondary, lineWidth: 1)
        }
    }

    private var transfersSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionTitle("Перевести")
                .frame(height: 25, alignment: .top)

            VStack(spacing: 0) {
                transferRow("По номеру телефона", subtitle: "В любой банк", icon: "favPhone", height: 62, route: .phone)
                transferRow("По реквизитам", subtitle: "Другим людям, компаниям\nили государству", icon: "favRequisites", height: 82, route: .requisites)
                transferRow("Между своими счетами", subtitle: "В любых банках", icon: "favBetweenAccounts", height: 62, route: .betweenAccounts)
                transferRow("В другую страну", subtitle: "По номеру телефона, карты, счёта\nили наличными", icon: "favWorld", height: 82, route: .crossBorder)
            }
        }
        .padding(.horizontal, WBSpace.x4)
        .padding(.top, WBSpace.x6)
    }

    private func transferRow(_ title: String, subtitle: String, icon: String, height: CGFloat, route destination: PaymentsHubRoute) -> some View {
        Button { route = destination } label: {
            HStack(spacing: WBSpace.x4) {
                RowIconView(icon: .tile(icon, CGSize(width: 24, height: 24), background: WBColor.bgLevel2))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(PaymentsHubFont.regular(17))
                        .frame(height: 24, alignment: .center)
                    Text(subtitle)
                        .font(PaymentsHubFont.regular(15))
                        .foregroundStyle(WBColor.textSecondary)
                        .lineSpacing(0.9)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(height: height - 42, alignment: .topLeading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: height)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("payments.transfer.\(destination.id)")
    }

    private var paymentsSection: some View {
        VStack(alignment: .leading, spacing: WBSpace.x4) {
            sectionTitle("Оплатить")
                .frame(height: 25, alignment: .top)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), alignment: .leading, spacing: 8) {
                ForEach(PaymentHubCategory.allCases) { category in
                    Button { route = category.route } label: {
                        paymentTile(category)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("payments.category.\(category.rawValue)")
                }
            }
        }
        .padding(.horizontal, WBSpace.x4)
        .padding(.top, WBSpace.x6)
    }

    private func paymentTile(_ category: PaymentHubCategory) -> some View {
        ZStack(alignment: .topLeading) {
            Text(category.title)
                .font(PaymentsHubFont.regular(15))
                .lineSpacing(0.9)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.top, 16)
            Image(category.asset)
                .frame(width: 64, height: 46)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .frame(height: 98)
        .frame(maxWidth: .infinity)
        .background(WBColor.bgLevel2, in: RoundedRectangle(cornerRadius: WBRadius.x5))
        .clipShape(RoundedRectangle(cornerRadius: WBRadius.x5))
        .contentShape(RoundedRectangle(cornerRadius: WBRadius.x5))
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(PaymentsHubFont.bold(19))
            .frame(height: 23, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private func destinationScreen(_ destination: PaymentsHubRoute) -> some View {
        switch destination {
        case .phone:
            PhoneTransferFlowScreen(baseConfig: TransferModes.byPhone, onBack: { route = nil })
        case .betweenAccounts:
            UniQRScreen(onBack: { route = nil }, configuration: .betweenAccountsTransition)
        case .requisites:
            ServiceFormHost(spec: ServiceCatalog.freeRequisites, onBack: { route = nil })
        case .crossBorder:
            TransactionHost(config: TransferModes.crossBorder, onBack: { route = nil })
        case .qr:
            UniQRScreen(onBack: { route = nil }, configuration: .freeAmount)
        case .utilities:
            ServiceFormHost(spec: ServiceCatalog.zhkuMoscow, onBack: { route = nil })
        case .internet:
            ServiceFormHost(spec: ServiceCatalog.internetOneStep, onBack: { route = nil })
        case .uin:
            ServiceFormHost(spec: ServiceCatalog.uin, onBack: { route = nil })
        case .shortcut(let favourite):
            if let details = favourite.utility {
                SavedUtilityPaymentScreen(shortcut: favourite, details: details, onBack: { route = nil })
            } else {
                TransactionHost(config: favourite.transaction, onBack: { route = nil })
            }
        case .walletTopUp:
            TransactionHost(config: TransferModes.topUp, onBack: { route = nil })
        case .category(let category):
            PaymentsCategoryScreen(category: category, onBack: { route = nil })
        }
    }
}

private struct FavouritesFeedScrollGeometry: Equatable {
    let distanceToEnd: CGFloat
    let endOffset: CGFloat
    var overscroll: CGFloat { max(0, distanceToEnd) }
    var isAtTrailingEdge: Bool { distanceToEnd >= -2 }

    init(_ geometry: ScrollGeometry) {
        let end = max(0, geometry.contentSize.width - geometry.containerSize.width + geometry.contentInsets.trailing)
        endOffset = end
        distanceToEnd = geometry.contentOffset.x - end
    }
}

private enum FavouritesSheet: String, Identifiable {
    case history
    var id: String { rawValue }
}

/// Google Sans из локальной библиотеки шрифтов, только для нового раздела.
enum PaymentsHubFont {
    private static let registration: Void = {
        for name in ["GoogleSans-Regular", "GoogleSans-Medium", "GoogleSans-Bold"] {
            if let url = Bundle.main.url(forResource: name, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }()

    static func regular(_ size: CGFloat) -> Font {
        _ = registration
        return .custom("GoogleSans-Regular", size: size)
    }

    static func medium(_ size: CGFloat) -> Font {
        _ = registration
        return .custom("GoogleSans-Medium", size: size)
    }

    static func bold(_ size: CGFloat) -> Font {
        _ = registration
        return .custom("GoogleSans-Bold", size: size)
    }
}
