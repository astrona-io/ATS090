# Overview: Securing Applications With Libraries, Proxies And Gateways (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, deploys Keycloak, creates a realm with a proxy client, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- Namespace **`proxy-demo`** with these workloads:

  | Workload | What it is |
  | --- | --- |
  | `keycloak` | One Keycloak 26.8.1 pod in development mode, behind the Service `keycloak` on port `8080` |
  | `tester` | Client pod with `curl`, `jq` and `openssl`; send every request from here to `http://keycloak:8080` |

- Inside Keycloak, the realm **`inventory`**:

  | Keycloak object | What it is |
  | --- | --- |
  | group `staff` | Holds `alice` |
  | user `alice` | Password `alice-password` |
  | client `web-proxy` | Confidential, secret `web-proxy-secret`, redirect URI `https://app.example.com/oauth2/callback`, an audience mapper and a groups mapper. The password grant is on so that you can get tokens from a terminal |

- The administrator of the `master` realm is `admin` with the password `admin`. These are lab-only credentials.

Keycloak takes a few minutes to start the first time. When `kubectl -n proxy-demo get pods` shows `keycloak` as `1/1`, it is ready.

## Helpers

```sh
NAMESPACE=proxy-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
```

## Ideas to try

- Get a token for `alice` with `web-proxy` and read `iss`, `aud` and `groups`.
- Delete the audience mapper and read the token again.
- Turn `full.path` on in the groups mapper and compare the value.
- Read the discovery document and the JWKS endpoint.
