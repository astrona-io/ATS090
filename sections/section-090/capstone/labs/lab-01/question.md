# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** SAML service providers

## Scenario

The SAML client `urn:app:billing` in the realm `inventory` was set up in a hurry. A review found four problems. Any address is accepted as the assertion consumer address. The assertion is not signed. The application expects the user's email as the attribute `email` and gets none. And the application reads the roles from the attribute `Role`, while Keycloak writes them to `role-list`.

Keycloak runs in the namespace `saml-demo`. The application listens at `https://billing.example.com/saml/acs`.

## Your task

In the realm `inventory`:

1. Restrict the valid redirect URIs of the client to the ACS address.
2. Sign the assertion.
3. Add a mapper that writes the user's email address to the attribute `email`.
4. Make the role list mapper write the attribute `Role`.

## Constraints

- Change the existing client. Do not create a new client.
- Do not use a wildcard in the redirect URIs.
- Keep the role list mapper; change it rather than adding a second one.

## Done when

- The only valid redirect URI is `https://billing.example.com/saml/acs`.
- `saml.assertion.signature` is `true`.
- A mapper copies the user property `email` into the attribute `email`.
- The role list mapper writes the attribute `Role`.
