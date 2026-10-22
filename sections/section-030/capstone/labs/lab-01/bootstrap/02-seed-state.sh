#!/usr/bin/env bash
# Creates the starting state for ats-090-capstone-030.
#
# Creates the realm inventory where alice's tokens from inventory-cli fail
# inventory-api's checks for three separate reasons:
#   - no audience mapper, so aud lacks inventory-api;
#   - alice does not have the realm role inventory-reader;
#   - the client scope roles is removed from inventory-cli, so the token has
#     no realm_access claim at all.
#
# None of this is fixed here — fixing it is the task.
set -euo pipefail

NAMESPACE="tokenscapstone-demo"

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
kcadm create clients -r inventory -s clientId=inventory-cli -s enabled=true \
  -s publicClient=true -s standardFlowEnabled=false -s directAccessGrantsEnabled=true
kcadm create clients -r inventory -s clientId=inventory-reporter -s enabled=true \
  -s publicClient=false -s serviceAccountsEnabled=true \
  -s standardFlowEnabled=false -s directAccessGrantsEnabled=false \
  -s secret=inventory-reporter-secret
kcadm create clients -r inventory -s clientId=inventory-api -s enabled=true \
  -s publicClient=false -s standardFlowEnabled=false -s directAccessGrantsEnabled=false \
  -s serviceAccountsEnabled=false
kcadm delete "clients/$(client_uuid inventory-cli)/default-client-scopes/$(scope_uuid roles)" -r inventory
# Keep a copy of the API code and settings, so the grader can tell whether the
# API was changed instead of Keycloak.
kubectl -n "$NAMESPACE" create configmap lab-baseline \
  --from-literal=server.js="$(kubectl -n "$NAMESPACE" get configmap inventory-api-code -o jsonpath='{.data.server\.js}')" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "[lab] Starting state ready."
kubectl -n "$NAMESPACE" get pods
echo "[lab] inventory-api rejects every token alice gets. Fixing Keycloak is the task."
