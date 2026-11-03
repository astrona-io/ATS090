# Summary

A bearer token is valid in anyone's hands. A sender-constrained token is bound to a key, so a copy of it is not enough.

## What you learned

Keycloak binds tokens in two ways. With DPoP the client sends a signed proof in the `DPoP` header with each request, and the token carries the key thumbprint in `cnf.jkt`. With mutual TLS the token carries the certificate thumbprint in `cnf` as `x5t#S256`, and the TLS handshake is the proof. DPoP is required on a client with the attribute `dpop.bound.access.tokens`, and then a token request without a valid proof is refused. Certificate-bound tokens need HTTPS with client certificates and, behind a proxy, a trusted header.

The key facts to remember are these:

- Binding needs checks at the resource server too.
- A DPoP proof is new for every request and names the method and the URL.
- Certificate authentication and certificate-bound tokens are two settings.
- Roll out client by client, and keep access token lifetimes short.

<!-- astrona:playground:destroy -->
