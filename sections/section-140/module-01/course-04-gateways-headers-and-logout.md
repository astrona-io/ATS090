# Gateways, Headers And Logout

Putting a proxy or a gateway in front of an application adds three topics: what the application is allowed to trust, how the public address affects tokens, and how logout works across the layers.

## Identity headers

A proxy usually passes the user to the application in headers, for example the user name, the email and the groups. The application trusts them, so two rules follow:

1. The proxy must **remove** any identity header that arrives from the outside before it sets its own. If it does not, a caller can send `X-Forwarded-User: admin` and be believed.
2. The application must be reachable **only through the proxy**. A network policy or a private network enforces this.

When the application can validate a token itself, prefer passing the access token and validating it in the application, which does not rely on a header.

## Hostname and issuer behind a proxy

Browsers reach Keycloak at a public address, for example `https://auth.example.com`. The server may sit behind a reverse proxy that ends TLS. Two server settings matter:

- the **hostname** the server presents in tokens and in the discovery document;
- the **proxy headers** setting, so that the server reads `X-Forwarded-*` headers from a trusted proxy.

If these are wrong, the issuer in tokens differs from the issuer that applications expect, redirect addresses use `http` instead of `https`, and sign-in fails with an invalid redirect error. Always compare the `issuer` in the discovery document with the issuer your application is configured with.

Backend calls inside the cluster may use another address from the browser's. Make the application read the discovery document through the public issuer, or set the issuer and the endpoints separately.

## Sessions and refresh

A proxy keeps the user session in a cookie. Large tokens make large cookies, which some proxies and browsers reject. Keep the tokens small by limiting groups and roles in them, or let the proxy keep the session on the server side. The proxy refreshes the access token with the refresh token before it expires if refresh is configured.

## Logout across layers

Logging out has three parts and each must happen:

1. The proxy removes its own session cookie.
2. The browser is sent to the Keycloak end session endpoint, with the ID token as a hint and a post logout redirect address that is registered on the client.
3. Keycloak ends the SSO session, and tells other clients by back-channel logout if configured.

If the proxy clears its cookie and never calls Keycloak, the user is still signed in at Keycloak and the next sign-in is silent. If only Keycloak is logged out, the proxy session stays until its cookie expires.

Find the end session endpoint in the discovery document:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=proxy-demo
kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s http://keycloak:8080/realms/inventory/.well-known/openid-configuration | jq -r .end_session_endpoint
```

## A checklist

1. The client is confidential, with the code flow and an exact redirect address.
2. Tokens carry the audience and the claims the proxy or API checks.
3. The API validates issuer, audience, signature, time and permission.
4. The application is reachable only through the proxy, and the proxy strips identity headers.
5. The issuer in tokens matches the public address.
6. Logout clears the proxy session and the Keycloak session.

## Common pitfalls

> [!WARNING]
> - **Trusting identity headers from outside the proxy.** Strip them at the proxy.
> - **Wrong hostname settings.** The issuer and redirect addresses differ from what applications expect.
> - **Very large tokens.** Cookies become too big; trim the claims.
> - **Clearing only the proxy cookie at logout.** The Keycloak session stays.
