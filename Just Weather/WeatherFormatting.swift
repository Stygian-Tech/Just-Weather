//
//  WeatherFormatting.swift
//  Just Weather
//
//  Pure formatting utilities shared between Just_WeatherView and WeatherSummaryView.
//  Internal access so they can be unit tested via @testable import.
//

import Foundation
import SwiftUI
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

// MARK: - Weather alerts

/// Formats the alert validity window from WeatherKit metadata (`date` through `expirationDate`).
func formatWeatherAlertEffectiveRange(metadata: WeatherMetadata) -> String {
    formatWeatherAlertEffectiveRange(start: metadata.date, end: metadata.expirationDate)
}

func formatWeatherAlertEffectiveRange(start: Date, end: Date) -> String {
    let cal = Calendar.current
    if cal.isDate(start, inSameDayAs: end) {
        let datePart = start.formatted(date: .abbreviated, time: .omitted)
        let startTime = start.formatted(date: .omitted, time: .shortened)
        let endTime = end.formatted(date: .omitted, time: .shortened)
        return "\(datePart), \(startTime) – \(endTime)"
    }
    return "\(start.formatted(date: .abbreviated, time: .shortened)) – \(end.formatted(date: .abbreviated, time: .shortened))"
}

/// One-line status for compact alert UI: effective window + issuing source (e.g. NWS).
func formatWeatherAlertStatusCaption(metadata: WeatherMetadata, source: String) -> String {
    let start = metadata.date
    let end = metadata.expirationDate
    let cal = Calendar.current
    let until: String
    if cal.isDate(start, inSameDayAs: end) {
        until = "In effect until \(end.formatted(date: .omitted, time: .shortened))"
    } else {
        until = "In effect until \(end.formatted(date: .abbreviated, time: .shortened))"
    }
    let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty { return until }
    return "\(until) · \(trimmed)"
}

/// US-style alert flavor from summary wording (Warning / Watch / Advisory), with `WeatherSeverity` as fallback.
enum WeatherAlertKind: Equatable {
    case advisory
    case watch
    case warning

    var systemImage: String {
        switch self {
        case .advisory: return "info.circle"
        case .watch: return "exclamationmark.triangle"
        case .warning: return "exclamationmark.octagon"
        }
    }
}

func weatherAlertKind(summary: String, severity: WeatherSeverity) -> WeatherAlertKind {
    let s = summary.lowercased()
    if s.contains("warning") { return .warning }
    if s.contains("watch") { return .watch }
    if s.contains("advisory") { return .advisory }
    switch severity {
    case .extreme, .severe: return .warning
    case .moderate: return .watch
    case .minor: return .advisory
    case .unknown: return .watch
    @unknown default: return .watch
    }
}

// MARK: - Cardinal direction

/// Converts a compass bearing in degrees to a 16-point cardinal abbreviation.
func cardinalDirection(from degrees: Double) -> String {
    let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                      "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW", "N"]
    let index = Int((degrees + 11.25) / 22.5) % 16
    return directions[index]
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

// MARK: - App font style (typography)

enum AppFontStyle: String, CaseIterable, Identifiable {
    case regular
    case rounded
    case serif
    case monospaced

    var id: String { rawValue }

    var label: String {
        switch self {
        case .regular: return "Regular"
        case .rounded: return "Rounded"
        case .serif: return "Serif"
        case .monospaced: return "Mono"
        }
    }

    /// Secondary line in Settings (family name).
    var subtitle: String {
        switch self {
        case .regular: return "SF Pro Display"
        case .rounded: return "SF Rounded"
        case .serif: return "New York"
        case .monospaced: return "SF Mono"
        }
    }

    var icon: String {
        switch self {
        case .regular: return "textformat"
        case .rounded: return "textformat.size"
        case .serif: return "character.textbox"
        case .monospaced: return "numbers"
        }
    }

    var fontDesign: Font.Design {
        switch self {
        case .regular: return .default
        case .rounded: return .rounded
        case .serif: return .serif
        case .monospaced: return .monospaced
        }
    }
}

/// Returns the LanguageModelSession system instructions for the given summary style.
func summaryInstructions(for style: SummaryStyle) -> String {
    let shared = """
        Hard cap: at most two sentences and about 45 words. No greeting. \
        Do not repeat numbers, units, temperatures, or clock times. \
        You must still reflect every important idea in the data: thermal comfort vs actual heat/cold, moisture, wind, \
        clouds/precip/visibility, UV when not trivial, today’s overall trend, the next-hours tendency, and any alerts. \
        Merge ideas aggressively; drop filler.
        """
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
            Metaphor and simile are welcome; still obey the word and sentence cap. \
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

// MARK: - Weather summary (full context + task)

/// Structured dump of everything we surface in the app, for the on-device model (numbers allowed here only).
@available(iOS 18.0, *)
func weatherSummaryDataContext(
    current: CurrentWeather?,
    today: DayWeather?,
    nextHours: [HourWeather],
    alerts: [WeatherAlert]?,
    isUSLocale: Bool
) -> String {
    var lines: [String] = []

    if let c = current {
        lines.append("NOW: condition \(String(describing: c.condition)) symbol \(c.symbolName)")
        lines.append("NOW: apparent \(formatTemperature(c.apparentTemperature.value, isUSLocale: isUSLocale)), actual \(formatTemperature(c.temperature.value, isUSLocale: isUSLocale)), dew \(formatTemperature(c.dewPoint.value, isUSLocale: isUSLocale))")
        lines.append("NOW: humidity \(Int((c.humidity * 100).rounded()))%, cloud cover \(Int((c.cloudCover * 100).rounded()))%")
        lines.append("NOW: wind \(formatWind(c.wind, isUSLocale: isUSLocale))")
        lines.append("NOW: UV \(c.uvIndex.value) (\(String(describing: c.uvIndex.category)))")
        lines.append("NOW: pressure \(c.pressure.formatted()), trend \(String(describing: c.pressureTrend))")
        lines.append("NOW: visibility \(c.visibility.formatted())")
        lines.append("NOW: daylight \(c.isDaylight)")
        lines.append("NOW: precip intensity \(c.precipitationIntensity.formatted())")
    } else {
        lines.append("NOW: (current weather unavailable)")
    }

    if let d = today {
        lines.append("TODAY: condition \(String(describing: d.condition)) symbol \(d.symbolName)")
        lines.append("TODAY: high \(formatTemperature(d.highTemperature.value, isUSLocale: isUSLocale)), low \(formatTemperature(d.lowTemperature.value, isUSLocale: isUSLocale))")
        lines.append("TODAY: precip \(String(describing: d.precipitation)), chance \(Int((d.precipitationChance * 100).rounded()))%")
        lines.append("TODAY: UV \(d.uvIndex.value) (\(String(describing: d.uvIndex.category)))")
        lines.append("TODAY: humidity range \(Int((d.minimumHumidity * 100).rounded()))–\(Int((d.maximumHumidity * 100).rounded()))%")
        if let rise = d.sun.sunrise {
            lines.append("TODAY: sunrise \(rise.formatted(date: .abbreviated, time: .shortened))")
        }
        if let set = d.sun.sunset {
            lines.append("TODAY: sunset \(set.formatted(date: .abbreviated, time: .shortened))")
        }
        lines.append("TODAY: moon \(String(describing: d.moon.phase))")
        lines.append("TODAY: wind \(formatWind(d.wind, isUSLocale: isUSLocale))")
        lines.append("DAYTIME window: \(String(describing: d.daytimeForecast.condition)), precip chance \(Int((d.daytimeForecast.precipitationChance * 100).rounded()))%, \(String(describing: d.daytimeForecast.precipitation))")
        lines.append("OVERNIGHT window: \(String(describing: d.overnightForecast.condition)), precip chance \(Int((d.overnightForecast.precipitationChance * 100).rounded()))%, \(String(describing: d.overnightForecast.precipitation))")
        if let rest = d.restOfDayForecast {
            lines.append("REST OF DAY: \(String(describing: rest.condition)), precip chance \(Int((rest.precipitationChance * 100).rounded()))%")
        }
    } else {
        lines.append("TODAY: (daily forecast unavailable)")
    }

    if nextHours.isEmpty {
        lines.append("NEXT HOURS: (no hourly slots)")
    } else {
        lines.append("NEXT HOURS (each slot):")
        for h in nextHours {
            let time = h.date.formatted(date: .omitted, time: .shortened)
            let temp = formatTemperature(h.temperature.value, isUSLocale: isUSLocale)
            lines.append("- \(time): \(temp), \(String(describing: h.condition)), precip chance \(Int((h.precipitationChance * 100).rounded()))%, \(String(describing: h.precipitation)), wind \(formatWind(h.wind, isUSLocale: isUSLocale))")
        }
    }

    if let alerts, !alerts.isEmpty {
        lines.append("ALERTS (\(alerts.count)):")
        for a in alerts {
            lines.append("- [\(String(describing: a.severity))] \(a.summary)")
        }
    } else {
        lines.append("ALERTS: none")
    }

    return lines.joined(separator: "\n")
}

/// User message: full data plus a tight generation task.
func weatherSummaryTaskPrompt(dataContext: String) -> String {
    """
    \(dataContext)

    In at most two short sentences (about 45 words total), say how it feels outside and what matters. \
    Do not quote numbers, units, or times. Cover every substantive cluster above (comfort vs heat/cold, moisture, wind, \
    sky/precip/visibility, UV if notable, today’s swing, near-term hourly trend, alerts if any). Be as short as possible without dropping an important idea.
    """
}
