#!/usr/bin/env bash
# Creates the starting state for ats-090-capstone-070.
#
# Creates the realm inventory with four problems on inventory-cli:
#   1. post.logout.redirect.uris is the wildcard *;
#   2. no back-channel logout URL;
#   3. backchannel.logout.session.required is false;
#   4. alice is signed in twice.
#
# The corrected state is NOT created here: producing it is the task.
set -euo pipefail

NAMESPACE="logout-demo"

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
kcadm create clients -r inventory -s clientId=inventory-cli -s enabled=true \
  -s publicClient=true -s standardFlowEnabled=false -s directAccessGrantsEnabled=true
CLI_ID="$(client_uuid inventory-cli)"
kcadm update "clients/$CLI_ID" -r inventory \
  -s 'attributes."post.logout.redirect.uris"=*' \
  -s 'attributes."backchannel.logout.session.required"=false'
for _ in 1 2; do
  tester curl -s -o /dev/null http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=inventory-cli \
    -d username=alice -d password=alice-password -d scope=openid
done

echo "[lab] Starting state ready."
kubectl -n "$NAMESPACE" get pods
