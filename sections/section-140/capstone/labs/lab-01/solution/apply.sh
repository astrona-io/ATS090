#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the student.
# Taken from solution.md - if one changes, change the other.
set -eu

NAMESPACE="proxy-demo"

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

GW_ID="$(client_uuid gateway)"
kcadm update "clients/$GW_ID" -r inventory \
  -s 'redirectUris=["https://orders.example.com/oauth2/callback"]' \
  -s 'attributes."access.token.lifespan"=300'
AUD_ID="$(kcadm get "clients/$GW_ID/protocol-mappers/models" -r inventory --fields id,name --format csv --noquotes | tr -d '\r' | awk -F, '$2 == "audience" {print $1}')"
GRP_ID="$(kcadm get "clients/$GW_ID/protocol-mappers/models" -r inventory --fields id,name --format csv --noquotes | tr -d '\r' | awk -F, '$2 == "groups" {print $1}')"
kcadm update "clients/$GW_ID/protocol-mappers/models/$AUD_ID" -r inventory -s 'config."included.client.audience"=orders-api'
kcadm update "clients/$GW_ID/protocol-mappers/models/$GRP_ID" -r inventory -s 'config."claim.name"=groups'
