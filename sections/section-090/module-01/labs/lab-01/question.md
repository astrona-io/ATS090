# Question

Solve this question on: `terminal`

**Time:** about 15 minutes · **Topic:** SAML clients

## Scenario

The billing application is a SAML service provider with the entity ID `urn:app:billing` in the realm `inventory`. Its vendor reports two problems. The application rejects the assertions, because they are not signed. And the application creates a new user on every sign-in, because the name ID changes each time. It expects the user's email address.

Keycloak runs in the namespace `saml-demo`.

## Your task

In the realm `inventory`:

1. Read the attributes of the client `urn:app:billing`.
2. Turn on the signature of the assertion.
3. Set the name ID format to `email`.
4. Read the client back and check both attributes.

## Constraints

- Change the existing client. Do not create a new client.
- Keep `https://billing.example.com/saml/acs` as the only valid redirect URI.
- Do not turn off the response signature.

## Done when

- `saml.assertion.signature` is `true`.
- `saml_name_id_format` is `email`.
- The only valid redirect URI is `https://billing.example.com/saml/acs`.
