# Overview: Sign Users In With The Authorization Code Flow And PKCE (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, deploys Keycloak, creates a realm with one user and one browser client, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- Namespace **`pkce-demo`** with these workloads:

  | Workload | What it is |
  | --- | --- |
  | `keycloak` | One Keycloak 26.8.1 pod in development mode, behind the Service `keycloak` on port `8080` |
  | `tester` | Client pod with `curl`, `jq` and `openssl`; open a shell in it with `kubectl -n pkce-demo exec -it deploy/tester -- sh` |

- Inside Keycloak, the realm **`inventory`** with the user `alice` (password `alice-password`) and the public client `inventory-web`: standard flow on, valid redirect URI `http://localhost:5173/callback`, web origin `+`, and PKCE not required yet.
- The administrator of the `master` realm is `admin` with the password `admin`. These are lab-only credentials.

Keycloak takes a few minutes to start the first time. When `kubectl -n pkce-demo get pods` shows `keycloak` as `1/1`, it is ready. No application runs at `http://localhost:5173`; every flow stops at Keycloak's redirect, and you read the code from the `Location` header.

## Helpers

Paste the `kcadm` helper once in each new terminal on your machine. It runs Keycloak's administration command-line tool inside the Keycloak pod; sign it in once with the `kcadm config credentials` line, and again when it answers `401`.

```sh
NAMESPACE=pkce-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
```

To run a whole sign-in in one command, save this script as `code-flow.sh`. It prints `KEY=VALUE` lines: `FORM_FOUND`, `CODE_FOUND`, `TOKEN_STATUS`, the `STATE` and `NONCE` it sent, and the decoded `ACCESS_CLAIMS` and `ID_CLAIMS`. `PKCE` can be `S256` (the default), `plain` or `none`, and `SEND_VERIFIER=no` leaves the verifier out of the code exchange.

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

Run it like this:

```sh
kubectl -n pkce-demo exec -i deploy/tester -- env REALM=inventory CLIENT_ID=inventory-web \
  REDIRECT_URI=http://localhost:5173/callback USERNAME=alice PASSWORD=alice-password \
  PKCE=S256 sh -s < code-flow.sh
```

## Practice tasks

- Run `code-flow.sh` with `PKCE=none`, `PKCE=plain` and `PKCE=S256`, before and after you set `pkce.code.challenge.method` to `S256` on `inventory-web`. Predict `FORM_FOUND` for each.
- Run it with `SEND_VERIFIER=no` and read the error in `TOKEN_JSON`.
- In the `tester` shell, change one character of the code verifier before the exchange and read Keycloak's answer.
- Send the authorization request with a `redirect_uri` that differs only by a trailing `/`, and see whether Keycloak accepts it.
- Decode the refresh token the same way as the ID token and compare its `typ` and `exp` with the access token's.
