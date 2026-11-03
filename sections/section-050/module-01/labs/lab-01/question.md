# Question

Solve this question on: `terminal`

**Time:** about 15 minutes · **Topic:** Service accounts

## Scenario

The nightly job of the `inventory-reporter` client must read the inventory API. Since the client was created, the job fails on its first request: Keycloak does not give it a token. A colleague also notes that once a token does arrive, the API will still refuse it, because the token has none of the roles the API checks.

The realm `inventory` runs in the namespace `m2m-demo`. The client `inventory-reporter` has the secret `inventory-reporter-secret`.

## Your task

In the realm `inventory`:

1. Send a token request for `inventory-reporter` with the client credentials grant and read why Keycloak refuses it.
2. Fix the client so the request returns an access token.
3. Give the token the realm role `inventory-reader`, and nothing more.
4. Request a new token and check the roles in it.

## Constraints

- `inventory-reporter` stays a **confidential** client and keeps its secret.
- Do not give the client the role `inventory-admin`.
- Do not create a new client.

## Done when

- A client credentials request for `inventory-reporter` answers `200`.
- The realm roles in the access token include `inventory-reader` and do not include `inventory-admin`.
