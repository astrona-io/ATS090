# Overview: Authenticate Service Clients With Client Credentials (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, deploys Keycloak, creates a realm with one user, one role and three clients, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- Namespace **`m2m-demo`** with these workloads:

  | Workload | What it is |
  | --- | --- |
  | `keycloak` | One Keycloak 26.8.1 pod in development mode, behind the Service `keycloak` on port `8080` |
  | `tester` | Client pod with `curl`, `jq` and `openssl`; send every request from here to `http://keycloak:8080` |

- Inside Keycloak, the realm **`inventory`**:

  | Keycloak object | What it is |
  | --- | --- |
  | user `alice` | Password `alice-password` |
  | realm role `inventory-reader` | Not given to any service account at the start |
  | client `inventory-cli` | Public client with direct access grants |
  | client `inventory-reporter` | Confidential client with a service account, secret `inventory-reporter-secret` |
  | client `inventory-sync` | Confidential client with a service account, secret `inventory-sync-secret` |

- The administrator of the `master` realm is `admin` with the password `admin`. These are lab-only credentials.

Keycloak takes a few minutes to start the first time. When `kubectl -n m2m-demo get pods` shows `keycloak` as `1/1`, it is ready.

## Helpers

Paste these once in each new terminal. `kcadm` runs Keycloak's administration command-line tool inside the Keycloak pod. `request_token` asks for a token with the client credentials grant and prints the response.

```sh
NAMESPACE=m2m-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
request_token() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- \
    curl -s -u "$1:$2" http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=client_credentials
}
```

## Ideas to try

- Request a token for `inventory-reporter` and decode its payload. Look at `azp`, `preferred_username` and `realm_access`.
- Give the service account of `inventory-reporter` the role `inventory-reader` and request a new token.
- Turn `serviceAccountsEnabled` off for `inventory-sync` and read the error.
- Change `clientAuthenticatorType` of a client to `client-jwt` and send the secret.
- Regenerate the secret of `inventory-sync` and test the old and the new secret.
