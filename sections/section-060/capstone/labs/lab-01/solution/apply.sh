#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the student.
# Taken from solution.md - if one changes, change the other.
set -eu

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

CLI_ID="$(client_uuid inventory-cli)"
kcadm update "clients/$CLI_ID" -r inventory -s 'attributes."access.token.lifespan"='
kcadm update realms/inventory -s revokeRefreshToken=true -s refreshTokenMaxReuse=0 -s offlineSessionIdleTimeout=604800
OFFLINE_SCOPE_ID="$(kcadm get client-scopes -r inventory --fields id,name --format csv --noquotes | tr -d '\r' | awk -F, '$2 == "offline_access" {print $1}')"
kcadm update "clients/$CLI_ID/optional-client-scopes/$OFFLINE_SCOPE_ID" -r inventory
