# Audience, Audience Mappers And Client Scopes

Every token `alice` gets has a valid signature, the right issuer and the right role, and `inventory-api` still refuses it, because the token does not say it is meant for `inventory-api`. Keycloak does not guess which APIs a client will call. You tell it, and how you tell it decides which other clients get the same audience. This part adds the audience and shows how to keep it where it belongs.

## What the audience is for

The **audience** claim, `aud`, lists who a token is for. An API accepts a token only when its own name is in that list. Without the check, a token that a client got for one API could be replayed against every other API of the realm, because they all trust the same signature. With the check, a token is only good where it was meant to go.

Keycloak builds `aud` from the token's contents. By default, a client of the realm appears in `aud` when the token carries roles of that client: that is why `account` is there. To add a client that has no roles in the token, such as `inventory-api`, you add an **audience mapper**. A **protocol mapper** is a rule that adds or changes a claim in a token. The audience mapper (`oidc-audience-mapper`, "Audience" in the Admin Console) adds one client ID, or a custom value, to `aud`.

## Add the audience to one client

A mapper can sit directly on a client, in the client's **dedicated scope**, which applies only to that client. Add one to `inventory-cli` that puts `inventory-api` in the audience. Sign in `kcadm.sh`, Keycloak's administration command-line tool, first:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=tokens-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
CLI_ID=$(kcadm get clients -r inventory -q clientId=inventory-cli --fields id --format csv --noquotes | tr -d '\r')
kcadm create "clients/$CLI_ID/protocol-mappers/models" -r inventory \
  -s name=audience-inventory-api -s protocol=openid-connect -s protocolMapper=oidc-audience-mapper \
  -s 'config."included.client.audience"=inventory-api' \
  -s 'config."access.token.claim"=true' -s 'config."id.token.claim"=false' \
  -s 'config."introspection.token.claim"=true'
```

The setting `included.client.audience` names a client of the realm, so the client `inventory-api` must exist; it does, as a client with every flow off that only stands for the API. `access.token.claim` puts the audience in access tokens, which is where the API looks.

Mappers apply to new tokens only. Define the helpers again if this is a new terminal, get a new token and call the API:

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
printf '%s' "$TOKEN" | jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson | .aud'
call_api "$TOKEN"
```

The token's `aud` now contains `inventory-api`, and the API answers `HTTP 200` with a JSON body that names `alice` as the user and `inventory-cli` as `azp`, followed by the list of items.

## Keep the audience where it belongs

Now check a token of another client, the background service `inventory-reporter`:

```sh
kubectl -n tokens-demo exec deploy/tester -- sh -c '
  curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=client_credentials -d client_id=inventory-reporter -d client_secret=inventory-reporter-secret \
  | jq -r .access_token' \
  | jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson | .aud'
```

Its `aud` does not contain `inventory-api`: the mapper sits on `inventory-cli` only. That is the point. An audience is a permission to call an API, and only the clients that call it should get it. A mapper on a realm-wide default scope would put `inventory-api` in every token of the realm, and the audience check would no longer mean anything.

## Client scopes

A mapper on one client works for one client. When several clients call the same API, you would repeat the mapper on each of them. A **client scope** solves that. It is a named, reusable set of protocol mappers and role scopes. A client uses a client scope as a **default** scope, applied to every token, or as an **optional** scope, applied only when the client asks for it in the `scope` parameter. Keycloak builds each token from the client's dedicated scope plus its client scopes.

The claims you have seen so far already come from client scopes. List the default client scopes of `inventory-cli`:

```sh
kcadm get "clients/$CLI_ID/default-client-scopes" -r inventory --fields name
```

The list includes `roles`, which puts `realm_access` into tokens, `profile` and `email`, which add the user's name and email address, and `web-origins`, among others. To share an audience, you create a client scope, put the audience mapper in it, and add the scope as a default scope to exactly the clients that call the API. With `kcadm.sh`, those are three requests:

| Step | Request |
| --- | --- |
| Create the client scope | `kcadm create client-scopes -r inventory -s name=<scope> -s protocol=openid-connect` |
| Add the mapper to it | `kcadm create client-scopes/<scope id>/protocol-mappers/models -r inventory -s ...` with the same mapper settings as above |
| Make it a default scope of a client | `kcadm update clients/<client id>/default-client-scopes/<scope id> -r inventory` |

In the Admin Console, the same steps are **Client scopes** › **Create client scope**, then the scope's **Mappers** tab, then the client's **Client scopes** tab › **Add client scope**.

You can now put an API's audience into the tokens of exactly the clients that call it, on one client or through a client scope. The token now passes the audience check, and the last check in the API's list, the role, is the one left to understand.

## Common pitfalls

> [!WARNING]
> - **Adding the audience mapper to a realm default scope.** Every client's tokens then carry the audience, and the API can no longer tell them apart.
> - **Testing with an old token.** Mappers apply when Keycloak issues a token. Get a new one after every change.
> - **Putting the audience only in the ID token.** The API reads the access token; `access.token.claim` must be on.
> - **Naming a client that does not exist.** `included.client.audience` needs an existing client ID; use `included.custom.audience` for a value that is not a client.

## Your mission: Add The API Audience With A Client Scope

You can now read why an API refuses a token and add the missing audience. The graded lab gives you a realm where `inventory-api` refuses `alice`'s tokens from `inventory-cli`, and asks you to add the audience through a client scope named `inventory-api-audience`, for `inventory-cli` only, without touching the API.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-090-playground-030-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS090.git -c sections/section-030/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-090-lab-030-01
astrona start ats-090-playground-030-01
```
