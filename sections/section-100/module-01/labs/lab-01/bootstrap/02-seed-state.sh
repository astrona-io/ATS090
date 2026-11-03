#!/usr/bin/env bash
# Creates the starting state for ats-090-lab-100-01.
#
# Creates the realm inventory with the resource server invoice-api, the
# resource invoice and the permission invoice-view, the WRONG way: its role
# policy requires the role auditor, which no user has.
#
# The corrected state is NOT created here: producing it is the task.
set -euo pipefail

NAMESPACE="authz-demo"

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
kcadm create roles -r inventory -s name=finance
kcadm create roles -r inventory -s name=auditor
for U in alice bob; do
  kcadm create users -r inventory -s username=$U -s enabled=true \
    -s email=$U@example.com -s emailVerified=true -s firstName=$U -s lastName=Example
  kcadm set-password -r inventory --username $U --new-password $U-password
done
kcadm add-roles -r inventory --uusername alice --rolename finance
kcadm create clients -r inventory -s clientId=inventory-cli -s enabled=true \
  -s publicClient=true -s standardFlowEnabled=false -s directAccessGrantsEnabled=true
kcadm create clients -r inventory -s clientId=invoice-api -s enabled=true -s publicClient=false \
  -s clientAuthenticatorType=client-secret -s secret=invoice-api-secret \
  -s standardFlowEnabled=false -s directAccessGrantsEnabled=false \
  -s serviceAccountsEnabled=true -s authorizationServicesEnabled=true
RS_ID="$(client_uuid invoice-api)"
RS=authz/resource-server
kcadm create "clients/$RS_ID/$RS/resource" -r inventory \
  -b '{"name":"invoice","type":"urn:invoice-api:resources:invoice","scopes":[{"name":"view"},{"name":"edit"}]}'
RES_ID="$(kcadm get "clients/$RS_ID/$RS/resource" -r inventory -q name=invoice --fields _id --format csv --noquotes | tr -d '\r')"
VIEW_ID="$(kcadm get "clients/$RS_ID/$RS/scope" -r inventory -q name=view --fields id --format csv --noquotes | tr -d '\r')"
ROLE_ID="$(kcadm get roles/auditor -r inventory --fields id --format csv --noquotes | tr -d '\r')"
kcadm create "clients/$RS_ID/$RS/policy/role" -r inventory \
  -b "{\"name\":\"finance-only\",\"type\":\"role\",\"logic\":\"POSITIVE\",\"decisionStrategy\":\"UNANIMOUS\",\"roles\":[{\"id\":\"$ROLE_ID\",\"required\":false}]}"
POLICY_ID="$(kcadm get "clients/$RS_ID/$RS/policy" -r inventory -q name=finance-only --fields id --format csv --noquotes | tr -d '\r')"
kcadm create "clients/$RS_ID/$RS/permission/scope" -r inventory \
  -b "{\"name\":\"invoice-view\",\"type\":\"scope\",\"logic\":\"POSITIVE\",\"decisionStrategy\":\"UNANIMOUS\",\"resources\":[\"$RES_ID\"],\"scopes\":[\"$VIEW_ID\"],\"policies\":[\"$POLICY_ID\"]}"

echo "[lab] Starting state ready."
kubectl -n "$NAMESPACE" get pods
