# Choosing How To Secure An Application

There are three common places to do the OpenID Connect work. Each moves the work and the risk to a different place.

## The three options

| Option | Where the sign-in and token checks run | Typical tools |
| --- | --- | --- |
| Library in the application | In the application code | A certified OpenID Connect library for the language or framework |
| Reverse proxy | In a proxy in front of the application | oauth2-proxy, Apache with mod_auth_openidc, an NGINX module |
| Gateway or service mesh | At the edge or beside each service | An API gateway or a mesh with JWT validation |

### Library in the application

The application starts the sign-in, receives the code, exchanges it and keeps the session. It has full control and can use claims directly. Every application repeats the work, and a library bug or a missing check is repeated too. A single-page application cannot keep a secret, so it uses a public client with PKCE. Keycloak publishes a JavaScript library for this case.

### Reverse proxy

The proxy handles the whole browser sign-in and passes the request to the application with identity headers. The application needs no OpenID Connect code. This fits applications you cannot change. The application must trust the headers, so it must only be reachable through the proxy.

### Gateway or mesh

For APIs, the gateway validates the access token and rejects bad requests before they reach a service. It does not sign users in. Services behind it receive requests that already passed the checks, and often also validate the token themselves for defence in depth.

## What Keycloak does in all three

Keycloak provides the same parts in all of them:

- the **discovery document** at `/realms/<realm>/.well-known/openid-configuration`, which lists the endpoints and the issuer;
- the **JWKS endpoint** with the public keys that sign tokens;
- the **token, authorization and logout endpoints**;
- clients, scopes and mappers that decide what the tokens contain.

Read the discovery document of the playground realm:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=proxy-demo
kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s http://keycloak:8080/realms/inventory/.well-known/openid-configuration \
  | jq '{issuer, jwks_uri, token_endpoint, end_session_endpoint}'
```

## How to choose

- Can you change the application? If not, use a proxy.
- Is it an API called by other programs? Validate tokens in the service, with a gateway in front if you have one.
- Is it a browser application with its own login pages and sessions? Use a library, with the code flow and PKCE.
- Do many services share the same rules? A gateway keeps the rules in one place.

## Common pitfalls

> [!WARNING]
> - **Writing your own OpenID Connect client.** Use a maintained, certified library.
> - **Putting a client secret into a single-page application.** Use a public client with PKCE.
> - **Leaving the application reachable around the proxy.** Anyone can then send the identity headers.
> - **Using the access token as proof of identity in the browser.** Read the ID token for identity and use the access token only to call APIs.
