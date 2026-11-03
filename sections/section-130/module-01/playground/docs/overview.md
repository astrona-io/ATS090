# Overview: Sender-Constrained Tokens (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, deploys Keycloak, creates a realm with two clients, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- Namespace **`bound-demo`** with these workloads:

  | Workload | What it is |
  | --- | --- |
  | `keycloak` | One Keycloak 26.8.1 pod in development mode, behind the Service `keycloak` on port `8080` |
  | `tester` | Client pod with `curl`, `jq` and `openssl`; send every request from here to `http://keycloak:8080` |

- Inside Keycloak, the realm **`inventory`**:

  | Keycloak object | What it is |
  | --- | --- |
  | client `payments-client` | Confidential, service account, secret `payments-secret`, DPoP-bound tokens required |
  | client `legacy-client` | Confidential, service account, secret `legacy-secret`, plain bearer tokens |

- The administrator of the `master` realm is `admin` with the password `admin`. These are lab-only credentials.
- The playground uses plain HTTP. Mutual TLS needs HTTPS with client certificates, so it cannot run here.

Keycloak takes a few minutes to start the first time. When `kubectl -n bound-demo get pods` shows `keycloak` as `1/1`, it is ready.

## Helpers

```sh
NAMESPACE=bound-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
```

## Ideas to try

- Request a token for each client without a proof and compare the status codes.
- Decode the token of `legacy-client` and look for the `cnf` claim.
- Read the discovery document and find `dpop_signing_alg_values_supported`.
- Turn the DPoP attribute on for `legacy-client` and request again.
