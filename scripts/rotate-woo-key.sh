#!/usr/bin/env bash
#
# rotate-woo-key.sh — audit and safely install the WooCommerce REST key that ships in the app.
#
# The key in Secrets.plist is embedded in the IPA and therefore extractable by anyone who
# downloads the app. It is used ONLY for public catalog reads (products, categories);
# everything touching a customer, order, voucher or payment goes through
# /wp-json/trinh-app/v1/* with the signed-in user's JWT.
#
# So the key MUST be Read-only. This script refuses to install one that can write.
#
# ─── Usage ──────────────────────────────────────────────────────────────────────
#   ./scripts/rotate-woo-key.sh audit      # what is in Secrets.plist right now?
#   ./scripts/rotate-woo-key.sh install    # prompts for a new key, validates, installs
#
# Secrets are read via hidden prompt, never as arguments — command-line args leak into
# shell history and `ps`.
#
# ─── How the permission probe works (and why it is safe) ────────────────────────
# WooCommerce rejects write methods for a Read-only key inside WC_REST_Authentication::
# check_permissions() — at the authentication layer, BEFORE routing or loading any object
# (includes/class-wc-rest-authentication.php). So:
#
#   PUT /wc/v3/products/999999999  with a Read key       → 401 woocommerce_rest_authentication_error
#   PUT /wc/v3/products/999999999  with a Read/Write key → 404 woocommerce_rest_product_invalid_id
#
# Product 999999999 does not exist and the body is empty, so NOTHING is created or
# modified in either case. This is a read-only diagnostic.
#
# ─── What this script cannot do ─────────────────────────────────────────────────
# Revoking the old key and generating a new one requires WP admin:
#   WooCommerce → Settings → Advanced → REST API
# WooCommerce shows a new consumer secret exactly once, at creation. Copy it before
# leaving that page.

set -uo pipefail

BASE_URL="${BASE_URL:-https://trinhsgroup.com.au}"
API="$BASE_URL/wp-json/wc/v3"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLIST="$REPO_ROOT/TrinhsGroup/Secrets.plist"

BOLD=$'\033[1m'; RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; DIM=$'\033[2m'; OFF=$'\033[0m'

command -v plutil >/dev/null || { echo "plutil required (macOS)" >&2; exit 2; }
command -v python3 >/dev/null || { echo "python3 required" >&2; exit 2; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# ─── Probes ─────────────────────────────────────────────────────────────────────

# probe_read CK CS -> sets READ_CODE + READ_REASON.
# Deliberately NOT called via $(…): a subshell would discard the globals.
READ_CODE=""; READ_REASON=""
probe_read() {
    READ_CODE=$(curl -sS -o "$TMP/read" -w '%{http_code}' --max-time 25 -u "$1:$2" \
        "$API/products?per_page=1" 2>/dev/null || echo 000)
    READ_REASON="$(python3 - "$TMP/read" <<'PY'
import json, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception:
    print(""); raise SystemExit(0)
if isinstance(d, list):
    print(""); raise SystemExit(0)
code = d.get('code', '')
msg  = (d.get('message') or '').strip()
# WooCommerce error messages never contain the credential itself, so this is safe to show.
print(f"{code} — {msg}" if code else msg)
PY
)"
}

# probe_write CK CS -> echoes "readonly" | "writable" | "unknown:<detail>"
probe_write() {
    local code
    code=$(curl -sS -o "$TMP/write" -w '%{http_code}' --max-time 25 -u "$1:$2" \
        -X PUT -H 'Content-Type: application/json' -d '{}' \
        "$API/products/999999999" 2>/dev/null || echo 000)
    python3 - "$code" "$TMP/write" <<'PY'
import json, sys
code, path = sys.argv[1], sys.argv[2]
try:
    d = json.load(open(path))
except Exception:
    print(f"unknown:HTTP {code}, unparseable body"); raise SystemExit(0)
c = d.get('code', '')
if c == 'woocommerce_rest_authentication_error':
    # Rejected at the auth layer → this key has no write permission.
    print("readonly")
elif c.startswith('woocommerce_rest_'):
    # Auth passed; it only failed on the non-existent product id.
    print("writable")
else:
    print(f"unknown:HTTP {code}, code={c or '?'}")
PY
}

# classify CK CS -> prints a verdict block, returns 0 if read-only & readable
classify() {
    local ck="$1" cs="$2" label="$3"
    local w
    probe_read "$ck" "$cs"
    printf '  %-28s %s' "$label" ""
    if [[ "$READ_CODE" != "200" ]]; then
        if [[ "$READ_CODE" == "401" ]]; then
            # WooCommerce distinguishes these by message, not by code
            # (includes/class-wc-rest-authentication.php).
            case "$READ_REASON" in
                *"does not have read permissions"*)
                    printf '%sWRITE-ONLY%s — valid key, wrong permission\n' "$RED" "$OFF"
                    printf '    %s%s%s\n' "$DIM" "$READ_REASON" "$OFF"
                    return 3 ;;
                *"Consumer secret is invalid"*)
                    printf '%sBAD SECRET%s — the key exists, the secret does not match it\n' "$RED" "$OFF"
                    printf '    %s%s%s\n' "$DIM" "$READ_REASON" "$OFF"
                    return 5 ;;
                *)
                    # Either "Consumer key is invalid." or — on this site, where the JWT
                    # plugin suppresses WooCommerce's auth error and the request falls
                    # through as anonymous — woocommerce_rest_cannot_view.
                    printf '%sNOT ACCEPTED%s — key unknown/revoked, or credentials not honoured\n' "$YELLOW" "$OFF"
                    [[ -n "$READ_REASON" ]] && printf '    %s%s%s\n' "$DIM" "$READ_REASON" "$OFF"
                    return 2 ;;
            esac
        fi
        printf '%scannot read%s (HTTP %s) %s\n' "$RED" "$OFF" "$READ_CODE" "$READ_REASON"
        return 1
    fi
    w=$(probe_write "$ck" "$cs")
    case "$w" in
        readonly) printf '%sREAD-ONLY%s — correct for a shipped key\n' "$GREEN" "$OFF"; return 0 ;;
        writable) printf '%sREAD-WRITE%s — must not ship; anyone with the IPA can write to the store\n' "$RED" "$OFF"; return 1 ;;
        unknown:*) printf '%sindeterminate%s (%s)\n' "$YELLOW" "$OFF" "${w#unknown:}"; return 1 ;;
    esac
}

current_ck() { plutil -extract WOO_CONSUMER_KEY raw "$PLIST" 2>/dev/null; }
current_cs() { plutil -extract WOO_CONSUMER_SECRET raw "$PLIST" 2>/dev/null; }

# ─── Commands ───────────────────────────────────────────────────────────────────

cmd_audit() {
    printf '\n%sAuditing %s%s\n' "$BOLD" "$PLIST" "$OFF"
    local ck cs
    ck="$(current_ck)"; cs="$(current_cs)"
    if [[ -z "$ck" || -z "$cs" ]]; then
        printf '  %s✗%s Secrets.plist missing or has no key.\n' "$RED" "$OFF"
        printf '    cp TrinhsGroup/Secrets.example.plist TrinhsGroup/Secrets.plist\n'
        exit 1
    fi
    if [[ "$ck" == ck_REPLACE* ]]; then
        printf '  %s–%s still the placeholder — nothing deployed yet.\n' "$YELLOW" "$OFF"
        exit 0
    fi
    printf '  key in Secrets.plist: %s…%s\n\n' "${ck:0:6}" "${ck: -8}"
    classify "$ck" "$cs" "permissions:"
    local rc=$?

    local in_history=0
    if git -C "$REPO_ROOT" log --all -S"$ck" --oneline -- '*.swift' 2>/dev/null | grep -q .; then
        in_history=1
    fi

    case $rc in
        2)  # Already revoked server-side — this is the expected state mid-rotation.
            printf '\n  %sThis key no longer works server-side%s — revocation confirmed.\n' "$GREEN" "$OFF"
            printf '  Secrets.plist still holds it, so the app cannot load the menu until you install\n'
            printf '  the new Read-only key:\n    %s./scripts/rotate-woo-key.sh install%s\n' "$BOLD" "$OFF"
            return 1 ;;
        0)  if [[ $in_history -eq 1 ]]; then
                printf '\n  %s⚠ this key appears in git history%s — compromised even though it is Read-only.\n' "$RED" "$OFF"
                printf '    Revoke it in WP admin and install a fresh key:\n'
                printf '    %s./scripts/rotate-woo-key.sh install%s\n' "$BOLD" "$OFF"
                return 1
            fi
            printf '\n  %s✓ Read-only and not present in git history — this is the state you want.%s\n' "$GREEN" "$OFF"
            return 0 ;;
        *)  if [[ $in_history -eq 1 ]]; then
                printf '\n  %s⚠ and it appears in git history%s — assume it is public.\n' "$RED" "$OFF"
            fi
            printf '    Fix: %s./scripts/rotate-woo-key.sh install%s\n' "$BOLD" "$OFF"
            return 1 ;;
    esac
}

cmd_install() {
    printf '\n%sInstall a new WooCommerce REST key%s\n' "$BOLD" "$OFF"
    printf '%sCreate it first: WP admin → WooCommerce → Settings → Advanced → REST API → Add key\n' "$DIM"
    printf 'Permissions MUST be "Read". The secret is shown only once.%s\n\n' "$OFF"

    local ck cs
    read -r  -p "  Consumer key (ck_…): " ck
    read -rs -p "  Consumer secret (cs_…, hidden): " cs; echo; echo

    [[ "$ck" == ck_* ]] || { printf '  %s✗%s key should start with ck_\n' "$RED" "$OFF"; exit 1; }
    [[ "$cs" == cs_* ]] || { printf '  %s✗%s secret should start with cs_\n' "$RED" "$OFF"; exit 1; }

    printf '%sValidating the new key against %s%s\n' "$BOLD" "$BASE_URL" "$OFF"
    classify "$ck" "$cs" "new key:"
    local verdict=$?
    if [[ $verdict -ne 0 ]]; then
        printf '\n  %sRefusing to install%s — Secrets.plist untouched. Cause and fix:\n\n' "$RED" "$OFF"
        case $verdict in
            2)  printf '  The consumer KEY was not recognised. In order of likelihood:\n'
                printf '   1. The ck_… value is truncated or has a stray character. Copy it again.\n'
                printf '   2. You revoked the NEW key instead of the old one — check the REST API list;\n'
                printf '      the new key should still be there with Permissions "Read".\n'
                printf '   3. The key belongs to a different site/environment than %s.\n' "$BASE_URL" ;;
            3)  printf '  The key is valid but Write-only. Re-create it with Permissions = %sRead%s.\n' "$BOLD" "$OFF" ;;
            5)  printf '  The key was found, but the SECRET does not match it. Almost always an\n'
                printf '  incomplete paste — the field is hidden, so a partial paste looks identical\n'
                printf '  to a full one. WooCommerce shows cs_… only once at creation; if it is no\n'
                printf '  longer on screen, revoke that key and generate a new one.\n' ;;
            *)  printf '  The key can write. A key shipped inside the app must be Read-only:\n'
                printf '  anyone can extract it from the IPA. Re-create with Permissions = %sRead%s.\n' "$BOLD" "$OFF" ;;
        esac
        exit 1
    fi

    # Confirm the old key is dead. Not fatal — but the whole point of rotating is revocation.
    local old_ck old_cs
    old_ck="$(current_ck)"; old_cs="$(current_cs)"
    if [[ -n "$old_ck" && "$old_ck" != ck_REPLACE* && "$old_ck" != "$ck" ]]; then
        printf '\n%sChecking the key being replaced%s\n' "$BOLD" "$OFF"
        classify "$old_ck" "$old_cs" "old key (…${old_ck: -8}):"
        if [[ $? -ne 2 ]]; then
            printf '\n  %s⚠ the old key still works%s — it has not been revoked.\n' "$YELLOW" "$OFF"
            printf '    Delete it in WP admin, or the exposure remains open.\n'
            read -r -p "    Install the new key anyway? [y/N] " go
            [[ "$go" == [yY] ]] || { printf '    Aborted.\n'; exit 1; }
        fi
    fi

    cp "$PLIST" "$PLIST.bak" && printf '\n  backed up → %s\n' "$(basename "$PLIST").bak"
    plutil -replace WOO_CONSUMER_KEY    -string "$ck" "$PLIST" || { printf '  %s✗%s write failed\n' "$RED" "$OFF"; exit 1; }
    plutil -replace WOO_CONSUMER_SECRET -string "$cs" "$PLIST" || { printf '  %s✗%s write failed\n' "$RED" "$OFF"; exit 1; }

    # Read back — never trust a write you have not verified.
    if [[ "$(current_ck)" == "$ck" && "$(current_cs)" == "$cs" ]]; then
        printf '  %s✓%s installed into Secrets.plist and verified on read-back\n' "$GREEN" "$OFF"
    else
        printf '  %s✗%s read-back mismatch — restoring backup\n' "$RED" "$OFF"
        mv "$PLIST.bak" "$PLIST"; exit 1
    fi

    printf '\n%sNext%s\n' "$BOLD" "$OFF"
    printf '  1. Rebuild the app (Secrets.plist is bundled at build time).\n'
    printf '  2. Check the menu still loads — that is all this key is used for.\n'
    printf '  3. Delete %s.bak once you are happy; it still holds the old secret.\n' "$(basename "$PLIST")"
    printf '\n%sNote:%s the old key stays in git history forever. Revoking it in WP admin is what\n' "$YELLOW" "$OFF"
    printf 'makes it harmless — rewriting history is neither necessary nor sufficient.\n'
}

# Test a candidate key and print the verdict only. Never touches Secrets.plist, so it is
# safe to run repeatedly while sorting out a paste problem. The output contains no secret.
cmd_probe() {
    printf '\n%sProbe a key (nothing will be written)%s\n\n' "$BOLD" "$OFF"
    local ck cs
    read -r  -p "  Consumer key (ck_…): " ck
    read -rs -p "  Consumer secret (cs_…, hidden): " cs; echo; echo
    classify "$ck" "$cs" "verdict:"
    local v=$?
    printf '\n  %sraw read response:%s HTTP %s  %s\n' "$DIM" "$OFF" "$READ_CODE" "${READ_REASON:-<none>}"
    printf '  %sSafe to share the two lines above — they contain no credential.%s\n' "$DIM" "$OFF"
    return $v
}

case "${1:-audit}" in
    audit)   cmd_audit ;;
    install) cmd_install ;;
    probe)   cmd_probe ;;
    -h|--help) sed -n '2,40p' "$0" ;;
    *) printf 'Usage: %s [audit|install|probe]\n' "$0" >&2; exit 2 ;;
esac
