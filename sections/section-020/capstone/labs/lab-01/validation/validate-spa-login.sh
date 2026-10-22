#!/usr/bin/env bash
# PASS when: the code flow with PKCE and no secret ends with an ID token for alice with the request's nonce.
set -uo pipefail

NAMESPACE="pkcecapstone-demo"

kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
# client_uuid CLIENT_ID: prints the internal id of a client in the realm inventory.
client_uuid() {
  kcadm get clients -r inventory -q clientId="$1" --fields id --format csv --noquotes | tr -d '\r'
}
# run_code_flow KEY=VALUE ...: runs one authorization code flow in the tester
# pod and prints KEY=VALUE lines (FORM_FOUND, CODE_FOUND, TOKEN_STATUS, ACAO,
# ACCESS_CLAIMS, ID_CLAIMS and more).
run_code_flow() {
  kubectl -n "$NAMESPACE" exec -i deploy/tester -- env "$@" sh -s <<'CODE_FLOW'
# One OpenID Connect authorization code flow, run inside the tester pod.
# Input (environment): REALM, CLIENT_ID, REDIRECT_URI, USERNAME, PASSWORD, and
# optionally ORIGIN (default http://localhost:5173), PKCE (S256, plain or
# none; default S256), RESPONSE_TYPE (default code), CLIENT_SECRET,
# SEND_VERIFIER (yes or no; default yes).
# Output: KEY=VALUE lines that say how far the flow got.
set -u
KEYCLOAK_URL="http://keycloak:8080"
ORIGIN="${ORIGIN:-http://localhost:5173}"
PKCE="${PKCE:-S256}"
RESPONSE_TYPE="${RESPONSE_TYPE:-code}"
CLIENT_SECRET="${CLIENT_SECRET:-}"
SEND_VERIFIER="${SEND_VERIFIER:-yes}"
WORK_DIR="$(mktemp -d)"
COOKIES="$WORK_DIR/cookies"
HEADERS="$WORK_DIR/headers"
BODY="$WORK_DIR/body"
random_text() { head -c "$1" /dev/urandom | base64 | tr -d '\n=+/'; }
url_encode() { printf '%s' "$1" | jq -sRr @uri; }
header_value() { grep -i "^$1:" "$HEADERS" | head -n 1 | cut -d' ' -f2- | tr -d '\r'; }
finish() { rm -rf "$WORK_DIR"; exit 0; }

STATE="state-$(random_text 12)"
NONCE="nonce-$(random_text 12)"
CODE_VERIFIER=""
AUTH_URL="$KEYCLOAK_URL/realms/$REALM/protocol/openid-connect/auth?client_id=$(url_encode "$CLIENT_ID")&response_type=$(url_encode "$RESPONSE_TYPE")&scope=openid&state=$STATE&nonce=$NONCE&redirect_uri=$(url_encode "$REDIRECT_URI")"
case "$PKCE" in
  S256)
    CODE_VERIFIER="$(random_text 48)"
    CODE_CHALLENGE="$(printf '%s' "$CODE_VERIFIER" | openssl dgst -sha256 -binary | base64 | tr '+/' '-_' | tr -d '=\n')"
    AUTH_URL="$AUTH_URL&code_challenge=$CODE_CHALLENGE&code_challenge_method=S256"
    ;;
  plain)
    CODE_VERIFIER="$(random_text 48)"
    AUTH_URL="$AUTH_URL&code_challenge=$CODE_VERIFIER&code_challenge_method=plain"
    ;;
esac
echo "STATE=$STATE"
echo "NONCE=$NONCE"

# Step 1: the authorization request. A login page means Keycloak accepted it.
AUTH_STATUS="$(curl -s -c "$COOKIES" -b "$COOKIES" -o "$BODY" -D "$HEADERS" -w '%{http_code}' "$AUTH_URL")"
echo "AUTH_STATUS=$AUTH_STATUS"
echo "AUTH_LOCATION=$(header_value location)"
FORM_ACTION="$(grep -o 'action="[^"]*login-actions/authenticate[^"]*"' "$BODY" | head -n 1 \
  | sed -e 's/^action="//' -e 's/"$//' -e 's/&amp;/\&/g')"
if [ -z "$FORM_ACTION" ]; then
  echo "FORM_FOUND=no"
  finish
fi
echo "FORM_FOUND=yes"

# Step 2: post the user's credentials to the login form. Keycloak answers with
# a redirect to redirect_uri that carries the authorization code.
LOGIN_STATUS="$(curl -s -c "$COOKIES" -b "$COOKIES" -o "$BODY" -D "$HEADERS" -w '%{http_code}' \
  --data-urlencode "username=$USERNAME" --data-urlencode "password=$PASSWORD" \
  --data-urlencode "credentialId=" "$FORM_ACTION")"
LOGIN_LOCATION="$(header_value location)"
echo "LOGIN_STATUS=$LOGIN_STATUS"
echo "LOGIN_LOCATION=$LOGIN_LOCATION"
CODE="$(printf '%s' "$LOGIN_LOCATION" | sed -n 's/.*[?&#]code=\([^&]*\).*/\1/p')"
if [ -z "$CODE" ]; then
  echo "CODE_FOUND=no"
  finish
fi
echo "CODE_FOUND=yes"

# Step 3: exchange the code for tokens, from the origin of the application.
set -- -d grant_type=authorization_code --data-urlencode "client_id=$CLIENT_ID" \
  --data-urlencode "code=$CODE" --data-urlencode "redirect_uri=$REDIRECT_URI"
if [ -n "$CODE_VERIFIER" ] && [ "$SEND_VERIFIER" = yes ]; then
  set -- "$@" --data-urlencode "code_verifier=$CODE_VERIFIER"
fi
if [ -n "$CLIENT_SECRET" ]; then
  set -- "$@" --data-urlencode "client_secret=$CLIENT_SECRET"
fi
TOKEN_STATUS="$(curl -s -o "$BODY" -D "$HEADERS" -w '%{http_code}' -H "Origin: $ORIGIN" "$@" \
  "$KEYCLOAK_URL/realms/$REALM/protocol/openid-connect/token")"
echo "TOKEN_STATUS=$TOKEN_STATUS"
echo "ACAO=$(header_value access-control-allow-origin)"
echo "TOKEN_JSON=$(tr -d '\n' < "$BODY")"
token_claims() {
  jq -r ".$1 // empty" "$BODY" \
    | jq -rR 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d' 2>/dev/null | tr -d '\n'
}
echo "ACCESS_CLAIMS=$(token_claims access_token)"
echo "ID_CLAIMS=$(token_claims id_token)"
finish
CODE_FLOW
}
# flow_value OUTPUT KEY: prints the value of KEY from the output of run_code_flow.
flow_value() {
  printf '%s\n' "$1" | sed -n "s/^$2=//p" | head -n 1
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin >/dev/null 2>&1

OUTPUT="$(run_code_flow REALM=inventory CLIENT_ID=inventory-web REDIRECT_URI=http://localhost:5173/callback \
  USERNAME=alice PASSWORD=alice-password PKCE=S256 ORIGIN=http://localhost:5173)"
if [ "$(flow_value "$OUTPUT" TOKEN_STATUS)" != "200" ]; then
  echo "FAIL: the single page application login (code flow with PKCE, no client secret) did not end with tokens."
  printf '%s\n' "$OUTPUT" | grep -E '^(AUTH_STATUS|AUTH_LOCATION|FORM_FOUND|LOGIN_STATUS|CODE_FOUND|TOKEN_STATUS)='
  exit 1
fi
NONCE="$(flow_value "$OUTPUT" NONCE)"
ID_CLAIMS="$(flow_value "$OUTPUT" ID_CLAIMS)"
if ! printf '%s' "$ID_CLAIMS" | grep -q "\"nonce\":\"$NONCE\""; then
  echo "FAIL: the ID token does not carry the nonce of the request."
  exit 1
fi
if ! printf '%s' "$ID_CLAIMS" | grep -q '"preferred_username":"alice"'; then
  echo "FAIL: the ID token does not name alice."
  exit 1
fi
if [ "$(flow_value "$OUTPUT" ACAO)" != "http://localhost:5173" ]; then
  echo "FAIL: the token response does not allow the origin http://localhost:5173."
  exit 1
fi
echo "PASS: alice signs in to the single page application, and the ID token carries her name and the nonce."
exit 0
