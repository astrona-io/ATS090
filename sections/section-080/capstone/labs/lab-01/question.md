# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Client scopes, mappers and roles

## Scenario

A partner API trusts the access tokens of the client `inventory-cli` in the realm `inventory` and reads three things: the user's groups, the roles, and a claim `audit`. Its developers report three problems. The `groups` claim is missing from access tokens. Tokens carry the role `inventory-admin`, although this client should only act as a reader. And the `audit` claim is missing, because the API cannot send an extra scope parameter.

Keycloak runs in the namespace `scopes-demo`. The user `alice` has the password `alice-password` and holds the roles `inventory-reader` and `inventory-admin`.

## Your task

In the realm `inventory`:

1. Find out why the `groups` mapper of `inventory-cli` does not write into the access token and fix it.
2. Limit the roles in the tokens of `inventory-cli` to `inventory-reader`.
3. Make the client scope `inventory-audit` apply to every token request of `inventory-cli`, without a scope parameter.

## Constraints

- Do not remove any role from the user `alice`.
- Do not delete the client scope `inventory-audit` or the client.
- Keep `inventory-reader` in the token.

## Done when

- The access token for `alice`, requested with the scope `openid`, has `groups` containing `logistics`.
- The access token holds `inventory-reader` and not `inventory-admin`.
- The access token has the claim `audit` with the value `true`.
