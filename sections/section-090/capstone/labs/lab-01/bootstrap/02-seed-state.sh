#!/usr/bin/env bash
# Creates the starting state for ats-090-capstone-090.
#
# Creates the realm inventory with four problems on the SAML client
# urn:app:billing:
#   1. the valid redirect URIs hold the wildcard *;
#   2. the assertion is not signed;
#   3. no mapper writes the email attribute;
#   4. the role list mapper writes the attribute role-list, not Role.
#
# The corrected state is NOT created here: producing it is the task.
set -euo pipefail

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

echo "[lab] Creating the starting state in the realm inventory..."
kcadm create realms -s realm=inventory -s enabled=true
kcadm create roles -r inventory -s name=billing-user
kcadm create users -r inventory -s username=alice -s enabled=true \
  -s email=alice@example.com -s emailVerified=true \
  -s firstName=Alice -s lastName=Example
kcadm set-password -r inventory --username alice --new-password alice-password
kcadm add-roles -r inventory --uusername alice --rolename billing-user
kcadm create clients -r inventory -s clientId=urn:app:billing -s protocol=saml -s enabled=true \
  -s 'redirectUris=["*"]' \
  -s 'attributes."saml_assertion_consumer_url_post"=https://billing.example.com/saml/acs' \
  -s 'attributes."saml.server.signature"=true' \
  -s 'attributes."saml.assertion.signature"=false' \
  -s 'attributes."saml_name_id_format"=email'
CLIENT_ID="$(client_uuid urn:app:billing)"
kcadm create "clients/$CLIENT_ID/protocol-mappers/models" -r inventory \
  -s name=roles -s protocol=saml -s protocolMapper=saml-role-list-mapper \
  -s 'config."attribute.name"=role-list' -s 'config."attribute.nameformat"=Basic' -s 'config."single"=false'


echo "[lab] Starting state ready."
kubectl -n "$NAMESPACE" get pods
