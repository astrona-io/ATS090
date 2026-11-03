# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Client policies

## Scenario

The realm `inventory` accepts clients from partners. The rules for every client are: PKCE must be used by public clients, and the password grant must not be used. A profile `partner-baseline` and a policy `partners` exist for this, but tests show that a public client gets no PKCE setting and a client with the password grant can be created.

Keycloak runs in the namespace `reg-demo`. The administrator of the `master` realm is `admin` with the password `admin`.

## Your task

In the realm `inventory`:

1. Read the profile and the policy.
2. Find why neither rule is enforced and fix both.
3. Create test clients through the admin API and through dynamic registration with an initial access token, and check that PKCE is set and the password grant is rejected. Delete the test clients.

## Constraints

- Keep the names `partner-baseline` and `partners`.
- Do not disable the policy or remove its condition.
- Registration of a normal client with an initial access token must keep working.

## Done when

- A new public client has `pkce.code.challenge.method` equal to `S256`.
- The admin API rejects a client with `directAccessGrantsEnabled` true.
- Dynamic registration rejects the password grant.
- Dynamic registration of a normal client returns HTTP 201.
