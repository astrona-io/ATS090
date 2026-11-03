# Solution: Sign Out A User Everywhere

Work the task yourself first. Running `astrona submit -c sections/section-070/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

## Step 1: List the sessions

```sh
NAMESPACE=logout-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
USER_ID=$(kcadm get users -r inventory -q username=alice --fields id --format csv --noquotes | tr -d '\r')
kcadm get "users/$USER_ID/sessions" -r inventory --fields id,ipAddress,start
```

Two sessions are listed.

## Step 2: End all sessions of the user

```sh
kcadm create "users/$USER_ID/logout" -r inventory -b '{}'
kcadm get "users/$USER_ID/sessions" -r inventory
```

The list is now empty.

## Step 3: Shorten the idle limit

```sh
kcadm update realms/inventory -s ssoSessionIdleTimeout=900
kcadm get realms/inventory --fields ssoSessionIdleTimeout
```

## Step 4: Check that alice can sign in

A password-grant sign-in returns tokens, because the user is not disabled. It also creates a new session, so the lab check for sessions must run before you sign in again; if you sign in, end the session once more. Run `astrona submit` to grade the lab.
