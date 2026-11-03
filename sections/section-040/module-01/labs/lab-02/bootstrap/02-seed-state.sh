#!/usr/bin/env bash
# Creates the starting state for ats-090-lab-040-02.
#
# Creates the realm inventory with alice, the clients inventory-cli,
# inventory-gateway, inventory-api and inventory-admin-api, the WRONG way:
# inventory-cli's tokens do not name the gateway, so the exchange is refused, and
# the gateway holds the audience of inventory-admin-api as well.
#
# The corrected state is NOT created here: producing it is the task.
set -euo pipefail

NAMESPACE="exchange-demo"

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
kcadm create users -r inventory -s username=alice -s enabled=true \
  -s email=alice@example.com -s emailVerified=true \
  -s firstName=Alice -s lastName=Example
kcadm set-password -r inventory --username alice --new-password alice-password
kcadm create roles -r inventory -s name=inventory-reader
kcadm add-roles -r inventory --uusername alice --rolename inventory-reader
kcadm create clients -r inventory -s clientId=inventory-cli -s enabled=true \
  -s publicClient=true -s standardFlowEnabled=false -s directAccessGrantsEnabled=true
kcadm create clients -r inventory -s clientId=inventory-gateway -s enabled=true \
  -s publicClient=false -s standardFlowEnabled=false -s directAccessGrantsEnabled=false \
  -s serviceAccountsEnabled=false -s secret=inventory-gateway-secret \
  -s 'attributes."standard.token.exchange.enabled"=true'
kcadm create clients -r inventory -s clientId=inventory-api -s enabled=true \
  -s publicClient=false -s standardFlowEnabled=false -s directAccessGrantsEnabled=false \
  -s serviceAccountsEnabled=false
kcadm create clients -r inventory -s clientId=inventory-admin-api -s enabled=true \
  -s publicClient=false -s standardFlowEnabled=false -s directAccessGrantsEnabled=false \
  -s serviceAccountsEnabled=false
GW_ID="$(client_uuid inventory-gateway)"
kcadm create "clients/$GW_ID/protocol-mappers/models" -r inventory \
  -s name=audience-inventory-api -s protocol=openid-connect -s protocolMapper=oidc-audience-mapper \
  -s 'config."included.client.audience"=inventory-api' \
  -s 'config."access.token.claim"=true' -s 'config."id.token.claim"=false' \
  -s 'config."introspection.token.claim"=true'
kcadm create "clients/$GW_ID/protocol-mappers/models" -r inventory \
  -s name=audience-inventory-admin-api -s protocol=openid-connect -s protocolMapper=oidc-audience-mapper \
  -s 'config."included.client.audience"=inventory-admin-api' \
  -s 'config."access.token.claim"=true' -s 'config."id.token.claim"=false' \
  -s 'config."introspection.token.claim"=true'


echo "[lab] Starting state ready."
kubectl -n "$NAMESPACE" get pods
