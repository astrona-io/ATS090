#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the student.
# Taken from solution.md - if one changes, change the other.
set -eu

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

CLI_ID="$(client_uuid inventory-cli)"
MAPPER_ID="$(kcadm get "clients/$CLI_ID/protocol-mappers/models" -r inventory --fields id,name --format csv --noquotes | tr -d '\r' | awk -F, '$2 == "groups" {print $1}')"
kcadm update "clients/$CLI_ID/protocol-mappers/models/$MAPPER_ID" -r inventory -s 'config."access.token.claim"=true'
kcadm update "clients/$CLI_ID" -r inventory -s fullScopeAllowed=false
READER_ID="$(kcadm get roles/inventory-reader -r inventory --fields id --format csv --noquotes | tr -d '\r')"
kcadm create "clients/$CLI_ID/scope-mappings/realm" -r inventory -b "[{\"id\":\"$READER_ID\",\"name\":\"inventory-reader\"}]"
AUDIT_ID="$(kcadm get client-scopes -r inventory --fields id,name --format csv --noquotes | tr -d '\r' | awk -F, '$2 == "inventory-audit" {print $1}')"
kcadm delete "clients/$CLI_ID/optional-client-scopes/$AUDIT_ID" -r inventory
kcadm update "clients/$CLI_ID/default-client-scopes/$AUDIT_ID" -r inventory
