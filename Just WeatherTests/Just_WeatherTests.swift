//
//  Just_WeatherTests.swift
//  Just WeatherTests
//

import Testing
import CoreLocation
@testable import Just_Weather

// MARK: - celsiusToFahrenheit

@Suite("celsiusToFahrenheit")
struct CelsiusToFahrenheitTests {
    @Test func freezingPoint() {
        #expect(celsiusToFahrenheit(0) == 32)
    }

    @Test func boilingPoint() {
        #expect(celsiusToFahrenheit(100) == 212)
    }

    @Test func bodyTemperature() {
        #expect(celsiusToFahrenheit(37) == 98.6)
    }

    @Test func negative() {
        #expect(celsiusToFahrenheit(-40) == -40)
    }
}

// MARK: - kilometersPerHourToMilesPerHour

@Suite("kilometersPerHourToMilesPerHour")
struct KmhToMphTests {
    @Test func zero() {
        #expect(kilometersPerHourToMilesPerHour(0) == 0)
    }

    @Test func oneHundredKmh() {
        // 100 km/h ≈ 62.1371 mph
        #expect(abs(kilometersPerHourToMilesPerHour(100) - 62.1371) < 0.0001)
    }

    @Test func roundTrip() {
        let mph = kilometersPerHourToMilesPerHour(80)
        #expect(abs(mph - 49.70968) < 0.0001)
    }
}

// MARK: - formatTemperature

@Suite("formatTemperature")
struct FormatTemperatureTests {
    // MARK: US locale (Fahrenheit)

    @Test func us_freezingPoint() {
        #expect(formatTemperature(0, isUSLocale: true) == "32º")
    }

    @Test func us_roundsToNearestDegree() {
        // 20°C = 68°F
        #expect(formatTemperature(20, isUSLocale: true) == "68º")
    }

    @Test func us_negativeValue() {
        // -10°C = 14°F
        #expect(formatTemperature(-10, isUSLocale: true) == "14º")
    }

    // MARK: Metric locale (Celsius)

    @Test func metric_wholeNumber() {
        #expect(formatTemperature(22, isUSLocale: false) == "22º")
    }

    @Test func metric_halfDegreeInSingleDigitRange() {
        // 9.5°C — in range (-10, 10) and fractional → "9.5º"
        #expect(formatTemperature(9.5, isUSLocale: false) == "9.5º")
    }

    @Test func metric_halfDegreeOutsideSingleDigitRange() {
        // 10.5°C — outside (-10, 10) → rounds to "10º" or "11º"
        // (10.5 * 2).rounded() / 2 = 21/2 = 10.5; still > 10 boundary → "10º" or "11º"?
        // 10.5 rounds to 10.5, which is not < 10, so integer branch: Int(10.5.rounded()) = 11
        #expect(formatTemperature(10.5, isUSLocale: false) == "11º")
    }

    @Test func metric_negativeHalfInSingleDigitRange() {
        // -9.5°C — in (-10, 10) and fractional → "-9.5º"
        #expect(formatTemperature(-9.5, isUSLocale: false) == "-9.5º")
    }

    @Test func metric_exactlyAtBoundary_10() {
        // 10.0°C — NOT less than 10, so integer branch
        #expect(formatTemperature(10, isUSLocale: false) == "10º")
    }

    @Test func metric_exactlyAtBoundary_neg10() {
        // -10.0°C — NOT greater than -10, so integer branch
        #expect(formatTemperature(-10, isUSLocale: false) == "-10º")
    }

    @Test func metric_zeroIsWholeNumber() {
        // 0°C — in range but equals floor(0) → integer branch
        #expect(formatTemperature(0, isUSLocale: false) == "0º")
    }

    @Test func metric_largePosValue() {
        #expect(formatTemperature(35, isUSLocale: false) == "35º")
    }

    @Test func metric_largeNegValue() {
        #expect(formatTemperature(-20, isUSLocale: false) == "-20º")
    }
}

// MARK: - cardinalDirection

@Suite("cardinalDirection")
struct CardinalDirectionTests {
    @Test func north_exactlyZero() {
        #expect(cardinalDirection(from: 0) == "N")
    }

    @Test func north_exactly360() {
        #expect(cardinalDirection(from: 360) == "N")
    }

    @Test func northNorthEast() {
        #expect(cardinalDirection(from: 22.5) == "NNE")
    }

    @Test func east() {
        #expect(cardinalDirection(from: 90) == "E")
    }

    @Test func south() {
        #expect(cardinalDirection(from: 180) == "S")
    }

    @Test func west() {
        #expect(cardinalDirection(from: 270) == "W")
    }

    @Test func northwest() {
        #expect(cardinalDirection(from: 315) == "NW")
    }

    @Test func northeast() {
        #expect(cardinalDirection(from: 45) == "NE")
    }

    @Test func southeast() {
        #expect(cardinalDirection(from: 135) == "SE")
    }

    @Test func southwest() {
        #expect(cardinalDirection(from: 225) == "SW")
    }

    @Test func justBelowNNE_boundary() {
        // < 11.25 degrees from North → N
        #expect(cardinalDirection(from: 11) == "N")
    }

    @Test func justAboveNNE_boundary() {
        // >= 11.25 → NNE
        #expect(cardinalDirection(from: 12) == "NNE")
    }
}

// MARK: - formatWindSpeed

@Suite("formatWindSpeed")
struct FormatWindSpeedTests {
    @Test func us_roundsSpeed() {
        // 48.28 km/h ≈ 30 mph
        let result = formatWindSpeed(speedKmh: 48.28, directionDegrees: 0, isUSLocale: true)
        #expect(result == "30 mph N")
    }

    @Test func us_includesCardinalDirection() {
        let result = formatWindSpeed(speedKmh: 16.09, directionDegrees: 90, isUSLocale: true)
        #expect(result == "10 mph E")
    }

    @Test func metric_showsKmh() {
        let result = formatWindSpeed(speedKmh: 30, directionDegrees: 180, isUSLocale: false)
        #expect(result == "30 km/h S")
    }

    @Test func metric_roundsSpeed() {
        let result = formatWindSpeed(speedKmh: 25.6, directionDegrees: 270, isUSLocale: false)
        #expect(result == "26 km/h W")
    }

    @Test func zeroWind() {
        let result = formatWindSpeed(speedKmh: 0, directionDegrees: 0, isUSLocale: false)
        #expect(result == "0 km/h N")
    }
}

// MARK: - trimToTwoSentences

@Suite("trimToTwoSentences")
struct TrimToTwoSentencesTests {
    @Test func emptyString_returnsEmpty() {
        #expect(trimToTwoSentences("") == "")
    }

    @Test func noPeriod_addsTrailingPeriod() {
        // No period → split produces one part with no separator → joined is the word → gets a "."
        let result = trimToTwoSentences("It feels warm outside")
        #expect(result == "It feels warm outside.")
    }

    @Test func oneSentence_preservesIt() {
        let result = trimToTwoSentences("It feels warm outside.")
        #expect(result == "It feels warm outside.")
    }

    @Test func twoSentences_keepsBoths() {
        let result = trimToTwoSentences("It feels warm. A light breeze helps.")
        #expect(result == "It feels warm. A light breeze helps.")
    }

    @Test func threeSentences_tripsAtTwo() {
        let result = trimToTwoSentences("It feels warm. A breeze helps. Enjoy it.")
        #expect(result == "It feels warm. A breeze helps.")
    }

    @Test func secondSentenceMissingPeriod_addsOne() {
        // After trim, second sentence has no trailing period
        let result = trimToTwoSentences("It feels warm. A breeze helps")
        #expect(result == "It feels warm. A breeze helps.")
    }

    @Test func leadingAndTrailingWhitespace_isTrimmed() {
        let result = trimToTwoSentences("  It feels warm.  A breeze helps.  And more. ")
        #expect(result == "It feels warm.  A breeze helps.")
    }

    @Test func onlyPeriod_returnsOriginal() {
        // split with omittingEmptySubsequences:true removes empty parts → trimmed is empty → returns original
        let result = trimToTwoSentences(".")
        #expect(result == ".")
    }
}

// MARK: - weather summary context + task prompt

@Suite("weatherSummaryTaskPrompt")
struct WeatherSummaryTaskPromptTests {
    @Test func embedsDataContextAndTask() {
        let ctx = "NOW: condition clear\nALERTS: none"
        let prompt = weatherSummaryTaskPrompt(dataContext: ctx)
        #expect(prompt.contains("NOW: condition clear"))
        #expect(prompt.contains("ALERTS: none"))
        #expect(prompt.contains("two short sentences"))
    }
}

@available(iOS 18, *)
@Suite("weatherSummaryDataContext")
struct WeatherSummaryDataContextTests {
    @Test func omitsTodayWhenNil() {
        let ctx = weatherSummaryDataContext(
            current: nil,
            today: nil,
            nextHours: [],
            alerts: nil,
            isUSLocale: true
        )
        #expect(ctx.contains("current weather unavailable"))
        #expect(ctx.contains("daily forecast unavailable"))
        #expect(ctx.contains("ALERTS: none"))
    }
}

// MARK: - LocationManager

@Suite("LocationManager")
struct LocationManagerTests {
    @Test @MainActor func initialState_hasNilLocation() {
        let manager = LocationManager()
        #expect(manager.lastLocation == nil)
    }

    @Test @MainActor func initialState_hasNilStatus() {
        let manager = LocationManager()
        // Status may be set by CLLocationManager init, but we can at least verify the property exists
        // and is not crashing on access.
        _ = manager.locationStatus
    }

    @Test @MainActor func didUpdateLocations_setsLastLocation() {
        let manager = LocationManager()
        let expected = CLLocation(latitude: 51.5074, longitude: -0.1278)
        manager.locationManager(CLLocationManager(), didUpdateLocations: [expected])
        #expect(manager.lastLocation?.coordinate.latitude == expected.coordinate.latitude)
        #expect(manager.lastLocation?.coordinate.longitude == expected.coordinate.longitude)
    }

    @Test @MainActor func didUpdateLocations_usesLastInArray() {
        let manager = LocationManager()
        let first = CLLocation(latitude: 40.7128, longitude: -74.0060)
        let last = CLLocation(latitude: 51.5074, longitude: -0.1278)
        manager.locationManager(CLLocationManager(), didUpdateLocations: [first, last])
        #expect(manager.lastLocation?.coordinate.latitude == last.coordinate.latitude)
    }

    @Test @MainActor func didUpdateLocations_emptyArray_doesNotUpdateLocation() {
        let manager = LocationManager()
        manager.locationManager(CLLocationManager(), didUpdateLocations: [])
        #expect(manager.lastLocation == nil)
    }

    @Test @MainActor func didChangeAuthorization_denied_setsStatus() {
        let manager = LocationManager()
        manager.locationManager(CLLocationManager(), didChangeAuthorization: .denied)
        #expect(manager.locationStatus == .denied)
    }

    @Test @MainActor func didChangeAuthorization_restricted_setsStatus() {
        let manager = LocationManager()
        manager.locationManager(CLLocationManager(), didChangeAuthorization: .restricted)
        #expect(manager.locationStatus == .restricted)
    }

    @Test @MainActor func didChangeAuthorization_notDetermined_setsStatus() {
        let manager = LocationManager()
        manager.locationManager(CLLocationManager(), didChangeAuthorization: .notDetermined)
        #expect(manager.locationStatus == .notDetermined)
    }

    @Test @MainActor func didChangeAuthorization_authorizedWhenInUse_setsStatus() {
        let manager = LocationManager()
        manager.locationManager(CLLocationManager(), didChangeAuthorization: .authorizedWhenInUse)
        #expect(manager.locationStatus == .authorizedWhenInUse)
    }
}

// MARK: - WeatherData

@Suite("WeatherData")
struct WeatherDataTests {
    @Test @MainActor func initialHumidity_isZero() {
        let data = WeatherData()
        #expect(data.humidity == 0.0)
    }

    @Test @MainActor func initialWind_isNil() {
        let data = WeatherData()
        #expect(data.wind == nil)
    }

    @Test @MainActor func initialSunrise_isNil() {
        let data = WeatherData()
        #expect(data.sunrise == nil)
    }

    @Test @MainActor func initialSunset_isNil() {
        let data = WeatherData()
        #expect(data.sunset == nil)
    }

    @Test @MainActor func initialMoonPhase_isNil() {
        let data = WeatherData()
        #expect(data.moonPhase == nil)
    }

    @Test @MainActor func initialConditionSymbol_isNotEmpty() {
        let data = WeatherData()
        #expect(!data.conditionSymbol.isEmpty)
    }
}
