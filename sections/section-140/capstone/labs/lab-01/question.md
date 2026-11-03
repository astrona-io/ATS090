# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Securing applications

## Scenario

An API gateway protects the service `orders-api` in the realm `inventory`. The gateway signs users in with the client `gateway` and checks four things: the access token's `aud` contains `orders-api`, its `groups` claim contains the user's groups, the token lives at most 5 minutes, and the redirect address is exactly `https://orders.example.com/oauth2/callback`. The review shows that the client does not meet any of them. The user `alice` is in the group `staff`.

Keycloak runs in the namespace `proxy-demo`. The client `gateway` has the secret `gateway-secret`, and for the lab it allows the password grant, so you can get tokens from a terminal. `alice` has the password `alice-password`.

## Your task

In the realm `inventory`:

1. Get an access token for `alice` with the client `gateway`, decode it, and compare it with the four rules.
2. Read the client and its protocol mappers.
3. Fix everything that breaks the rules.
4. Get a new token and read the claims again.

## Constraints

- Do not create a new client or delete `gateway`.
- Do not change the group or the user.
- Keep the password grant on for the lab.

## Done when

- The access token for `alice` has `orders-api` in `aud`.
- The token has a `groups` claim that contains `staff`.
- The token lives 300 seconds or less (`exp` minus `iat`).
- The only redirect address of `gateway` is `https://orders.example.com/oauth2/callback`.
