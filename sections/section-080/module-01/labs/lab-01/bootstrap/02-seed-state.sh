#!/usr/bin/env bash
# Creates the starting state for ats-090-lab-080-01.
#
# Creates the realm inventory with the user alice (member of the group
# logistics) and the public client inventory-cli, which has no mapper that
# writes a groups claim or a tenant claim.
#
# The corrected state is NOT created here: producing it is the task.
set -euo pipefail

NAMESPACE="scopes-demo"

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
GROUP_ID="$(kcadm create groups -r inventory -s name=logistics -i | tr -d '\r')"
USER_ID="$(kcadm create users -r inventory -s username=alice -s enabled=true \
  -s email=alice@example.com -s emailVerified=true \
  -s firstName=Alice -s lastName=Example -i | tr -d '\r')"
kcadm set-password -r inventory --username alice --new-password alice-password
kcadm update "users/$USER_ID/groups/$GROUP_ID" -r inventory -s realm=inventory -s userId="$USER_ID" -s groupId="$GROUP_ID" -n
kcadm add-roles -r inventory --uusername alice --rolename inventory-reader --rolename inventory-admin
kcadm create clients -r inventory -s clientId=inventory-cli -s enabled=true \
  -s publicClient=true -s standardFlowEnabled=false -s directAccessGrantsEnabled=true

echo "[lab] Starting state ready."
kubectl -n "$NAMESPACE" get pods
