# Validating Tokens In A Resource Server

An API receives an access token and must decide whether to trust it. The decision is a short list of checks. Missing one of them is a real vulnerability.

## The checks

| Check | What it prevents |
| --- | --- |
| Signature, with the public key from the JWKS endpoint | A forged token |
| `iss` equals the expected issuer | A token from another realm or server |
| `aud` contains this API | A token meant for a different API |
| `exp` and `nbf` in the valid time window | An expired or not yet valid token |
| Scope or role needed for the operation | A valid token without the right to do this |
| Algorithm is the one you expect | A token that claims `none` or a weak algorithm |

Use a maintained JWT library and turn on each check. A library that checks only the signature accepts any token from any realm that uses the same server.

## Public keys

The JWKS endpoint lists the signing keys, each with a `kid`:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=proxy-demo
kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/certs \
  | jq '.keys[] | {kid, alg, use}'
```

Fetch the keys once and cache them. When a token arrives with a `kid` you do not know, fetch the list again, because the realm may have rotated its keys. Do not fetch the list for every request.

## Local validation or introspection

| Method | How | Trade-off |
| --- | --- | --- |
| Local validation | The API checks the JWT itself with cached keys | Fast and no call to Keycloak, but a revoked token is accepted until it expires |
| Introspection | The API sends the token to the introspection endpoint | Sees revocation at once, but costs a call per request and needs client credentials |

Use short access token lifetimes with local validation. Use introspection where immediate revocation matters, and consider caching its answer for a few seconds.

## Audience and scope design

An API should accept a token only if `aud` names it. Keycloak adds the audience when you use an audience mapper, or automatically from client roles through the roles scope. Tokens for the browser client are not automatically meant for an API; add the API as an audience on purpose.

Map the permissions to something the API reads: a `scope` value, a realm or client role, or a custom claim. Keep the names the same on both sides.

## Issuer

The `iss` value in a token is the URL that the client used to reach Keycloak, set by the hostname options of the server. If the API expects `https://auth.example.com/realms/inventory` and the token says `http://keycloak:8080/realms/inventory`, every token is rejected. The playground reaches Keycloak at `http://keycloak:8080`, so that is its issuer.

## Your mission: Make Tokens Acceptable To A Proxy Lab

The mission starts from a proxy client whose tokens lack the audience and the groups that the proxy checks. You add both mappers and read the tokens.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-090-playground-140-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS090.git -c sections/section-140/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-140/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-090-lab-140-01
astrona start ats-090-playground-140-01
```

## Common pitfalls

> [!WARNING]
> - **Checking only the signature.** Also check issuer, audience, time and permission.
> - **Fetching the JWKS for every request.** Cache it and refresh on an unknown `kid`.
> - **Accepting any `alg`.** Pin the algorithms you expect.
> - **Treating an ID token as an access token.** The ID token is for the client, not for an API.
