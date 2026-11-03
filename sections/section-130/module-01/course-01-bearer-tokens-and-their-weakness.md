# Bearer Tokens And Their Weakness

A resource server that receives `Authorization: Bearer <token>` checks the signature, the expiry and the audience. It does not ask who sent the request, because the token itself is the proof. That is simple and it is the weakness.

## Where tokens leak

- Server logs and error reports that print request headers.
- Proxies and monitoring tools that sit in the path.
- Browser storage that a script can read.
- A compromised or stolen device.
- A resource server that is itself compromised and replays the token to another server.

In each case the thief sends the same token from another machine, and the resource server cannot tell the difference.

## The idea of binding

To bind a token, the client proves it holds a **private key**. The authorization server writes a fingerprint of the matching public key into the token, in the `cnf` (confirmation) claim. The resource server then asks two questions:

1. Is the token valid?
2. Does the caller prove it holds the key that the `cnf` claim names?

A thief with only the token fails the second question.

| Binding | The proof is | The `cnf` member |
| --- | --- | --- |
| DPoP | A signed JWT sent in a `DPoP` header with each request | `jkt`, the thumbprint of the public key |
| Mutual TLS | The client certificate used in the TLS handshake | `x5t#S256`, the thumbprint of the certificate |

## What binding does not do

Binding does not stop a thief who controls the client itself, because that thief can use the key. It also does not replace short token lifetimes or scope limits. It removes one important attack, the replay of a copied token.

## Read a token

You can see a `cnf` claim in a token by decoding its middle part. For a plain bearer token there is no `cnf` claim:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=bound-demo
kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=client_credentials -d client_id=legacy-client -d client_secret=legacy-secret \
  | jq -r .access_token | jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson | {azp, cnf, exp}'
```

The token of `legacy-client` has no `cnf`. A bound token has one.

## Common pitfalls

> [!WARNING]
> - **Thinking a short lifetime makes binding unnecessary.** A stolen token works during its whole life.
> - **Thinking binding makes a stolen client safe.** The thief who owns the client owns the key.
> - **Binding tokens and not checking the proof at the resource server.** Both sides are needed.
> - **Logging full tokens.** A bound token is safer, but a log is still not a place for it.
