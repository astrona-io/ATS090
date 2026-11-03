# Solution: Fix The Token Lifetimes Of A Client

Work the task yourself first. Running `astrona submit -c sections/section-060/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

## Step 1: Read the realm and the client

```sh
NAMESPACE=sessions-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm get realms/inventory --fields accessTokenLifespan,revokeRefreshToken,offlineSessionIdleTimeout
kcadm get clients -r inventory -q clientId=inventory-cli --fields id,attributes,optionalClientScopes
```

The realm lifespan is the default `300`, so the long lifetime comes from the client attribute `access.token.lifespan`, which is `86400`. The client's optional client scopes do not list `offline_access`.

## Step 2: Remove the client override

```sh
CLI_ID=$(kcadm get clients -r inventory -q clientId=inventory-cli --fields id --format csv --noquotes | tr -d '\r')
kcadm update "clients/$CLI_ID" -r inventory -s 'attributes."access.token.lifespan"='
```

## Step 3: Rotate refresh tokens and extend the offline idle time

```sh
kcadm update realms/inventory -s revokeRefreshToken=true -s refreshTokenMaxReuse=0 -s offlineSessionIdleTimeout=604800
```

## Step 4: Give the client the offline_access scope again

Find the id of the scope and add it as an optional scope of the client:

```sh
OFFLINE_SCOPE_ID=$(kcadm get client-scopes -r inventory --fields id,name --format csv --noquotes | tr -d '\r' | awk -F, '$2 == "offline_access" {print $1}')
kcadm update "clients/$CLI_ID/optional-client-scopes/$OFFLINE_SCOPE_ID" -r inventory
```

## Step 5: Check each result

Sign in with `scope=openid offline_access` and decode the refresh token: its `typ` is `Offline`. Measure `exp - iat` in a new access token, and use a refresh token twice. Run `astrona submit` to grade the capstone.
