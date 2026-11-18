import SwiftUI
import UIKit
import QuartzCore

/// iOS 16+. Retain one instance in the owner of the home screen.
@MainActor
final class AccountScrollHint {
    private var consumed = false
    private var task: Task<Void, Never>?

    /// Call when both the skeleton exit and the gallery shimmers have finished.
    func start(afterLoading scrollView: UIScrollView) {
        guard !consumed else { return }
        consumed = true
        guard !UIAccessibility.isReduceMotionEnabled else { return }

        task = Task { @MainActor [weak scrollView] in
            do {
                try await Task.sleep(for: .seconds(1))
                guard let view = scrollView,
                      view.window != nil,
                      !view.isTracking, !view.isDragging, !view.isDecelerating,
                      !UIAccessibility.isReduceMotionEnabled else { return }

                let origin = view.contentOffset.x
                let start = -view.adjustedContentInset.left
                let end = max(start, view.contentSize.width - view.bounds.width + view.adjustedContentInset.right)
                let distance = min(36, end - origin)
                guard abs(origin - start) < 0.5, distance >= 4 else { return }

                try await Self.move(view, from: origin, to: origin + distance,
                                    duration: 0.378, curve: (0.22, 1, 0.36, 1))
                try await Self.move(view, from: origin + distance, to: origin,
                                    duration: 0.522, curve: (0.45, 0, 0.25, 1))
            } catch {
                // Keep the last content offset when the user takes control.
            }
        }
    }

    /// Also call from custom keyboard, wheel or trackpad scroll handlers.
    func cancel() {
        consumed = true
        task?.cancel()
        task = nil
    }

    private static func move(
        _ view: UIScrollView, from start: CGFloat, to end: CGFloat,
        duration: TimeInterval, curve: (Double, Double, Double, Double)
    ) async throws {
        let started = CACurrentMediaTime()
        repeat {
            try Task.checkCancellation()
            guard view.window != nil, !view.isTracking, !view.isDragging,
                  !UIAccessibility.isReduceMotionEnabled else { throw CancellationError() }
            let time = min(1, (CACurrentMediaTime() - started) / duration)
            let progress = CGFloat(eased(time, curve: curve))
            view.contentOffset.x = start + (end - start) * progress
            if time == 1 { return }
            try await Task.sleep(for: .milliseconds(8))
        } while true
    }

    private static func eased(_ time: Double, curve: (Double, Double, Double, Double)) -> Double {
        if time <= 0 || time >= 1 { return time }
        func component(_ t: Double, _ a: Double, _ b: Double) -> Double {
            let inverse = 1 - t
            return 3 * inverse * inverse * t * a + 3 * inverse * t * t * b + t * t * t
        }
        var low = 0.0
        var high = 1.0
        for _ in 0..<16 {
            let middle = (low + high) / 2
            if component(middle, curve.0, curve.2) < time { low = middle }
            else { high = middle }
        }
        return component((low + high) / 2, curve.1, curve.3)
    }
}

/// SwiftUI adapter for an existing UIKit account carousel.
/// In an existing UIKit screen, call the same hint from its loading and gesture callbacks.
struct AccountCarouselExample: UIViewRepresentable {
    let hint: AccountScrollHint
    let loadingFinished: Bool
    let makeScrollView: () -> UIScrollView

    func makeCoordinator() -> Coordinator { Coordinator(hint: hint) }

    func makeUIView(context: Context) -> UIScrollView {
        let view = makeScrollView()
        view.panGestureRecognizer.addTarget(context.coordinator, action: #selector(Coordinator.didPan(_:)))
        return view
    }

    func updateUIView(_ view: UIScrollView, context: Context) {
        if loadingFinished {
            hint.start(afterLoading: view)
        }
    }

    static func dismantleUIView(_ view: UIScrollView, coordinator: Coordinator) {
        view.panGestureRecognizer.removeTarget(coordinator, action: #selector(Coordinator.didPan(_:)))
        coordinator.hint.cancel()
    }

    @MainActor
    final class Coordinator: NSObject {
        let hint: AccountScrollHint
        init(hint: AccountScrollHint) { self.hint = hint }

        @objc func didPan(_ gesture: UIPanGestureRecognizer) {
            if gesture.state == .began { hint.cancel() }
        }
    }
}
