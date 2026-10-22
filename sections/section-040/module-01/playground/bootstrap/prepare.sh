#!/usr/bin/env bash
# OS prep for the "Propagate Tokens Through An API Gateway" playground (`ats-090-playground-040-01`).
#
# Environment preparation only. There is no task and no grading. This script:
#   1. applies the module's starting workloads (Keycloak 26.8.1, tester and
#      the module's API workloads),
#   2. waits until Keycloak and the workloads are ready,
#   3. creates the realm inventory, the user alice with the realm role inventory-reader, the clients inventory-cli, inventory-gateway and inventory-api, and an audience mapper that puts inventory-gateway in the audience of inventory-cli's tokens.
set -euo pipefail

NAMESPACE="exchange-demo"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR=""
for candidate in "$SCRIPT_DIR/../manifests" "./manifests" "$SCRIPT_DIR/manifests"; do
  [ -d "$candidate" ] && { MANIFEST_DIR="$candidate"; break; }
done

# lab-start.yaml is also listed under bootstrap.manifests in config.yaml, so it
# may already be applied. kubectl apply is idempotent.
if [ -n "$MANIFEST_DIR" ] && [ -f "$MANIFEST_DIR/lab-start.yaml" ]; then
  echo "[playground] Applying starting workloads..."
  kubectl apply -f "$MANIFEST_DIR/lab-start.yaml"
fi

# The first rollout pulls a large image and Keycloak takes a while to start.
echo "[playground] Waiting for Keycloak and the workloads (this can take a few minutes)..."
kubectl -n "$NAMESPACE" rollout status deployment/keycloak --timeout=600s
kubectl -n "$NAMESPACE" rollout status deployment/tester --timeout=300s
kubectl -n "$NAMESPACE" rollout status deployment/inventory-api --timeout=300s
kubectl -n "$NAMESPACE" rollout status deployment/inventory-gateway --timeout=300s

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

# The bootstrap administrator can need a few seconds after /health/ready.
for _ in $(seq 1 30); do
  kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin >/dev/null 2>&1 && break
  sleep 5
done

if kcadm get realms/inventory >/dev/null 2>&1; then
  echo "[playground] The realm inventory already exists."
else
  echo "[playground] Creating the realm inventory, the user alice with the realm role inventory-reader, the clients inventory-cli, inventory-gateway and inventory-api, and an audience mapper that puts inventory-gateway in the audience of inventory-cli's tokens..."
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
    -s serviceAccountsEnabled=false -s secret=inventory-gateway-secret
  kcadm create clients -r inventory -s clientId=inventory-api -s enabled=true \
    -s publicClient=false -s standardFlowEnabled=false -s directAccessGrantsEnabled=false \
    -s serviceAccountsEnabled=false
  add_audience_mapper inventory-cli inventory-gateway
fi

echo "[playground] Ready."
kubectl -n "$NAMESPACE" get pods -o wide
echo "[playground] Keycloak answers at http://keycloak:8080 from the tester pod."
