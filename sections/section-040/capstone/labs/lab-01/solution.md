# Solution: Propagate A User To A Second API

Work the task yourself first. `astrona submit -c sections/section-040/capstone/labs/lab-01` tells you which checks pass.

The grader checks five things: the exchange and call for `reporting-api`, the same for `inventory-api`, that `inventory-admin-api` is out of reach, that the original token reaches neither API, and that both APIs are unchanged.

## Step 1: Set up the helpers

```sh
NAMESPACE=exchangecapstone-demo
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
exchange_token() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- sh -c '
    curl -s -w "\nHTTP %{http_code}\n" \
      http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=urn:ietf:params:oauth:grant-type:token-exchange \
      -d client_id=inventory-gateway -d client_secret=inventory-gateway-secret \
      --data-urlencode subject_token="$1" \
      -d subject_token_type=urn:ietf:params:oauth:token-type:access_token \
      -d audience="$2"' sh "$1" "$2"
}
call_service() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- \
    curl -s -w '\nHTTP %{http_code}\n' -H "Authorization: Bearer $2" "http://$1:8080/items"
}
client_id_of() {
  kcadm get clients -r inventory -q clientId="$1" --fields id --format csv --noquotes | tr -d '\r'
}
add_audience() {
  kcadm create "clients/$(client_id_of "$1")/protocol-mappers/models" -r inventory \
    -s name="audience-$2" -s protocol=openid-connect -s protocolMapper=oidc-audience-mapper \
    -s 'config."included.client.audience"='"$2" \
    -s 'config."access.token.claim"=true' -s 'config."id.token.claim"=false' \
    -s 'config."introspection.token.claim"=true'
}
```

## Step 2: The subject token must name the gateway

```sh
TOKEN=$(get_alice_token)
printf '%s' "$TOKEN" | jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson | .aud'
```

`alice`'s token does not name `inventory-gateway`, so Keycloak would refuse any exchange of it by the gateway. Add the gateway's audience to `inventory-cli`'s tokens. This is the one audience the client needs: the gateway is the service it calls.

```sh
add_audience inventory-cli inventory-gateway
TOKEN=$(get_alice_token)
```

## Step 3: Allow the gateway to exchange

```sh
kcadm update "clients/$(client_id_of inventory-gateway)" -r inventory \
  -s 'attributes."standard.token.exchange.enabled"=true'
exchange_token "$TOKEN" inventory-api | tail -n 1
exchange_token "$TOKEN" reporting-api
```

The exchange for `inventory-api` now returns `HTTP 200`: its audience mapper was already on the gateway. The exchange for `reporting-api` fails because that audience is not available to the gateway.

## Step 4: Make reporting-api available to the gateway

```sh
add_audience inventory-gateway reporting-api
RESPONSE=$(exchange_token "$TOKEN" reporting-api)
printf '%s\n' "$RESPONSE" | tail -n 1
EXCHANGED=$(printf '%s\n' "$RESPONSE" | head -n 1 | jq -r .access_token)
call_service reporting-api "$EXCHANGED"
kubectl -n "$NAMESPACE" logs deploy/reporting-api --tail=1
```

The exchange works, and `reporting-api` answers `403`: its log says the realm role `reporting-reader` is missing. Token exchange keeps the user's roles; it does not add any.

## Step 5: Give alice the role

```sh
kcadm add-roles -r inventory --uusername alice --rolename reporting-reader
TOKEN=$(get_alice_token)
for API in reporting-api inventory-api; do
  EXCHANGED=$(exchange_token "$TOKEN" "$API" | head -n 1 | jq -r .access_token)
  echo "== $API"; call_service "$API" "$EXCHANGED"
done
```

Both APIs answer `200` to their exchanged tokens.

## Step 6: Prove what must stay refused

```sh
exchange_token "$TOKEN" inventory-admin-api | tail -n 1
call_service inventory-api "$TOKEN" | tail -n 1
call_service reporting-api "$TOKEN" | tail -n 1
```

The exchange for `inventory-admin-api` fails: nothing gives the gateway that audience. Both APIs answer `401` to the original token.

## Step 7: Submit

```sh
astrona submit -c sections/section-040/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Adding `reporting-api` to `inventory-cli`'s audience | The original token reaches the API directly; the grader requires `401` |
| Giving the gateway every API's audience through a realm default scope | The gateway can reach `inventory-admin-api`, and every client gets every audience |
| Setting `REQUIRED_ROLE` of `reporting-api` to `inventory-reader` | The grader rejects any change to the APIs |
