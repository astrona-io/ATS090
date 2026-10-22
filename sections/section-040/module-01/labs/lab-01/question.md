# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Token propagation

## Scenario

`inventory-cli` sends `alice`'s requests through `inventory-gateway`, which calls `inventory-api`. `alice`'s token is meant for the gateway, so `inventory-api` refuses it. The security team does not want the API's audience in `inventory-cli`'s tokens, because then the client could bypass the gateway. The gateway must exchange the token for one meant for the API.

Everything runs in the namespace `exchange-demo`. The gateway's client is `inventory-gateway`, a confidential client with the secret `inventory-gateway-secret`. `alice`'s password is `alice-password`.

## Your task

In the realm `inventory`:

1. Allow `inventory-gateway` to use standard token exchange.
2. Make the audience `inventory-api` available to `inventory-gateway`, and to no other client.
3. Prove that `inventory-gateway` can exchange `alice`'s token for one with the audience `inventory-api`, and that `inventory-api` accepts the new token.
4. Prove that `inventory-api` still refuses `alice`'s original token.

To get a token for `alice` from a terminal, use the password grant of `inventory-cli` (lab-only; a real application uses the authorization code flow). Send the exchange from the `tester` pod, playing the gateway's part.

## Constraints

- Do **not** add `inventory-api` to the audience of `inventory-cli`'s tokens.
- Do **not** change `inventory-api`: not its code, and not its `ISSUER`, `AUDIENCE` or `REQUIRED_ROLE` settings.
- Do not make `inventory-cli` confidential, and do not create new clients.

## Done when

- A token exchange by `inventory-gateway` with `alice`'s access token as `subject_token` and `audience=inventory-api` returns `200`, and the new token names `alice`, has `azp` `inventory-gateway` and has `inventory-api` in `aud`.
- `inventory-api` returns `200` for the exchanged token.
- `inventory-api` returns `401` for `alice`'s original token from `inventory-cli`.
- The API's code and settings are unchanged.
