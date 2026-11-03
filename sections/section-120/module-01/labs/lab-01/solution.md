# Solution: Enable The Device Grant

Work the task yourself first. Running `astrona submit -c sections/section-120/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

## Step 1: Send the device request

```sh
NAMESPACE=device-demo
kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s -w '\n%{http_code}\n' http://keycloak:8080/realms/inventory/protocol/openid-connect/auth/device \
    -d client_id=kiosk
```

The answer is the error `unauthorized_client` with status `400`.

## Step 2: Read the client

```sh
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm get clients -r inventory -q clientId=kiosk --fields clientId,publicClient,attributes
```

The attribute `oauth2.device.authorization.grant.enabled` is `false`.

## Step 3: Enable the grant

```sh
CLIENT_ID=$(kcadm get clients -r inventory -q clientId=kiosk --fields id --format csv --noquotes | tr -d '\r')
kcadm update "clients/$CLIENT_ID" -r inventory -s 'attributes."oauth2.device.authorization.grant.enabled"=true'
```

## Step 4: Request and poll

```sh
DEVICE=$(kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/auth/device -d client_id=kiosk)
echo "$DEVICE" | jq .
DEVICE_CODE=$(echo "$DEVICE" | jq -r .device_code)
kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=urn:ietf:params:oauth:grant-type:device_code -d client_id=kiosk -d device_code="$DEVICE_CODE"
```

The poll answers `authorization_pending`. Run `astrona submit` to grade the lab.
