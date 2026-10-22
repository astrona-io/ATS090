# Question

Solve this question on: `terminal`

**Time:** about 40 minutes · **Topic:** Token propagation

## Scenario

`inventory-gateway` now sits in front of two APIs in the namespace `exchangecapstone-demo`: `inventory-api`, which `alice` already uses, and the new `reporting-api`, which expects the audience `reporting-api` and the realm role `reporting-reader`. The gateway exchanges each user's token for one meant for the API it calls. The setup was started but not finished, and nothing works: not even the exchange for `inventory-api`.

The realm also holds the client `inventory-admin-api`, an internal API the gateway must never reach.

## Your task

In the realm `inventory`:

1. Follow `alice`'s token from `inventory-cli` to an exchange by `inventory-gateway` for `reporting-api`, and find every reason it fails. Each fix may uncover the next reason.
2. Fix Keycloak so that the gateway can exchange `alice`'s token for `reporting-api` and for `inventory-api`, and each API accepts its token.
3. Make sure the gateway cannot get a token for `inventory-admin-api`, and that `alice`'s original token reaches neither API directly.

`alice`'s password is `alice-password`. The gateway's client is `inventory-gateway`, secret `inventory-gateway-secret`. Use the password grant of `inventory-cli` to get `alice`'s token (lab-only; a real application uses the authorization code flow), and send the exchanges from the `tester` pod.

## Constraints

- Do **not** change either API: not the code, and not the `ISSUER`, `AUDIENCE` or `REQUIRED_ROLE` settings.
- Do not add an API's audience to `inventory-cli`'s tokens.
- Give `alice` only the roles the APIs need.

## Done when

- An exchange with `audience=reporting-api` returns a token for `alice` with `azp` `inventory-gateway`, and `reporting-api` returns `200` for it.
- An exchange with `audience=inventory-api` does the same for `inventory-api`.
- An exchange with `audience=inventory-admin-api` does not return a token.
- Both APIs return `401` for `alice`'s original token from `inventory-cli`.
- Both APIs' code and settings are unchanged.
