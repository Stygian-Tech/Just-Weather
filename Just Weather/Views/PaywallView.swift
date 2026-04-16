//
//  PaywallView.swift
//  Just Weather
//
//  Shown when the user's free trial has lapsed and they have no active entitlement.
//  Non-dismissible — requires a purchase or restore to proceed.
//
//  Pricing is hardcoded as placeholder until RevenueCat is wired in.
//  TODO: Replace purchase button actions with real RevenueCat package purchases.
//

import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @State private var isPurchasing = false
    @State private var errorMessage: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Header
            VStack(spacing: 10) {
                Image(systemName: "cloud.sun.fill")
                    .font(.system(size: 64))
                    .symbolRenderingMode(.multicolor)
                    .accessibilityHidden(true)
                Text("Just Weather")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Know exactly how it feels outside.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Purchase options
            VStack(spacing: 12) {
                PurchaseOptionButton(
                    title: "Annual",
                    subtitle: "1 month free, then $8 / year",
                    price: "$8 / yr",
                    isBadged: true,
                    isPurchasing: isPurchasing
                ) {
                    await buy { try await purchaseManager.purchaseAnnual() }
                }

                PurchaseOptionButton(
                    title: "Lifetime",
                    subtitle: "One-time purchase, no subscription",
                    price: "$15",
                    isBadged: false,
                    isPurchasing: isPurchasing
                ) {
                    await buy { try await purchaseManager.purchaseLifetime() }
                }
            }
            .padding(.horizontal, 24)

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .padding(.horizontal, 24)
            }

            Spacer()

            // Footer
            VStack(spacing: 12) {
                Button("Restore Purchases") {
                    Task { try? await purchaseManager.restore() }
                }
                .font(.subheadline)

                Text("Subscription auto-renews annually. Cancel anytime in Settings.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.bottom, 32)
        }
        .accessibilityElement(children: .contain)
    }

    private func buy(_ action: () async throws -> Void) async {
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }
        do {
            try await action()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Purchase option button

private struct PurchaseOptionButton: View {
    let title: String
    let subtitle: String
    let price: String
    let isBadged: Bool
    let isPurchasing: Bool
    let action: () async -> Void

    var body: some View {
        Button { Task { await action() } } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.headline)
                        if isBadged {
                            Text("FREE TRIAL")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.blue.opacity(0.15), in: Capsule())
                                .foregroundStyle(.blue)
                        }
                    }
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isPurchasing {
                    ProgressView()
                } else {
                    Text(price)
                        .font(.headline)
                }
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(isPurchasing)
        .accessibilityLabel("\(title), \(subtitle), \(price)")
    }
}
