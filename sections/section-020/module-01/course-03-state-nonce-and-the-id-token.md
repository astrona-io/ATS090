# State, Nonce And The ID Token

PKCE protects the code. Two more questions are left for the application: is the redirect it just received the answer to a sign-in it started, and was the ID token it got issued for that same sign-in? The `state` and `nonce` parameters answer them. This part shows where each one comes back and what the application checks in the ID token.

## State: is this my sign-in?

The application puts a random **`state`** value in the authorization request and stores it, for example in the browser's session storage. Keycloak copies it unchanged into the redirect. When the callback page loads, the application compares the two values and stops if they differ.

Without that check, another website could send the user's browser to the application's callback with a code from the attacker's own sign-in. The application would exchange it and sign the user in as the attacker, and anything the user then saved would go into the attacker's account. This attack is called cross-site request forgery (CSRF) on the callback. PKCE also stops it when the application checks that it has a verifier for the flow, but `state` makes the check explicit and cheap.

## Nonce: is this token for this sign-in?

The application also puts a random **`nonce`** in the authorization request. Keycloak does not return it in the redirect. It copies it into the **ID token**, the token that tells the application who the user is. The application checks that the ID token's `nonce` claim equals the value it sent. A token copied from another sign-in carries another nonce, so the application refuses it. This protects against replayed ID tokens.

## Read the ID token

Run a sign-in with both values and decode the ID token. The script below runs the whole flow with PKCE from the `tester` pod and prints one `KEY=VALUE` line per result, including the `NONCE` it sent and the decoded claims of the ID token (`ID_CLAIMS`). The steps are the same ones you can run by hand with `curl`.

<!-- astrona:playground:renew -->

Save this as `code-flow.sh`:

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

Run it and show the state and nonce it sent, the redirect, and the ID token's claims:

```sh
kubectl -n pkce-demo exec -i deploy/tester -- env REALM=inventory CLIENT_ID=inventory-web \
  REDIRECT_URI=http://localhost:5173/callback USERNAME=alice PASSWORD=alice-password \
  sh -s < code-flow.sh > flow-output.txt
grep -E '^(STATE|NONCE|LOGIN_LOCATION|TOKEN_STATUS)=' flow-output.txt
sed -n 's/^ID_CLAIMS=//p' flow-output.txt | jq
```

`LOGIN_LOCATION` contains `state=` with the same value as the `STATE` line: the application's first check passes. The decoded ID token is a JSON object, and its `nonce` claim has the same value as the `NONCE` line: the second check passes.

The ID token has more claims than the nonce, and an application checks several of them before it trusts the token:

| Claim | What the application checks |
| --- | --- |
| `iss` | It is the realm the application uses, here `http://keycloak:8080/realms/inventory` |
| `aud` | It contains the application's own client ID, `inventory-web` |
| `azp` | The client the token was issued to; `inventory-web` |
| `exp`, `iat` | The token has not expired, and was issued just now |
| `nonce` | It equals the value the application sent |
| `typ` | `ID`: this is an ID token, not an access token |
| `sub`, `preferred_username` | Who the user is |

Compare it with the access token from the same response, which is meant for APIs, not for the application:

```sh
sed -n 's/^ACCESS_CLAIMS=//p' flow-output.txt | jq '{typ, azp, aud, scope}'
```

The access token's `typ` is `Bearer`, and its `aud` does not name `inventory-web`. The two tokens have different jobs: the application reads the ID token to learn who signed in, and sends the access token to APIs without reading it.

You now know every value that protects a browser sign-in: the redirect URI decides where the code goes, PKCE ties the code to the application, `state` ties the redirect to the sign-in, and `nonce` ties the ID token to it. Each one is sent at the start and checked at a later step. A library does these checks for you, but when one of them fails, you can now find which.

## Common pitfalls

> [!WARNING]
> - **Using a fixed `state` or `nonce`.** A value that never changes protects nothing. Create new random values for each sign-in.
> - **Sending the ID token to an API.** It is for the application. APIs accept access tokens; an API that checks `typ` refuses an ID token.
> - **Reading user details from the access token in the application.** Use the ID token, or the userinfo endpoint; the access token's contents are for the API.
> - **Skipping the `aud` check of the ID token.** An ID token issued to another client of the same realm also has a valid signature.
