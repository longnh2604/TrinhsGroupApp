//
//  KeychainStore.swift
//  TrinhsGroup
//
//  Credential-grade storage for the session JWT.
//

import Foundation
import Security

/// Minimal Keychain wrapper for values that must not sit in UserDefaults.
///
/// UserDefaults is a plaintext plist inside the app container: readable from an
/// unencrypted device backup and from any jailbroken device. Keychain items are encrypted
/// by the Secure Enclave-backed class key and, with `ThisDeviceOnly`, are excluded from
/// backups and never synced to iCloud Keychain.
enum Keychain {

    private static let service = Bundle.main.bundleIdentifier ?? "com.trinhskitchen.app"

    /// `AfterFirstUnlock` rather than `WhenUnlocked`: the value stays readable if the app
    /// is resumed or relaunched while the device is locked. `ThisDeviceOnly` keeps it out
    /// of backups and off iCloud Keychain — correct for a session token, which must not
    /// restore onto a different device.
    private static let accessibility = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

    private static func baseQuery(_ account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }

    static func string(for account: String) -> String? {
        var query = baseQuery(account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8)
        else {
            if status != errSecSuccess && status != errSecItemNotFound {
                print("🔐 Keychain read failed for \(account): OSStatus \(status)")
            }
            return nil
        }
        return value
    }

    @discardableResult
    static func set(_ value: String, for account: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        // Update in place when the item exists, so there is never a moment with no token.
        let updateStatus = SecItemUpdate(
            baseQuery(account) as CFDictionary,
            [
                kSecValueData as String: data,
                kSecAttrAccessible as String: accessibility,
            ] as CFDictionary
        )
        if updateStatus == errSecSuccess { return true }

        guard updateStatus == errSecItemNotFound else {
            print("🔐 Keychain update failed for \(account): OSStatus \(updateStatus)")
            return false
        }

        var insert = baseQuery(account)
        insert[kSecValueData as String] = data
        insert[kSecAttrAccessible as String] = accessibility
        let addStatus = SecItemAdd(insert as CFDictionary, nil)
        if addStatus != errSecSuccess {
            print("🔐 Keychain add failed for \(account): OSStatus \(addStatus)")
        }
        return addStatus == errSecSuccess
    }

    @discardableResult
    static func remove(_ account: String) -> Bool {
        let status = SecItemDelete(baseQuery(account) as CFDictionary)
        // Nothing stored is the same outcome as deleting it.
        return status == errSecSuccess || status == errSecItemNotFound
    }
}

/// The signed-in user's JWT, shared between `AuthViewModel` (which writes it) and the
/// networking layer (which reads it on every user-scoped request).
///
/// This token authorises everything under `/wp-json/trinh-app/v1/*` — the customer record,
/// order history, order creation, vouchers and points — so it is a bearer credential
/// equivalent to the account password and belongs in the Keychain.
enum AuthTokenStore {

    private static let account = "authJWTToken"

    /// Builds before the Keychain migration persisted the JWT in UserDefaults under this
    /// key. Carried over once so existing installs are not logged out, then deleted.
    private static let legacyDefaultsKey = "authJWTToken"

    #if DEBUG
    /// Keychain returns `errSecMissingEntitlement` (-34018) to builds signed without a
    /// provisioning profile — i.e. "Sign to Run Locally" simulator builds, which have no
    /// `application-identifier` and therefore no default keychain access group.
    ///
    /// Without a fallback that turns into an infinite login loop: the write fails, the next
    /// read is nil, and the networking layer posts `.sessionExpired`. This keeps such
    /// builds usable. It is compiled out of Release entirely — production is Keychain-only.
    private static let debugFallbackKey = "authJWTToken.debugFallbackOnly"
    #endif

    // MARK: Primitives (must not touch `migration` — it calls them)

    private static func readStored() -> String? {
        if let value = Keychain.string(for: account), !value.isBlank { return value }
        #if DEBUG
        if let value = UserDefaults.standard.string(forKey: debugFallbackKey), !value.isBlank {
            return value
        }
        #endif
        return nil
    }

    @discardableResult
    private static func writeStored(_ token: String) -> Bool {
        if Keychain.set(token, for: account) {
            #if DEBUG
            UserDefaults.standard.removeObject(forKey: debugFallbackKey)
            #endif
            return true
        }
        #if DEBUG
        print("""
        🔐 ⚠️ DEBUG ONLY: Keychain unavailable, storing the session token in UserDefaults.
           This happens in builds signed "to run locally" (no provisioning profile).
           Release builds have no such fallback — verify Keychain on a provisioned build.
        """)
        UserDefaults.standard.set(token, forKey: debugFallbackKey)
        return true
        #else
        print("🔐 Keychain write failed — the session will not persist across launches.")
        return false
        #endif
    }

    /// Swift guarantees lazy `static let` initialisation runs exactly once, thread-safely.
    private static let migration: Void = {
        let defaults = UserDefaults.standard
        guard let legacy = defaults.string(forKey: legacyDefaultsKey), !legacy.isBlank else { return }

        writeStored(legacy)
        // Only drop the plaintext copy once the value is confirmed readable from its new
        // home — otherwise the user would be silently signed out.
        if readStored() != nil {
            defaults.removeObject(forKey: legacyDefaultsKey)
            print("🔐 Migrated session token out of plaintext UserDefaults")
        } else {
            print("🔐 ⚠️ Token migration failed; leaving the legacy value in place")
        }
    }()

    // MARK: API

    static var token: String? {
        _ = migration
        return readStored()
    }

    static func save(_ token: String) {
        _ = migration
        writeStored(token)
    }

    static func clear() {
        _ = migration
        Keychain.remove(account)
        // Make sure no pre-migration or fallback copy survives a logout.
        UserDefaults.standard.removeObject(forKey: legacyDefaultsKey)
        #if DEBUG
        UserDefaults.standard.removeObject(forKey: debugFallbackKey)
        #endif
    }
}

private extension String {
    var isBlank: Bool { trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}
