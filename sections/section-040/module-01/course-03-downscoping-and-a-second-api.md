# Downscoping And A Second API

A gateway rarely sits in front of only one API. Once it may call two, every token it gets by exchange could name both, and the first API would receive a token that also works on the second. This part gives the gateway a second audience and shows how the `audience` parameter keeps each exchanged token down to the one API that receives it.

## A gateway with two audiences

Add two more API clients to the realm: `reporting-api`, which the gateway will be allowed to call, and `inventory-admin-api`, which it will not. Make `reporting-api` available to the gateway with a second audience mapper. No workload runs for either client in the playground; the clients are enough to see what Keycloak puts in the tokens. These commands need the token exchange for `inventory-gateway` set up: the switch **Standard token exchange** on, and an audience mapper for `inventory-api` on the gateway's client.

<!-- astrona:playground:renew -->

```sh
NAMESPACE=exchange-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
for API in reporting-api inventory-admin-api; do
  kcadm create clients -r inventory -s clientId="$API" -s enabled=true \
    -s publicClient=false -s standardFlowEnabled=false -s directAccessGrantsEnabled=false
done
GATEWAY_ID=$(kcadm get clients -r inventory -q clientId=inventory-gateway --fields id --format csv --noquotes | tr -d '\r')
kcadm create "clients/$GATEWAY_ID/protocol-mappers/models" -r inventory \
  -s name=audience-reporting-api -s protocol=openid-connect -s protocolMapper=oidc-audience-mapper \
  -s 'config."included.client.audience"=reporting-api' \
  -s 'config."access.token.claim"=true' -s 'config."id.token.claim"=false' \
  -s 'config."introspection.token.claim"=true'
```

Define the token helpers again if this is a new terminal. This version of `exchange_token` leaves the `audience` parameter out when you give no second argument:

```sh
get_alice_token() {
  kubectl -n exchange-demo exec deploy/tester -- sh -c '
    curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=password -d client_id=inventory-cli \
      -d username=alice -d password=alice-password -d scope=openid \
    | jq -r .access_token'
}
exchange_token() {
  kubectl -n exchange-demo exec deploy/tester -- sh -c '
    set -- "$1" ${2:+-d audience="$2"}
    TOKEN="$1"; shift
    curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=urn:ietf:params:oauth:grant-type:token-exchange \
      -d client_id=inventory-gateway -d client_secret=inventory-gateway-secret \
      --data-urlencode subject_token="$TOKEN" \
      -d subject_token_type=urn:ietf:params:oauth:token-type:access_token "$@"' sh "$1" "${2:-}"
}
audience_of() {
  jq -r '.access_token // empty' | jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson | .aud'
}
```

## Exchange with and without an audience

Exchange `alice`'s token three times: without an `audience`, with `audience=inventory-api`, and with `audience=reporting-api`:

```sh
TOKEN=$(get_alice_token)
exchange_token "$TOKEN" | audience_of
exchange_token "$TOKEN" inventory-api | audience_of
exchange_token "$TOKEN" reporting-api | audience_of
```

Without an `audience`, the new token names both `inventory-api` and `reporting-api`, and possibly other clients whose roles it carries: everything that is available to the gateway. With an `audience`, the new token names only the one you asked for. Asking for less than the requester may have is called **downscoping**. A gateway that downscopes hands each API a token that works on that API and nowhere else.

## An audience the gateway was not given

The second rule of token exchange still holds: the `audience` parameter only filters. Ask for `inventory-admin-api`, a client of the realm that nothing makes available to the gateway:

```sh
exchange_token "$TOKEN" inventory-admin-api | jq
```

Keycloak answers with an error object instead of a token; the description says that the requested audience is not available. A gateway cannot reach an API just by naming it. An administrator decides which APIs the gateway may call, by giving it those audiences, and the gateway decides, per request, which one it calls.

## The second API and its roles

Audience is one check; the second API also checks its own role. In a setup with a real `reporting-api`, which requires the realm role `reporting-reader`, an exchanged token for `alice` passes the audience check and still gets `403` until `alice` has that role. Token exchange keeps the user's identity and roles; it does not add permissions the user did not have.

You can now limit each exchanged token to one audience and tell a missing audience from a missing role. Together with the two rules of the exchange, that is the whole hand-over: the client's token names the gateway, the gateway is allowed to exchange and has the APIs' audiences, and each API gets a token for itself only.

## Common pitfalls

> [!WARNING]
> - **Exchanging without `audience` when the gateway has several.** Every API then receives a token that works on the others.
> - **Reading an "audience not available" error as a broken exchange.** The exchange works; the requester was not given that audience.
> - **Expecting the exchange to add roles.** The new token carries the user's roles; a missing role still gives `403`.
> - **Giving the gateway audiences "just in case".** Each one is an API the gateway can reach for any user whose token it receives.
