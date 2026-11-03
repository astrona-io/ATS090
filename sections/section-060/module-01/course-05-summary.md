# Summary

Every token a client holds has a lifetime, and behind the refresh token stands a session with its own clocks. This module read each setting, changed it and checked the effect in a real token.

## What you learned

The access token lifespan of the realm is 300 seconds by default, and a client attribute can override it for one client. A token states its own lifetime with `iat` and `exp`, so the surest check is to decode a new token. The SSO session has an idle limit and a maximum, and the refresh token expires with the session.

The refresh token grant gives a client a new access token without a new sign-in. By default a refresh token can be used again after it was used. Revoke Refresh Token turns on rotation: each refresh token works once, and a second use fails with `invalid_grant`. The setting for the number of allowed reuses stays at 0 unless a client loses responses.

An offline token is a refresh token that is stored in an offline session, outside the SSO session. A client gets one with the scope `offline_access`, if the client has that optional scope and the user has the `offline_access` role. Its lifetime is the offline session idle time, 30 days by default. A session ends by revoking the refresh token, by logging out with it, or by an administrator. An API that checks tokens locally still accepts an access token until it expires. The key facts to remember are these:

- Decode a new token to see its real lifetime.
- Rotation makes each refresh token work once.
- Offline tokens need the scope on the client and the role on the user.
- Ending a session does not stop an access token that was already issued.

<!-- astrona:playground:destroy -->
