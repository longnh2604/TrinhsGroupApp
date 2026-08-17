//
//  APIClient.swift
//  TrinhsGroup
//
//  Created by long on 04/07/2022.
//

import Foundation

/// URL cache management.
///
/// This type used to hold a second, parallel WooCommerce client that authenticated by
/// putting `consumer_key`/`consumer_secret` in the query string. Those calls were
/// superseded by `WooCommerceAPI` and had been dead for some time — `Config.swift` had
/// already blanked the key constants, so every one of them would have returned 401.
/// `clearCache()` was the only member ever called, so it is all that remains.
///
/// The old `static let shared` also configured `URLCache.shared` in its initialiser, but
/// nothing ever accessed `shared`; being lazy, that configuration never ran. Dropping it
/// changes no behaviour.
enum APIClient {

    /// Discard all cached URL responses so the next request goes to the network.
    static func clearCache() {
        URLCache.shared.removeAllCachedResponses()
        print("🗑️ URL Cache cleared")
    }
}
