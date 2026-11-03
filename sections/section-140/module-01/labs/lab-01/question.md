# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Securing applications

## Scenario

A reverse proxy protects an internal application. It signs in users with the Keycloak client `web-proxy` in the realm `inventory`. The proxy accepts a token only if the `aud` claim contains `web-proxy`, and it allows only users whose `groups` claim contains `staff`. The user `alice` is in the group `staff`, but the proxy rejects her tokens.

Keycloak runs in the namespace `proxy-demo`. The client has the secret `web-proxy-secret`, and for the lab it allows the password grant, so you can get tokens from a terminal. `alice` has the password `alice-password`.

## Your task

In the realm `inventory`:

1. Get an access token for `alice` with the client `web-proxy` and decode its payload.
2. Find which claims the proxy needs and are missing.
3. Add what is missing to the client `web-proxy`.
4. Get a new token and read the claims again.

## Constraints

- Keep the redirect address of the client exactly `https://app.example.com/oauth2/callback`.
- Do not change the group or the user.
- Use the claim name `groups` and group names without a path.

## Done when

- The access token for `alice` has `web-proxy` in `aud`.
- The access token has a `groups` claim that contains `staff`.
- The only redirect address of the client is `https://app.example.com/oauth2/callback`.
