# Troubleshooting A Token Exchange

A token exchange has several places to fail, and Keycloak answers most of them with the same kind of error object. This part gives you a short list of questions to ask in order, shows how to read the answer for each one, and breaks the playground on purpose so that you see every answer once.

## Ask four questions, in order

When an exchange fails, the cause is one of four things. Each has a place to look:

| Question | Where to look | Fix |
| --- | --- | --- |
| Is the requester allowed to exchange? | The client attribute `standard.token.exchange.enabled` | Switch on **Standard token exchange** for the gateway |
| Is the requester a confidential client that sent its credentials? | `publicClient`, the secret in the request | Use the gateway's own `client_id` and `client_secret` |
| Does the subject token name the requester? | The `aud` claim of the token that was sent | Add an audience mapper for the gateway to the first client |
| Is the audience that was asked for available to the requester? | The protocol mappers and scopes of the requester | Add a mapper for that API to the gateway, and only that API |

Ask them in this order, because each answer rules out a whole class of causes. The list also says what **not** to do: none of the fixes puts the API's audience on the first client, and none of them gives the gateway more audiences than it uses.

Define the helpers once. `claims` prints the payload of a token, and `exchange_token` sends the exchange as the gateway and prints the response and the HTTP status. They are the same helpers as in the earlier parts:

```sh
NAMESPACE=exchange-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin

claims() { jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson'; }
get_alice_token() {
  kubectl -n exchange-demo exec deploy/tester -- sh -c '
    curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=password -d client_id=inventory-cli \
      -d username=alice -d password=alice-password -d scope=openid \
    | jq -r .access_token'
}
exchange_token() {
  # exchange_token SUBJECT_TOKEN AUDIENCE [CLIENT_ID CLIENT_SECRET]
  kubectl -n exchange-demo exec deploy/tester -- sh -c '
    curl -s -w "\nHTTP %{http_code}\n" \
      http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=urn:ietf:params:oauth:grant-type:token-exchange \
      -d "client_id=${3-inventory-gateway}" -d "client_secret=${4-inventory-gateway-secret}" \
      --data-urlencode subject_token="$1" \
      -d subject_token_type=urn:ietf:params:oauth:token-type:access_token \
      -d audience="$2"' sh "$@"
}
```

This part assumes the exchange works, as it did at the end of the second part: the gateway is allowed to exchange and has the audience `inventory-api`. If your playground is fresh, repeat that part first. Check it with one exchange:

```sh
TOKEN=$(get_alice_token)
exchange_token "$TOKEN" inventory-api | tail -n 1
```

The last line is `HTTP 200`. Now break it four ways.

## Failure one: the subject token does not name the gateway

The first rule of the exchange says that the token that is sent must have the gateway in `aud`. It does, because of an audience mapper on `inventory-cli`. Look at the claim, then take the mapper away:

```sh
printf '%s' "$TOKEN" | claims | jq .aud
CLI_ID=$(kcadm get clients -r inventory -q clientId=inventory-cli --fields id --format csv --noquotes | tr -d '\r')
MAPPER_ID=$(kcadm get "clients/$CLI_ID/protocol-mappers/models" -r inventory --fields id,name --format csv --noquotes \
  | tr -d '\r' | awk -F, '$2 == "audience-inventory-gateway" {print $1}')
kcadm delete "clients/$CLI_ID/protocol-mappers/models/$MAPPER_ID" -r inventory
TOKEN=$(get_alice_token)
printf '%s' "$TOKEN" | claims | jq .aud
exchange_token "$TOKEN" inventory-api
```

The first `aud` has `inventory-gateway`; the second does not. The exchange fails with an error object and a `4xx` status. The error is about the token, not about the gateway: the gateway is allowed to exchange, but Keycloak will only exchange a token that was meant for it. The fix is on the first client, not on the gateway. Add the mapper back:

```sh
kcadm create "clients/$CLI_ID/protocol-mappers/models" -r inventory \
  -s name=audience-inventory-gateway -s protocol=openid-connect -s protocolMapper=oidc-audience-mapper \
  -s 'config."included.client.audience"=inventory-gateway' \
  -s 'config."access.token.claim"=true' -s 'config."id.token.claim"=false' \
  -s 'config."introspection.token.claim"=true'
TOKEN=$(get_alice_token)
```

## Failure two: the gateway is not allowed to exchange

Switch off the capability and send the same exchange:

```sh
GATEWAY_ID=$(kcadm get clients -r inventory -q clientId=inventory-gateway --fields id --format csv --noquotes | tr -d '\r')
kcadm update "clients/$GATEWAY_ID" -r inventory -s 'attributes."standard.token.exchange.enabled"=false'
exchange_token "$TOKEN" inventory-api
```

Keycloak refuses with a `4xx` status. The error is about the client: it is not allowed to use this grant. The token and the audiences are fine, and the only way to see the difference from failure one is to read the error description, so read it every time. Switch the capability back on:

```sh
kcadm update "clients/$GATEWAY_ID" -r inventory -s 'attributes."standard.token.exchange.enabled"=true'
```

## Failure three: the requester did not authenticate

Send the exchange as `inventory-cli`, which is a public client, and then as the gateway with a wrong secret:

```sh
exchange_token "$TOKEN" inventory-api inventory-cli ""
exchange_token "$TOKEN" inventory-api inventory-gateway not-the-secret
```

Both fail before Keycloak looks at the token. A wrong secret gives the error `invalid_client` with status `401`. A `401` at the token endpoint is always about the client, never about the user or the token. If you see it, check the secret and check that the requester is confidential.

## Failure four: the audience is not available

Ask for an API that nothing gives to the gateway:

```sh
exchange_token "$TOKEN" inventory-admin-api
```

Keycloak says that the requested audience is not available. The exchange works, and the gateway does not have that audience. This is the one that must stay an error. The wrong fix is to give the gateway the audience so that the error goes away. Ask whether the gateway should be able to call that API for any user at all. If it should, add a mapper for that API to the gateway, and nowhere else.

## Read the result, not only the status

A successful exchange can still be wrong. After a fix, read the new token before you trust it:

```sh
RESPONSE=$(exchange_token "$TOKEN" inventory-api)
printf '%s\n' "$RESPONSE" | head -n 1 | jq -r .access_token | claims | jq '{preferred_username, azp, aud}'
```

`preferred_username` is `alice`, so the user is the same. `azp`, the party that asked for the token, is `inventory-gateway`, so the API can tell who called. `aud` holds `inventory-api` and nothing you did not ask for. If `aud` names a second API, the gateway has an audience it does not need, and any token it exchanges without an `audience` parameter works on that API as well.

## Common pitfalls

> [!WARNING]
> - **Fixing failure one on the gateway.** The subject token must name the gateway. Adding mappers to the gateway does not change the token that was already issued.
> - **Reading every error as "not allowed".** The error description separates a client that may not exchange, a token that is not for it, and an audience that is not available.
> - **Making the error go away with a wider audience.** The exchange protects nothing if the first client's token also names the API.
> - **Testing with an old token.** After a mapper change, get a new subject token. An old one keeps its old `aud`.

## Your mission: Repair A Failing Token Exchange

You can now tell the four failures of a token exchange apart and fix each one at the right client. The graded lab gives you a realm where the exchange is set up and still fails, and where the gateway also holds an audience it should not have. You repair both.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-090-playground-040-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS090.git -c sections/section-040/module-01/labs/lab-02
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/module-01/labs/lab-02
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-090-lab-040-02
astrona start ats-090-playground-040-01
```
