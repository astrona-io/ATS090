# Solution: Require DPoP Binding

Work the task yourself first. Running `astrona submit -c sections/section-130/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

## Step 1: Request tokens

```sh
NAMESPACE=bound-demo
for C in payments legacy; do
  kubectl -n "$NAMESPACE" exec deploy/tester -- \
    curl -s -o /dev/null -w "$C %{http_code}\n" http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=client_credentials -d client_id=$C-client -d client_secret=$C-secret
done
```

Both return `200`.

## Step 2: Require DPoP on payments-client

```sh
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
CLIENT_ID=$(kcadm get clients -r inventory -q clientId=payments-client --fields id --format csv --noquotes | tr -d '\r')
kcadm update "clients/$CLIENT_ID" -r inventory -s 'attributes."dpop.bound.access.tokens"=true'
```

## Step 3: Request again

Run the loop from step 1. `payments` now returns an error status such as `400`, and `legacy` still returns `200`. Run `astrona submit` to grade the lab.
