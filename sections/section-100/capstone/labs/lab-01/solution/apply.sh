#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the student.
# Taken from solution.md - if one changes, change the other.
set -eu

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

RS_ID="$(client_uuid invoice-api)"
RS=authz/resource-server
FIN_POL="$(kcadm get "clients/$RS_ID/$RS/policy" -r inventory -q name=finance-policy --fields id --format csv --noquotes | tr -d '\r')"
ADM_POL="$(kcadm get "clients/$RS_ID/$RS/policy" -r inventory -q name=admin-policy --fields id --format csv --noquotes | tr -d '\r')"
FIN_ROLE="$(kcadm get roles/finance -r inventory --fields id --format csv --noquotes | tr -d '\r')"
kcadm update "clients/$RS_ID/$RS/policy/role/$FIN_POL" -r inventory \
  -b "{\"id\":\"$FIN_POL\",\"name\":\"finance-policy\",\"type\":\"role\",\"logic\":\"POSITIVE\",\"decisionStrategy\":\"UNANIMOUS\",\"roles\":[{\"id\":\"$FIN_ROLE\",\"required\":false}]}"
PERM_ID="$(kcadm get "clients/$RS_ID/$RS/permission" -r inventory -q name=report-delete --fields id --format csv --noquotes | tr -d '\r')"
RES_ID="$(kcadm get "clients/$RS_ID/$RS/resource" -r inventory -q name=report --fields _id --format csv --noquotes | tr -d '\r')"
DELETE_ID="$(kcadm get "clients/$RS_ID/$RS/scope" -r inventory -q name=delete --fields id --format csv --noquotes | tr -d '\r')"
kcadm update "clients/$RS_ID/$RS/permission/scope/$PERM_ID" -r inventory \
  -b "{\"id\":\"$PERM_ID\",\"name\":\"report-delete\",\"type\":\"scope\",\"logic\":\"POSITIVE\",\"decisionStrategy\":\"UNANIMOUS\",\"resources\":[\"$RES_ID\"],\"scopes\":[\"$DELETE_ID\"],\"policies\":[\"$ADM_POL\"]}"
