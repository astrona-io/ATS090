# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** Token validation

## Scenario

After a realm was rebuilt in the namespace `tokenscapstone-demo`, `inventory-api` refuses every token `alice` gets from `inventory-cli`. A first attempt to fix it "gave `alice` admin rights and it still failed", and was rolled back. The API is correct and was not changed.

`alice`'s password is `alice-password`. The API accepts a token from `http://keycloak:8080/realms/inventory` with `inventory-api` in `aud` and the realm role `inventory-reader` in `realm_access.roles`.

## Your task

In the realm `inventory`:

1. Find every reason `inventory-api` refuses `alice`'s tokens. Use the API's log and the token's claims; each fix may uncover the next reason.
2. Fix Keycloak so that `inventory-api` accepts a new token for `alice` from `inventory-cli`.
3. Make sure the token holds only what it needs.

To get a token for `alice` from a terminal, use the password grant of `inventory-cli` (lab-only; a real application uses the authorization code flow).

## Constraints

- Do **not** change `inventory-api`: not its code, and not its `ISSUER`, `AUDIENCE` or `REQUIRED_ROLE` settings.
- Give `alice` only the role the API needs. No roles of the client `realm-management`.
- Tokens of `inventory-reporter` must not carry `inventory-api` in `aud`.

## Done when

- `GET /items` on `inventory-api` with a new access token for `alice` from `inventory-cli` returns `200`.
- That token carries `inventory-api` in `aud` and `inventory-reader` in `realm_access.roles`.
- `alice` has the realm role `inventory-reader` and no `realm-management` roles.
- An access token of `inventory-reporter` does not contain `inventory-api` in `aud`.
- The API's code and settings are unchanged.
