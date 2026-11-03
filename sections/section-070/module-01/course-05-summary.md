# Summary

A session is the object that every token of a sign-in points to. Ending it stops refreshing, and nothing more: access tokens already issued run until their `exp`.

## What you learned

A session ends by a logout request, by the SSO Session Idle or Max limit, by an administrator, or by disabling the user. A browser application logs out through the `end_session_endpoint` with `id_token_hint` and an optional `post_logout_redirect_uri`, which must match the client's registered post-logout redirect URIs exactly. A back end logs out with a `POST` that carries the client ID and the refresh token and gets `204`.

Keycloak tells other applications through back-channel logout, a server-to-server `POST` of a signed `logout_token`, or through front-channel logout, which uses the browser. Back-channel needs a reachable URL and, with session required on, includes the `sid` claim. Operators list sessions per user or client, delete one session by ID, end all sessions of a user, or call `logout-all` for the realm. The key facts to remember are these:

- Logout stops refresh tokens; access tokens live until they expire.
- Register exact post-logout redirect URIs, never `*`.
- Prefer back-channel logout and validate the logout token.
- Disabling a user also ends sessions and blocks new sign-ins.

<!-- astrona:playground:destroy -->
