# Summary

Keycloak plays the identity provider for SAML service providers. It publishes a descriptor, keeps one client per service provider and issues signed XML assertions.

## What you learned

A SAML sign-in moves an `AuthnRequest` and a `Response` through the browser, using the redirect or POST binding. The IdP descriptor at `/realms/<realm>/protocol/saml/descriptor` carries the entity ID, the sign-on addresses and the signing certificate. A SAML client has the SP's entity ID as its client ID, a list of valid ACS addresses and a name ID format of `username`, `email`, `persistent` or `transient`.

Signing is set on the client: `saml.assertion.signature` and `saml.server.signature` for Keycloak's documents, `saml.client.signature` to require signed requests and `saml.encrypt` to encrypt the assertion. Mappers add attributes and the role list, and the logout addresses give single logout. The key facts to remember are these:

- The client ID is the entity ID.
- List exact ACS addresses, never `*`.
- Sign the assertion or the response, preferably both.
- Import the descriptor again after a key rotation.

<!-- astrona:playground:destroy -->
