# Avatar Upload HTTP 400 Investigation

- Symptom: Avatar upload reported an unknown HTTP 400 backend error.
- Root cause: Firebase Storage bucket setup is incomplete. A read-only request to the app-configured bucket returned: "Your bucket has not been set up properly for Firebase Storage."
- Evidence: The WordPress avatar endpoint is registered and accepts POST/DELETE. A non-persisting invalid request authenticated successfully and returned the plugin's expected 422 validation response. The Firebase bucket request returned HTTP 400 before the WordPress path could run.
- Required action: Initialize Firebase Storage and configure its security rules for the `trinhsgroup-befce` Firebase project.
- Status: BLOCKED — requires Firebase Console configuration outside this repository.
