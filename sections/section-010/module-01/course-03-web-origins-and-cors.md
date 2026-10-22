# Web Origins And CORS

A single page application does not only send the browser to Keycloak. Its JavaScript also calls Keycloak directly, for example to exchange the authorization code for tokens. The browser allows that call only if Keycloak's answer says the application's website may read it. This part shows the setting behind that answer, and what goes wrong when it allows every website.

## Origins and the browser's rule

An **origin** is the scheme, host and port of a web address: `http://localhost:5173` is one origin, and `http://keycloak:8080` is another. A browser runs every page's JavaScript under the page's origin. When that JavaScript calls a different origin, the browser sends the request but hides the response from the script, unless the response carries the header `Access-Control-Allow-Origin` with the script's origin in it. This rule is **Cross-Origin Resource Sharing (CORS)**.

So when `inventory-web`, served from `http://localhost:5173`, posts the authorization code to Keycloak's token endpoint, the browser adds the header `Origin: http://localhost:5173`. Keycloak decides whether to answer with `Access-Control-Allow-Origin: http://localhost:5173`. If it does not, the script never sees the tokens, even though Keycloak issued them.

Keycloak takes that decision from the client's **web origins** setting:

| Value | Meaning |
| --- | --- |
| `http://localhost:5173` | This one origin may read the responses |
| `+` | Every origin of the client's valid redirect URIs may read them; for `inventory-web` that is `http://localhost:5173` |
| `*` | Every website may read them |
| (empty) | No website may read them |

`+` is the usual value for a single page application: you list the exact redirect URIs once, and the web origins follow from them.

## Run a sign-in with an origin

To see the header, you need a real token response, and that means the whole authorization code flow. The script below runs it from the `tester` pod, the way a browser and a single page application would together. It sends the authorization request, posts `alice`'s credentials to the login form, reads the code from Keycloak's redirect, and posts the code to the token endpoint with an `Origin` header. It prints one `KEY=VALUE` line per result. You do not need to read it all now; the steps of the flow get their own module.

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

Run it with the application's own origin, and print the lines that matter here:

```sh
kubectl -n clients-demo exec -i deploy/tester -- env REALM=inventory CLIENT_ID=inventory-web \
  REDIRECT_URI=http://localhost:5173/callback USERNAME=alice PASSWORD=alice-password \
  ORIGIN=http://localhost:5173 sh -s < code-flow.sh | grep -E '^(FORM_FOUND|CODE_FOUND|TOKEN_STATUS|ACAO)='
```

The output shows `FORM_FOUND=yes`, `CODE_FOUND=yes` and `TOKEN_STATUS=200`: Keycloak showed the login page, redirected with a code, and issued tokens. The line `ACAO=http://localhost:5173` is the value of `Access-Control-Allow-Origin` in the token response. A browser would let `inventory-web`'s JavaScript read the tokens.

Now run the same flow with an origin that is not the application's:

```sh
kubectl -n clients-demo exec -i deploy/tester -- env REALM=inventory CLIENT_ID=inventory-web \
  REDIRECT_URI=http://localhost:5173/callback USERNAME=alice PASSWORD=alice-password \
  ORIGIN=http://attacker.example sh -s < code-flow.sh | grep -E '^(TOKEN_STATUS|ACAO)='
```

`TOKEN_STATUS` is still `200`, but `ACAO` is empty: Keycloak left the header out. `curl` ignores CORS, so it still received the tokens. A browser would not hand them to a script running on `http://attacker.example`.

## What CORS does and does not protect

That last result is worth a second look, because it shows what web origins are for. CORS is a rule that browsers enforce for their users. It stops a page on another website from reading Keycloak's answers with the user's browser and the user's Keycloak session. It does not stop a program like `curl` that sends requests on its own, because that program has no user session to misuse.

That is why a web origin of `*` matters. With `*`, Keycloak tells every browser that scripts on any website may read its answers for this client. On its own, that removes one of the two checks that keep a browser sign-in inside the application. Combined with a wildcard redirect URI, it removes both: any website the user visits can run the whole sign-in for `inventory-web` in the user's browser, receive the code and read the tokens, as long as the user is still signed in to Keycloak.

You can now set a browser client's web origins and prove which origins Keycloak allows, with a real token response. The client settings together decide the whole picture: the client type decides who must authenticate, the redirect URIs decide where codes go, and the web origins decide which websites may read the answers.

## Common pitfalls

> [!WARNING]
> - **Setting web origins to `*` to make a CORS error go away.** Add the application's origin, or use `+`, instead.
> - **Leaving web origins empty for a single page application.** Keycloak issues tokens, and the browser hides them from the script. The error appears in the browser console, not in Keycloak.
> - **Expecting CORS to stop `curl`.** CORS protects users' browsers. Only client authentication and the redirect URI check protect the token endpoint itself.
> - **Writing an origin with a path.** An origin is scheme, host and port only: `http://localhost:5173`, not `http://localhost:5173/`.

## Your mission: Lock Down The Redirect URIs And Web Origins Of A Browser Client

You can now read a client's settings, test a redirect URI and test an origin with a real sign-in. The graded lab gives you a realm where `inventory-web` accepts any redirect URI and any origin, and asks you to lock it down to the application's own addresses while the sign-in keeps working.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-090-playground-010-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS090.git -c sections/section-010/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-090-lab-010-01
astrona start ats-090-playground-010-01
```
