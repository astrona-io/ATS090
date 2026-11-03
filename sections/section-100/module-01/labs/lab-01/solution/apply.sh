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
POLICY_ID="$(kcadm get "clients/$RS_ID/$RS/policy" -r inventory -q name=finance-only --fields id --format csv --noquotes | tr -d '\r')"
ROLE_ID="$(kcadm get roles/finance -r inventory --fields id --format csv --noquotes | tr -d '\r')"
kcadm update "clients/$RS_ID/$RS/policy/role/$POLICY_ID" -r inventory \
  -b "{\"id\":\"$POLICY_ID\",\"name\":\"finance-only\",\"type\":\"role\",\"logic\":\"POSITIVE\",\"decisionStrategy\":\"UNANIMOUS\",\"roles\":[{\"id\":\"$ROLE_ID\",\"required\":false}]}"
