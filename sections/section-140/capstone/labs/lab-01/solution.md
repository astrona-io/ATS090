# Solution: Protect An Orders API Behind A Gateway

Work the task yourself first. Running `astrona submit -c sections/section-140/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

## Step 1: Read the token and the client

```sh
NAMESPACE=proxy-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
ACCESS=$(kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=gateway -d client_secret=gateway-secret \
    -d username=alice -d password=alice-password | jq -r .access_token)
echo "$ACCESS" | jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson | {aud, group, groups, iat, exp}'
GW_ID=$(kcadm get clients -r inventory -q clientId=gateway --fields id --format csv --noquotes | tr -d '\r')
kcadm get "clients/$GW_ID" -r inventory --fields redirectUris,attributes
kcadm get "clients/$GW_ID/protocol-mappers/models" -r inventory
```

The audience is `order-api`, the claim is named `group`, `exp` minus `iat` is 3600 and the redirect address ends in `*`.

## Step 2: Fix the client

```sh
kcadm update "clients/$GW_ID" -r inventory \
  -s 'redirectUris=["https://orders.example.com/oauth2/callback"]' \
  -s 'attributes."access.token.lifespan"=300'
```

## Step 3: Fix the mappers

```sh
AUD_ID=$(kcadm get "clients/$GW_ID/protocol-mappers/models" -r inventory --fields id,name --format csv --noquotes | tr -d '\r' | awk -F, '$2 == "audience" {print $1}')
GRP_ID=$(kcadm get "clients/$GW_ID/protocol-mappers/models" -r inventory --fields id,name --format csv --noquotes | tr -d '\r' | awk -F, '$2 == "groups" {print $1}')
kcadm update "clients/$GW_ID/protocol-mappers/models/$AUD_ID" -r inventory -s 'config."included.client.audience"=orders-api'
kcadm update "clients/$GW_ID/protocol-mappers/models/$GRP_ID" -r inventory -s 'config."claim.name"=groups'
```

## Step 4: Read the token again

Repeat the token request. `aud` contains `orders-api`, `groups` is `["staff"]` and `exp` minus `iat` is 300. Run `astrona submit` to grade the capstone.
