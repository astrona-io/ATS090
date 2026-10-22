# Overview: Propagate Tokens Through An API Gateway (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, deploys Keycloak, an API and a gateway in front of it, creates a realm with one user and three clients, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- Namespace **`exchange-demo`** with these workloads:

  | Workload | What it is |
  | --- | --- |
  | `keycloak` | One Keycloak 26.8.1 pod in development mode, behind the Service `keycloak` on port `8080` |
  | `inventory-gateway` | nginx on port `8080`; forwards every request, `Authorization` header unchanged, to `inventory-api` |
  | `inventory-api` | The API on port `8080`; `GET /items` needs `inventory-api` in `aud` and the realm role `inventory-reader`, and its log says why it refuses a token |
  | `tester` | Client pod with `curl` and `jq`; send every request from here |

- Inside Keycloak, the realm **`inventory`**:

  | Keycloak object | What it is |
  | --- | --- |
  | user `alice` | Password `alice-password`, realm role `inventory-reader` |
  | client `inventory-cli` | Public client with direct access grants; an audience mapper puts `inventory-gateway` in its tokens |
  | client `inventory-gateway` | Confidential client, secret `inventory-gateway-secret`; token exchange is **not** allowed yet |
  | client `inventory-api` | Stands for the API so it can be named as an audience |

- The administrator of the `master` realm is `admin` with the password `admin`. These are lab-only credentials.

Keycloak takes a few minutes to start the first time. When `kubectl -n exchange-demo get pods` shows every pod as ready, the playground is ready.

## Helpers

Paste these once in each new terminal. `get_alice_token` uses the password grant of `inventory-cli` (lab-only: OAuth 2.1 drops this grant). `exchange_token TOKEN AUDIENCE` sends a token exchange as `inventory-gateway` and prints the response and the HTTP status. `call_service SERVICE TOKEN` calls `GET /items` on `inventory-gateway` or `inventory-api`. `decode_jwt` prints a token's payload.

```sh
NAMESPACE=exchange-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
get_alice_token() {
  kubectl -n exchange-demo exec deploy/tester -- sh -c '
    curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=password -d client_id=inventory-cli \
      -d username=alice -d password=alice-password -d scope=openid \
    | jq -r .access_token'
}
exchange_token() {
  kubectl -n exchange-demo exec deploy/tester -- sh -c '
    curl -s -w "\nHTTP %{http_code}\n" \
      http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=urn:ietf:params:oauth:grant-type:token-exchange \
      -d client_id=inventory-gateway -d client_secret=inventory-gateway-secret \
      --data-urlencode subject_token="$1" \
      -d subject_token_type=urn:ietf:params:oauth:token-type:access_token \
      -d audience="$2"' sh "$1" "$2"
}
call_service() {
  kubectl -n exchange-demo exec deploy/tester -- \
    curl -s -w '\nHTTP %{http_code}\n' -H "Authorization: Bearer $2" "http://$1:8080/items"
}
decode_jwt() {
  jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson'
}
```

## Practice tasks

- Send `alice`'s token to `inventory-gateway` and to `inventory-api` directly, and read the API's log for both.
- Remove the audience mapper from `inventory-cli` and try the exchange. Which rule does Keycloak apply?
- After you set up the exchange, compare `azp` in the original and the exchanged token.
- Make `inventory-cli` confidential for a moment and try to exchange as it, then make it public again. Who may exchange?
- Find the **Standard token exchange** switch in the Admin Console (`kubectl -n exchange-demo port-forward svc/keycloak 8080:8080`, then `http://localhost:8080/admin`).
