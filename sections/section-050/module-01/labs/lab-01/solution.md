# Solution: Repair A Service Client

Work the task yourself first. Running `astrona submit -c sections/section-050/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the client's settings, the token request, and the roles in the token.

## Step 1: Read the error

Define the helpers and send the token request:

```sh
NAMESPACE=m2m-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s -u inventory-reporter:inventory-reporter-secret \
    http://keycloak:8080/realms/inventory/protocol/openid-connect/token -d grant_type=client_credentials
```

Keycloak answers with the error `unauthorized_client`. The secret is right. The client is not allowed to use the grant.

## Step 2: Turn on service accounts

Read the settings that decide it:

```sh
kcadm get clients -r inventory -q clientId=inventory-reporter --fields clientId,publicClient,serviceAccountsEnabled
```

The client is confidential, but `serviceAccountsEnabled` is `false`. Turn it on:

```sh
REPORTER_ID=$(kcadm get clients -r inventory -q clientId=inventory-reporter --fields id --format csv --noquotes | tr -d '\r')
kcadm update "clients/$REPORTER_ID" -r inventory -s serviceAccountsEnabled=true
```

Send the token request again. It now returns an access token.

## Step 3: Give the service account the role

Keycloak has created the user `service-account-inventory-reporter`. Give it the role:

```sh
kcadm add-roles -r inventory --uusername service-account-inventory-reporter --rolename inventory-reader
```

## Step 4: Check the roles in a new token

```sh
kubectl -n "$NAMESPACE" exec deploy/tester -- sh -c '
  curl -s -u inventory-reporter:inventory-reporter-secret \
    http://keycloak:8080/realms/inventory/protocol/openid-connect/token -d grant_type=client_credentials \
  | jq -r .access_token | jq -R "split(\".\")[1] | gsub(\"-\";\"+\") | gsub(\"_\";\"/\") | @base64d | fromjson | .realm_access.roles"'
```

The list holds `inventory-reader` and no `inventory-admin`. Run `astrona submit` to grade the lab.
