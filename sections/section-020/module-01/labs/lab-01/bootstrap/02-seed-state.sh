#!/usr/bin/env bash
# Creates the starting state for ats-090-lab-020-01.
#
# Creates the realm inventory, the user alice and inventory-web, with the
# client attribute pkce.code.challenge.method set to plain: the weak PKCE
# method, which sends the code verifier itself as the challenge.
#
# The corrected setting is NOT applied here — producing it is the task.
set -euo pipefail

NAMESPACE="pkce-demo"

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
kcadm create clients -r inventory -s clientId=inventory-web -s enabled=true \
  -s publicClient=true -s standardFlowEnabled=true -s implicitFlowEnabled=false \
  -s directAccessGrantsEnabled=false -s rootUrl=http://localhost:5173 \
  -s 'redirectUris=["http://localhost:5173/callback"]' -s 'webOrigins=["+"]'
kcadm update "clients/$(client_uuid inventory-web)" -r inventory \
  -s 'attributes."pkce.code.challenge.method"=plain'

echo "[lab] Starting state ready."
kubectl -n "$NAMESPACE" get pods
echo "[lab] inventory-web requires PKCE with the method plain. Requiring S256 is the task."
