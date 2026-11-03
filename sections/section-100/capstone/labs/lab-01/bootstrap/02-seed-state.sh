#!/usr/bin/env bash
# Creates the starting state for ats-090-capstone-100.
#
# Creates the realm inventory with the resource server invoice-api and the
# resource report (scopes read and delete), with two faults:
#   1. the policy finance-policy has the logic NEGATIVE;
#   2. the permission report-delete uses finance-policy, not admin-policy.
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
kcadm create roles -r inventory -s name=report-admin
for U in alice bob carol; do
  kcadm create users -r inventory -s username=$U -s enabled=true \
    -s email=$U@example.com -s emailVerified=true -s firstName=$U -s lastName=Example
  kcadm set-password -r inventory --username $U --new-password $U-password
done
kcadm add-roles -r inventory --uusername alice --rolename finance
kcadm add-roles -r inventory --uusername carol --rolename finance --rolename report-admin
kcadm create clients -r inventory -s clientId=inventory-cli -s enabled=true \
  -s publicClient=true -s standardFlowEnabled=false -s directAccessGrantsEnabled=true
kcadm create clients -r inventory -s clientId=invoice-api -s enabled=true -s publicClient=false \
  -s clientAuthenticatorType=client-secret -s secret=invoice-api-secret \
  -s standardFlowEnabled=false -s directAccessGrantsEnabled=false \
  -s serviceAccountsEnabled=true -s authorizationServicesEnabled=true
RS_ID="$(client_uuid invoice-api)"
RS=authz/resource-server
kcadm create "clients/$RS_ID/$RS/resource" -r inventory \
  -b '{"name":"report","type":"urn:invoice-api:resources:report","scopes":[{"name":"read"},{"name":"delete"}]}'
RES_ID="$(kcadm get "clients/$RS_ID/$RS/resource" -r inventory -q name=report --fields _id --format csv --noquotes | tr -d '\r')"
READ_ID="$(kcadm get "clients/$RS_ID/$RS/scope" -r inventory -q name=read --fields id --format csv --noquotes | tr -d '\r')"
DELETE_ID="$(kcadm get "clients/$RS_ID/$RS/scope" -r inventory -q name=delete --fields id --format csv --noquotes | tr -d '\r')"
FIN_ROLE="$(kcadm get roles/finance -r inventory --fields id --format csv --noquotes | tr -d '\r')"
ADM_ROLE="$(kcadm get roles/report-admin -r inventory --fields id --format csv --noquotes | tr -d '\r')"
kcadm create "clients/$RS_ID/$RS/policy/role" -r inventory \
  -b "{\"name\":\"finance-policy\",\"type\":\"role\",\"logic\":\"NEGATIVE\",\"decisionStrategy\":\"UNANIMOUS\",\"roles\":[{\"id\":\"$FIN_ROLE\",\"required\":false}]}"
kcadm create "clients/$RS_ID/$RS/policy/role" -r inventory \
  -b "{\"name\":\"admin-policy\",\"type\":\"role\",\"logic\":\"POSITIVE\",\"decisionStrategy\":\"UNANIMOUS\",\"roles\":[{\"id\":\"$ADM_ROLE\",\"required\":false}]}"
FIN_POL="$(kcadm get "clients/$RS_ID/$RS/policy" -r inventory -q name=finance-policy --fields id --format csv --noquotes | tr -d '\r')"
kcadm create "clients/$RS_ID/$RS/permission/scope" -r inventory \
  -b "{\"name\":\"report-read\",\"type\":\"scope\",\"logic\":\"POSITIVE\",\"decisionStrategy\":\"UNANIMOUS\",\"resources\":[\"$RES_ID\"],\"scopes\":[\"$READ_ID\"],\"policies\":[\"$FIN_POL\"]}"
kcadm create "clients/$RS_ID/$RS/permission/scope" -r inventory \
  -b "{\"name\":\"report-delete\",\"type\":\"scope\",\"logic\":\"POSITIVE\",\"decisionStrategy\":\"UNANIMOUS\",\"resources\":[\"$RES_ID\"],\"scopes\":[\"$DELETE_ID\"],\"policies\":[\"$FIN_POL\"]}"

echo "[lab] Starting state ready."
kubectl -n "$NAMESPACE" get pods
