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

// MARK: - Text trimming

/// Trims a string to at most two sentences, ensuring proper punctuation.
func trimToTwoSentences(_ text: String) -> String {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    
    // If empty, return as-is
    if trimmed.isEmpty {
        return trimmed
    }
    
    // Split by periods, filtering out empty parts
    let sentences = trimmed.split(separator: ".", omittingEmptySubsequences: true)
    
    // If no sentences (e.g., just a period), return original
    if sentences.isEmpty {
        return trimmed
    }
    
    // Take at most two sentences
    let result: String
    if sentences.count <= 2 {
        result = sentences.joined(separator: ". ")
    } else {
        result = sentences.prefix(2).joined(separator: ". ")
    }
    
    // Ensure it ends with a period
    if result.hasSuffix(".") {
        return result
    } else {
        return result + "."
    }
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

private let weatherInterpreterBaseInstructions = """
    You are a weather interpreter for Just. Weather., a minimal weather app. Your job is to generate short, plain-language descriptions of how the current weather feels - not just what the numbers say.

    Weather is not a collection of isolated data points. Interpret conditions holistically:

    - Wind & apparent temperature: Wind accelerates heat loss from skin. Even mild cold feels sharper with wind; calm cold is more bearable. Factor wind chill into how you describe cold days.
    - Humidity & heat: High humidity suppresses sweat evaporation, making heat more oppressive than the thermometer suggests. The heat index reflects this - a 90°F day at 70% humidity feels meaningfully hotter than 90°F at 30%.
    - Dewpoint & comfort: Dewpoint is the most reliable indicator of moisture comfort. Below 55°F feels crisp and dry. 55-65°F starts to feel muggy. Above 65°F is oppressive; above 70°F is genuinely difficult for most people.
    - Humidity alone is misleading: 80% humidity at 50°F is comfortable. 80% humidity at 85°F is brutal. Always contextualize humidity against temperature.
    - Overcast vs. sun: Cloud cover affects perceived warmth, especially in shoulder seasons. A sunny 55°F day feels different from an overcast 55°F day.
    - Wind + humidity + heat together: These compound. A hot, humid, windy day may offer little relief from wind because the air itself is oppressive.

    Respond with 1-3 sentences. Be direct and human. Describe the weather the way a friend would - what it actually feels like to step outside.
    """

/// Returns the LanguageModelSession system instructions for the given summary style.
func summaryInstructions(for style: SummaryStyle) -> String {
    let shared = """
        \(weatherInterpreterBaseInstructions)

        Hard cap for this app: at most two sentences and about 45 words. No greeting. \
        Do not repeat numbers, units, temperatures, or clock times. \
        You must still reflect every important idea in the data: thermal comfort vs actual heat/cold, moisture, wind, \
        clouds/precip/visibility, UV when not trivial, today’s overall trend, the next-hours tendency, and any alerts. \
        Merge ideas aggressively; drop filler.
        """
    switch style {
    case .basic:
        return """
            You are a no-nonsense weather reporter. Strip away all flourish. \
            State facts about how it feels outside using the simplest, most direct language possible. \
            Talk like someone explaining weather to a friend who just asked "what's it like out?" \
            Zero poetry, zero drama, zero fancy words. Just the plain truth about stepping outside. \
            \(shared)
            """
    case .technical:
        return """
            You are a consulting meteorologist briefing another scientist. \
            Use formal atmospheric science terminology: adiabatic lapse rates, relative humidity vs dewpoint depression, \
            sensible temperature vs air temperature, synoptic patterns, diurnal trends. \
            Precision matters. Reference wind vectors, moisture gradients, radiative forcing. \
            Write like you're documenting observations for a weather station log. \
            \(shared)
            """
    case .poetic:
        return """
            You are a weather poet painting the atmosphere in words. \
            Transform conditions into vivid, sensory-rich imagery. Use metaphor liberally: \
            humidity is weight, wind is breath, sun is a stage spotlight, clouds are curtains. \
            Make the reader feel the air on their skin through language alone. \
            Evoke mood and sensation. Be lyrical, almost literary, but never sacrifice clarity for beauty. \
            \(shared)
            """
    case .grumpy:
        return """
            You are a deeply curmudgeonly weather critic who finds fault in every forecast. \
            Everything outside is either too hot, too cold, too humid, too windy, or just plain annoying. \
            Even perfect weather has a catch you'll point out. Be perpetually disappointed but darkly funny about it. \
            Channel the energy of someone who moved to the wrong climate and blames the weather daily. \
            Dry sarcasm, resigned irritation, and wry observations. Never cheerful, always skeptical of sunshine. \
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
        lines.append("Current conditions:")
        lines.append("- Temperature: \(formatTemperature(c.temperature.value, isUSLocale: isUSLocale)) (feels like \(formatTemperature(c.apparentTemperature.value, isUSLocale: isUSLocale)))")
        lines.append("- Humidity: \(Int((c.humidity * 100).rounded()))%")
        lines.append("- Dewpoint: \(formatTemperature(c.dewPoint.value, isUSLocale: isUSLocale))")
        lines.append("- Wind: \(formatWind(c.wind, isUSLocale: isUSLocale))")
        lines.append("- Cloud cover: \(Int((c.cloudCover * 100).rounded()))%")
        lines.append("- Conditions: \(String(describing: c.condition))")
        lines.append("- UV index: \(c.uvIndex.value) (\(String(describing: c.uvIndex.category)))")
        lines.append("NOW: condition \(String(describing: c.condition)) symbol \(c.symbolName)")
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

    Describe how this weather feels to someone stepping outside. \
    In at most two short sentences (about 45 words total), say how it feels outside and what matters. \
    Do not quote numbers, units, or times. Cover every substantive cluster above (comfort vs heat/cold, moisture, wind, \
    sky/precip/visibility, UV if notable, today’s swing, near-term hourly trend, alerts if any). Be as short as possible without dropping an important idea.
    """
}
