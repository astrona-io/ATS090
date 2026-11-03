#!/usr/bin/env bash
# Creates the starting state for ats-090-lab-010-02.
#
# Creates the realm inventory with the user alice and the client inventory-web,
# the WRONG way: the implicit flow and direct access grants are on, and the full
# scope is allowed, so the client carries the user's administrator role.
#
# The corrected state is NOT created here: producing it is the task.
set -euo pipefail

NAMESPACE="clients-demo"

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
  -s email=alice@example.com -s emailVerified=true \
  -s firstName=Alice -s lastName=Example
kcadm set-password -r inventory --username alice --new-password alice-password
kcadm create roles -r inventory -s name=inventory-admin
kcadm add-roles -r inventory --uusername alice --rolename inventory-admin
kcadm create clients -r inventory -s clientId=inventory-web -s enabled=true \
  -s publicClient=true -s standardFlowEnabled=true -s implicitFlowEnabled=true \
  -s directAccessGrantsEnabled=true -s fullScopeAllowed=true -s rootUrl=http://localhost:5173 \
  -s 'redirectUris=["http://localhost:5173/callback"]' -s 'webOrigins=["+"]'


echo "[lab] Starting state ready."
kubectl -n "$NAMESPACE" get pods
