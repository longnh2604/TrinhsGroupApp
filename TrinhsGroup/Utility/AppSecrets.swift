//
//  AppSecrets.swift
//  TrinhsGroup
//
//  Reads build-time credentials out of Secrets.plist (untracked — see
//  Secrets.example.plist for the template).
//

import Foundation

/// Credentials loaded from the bundled, untracked `Secrets.plist`.
///
/// Only the **read-only** WooCommerce key belongs here. Anything embedded in the app is
/// extractable from the IPA, so this key is used solely for public catalog reads
/// (products, categories). Customer, order, voucher and payment data go through
/// `/wp-json/trinh-app/v1/*` authenticated with the signed-in user's JWT — see
/// `WooCommerceAPI.requestAuthenticated`.
enum AppSecrets {

    private static let values: [String: String] = {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(
                  from: data, options: [], format: nil
              ) as? [String: String]
        else {
            assertionFailure("""
            Secrets.plist is missing or malformed.
            Run: cp TrinhsGroup/Secrets.example.plist TrinhsGroup/Secrets.plist
            then fill in a read-only WooCommerce REST key.
            """)
            return [:]
        }
        return plist
    }()

    private static func value(for key: String) -> String {
        guard let value = values[key], !value.isEmpty, !value.hasSuffix("_KEY"), !value.hasSuffix("_SECRET") else {
            assertionFailure("Secrets.plist is missing a real value for \(key).")
            return ""
        }
        return value
    }

    /// Read-only WooCommerce consumer key — public catalog reads only.
    static var wooConsumerKey: String { value(for: "WOO_CONSUMER_KEY") }

    /// Read-only WooCommerce consumer secret — public catalog reads only.
    static var wooConsumerSecret: String { value(for: "WOO_CONSUMER_SECRET") }
}

// The session JWT lives in `AuthTokenStore` (Utility/KeychainStore.swift) — Keychain, not
// UserDefaults. Build-time secrets belong here; runtime credentials do not.
