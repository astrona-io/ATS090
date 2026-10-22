# Summary

An API decides on its own whether to trust an access token, with a short list of checks and the realm's public keys. This module followed a token through those checks and fixed Keycloak until the token passed them for the right reasons.

## What you learned

An API checks the signature first, then the issuer (`iss`), the audience (`aud`), the expiry (`exp`) and the type (`typ`), and refuses with `401` when one fails. It then checks the user's roles and refuses with `403` when one is missing. Decoding a token only reads it; the signature check is what proves Keycloak issued it, and a changed token fails it.

The API finds Keycloak's public key in the realm's JSON Web Key Set (JWKS), by the key ID (`kid`) in the token's header. A key rotation adds a key provider with a higher priority; new tokens get the new `kid`, and an API that loads the JWKS again for an unknown `kid` keeps working. The old key stays published until the tokens it signed have expired.

A valid signature proves who issued a token, not who it is for. The `aud` claim says that, and an audience mapper adds an API's client to it. The mapper can sit on one client, or in a client scope that is a default scope of exactly the clients that call the API. Realm roles reach the token through the client scope `roles`, and a token keeps the roles it had when Keycloak issued it. Local validation cannot see a session that ended after the token was issued; token introspection, which needs a confidential client, can. The key facts to remember are these:

- Read the API's log first; it says which check failed.
- `401` means the token is not acceptable; `403` means the user lacks a role.
- Add an API's audience only to the clients that call it.
- Get a new token after every change in Keycloak.

<!-- astrona:playground:destroy -->
