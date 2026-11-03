#!/usr/bin/env bash
# Creates the starting state for ats-090-lab-020-02.
#
# Creates the realm inventory with the user alice and the client inventory-app,
# the WRONG way: the email scope was taken off the client's default scopes, so
# the UserInfo answer has no email address.
#
# The corrected state is NOT created here: producing it is the task.
set -euo pipefail

NAMESPACE="pkce-demo"

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
kcadm create clients -r inventory -s clientId=inventory-app -s enabled=true \
  -s publicClient=true -s standardFlowEnabled=false -s directAccessGrantsEnabled=true
APP_ID="$(client_uuid inventory-app)"
EMAIL_ID="$(kcadm get client-scopes -r inventory --fields id,name --format csv --noquotes | tr -d '\r' | awk -F, '$2 == "email" {print $1}')"
# The mistake: the email scope is taken off the client's default scopes.
kcadm delete "clients/$APP_ID/default-client-scopes/$EMAIL_ID" -r inventory


echo "[lab] Starting state ready."
kubectl -n "$NAMESPACE" get pods
