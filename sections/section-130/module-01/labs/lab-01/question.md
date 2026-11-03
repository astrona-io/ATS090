# Question

Solve this question on: `terminal`

**Time:** about 15 minutes · **Topic:** DPoP

## Scenario

The client `payments-client` in the realm `inventory` calls a payments API with client credentials. Its access tokens are plain bearer tokens, so a copy of a leaked token works from any machine. Security wants them bound to the client's key with DPoP. A second client, `legacy-client`, belongs to old software that cannot send DPoP proofs.

Keycloak runs in the namespace `bound-demo`. The administrator of the `master` realm is `admin` with the password `admin`.

## Your task

In the realm `inventory`:

1. Request a token with client credentials for `payments-client` and for `legacy-client`, without a proof, and note the HTTP status of each.
2. Require DPoP-bound access tokens on `payments-client`.
3. Request a token for each client again.

## Constraints

- Do not change `legacy-client`.
- Do not change the secrets of the clients.

## Done when

- A token request for `payments-client` without a DPoP proof is refused.
- A token request for `legacy-client` still returns a token.
- The attribute `dpop.bound.access.tokens` on `payments-client` is `true`.
