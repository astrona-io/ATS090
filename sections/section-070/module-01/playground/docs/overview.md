# Overview: End Sessions With Logout And Admin Control (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, deploys Keycloak, creates a realm with one user and one client, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- Namespace **`logout-demo`** with these workloads:

  | Workload | What it is |
  | --- | --- |
  | `keycloak` | One Keycloak 26.8.1 pod in development mode, behind the Service `keycloak` on port `8080` |
  | `tester` | Client pod with `curl`, `jq` and `openssl`; send every request from here to `http://keycloak:8080` |

- Inside Keycloak, the realm **`inventory`** with default session limits:

  | Keycloak object | What it is |
  | --- | --- |
  | user `alice` | Password `alice-password` |
  | client `inventory-cli` | Public client with direct access grants, so you can sign in from a terminal |

- The administrator of the `master` realm is `admin` with the password `admin`. These are lab-only credentials.

Keycloak takes a few minutes to start the first time. When `kubectl -n logout-demo get pods` shows `keycloak` as `1/1`, it is ready.

## Helpers

```sh
NAMESPACE=logout-demo
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
```

## Ideas to try

- Sign in twice and list the sessions of `alice` with `kcadm get users/<id>/sessions`.
- Log out with the refresh token at the logout endpoint and check for `204`.
- Register a post-logout redirect URI and read the client attribute back.
- Set a back-channel logout URL and read the client attributes.
- Call `logout-all` and refresh with an old refresh token.
