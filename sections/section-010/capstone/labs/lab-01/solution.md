# Solution: Secure The Clients Of A Realm

Work the task yourself first. `astrona submit -c sections/section-010/capstone/labs/lab-01` tells you which checks pass.

The grader checks four things: the settings of `inventory-web`, that the implicit flow is refused, a full sign-in with the right and a wrong origin, and a client credentials token for `inventory-reporter`.

## Step 1: Read both clients

```sh
NAMESPACE=clientscapstone-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
for CLIENT in inventory-web inventory-reporter; do
  kcadm get clients -r inventory -q clientId="$CLIENT" \
    --fields clientId,publicClient,standardFlowEnabled,implicitFlowEnabled,serviceAccountsEnabled,redirectUris,webOrigins
done
```

`inventory-web` has three problems. The implicit flow is on (`implicitFlowEnabled: true`), so Keycloak returns tokens in the redirect address. The redirect URIs are `http://localhost:5173/*` and `*`, so codes can go to any address. The web origins are `*`, so any website may read the answers.

`inventory-reporter` has `publicClient: true` and `serviceAccountsEnabled: false`. A public client has nothing to authenticate with, and without a service account there is no identity for a client credentials token.

## Step 2: Fix inventory-web

```sh
WEB_ID=$(kcadm get clients -r inventory -q clientId=inventory-web --fields id --format csv --noquotes | tr -d '\r')
kcadm update "clients/$WEB_ID" -r inventory \
  -s implicitFlowEnabled=false \
  -s 'redirectUris=["http://localhost:5173/callback"]' -s 'webOrigins=["+"]'
```

The client keeps `publicClient: true` and the standard flow.

## Step 3: Fix inventory-reporter

Make the client confidential with the client secret authenticator and a service account, then let Keycloak generate a secret and read it:

```sh
REPORTER_ID=$(kcadm get clients -r inventory -q clientId=inventory-reporter --fields id --format csv --noquotes | tr -d '\r')
kcadm update "clients/$REPORTER_ID" -r inventory \
  -s publicClient=false -s clientAuthenticatorType=client-secret \
  -s serviceAccountsEnabled=true -s standardFlowEnabled=false -s directAccessGrantsEnabled=false
kcadm create "clients/$REPORTER_ID/client-secret" -r inventory
REPORTER_SECRET=$(kcadm get "clients/$REPORTER_ID/client-secret" -r inventory --fields value --format csv --noquotes | tr -d '\r')
```

## Step 4: Prove every fix

Request a token for `inventory-reporter` with the new secret:

```sh
kubectl -n clientscapstone-demo exec deploy/tester -- \
  curl -s -u "inventory-reporter:$REPORTER_SECRET" \
    http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=client_credentials | jq 'keys'
```

The response has an `access_token`. Then save the code flow script as `code-flow.sh`:

```sh
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
```

Run the implicit flow, then the code flow with both origins:

```sh
run_flow() {
  kubectl -n clientscapstone-demo exec -i deploy/tester -- env REALM=inventory CLIENT_ID=inventory-web \
    REDIRECT_URI=http://localhost:5173/callback USERNAME=alice PASSWORD=alice-password "$@" sh -s < code-flow.sh
}
run_flow RESPONSE_TYPE=token PKCE=none | grep -E '^(FORM_FOUND|AUTH_LOCATION)='
run_flow ORIGIN=http://localhost:5173 | grep -E '^(TOKEN_STATUS|ACAO)='
run_flow ORIGIN=http://attacker.example | grep -E '^(TOKEN_STATUS|ACAO)='
```

The implicit request shows `FORM_FOUND=no`; `AUTH_LOCATION` is a redirect to the callback with an `error` parameter instead of a login page. Both code flows end with `TOKEN_STATUS=200`; only the first shows `ACAO=http://localhost:5173`.

## Step 5: Submit

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Keeping `http://localhost:5173/*` and removing only `*` | Any page on the origin can still receive codes; the grader rejects any `*` |
| Turning on direct access grants for `inventory-reporter` | It needs no user; the grader only accepts the client credentials grant |
| Making `inventory-web` confidential | A browser cannot keep its secret |
