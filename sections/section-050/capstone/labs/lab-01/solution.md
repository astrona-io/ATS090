# Solution: Secure The Service Clients Of A Realm

Work the task yourself first. Running `astrona submit -c sections/section-050/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

## Step 1: Find why the secret is refused

Define the helpers and read the settings of both clients:

```sh
NAMESPACE=m2m-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm get clients -r inventory -q clientId=inventory-reporter --fields clientId,publicClient,serviceAccountsEnabled,clientAuthenticatorType
kcadm get clients -r inventory -q clientId=inventory-sync --fields clientId,publicClient,serviceAccountsEnabled
```

`inventory-reporter` has `clientAuthenticatorType` set to `client-jwt`, so it accepts only a signed JWT. `inventory-sync` is public and has service accounts off.

## Step 2: Fix the method and rotate the secret

Set the method back to client ID and secret, then generate a new secret:

```sh
REPORTER_ID=$(kcadm get clients -r inventory -q clientId=inventory-reporter --fields id --format csv --noquotes | tr -d '\r')
kcadm update "clients/$REPORTER_ID" -r inventory -s clientAuthenticatorType=client-secret
kcadm create "clients/$REPORTER_ID/client-secret" -r inventory
kcadm get "clients/$REPORTER_ID/client-secret" -r inventory
```

The last command prints the new secret in the field `value`. The value `leaked-secret` no longer works.

## Step 3: Give the reporting service account the role

```sh
kcadm add-roles -r inventory --uusername service-account-inventory-reporter --rolename inventory-reader
```

## Step 4: Turn inventory-sync into a service client

Make it confidential and turn on service accounts, then give its service account the role:

```sh
SYNC_ID=$(kcadm get clients -r inventory -q clientId=inventory-sync --fields id --format csv --noquotes | tr -d '\r')
kcadm update "clients/$SYNC_ID" -r inventory -s publicClient=false -s serviceAccountsEnabled=true
kcadm add-roles -r inventory --uusername service-account-inventory-sync --rolename inventory-reader
kcadm get "clients/$SYNC_ID/client-secret" -r inventory
```

Keycloak creates a secret when a client becomes confidential, and the last command prints it. Request a token for each client with its current secret and check `realm_access.roles` in it. Run `astrona submit` to grade the capstone.
