//
//  WeatherFormatting.swift
//  Just Weather
//
//  Pure formatting utilities shared between Just_WeatherView and WeatherSummaryView.
//  Internal access so they can be unit tested via @testable import.
//

import Foundation
import WeatherKit

// MARK: - Unit conversions

func celsiusToFahrenheit(_ celsius: Double) -> Double {
    (celsius * 9.0 / 5.0) + 32.0
}

func kilometersPerHourToMilesPerHour(_ kmh: Double) -> Double {
    kmh * 0.621371
}

// MARK: - Temperature formatting

/// Formats a Celsius value as a locale-appropriate display string (e.g. "72º" or "22.5º").
func formatTemperature(_ celsius: Double, isUSLocale: Bool) -> String {
    if isUSLocale {
        return "\(Int(celsiusToFahrenheit(celsius).rounded()))º"
    } else {
        let rounded = (celsius * 2).rounded() / 2
        if rounded < 10 && rounded > -10 && rounded != floor(rounded) {
            return String(format: "%.1fº", rounded)
        } else {
            return "\(Int(rounded.rounded()))º"
        }
    }
}

// MARK: - Wind formatting

/// Formats a raw wind speed (km/h) and direction (degrees) as a display string.
/// Separated from formatWind(_:isUSLocale:) so it can be unit tested without constructing Wind.
func formatWindSpeed(speedKmh: Double, directionDegrees: Double, isUSLocale: Bool) -> String {
    let direction = cardinalDirection(from: directionDegrees)
    if isUSLocale {
        return "\(Int(kilometersPerHourToMilesPerHour(speedKmh).rounded())) mph \(direction)"
    } else {
        return "\(Int(speedKmh.rounded())) km/h \(direction)"
    }
}

/// Formats a WeatherKit Wind value as a display string.
func formatWind(_ wind: Wind, isUSLocale: Bool) -> String {
    formatWindSpeed(speedKmh: wind.speed.value, directionDegrees: wind.direction.value, isUSLocale: isUSLocale)
}

// MARK: - Cardinal direction

/// Converts a compass bearing in degrees to a 16-point cardinal abbreviation.
func cardinalDirection(from degrees: Double) -> String {
    let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                      "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW", "N"]
    let index = Int((degrees + 11.25) / 22.5) % 16
    return directions[index]
}

// MARK: - Text trimming

/// Caps AI-generated output at two sentences, ensuring a trailing period.
func trimToTwoSentences(_ text: String) -> String {
    let parts = text.split(separator: ".", maxSplits: 2, omittingEmptySubsequences: true)
    let trimmed = parts.prefix(2).joined(separator: ".").trimmingCharacters(in: .whitespaces)
    guard !trimmed.isEmpty else { return text }
    return trimmed.hasSuffix(".") ? trimmed : trimmed + "."
}

// MARK: - Summary style

enum SummaryStyle: String, CaseIterable, Identifiable {
    case basic, technical, poetic, grumpy, none

    var id: String { rawValue }

    var label: String { rawValue.capitalized }

    var icon: String {
        switch self {
        case .basic:     return "cloud.sun"
        case .technical: return "chart.bar.doc.horizontal"
        case .poetic:    return "sparkles"
        case .grumpy:    return "cloud.bolt.rain"
        case .none:      return "minus.circle"
        }
    }
}

/// Returns the LanguageModelSession system instructions for the given summary style.
func summaryInstructions(for style: SummaryStyle) -> String {
    let shared = "Output exactly one sentence. No greeting. No numbers. Do not repeat the data."
    switch style {
    case .basic:
        return """
            You describe outdoor conditions in plain language. \
            State what the air feels like — comfort, humidity, wind — using only everyday words. \
            No metaphors, similes, or poetic language. \
            \(shared)
            """
    case .technical:
        return """
            You brief a meteorologist on current conditions. \
            Use precise professional terminology: thermal comfort, dew point depression, wind if notable. \
            \(shared)
            """
    case .poetic:
        return """
            You describe weather through vivid sensory imagery. \
            Metaphor and simile are welcome. Keep it evocative and concise. \
            \(shared)
            """
    case .grumpy:
        return """
            You describe weather as someone perpetually annoyed by it. \
            Complain about what's unpleasant. Be dry and wry, not melodramatic. \
            \(shared)
            """
    case .none:
        return "" // Not used — view is skipped entirely
    }
}

// MARK: - Weather summary prompt

/// Builds the user-facing prompt sent to LanguageModelSession.
func weatherSummaryPrompt(
    apparentTemp: String,
    actualTemp: String,
    dewPoint: String,
    humidity: Int,
    wind: String,
    highTemp: String,
    lowTemp: String
) -> String {
    var parts = [
        "Apparent temperature: \(apparentTemp) (actual: \(actualTemp))",
        "Dew point: \(dewPoint), humidity: \(humidity)%",
        "Day range: \(lowTemp) – \(highTemp)"
    ]
    if !wind.isEmpty { parts.insert("Wind: \(wind)", at: 2) }
    return "Current conditions:\n" + parts.joined(separator: "\n") + "\n\nDescribe in one sentence how stepping outside feels right now."
}
