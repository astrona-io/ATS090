# Solution: Bind Tokens For A Payments Platform

Work the task yourself first. Running `astrona submit -c sections/section-130/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

## Step 1: Read the clients

```sh
NAMESPACE=bound-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm get clients -r inventory -q clientId=payments-client --fields attributes
kcadm get clients -r inventory -q clientId=partner-client --fields attributes
```

`payments-client` has `dpop.bound.access.tokens` false and a lifespan of 3600. `partner-client` has `dpop.bound.access.tokens` true.

## Step 2: Fix both clients

```sh
PAY=$(kcadm get clients -r inventory -q clientId=payments-client --fields id --format csv --noquotes | tr -d '\r')
PARTNER=$(kcadm get clients -r inventory -q clientId=partner-client --fields id --format csv --noquotes | tr -d '\r')
kcadm update "clients/$PAY" -r inventory -s 'attributes."dpop.bound.access.tokens"=true' -s 'attributes."access.token.lifespan"=300'
kcadm update "clients/$PARTNER" -r inventory -s 'attributes."dpop.bound.access.tokens"=false'
```

## Step 3: Request tokens

```sh
for C in payments partner; do
  kubectl -n "$NAMESPACE" exec deploy/tester -- \
    curl -s -o /dev/null -w "$C %{http_code}\n" http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=client_credentials -d client_id=$C-client -d client_secret=$C-secret
done
```

`payments` returns an error status and `partner` returns `200`. Run `astrona submit` to grade the capstone.
