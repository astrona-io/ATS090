#!/usr/bin/env bash
# Creates the starting state for ats-090-capstone-040.
#
# Creates the realm inventory with two APIs, inventory-api and reporting-api,
# and four faults on the way from alice's token to reporting-api:
#   - inventory-cli's tokens do not carry inventory-gateway in aud;
#   - standard token exchange is off for inventory-gateway;
#   - inventory-gateway may request inventory-api as an audience, but not
#     reporting-api;
#   - alice does not have the realm role reporting-reader.
# The client inventory-admin-api exists and must stay out of reach.
#
# None of this is fixed here — fixing it is the task.
set -euo pipefail

NAMESPACE="exchangecapstone-demo"

kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
# client_uuid CLIENT_ID: prints the internal id of a client in the realm inventory.
client_uuid() {
  kcadm get clients -r inventory -q clientId="$1" --fields id --format csv --noquotes | tr -d '\r'
}
# scope_uuid NAME: prints the internal id of a client scope in the realm inventory.
scope_uuid() {
  kcadm get client-scopes -r inventory --fields id,name --format csv --noquotes \
    | tr -d '\r' | awk -F, -v name="$1" '$2 == name {print $1}'
}
# add_audience_mapper CLIENT_ID AUDIENCE: adds an audience mapper to the
# client's dedicated scope, so its access tokens carry AUDIENCE in aud.
add_audience_mapper() {
  kcadm create "clients/$(client_uuid "$1")/protocol-mappers/models" -r inventory \
    -s name="audience-$2" -s protocol=openid-connect -s protocolMapper=oidc-audience-mapper \
    -s 'config."included.client.audience"='"$2" \
    -s 'config."access.token.claim"=true' -s 'config."id.token.claim"=false' \
    -s 'config."introspection.token.claim"=true'
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin

echo "[lab] Creating the starting state in the realm inventory..."
kcadm create realms -s realm=inventory -s enabled=true
kcadm create users -r inventory -s username=alice -s enabled=true \
  -s email=alice@example.com -s emailVerified=true \
  -s firstName=Alice -s lastName=Example
kcadm set-password -r inventory --username alice --new-password alice-password
kcadm create roles -r inventory -s name=inventory-reader
kcadm add-roles -r inventory --uusername alice --rolename inventory-reader
kcadm create roles -r inventory -s name=reporting-reader
kcadm create clients -r inventory -s clientId=inventory-cli -s enabled=true \
  -s publicClient=true -s standardFlowEnabled=false -s directAccessGrantsEnabled=true
kcadm create clients -r inventory -s clientId=inventory-gateway -s enabled=true \
  -s publicClient=false -s standardFlowEnabled=false -s directAccessGrantsEnabled=false \
  -s serviceAccountsEnabled=false -s secret=inventory-gateway-secret
kcadm create clients -r inventory -s clientId=inventory-api -s enabled=true \
  -s publicClient=false -s standardFlowEnabled=false -s directAccessGrantsEnabled=false \
  -s serviceAccountsEnabled=false
kcadm create clients -r inventory -s clientId=reporting-api -s enabled=true \
  -s publicClient=false -s standardFlowEnabled=false -s directAccessGrantsEnabled=false \
  -s serviceAccountsEnabled=false
kcadm create clients -r inventory -s clientId=inventory-admin-api -s enabled=true \
  -s publicClient=false -s standardFlowEnabled=false -s directAccessGrantsEnabled=false \
  -s serviceAccountsEnabled=false
add_audience_mapper inventory-gateway inventory-api
# Keep a copy of the API code and settings, so the grader can tell whether the
# API was changed instead of Keycloak.
kubectl -n "$NAMESPACE" create configmap lab-baseline \
  --from-literal=server.js="$(kubectl -n "$NAMESPACE" get configmap inventory-api-code -o jsonpath='{.data.server\.js}')" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "[lab] Starting state ready."
kubectl -n "$NAMESPACE" get pods
echo "[lab] alice's requests cannot reach reporting-api through the gateway. Fixing that is the task."
