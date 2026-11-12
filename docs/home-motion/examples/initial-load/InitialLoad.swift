import SwiftUI

// iOS 17+. Example names are arbitrary; use your application's naming and tokens.
// Keep this state with the screen's owner, above navigation destinations.
@available(iOS 17.0, macOS 14.0, *)
@MainActor
final class InitialLoadMotion: ObservableObject {
    @Published private(set) var skeletonOpacity: Double = 1
    @Published private(set) var showsSkeleton = true
    @Published private(set) var isWaiting = true
    @Published private(set) var isFinished = false

    private var started = false
    private var generation = UUID()
    private var onFinished: () -> Void = {}

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
            self.isFinished = true
            self.onFinished()
        }
    }

    // Use if Reduce Motion is enabled during the transition, or when the screen
    // owner explicitly ends the sequence. Do not call merely on pushing a detail.
    func finishImmediately() {
        guard started, !isFinished else { return }
        generation = UUID() // Ignore callbacks belonging to the old sequence.
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            skeletonOpacity = 0
            showsSkeleton = false
            isWaiting = false
            isFinished = true
        }
        onFinished()
    }

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

// Static right-hand cards. Supply existing product views and layout tokens.
// The full benefits area, including the left-hand categories widget, is covered
// by ONE rounded skeleton in the supplied skeleton view (height 116, radius 20).
@available(iOS 17.0, macOS 14.0, *)
@MainActor
struct BenefitsLayoutExample<Cashback: View, Referral: View>: View {
    @ViewBuilder var cashback: () -> Cashback
    @ViewBuilder var referral: () -> Referral

    var body: some View {
        ZStack(alignment: .top) {
            cashback()
                .frame(width: 119, height: 68, alignment: .top)
                .clipped()
            referral()
                .frame(width: 115, height: 51)
                .rotationEffect(.degrees(-10), anchor: .center)
                .offset(y: 67.6)
        }
        .frame(width: 119, height: 126, alignment: .top)
    }
}
