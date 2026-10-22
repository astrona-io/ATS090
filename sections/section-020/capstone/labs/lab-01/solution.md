# Solution: Repair The Login Of A Single Page Application

Work the task yourself first. `astrona submit -c sections/section-020/capstone/labs/lab-01` tells you which checks pass.

The grader checks four things: the client settings, the PKCE attribute, a full sign-in with PKCE and no secret including the ID token's `nonce`, and that a request without PKCE is refused.

## Step 1: Follow the sign-in

Save the code flow script as `code-flow.sh`; it runs each step from the `tester` pod and says how far it got:

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

```sh
run_flow() {
  kubectl -n pkcecapstone-demo exec -i deploy/tester -- env REALM=inventory CLIENT_ID=inventory-web \
    REDIRECT_URI=http://localhost:5173/callback USERNAME=alice PASSWORD=alice-password "$@" sh -s < code-flow.sh \
    | grep -E '^(AUTH_STATUS|AUTH_LOCATION|FORM_FOUND|CODE_FOUND|TOKEN_STATUS|TOKEN_JSON)='
}
run_flow
```

The flow stops at the first step: `FORM_FOUND=no`. Read the client to see why:

```sh
NAMESPACE=pkcecapstone-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
WEB_ID=$(kcadm get clients -r inventory -q clientId=inventory-web --fields id --format csv --noquotes | tr -d '\r')
kcadm get "clients/$WEB_ID" -r inventory --fields publicClient,standardFlowEnabled,redirectUris,attributes \
  | jq '{publicClient, standardFlowEnabled, redirectUris, pkce: .attributes["pkce.code.challenge.method"]}'
```

There are four faults, and they stop the flow at different steps:

| Fault | Where the flow stops |
| --- | --- |
| `standardFlowEnabled: false` | Step 1: Keycloak refuses `response_type=code` for this client |
| Redirect URI `http://localhost:5173/calback` (a typing mistake) | Step 1: the request's `redirect_uri` is not valid, so Keycloak shows an error page |
| `publicClient: false` | Step 4: the exchange without a client secret fails, because Keycloak expects the client to authenticate |
| No PKCE method | Nothing fails, but a stolen code would be enough |

## Step 2: Fix the client

```sh
kcadm update "clients/$WEB_ID" -r inventory \
  -s publicClient=true -s standardFlowEnabled=true \
  -s 'redirectUris=["http://localhost:5173/callback"]' \
  -s 'attributes."pkce.code.challenge.method"=S256'
```

## Step 3: Prove the sign-in

Run the flow again, and check the nonce in the ID token:

```sh
kubectl -n pkcecapstone-demo exec -i deploy/tester -- env REALM=inventory CLIENT_ID=inventory-web \
  REDIRECT_URI=http://localhost:5173/callback USERNAME=alice PASSWORD=alice-password \
  ORIGIN=http://localhost:5173 sh -s < code-flow.sh > flow-output.txt
grep -E '^(NONCE|TOKEN_STATUS|ACAO)=' flow-output.txt
sed -n 's/^ID_CLAIMS=//p' flow-output.txt | jq '{preferred_username, nonce, aud}'
run_flow PKCE=none | grep -E '^(FORM_FOUND|AUTH_LOCATION)='
```

The flow ends with `TOKEN_STATUS=200` and `ACAO=http://localhost:5173`. The ID token's `preferred_username` is `alice` and its `nonce` equals the `NONCE` line. The flow without PKCE shows `FORM_FOUND=no`.

## Step 4: Submit

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Keeping the client confidential and putting the secret in the application | The secret is readable in the browser; the grader requires a public client |
| Adding `http://localhost:5173/*` instead of fixing the typing mistake | Any page on the origin can receive codes; the grader rejects any `*` |
| Fixing the flow but not requiring PKCE | The sign-in works, and a stolen code would work too |
