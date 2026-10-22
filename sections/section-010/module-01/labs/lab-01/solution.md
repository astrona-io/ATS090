# Solution: Lock Down The Redirect URIs And Web Origins Of A Browser Client

Work the task yourself first. Running `astrona submit -c sections/section-010/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the client settings of `inventory-web`, a full sign-in with the right and a wrong origin, and an authorization request with a redirect URI on another website.

## Step 1: Read the client settings

Define the `kcadm` helper, sign in, and read the settings that decide where codes go and who may read the answers:

```sh
NAMESPACE=clients-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm get clients -r inventory -q clientId=inventory-web \
  --fields clientId,publicClient,standardFlowEnabled,redirectUris,webOrigins
```

The client is public and the standard flow is on, which is right for a single page application. The valid redirect URIs are `["*"]` and the web origins are `["*"]`. The first lets Keycloak send an authorization code to any address; the second lets scripts on any website read Keycloak's answers for this client.

## Step 2: Show the problem

Send an authorization request with a redirect URI on another website, from the `tester` pod:

```sh
kubectl -n clients-demo exec deploy/tester -- sh -c '
  curl -s "http://keycloak:8080/realms/inventory/protocol/openid-connect/auth?client_id=inventory-web&response_type=code&scope=openid&redirect_uri=http%3A%2F%2Fattacker.example%2Fcallback" \
  | grep -c login-actions/authenticate'
```

The count is `1`: Keycloak shows the login page, and after the user signs in it would send the code to `attacker.example`.

## Step 3: Set the exact redirect URI and the web origins

Replace both lists. `+` makes the web origins follow the valid redirect URIs, so the only allowed origin becomes `http://localhost:5173`:

```sh
WEB_ID=$(kcadm get clients -r inventory -q clientId=inventory-web --fields id --format csv --noquotes | tr -d '\r')
kcadm update "clients/$WEB_ID" -r inventory \
  -s 'redirectUris=["http://localhost:5173/callback"]' -s 'webOrigins=["+"]'
kcadm get clients -r inventory -q clientId=inventory-web --fields redirectUris,webOrigins
```

The client now lists one redirect URI, `http://localhost:5173/callback`, and the web origin `+`. Writing `["http://localhost:5173"]` for the web origins works too.

## Step 4: Prove the fix from both sides

Run the request from step 2 again. The count is now `0`: Keycloak answers with an error page about an invalid `redirect_uri` instead of the login page.

Then run a whole sign-in. Save the script below as `code-flow.sh`; it runs the authorization code flow from the `tester` pod and prints one `KEY=VALUE` line per result:

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

Run it with the application's origin and with a foreign one:

```sh
for ORIGIN in http://localhost:5173 http://attacker.example; do
  echo "== $ORIGIN"
  kubectl -n clients-demo exec -i deploy/tester -- env REALM=inventory CLIENT_ID=inventory-web \
    REDIRECT_URI=http://localhost:5173/callback USERNAME=alice PASSWORD=alice-password \
    ORIGIN="$ORIGIN" sh -s < code-flow.sh | grep -E '^(TOKEN_STATUS|ACAO)='
done
```

Both flows end with `TOKEN_STATUS=200`. The first shows `ACAO=http://localhost:5173`; the second shows an empty `ACAO`, so a browser would not hand the tokens to a script on `attacker.example`.

## Step 5: Submit

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| `http://localhost:5173/*` as the redirect URI | Every page on the origin can receive codes; the grader rejects any `*` |
| Making the client confidential | The browser cannot keep the secret, and the code exchange without a secret fails |
| Emptying the web origins | Keycloak issues tokens, but the browser hides them from the application |
| Creating a new, clean client | The application still uses `inventory-web` |

## Practice on your own

- Add a second exact redirect URI for another port and check that `+` now allows both origins.
- Look at the client in the Admin Console and find **Valid redirect URIs** and **Web origins** under **Access settings**.
