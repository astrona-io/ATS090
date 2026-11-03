#!/usr/bin/env bash
# Creates the starting state for ats-090-capstone-120.
#
# Creates the realm inventory with the client tv-app, the WRONG way:
#   1. it is a confidential client;
#   2. the code lifetime is 3600 seconds;
#   3. the polling interval is 1 second;
#   4. direct access grants are on.
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
kcadm create clients -r inventory -s clientId=tv-app -s enabled=true \
  -s publicClient=false -s standardFlowEnabled=false \
  -s directAccessGrantsEnabled=true \
  -s clientAuthenticatorType=client-secret -s secret=tv-secret \
  -s 'attributes."oauth2.device.authorization.grant.enabled"=true' \
  -s 'attributes."oauth2.device.code.lifespan"=3600' \
  -s 'attributes."oauth2.device.polling.interval"=1'

echo "[lab] Starting state ready."
kubectl -n "$NAMESPACE" get pods
