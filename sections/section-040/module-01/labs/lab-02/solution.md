# Solution: Repair A Failing Token Exchange

Work the task yourself first. Running `astrona submit -c sections/section-040/module-01/labs/lab-02` after a step tells you which checks pass, without telling you what is left.

## Step 1: Send the exchange and read the error

```sh
NAMESPACE=exchange-demo
TOKEN=$(kubectl -n "$NAMESPACE" exec deploy/tester -- sh -c '
  curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=inventory-cli \
    -d username=alice -d password=alice-password -d scope=openid | jq -r .access_token')
kubectl -n "$NAMESPACE" exec deploy/tester -- sh -c '
  curl -s -w "\nHTTP %{http_code}\n" http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=urn:ietf:params:oauth:grant-type:token-exchange \
    -d client_id=inventory-gateway -d client_secret=inventory-gateway-secret \
    --data-urlencode subject_token="$1" \
    -d subject_token_type=urn:ietf:params:oauth:token-type:access_token \
    -d audience=inventory-api' sh "$TOKEN"
```

Keycloak refuses the exchange. The gateway authenticated, so it is not failure three, and the capability is on in the realm, so it is not failure two. Decode the token you sent and read `aud`:

```sh
printf '%s' "$TOKEN" | jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson | .aud'
```

The token does not name `inventory-gateway`. That is failure one, and the fix is on `inventory-cli`.

## Step 2: Name the gateway in the first client's tokens

```sh
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
CLI_ID=$(kcadm get clients -r inventory -q clientId=inventory-cli --fields id --format csv --noquotes | tr -d '\r')
kcadm create "clients/$CLI_ID/protocol-mappers/models" -r inventory \
  -s name=audience-inventory-gateway -s protocol=openid-connect -s protocolMapper=oidc-audience-mapper \
  -s 'config."included.client.audience"=inventory-gateway' \
  -s 'config."access.token.claim"=true' -s 'config."id.token.claim"=false' \
  -s 'config."introspection.token.claim"=true'
```

Get a new token from `inventory-cli` and send the exchange again. It returns `HTTP 200` now.

## Step 3: Remove the extra audience from the gateway

An exchange without `audience` names everything available to the gateway. Run it and read `aud`: it contains `inventory-admin-api` as well. List the gateway's mappers and delete the one for that API:

```sh
GW_ID=$(kcadm get clients -r inventory -q clientId=inventory-gateway --fields id --format csv --noquotes | tr -d '\r')
kcadm get "clients/$GW_ID/protocol-mappers/models" -r inventory --fields id,name
MID=$(kcadm get "clients/$GW_ID/protocol-mappers/models" -r inventory --fields id,name --format csv --noquotes \
  | tr -d '\r' | awk -F, '$2 == "audience-inventory-admin-api" {print $1}')
kcadm delete "clients/$GW_ID/protocol-mappers/models/$MID" -r inventory
```

## Step 4: Prove it

Exchange with `audience=inventory-api`: `aud` has `inventory-api`, `azp` is `inventory-gateway`. Exchange without `audience`: `aud` has no `inventory-admin-api`. Exchange with `audience=inventory-admin-api`: an error and no token. Run `astrona submit` to grade the lab.
