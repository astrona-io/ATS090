# Solution: Exchange A User Token At The Gateway

Work the task yourself first. Running `astrona submit -c sections/section-040/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the exchange and the API's answer to the new token, the API's answer to the original token, and that the API was not changed.

## Step 1: Set up the helpers and try the exchange

```sh
NAMESPACE=exchange-demo
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
TOKEN=$(get_alice_token)
printf '%s' "$TOKEN" | jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson | .aud'
exchange_token "$TOKEN" inventory-api
```

`alice`'s token already names `inventory-gateway` in `aud`, so the first rule of token exchange holds. The exchange still fails with a `4xx` status, because the gateway is not allowed to exchange.

## Step 2: Allow the gateway to exchange

```sh
GATEWAY_ID=$(kcadm get clients -r inventory -q clientId=inventory-gateway --fields id --format csv --noquotes | tr -d '\r')
kcadm update "clients/$GATEWAY_ID" -r inventory -s 'attributes."standard.token.exchange.enabled"=true'
exchange_token "$TOKEN" inventory-api
```

In the Admin Console this is the **Standard token exchange** switch on the client's **Settings** tab. The exchange now fails because the requested audience is not available to the gateway.

## Step 3: Make the audience available to the gateway only

Add an audience mapper to the gateway's own client, not to `inventory-cli`:

```sh
kcadm create "clients/$GATEWAY_ID/protocol-mappers/models" -r inventory \
  -s name=audience-inventory-api -s protocol=openid-connect -s protocolMapper=oidc-audience-mapper \
  -s 'config."included.client.audience"=inventory-api' \
  -s 'config."access.token.claim"=true' -s 'config."id.token.claim"=false' \
  -s 'config."introspection.token.claim"=true'
```

## Step 4: Prove the exchange from both sides

```sh
RESPONSE=$(exchange_token "$TOKEN" inventory-api)
printf '%s\n' "$RESPONSE" | tail -n 1
EXCHANGED=$(printf '%s\n' "$RESPONSE" | head -n 1 | jq -r .access_token)
printf '%s' "$EXCHANGED" | jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson | {preferred_username, azp, aud}'
call_service inventory-api "$EXCHANGED"
call_service inventory-api "$TOKEN"
```

The exchange returns `HTTP 200`. The new token names `alice`, has `azp` `inventory-gateway` and `inventory-api` in `aud`. The API answers `200` to the exchanged token and `401` to the original one.

## Step 5: Submit

```sh
astrona submit -c sections/section-040/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Adding `inventory-api` to `inventory-cli`'s audience | The original token reaches the API directly; the grader requires `401` for it |
| Changing the API's `AUDIENCE` to `inventory-gateway` | The API accepts tokens meant for the gateway; the grader rejects any change to the API |
| Adding the audience mapper to a realm default scope | Every client gets the audience, including `inventory-cli` |
