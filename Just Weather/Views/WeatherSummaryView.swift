//
//  WeatherSummaryView.swift
//  Just Weather
//
//  On-device AI summary of how the weather feels (iOS 26+).
//  Uses Apple Foundation Models — no network call, degrades silently on older OS.
//

import SwiftUI
import Foundation
import FoundationModels
import WeatherKit

@available(iOS 26.0, *)
struct WeatherSummaryView: View {
    /// Full structured weather dump for the model (see `weatherSummaryDataContext`).
    let dataContext: String
    let style: SummaryStyle

    @State private var summary: String? = nil
    @State private var isGenerating: Bool = false

    private var taskID: String {
        "\(style.rawValue)|\(dataContext)"
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
        VStack(alignment: .leading, spacing: 8) {
            Text("Today At A Glance")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Group {
                if isGenerating || summary == nil {
                    TimelineView(.animation) { timeline in
                        let phase = CGFloat(
                            timeline.date.timeIntervalSinceReferenceDate
                                .truncatingRemainder(dividingBy: 2.0) / 2.0
                        )
                        Text("Checking how it feels outside…")
                            .font(.footnote)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundStyle(auroraGradient(phase: phase))
                            .accessibilityLabel("Loading weather summary")
                    }
                } else if let text = summary {
                    Text(text)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity.animation(.easeIn(duration: 0.4)))
                        .accessibilityLabel(text)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassEffect(in: RoundedRectangle(cornerRadius: 14, style: .continuous))
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
            let response = try await session.respond(to: weatherSummaryTaskPrompt(dataContext: dataContext))
            summary = Self.atMostSentences(response.content.trimmingCharacters(in: .whitespacesAndNewlines), max: 2)
        } catch {
            // Silent failure — keep prior summary if one exists
        }
    }

    /// Keeps the first `max` sentences for a hard cap when the model runs over.
    private static func atMostSentences(_ text: String, max: Int) -> String {
        guard max > 0, !text.isEmpty else { return text }
        let ns = text as NSString
        var parts: [String] = []
        ns.enumerateSubstrings(in: NSRange(location: 0, length: ns.length), options: [.bySentences, .localized]) { substring, _, _, stop in
            guard let substring, !substring.isEmpty else { return }
            parts.append(substring.trimmingCharacters(in: .whitespacesAndNewlines))
            if parts.count >= max {
                stop.pointee = true
            }
        }
        if parts.isEmpty { return text }
        return parts.joined(separator: " ")
    }
}

// MARK: - Preview
#Preview {
    if #available(iOS 26.0, *) {
        VStack(spacing: 16) {
            WeatherSummaryView(
                dataContext: "NOW: condition clear\nTODAY: high 76º low 58º\nALERTS: none",
                style: .basic
            )
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
