## Learned User Preferences

- When matching external reference designs, keep the app’s minimal glass aesthetic and avoid extra chrome.
- Weather alert presentation: use advisory (blue), watch (orange), and warning (red) accents; use outline SF Symbols only (`info.circle`, `exclamationmark.triangle`, `exclamationmark.octagon`) for those states.
- Prefer the main weather-alerts control as rounded-rectangle glass (continuous corner radius ~14), consistent with other stat-style cards, rather than a capsule.
- Prefer tighter insets and leading-aligned text for dense alert and forecast content.

## Learned Workspace Facts

- Just Weather is a SwiftUI iOS app that uses WeatherKit; screen composition is centered in `Just Weather/Just_WeatherView.swift`, shared formatters in `Just Weather/WeatherFormatting.swift`, and fetch/state in `Just Weather/Models/WeatherData.swift` (current, daily, hourly, and alerts).
- On newer iOS versions the primary layout relies on `glassEffect`-based controls; older OS versions still use a legacy path that includes the standalone condition card.
