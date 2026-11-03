# Summary

A backend job has no user, so it uses the client credentials grant: it sends its client ID and a credential to the token endpoint and gets an access token for itself. This module followed one service client from its first token request to a replaced secret.

## What you learned

The token response of the client credentials grant has an access token, its lifetime and its type, but no refresh token and no ID token. When the token expires, the client asks again. Keycloak only allows the grant for a confidential client with service accounts turned on, and a client that fails that rule gets `unauthorized_client`.

Turning on service accounts makes Keycloak create a user named `service-account-` plus the client ID. Roles for the client are role mappings on that user, and they reach the token through the client scope `roles`, like for any user. A token keeps the roles it had when it was issued, so every change needs a new token. A service account gets the one role its job needs.

The client proves its identity with one of four methods: client ID and secret, signed JWT, signed JWT with the client secret, or an X509 certificate. A client accepts only the method it is set to, so a correct secret with the wrong method still gives `401`. Regenerating a secret works at once and cuts off the old one unless a rotation policy keeps it valid for a while. The key facts to remember are these:

- Public clients cannot use the client credentials grant.
- Roles of a service client come from its service account user.
- Check `clientAuthenticatorType` before you blame the secret.
- Cache the token until shortly before it expires.

<!-- astrona:playground:destroy -->
