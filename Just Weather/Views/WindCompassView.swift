//
//  WindCompassView.swift
//  Just Weather
//
//  Pure-SwiftUI compass rose for the wind stat card (iOS 26+).
//

import SwiftUI

@available(iOS 26, *)
struct WindCompassView: View {
    /// Wind direction in degrees (0 = N, 90 = E, 180 = S, 270 = W).
    let degrees: Double
    /// Pre-formatted speed string, e.g. "14 mph NW".
    let speedLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Wind", systemImage: "wind")
                .font(.caption)
                .foregroundStyle(.secondary)

            Canvas { context, size in
                drawCompass(context: context, size: size)
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: .infinity)

            Text(speedLabel)
                .font(.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Wind, \(speedLabel)")
    }

    private func drawCompass(context: GraphicsContext, size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) / 2 - 4

        // Outer ring
        var ring = Path()
        ring.addEllipse(in: CGRect(
            x: center.x - radius, y: center.y - radius,
            width: radius * 2, height: radius * 2
        ))
        context.stroke(ring, with: .color(.secondary.opacity(0.4)), lineWidth: 1.5)

        // Cardinal ticks (0/90/180/270°)
        for deg in stride(from: 0.0, to: 360.0, by: 90.0) {
            let angle = Angle(degrees: deg - 90)
            let outer = pointOn(center: center, radius: radius, angle: angle)
            let inner = pointOn(center: center, radius: radius * 0.82, angle: angle)
            var tick = Path()
            tick.move(to: outer)
            tick.addLine(to: inner)
            context.stroke(tick, with: .color(.secondary.opacity(0.6)), lineWidth: 1.5)
        }

        // Minor ticks (45/135/225/315°)
        for deg in stride(from: 45.0, to: 360.0, by: 90.0) {
            let angle = Angle(degrees: deg - 90)
            let outer = pointOn(center: center, radius: radius, angle: angle)
            let inner = pointOn(center: center, radius: radius * 0.88, angle: angle)
            var tick = Path()
            tick.move(to: outer)
            tick.addLine(to: inner)
            context.stroke(tick, with: .color(.secondary.opacity(0.35)), lineWidth: 1)
        }

        // Cardinal labels
        let labelRadius = radius * 0.64
        for (label, deg) in [("N", 0.0), ("E", 90.0), ("S", 180.0), ("W", 270.0)] {
            let pos = pointOn(center: center, radius: labelRadius, angle: Angle(degrees: deg - 90))
            let isNorth = label == "N"
            let resolved = context.resolve(
                Text(label)
                    .font(.system(size: radius * 0.22, weight: isNorth ? .bold : .regular))
                    .foregroundStyle(isNorth ? AnyShapeStyle(Color.primary) : AnyShapeStyle(Color.secondary))
            )
            context.draw(resolved, at: pos)
        }

        // Needle — points in the direction wind travels toward
        let needleAngle = Angle(degrees: degrees - 90)
        let tipRadius  = radius * 0.50
        let tailRadius = radius * 0.30
        let wingHalf   = radius * 0.13

        let tip  = pointOn(center: center, radius: tipRadius,   angle: needleAngle)
        let tail = pointOn(center: center, radius: -tailRadius, angle: needleAngle)

        var shaft = Path()
        shaft.move(to: tip)
        shaft.addLine(to: tail)
        context.stroke(shaft, with: .color(.primary), lineWidth: 2)

        let leftWing  = pointOn(center: tip, radius: wingHalf, angle: Angle(degrees: needleAngle.degrees + 135))
        let rightWing = pointOn(center: tip, radius: wingHalf, angle: Angle(degrees: needleAngle.degrees - 135))
        var head = Path()
        head.move(to: tip)
        head.addLine(to: leftWing)
        head.addLine(to: rightWing)
        head.closeSubpath()
        context.fill(head, with: .color(.primary))

        // Center dot
        let dotR: CGFloat = 3
        var dot = Path()
        dot.addEllipse(in: CGRect(x: center.x - dotR, y: center.y - dotR, width: dotR * 2, height: dotR * 2))
        context.fill(dot, with: .color(.secondary))
    }

    private func pointOn(center: CGPoint, radius: CGFloat, angle: Angle) -> CGPoint {
        CGPoint(
            x: center.x + radius * CGFloat(cos(angle.radians)),
            y: center.y + radius * CGFloat(sin(angle.radians))
        )
    }
}

/// Ticks + needle only, for embedding beside wind text without growing the stat card.
@available(iOS 26, *)
struct WindCompassMiniGlyph: View {
    let degrees: Double

    var body: some View {
        Canvas { context, size in
            drawCompactCompass(context: context, size: size, degrees: degrees)
        }
        .frame(width: 40, height: 40)
        .accessibilityHidden(true)
    }

    private func drawCompactCompass(context: GraphicsContext, size: CGSize, degrees: Double) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) / 2 - 2

        var ring = Path()
        ring.addEllipse(in: CGRect(
            x: center.x - radius, y: center.y - radius,
            width: radius * 2, height: radius * 2
        ))
        context.stroke(ring, with: .color(.secondary.opacity(0.4)), lineWidth: 1)

        for deg in stride(from: 0.0, to: 360.0, by: 90.0) {
            let angle = Angle(degrees: deg - 90)
            let outer = pointOn(center: center, radius: radius, angle: angle)
            let inner = pointOn(center: center, radius: radius * 0.78, angle: angle)
            var tick = Path()
            tick.move(to: outer)
            tick.addLine(to: inner)
            context.stroke(tick, with: .color(.secondary.opacity(0.55)), lineWidth: 1)
        }

        let needleAngle = Angle(degrees: degrees - 90)
        let tipRadius = radius * 0.52
        let tailRadius = radius * 0.28
        let wingHalf = radius * 0.12

        let tip = pointOn(center: center, radius: tipRadius, angle: needleAngle)
        let tail = pointOn(center: center, radius: -tailRadius, angle: needleAngle)

        var shaft = Path()
        shaft.move(to: tip)
        shaft.addLine(to: tail)
        context.stroke(shaft, with: .color(.primary), lineWidth: 1.25)

        let leftWing = pointOn(center: tip, radius: wingHalf, angle: Angle(degrees: needleAngle.degrees + 135))
        let rightWing = pointOn(center: tip, radius: wingHalf, angle: Angle(degrees: needleAngle.degrees - 135))
        var head = Path()
        head.move(to: tip)
        head.addLine(to: leftWing)
        head.addLine(to: rightWing)
        head.closeSubpath()
        context.fill(head, with: .color(.primary))

        let dotR: CGFloat = 2
        var dot = Path()
        dot.addEllipse(in: CGRect(x: center.x - dotR, y: center.y - dotR, width: dotR * 2, height: dotR * 2))
        context.fill(dot, with: .color(.secondary))
    }

    private func pointOn(center: CGPoint, radius: CGFloat, angle: Angle) -> CGPoint {
        CGPoint(
            x: center.x + radius * CGFloat(cos(angle.radians)),
            y: center.y + radius * CGFloat(sin(angle.radians))
        )
    }
}

#Preview {
    if #available(iOS 26, *) {
        HStack(spacing: 16) {
            WindCompassView(degrees: 315, speedLabel: "14 mph NW")
                .padding(12)
                .glassEffect(in: RoundedRectangle(cornerRadius: 14))
                .frame(width: 160)
            WindCompassView(degrees: 90, speedLabel: "8 mph E")
                .padding(12)
                .glassEffect(in: RoundedRectangle(cornerRadius: 14))
                .frame(width: 160)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
