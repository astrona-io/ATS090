# Client Authentication Methods

Whoever holds the client secret can get tokens as the service client. That makes the way a client proves its identity the most important setting of a service client. Keycloak supports four methods, set per client. This part shows the default one in two forms, changes the method on a client to see what a mismatch looks like, and explains when a stronger method is worth the effort.

## Client ID and secret

The default method is **Client Id and Secret**. In the client's settings it is the attribute `clientAuthenticatorType` with the value `client-secret`. The client sends its ID and its secret in one of two places. HTTP Basic authentication is the first, and you have already used it with `curl -u`. The second is the request body, with the form fields `client_id` and `client_secret`. Keycloak accepts both.

Define the helpers, then send the secret in the body instead:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=m2m-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
SYNC_ID=$(kcadm get clients -r inventory -q clientId=inventory-sync --fields id --format csv --noquotes | tr -d '\r')
kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s -o /dev/null -w '%{http_code}\n' http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=client_credentials -d client_id=inventory-sync -d client_secret=inventory-sync-secret
```

The status is `200`. Basic authentication is slightly better in practice, because many HTTP libraries and proxies keep request bodies out of their logs but are less careful with query strings and custom fields. Neither form is safe over plain HTTP: always use HTTPS outside a playground.

## Methods that do not send the secret

A secret is a shared secret: Keycloak and the client both hold it, and it travels with every request. Two methods avoid sending it.

- **Signed JWT** (`client-jwt`) uses a key pair. The client keeps the private key. Keycloak holds the public key, either uploaded on the client's Credentials tab or fetched from a JWKS URL. For each token request the client builds a short JWT, signs it with its private key and sends it as `client_assertion`. The request also carries `client_assertion_type` with the value `urn:ietf:params:oauth:client-assertion-type:jwt-bearer`. The JWT's `iss` and `sub` are the client ID, its `aud` is the realm's token endpoint or issuer, and it has an `exp` and a unique `jti`. In OpenID Connect this method is called `private_key_jwt`.
- **Signed JWT with Client Secret** (`client-secret-jwt`) works the same way, but signs the JWT with the client secret as an HMAC key. The secret does not travel, but Keycloak and the client still share it.

The fourth method, **X509 Certificate** (`client-x509`), authenticates the client with the certificate it presents in a mutual TLS connection. It needs HTTPS with client certificates enabled on Keycloak or on the proxy in front of it, so it is not available in this playground.

| Method | Value of `clientAuthenticatorType` | What the client sends | What Keycloak holds |
| --- | --- | --- | --- |
| Client Id and Secret | `client-secret` | The secret | The secret |
| Signed JWT | `client-jwt` | A JWT signed with its private key | The public key |
| Signed JWT with Client Secret | `client-secret-jwt` | A JWT signed with the secret | The secret |
| X509 Certificate | `client-x509` | A TLS client certificate | The certificate or its subject |

## What a mismatch looks like

A client accepts only the method it is set to. Switch `inventory-sync` to Signed JWT and send the secret as before:

```sh
kcadm update "clients/$SYNC_ID" -r inventory -s clientAuthenticatorType=client-jwt
kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s -u inventory-sync:inventory-sync-secret http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=client_credentials | jq -r .error
```

The error is `unauthorized_client`, with the status `401`. The secret is still right, but the client no longer accepts it. Put the default back and check:

```sh
kcadm update "clients/$SYNC_ID" -r inventory -s clientAuthenticatorType=client-secret
kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s -u inventory-sync:inventory-sync-secret http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=client_credentials | jq -r .token_type
```

The answer is `Bearer` again. So when a client that has a correct secret gets `401`, check `clientAuthenticatorType` before you suspect the secret.

You now know the four ways a client can prove who it is, and how the choice shows up as an error. A stronger method costs key management, so most service clients start with a secret. A secret then needs a plan for the day it leaks or expires, which is the topic of the next part.

## Common pitfalls

> [!WARNING]
> - **Sending a secret over plain HTTP.** Use HTTPS everywhere except in a throwaway playground.
> - **Changing the method on a client in use.** The client stops working until it sends the new kind of proof.
> - **Uploading a private key to Keycloak.** Keycloak needs the public key only; the client keeps the private key.
> - **Choosing `client-secret-jwt` for safety.** Both sides still hold the same secret; use `client-jwt` for a real gain.
