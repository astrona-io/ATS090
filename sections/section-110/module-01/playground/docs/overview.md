# Overview: Client Registration And Client Policies (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, deploys Keycloak, creates a realm with a client profile and a client policy, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- Namespace **`reg-demo`** with these workloads:

  | Workload | What it is |
  | --- | --- |
  | `keycloak` | One Keycloak 26.8.1 pod in development mode, behind the Service `keycloak` on port `8080` |
  | `tester` | Client pod with `curl`, `jq` and `openssl`; send every request from here to `http://keycloak:8080` |

- Inside Keycloak, the realm **`inventory`**:

  | Keycloak object | What it is |
  | --- | --- |
  | profile `strict-public` | One executor, `pkce-enforcer`, with `auto-configure` on |
  | policy `public-clients` | Enabled, condition `any-client`, applies the profile `strict-public` |

- The administrator of the `master` realm is `admin` with the password `admin`. These are lab-only credentials.

Keycloak takes a few minutes to start the first time. When `kubectl -n reg-demo get pods` shows `keycloak` as `1/1`, it is ready.

## Helpers

```sh
NAMESPACE=reg-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
```

## Ideas to try

- Create an initial access token and register a client with it.
- Register again with the same token and read the error.
- Create a public client and read its `pkce.code.challenge.method` attribute.
- Add the executor `reject-ropc-grant` and try to create a client with the password grant.
