# Roles In Tokens And Token Introspection

A token with the right signature, issuer and audience proves that a signed-in user's client asked for this API. It does not yet prove that this user may use it. The last check in the API's list reads the user's roles from the token. This part shows where those roles come from, what the API answers when one is missing, and the case where checking the token locally is not enough.

## Where the roles in a token come from

A **realm role** is a role defined in the realm, such as `inventory-reader`, that you give to users. Keycloak writes a user's realm roles into the access token's `realm_access.roles` claim. Two settings decide whether a role arrives there: the user must have the role, and the client must use the client scope `roles`, the default client scope whose mappers write `realm_access` and `resource_access`.

Define the helpers again if this is a new terminal. The commands below need the audience mapper on `inventory-cli` in place, so that tokens pass the audience check:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=tokens-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
get_alice_token() {
  kubectl -n tokens-demo exec deploy/tester -- sh -c '
    curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=password -d client_id=inventory-cli \
      -d username=alice -d password=alice-password -d scope=openid \
    | jq -r .access_token'
}
call_api() {
  kubectl -n tokens-demo exec deploy/tester -- \
    curl -s -w '\nHTTP %{http_code}\n' -H "Authorization: Bearer $1" http://inventory-api:8080/items
}
```

Take the role away from `alice`, get a new token and call the API:

```sh
kcadm remove-roles -r inventory --uusername alice --rolename inventory-reader
TOKEN=$(get_alice_token)
printf '%s' "$TOKEN" | jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson | .realm_access'
call_api "$TOKEN"
```

`realm_access.roles` no longer lists `inventory-reader`, and the API answers `HTTP 403` with the error `insufficient_role`. The token is valid; the user is not allowed. Give the role back and check that a new token passes:

```sh
kcadm add-roles -r inventory --uusername alice --rolename inventory-reader
call_api "$(get_alice_token)"
```

The API answers `HTTP 200` again. Notice that the token from before the change still lists whatever roles `alice` had when Keycloak issued it. A token is a snapshot: role changes reach the API with the next token.

## Local validation and its blind spot

That snapshot is the price of checking tokens locally. The API never asks Keycloak, so it cannot know that something changed after the token was issued: a role removed, a user disabled, a session ended. The token stays acceptable until its `exp`, which is five minutes after issue with Keycloak's default access token lifespan.

**Token introspection**, defined in RFC 7662, is the other way. The API sends the token to Keycloak's introspection endpoint, `/realms/<realm>/protocol/openid-connect/token/introspect`, and Keycloak answers whether it is still active. Only a confidential client may introspect, because the endpoint needs client authentication. Introspect a fresh token as `inventory-reporter`:

```sh
TOKEN=$(get_alice_token)
introspect() {
  kubectl -n tokens-demo exec deploy/tester -- sh -c '
    curl -s -u inventory-reporter:inventory-reporter-secret \
      http://keycloak:8080/realms/inventory/protocol/openid-connect/token/introspect \
      --data-urlencode token="$1" | jq "{active, username, aud}"' sh "$1"
}
introspect "$TOKEN"
```

Keycloak answers `active: true` with the user name and the audience. Now end `alice`'s sessions, as an administrator would after a stolen laptop, and ask both ways again:

```sh
ALICE_ID=$(kcadm get users -r inventory -q username=alice -q exact=true --fields id --format csv --noquotes | tr -d '\r')
kcadm create "users/$ALICE_ID/logout" -r inventory
introspect "$TOKEN"
call_api "$TOKEN"
```

Introspection now says `active: false`: the session behind the token is gone. The API, which validates locally, still answers `HTTP 200` with the same token, and will until the token expires.

| | Local validation | Introspection |
| --- | --- | --- |
| Request to Keycloak per call | No | Yes |
| Sees a revoked session or disabled user | No, until `exp` | Yes, at once |
| Needs | The JWKS | A confidential client's credentials |
| Good for | Most APIs, with short token lifespans | APIs where a revoked token must stop at once |

Most APIs validate locally and keep access tokens short-lived. An API that handles money or personal data, or that must react to a stolen session at once, introspects, or caches introspection results for a few seconds.

You now know every check an API runs on a token, which setting in Keycloak each one depends on, and when local validation is not enough. The fix for a refused token is almost always one of them: the audience, the user's roles, the client's scopes, or a token that is simply too old.

## Common pitfalls

> [!WARNING]
> - **Testing a role change with an old token.** The token keeps the roles from the moment it was issued. Get a new one.
> - **Removing the `roles` client scope from a client.** Tokens then have no `realm_access`, and every role check fails with `403`.
> - **Giving users administration roles to make a `403` go away.** Give the one role the API checks.
> - **Introspecting with a public client.** The endpoint needs client authentication; use a confidential client.
