# Trinh App Avatar

This plugin stores avatar images directly in the WordPress Media Library. Firebase Storage and FTP are not required.

## Install

1. Zip the `trinh-app-avatar` folder.
2. In WordPress, open **Plugins → Add New → Upload Plugin** and upload the ZIP.
3. Activate **Trinh App Avatar**.
4. Ensure the WooCommerce REST API key used by the app belongs to an administrator or a user allowed to edit customers, and has **Read/Write** access.

## API

The plugin adds these authenticated endpoints:

- `POST /wp-json/wc/v3/customers/{id}/avatar` as `multipart/form-data`, with a JPEG file named `avatar`
- `DELETE /wp-json/wc/v3/customers/{id}/avatar`

The plugin accepts JPEG images, creates a WordPress Media Library attachment, and replaces WooCommerce's read-only `avatar_url` response value when a custom avatar exists. Replacing or deleting an avatar removes the previous attachment.

## Verification

After installing the updated plugin and rebuilding the iOS app, upload an avatar in the iOS app. Confirm this request returns HTTP 200:

`POST /wp-json/wc/v3/customers/{id}/avatar`

Then request the customer through WooCommerce REST API and confirm `avatar_url` matches the Firebase URL:

`GET /wp-json/wc/v3/customers/{id}`
