# Question

Solve this question on: `terminal`

**Time:** about 15 minutes · **Topic:** Token lifetimes

## Scenario

A security review found that the client `inventory-cli` in the realm `inventory` receives access tokens that stay valid for a whole day, and that a refresh token can be used again and again after the client has used it. A copy of either token would give an attacker a long time to act.

Keycloak runs in the namespace `sessions-demo`. The user `alice` has the password `alice-password`.

## Your task

In the realm `inventory`:

1. Read the realm settings for the access token lifespan and for refresh token revocation.
2. Set the access token lifespan to 300 seconds.
3. Turn on refresh token rotation so that every refresh token works once and cannot be reused.
4. Prove it: sign `alice` in with the password grant, refresh once, then use the first refresh token a second time.

## Constraints

- Change the settings on the **realm**. Do not set a client override.
- Keep the maximum reuse count of a refresh token at `0`.
- Do not change the user or the client.

## Done when

- A new access token for `alice` lives 600 seconds or less (`exp` minus `iat`).
- The realm has Revoke Refresh Token on and a maximum reuse of `0`.
- A refresh token answers `200` the first time and a failure status the second time.
