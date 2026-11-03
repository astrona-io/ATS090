#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the student.
# Taken from solution.md - if one changes, change the other.
set -eu

NAMESPACE="saml-demo"

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

CLIENT_ID="$(client_uuid urn:app:billing)"
kcadm update "clients/$CLIENT_ID" -r inventory \
  -s 'redirectUris=["https://billing.example.com/saml/acs"]' \
  -s 'attributes."saml.assertion.signature"=true'
kcadm create "clients/$CLIENT_ID/protocol-mappers/models" -r inventory \
  -s name=email -s protocol=saml -s protocolMapper=saml-user-property-mapper \
  -s 'config."user.attribute"=email' -s 'config."attribute.name"=email' \
  -s 'config."friendly.name"=email' -s 'config."attribute.nameformat"=Basic'
MAPPER_ID="$(kcadm get "clients/$CLIENT_ID/protocol-mappers/models" -r inventory --fields id,name --format csv --noquotes | tr -d '\r' | awk -F, '$2 == "roles" {print $1}')"
kcadm update "clients/$CLIENT_ID/protocol-mappers/models/$MAPPER_ID" -r inventory -s 'config."attribute.name"=Role'
