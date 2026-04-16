//
//  ContentView.swift
//  Just Weather
//
//  Created by Sam Clemente on 8/21/24.
//

import Foundation
import SwiftUI
import WeatherKit

struct Just_WeatherView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var purchaseManager: PurchaseManager
    @StateObject private var weatherData = WeatherData()
    @State private var isLoading = true
    @State private var showSettings = false

    @AppStorage("summaryStyle") private var summaryStyle: SummaryStyle = .basic

    let formatter = MeasurementFormatter()
    private let isUSLocale = Locale.current.measurementSystem == .us

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                if isLoading {
                    Text("Fetching Weather Data...")
                        .font(.largeTitle)
                        .accessibilityLabel("Loading weather data")
                } else if weatherData.wind != nil {
                    if #available(iOS 26, *) {
                        ios26Layout
                    } else {
                        legacyLayout
                    }
                } else {
                    Text("No Weather Data Available")
                        .font(.largeTitle)
                }
            }

            // Gear icon — top-right corner
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.title3)
                    .padding(16)
            }
            .accessibilityLabel("Settings")
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(purchaseManager)
        }
        .sheet(
            isPresented: Binding(
                get: { !purchaseManager.isEntitled && !purchaseManager.isLoading },
                set: { _ in }
            )
        ) {
            PaywallView()
                .environmentObject(purchaseManager)
                .interactiveDismissDisabled(true)
        }
        .onAppear {
            fetchWeatherIfLocationAvailable()
        }
        .onChange(of: locationManager.locationStatus) { _ in
            fetchWeatherIfLocationAvailable()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            fetchWeatherIfLocationAvailable()
            Task { await purchaseManager.refresh() }
        }
    }

    // MARK: - Pre-formatted stat values (shared by both layouts)

    private var actualTempString: String { formatTemperature(weatherData.temperature.value, isUSLocale: isUSLocale) }
    private var windString: String { weatherData.wind.map { formatWind($0, isUSLocale: isUSLocale) } ?? "—" }
    private var humidityString: String { "\(Int(weatherData.humidity * 100))%" }
    private var dewPointString: String { formatTemperature(weatherData.dewPoint.value, isUSLocale: isUSLocale) }
    private var sunriseString: String { weatherData.sunrise?.formatted(date: .omitted, time: .shortened) ?? "None" }
    private var sunsetString: String { weatherData.sunset?.formatted(date: .omitted, time: .shortened) ?? "None" }

    // MARK: - Shared sections (accessible on all OS versions)

    private var feelsLikeSection: some View {
        VStack {
            temperatureDecimalFormatter(weatherData.apparentTemperature.value)
                .font(.custom("SF-Pro-Display-Regular", fixedSize: 150))
            Text("Feels Like")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Feels like \(formatTemperature(weatherData.apparentTemperature.value, isUSLocale: isUSLocale))")
        .accessibilityAddTraits(.isHeader)
    }

    private var conditionSection: some View {
        VStack {
            Image(systemName: weatherData.conditionSymbol)
                .font(.largeTitle)
                .accessibilityHidden(true)
            Text(String(describing: weatherData.condition))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Condition: \(String(describing: weatherData.condition))")
    }

    private var highLowSection: some View {
        HStack {
            Text("H:")
            temperatureDecimalFormatter(weatherData.highTemp.value)
            Text("L:")
            temperatureDecimalFormatter(weatherData.lowTemp.value)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("High \(formatTemperature(weatherData.highTemp.value, isUSLocale: isUSLocale)), Low \(formatTemperature(weatherData.lowTemp.value, isUSLocale: isUSLocale))")
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
        if let moonPhase = weatherData.moonPhase {
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
            // Summary is part of the layout flow so the engine can center
            // the feels-like temp in the actual space between them
            if summaryStyle != .none {
                WeatherSummaryView(
                    apparentTemp: formatTemperature(weatherData.apparentTemperature.value, isUSLocale: isUSLocale),
                    actualTemp: formatTemperature(weatherData.temperature.value, isUSLocale: isUSLocale),
                    dewPoint: formatTemperature(weatherData.dewPoint.value, isUSLocale: isUSLocale),
                    humidity: Int(weatherData.humidity * 100),
                    wind: weatherData.wind.map { formatWind($0, isUSLocale: isUSLocale) } ?? "",
                    highTemp: formatTemperature(weatherData.highTemp.value, isUSLocale: isUSLocale),
                    lowTemp: formatTemperature(weatherData.lowTemp.value, isUSLocale: isUSLocale),
                    style: summaryStyle
                )
                .padding(.horizontal, 52)
                .padding(.top, 12)
            }

            Spacer()

            // Hero: no glass — stays centered between summary and conditions
            feelsLikeSection

            Spacer()

            VStack(spacing: 12) {
                conditionSection
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 20))

                highLowSection
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .glassEffect(in: Capsule())

                statGridGlass

                if let moonPhase = weatherData.moonPhase {
                    HStack {
                        Image(systemName: moonPhase.symbolName)
                            .accessibilityHidden(true)
                        Text(String(describing: moonPhase))
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Moon phase: \(String(describing: moonPhase))")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .glassEffect(in: Capsule())
                }
            }
            .padding(.bottom, 20)
        }
    }

    /// 2×3 grid of individual glass stat cards for iOS 26.
    @available(iOS 26, *)
    private var statGridGlass: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                statCard(icon: "thermometer.medium", label: "Temperature", value: actualTempString)
                    .padding(12)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 14))
                statCard(icon: "wind", label: "Wind", value: windString)
                    .padding(12)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 14))
            }
            HStack(spacing: 10) {
                statCard(icon: "humidity", label: "Humidity", value: humidityString)
                    .padding(12)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 14))
                statCard(icon: "drop.degreesign", label: "Dew Point", value: dewPointString)
                    .padding(12)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 14))
            }
            HStack(spacing: 10) {
                statCard(icon: "sunrise", label: "Sunrise", value: sunriseString)
                    .padding(12)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 14))
                statCard(icon: "sunset", label: "Sunset", value: sunsetString)
                    .padding(12)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(.horizontal)
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
            statGrid
            moonPhaseSection
            Spacer()
        }
    }

    /// 2×3 grid of labeled stat cards for pre-iOS 26 (no glass).
    private var statGrid: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                statCard(icon: "thermometer.medium", label: "Temperature", value: actualTempString)
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

    private func fetchWeatherIfLocationAvailable() {
        Task {
            if let lastLocation = locationManager.lastLocation {
                await weatherData.fetchWeather(for: lastLocation)
                isLoading = false
            } else {
                print("No Location Found")
                isLoading = false
            }
        }
    }

    private func temperatureDecimalFormatter(_ temperature: Double) -> Text {
        Text(formatTemperature(temperature, isUSLocale: isUSLocale))
    }
}
