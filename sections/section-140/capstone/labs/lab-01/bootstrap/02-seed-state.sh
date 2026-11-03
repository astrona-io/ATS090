#!/usr/bin/env bash
# Creates the starting state for ats-090-capstone-140.
#
# Creates the realm inventory with the client gateway and the API client
# orders-api, with four faults on gateway:
#   1. the redirect address is a wildcard;
#   2. access tokens live 3600 seconds;
#   3. the audience mapper names order-api, not orders-api;
#   4. the groups mapper writes the claim group, not groups.
#
# The corrected state is NOT created here: producing it is the task.
set -euo pipefail

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

echo "[lab] Creating the starting state in the realm inventory..."
kcadm create realms -s realm=inventory -s enabled=true
GROUP_ID="$(kcadm create groups -r inventory -s name=staff -i | tr -d '\r')"
USER_ID="$(kcadm create users -r inventory -s username=alice -s enabled=true \
  -s email=alice@example.com -s emailVerified=true \
  -s firstName=Alice -s lastName=Example -i | tr -d '\r')"
kcadm set-password -r inventory --username alice --new-password alice-password
kcadm update "users/$USER_ID/groups/$GROUP_ID" -r inventory -s realm=inventory -s userId="$USER_ID" -s groupId="$GROUP_ID" -n
kcadm create clients -r inventory -s clientId=orders-api -s enabled=true -s publicClient=false \
  -s clientAuthenticatorType=client-secret -s secret=orders-api-secret \
  -s standardFlowEnabled=false -s directAccessGrantsEnabled=false
kcadm create clients -r inventory -s clientId=gateway -s enabled=true -s publicClient=false \
  -s clientAuthenticatorType=client-secret -s secret=gateway-secret \
  -s standardFlowEnabled=true -s directAccessGrantsEnabled=true \
  -s 'redirectUris=["https://orders.example.com/*"]' \
  -s 'attributes."access.token.lifespan"=3600'
GW_ID="$(client_uuid gateway)"
kcadm create "clients/$GW_ID/protocol-mappers/models" -r inventory \
  -s name=audience -s protocol=openid-connect -s protocolMapper=oidc-audience-mapper \
  -s 'config."included.client.audience"=order-api' \
  -s 'config."access.token.claim"=true' -s 'config."id.token.claim"=false'
kcadm create "clients/$GW_ID/protocol-mappers/models" -r inventory \
  -s name=groups -s protocol=openid-connect -s protocolMapper=oidc-group-membership-mapper \
  -s 'config."claim.name"=group' -s 'config."full.path"=false' \
  -s 'config."access.token.claim"=true' -s 'config."id.token.claim"=true' -s 'config."userinfo.token.claim"=true'


echo "[lab] Starting state ready."
kubectl -n "$NAMESPACE" get pods
