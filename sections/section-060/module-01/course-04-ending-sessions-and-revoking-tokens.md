# Ending Sessions And Revoking Tokens

Sooner or later a token has to be stopped before it expires: a laptop is stolen, an employee leaves, or a user signs out. Keycloak can end a session from the user's side, from the client's side and from the administrator's side. This part tries all three, and then looks at what still works afterwards, which is the part that surprises people.

## Revoke one token

The OAuth 2.0 revocation endpoint, `/realms/<realm>/protocol/openid-connect/revoke`, lets a client revoke a token it holds. The request carries the token, a `token_type_hint` and the client ID. Keycloak invalidates the client session behind a refresh token, so that refresh token can no longer be used to get new tokens.

Define the helpers, sign in and revoke the refresh token:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=sessions-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
get_tokens() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- \
    curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=password -d client_id=inventory-cli \
      -d username=alice -d password=alice-password -d scope=openid
}
refresh_status() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- \
    curl -s -o /dev/null -w '%{http_code}\n' http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=refresh_token -d client_id=inventory-cli -d refresh_token="$1"
}
REFRESH=$(get_tokens | jq -r .refresh_token)
kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s -o /dev/null -w '%{http_code}\n' http://keycloak:8080/realms/inventory/protocol/openid-connect/revoke \
    -d client_id=inventory-cli -d token_type_hint=refresh_token -d token="$REFRESH"
refresh_status "$REFRESH"
```

The revocation request answers `200`, and the refresh now prints `400`: the token is dead. The endpoint also answers `200` for a token it does not know, so it never tells an attacker which tokens exist.

## Log out with the refresh token

A client signs a user out of the session with a `POST` to `/realms/<realm>/protocol/openid-connect/logout`, with the client ID and the refresh token. Keycloak ends the session and answers `204`:

```sh
REFRESH=$(get_tokens | jq -r .refresh_token)
kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s -o /dev/null -w '%{http_code}\n' http://keycloak:8080/realms/inventory/protocol/openid-connect/logout \
    -d client_id=inventory-cli -d refresh_token="$REFRESH"
refresh_status "$REFRESH"
```

The first status is `204` and the second is `400`.

## End a session as the administrator

The administrator sees the sessions of a user and can end them all. This is what you do after a stolen laptop:

```sh
ALICE_ID=$(kcadm get users -r inventory -q username=alice -q exact=true --fields id --format csv --noquotes | tr -d '\r')
REFRESH=$(get_tokens | jq -r .refresh_token)
kcadm get "users/$ALICE_ID/sessions" -r inventory --fields id,ipAddress,clients
kcadm create "users/$ALICE_ID/logout" -r inventory
refresh_status "$REFRESH"
```

The first command lists the open session with the clients that use it. After the logout call, the refresh prints `400`. The administrator can also remove one session by its id with `kcadm delete sessions/<id> -r inventory`.

## What still works afterwards

An access token is a signed token that an API checks locally, so ending a session does not change the token that was already issued. An API that checks the signature, issuer, audience and expiry accepts the old access token until its `exp`. Only a call to the introspection endpoint answers that the token is no longer active. This is the reason to keep access tokens short: the time between the end of a session and the end of the last access token is, at most, the access token lifespan.

You have seen all the clocks of a Keycloak token: its own expiry, the idle and max limits of the session, rotation of refresh tokens, offline sessions, and the three ways to end a session. Together they let you answer the question every security review asks: how long can a stolen token be used?

## Common pitfalls

> [!WARNING]
> - **Expecting an API to reject an access token right after logout.** A locally validated token works until `exp`; use short lifespans or introspection.
> - **Revoking an access token to end a session.** Revoke the refresh token, or log out with it.
> - **Reading `200` from the revocation endpoint as proof the token existed.** It answers `200` for unknown tokens too.
> - **Ending one session when the user has several.** List the sessions first, or log the user out everywhere.
