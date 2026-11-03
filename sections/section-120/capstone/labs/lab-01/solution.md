# Solution: Secure A Device Login For A TV App

Work the task yourself first. Running `astrona submit -c sections/section-120/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

## Step 1: Read the client

```sh
NAMESPACE=device-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm get clients -r inventory -q clientId=tv-app --fields clientId,publicClient,directAccessGrantsEnabled,attributes
```

The client is confidential, direct access grants are on, the lifetime is 3600 seconds and the interval is 1 second.

## Step 2: Fix the client

```sh
CLIENT_ID=$(kcadm get clients -r inventory -q clientId=tv-app --fields id --format csv --noquotes | tr -d '\r')
kcadm update "clients/$CLIENT_ID" -r inventory -s publicClient=true -s directAccessGrantsEnabled=false \
  -s 'attributes."oauth2.device.code.lifespan"=600' \
  -s 'attributes."oauth2.device.polling.interval"=5'
```

## Step 3: Request and poll

```sh
DEVICE=$(kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/auth/device -d client_id=tv-app)
echo "$DEVICE" | jq '{expires_in, interval}'
```

The values are `600` and `5`. Poll once with the device code and the device grant type; the answer is `authorization_pending`. Run `astrona submit` to grade the capstone.
