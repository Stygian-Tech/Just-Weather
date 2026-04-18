//
//  ContentView.swift
//  Just Weather
//
//  Created by Sam Clemente on 8/21/24.
//

import Foundation
import SwiftUI
import WeatherKit
import CoreLocation

struct Just_WeatherView: View {
    @EnvironmentObject var purchaseManager: PurchaseManager
    @EnvironmentObject var weatherData: WeatherData
    @EnvironmentObject var locationManager: LocationManager
    @State private var showSettings = false
    @State private var currentAlertPage: Int? = 0
    /// Last non-empty reverse-geocode label; retained when a later lookup fails or returns nothing (stable capsule).
    @State private var placemarkTitle: String = ""

    @AppStorage("summaryStyle") private var summaryStyle: SummaryStyle = .basic
    @AppStorage("appFontStyle") private var appFontStyle: AppFontStyle = .regular

    let formatter = MeasurementFormatter()
    private let isUSLocale = Locale.current.measurementSystem == .us

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if #available(iOS 26, *) {
                    ios26Layout
                        .task(id: locationGeocodeTaskID) {
                            await refreshLocationPlacemark()
                        }
                } else {
                    legacyLayout
                }
            }
            .modifier(OptionalFontDesignModifier(design: appFontStyle.fontDesign))

            // Gear icon — top-right corner
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.title3)
                    .foregroundStyle(.primary)
                    .padding(16)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(purchaseManager)
        }
    }

    // MARK: - Pre-formatted stat values (shared by both layouts)

    private var actualTempString: String { formatTemperature(weatherData.current?.temperature.value ?? 0, isUSLocale: isUSLocale) }
    private var windString: String { weatherData.current.map { formatWind($0.wind, isUSLocale: isUSLocale) } ?? "—" }
    private var humidityString: String { "\(Int((weatherData.current?.humidity ?? 0) * 100))%" }
    private var dewPointString: String { formatTemperature(weatherData.current?.dewPoint.value ?? 0, isUSLocale: isUSLocale) }
    private var sunriseString: String { weatherData.today?.sun.sunrise?.formatted(date: .omitted, time: .shortened) ?? "None" }
    private var sunsetString: String { weatherData.today?.sun.sunset?.formatted(date: .omitted, time: .shortened) ?? "None" }

    // MARK: - Shared sections (accessible on all OS versions)

    private var feelsLikeSection: some View {
        let apparentValue = weatherData.current?.apparentTemperature.value ?? 0
        let heroFont: Font = {
            switch appFontStyle {
            case .regular:
                return .custom("SF-Pro-Display-Regular", size: 150, relativeTo: .largeTitle)
            case .rounded, .serif, .monospaced:
                return .system(size: 150, weight: .regular, design: appFontStyle.fontDesign)
            }
        }()
        return VStack {
            temperatureDecimalFormatter(apparentValue)
                .font(heroFont)
            Text("Feels Like")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Feels like \(formatTemperature(apparentValue, isUSLocale: isUSLocale))")
        .accessibilityAddTraits(.isHeader)
    }

    private var conditionSection: some View {
        VStack {
            Image(systemName: weatherData.current?.symbolName ?? "sun.max")
                .font(.largeTitle)
                .accessibilityHidden(true)
            Text(String(describing: weatherData.current?.condition ?? .clear))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Condition: \(String(describing: weatherData.current?.condition ?? .clear))")
    }

    private var highLowSection: some View {
        let high = weatherData.today?.highTemperature.value ?? 0
        let low  = weatherData.today?.lowTemperature.value ?? 0
        return HStack {
            Text("H:")
            temperatureDecimalFormatter(high)
            Text("L:")
            temperatureDecimalFormatter(low)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("High \(formatTemperature(high, isUSLocale: isUSLocale)), Low \(formatTemperature(low, isUSLocale: isUSLocale))")
    }

    /// Labeled card content for a single weather stat. Padding and glass are applied by each layout.
    @ViewBuilder
    private func statCard(icon: String, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(label, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(value)")
    }

    @ViewBuilder
    private var moonPhaseSection: some View {
        if let moonPhase = weatherData.today?.moon.phase {
            HStack {
                Image(systemName: moonPhase.symbolName)
                    .accessibilityHidden(true)
                Text(String(describing: moonPhase))
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Moon phase: \(String(describing: moonPhase))")
        }
    }

    // MARK: - iOS 26 layout (Liquid Glass)

    @available(iOS 26, *)
    private var ios26Layout: some View {
        VStack(spacing: 0) {
            Spacer()

            locationCapsuleGlass
                .padding(.bottom, 8)

            feelsLikeSection

            Spacer()

            VStack(spacing: 12) {
                highLowSection
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .glassEffect(in: Capsule())

                if summaryStyle != .none {
                    WeatherSummaryView(
                        dataContext: weatherSummaryDataContext(
                            current: weatherData.current,
                            today: weatherData.today,
                            nextHours: weatherData.nextFiveHours,
                            alerts: weatherData.alerts,
                            isUSLocale: isUSLocale
                        ),
                        style: summaryStyle
                    )
                    .padding(.horizontal)
                }

                alertsCarouselGlass

                fiveHourForecastGlass

                statGridGlass
            }
            .padding(.bottom, 20)
        }
    }

    @available(iOS 26, *)
    private var locationGeocodeTaskID: String {
        guard let loc = locationManager.lastLocation else { return "nil" }
        return "\(loc.coordinate.latitude),\(loc.coordinate.longitude),\(loc.timestamp.timeIntervalSince1970)"
    }

    @available(iOS 26, *)
    @ViewBuilder
    private var locationCapsuleGlass: some View {
        if !placemarkTitle.isEmpty {
            HStack(spacing: 8) {
                Image(systemName: "location.fill")
                    .font(.subheadline)
                    .accessibilityHidden(true)
                Text(placemarkTitle)
                    .font(.subheadline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .glassEffect(in: Capsule())
            .padding(.horizontal, 24)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Location, \(placemarkTitle)")
        }
    }

    @available(iOS 26, *)
    private func refreshLocationPlacemark() async {
        guard let loc = locationManager.lastLocation else {
            await MainActor.run { placemarkTitle = "" }
            return
        }
        let geocoder = CLGeocoder()
        let resolved: String
        do {
            let marks = try await geocoder.reverseGeocodeLocation(loc)
            if let p = marks.first {
                resolved = placemarkDisplayName(from: p)
            } else {
                resolved = ""
            }
        } catch {
            resolved = ""
        }
        await MainActor.run {
            // Keep the last good label when geocoding returns empty or fails (avoids capsule flashing).
            if !resolved.isEmpty {
                placemarkTitle = resolved
            }
        }
    }

    /// Human-readable place name only (no coordinates).
    private func placemarkDisplayName(from p: CLPlacemark) -> String {
        if let city = p.locality {
            if let region = p.administrativeArea, !region.isEmpty {
                return "\(city), \(region)"
            }
            return city
        }
        if let sub = p.subAdministrativeArea, !sub.isEmpty {
            return sub
        }
        if let region = p.administrativeArea, !region.isEmpty {
            return region
        }
        if let name = p.name, !name.isEmpty {
            return name
        }
        return ""
    }

    /// Compact capsule alert strip (paging when needed), aligned with other glass controls.
    @available(iOS 26, *)
    @ViewBuilder
    private var alertsCarouselGlass: some View {
        if let alerts = weatherData.alerts, !alerts.isEmpty {
            VStack(spacing: 6) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(Array(alerts.enumerated()), id: \.offset) { i, alert in
                            let statusCaption = formatWeatherAlertStatusCaption(metadata: alert.metadata, source: alert.source)
                            let rangeSpoken = formatWeatherAlertEffectiveRange(metadata: alert.metadata)
                            let alertKind = weatherAlertKind(summary: alert.summary, severity: alert.severity)
                            let accent = weatherAlertAccent(for: alertKind)
                            HStack(alignment: .center, spacing: 10) {
                                Image(systemName: alertKind.systemImage)
                                    .font(.system(size: 15, weight: .semibold, design: appFontStyle.fontDesign))
                                    .foregroundStyle(accent)
                                    .frame(width: 34, height: 34)
                                    .background(accent.opacity(0.18), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(alert.summary)
                                        .font(.subheadline.weight(.semibold))
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text(statusCaption)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .containerRelativeFrame(.horizontal)
                            .id(i)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Alert \(i + 1) of \(alerts.count). \(alert.summary). \(statusCaption). \(rangeSpoken).")
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $currentAlertPage)
                .frame(minHeight: 62)
                .glassEffect(in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                if alerts.count > 1 {
                    HStack(spacing: 4) {
                        ForEach(0..<alerts.count, id: \.self) { i in
                            Circle()
                                .fill((currentAlertPage ?? 0) == i ? Color.primary : Color.secondary.opacity(0.35))
                                .frame(width: 5, height: 5)
                                .animation(.easeInOut(duration: 0.2), value: currentAlertPage)
                        }
                    }
                    .accessibilityLabel("Alert page indicators")
                }
            }
            .padding(.horizontal)
        }
    }

    /// Full-width hourly strip: three rows so times, icons, and temps line up across columns.
    @available(iOS 26, *)
    @ViewBuilder
    private var fiveHourForecastGlass: some View {
        let hours = weatherData.nextFiveHours
        if !hours.isEmpty {
            VStack(spacing: 4) {
                HStack(spacing: 0) {
                    ForEach(hours, id: \.date) { hour in
                        Text(hour.date.formatted(date: .omitted, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .frame(maxWidth: .infinity)
                            .frame(height: 14, alignment: .center)
                    }
                }
                HStack(spacing: 0) {
                    ForEach(hours, id: \.date) { hour in
                        Image(systemName: hour.symbolName)
                            .font(.body)
                            .accessibilityHidden(true)
                            .frame(maxWidth: .infinity)
                            .frame(height: 22, alignment: .center)
                    }
                }
                HStack(spacing: 0) {
                    ForEach(hours, id: \.date) { hour in
                        Text(formatTemperature(hour.temperature.value, isUSLocale: isUSLocale))
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .frame(maxWidth: .infinity)
                            .frame(height: 16, alignment: .center)
                    }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(hourlyForecastAccessibilityLabel(hours: hours))
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .glassEffect(in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal)
        }
    }

    @available(iOS 26, *)
    private func hourlyForecastAccessibilityLabel(hours: [HourWeather]) -> String {
        hours.map { hour in
            let t = hour.date.formatted(date: .omitted, time: .shortened)
            let temp = formatTemperature(hour.temperature.value, isUSLocale: isUSLocale)
            return "\(t), \(String(describing: hour.condition)), \(temp)"
        }.joined(separator: ". ")
    }

    @available(iOS 26, *)
    private func weatherAlertAccent(for kind: WeatherAlertKind) -> Color {
        switch kind {
        case .advisory:
            return Color(red: 0.29, green: 0.56, blue: 0.88)
        case .watch:
            return .orange
        case .warning:
            return .red
        }
    }

    /// Three stat cards in one row; wind (with mini compass) & moon cards; sunrise/sunset bar.
    @available(iOS 26, *)
    private var statGridGlass: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                statCard(icon: "thermometer.medium", label: "Temp", value: actualTempString)
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                statCard(icon: "drop.degreesign", label: "Dew Point", value: dewPointString)
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                statCard(icon: "humidity", label: "Humidity", value: humidityString)
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            HStack(spacing: 10) {
                windStatCardGlass

                if let moonPhase = weatherData.today?.moon.phase {
                    statCard(icon: moonPhase.symbolName, label: "Moon", value: String(describing: moonPhase))
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .glassEffect(in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                } else {
                    statCard(icon: "moon", label: "Moon", value: "—")
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .glassEffect(in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }

            sunriseSunsetBar
        }
        .padding(.horizontal)
    }

    @available(iOS 26, *)
    private var windStatCardGlass: some View {
        Group {
            if let wind = weatherData.current?.wind {
                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Wind", systemImage: "wind")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(windString)
                            .font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    WindCompassMiniGlyph(degrees: wind.direction.value)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Wind, \(windString)")
            } else {
                statCard(icon: "wind", label: "Wind", value: "—")
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .glassEffect(in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    /// Bottom bar: sunrise leading, sunset trailing.
    @available(iOS 26, *)
    private var sunriseSunsetBar: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "sunrise")
                    .accessibilityHidden(true)
                Text(sunriseString)
            }
            Spacer(minLength: 16)
            HStack(spacing: 8) {
                Image(systemName: "sunset")
                    .accessibilityHidden(true)
                Text(sunsetString)
            }
        }
        .font(.body)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Sunrise \(sunriseString), Sunset \(sunsetString)")
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .glassEffect(in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Legacy layout (pre-iOS 26, raw SwiftUI text)

    private var legacyLayout: some View {
        VStack {
            Spacer()
            Spacer()
            Spacer()
            feelsLikeSection
            Spacer()
            Spacer()
            conditionSection
            Spacer()
            highLowSection
            legacyStatGrid
            moonPhaseSection
            Spacer()
        }
    }

    /// 2×3 grid of labeled stat cards for pre-iOS 26 (no glass).
    private var legacyStatGrid: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                statCard(icon: "thermometer.medium", label: "Temp", value: actualTempString)
                statCard(icon: "wind", label: "Wind", value: windString)
            }
            HStack(spacing: 12) {
                statCard(icon: "humidity", label: "Humidity", value: humidityString)
                statCard(icon: "drop.degreesign", label: "Dew Point", value: dewPointString)
            }
            HStack(spacing: 12) {
                statCard(icon: "sunrise", label: "Sunrise", value: sunriseString)
                statCard(icon: "sunset", label: "Sunset", value: sunsetString)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private func temperatureDecimalFormatter(_ temperature: Double) -> Text {
        Text(formatTemperature(temperature, isUSLocale: isUSLocale))
    }
}

/// `fontDesign(_:)` requires iOS 16.1+; app target is 16.0.
private struct OptionalFontDesignModifier: ViewModifier {
    let design: Font.Design

    func body(content: Content) -> some View {
        if #available(iOS 16.1, *) {
            content.fontDesign(design)
        } else {
            content
        }
    }
}
