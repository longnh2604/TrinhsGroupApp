# Direct WordPress Avatar Upload

- Symptom: Firebase Storage avatar uploads failed because the configured bucket is not initialized and Firebase Storage requires additional billing/setup.
- Root cause: The prior avatar implementation depended on Firebase Storage before calling WordPress.
- Fix: Reworked the avatar flow to upload a JPEG directly from iOS to the authenticated WordPress endpoint. The plugin stores the image as a WordPress Media Library attachment, keeps its URL in customer user metadata, exposes it as WooCommerce `avatar_url`, and deletes the old attachment when replacing or deleting an avatar.
- Evidence: PHP lint, diff whitespace validation, and WordPress ZIP archive validation pass.
- Status: DONE_WITH_CONCERNS — the updated plugin must replace the previous installed version and the updated iOS app must be rebuilt before a device upload can be verified.
