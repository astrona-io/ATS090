# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Token lifetimes

## Scenario

The mobile team uses the client `inventory-cli` in the realm `inventory`. Their field application must keep working for a week when a worker is offline, but a review of the realm found four problems. Access tokens of the client live a day. Refresh tokens can be reused after use. The client can no longer get an offline token. And the realm drops offline sessions after one minute without use.

Keycloak runs in the namespace `sessions-demo`. The user `alice` has the password `alice-password`.

## Your task

In the realm `inventory`:

1. Find out why access tokens of `inventory-cli` live a day, although the realm uses its default lifespan, and fix it.
2. Make every refresh token work once.
3. Make `inventory-cli` able to get an offline token again with the scope `offline_access`.
4. Let an offline session stay valid for at least seven days without use.

## Constraints

- Do not raise the realm access token lifespan above 600 seconds.
- Keep the maximum reuse count of a refresh token at `0`.
- Do not create new clients and do not change the user.

## Done when

- A new access token for `alice` lives 600 seconds or less.
- A refresh token answers `200` once and a failure status the second time.
- A sign-in with the scope `offline_access` returns a refresh token of the type `Offline`.
- `offlineSessionIdleTimeout` is at least `604800`.
