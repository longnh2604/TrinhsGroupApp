# Profile Update Investigation

- Symptom: User profile changes were not saved.
- Root cause: `AuthServices.updateUser` delegated to `APIClient.onUpdateUser`, whose entire request implementation is commented out. The app therefore never made a profile-update request. The Edit Profile screen also hid its update button.
- Fix: Send the documented WooCommerce `PUT /wp-json/wc/v3/customers/{id}` request through `WooCommerceAPI`, including customer, billing, and shipping fields; include a password only when supplied; restore the update button.
- Avatar finding: WooCommerce documents `avatar_url` as read-only. The Firebase Storage upload is valid for an app-managed avatar, but it cannot update the WordPress/WooCommerce avatar without a custom authenticated WordPress endpoint or a WordPress avatar provider such as Gravatar.
- Evidence: Official WooCommerce customer REST API documentation lists `avatar_url` as read-only and specifies the customer PUT endpoint.
- Status: DONE_WITH_CONCERNS — source-level validation passes; an authenticated production update was not issued during investigation.
