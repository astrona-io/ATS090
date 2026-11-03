#!/usr/bin/env bash
# Creates the starting state for ats-090-capstone-050.
#
# Creates the realm inventory and three problems:
#   1. inventory-reporter accepts only a signed JWT, so its secret is refused,
#      and its service account has no role;
#   2. the secret of inventory-reporter, leaked-secret, was posted in a chat;
#   3. inventory-sync is a public client with service accounts off.
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
  -s publicClient=false -s serviceAccountsEnabled=true -s clientAuthenticatorType=client-jwt \
  -s standardFlowEnabled=false -s directAccessGrantsEnabled=false \
  -s secret=leaked-secret
kcadm create clients -r inventory -s clientId=inventory-sync -s enabled=true \
  -s publicClient=true -s serviceAccountsEnabled=false \
  -s standardFlowEnabled=false -s directAccessGrantsEnabled=false

echo "[lab] Starting state ready."
kubectl -n "$NAMESPACE" get pods
