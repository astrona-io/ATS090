#!/usr/bin/env bash
# Creates the starting state for ats-090-lab-120-01.
#
# Creates the realm inventory with the public client kiosk, the WRONG way:
# the device authorization grant is not enabled, so the device endpoint
# answers unauthorized_client.
#
# The corrected state is NOT created here: producing it is the task.
set -euo pipefail

NAMESPACE="device-demo"

kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
# client_uuid CLIENT_ID: prints the internal id of a client in the realm inventory.
client_uuid() {
  kcadm get clients -r inventory -q clientId="$1" --fields id --format csv --noquotes | tr -d '\r'
}
# tester COMMAND...: runs a command in the tester pod (curl and jq are there).
tester() {
  kubectl -n "$NAMESPACE" exec -i deploy/tester -- "$@"
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin

echo "[lab] Creating the starting state in the realm inventory..."
kcadm create realms -s realm=inventory -s enabled=true
kcadm create users -r inventory -s username=alice -s enabled=true \
  -s email=alice@example.com -s emailVerified=true -s firstName=alice -s lastName=Example
kcadm set-password -r inventory --username alice --new-password alice-password
kcadm create clients -r inventory -s clientId=kiosk -s enabled=true \
  -s publicClient=true -s standardFlowEnabled=false \
  -s directAccessGrantsEnabled=false \
  -s 'attributes."oauth2.device.authorization.grant.enabled"=false' \
  -s 'attributes."oauth2.device.code.lifespan"=600' \
  -s 'attributes."oauth2.device.polling.interval"=5'

echo "[lab] Starting state ready."
kubectl -n "$NAMESPACE" get pods
