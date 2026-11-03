# Mutual TLS And Certificate-Bound Tokens

Mutual TLS, or mTLS, binds a token to the **client certificate** used in the TLS connection. This is described in RFC 8705. It needs HTTPS with client certificates, so the playground, which uses plain HTTP, cannot run it. This part is for reading and for knowing which settings exist.

## Two different uses of certificates

| Use | What it does | Client setting |
| --- | --- | --- |
| Client authentication | The client proves who it is at the token endpoint with its certificate, not a secret | Client authenticator `X509 Certificate` |
| Certificate-bound tokens | The token carries the thumbprint of the certificate, `x5t#S256` in `cnf` | `tls.client.certificate.bound.access.tokens` set to `true` |

They are separate. A client can authenticate with a secret and still receive certificate-bound tokens, or use both.

## What the server needs

- **HTTPS** with a certificate for the server.
- **Client certificate requests** turned on: the server option `--https-client-auth` set to `request` or `required`, and a truststore with the certificate authorities that sign client certificates.
- If a **reverse proxy** ends TLS, the proxy must pass the client certificate to Keycloak in a header, and Keycloak must be set to trust that proxy and read the header. A proxy that does not pass the certificate makes every bound token request fail.

## The flow

1. The client opens a TLS connection to the token endpoint with its certificate.
2. Keycloak issues an access token whose `cnf` holds `x5t#S256`.
3. The client calls the resource server over mTLS with the same certificate.
4. The resource server compares the thumbprint of the certificate in the connection with `cnf`.

No extra header is needed. The TLS handshake is the proof.

## Client setting

```sh
kcadm update "clients/$CLIENT_ID" -r inventory -s 'attributes."tls.client.certificate.bound.access.tokens"=true'
```

On a server without client certificates, a token request for such a client fails, because Keycloak finds no certificate to bind. Do not turn this on in a plain HTTP playground except to see that error.

## Where mTLS fits

mTLS fits service-to-service calls inside a platform where a mesh or a gateway already manages certificates. It does not fit browser applications, where users have no client certificates, and it is awkward where a proxy ends TLS in a way you do not control.

## Common pitfalls

> [!WARNING]
> - **Confusing certificate authentication with certificate-bound tokens.** They are two settings.
> - **A proxy that drops the client certificate.** The bound request fails or, worse, binds the proxy's certificate.
> - **Trusting a certificate header from anyone.** Only a trusted proxy may set it.
> - **Forgetting certificate renewal.** A new certificate has a new thumbprint, so old tokens stop matching.
