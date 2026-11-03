# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Token propagation

## Scenario

The security team approved standard token exchange for the gateway `inventory-gateway`, which calls `inventory-api` for the user `alice`. Someone has set it up, and every exchange fails. In the same change, the gateway was also given the audience of `inventory-admin-api` "for later", and the team wants that gone.

Everything runs in the namespace `exchange-demo`. The gateway's client is a confidential client with the secret `inventory-gateway-secret`. `alice` (password `alice-password`) gets her token from the public client `inventory-cli` with the password grant (lab-only). Send the exchange from the `tester` pod, playing the gateway's part.

## Your task

In the realm `inventory`:

1. Request `alice`'s token from `inventory-cli`, send it to the token endpoint as `inventory-gateway` with `audience=inventory-api`, and read the error.
2. Work out which of the four questions about a failing exchange the error answers, and fix the cause where it is.
3. Find the extra audience on the gateway and remove it.
4. Prove that the exchange now returns a token for `alice` with the audience `inventory-api`, and that an exchange for `inventory-admin-api` is refused.

## Constraints

- Do **not** add `inventory-api` or `inventory-admin-api` to the audience of `inventory-cli`'s tokens.
- Do not make `inventory-cli` confidential, do not create or delete clients, and do not change the user.
- The gateway keeps the capability to exchange and keeps the audience `inventory-api`.

## Done when

- `alice`'s access token from `inventory-cli` names `inventory-gateway` in `aud`, and names neither `inventory-api` nor `inventory-admin-api`.
- An exchange by `inventory-gateway` with `audience=inventory-api` returns a token with `preferred_username` `alice`, `azp` `inventory-gateway` and `inventory-api` in `aud`.
- An exchange without `audience` returns a token that names `inventory-api` and does not name `inventory-admin-api`.
- An exchange with `audience=inventory-admin-api` returns an error and no token.
