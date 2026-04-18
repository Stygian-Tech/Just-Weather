//
//  Just_WeatherApp.swift
//  Just Weather
//
//  Created by Sam Clemente on 8/21/24.
//

import SwiftUI
import WeatherKit
import CoreLocation

@main
struct Just_WeatherApp: App {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var purchaseManager = PurchaseManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(locationManager)
                .environmentObject(purchaseManager)
        }
    }
}

private struct RootView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var purchaseManager: PurchaseManager
    @StateObject private var weatherData = WeatherData()
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                Text("Fetching Weather Data...")
                    .font(.largeTitle)
                    .accessibilityLabel("Loading weather data")
            } else if weatherData.current != nil {
                Just_WeatherView()
                    .environmentObject(weatherData)
                    .environmentObject(locationManager)
            } else {
                Text("No Weather Data Available")
                    .font(.largeTitle)
            }
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
            locationManager.startUpdatingLocation()
            fetchWeatherIfLocationAvailable()
        }
        .onDisappear {
            locationManager.stopUpdatingLocation()
        }
        .onChange(of: locationManager.locationStatus) { _ in
            fetchWeatherIfLocationAvailable()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            fetchWeatherIfLocationAvailable()
            Task { await purchaseManager.refresh() }
        }
    }

    private func fetchWeatherIfLocationAvailable() {
        Task {
            if let lastLocation = locationManager.lastLocation {
                await weatherData.fetchWeather(for: lastLocation)
            } else {
                print("No Location Found")
            }
            isLoading = false
        }
    }
}
