//
//  SettingsView.swift
//  Just Weather
//
//  Opened by the gear icon on the main view.
//  Contains the summary style picker and subscription management.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @AppStorage("summaryStyle") private var summaryStyle: SummaryStyle = .basic
    @AppStorage("appFontStyle") private var appFontStyle: AppFontStyle = .regular
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                appFontStyleSection
                summaryStyleSection
                subscriptionSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Font style

    private var appFontStyleSection: some View {
        Section {
            Picker("Font", selection: $appFontStyle) {
                ForEach(AppFontStyle.allCases) { style in
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(style.label)
                            Text(style.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: style.icon)
                    }
                    .labelStyle(SettingsPickerLabelStyle())
                    .tag(style)
                }
            }
            .pickerStyle(.menu)
        } footer: {
            Text("Applies to the main weather screen. Regular keeps the large temperature in SF Pro Display.")
        }
    }

    // MARK: - Summary style

    private var summaryStyleSection: some View {
        Section {
            Picker("Summary Style", selection: $summaryStyle) {
                ForEach(SummaryStyle.allCases) { style in
                    Label(style.label, systemImage: style.icon)
                        .labelStyle(SettingsPickerLabelStyle())
                        .tag(style)
                }
            }
            .pickerStyle(.menu)
        } footer: {
            Text(styleFooter)
        }
    }

    private var styleFooter: String {
        switch summaryStyle {
        case .basic:     return "Plain, factual description of how the air feels."
        case .technical: return "Atmospheric analysis using meteorological terminology."
        case .poetic:    return "Creative, evocative take on the current conditions."
        case .grumpy:    return "Complaints about the weather. Specifically."
        case .none:      return "No summary shown."
        }
    }

    // MARK: - Subscription

    private var subscriptionSection: some View {
        Section {
            HStack {
                Text("Status")
                Spacer()
                if purchaseManager.isLoading {
                    ProgressView()
                } else {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(purchaseManager.statusLabel)
                            .foregroundStyle(.secondary)
                        if let detail = purchaseManager.statusDetail {
                            Text(detail)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }

            if purchaseManager.isEntitled {
                Link(
                    "Manage Subscription",
                    destination: URL(string: "https://apps.apple.com/account/subscriptions")!
                )
            }

            Button("Restore Purchases") {
                Task { try? await purchaseManager.restore() }
            }
        } header: {
            Text("Subscription")
        }
    }
}

// MARK: - Picker label layout

/// Wider gap between SF Symbol and text than default `Label` (menu row + trailing selection).
private struct SettingsPickerLabelStyle: LabelStyle {
    /// Default `Label` spacing is tight; menu pickers read better with explicit separation.
    var iconTitleSpacing: CGFloat = 14

    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .center, spacing: iconTitleSpacing) {
            configuration.icon
            configuration.title
        }
    }
}
