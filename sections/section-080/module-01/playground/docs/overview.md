# Overview: Shape Tokens With Client Scopes And Protocol Mappers (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, deploys Keycloak, creates a realm with one user, one group and one client, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- Namespace **`scopes-demo`** with these workloads:

  | Workload | What it is |
  | --- | --- |
  | `keycloak` | One Keycloak 26.8.1 pod in development mode, behind the Service `keycloak` on port `8080` |
  | `tester` | Client pod with `curl`, `jq` and `openssl`; send every request from here to `http://keycloak:8080` |

- Inside Keycloak, the realm **`inventory`**:

  | Keycloak object | What it is |
  | --- | --- |
  | user `alice` | Password `alice-password`, member of the group `logistics`, with the realm roles `inventory-reader` and `inventory-admin` |
  | client `inventory-cli` | Public client with direct access grants, so you can sign in from a terminal |

- The administrator of the `master` realm is `admin` with the password `admin`. These are lab-only credentials.

Keycloak takes a few minutes to start the first time. When `kubectl -n scopes-demo get pods` shows `keycloak` as `1/1`, it is ready.

## Helpers

Paste these once in each new terminal. `get_tokens` signs `alice` in with the password grant and prints the token response. `decode_token` prints the payload of a token.

```sh
NAMESPACE=scopes-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
get_tokens() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- \
    curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=password -d client_id=inventory-cli \
      -d username=alice -d password=alice-password -d scope=openid
}
decode_token() {
  jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson'
}
```

## Ideas to try

- Add a group membership mapper to `inventory-cli` and look for the `groups` claim.
- Create a client scope with a hardcoded claim mapper and assign it as optional, then request it with `scope=openid <name>`.
- Turn off `fullScopeAllowed` and see the realm roles disappear from the token.
- Compare the claims of the access token, the ID token and the UserInfo response.
