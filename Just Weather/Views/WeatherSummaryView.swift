//
//  WeatherSummaryView.swift
//  Just Weather
//
//  On-device AI summary of how the weather feels (iOS 26+).
//  Uses Apple Foundation Models — no network call, degrades silently on older OS.
//

import SwiftUI
import FoundationModels
import WeatherKit

@available(iOS 26.0, *)
struct WeatherSummaryView: View {
    // Pre-formatted locale-correct strings (passed from Just_WeatherView)
    let apparentTemp: String    // e.g. "72º"
    let actualTemp: String      // e.g. "68º"
    let dewPoint: String        // e.g. "61º"
    let humidity: Int           // 0–100
    let wind: String            // e.g. "14 mph NW" or "" if unavailable
    let highTemp: String        // e.g. "76º"
    let lowTemp: String         // e.g. "58º"
    let style: SummaryStyle

    @State private var summary: String? = nil
    @State private var isGenerating: Bool = false

    // Re-generates when comfort-relevant values or the style changes
    private var taskID: String {
        "\(apparentTemp)|\(actualTemp)|\(dewPoint)|\(humidity)|\(wind)|\(style.rawValue)"
    }

    var body: some View {
        if style == .none { return AnyView(EmptyView()) }

        switch SystemLanguageModel.default.availability {
        case .available:
            return AnyView(
                summaryView
                    .task(id: taskID) {
                        await generateSummary()
                    }
            )
        case .unavailable:
            return AnyView(EmptyView())
        }
    }

    @ViewBuilder
    private var summaryView: some View {
        Group {
            if isGenerating || summary == nil {
                // Apple Intelligence aurora shimmer — gradient sweeps left-to-right via TimelineView
                TimelineView(.animation) { timeline in
                    let phase = CGFloat(
                        timeline.date.timeIntervalSinceReferenceDate
                            .truncatingRemainder(dividingBy: 2.0) / 2.0
                    )
                    Text("Checking how it feels outside…")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(auroraGradient(phase: phase))
                        .accessibilityLabel("Loading weather summary")
                }
            } else if let text = summary {
                Text(text)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .transition(.opacity.animation(.easeIn(duration: 0.4)))
                    .accessibilityLabel(text)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassEffect(in: RoundedRectangle(cornerRadius: 20))
    }

    /// A wide gradient that slides across the text to create a continuous aurora sweep.
    private func auroraGradient(phase: CGFloat) -> LinearGradient {
        LinearGradient(
            colors: [
                Color(hue: 0.58, saturation: 0.9, brightness: 1.0),   // blue
                Color(hue: 0.72, saturation: 0.8, brightness: 1.0),   // purple
                Color(hue: 0.88, saturation: 0.7, brightness: 1.0),   // pink
                Color(hue: 0.58, saturation: 0.9, brightness: 1.0),   // blue (wrap)
                Color(hue: 0.72, saturation: 0.8, brightness: 1.0),   // purple
            ],
            startPoint: UnitPoint(x: phase * 3 - 1, y: 0.5),
            endPoint:   UnitPoint(x: phase * 3 + 2, y: 0.5)
        )
    }

    private func generateSummary() async {
        isGenerating = true
        defer { isGenerating = false }
        do {
            let session = LanguageModelSession(instructions: summaryInstructions(for: style))
            let response = try await session.respond(to: weatherPrompt)
            summary = trimToTwoSentences(response.content)
        } catch {
            // Silent failure — keep prior summary if one exists
        }
    }

    private var weatherPrompt: String {
        weatherSummaryPrompt(
            apparentTemp: apparentTemp,
            actualTemp: actualTemp,
            dewPoint: dewPoint,
            humidity: humidity,
            wind: wind,
            highTemp: highTemp,
            lowTemp: lowTemp
        )
    }
}

// MARK: - Preview
#Preview {
    if #available(iOS 26.0, *) {
        VStack(spacing: 16) {
            WeatherSummaryView(
                apparentTemp: "72º",
                actualTemp: "68º",
                dewPoint: "61º",
                humidity: 72,
                wind: "14 mph NW",
                highTemp: "76º",
                lowTemp: "58º",
                style: .basic
            )
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
