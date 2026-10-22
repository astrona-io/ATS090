# Prerequisites

Before starting this lab you should be able to:

- Decode an access token and read its `aud`, `azp` and `realm_access` claims.
- Explain what the audience of a token is for.
- Create a client scope and a protocol mapper with `kcadm.sh` or the Admin Console.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Keycloak 26.8.1** in development mode in the namespace **`tokens-demo`**, behind the Service `keycloak` on port `8080`.
- A `tester` pod with `curl`, `jq` and `openssl`.
- `inventory-api`, an API on port `8080` that accepts a request only with a valid access token from the realm `inventory`. Its log says why it rejects a token.
- The realm `inventory`, prepared as the task describes. The administrator of the `master` realm is `admin` with the password `admin` (lab-only credentials).

Nothing the task asks you to create has been created for you.

## Working rules

- Everything is graded on the **final state** of Keycloak and the cluster, so test again at the end and leave the fix in place.
- Change one setting at a time and test again. A second change you are not sure about makes the first one impossible to check.
- `kubectl`, `curl` and `jq` are available, and `kcadm.sh` is in the Keycloak pod at `/opt/keycloak/bin/kcadm.sh`. You may also use the Admin Console through `kubectl -n tokens-demo port-forward svc/keycloak 8080:8080`.
