# Summary

Keycloak no longer ships adapters. An application is secured with a standard OpenID Connect library, a reverse proxy or a gateway, and Keycloak provides the endpoints, keys and claims.

## What you learned

A library gives the application full control, a proxy secures applications you cannot change, and a gateway validates tokens for many services. A proxy client is confidential, uses the code flow and has an exact redirect address. The proxy or API usually needs an audience in the token and a groups claim, which come from an audience mapper and a group membership mapper. A resource server checks the signature against cached keys, the issuer, the audience, the time window, the algorithm and the permission. Behind a reverse proxy, the hostname settings decide the issuer, and logout must clear both the proxy session and the Keycloak session.

The key facts to remember are these:

- Use exact redirect addresses and add the audience on purpose.
- Check issuer, audience, signature, time and permission.
- Strip identity headers at the proxy and keep the application behind it.
- The issuer in tokens must match what applications expect.

<!-- astrona:playground:destroy -->
