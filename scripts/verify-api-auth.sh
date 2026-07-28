#!/usr/bin/env bash
#
# verify-api-auth.sh — integration checks for the JWT-scoped trinh-app/v1 routes and the
# re-secured bu/v1 points routes.
#
# Confirms the two vulnerabilities that motivated this work are actually closed:
#   1. Consumer-key data access replaced by per-user JWT scoping
#      (customers / orders / vouchers / payment methods / payment intents)
#   2. Unauthenticated, client-supplied user_id on /fcm/register and bu/v1/*
#
# ─── Usage ───────────────────────────────────────────────────────────────────────
#   APP_USER='you@example.com' APP_PASS='…' ./scripts/verify-api-auth.sh
#
#   Cross-account tests (the strongest ones) need a second real account:
#   APP_USER='a@x.com'  APP_PASS='…' \
#   APP_USER2='b@x.com' APP_PASS2='…' ./scripts/verify-api-auth.sh
#
# Flags:
#   --write             Enable tests that CREATE DATA (orders, an account, a redeemed
#                       voucher). Off by default — see "Safety" below.
#   --rate-limit        Also test the /register throttle. Blocks your IP from signing up
#                       for 15 min, so it runs last and is opt-in.
#   --verbose           Print response bodies for every check, not just failures.
#   --base-url URL      Override the target (default https://trinhsgroup.com.au).
#
# Optional env:
#   TEST_PRODUCT_ID     A purchasable product id. Required for the order-creation checks;
#                       those are skipped without it.
#
# ─── Safety ──────────────────────────────────────────────────────────────────────
# The default run is NON-DESTRUCTIVE: it only reads, and exercises attacks that are
# expected to be *rejected*. Nothing is created or modified.
#
# This script NEVER calls DELETE /me. To verify account deletion, do it deliberately on a
# throwaway account:
#     curl -X DELETE -H "Authorization: Bearer $JWT" \
#          https://trinhsgroup.com.au/wp-json/trinh-app/v1/me
#
# --write creates real WooCommerce orders (status on-hold) and possibly a real customer.
# Point it at staging if you have one, and clean up afterwards in wp-admin.

set -uo pipefail

BASE_URL="${BASE_URL:-https://trinhsgroup.com.au}"
ALLOW_WRITES=0
TEST_RATE_LIMIT=0
VERBOSE=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --write)      ALLOW_WRITES=1; shift ;;
        --rate-limit) TEST_RATE_LIMIT=1; shift ;;
        --verbose)    VERBOSE=1; shift ;;
        --base-url)   BASE_URL="$2"; shift 2 ;;
        -h|--help)    sed -n '2,45p' "$0"; exit 0 ;;
        *) echo "Unknown flag: $1 (try --help)" >&2; exit 2 ;;
    esac
done

: "${APP_USER:?Set APP_USER to a WordPress account email or username}"
: "${APP_PASS:?Set APP_PASS to the matching password}"

command -v python3 >/dev/null || { echo "python3 is required for JSON parsing" >&2; exit 2; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

PASS=0; FAIL=0; SKIP=0
FAILED_NAMES=()

BOLD=$'\033[1m'; RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; DIM=$'\033[2m'; OFF=$'\033[0m'

# ─── HTTP + JSON helpers ─────────────────────────────────────────────────────────

RESP_CODE=""; RESP_BODY=""

# req METHOD PATH [JWT] [JSON_BODY]
req() {
    local method="$1" path="$2" jwt="${3:-}" body="${4:-}"
    local args=(-sS -X "$method" -o "$TMP/body" -w '%{http_code}' --max-time 30)
    [[ -n "$jwt" ]]  && args+=(-H "Authorization: Bearer $jwt")
    [[ -n "$body" ]] && args+=(-H 'Content-Type: application/json' -d "$body")
    RESP_CODE="$(curl "${args[@]}" "${BASE_URL}${path}" 2>/dev/null)" || RESP_CODE="000"
    RESP_BODY="$(cat "$TMP/body" 2>/dev/null || true)"
    [[ $VERBOSE -eq 1 ]] && printf '%s    → %s %s [%s] %s%s\n' "$DIM" "$method" "$path" "$RESP_CODE" "${RESP_BODY:0:400}" "$OFF"
    return 0
}

# jval '<python expr over d>' — evaluates against the last response body
jval() {
    printf '%s' "$RESP_BODY" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    print(''); raise SystemExit(0)
try:
    v = ($1)
except Exception:
    v = ''
print('' if v is None else v)
" 2>/dev/null
}

ok()   { PASS=$((PASS+1)); printf '  %s✓%s %s\n' "$GREEN" "$OFF" "$1"; }
bad()  { FAIL=$((FAIL+1)); FAILED_NAMES+=("$1"); printf '  %s✗%s %s\n     %sexpected %s, got %s%s\n' "$RED" "$OFF" "$1" "$DIM" "$2" "$3" "$OFF"
         [[ $VERBOSE -eq 0 ]] && printf '     %sbody: %s%s\n' "$DIM" "${RESP_BODY:0:300}" "$OFF"; return 0; }
skip() { SKIP=$((SKIP+1)); printf '  %s–%s %s %s(%s)%s\n' "$YELLOW" "$OFF" "$1" "$DIM" "$2" "$OFF"; }

# expect_code NAME EXPECTED
expect_code() {
    [[ "$RESP_CODE" == "$2" ]] && ok "$1" || bad "$1" "HTTP $2" "HTTP $RESP_CODE"
}

# expect_val NAME EXPECTED ACTUAL
expect_val() {
    [[ "$3" == "$2" ]] && ok "$1" || bad "$1" "$2" "${3:-<empty>}"
}

section() { printf '\n%s%s%s\n' "$BOLD" "$1" "$OFF"; }

# ─── 0. Authenticate ────────────────────────────────────────────────────────────

section "0. Authentication"

login() { # login USER PASS -> echoes token
    curl -sS --max-time 30 -X POST "${BASE_URL}/wp-json/jwt-auth/v1/token" \
        -H 'Content-Type: application/json' \
        -d "$(python3 -c 'import json,sys; print(json.dumps({"username":sys.argv[1],"password":sys.argv[2]}))' "$1" "$2")" \
        2>/dev/null | python3 -c 'import json,sys; print(json.load(sys.stdin).get("token",""))' 2>/dev/null
}

JWT="$(login "$APP_USER" "$APP_PASS")"
if [[ -z "$JWT" ]]; then
    printf '  %s✗%s could not obtain a JWT for %s — check APP_USER/APP_PASS\n' "$RED" "$OFF" "$APP_USER"
    exit 1
fi
ok "obtained JWT for $APP_USER"

req GET /wp-json/trinh-app/v1/me "$JWT"
if [[ "$RESP_CODE" != "200" ]]; then
    printf '  %s✗%s GET /me returned %s — is the trinh-app-api plugin active?\n' "$RED" "$OFF" "$RESP_CODE"
    printf '     %s%s%s\n' "$DIM" "${RESP_BODY:0:300}" "$OFF"
    exit 1
fi
USER_ID="$(jval "d['id']")"
USER_EMAIL="$(jval "d.get('email','')")"
ok "GET /me → id=$USER_ID email=$USER_EMAIL"

JWT2=""; USER2_ID=""
if [[ -n "${APP_USER2:-}" && -n "${APP_PASS2:-}" ]]; then
    JWT2="$(login "$APP_USER2" "$APP_PASS2")"
    if [[ -n "$JWT2" ]]; then
        req GET /wp-json/trinh-app/v1/me "$JWT2"
        USER2_ID="$(jval "d['id']")"
        ok "obtained JWT for second account (id=$USER2_ID)"
    else
        skip "second account login" "bad APP_USER2/APP_PASS2"
    fi
else
    skip "second account" "set APP_USER2/APP_PASS2 to enable cross-account tests"
fi

# ─── 1. Auth gate: every protected route must reject anonymous callers ──────────

section "1. Anonymous access is refused (fix #2)"

for route in /me /me/orders /me/vouchers /payment-methods; do
    req GET "/wp-json/trinh-app/v1${route}"
    expect_code "GET $route without token → 401" 401
done

req POST /wp-json/trinh-app/v1/fcm/register "" '{"fcm_token":"anon-probe-token"}'
expect_code "POST /fcm/register without token → 401" 401

req POST /wp-json/bu/v1/redeem "" '{"user_id":1,"points":10}'
expect_code "POST /bu/v1/redeem without token → 401" 401

req GET "/wp-json/bu/v1/me/points?user_id=1"
expect_code "GET /bu/v1/me/points without token → 401" 401

# An invalid/garbage token must not be treated as anonymous-but-allowed.
req GET /wp-json/trinh-app/v1/me "not.a.real.jwt"
if [[ "$RESP_CODE" == "401" || "$RESP_CODE" == "403" ]]; then
    ok "GET /me with a malformed token → $RESP_CODE"
else
    bad "GET /me with a malformed token → 401/403" "401 or 403" "HTTP $RESP_CODE"
fi

# ─── 2. Identity binding: the server ignores client-supplied user_id ────────────

section "2. user_id comes from the token, not the request (fix #2)"

FORGED_ID=999999

req POST /wp-json/trinh-app/v1/fcm/register "$JWT" \
    "$(printf '{"user_id":%s,"fcm_token":"verify-script-token"}' "$FORGED_ID")"
if [[ "$RESP_CODE" == "200" ]]; then
    expect_val "/fcm/register binds device to token's user, not the forged user_id" \
               "$USER_ID" "$(jval "d.get('user_id','')")"
else
    bad "/fcm/register with forged user_id" "HTTP 200" "HTTP $RESP_CODE"
fi

req GET "/wp-json/bu/v1/me/points?user_id=${FORGED_ID}" "$JWT"
expect_code "GET /bu/v1/me/points with someone else's user_id → 403" 403

req GET "/wp-json/bu/v1/me/points?user_id=${USER_ID}" "$JWT"
expect_code "GET /bu/v1/me/points with own user_id → 200" 200

# The guard back-fills user_id, so omitting it must still satisfy the route's
# 'required' => true arg and return this account's balance.
req GET "/wp-json/bu/v1/me/points" "$JWT"
if [[ "$RESP_CODE" == "200" ]]; then
    expect_val "GET /bu/v1/me/points with no user_id resolves to own account" \
               "$USER_ID" "$(jval "d.get('user_id','')")"
else
    bad "GET /bu/v1/me/points with no user_id → 200" "HTTP 200" "HTTP $RESP_CODE"
fi

req POST /wp-json/bu/v1/redeem "$JWT" \
    "$(printf '{"user_id":%s,"points":10}' "$FORGED_ID")"
expect_code "POST /bu/v1/redeem for another user → 403" 403

# ─── 3. Data scoping: reads only ever return the caller's own records ───────────

section "3. Responses are scoped to the caller (fix #1)"

req GET /wp-json/trinh-app/v1/me/orders "$JWT"
if [[ "$RESP_CODE" == "200" ]]; then
    FOREIGN="$(jval "sum(1 for o in d if int(o.get('customer_id',0)) != $USER_ID)")"
    TOTAL="$(jval "len(d)")"
    expect_val "GET /me/orders returns only own orders ($TOTAL total)" "0" "$FOREIGN"
    FIRST_ORDER_ID="$(jval "d[0]['id'] if d else ''")"
else
    bad "GET /me/orders → 200" "HTTP 200" "HTTP $RESP_CODE"
    FIRST_ORDER_ID=""
fi

req GET /wp-json/trinh-app/v1/me/vouchers "$JWT"
if [[ "$RESP_CODE" == "200" ]]; then
    NV="$(jval "len(d)")"
    # Redeemed voucher codes are minted as RW{user_id}-XXXXXXXX.
    FOREIGN="$(jval "sum(1 for c in d if not str(c.get('code','')).upper().startswith('RW${USER_ID}-'))")"
    expect_val "GET /me/vouchers returns only own vouchers ($NV total)" "0" "$FOREIGN"
else
    bad "GET /me/vouchers → 200" "HTTP 200" "HTTP $RESP_CODE"
fi

req GET /wp-json/trinh-app/v1/payment-methods "$JWT"
if [[ "$RESP_CODE" == "200" ]]; then
    NG="$(jval "len(d)")"
    DISABLED="$(jval "sum(1 for g in d if not g.get('enabled'))")"
    SUBMETHOD="$(jval "sum(1 for g in d if str(g.get('id','')).startswith(('woocommerce_payments_','stripe_')))")"
    expect_val "GET /payment-methods excludes disabled gateways ($NG returned)" "0" "$DISABLED"
    expect_val "GET /payment-methods excludes express/sub-methods" "0" "$SUBMETHOD"
else
    bad "GET /payment-methods → 200" "HTTP 200" "HTTP $RESP_CODE"
fi

# Strongest scoping evidence: two tokens must never see the same account.
if [[ -n "$JWT2" ]]; then
    req GET /wp-json/trinh-app/v1/me "$JWT2"
    expect_val "second token's /me returns the second account" "$USER2_ID" "$(jval "d['id']")"
    if [[ "$USER_ID" == "$USER2_ID" ]]; then
        skip "cross-account order/intent tests" "both credentials resolve to the same user"
    elif [[ -n "$FIRST_ORDER_ID" ]]; then
        req POST "/wp-json/trinh-app/v1/me/orders/${FIRST_ORDER_ID}/cancel" "$JWT2"
        expect_code "cancelling account A's order #${FIRST_ORDER_ID} with B's token → 403" 403

        req GET "/wp-json/trinh-app/v1/me/orders/${FIRST_ORDER_ID}/payment-intent" "$JWT2"
        expect_code "reading A's payment intent with B's token → 403" 403
    else
        skip "cross-account order tests" "account A has no orders to target"
    fi
fi

req POST "/wp-json/trinh-app/v1/me/orders/999999999/cancel" "$JWT"
expect_code "cancelling a non-existent order → 404" 404

# ─── 4. Profile writes cannot escalate privileges ──────────────────────────────

section "4. PUT /me drops non-allowlisted fields"

# role/id/meta_data are outside the allowlist, so a body containing only those has
# nothing left to apply — proving they were stripped rather than written.
req PUT /wp-json/trinh-app/v1/me "$JWT" '{"role":"administrator"}'
expect_code "PUT /me {role:administrator} → 400 nothing to update" 400
expect_val  "  …rejected as trinh_nothing_to_update" "trinh_nothing_to_update" "$(jval "d.get('code','')")"

req PUT /wp-json/trinh-app/v1/me "$JWT" '{"id":1,"meta_data":[{"key":"mycred_default","value":999999}]}'
expect_code "PUT /me {id, meta_data:points} → 400 nothing to update" 400

req PUT /wp-json/trinh-app/v1/me "$JWT" '{"email":"not-an-email"}'
expect_code "PUT /me with a malformed email → 400" 400

# Points must be untouched by the attempted meta_data write above.
req GET "/wp-json/bu/v1/me/points" "$JWT"
BAL="$(jval "d.get('balance','')")"
if [[ "$BAL" == "999999" || "$BAL" == "999999.0" ]]; then
    bad "points balance unchanged by meta_data write" "not 999999" "$BAL"
else
    ok "points balance unchanged by meta_data write (balance=$BAL)"
fi

# ─── 5. Order creation cannot be tampered with ─────────────────────────────────

section "5. POST /me/orders validates and recomputes server-side"

req POST /wp-json/trinh-app/v1/me/orders "$JWT" '{"line_items":[]}'
expect_code "empty line_items → 400" 400

req POST /wp-json/trinh-app/v1/me/orders "$JWT" \
    '{"line_items":[{"product_id":999999999,"quantity":1}]}'
expect_code "non-existent product → 400" 400

if [[ -z "${TEST_PRODUCT_ID:-}" ]]; then
    skip "order status/pricing/coupon checks" "set TEST_PRODUCT_ID to a purchasable product id"
else
    PID="$TEST_PRODUCT_ID"

    # Rejected before anything is created — safe to run without --write.
    req POST /wp-json/trinh-app/v1/me/orders "$JWT" \
        "$(printf '{"status":"completed","line_items":[{"product_id":%s,"quantity":1}]}' "$PID")"
    expect_code "status:completed (skipping payment) → 400" 400
    expect_val  "  …rejected as trinh_invalid_status" "trinh_invalid_status" "$(jval "d.get('code','')")"

    req POST /wp-json/trinh-app/v1/me/orders "$JWT" \
        "$(printf '{"status":"processing","line_items":[{"product_id":%s,"quantity":1}]}' "$PID")"
    expect_code "status:processing → 400" 400

    req POST /wp-json/trinh-app/v1/me/orders "$JWT" \
        "$(printf '{"payment_method":"not_a_gateway","line_items":[{"product_id":%s,"quantity":1}]}' "$PID")"
    expect_code "unknown payment_method → 400" 400

    req POST /wp-json/trinh-app/v1/me/orders "$JWT" \
        "$(printf '{"coupon_code":"DEFINITELY-NOT-YOURS-XYZ","line_items":[{"product_id":%s,"quantity":1}]}' "$PID")"
    expect_code "voucher not owned by caller → 403" 403

    if [[ $ALLOW_WRITES -eq 0 ]]; then
        skip "order creation (customer_id + price tampering)" "re-run with --write; creates real orders"
    else
        printf '  %screating real orders — clean them up in wp-admin afterwards%s\n' "$YELLOW" "$OFF"

        # Forge customer_id AND under-price the line item in one request.
        req POST /wp-json/trinh-app/v1/me/orders "$JWT" "$(printf '{
            "customer_id": %s,
            "set_paid": true,
            "status": "on-hold",
            "line_items": [{"product_id": %s, "quantity": 2, "price": "0.01", "total": "0.01", "subtotal": "0.01"}],
            "pickup_datetime": "2030-01-01 12:00:00"
        }' "$FORGED_ID" "$PID")"

        if [[ "$RESP_CODE" == "201" || "$RESP_CODE" == "200" ]]; then
            NEW_ORDER_ID="$(jval "d.get('id','')")"
            expect_val "created order belongs to the token's user, not the forged customer_id" \
                       "$USER_ID" "$(jval "d.get('customer_id','')")"
            expect_val "  …set_paid:true ignored (order is unpaid)" \
                       "" "$(jval "d.get('date_paid') or ''")"

            LINE_TOTAL="$(jval "d['line_items'][0]['total']")"
            if [[ "$LINE_TOTAL" == "0.01" ]]; then
                bad "client price rejected in favour of catalog price" "catalog price" "0.01 (client value honoured)"
            else
                ok "client price rejected in favour of catalog price (line total=$LINE_TOTAL)"
            fi

            DISCOUNT="$(jval "next((f['name'] for f in d.get('fee_lines',[]) if 'Discount' in f.get('name','')), '')")"
            expect_val "  …5% discount applied server-side" "Discount 5%" "$DISCOUNT"

            printf '     %screated order #%s — cancel/delete it in wp-admin%s\n' "$DIM" "$NEW_ORDER_ID" "$OFF"

            # An on-hold order is cancellable by its owner; a cancelled one is not.
            req POST "/wp-json/trinh-app/v1/me/orders/${NEW_ORDER_ID}/cancel" "$JWT"
            expect_code "owner cancels own on-hold order #${NEW_ORDER_ID} → 200" 200
            req POST "/wp-json/trinh-app/v1/me/orders/${NEW_ORDER_ID}/cancel" "$JWT"
            expect_code "  …cancelling it again → 409 not cancellable" 409
        else
            bad "create order with forged customer_id" "HTTP 200/201" "HTTP $RESP_CODE"
        fi
    fi
fi

# ─── 6. Public signup route ────────────────────────────────────────────────────

section "6. POST /register (public by necessity)"

req POST /wp-json/trinh-app/v1/register "" '{"email":"not-an-email","password":"abcdefgh"}'
expect_code "malformed email → 400" 400

req POST /wp-json/trinh-app/v1/register "" '{"email":"probe+verify@example.com","password":"short"}'
expect_code "password under 8 chars → 400" 400

req POST /wp-json/trinh-app/v1/register "" \
    "$(python3 -c 'import json,sys; print(json.dumps({"email":sys.argv[1],"password":"abcdefgh12"}))' "$USER_EMAIL")"
expect_code "already-registered email → 409" 409

if [[ $ALLOW_WRITES -eq 1 ]]; then
    NEW_EMAIL="verify-$(date +%s)@example.com"
    req POST /wp-json/trinh-app/v1/register "" \
        "$(python3 -c 'import json,sys; print(json.dumps({"email":sys.argv[1],"password":"Abcdefgh12!","username":"Verify Script"}))' "$NEW_EMAIL")"
    expect_code "valid signup → 201" 201
    printf '     %screated customer %s (id=%s) — delete it in wp-admin%s\n' \
        "$DIM" "$NEW_EMAIL" "$(jval "d.get('id','')")" "$OFF"
else
    skip "valid signup" "re-run with --write; creates a real customer"
fi

if [[ $TEST_RATE_LIMIT -eq 1 ]]; then
    printf '  %sthrottle test — this IP will be blocked from signup for 15 min%s\n' "$YELLOW" "$OFF"
    THROTTLED=0
    for i in 1 2 3 4 5 6 7; do
        req POST /wp-json/trinh-app/v1/register "" '{"email":"bad","password":"x"}'
        [[ "$RESP_CODE" == "429" ]] && { THROTTLED=1; break; }
    done
    expect_val "repeated signup attempts eventually return 429" "1" "$THROTTLED"
else
    skip "signup throttle" "re-run with --rate-limit (blocks your IP for 15 min)"
fi

# ─── Summary ───────────────────────────────────────────────────────────────────

printf '\n%s────────────────────────────────────────%s\n' "$BOLD" "$OFF"
printf '%spassed%s %s   %sfailed%s %s   %sskipped%s %s\n' \
    "$GREEN" "$OFF" "$PASS" "$RED" "$OFF" "$FAIL" "$YELLOW" "$OFF" "$SKIP"

if [[ $FAIL -gt 0 ]]; then
    printf '\n%sFailures:%s\n' "$RED" "$OFF"
    for n in "${FAILED_NAMES[@]}"; do printf '  • %s\n' "$n"; done
    printf '\nRe-run with --verbose to see full responses.\n'
    exit 1
fi

printf '\n%sAll executed checks passed.%s\n' "$GREEN" "$OFF"
[[ $SKIP -gt 0 ]] && printf '%s%s check(s) skipped — see the notes above for how to enable them.%s\n' "$DIM" "$SKIP" "$OFF"
exit 0
