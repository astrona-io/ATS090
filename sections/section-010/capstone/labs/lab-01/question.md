# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Clients

## Scenario

A security review of the realm `inventory` in the namespace `clientscapstone-demo` found two clients that do not do what their teams think:

- `inventory-web`, the single page application served from `http://localhost:5173`, was set up from an old template. The reviewer says "any website can take part in its sign-in, and some sign-ins put tokens in the browser's address bar".
- `inventory-reporter`, a background service with no user, cannot get a token at all. Its team says "it worked on the old server".

## Your task

In the realm `inventory`:

1. Find every setting of `inventory-web` that lets another website take part in a sign-in, or that returns tokens in the address. Fix them so the application signs in only through the authorization code flow, with codes sent only to `http://localhost:5173/callback` and answers readable only by `http://localhost:5173`.
2. Find why `inventory-reporter` cannot get a token with the client credentials grant, and fix it so it authenticates with a client secret.
3. Prove both clients work, and prove that the refused requests are refused.

## Constraints

- `inventory-web` stays a **public** client. No `*` in its redirect URIs or web origins.
- `inventory-reporter` must use the **client credentials grant** with a **client secret**. Do not turn on the standard flow or direct access grants for it.
- Do not create new clients, and do not change `inventory-cli`.

## Done when

- `inventory-web` is public, the standard flow is on, the implicit flow is off, its redirect URIs contain `http://localhost:5173/callback` and no `*`, and its web origins contain no `*`.
- An authorization request for `inventory-web` with `response_type=token` gets no login page.
- A full authorization code flow for `alice` (password `alice-password`) ends with tokens, `Access-Control-Allow-Origin` is `http://localhost:5173`, and it is absent for the origin `http://attacker.example`.
- `inventory-reporter` gets a token with the client credentials grant and its current client secret.
