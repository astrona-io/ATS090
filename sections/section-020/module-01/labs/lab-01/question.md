# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Browser sign-in

## Scenario

The single page application `inventory-web` in the realm `inventory` (namespace `pkce-demo`) is a public client. An earlier administrator turned on PKCE for it, but chose the method `plain`, "because it was easier to debug". With `plain`, the code challenge is the code verifier itself, so anyone who reads the authorization request in the browser's history can also exchange the code.

## Your task

In the realm `inventory`:

1. Make Keycloak require PKCE with the method `S256` for `inventory-web`.
2. Prove that a full sign-in for `alice` (password `alice-password`) with an `S256` code challenge ends with tokens, and that the code is not enough without its verifier.
3. Prove that Keycloak refuses an authorization request without PKCE, and one with the method `plain`.

The application receives codes at `http://localhost:5173/callback`. No application runs there; read the code from Keycloak's redirect.

## Constraints

- `inventory-web` stays a **public** client with the standard flow on and the redirect URI `http://localhost:5173/callback`.
- Do not create a new client.

## Done when

- The client attribute `pkce.code.challenge.method` of `inventory-web` is `S256`.
- A full authorization code flow with an `S256` challenge and its verifier ends with tokens; the same flow without the verifier in the code exchange does not.
- An authorization request without `code_challenge` gets no login page.
- An authorization request with `code_challenge_method=plain` gets no login page.
