//
//  WeatherData.swift
//  Just Weather
//
//  Created by Sam Clemente on 8/21/24.
//

import WeatherKit
import CoreLocation

@MainActor
class WeatherData: ObservableObject {
    @Published var current: CurrentWeather? = nil
    @Published var today: DayWeather? = nil
    @Published var hourly: Forecast<HourWeather>? = nil
    @Published var alerts: [WeatherAlert]? = nil

    /// Up to five clock hours at or after now (falls back to the first five forecast slots if needed).
    var nextFiveHours: [HourWeather] {
        guard let hourly else { return [] }
        let now = Date()
        let upcoming = hourly.forecast.filter { $0.date >= now }.sorted { $0.date < $1.date }
        if upcoming.count >= 5 {
            return Array(upcoming.prefix(5))
        }
        if !upcoming.isEmpty {
            return upcoming
        }
        return Array(hourly.forecast.prefix(5))
    }

    func fetchWeather(for location: CLLocation) async {
        do {
            let (current, daily, hourly, alerts) = try await WeatherService.shared.weather(
                for: location,
                including: .current, .daily, .hourly, .alerts
            )
            self.current = current
            self.today = daily.first
            self.hourly = hourly
            self.alerts = alerts
        } catch {
            print("Error fetching weather: \(error.localizedDescription)")
        }
    }
}
