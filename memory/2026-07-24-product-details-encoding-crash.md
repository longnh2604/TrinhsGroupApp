# Product Details Encoding Crash

- Symptom: Opening Product Details and saving a product (for example, via Favorite) could crash during JSON encoding.
- Root cause: `AnyCodableValue.null` called `container.encode(self)`, recursively encoding itself forever.
- Fix: Encode JSON null values with `container.encodeNil()`.
- Evidence: Products are encoded by `UserDefaultsManager.saveFavorites`; product metadata can contain `.null` when WooCommerce returns nested metadata.
- Status: DONE_WITH_CONCERNS — the local simulator and CocoaPods build environment is unavailable, so the app flow requires device or Xcode verification.
