# Question

Solve this question on: `terminal`

**Time:** about 15 minutes · **Topic:** Client policies

## Scenario

The realm `inventory` has the client profile `strict-public`, which requires PKCE, and the client policy `public-clients`, which should apply it to every client. A new public client is not set to S256, so the control does nothing.

Keycloak runs in the namespace `reg-demo`. The administrator of the `master` realm is `admin` with the password `admin`.

## Your task

In the realm `inventory`:

1. Read the profile and the policy with the admin API.
2. Create a public client and read its `pkce.code.challenge.method` attribute. Delete the test client.
3. Find why the profile is not applied and fix it.
4. Repeat the test and read the attribute again.

## Constraints

- Do not remove the profile or change its executor.
- Do not remove the condition from the policy.
- Dynamic registration with an initial access token must keep working.

## Done when

- A new public client gets `pkce.code.challenge.method` equal to `S256`.
- Registration of a normal client with an initial access token returns HTTP 201.
- The client policy is enabled.
