#!/usr/bin/env bash
# Creates the starting state for ats-090-capstone-060.
#
# Creates the realm inventory with four problems:
#   1. inventory-cli overrides the access token lifespan with one day;
#   2. refresh tokens are not revoked after use;
#   3. inventory-cli lost the optional client scope offline_access;
#   4. the offline session idle time is 60 seconds.
#
# The corrected state is NOT created here: producing it is the task.
set -euo pipefail

NAMESPACE="sessions-demo"

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
kcadm create realms -s realm=inventory -s enabled=true \
  -s revokeRefreshToken=false -s offlineSessionIdleTimeout=60
kcadm create users -r inventory -s username=alice -s enabled=true \
  -s email=alice@example.com -s emailVerified=true \
  -s firstName=Alice -s lastName=Example
kcadm set-password -r inventory --username alice --new-password alice-password
kcadm create clients -r inventory -s clientId=inventory-cli -s enabled=true \
  -s publicClient=true -s standardFlowEnabled=false -s directAccessGrantsEnabled=true
CLI_ID="$(client_uuid inventory-cli)"
kcadm update "clients/$CLI_ID" -r inventory -s 'attributes."access.token.lifespan"=86400'
OFFLINE_SCOPE_ID="$(kcadm get client-scopes -r inventory --fields id,name --format csv --noquotes | tr -d '\r' | awk -F, '$2 == "offline_access" {print $1}')"
kcadm delete "clients/$CLI_ID/optional-client-scopes/$OFFLINE_SCOPE_ID" -r inventory

echo "[lab] Starting state ready."
kubectl -n "$NAMESPACE" get pods
