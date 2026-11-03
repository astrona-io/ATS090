# Solution: Make Tokens Acceptable To A Proxy

Work the task yourself first. Running `astrona submit -c sections/section-140/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

## Step 1: Read the token

```sh
NAMESPACE=proxy-demo
ACCESS=$(kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=web-proxy -d client_secret=web-proxy-secret \
    -d username=alice -d password=alice-password | jq -r .access_token)
echo "$ACCESS" | jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson | {iss, aud, azp, groups}'
```

The token has no `web-proxy` in `aud` and no `groups` claim.

## Step 2: Add the mappers

```sh
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
PROXY_ID=$(kcadm get clients -r inventory -q clientId=web-proxy --fields id --format csv --noquotes | tr -d '\r')
kcadm create "clients/$PROXY_ID/protocol-mappers/models" -r inventory \
  -s name=audience -s protocol=openid-connect -s protocolMapper=oidc-audience-mapper \
  -s 'config."included.client.audience"=web-proxy' \
  -s 'config."access.token.claim"=true' -s 'config."id.token.claim"=false'
kcadm create "clients/$PROXY_ID/protocol-mappers/models" -r inventory \
  -s name=groups -s protocol=openid-connect -s protocolMapper=oidc-group-membership-mapper \
  -s 'config."claim.name"=groups' -s 'config."full.path"=false' \
  -s 'config."access.token.claim"=true' -s 'config."id.token.claim"=true' -s 'config."userinfo.token.claim"=true'
```

## Step 3: Read the token again

Repeat step 1. `aud` now contains `web-proxy` and `groups` is `["staff"]`. Run `astrona submit` to grade the lab.
