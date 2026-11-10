import SwiftUI

// iOS 17+. Example names are arbitrary; use your application's naming and tokens.
// Keep this state with the screen's owner, above navigation destinations.
@available(iOS 17.0, macOS 14.0, *)
@MainActor
final class InitialLoadMotion: ObservableObject {
    @Published private(set) var cashbackHeight: CGFloat = 116
    @Published private(set) var referralProgress: Double = 0
    @Published private(set) var referralAngle: Double = 0
    @Published private(set) var skeletonOpacity: Double = 1
    @Published private(set) var showsSkeleton = true
    @Published private(set) var allowsReferral = false
    @Published private(set) var isWaiting = true
    @Published private(set) var isFinished = false

    private var started = false
    private var generation = UUID()
    private var delayTask: Task<Void, Never>?
    private var onFinished: () -> Void = {}

    private func curve(_ seconds: Double) -> Animation {
        .timingCurve(0.22, 1, 0.36, 1, duration: seconds)
    }

    // Call only when the application has content ready. No loading timeout.
    func contentBecameReady(reduceMotion: Bool, onFinished: @escaping () -> Void = {}) {
        guard !started else { return }
        started = true
        isWaiting = false
        self.onFinished = onFinished
        if reduceMotion { finishImmediately(); return }
        let token = generation

        withAnimation(.easeOut(duration: 0.22), completionCriteria: .removed) {
            skeletonOpacity = 0
        } completion: { [weak self] in
            guard let self, self.generation == token else { return }
            self.showsSkeleton = false
        }
        // T+300 ms includes the 220 ms fade, rather than following it.
        delayTask = Task { @MainActor [weak self] in
            do { try await Task.sleep(for: .milliseconds(300)) }
            catch { return }
            guard let self, self.generation == token else { return }
            self.shrink(token)
        }
    }

    private func shrink(_ token: UUID) {
        withAnimation(curve(0.4), completionCriteria: .removed) {
            cashbackHeight = 68
        } completion: { [weak self] in
            guard let self, self.generation == token else { return }
            self.reveal(token)
        }
    }

    private func reveal(_ token: UUID) {
        allowsReferral = true
        // One progress drives opacity and scale, so they finish together.
        withAnimation(curve(0.3), completionCriteria: .removed) {
            referralProgress = 1
        } completion: { [weak self] in
            guard let self, self.generation == token else { return }
            self.tilt(token)
        }
    }

    private func tilt(_ token: UUID) {
        withAnimation(curve(0.28), completionCriteria: .removed) {
            referralAngle = -10
        } completion: { [weak self] in
            guard let self, self.generation == token else { return }
            self.isFinished = true
            self.onFinished()
        }
    }

    // Use if Reduce Motion is enabled during the transition, or when the screen
    // owner explicitly ends the sequence. Do not call merely on pushing a detail.
    func finishImmediately() {
        guard started, !isFinished else { return }
        generation = UUID() // Ignore callbacks belonging to the old sequence.
        delayTask?.cancel()
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            cashbackHeight = 68
            referralProgress = 1
            referralAngle = -10
            skeletonOpacity = 0
            showsSkeleton = false
            allowsReferral = true
            isWaiting = false
            isFinished = true
        }
        onFinished()
    }

    deinit { delayTask?.cancel() }
}

// Wrap the whole home content, not just the benefits area, with this overlay.
// The supplied skeleton view owns your design-system shimmer (1 s sweep + 1 s pause).
@available(iOS 17.0, macOS 14.0, *)
@MainActor
struct InitialLoadExample<Content: View, Skeleton: View>: View {
    @ObservedObject var motion: InitialLoadMotion
    let contentReady: Bool
    var onFinished: () -> Void = {}
    @ViewBuilder var content: () -> Content
    @ViewBuilder var skeleton: () -> Skeleton
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .top) {
            content()
                .allowsHitTesting(!motion.isWaiting)
                .disabled(motion.isWaiting)
                .accessibilityHidden(motion.isWaiting)
            if motion.showsSkeleton {
                skeleton()
                    .opacity(motion.skeletonOpacity)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .onChange(of: contentReady, initial: true) { _, ready in
            if ready {
                motion.contentBecameReady(reduceMotion: reduceMotion, onFinished: onFinished)
            }
        }
        .onChange(of: reduceMotion) { _, reduced in
            if reduced { motion.finishImmediately() }
        }
    }
}

// Only the animated slot. Supply existing product views, fonts and colours.
// Cashback content should pin its amount 12 pt from the bottom; don't scale text.
@available(iOS 17.0, macOS 14.0, *)
@MainActor
struct BenefitsMotionExample<Cashback: View, Referral: View>: View {
    @ObservedObject var motion: InitialLoadMotion
    @ViewBuilder var cashback: () -> Cashback
    @ViewBuilder var referral: () -> Referral

    var body: some View {
        ZStack(alignment: .top) {
            cashback()
                .frame(width: 119, height: motion.cashbackHeight, alignment: .top)
                .clipped()
            referral()
                .frame(width: 115, height: 51)
                .opacity(motion.referralProgress)
                .scaleEffect(0.9 + 0.1 * motion.referralProgress, anchor: .center)
                .rotationEffect(.degrees(motion.referralAngle), anchor: .center)
                .offset(y: 67.6)
                .allowsHitTesting(motion.allowsReferral)
                .accessibilityHidden(!motion.allowsReferral)
        }
        .frame(width: 119, height: 126, alignment: .top) // Fixed outer geometry.
    }
}
