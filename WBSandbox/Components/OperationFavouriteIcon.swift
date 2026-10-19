import SwiftUI

/// Pop from the original Pow heart example, adapted to the WB icon and token.
/// https://github.com/EmergeTools/Pow/blob/1b4b1dda28c50b95f0872927ee2226fe8b58950e/Sources/Pow/Transitions/Pop.swift
/// Copyright (c) 2023 Emerge Tools, Inc. See Resources/ThirdParty/Pow-LICENSE.txt.
struct OperationFavouriteIcon: View {
    let isFavourite: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var startedAt: Date?
    @State private var seed = UInt64.random(in: .min ... .max)

    private var playsMotion: Bool { !reduceMotion && scenePhase == .active }

    var body: some View {
        TimelineView(.animation(paused: startedAt == nil || !playsMotion)) { context in
            let elapsed = startedAt.map { max(0, context.date.timeIntervalSince($0)) } ?? 0
            let progress = startedAt == nil || !playsMotion ? 1 : min(1, elapsed / 1.2)
            ZStack {
                Image("opDetailsHeart")
                    .renderingMode(.template)
                    .opacity(isFavourite ? 0 : 1)
                Image("opDetailsHeartFilled")
                    .renderingMode(.template)
                    .modifier(OperationPop(progress: progress, seed: seed))
                    .opacity(isFavourite ? 1 : 0)
            }
            .frame(width: 24, height: 24)
            .foregroundStyle(WBColor.textPrimary)
            // Explicit progress keeps nested button/label transactions from
            // swallowing Pow's insertion transition.
            .transaction { $0.animation = nil }
        }
        .accessibilityHidden(true)
        .onChange(of: isFavourite) { _, saved in
            if saved { seed = .random(in: .min ... .max) }
            startedAt = saved && playsMotion ? .now : nil
        }
        .task(id: startedAt) {
            guard startedAt != nil else { return }
            do {
                try await Task.sleep(for: .seconds(1.2))
                startedAt = nil
            } catch { return }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { finishMotion() }
        }
        .onChange(of: reduceMotion) { _, reduced in
            if reduced { finishMotion() }
        }
        .onDisappear { finishMotion() }
    }

    private func finishMotion() {
        startedAt = nil
    }
}

/// Original Pop geometry, exponential timing curves and 20 radial particles.
/// The only style change is monochrome text/icon Primary, without hue rotation.
private struct OperationPop: ViewModifier {
    let progress: Double
    let seed: UInt64

    private var style: AnyShapeStyle { AnyShapeStyle(WBColor.textPrimary) }

    func body(content: Content) -> some View {
        let t = clamp(2 * (progress - 1 / 2.5))
        let scale = 1 - pow(2, -20 * t)
        content
            .scaleEffect(max(0.0001, scale))
            .opacity(scale > 0 ? 1 : 0)
            .overlay { circleOverlay }
            .background { particles }
    }

    private var circleOverlay: some View {
        let t1 = clamp(1.5 * progress)
        let t2 = clamp(1.5 * (progress - 0.15))
        return ZStack {
            Circle()
                .fill(style)
                .scaleEffect(max(0.0001, 1 - pow(2, -14 * t1)))
                .opacity(t1 > 0 ? 1 : 0)
            Circle()
                .fill(.white)
                .scaleEffect(max(0.0001, 1 - pow(2, -14 * t2)))
                .opacity(t2 > 0 ? 1 : 0)
                .blendMode(.destinationOut)
        }
        .compositingGroup()
        .opacity(clamp(1 - pow(1.3, -20 * (1 - t1))))
        .padding(-8)
        .allowsHitTesting(false)
    }

    private var particles: some View {
        let t = clamp(2 * (progress - 1 / 3.0))
        return Canvas { context, size in
            guard t > 0 else { return }
            var rng = OperationPopRandom(seed: seed)
            let radius = min(size.width, size.height) - 22
            for index in 0..<20 {
                let f = CGFloat.random(in: 0.95...1.1, using: &rng)
                let particleT = clamp(f * (t - (1 - 1 / f)))
                guard particleT > 0 else { return }
                let opacity = particleT < 0.5
                    ? 1 - pow(2, -20 * particleT)
                    : 1 - pow(2, 10 * (particleT - 1))
                guard opacity > 0 else { return }
                let yOffset = CGFloat.random(in: -2...2, using: &rng)
                let scale = easeOut(1 - particleT) * CGFloat.random(in: 0.8...1.4, using: &rng)
                let angle = 360 * CGFloat(index) / 20 + CGFloat.random(in: -5...5, using: &rng)
                // Consume the original hue sample while keeping the WB token
                // unchanged, including in dark appearance.
                _ = CGFloat.random(in: -25...25, using: &rng)
                context.drawLayer { layer in
                    layer.translateBy(x: size.width / 2, y: size.height / 2)
                    layer.rotate(by: .degrees(angle))
                    layer.translateBy(x: 0, y: easeOut(particleT) * (radius / 2 + yOffset))
                    layer.scaleBy(x: scale, y: scale)
                    layer.opacity = clamp(opacity)
                    layer.fill(Circle().path(in: CGRect(x: -1.5, y: -1.5, width: 3, height: 3)), with: .style(style))
                }
            }
        }
        .padding(-30)
        .aspectRatio(1, contentMode: .fit)
        .allowsHitTesting(false)
    }

    private func clamp(_ value: Double) -> Double { min(1, max(0, value)) }
    private func easeOut(_ t: Double) -> Double { pow(t - 1, 3) + 1 }
}

/// Pow's PCG generator keeps each particle's trajectory stable across frames.
private struct OperationPopRandom: RandomNumberGenerator {
    private struct PCG {
        var state: UInt64 = 0x853c49e6748fea9b
        var increment: UInt64 = 0xda3e39cb94b95bdb

        mutating func seed(_ initializer: UInt64, sequence: UInt64) {
            state = 0
            increment = (sequence << 1) | 1
            step()
            state = state &+ initializer
            step()
        }

        mutating func step() { state = state &* 0x5851f42d4c957f2d &+ increment }

        mutating func next() -> UInt32 {
            defer { step() }
            let shifted = UInt32(truncatingIfNeeded: ((state >> 18) ^ state) >> 27)
            let rotation = UInt32(truncatingIfNeeded: state >> 59)
            return (shifted >> rotation) | (shifted << ((~rotation &+ 1) & 31))
        }
    }

    private var a = PCG()
    private var b = PCG()

    init(seed: UInt64) {
        a.seed(seed, sequence: 666)
        b.seed(seed, sequence: 123)
    }

    mutating func next() -> UInt64 { UInt64(a.next()) << 32 | UInt64(b.next()) }
}
