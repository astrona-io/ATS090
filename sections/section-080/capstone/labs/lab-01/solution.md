# Solution: Repair The Token Contents Of A Client

Work the task yourself first. Running `astrona submit -c sections/section-080/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

## Step 1: Decode the current token

```sh
NAMESPACE=scopes-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
decode_token() {
  jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson'
}
get_access_token() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- \
    curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=password -d client_id=inventory-cli \
      -d username=alice -d password=alice-password -d scope=openid \
  | jq -r .access_token
}
get_access_token | decode_token | jq '{groups, audit, roles: .realm_access.roles}'
```

`groups` and `audit` are `null`, and the roles include `inventory-admin`.

## Step 2: Turn on the access token switch of the groups mapper

```sh
CLI_ID=$(kcadm get clients -r inventory -q clientId=inventory-cli --fields id --format csv --noquotes | tr -d '\r')
kcadm get "clients/$CLI_ID/protocol-mappers/models" -r inventory --fields id,name,config
```

The mapper `groups` has `access.token.claim` set to `false`. Update it:

```sh
MAPPER_ID=$(kcadm get "clients/$CLI_ID/protocol-mappers/models" -r inventory --fields id,name --format csv --noquotes | tr -d '\r' | awk -F, '$2 == "groups" {print $1}')
kcadm update "clients/$CLI_ID/protocol-mappers/models/$MAPPER_ID" -r inventory -s 'config."access.token.claim"=true'
```

## Step 3: Limit the roles

Turn off Full Scope Allowed, then allow only the reader role:

```sh
kcadm update "clients/$CLI_ID" -r inventory -s fullScopeAllowed=false
READER_ID=$(kcadm get roles/inventory-reader -r inventory --fields id --format csv --noquotes | tr -d '\r')
kcadm create "clients/$CLI_ID/scope-mappings/realm" -r inventory -b "[{\"id\":\"$READER_ID\",\"name\":\"inventory-reader\"}]"
```

## Step 4: Make the audit scope a default scope

```sh
AUDIT_ID=$(kcadm get client-scopes -r inventory --fields id,name --format csv --noquotes | tr -d '\r' | awk -F, '$2 == "inventory-audit" {print $1}')
kcadm delete "clients/$CLI_ID/optional-client-scopes/$AUDIT_ID" -r inventory
kcadm update "clients/$CLI_ID/default-client-scopes/$AUDIT_ID" -r inventory
```

## Step 5: Check the token

```sh
get_access_token | decode_token | jq '{groups, audit, roles: .realm_access.roles}'
```

The token has `groups` with `logistics`, `audit` as `true`, and only `inventory-reader` in the roles. Run `astrona submit` to grade the capstone.
