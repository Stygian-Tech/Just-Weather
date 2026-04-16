//
//  PurchaseManager.swift
//  Just Weather
//
//  Stub purchase manager — all RevenueCat wiring is marked TODO.
//  The app runs fully during development; when you're ready to go live:
//    1. Add RevenueCat SPM: https://github.com/RevenueCat/purchases-ios-spm (product: RevenueCat)
//    2. Replace the stub body with the commented-out RevenueCat implementation below.
//    3. Set your API key and entitlement ID.
//

import SwiftUI

@MainActor
final class PurchaseManager: ObservableObject {

    static let entitlementID = "premium"

    /// Set to `false` to test the paywall UI during development.
    @Published var isEntitled = true
    @Published var isLoading = false

    /// Human-readable subscription status shown in Settings.
    @Published var statusLabel = "Free Trial"
    @Published var statusDetail: String? = "Ends in 30 days"

    func refresh() async {
        // TODO: Replace with RevenueCat customer info fetch
        // isLoading = true
        // defer { isLoading = false }
        // if let info = try? await Purchases.shared.customerInfo() {
        //     isEntitled = info.entitlements[Self.entitlementID]?.isActive == true
        //     apply(info)
        // }
    }

    func purchaseAnnual() async throws {
        // TODO: Replace with RevenueCat package purchase
        // let offerings = try await Purchases.shared.offerings()
        // guard let package = offerings.current?.annual else { return }
        // let result = try await Purchases.shared.purchase(package: package)
        // isEntitled = result.customerInfo.entitlements[Self.entitlementID]?.isActive == true
        isEntitled = true
    }

    func purchaseLifetime() async throws {
        // TODO: Replace with RevenueCat package purchase
        // let offerings = try await Purchases.shared.offerings()
        // guard let package = offerings.current?.lifetime else { return }
        // let result = try await Purchases.shared.purchase(package: package)
        // isEntitled = result.customerInfo.entitlements[Self.entitlementID]?.isActive == true
        isEntitled = true
    }

    func restore() async throws {
        // TODO: Replace with Purchases.shared.restorePurchases()
        // let info = try await Purchases.shared.restorePurchases()
        // isEntitled = info.entitlements[Self.entitlementID]?.isActive == true
    }
}
