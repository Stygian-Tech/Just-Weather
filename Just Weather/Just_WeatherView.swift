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
    @StateObject private var weatherData = WeatherData()
    @State private var isLoading = true

    let formatter = MeasurementFormatter()
    private let isUSLocale = Locale.current.measurementSystem == .us

    var body: some View {
        VStack {
            if isLoading {
                Text("Fetching Weather Data...")
                    .font(.largeTitle)
            } else if weatherData.wind != nil {
                VStack {
                    Spacer()
                    Spacer()
                    Spacer()
                    VStack {
                        temperatureDecimalFormatter(weatherData.apparentTemperature.value)
                            .font(.custom("SF-Pro-Display-Regular", fixedSize: 150))
                        Text("Feels Like")
                    }
                    Spacer()
                    Spacer()
                    VStack {
                        Image(systemName: weatherData.conditionSymbol)
                            .font(.largeTitle)
                        Text(String(describing: weatherData.condition))
                    }
                    Spacer()
                    HStack {
                        Text("H:")
                        temperatureDecimalFormatter(weatherData.highTemp.value)
                        Text("L:")
                        temperatureDecimalFormatter(weatherData.lowTemp.value)
                    }
                    HStack {
                        VStack {
                            Image(systemName: "thermometer.medium")
                            Image(systemName: "humidity")
                            Image(systemName: "sunrise")
                        }
                        VStack {
                            HStack {
                                // Text("Actual:")
                                Spacer()
                                temperatureDecimalFormatter(weatherData.temperature.value)
                            }
                            HStack {
                                // Text("Humidity:")
                                Spacer()
                                Text("\(weatherData.humidity * 100, specifier: "%.0f")%")
                            }
                            HStack {
                                // Text("Sunrise:")
                                Spacer()
                                if let sunrise = weatherData.sunrise  {
                                    Text("\(sunrise.formatted(date: .omitted, time: .shortened))")
                                } else {
                                    Text("None")
                                }
                            }
                        }
                        Spacer()
                        VStack {
                            Image(systemName: "wind")
                            Image(systemName: "drop.degreesign")
                            Image(systemName: "sunset")
                        }
                        VStack {
                            HStack {
                                // Text("Wind:")
                                Spacer()
                                if let wind = weatherData.wind {
                                    Text(formatWind(wind, isUSLocale: isUSLocale))
                                } else {
                                    Text("Fetching...")
                                }
                            }
                            HStack {
                                // Text("Dew Point:")
                                Spacer()
                                temperatureDecimalFormatter(weatherData.dewPoint.value)
                            }
                            HStack {
                                // Text("Sunset:")
                                Spacer()
                                if let sunset = weatherData.sunset {
                                    Text("\(sunset.formatted(date: .omitted, time: .shortened))")
                                } else {
                                    Text("None")
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    if let moonPhase = weatherData.moonPhase {
                        HStack {
                            Image(systemName: moonPhase.symbolName)
                            Text(String(describing: moonPhase))
                        }
                    }

                    Spacer()
                }
            } else {
                Text("No Weather Data Available")
                    .font(.largeTitle)
            }
        }
        .overlay(alignment: .top) {
            if weatherData.wind != nil, #available(iOS 26.0, *) {
                WeatherSummaryView(
                    apparentTemp: formatTemperature(weatherData.apparentTemperature.value, isUSLocale: isUSLocale),
                    actualTemp: formatTemperature(weatherData.temperature.value, isUSLocale: isUSLocale),
                    dewPoint: formatTemperature(weatherData.dewPoint.value, isUSLocale: isUSLocale),
                    humidity: Int(weatherData.humidity * 100),
                    wind: weatherData.wind.map { formatWind($0, isUSLocale: isUSLocale) } ?? "",
                    highTemp: formatTemperature(weatherData.highTemp.value, isUSLocale: isUSLocale),
                    lowTemp: formatTemperature(weatherData.lowTemp.value, isUSLocale: isUSLocale)
                )
                .padding(.horizontal, 24)
                .padding(.top, 12)
            }
        }
        .onAppear {
            fetchWeatherIfLocationAvailable()
        }
        .onChange(of: locationManager.locationStatus) { _ in
            fetchWeatherIfLocationAvailable()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            fetchWeatherIfLocationAvailable()
        }
    }

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
