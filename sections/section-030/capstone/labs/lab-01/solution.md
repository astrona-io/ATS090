# Solution: Make An API Accept The Right Tokens

Work the task yourself first. `astrona submit -c sections/section-030/capstone/labs/lab-01` tells you which checks pass.

The grader checks five things: the API accepts `alice`'s token, the token's audience and role, `alice`'s role mappings, that `inventory-reporter`'s tokens stay without the audience, and that the API was not changed.

## Step 1: Set up the helpers and read the first reason

```sh
NAMESPACE=tokenscapstone-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
get_alice_token() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- sh -c '
    curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=password -d client_id=inventory-cli \
      -d username=alice -d password=alice-password -d scope=openid \
    | jq -r .access_token'
}
call_api() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- \
    curl -s -w '\nHTTP %{http_code}\n' -H "Authorization: Bearer $1" http://inventory-api:8080/items
}
check() {
  TOKEN=$(get_alice_token)
  printf '%s' "$TOKEN" | jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson | {aud, realm_access}'
  call_api "$TOKEN"
  kubectl -n "$NAMESPACE" logs deploy/inventory-api --tail=1
}
check
```

The API answers `401` because `aud` lacks `inventory-api`. The decoded token also has no `realm_access` at all, which will matter after the first fix.

## Step 2: Add the audience to inventory-cli

```sh
CLI_ID=$(kcadm get clients -r inventory -q clientId=inventory-cli --fields id --format csv --noquotes | tr -d '\r')
kcadm create "clients/$CLI_ID/protocol-mappers/models" -r inventory \
  -s name=audience-inventory-api -s protocol=openid-connect -s protocolMapper=oidc-audience-mapper \
  -s 'config."included.client.audience"=inventory-api' \
  -s 'config."access.token.claim"=true' -s 'config."id.token.claim"=false' \
  -s 'config."introspection.token.claim"=true'
check
```

The audience is now right, and the API answers `403`: the realm role `inventory-reader` is missing from the token.

## Step 3: Find why the role is missing

A role is missing from a token for one of two reasons: the user does not have it, or the client does not use the client scope that writes roles into tokens. Check both:

```sh
kcadm get-roles -r inventory --uusername alice --fields name
kcadm get "clients/$CLI_ID/default-client-scopes" -r inventory --fields name
```

`alice` does not have `inventory-reader`, and `roles` is missing from the default client scopes of `inventory-cli`. Both are faults. Without the `roles` scope, even the right role would never reach the token, which is why giving `alice` more roles did not help before.

## Step 4: Fix both

```sh
kcadm add-roles -r inventory --uusername alice --rolename inventory-reader
ROLES_SCOPE_ID=$(kcadm get client-scopes -r inventory --fields id,name --format csv --noquotes \
  | tr -d '\r' | awk -F, '$2 == "roles" {print $1}')
kcadm update "clients/$CLI_ID/default-client-scopes/$ROLES_SCOPE_ID" -r inventory
check
```

The token now carries `realm_access.roles` with `inventory-reader`, and the API answers `200`.

## Step 5: Submit

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Giving `alice` the `realm-admin` role | Still `403`: without the `roles` scope no role reaches the token; and the grader rejects `realm-management` roles |
| Setting `REQUIRED_ROLE` on the API to empty | The API now accepts any user; the grader rejects any change to the API |
| Adding the audience mapper to the realm's `roles` scope | Every client gets the audience, including `inventory-reporter` |
