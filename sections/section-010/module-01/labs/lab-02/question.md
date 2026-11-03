# Question

Solve this question on: `terminal`

**Time:** about 15 minutes · **Topic:** Clients

## Scenario

The browser application `inventory-web` is a single page application. It signs users in with the authorization code flow and does nothing else. During development the team switched on every flow so that "something would work", and they never switched them off. A security review found that the client also lets a script exchange a password for tokens, that it accepts `response_type=token`, and that its tokens carry every role of the user, including the administrator role `inventory-admin`.

The user `alice` (password `alice-password`) has that role. Keycloak runs in the namespace `clients-demo`, and the application is served from `http://localhost:5173`.

## Your task

In the realm `inventory`:

1. Read the capability settings of `inventory-web` and find which flows are on.
2. Prove with a request that the password grant and the implicit flow are open.
3. Trim the client to the one flow it uses, and stop its tokens from carrying every role of the user.
4. Prove with the same requests that both flows are now refused and that the sign-in page still appears.

## Constraints

- `inventory-web` stays a **public** client, and its **standard flow** stays on.
- Do not change the redirect URIs or the web origins, do not create a client, and do not delete the role or change the user.

## Done when

- `inventory-web` is public, has the standard flow on, and has the implicit flow and direct access grants off.
- A password grant for `alice` with `inventory-web` is answered with the error `unauthorized_client` and no token.
- An authorization request with `response_type=token` shows no login page, and one with `response_type=code` still does.
- `fullScopeAllowed` is `false` for `inventory-web`.
