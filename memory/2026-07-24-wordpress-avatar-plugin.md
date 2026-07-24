# WordPress Avatar Plugin Integration

- Symptom: Avatar uploads were Firebase-only and did not update the WordPress/WooCommerce customer response.
- Root cause: WooCommerce marks `avatar_url` as read-only; no custom WordPress endpoint or user-meta integration existed.
- Fix: Added the `trinh-app-avatar` plugin, with authenticated POST and DELETE endpoints under `wc/v3`, and a WooCommerce response filter that returns the stored Firebase URL as `avatar_url`. The iOS app now calls those endpoints after uploading to Firebase Storage and before deleting the Firebase file.
- Evidence: PHP lint and ZIP archive validation both pass. The archive contains the WordPress-ready `trinh-app-avatar/` root folder.
- Status: DONE_WITH_CONCERNS — requires installation on the WordPress site and an authenticated device test with the app's WooCommerce REST API key.
