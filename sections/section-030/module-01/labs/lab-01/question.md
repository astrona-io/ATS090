# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Token validation

## Scenario

The command-line tool `inventory-cli` lists the stock by calling `inventory-api` with `alice`'s access token. Every call fails with `401`. The API team says the API is correct and will not change it. Two more clients will call `inventory-api` next quarter, so the platform team wants the fix to be reusable: a client scope named `inventory-api-audience`, not a setting copied onto each client.

Keycloak and the API run in the namespace `tokens-demo`. `alice`'s password is `alice-password`.

## Your task

In the realm `inventory`:

1. Find out, from the API's log and from the token, why `inventory-api` refuses `alice`'s tokens.
2. Create the client scope `inventory-api-audience` with an audience mapper that adds the client `inventory-api` to the access token's audience.
3. Make it a default client scope of `inventory-cli`, and of no other client.
4. Prove that `inventory-api` accepts a new token for `alice` from `inventory-cli`.

To get a token for `alice` from a terminal, use the password grant of `inventory-cli` (`grant_type=password`). It is lab-only; a real application uses the authorization code flow.

## Constraints

- Do **not** change `inventory-api`: not its code in the ConfigMap `inventory-api-code`, and not its `ISSUER`, `AUDIENCE` or `REQUIRED_ROLE` settings.
- Do not add the audience to a realm-wide default client scope. Tokens of `inventory-reporter` must not carry `inventory-api` in `aud`.
- Do not change `alice`'s roles.

## Done when

- `GET /items` on `inventory-api` with a new access token for `alice` from `inventory-cli` returns `200`.
- The client scope `inventory-api-audience` exists, holds an audience mapper for `inventory-api`, and is a default client scope of `inventory-cli`.
- An access token of `inventory-reporter` (client credentials grant) does not contain `inventory-api` in `aud`.
- The API's code and settings are unchanged.
