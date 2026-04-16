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
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
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

    // MARK: - Summary style

    private var summaryStyleSection: some View {
        Section {
            ForEach(SummaryStyle.allCases) { style in
                Button {
                    summaryStyle = style
                } label: {
                    HStack {
                        Label(style.label, systemImage: style.icon)
                            .foregroundStyle(.primary)
                        Spacer()
                        if summaryStyle == style {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        } header: {
            Text("Summary Style")
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
