#!/usr/bin/env bash
# Creates the starting state for ats-090-capstone-010.
#
# Creates the realm inventory with two clients set up the WRONG way:
#   - inventory-web: implicit flow on, a wildcard redirect URI next to a path
#     wildcard, and every web origin allowed;
#   - inventory-reporter: a public client without a service account, so the
#     client credentials grant fails.
#
# The corrected clients are NOT created here — producing them is the task.
set -euo pipefail

NAMESPACE="clientscapstone-demo"

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
kcadm create clients -r inventory -s clientId=inventory-cli -s enabled=true \
  -s publicClient=true -s standardFlowEnabled=false -s directAccessGrantsEnabled=true
kcadm create clients -r inventory -s clientId=inventory-web -s enabled=true \
  -s publicClient=true -s standardFlowEnabled=true -s implicitFlowEnabled=true \
  -s directAccessGrantsEnabled=false \
  -s 'redirectUris=["http://localhost:5173/*","*"]' -s 'webOrigins=["*"]'
kcadm create clients -r inventory -s clientId=inventory-reporter -s enabled=true \
  -s publicClient=true -s serviceAccountsEnabled=false \
  -s standardFlowEnabled=false -s directAccessGrantsEnabled=false

echo "[lab] Starting state ready."
kubectl -n "$NAMESPACE" get pods
echo "[lab] Both clients are set up the wrong way. Fixing them is the task."
