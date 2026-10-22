# Overview: Validate Access Tokens In An API (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, deploys Keycloak and an API that checks every token, creates a realm with one user and three clients, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- Namespace **`tokens-demo`** with these workloads:

  | Workload | What it is |
  | --- | --- |
  | `keycloak` | One Keycloak 26.8.1 pod in development mode, behind the Service `keycloak` on port `8080` |
  | `inventory-api` | The API on port `8080`. `GET /items` needs an access token from `http://keycloak:8080/realms/inventory` with `inventory-api` in `aud` and the realm role `inventory-reader`. It logs one line per request with the reason for a refusal |
  | `tester` | Client pod with `curl` and `jq`; send every request from here |

- Inside Keycloak, the realm **`inventory`**:

  | Keycloak object | What it is |
  | --- | --- |
  | user `alice` | Password `alice-password`, realm role `inventory-reader` |
  | client `inventory-cli` | Public client with direct access grants, to get a token for `alice` from a terminal |
  | client `inventory-reporter` | Confidential service client, secret `inventory-reporter-secret` |
  | client `inventory-api` | Stands for the API, so it can be named as an audience; every flow is off |

- At the start there is **no audience mapper**, so `inventory-api` refuses every token of `alice` with `401`. That is the starting point of the module.
- The administrator of the `master` realm is `admin` with the password `admin`. These are lab-only credentials.

Keycloak takes a few minutes to start the first time. When `kubectl -n tokens-demo get pods` shows every pod as ready, the playground is ready.

## Helpers

Paste these once in each new terminal. `kcadm` runs Keycloak's administration command-line tool inside the Keycloak pod. `get_alice_token` gets an access token for `alice` with the password grant of `inventory-cli` (lab-only: OAuth 2.1 drops this grant). `call_api` calls the API with a token. `decode_jwt` prints a token's payload. `api_log` shows the API's last log lines.

```sh
NAMESPACE=tokens-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
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
decode_jwt() {
  jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson'
}
api_log() {
  kubectl -n tokens-demo logs deploy/inventory-api --tail="${1:-5}"
}
```

Use them like this: `TOKEN=$(get_alice_token)`, `call_api "$TOKEN"`, `printf '%s' "$TOKEN" | decode_jwt`, `api_log`.

## Practice tasks

- Before you change anything, call the API and predict the reason in its log.
- Send an ID token instead of the access token (`jq -r .id_token` in `get_alice_token`). Which check refuses it?
- Lower the realm's access token lifespan to 30 seconds (`kcadm update realms/inventory -s accessTokenLifespan=30`), wait a minute and call the API with an old token. Put it back to `300`.
- Move the audience mapper from `inventory-cli` into a client scope, make the scope an optional scope of the client, and get a token with and without `scope=openid inventory-api-audience`.
- Read the API's code with `kubectl -n tokens-demo get configmap inventory-api-code -o jsonpath='{.data.server\.js}'` and find each check.
