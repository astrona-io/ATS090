# Solution: Add Group And Tenant Claims To A Client

Work the task yourself first. Running `astrona submit -c sections/section-080/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

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
get_tokens() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- \
    curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=password -d client_id=inventory-cli \
      -d username=alice -d password=alice-password -d scope=openid
}
get_tokens | jq -r .access_token | decode_token | jq '{groups, tenant}'
```

Both values are `null`.

## Step 2: Add the groups mapper

```sh
CLI_ID=$(kcadm get clients -r inventory -q clientId=inventory-cli --fields id --format csv --noquotes | tr -d '\r')
kcadm create "clients/$CLI_ID/protocol-mappers/models" -r inventory \
  -s name=groups -s protocol=openid-connect -s protocolMapper=oidc-group-membership-mapper \
  -s 'config."claim.name"=groups' -s 'config."full.path"=false' \
  -s 'config."access.token.claim"=true' -s 'config."id.token.claim"=true' -s 'config."userinfo.token.claim"=true'
```

## Step 3: Add the tenant mapper for the access token only

```sh
kcadm create "clients/$CLI_ID/protocol-mappers/models" -r inventory \
  -s name=tenant -s protocol=openid-connect -s protocolMapper=oidc-hardcoded-claim-mapper \
  -s 'config."claim.name"=tenant' -s 'config."claim.value"=outpost' -s 'config."jsonType.label"=String' \
  -s 'config."access.token.claim"=true' -s 'config."id.token.claim"=false' -s 'config."userinfo.token.claim"=false'
```

## Step 4: Check both tokens

```sh
TOKENS=$(get_tokens)
printf '%s' "$TOKENS" | jq -r .access_token | decode_token | jq '{groups, tenant}'
printf '%s' "$TOKENS" | jq -r .id_token | decode_token | jq '{groups, tenant}'
```

The access token shows `groups` and `tenant`. The ID token shows `groups` and `null` for `tenant`. Run `astrona submit` to grade the lab.
