# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Browser sign-in

## Scenario

The single page application `inventory-web` was moved to a new Keycloak in the namespace `pkcecapstone-demo`, and nobody can sign in anymore. The client was recreated by hand from notes. The front-end team reports that "the login page never shows up", and the security team adds that the old client required PKCE with `S256`.

The application is served from `http://localhost:5173`, runs in the browser, and receives codes at `http://localhost:5173/callback`.

## Your task

In the realm `inventory`:

1. Follow a sign-in for `alice` (password `alice-password`) step by step and find every reason it fails.
2. Fix `inventory-web` so the sign-in works the way a single page application must sign in: the authorization code flow with PKCE `S256`, without a client secret.
3. Prove the sign-in works end to end, and that the ID token belongs to it.

## Constraints

- `inventory-web` must be a **public** client: the application runs in the browser and cannot keep a secret.
- The only valid redirect URI is `http://localhost:5173/callback`. No `*`.
- Do not create a new client.

## Done when

- `inventory-web` is public, the standard flow is on, and its redirect URIs contain `http://localhost:5173/callback` and no `*`.
- `pkce.code.challenge.method` is `S256`, and an authorization request without PKCE gets no login page.
- A full authorization code flow with PKCE and no client secret ends with tokens; the ID token names `alice` and carries the request's `nonce`; the token response allows the origin `http://localhost:5173`.
