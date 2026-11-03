# Summary

Dynamic client registration lets other systems create clients. Client policies keep every client within rules, however it was created.

## What you learned

A client can be created in the console or admin API, through the Keycloak or OpenID Connect registration endpoint, or by realm import. A registration request is anonymous, carries an initial access token with a count and an expiration, or carries an account token. Registration policies such as Trusted Hosts, Allowed Client Scopes and Max Clients check those requests. Client profiles hold executors that enforce rules such as PKCE, and client policies attach profiles to conditions. A policy that is not enabled, or a profile that no policy names, enforces nothing.

The key facts to remember are these:

- Prefer an initial access token with a small count and a short life.
- Registration policies cover the registration endpoints only.
- Client policies cover every path, and writes replace the whole custom document.
- Keep the new registration access token after each update.

<!-- astrona:playground:destroy -->
