# Summary

Every application that talks to Keycloak is a client in a realm, and its settings decide who may use it and how. This module showed the settings that matter most for applications and services.

## What you learned

OAuth 2.0 splits clients by whether they can keep a secret. A public client, such as a single page application or a command-line tool, cannot, so it sends only its client ID. A confidential client, such as a service in a cluster, authenticates at the token endpoint with a client secret, sent in an `Authorization: Basic` header or as form fields, or with a signed JWT. Only a confidential client can use the client credentials grant, through its service account. In the Admin Console, **Client authentication** on means a confidential client.

A browser sign-in, the authorization code flow, sends the authorization code through the front channel: Keycloak redirects the browser to the request's `redirect_uri` with the code. The browser follows any redirect, so Keycloak's check of the valid redirect URIs is the only protection. Keycloak compares the address exactly, unless an entry ends with `*`. An entry that is only `*` sends codes to any website.

A single page application also calls Keycloak from JavaScript, and the browser shows the script the response only when it carries `Access-Control-Allow-Origin` with the page's origin. Keycloak sets that header from the client's web origins. `+` allows the origins of the valid redirect URIs, and `*` allows every website. CORS protects users' browsers, not the token endpoint: `curl` gets the tokens either way. A client also carries capability switches. A flow that is off is refused: the password grant for a client without direct access grants fails with `unauthorized_client`, and `response_type=token` gets no login page when the implicit flow is off. With Full scope allowed on, a token carries every role of the user; off, only the roles in the client's scope mappings. The key facts to remember are these:

- A browser or laptop application is a public client; a server or cluster service is a confidential client.
- List exact redirect URIs, one per callback address; never `*`.
- Use `+` or the exact origin for web origins; never `*`.
- Switch on only the flows the client uses: the standard flow for a browser application. Keep the implicit flow and direct access grants off for it.
- Turn Full scope allowed off, and add the roles a client needs as scope mappings.
- Prove a client's settings with one request that must work and one that must fail.

<!-- astrona:playground:destroy -->
