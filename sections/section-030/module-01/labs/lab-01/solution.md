# Solution: Add The API Audience With A Client Scope

Work the task yourself first. Running `astrona submit -c sections/section-030/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: the API accepts `alice`'s token, the client scope and its mapper, that `inventory-reporter`'s tokens stay without the audience, and that the API was not changed.

## Step 1: Read why the API refuses the token

```sh
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
TOKEN=$(get_alice_token)
call_api "$TOKEN"
kubectl -n tokens-demo logs deploy/inventory-api --tail=1
printf '%s' "$TOKEN" | jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson | {iss, aud, azp, realm_access}'
```

The API answers `401`, and its log says the token's `aud` does not include `inventory-api`. The token's `iss` and `realm_access` are right; only the audience is missing.

## Step 2: Create the client scope and its mapper

```sh
NAMESPACE=tokens-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm create client-scopes -r inventory -s name=inventory-api-audience \
  -s protocol=openid-connect -s 'attributes."include.in.token.scope"=false'
SCOPE_ID=$(kcadm get client-scopes -r inventory --fields id,name --format csv --noquotes \
  | tr -d '\r' | awk -F, '$2 == "inventory-api-audience" {print $1}')
kcadm create "client-scopes/$SCOPE_ID/protocol-mappers/models" -r inventory \
  -s name=audience-inventory-api -s protocol=openid-connect -s protocolMapper=oidc-audience-mapper \
  -s 'config."included.client.audience"=inventory-api' \
  -s 'config."access.token.claim"=true' -s 'config."id.token.claim"=false' \
  -s 'config."introspection.token.claim"=true'
```

`include.in.token.scope` set to `false` keeps the scope's name out of the token's `scope` claim; the scope only adds the audience.

## Step 3: Make it a default scope of inventory-cli only

```sh
CLI_ID=$(kcadm get clients -r inventory -q clientId=inventory-cli --fields id --format csv --noquotes | tr -d '\r')
kcadm update "clients/$CLI_ID/default-client-scopes/$SCOPE_ID" -r inventory
kcadm get "clients/$CLI_ID/default-client-scopes" -r inventory --fields name
```

The list now includes `inventory-api-audience`.

## Step 4: Prove the fix from both sides

```sh
call_api "$(get_alice_token)"
kubectl -n tokens-demo exec deploy/tester -- sh -c '
  curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=client_credentials -d client_id=inventory-reporter -d client_secret=inventory-reporter-secret \
  | jq -r .access_token' \
  | jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson | .aud'
```

The API answers `200`. The token of `inventory-reporter` has no `inventory-api` in its `aud`.

## Step 5: Submit

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Changing `AUDIENCE` on the API to `account` | Every token of the realm passes the audience check; the grader rejects any change to the API |
| Adding the mapper to the realm's default scope `profile` | Every client gets the audience, including `inventory-reporter` |
| Putting the mapper on `inventory-cli` directly | The API accepts the token, but the next two clients would need copies; the task asks for the client scope |
