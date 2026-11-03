#!/usr/bin/env bash
# Creates the starting state for ats-090-lab-050-01.
#
# Creates the realm inventory, the roles inventory-reader and inventory-admin, and
# the confidential client inventory-reporter the WRONG way: service accounts
# are off, so the client cannot get a token, and its service account has no role.
#
# The corrected state is NOT created here: producing it is the task.
set -euo pipefail

NAMESPACE="m2m-demo"

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
kcadm create roles -r inventory -s name=inventory-reader
kcadm create roles -r inventory -s name=inventory-admin
kcadm create clients -r inventory -s clientId=inventory-reporter -s enabled=true \
  -s publicClient=false -s serviceAccountsEnabled=false \
  -s standardFlowEnabled=false -s directAccessGrantsEnabled=false \
  -s secret=inventory-reporter-secret

echo "[lab] Starting state ready."
kubectl -n "$NAMESPACE" get pods
