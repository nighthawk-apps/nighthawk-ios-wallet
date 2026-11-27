import Generated
import SwiftUI
import UIComponents

/// Lightweight `flow`-inspired mirrored sync waveform (upper crest, dashed midpoint axis,
/// mirrored lower reflection, and scan cursor tick). Pauses when idle or Reduce Motion is enabled.
struct FlowSyncWaveView: View {
    let progress: Double
    let isActive: Bool
    var upperColor: Color = Asset.Colors.Nighthawk.peach.color
    var lowerColor: Color = Asset.Colors.Nighthawk.parmaviolet.color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var startDate = Date()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isActive || reduceMotion)) { timeline in
            let elapsed = (isActive && !reduceMotion)
                ? timeline.date.timeIntervalSince(startDate)
                : 0
            let phase = (elapsed * 2.6).truncatingRemainder(dividingBy: .pi * 2)
            Canvas { ctx, size in
                drawWave(in: ctx, size: size, phase: phase)
            }
        }
        .frame(height: 34)
        .accessibilityHidden(true)
    }

    private func drawWave(in ctx: GraphicsContext, size: CGSize, phase: Double) {
        let w = size.width
        let h = size.height
        let midY = h * 0.5
        let clamped = min(max(progress, 0), 1)

        var axis = Path()
        axis.move(to: CGPoint(x: 0, y: midY))
        axis.addLine(to: CGPoint(x: w, y: midY))
        ctx.stroke(
            axis,
            with: .color(lowerColor.opacity(0.28)),
            style: StrokeStyle(lineWidth: 1, dash: [4, 4])
        )

        if !isActive {
            if clamped > 0 {
                var track = Path()
                track.move(to: CGPoint(x: 0, y: midY))
                track.addLine(to: CGPoint(x: w * clamped, y: midY))
                ctx.stroke(
                    track,
                    with: .color(upperColor.opacity(0.75)),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
            }
            return
        }

        let stepCount = 44
        let maxAmp = max(h * 0.42, 4)
        let activeFraction = max(clamped, 0.18)

        var upperFill = Path()
        var upperStroke = Path()
        var lowerFill = Path()
        upperFill.move(to: CGPoint(x: 0, y: midY))
        lowerFill.move(to: CGPoint(x: 0, y: midY))

        for i in 0...stepCount {
            let u = Double(i) / Double(stepCount)
            let x = w * u
            let env = u <= activeFraction
                ? 0.35 + 0.65 * max(0, sin(.pi * u / activeFraction))
                : 0.14
            let rawUp = 0.5 + 0.30 * sin(u * 10.5 - phase * 2.0) + 0.20 * sin(u * 21.0 + phase * 3.0)
            let rawDown = 0.42 + 0.28 * sin(u * 8.5 + phase * 1.5 + 1.1) + 0.18 * sin(u * 17.0 - phase * 2.5)
            let dyUp = min(max(rawUp, 0.05), 1.0) * maxAmp * env
            let dyDown = min(max(rawDown, 0.05), 1.0) * maxAmp * 0.72 * env
            let ptUp = CGPoint(x: x, y: midY - dyUp)
            let ptDown = CGPoint(x: x, y: midY + dyDown)
            upperFill.addLine(to: ptUp)
            lowerFill.addLine(to: ptDown)
            if i == 0 {
                upperStroke.move(to: ptUp)
            } else {
                upperStroke.addLine(to: ptUp)
            }
        }
        upperFill.addLine(to: CGPoint(x: w, y: midY))
        upperFill.closeSubpath()
        lowerFill.addLine(to: CGPoint(x: w, y: midY))
        lowerFill.closeSubpath()

        ctx.fill(
            upperFill,
            with: .linearGradient(
                Gradient(colors: [upperColor.opacity(0.42), upperColor.opacity(0.04)]),
                startPoint: CGPoint(x: 0, y: midY - maxAmp),
                endPoint: CGPoint(x: 0, y: midY)
            )
        )
        ctx.fill(
            lowerFill,
            with: .linearGradient(
                Gradient(colors: [lowerColor.opacity(0.04), lowerColor.opacity(0.24)]),
                startPoint: CGPoint(x: 0, y: midY),
                endPoint: CGPoint(x: 0, y: midY + maxAmp)
            )
        )
        ctx.stroke(
            upperStroke,
            with: .color(upperColor.opacity(0.92)),
            style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round)
        )

        let tickX = min(max(w * activeFraction, 2), w - 2)
        var tick = Path()
        tick.move(to: CGPoint(x: tickX, y: midY - maxAmp * 0.65))
        tick.addLine(to: CGPoint(x: tickX, y: midY + maxAmp * 0.45))
        ctx.stroke(
            tick,
            with: .color(upperColor),
            style: StrokeStyle(lineWidth: 2, lineCap: .round)
        )
    }
}
