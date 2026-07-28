#!/usr/bin/env bash
#
# verify-release-build.sh — pre-upload check on a built archive or IPA.
#
# Why this exists instead of an edit to TrinhsGroup.entitlements:
#
# The entitlements file in the repo says `aps-environment = development`. With automatic
# signing, Xcode is documented to replace that value at signing time from the provisioning
# profile, so an App Store archive gets `production` and everything works. That is probably
# what happens here — but "probably" is a bad basis for shipping push notifications, because
# a wrong value fails *silently*: the device registers with sandbox APNs, FCM sends to the
# production gateway, and no customer ever sees an order-status notification. There is no
# error anywhere.
#
# Hardcoding `production` in the entitlements file instead would just move the risk onto
# Debug builds, and neither variant can be tested without a provisioning profile for the
# app's team. So: leave the signing configuration alone, and verify the artifact you are
# about to upload.
#
# ─── Usage ──────────────────────────────────────────────────────────────────────
#   ./scripts/verify-release-build.sh <path to .xcarchive | .ipa | .app>
#   ./scripts/verify-release-build.sh          # newest .xcarchive in ~/Library/Developer/Xcode/Archives
#
# Exit 0 = safe to upload. Exit 1 = a check failed. Exit 2 = usage/setup problem.

set -uo pipefail

EXPECTED_TEAM="${EXPECTED_TEAM:-8YLSK83HY4}"
EXPECTED_BUNDLE_ID="${EXPECTED_BUNDLE_ID:-com.trinhskitchen.app}"

BOLD=$'\033[1m'; RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; DIM=$'\033[2m'; OFF=$'\033[0m'
PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); printf '  %s✓%s %s\n' "$GREEN" "$OFF" "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  %s✗%s %s\n' "$RED" "$OFF" "$1"; [[ $# -gt 1 ]] && printf '      %s%s%s\n' "$DIM" "$2" "$OFF"; return 0; }
warn() { printf '  %s!%s %s\n' "$YELLOW" "$OFF" "$1"; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# ── Resolve the .app bundle to inspect ──────────────────────────────────────────
TARGET="${1:-}"
if [[ -z "$TARGET" ]]; then
    TARGET="$(find "$HOME/Library/Developer/Xcode/Archives" -name '*.xcarchive' -maxdepth 2 2>/dev/null \
              | xargs -I{} stat -f '%m %N' {} 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)"
    [[ -n "$TARGET" ]] || { echo "No .xcarchive found — pass a path explicitly." >&2; exit 2; }
    printf '%susing newest archive:%s %s\n' "$DIM" "$OFF" "$TARGET"
fi
[[ -e "$TARGET" ]] || { echo "Not found: $TARGET" >&2; exit 2; }

case "$TARGET" in
    *.xcarchive) APP="$(find "$TARGET/Products/Applications" -maxdepth 1 -name '*.app' | head -1)" ;;
    *.ipa)       unzip -qq "$TARGET" -d "$TMP/ipa" || exit 2
                 APP="$(find "$TMP/ipa/Payload" -maxdepth 1 -name '*.app' | head -1)" ;;
    *.app)       APP="$TARGET" ;;
    *)           echo "Expected .xcarchive, .ipa or .app — got: $TARGET" >&2; exit 2 ;;
esac
[[ -n "${APP:-}" && -d "$APP" ]] || { echo "Could not locate an .app inside $TARGET" >&2; exit 2; }

printf '\n%sInspecting%s %s\n' "$BOLD" "$OFF" "$APP"

# ── Entitlements ────────────────────────────────────────────────────────────────
ENT="$TMP/ent.plist"
if ! codesign -d --entitlements :- --xml "$APP" >"$ENT" 2>/dev/null || [[ ! -s "$ENT" ]]; then
    # Older codesign spellings, plus the unsigned case.
    codesign -d --entitlements :- "$APP" >"$ENT" 2>/dev/null || true
fi

ent() { plutil -extract "$1" raw "$ENT" 2>/dev/null; }

printf '\n%s1. Push notification environment%s\n' "$BOLD" "$OFF"
APS="$(ent 'aps-environment')"
case "$APS" in
    production)
        ok "aps-environment = production" ;;
    development)
        bad "aps-environment = development" \
            "This build registers with the APNs sandbox. Order-status pushes will never reach customers. Re-export with an App Store / Ad Hoc distribution profile." ;;
    "")
        if [[ -s "$ENT" ]] && plutil -p "$ENT" >/dev/null 2>&1; then
            bad "aps-environment is absent" "Push Notifications capability is missing from the signed entitlements — FCM cannot obtain an APNs token."
        else
            bad "no entitlements found" "The bundle looks unsigned (a simulator or CODE_SIGNING_ALLOWED=NO build). Inspect a real archive or IPA instead."
        fi ;;
    *)
        bad "aps-environment = $APS (unexpected)" ;;
esac

printf '\n%s2. Build is a distribution build%s\n' "$BOLD" "$OFF"
GTA="$(ent 'get-task-allow')"
case "$GTA" in
    false) ok "get-task-allow = false (distribution)" ;;
    true)  bad "get-task-allow = true" "This is a development build; the App Store rejects it and pushes use sandbox APNs." ;;
    "")    warn "get-task-allow absent — treat as inconclusive, check the export method" ;;
esac

printf '\n%s3. Identity%s\n' "$BOLD" "$OFF"
APPID="$(ent 'application-identifier')"
if [[ -z "$APPID" ]]; then
    bad "application-identifier missing" "Without it the app has no default Keychain access group, so the session token cannot be stored (AuthTokenStore)."
else
    if [[ "$APPID" == "$EXPECTED_TEAM.$EXPECTED_BUNDLE_ID" ]]; then
        ok "application-identifier = $APPID"
    else
        bad "application-identifier = $APPID" "expected $EXPECTED_TEAM.$EXPECTED_BUNDLE_ID"
    fi
fi

CERT="$(codesign -dvvv "$APP" 2>&1 | sed -n 's/^Authority=//p' | head -1)"
case "$CERT" in
    "Apple Distribution"*) ok "signed by: $CERT" ;;
    "Apple Development"*)  bad "signed by: $CERT" "A development certificate cannot be uploaded to App Store Connect." ;;
    "")                    bad "no signing authority found (unsigned bundle)" ;;
    *)                     warn "signed by: $CERT" ;;
esac

printf '\n%s4. Push notification plumbing%s\n' "$BOLD" "$OFF"
PLIST="$APP/Info.plist"
BG="$(plutil -extract UIBackgroundModes json "$PLIST" 2>/dev/null)"
if [[ "$BG" == *remote-notification* ]]; then
    ok "UIBackgroundModes includes remote-notification (silent pushes deliverable)"
else
    # Visible alert pushes — which is all trinh-push-notify sends — work without this.
    warn "UIBackgroundModes has no remote-notification"
    printf '      %sAppDelegate implements application(_:didReceiveRemoteNotification:fetchCompletionHandler:),%s\n' "$DIM" "$OFF"
    printf '      %sso iOS logs a warning and never calls it. Visible order-status alerts still%s\n' "$DIM" "$OFF"
    printf '      %swork. Either add the background mode or drop the unused handler.%s\n' "$DIM" "$OFF"
fi
[[ -f "$APP/GoogleService-Info.plist" ]] \
    && ok "GoogleService-Info.plist bundled (FCM can initialise)" \
    || bad "GoogleService-Info.plist missing from the bundle" "FirebaseApp.configure() will crash at launch."

printf '\n%s5. Secrets%s\n' "$BOLD" "$OFF"
if [[ -f "$APP/Secrets.plist" ]]; then
    K="$(plutil -extract WOO_CONSUMER_KEY raw "$APP/Secrets.plist" 2>/dev/null)"
    if [[ "$K" == ck_REPLACE* || -z "$K" ]]; then
        bad "Secrets.plist still holds the placeholder key" "The menu will not load. Run scripts/rotate-woo-key.sh install."
    else
        ok "Secrets.plist has a real key (…${K: -8})"
        printf '      %sRead-only is required — this ships inside the IPA. Verify with:%s\n' "$DIM" "$OFF"
        printf '      %s./scripts/rotate-woo-key.sh audit%s\n' "$DIM" "$OFF"
    fi
else
    bad "Secrets.plist missing from the bundle" "Catalog reads will fail."
fi

printf '\n%s────────────────────────────%s\n' "$BOLD" "$OFF"
if [[ $FAIL -eq 0 ]]; then
    printf '%s%s check(s) passed — safe to upload.%s\n' "$GREEN" "$PASS" "$OFF"
    exit 0
fi
printf '%s%s of %s check(s) failed.%s\n' "$RED" "$FAIL" "$((PASS+FAIL))" "$OFF"
exit 1
