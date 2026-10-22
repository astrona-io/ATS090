# Summary

A browser sign-in is a short series of requests, and each of them carries a value that a later step checks. This module ran the series by hand and added the protections a public client needs.

## What you learned

The authorization code flow has four requests. The authorization request sends the client ID, the redirect URI and `response_type=code`, and Keycloak shows the login page. The login form post checks the user. Keycloak then redirects the browser to the redirect URI with a short-lived, one-time authorization code. The application exchanges the code at the token endpoint, with the same redirect URI, and gets an access token, an ID token and a refresh token. The first three requests pass through the browser, the front channel, and the code exchange is a direct request, the back channel.

A public client has no secret, so the code alone would be enough to get tokens. Proof Key for Code Exchange (PKCE) fixes that. The application sends the SHA-256 hash of a random code verifier as the code challenge, with `code_challenge_method=S256`, and sends the verifier itself with the code. Keycloak refuses an exchange without the right verifier, and a code is used up after one exchange, even a failed one. The client attribute `pkce.code.challenge.method` set to `S256` makes Keycloak refuse every authorization request without PKCE, and every request with the weaker method `plain`.

Two more values protect the application. Keycloak copies `state` into the redirect, so the application can check that the redirect answers its own sign-in. Keycloak copies `nonce` into the ID token, so the application can check that the token belongs to this sign-in. The application also checks the ID token's `iss`, `aud`, `exp` and `typ`. The key facts to remember are these:

- A code works once, for about a minute, and only with the redirect URI it was issued for.
- Set `pkce.code.challenge.method` to `S256` on every public browser client.
- `state` comes back in the redirect; `nonce` comes back in the ID token.
- The ID token is for the application; the access token is for APIs.

<!-- astrona:playground:destroy -->
