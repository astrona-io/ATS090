# Solution: Repair The Logout Of A Client

Work the task yourself first. Running `astrona submit -c sections/section-070/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

## Step 1: Read the client attributes

```sh
NAMESPACE=logout-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
CLI_ID=$(kcadm get clients -r inventory -q clientId=inventory-cli --fields id --format csv --noquotes | tr -d '\r')
kcadm get "clients/$CLI_ID" -r inventory --fields attributes
```

`post.logout.redirect.uris` is `*` and `backchannel.logout.session.required` is `false`.

## Step 2: Fix the client

```sh
kcadm update "clients/$CLI_ID" -r inventory \
  -s 'attributes."post.logout.redirect.uris"=https://app.example.com/signed-out' \
  -s 'attributes."backchannel.logout.url"=http://app-backend.logout-demo.svc:8080/backchannel-logout' \
  -s 'attributes."backchannel.logout.session.required"=true'
```

## Step 3: End the sessions of alice

```sh
USER_ID=$(kcadm get users -r inventory -q username=alice --fields id --format csv --noquotes | tr -d '\r')
kcadm get "users/$USER_ID/sessions" -r inventory --fields id
kcadm create "users/$USER_ID/logout" -r inventory -b '{}'
kcadm get "users/$USER_ID/sessions" -r inventory
```

The last list is empty. Run `astrona submit` to grade the capstone.
