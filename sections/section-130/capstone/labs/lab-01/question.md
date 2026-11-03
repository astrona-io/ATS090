# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** DPoP

## Scenario

The realm `inventory` serves a payments platform. The client `payments-client` must issue DPoP-bound access tokens that live at most 5 minutes. The client `partner-client` belongs to an outside partner whose software cannot send DPoP proofs, so it must keep getting plain bearer tokens. A review found three mistakes in the current settings.

Keycloak runs in the namespace `bound-demo`. The administrator of the `master` realm is `admin` with the password `admin`.

## Your task

In the realm `inventory`:

1. Read the attributes of `payments-client` and `partner-client`.
2. Request a token for each client without a proof and note the status.
3. Fix the settings so that both clients behave as described.
4. Request a token for each client again.

## Constraints

- Do not delete or recreate the clients.
- Do not change the secrets of the clients.

## Done when

- A token request for `payments-client` without a DPoP proof is refused.
- A token request for `partner-client` returns a token.
- The attribute `access.token.lifespan` on `payments-client` is 300 or less.
