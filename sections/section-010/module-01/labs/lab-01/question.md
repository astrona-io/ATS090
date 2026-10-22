# Question

Solve this question on: `terminal`

**Time:** about 15 minutes · **Topic:** Clients

## Scenario

The team behind the single page application `inventory-web` could not get the sign-in to work on a new laptop, so someone opened the client up "for now". The client `inventory-web` in the realm `inventory` now accepts any redirect URI and any web origin. The sign-in works, and so would a sign-in started by any other website.

The application is served from `http://localhost:5173` and receives the authorization code at `http://localhost:5173/callback`. Keycloak runs in the namespace `clients-demo`.

## Your task

In the realm `inventory`:

1. Find which settings of `inventory-web` let other websites take part in a sign-in.
2. Change them so that Keycloak sends authorization codes only to `http://localhost:5173/callback`, and only the origin `http://localhost:5173` may read Keycloak's answers for this client.
3. Prove that `alice` (password `alice-password`) can still sign in through `inventory-web`, and that a redirect URI on another website is refused.

## Constraints

- **No wildcard** in the valid redirect URIs, and no `*` in the web origins.
- `inventory-web` stays a **public** client with the standard flow on. A browser application cannot keep a client secret.
- Do not create a new client, and do not change `inventory-cli`.

## Done when

- The valid redirect URIs of `inventory-web` contain `http://localhost:5173/callback` and no `*`; its web origins contain no `*`.
- A full authorization code flow for `alice` with redirect URI `http://localhost:5173/callback` ends with tokens, and the token response carries `Access-Control-Allow-Origin: http://localhost:5173`.
- The same flow with the origin `http://attacker.example` gets no `Access-Control-Allow-Origin` header.
- An authorization request with redirect URI `http://attacker.example/callback` gets no login page.
