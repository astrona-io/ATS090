#!/usr/bin/env bash
# OS prep for the "Securing Applications With Libraries, Proxies And Gateways" playground (`ats-090-playground-140-01`).
#
# Environment preparation only. There is no task and no grading. This script:
#   1. applies the module's starting workloads (Keycloak 26.8.1 and tester),
#   2. waits until Keycloak and the workloads are ready,
#   3. creates the realm inventory, the user alice in the group staff and the client web-proxy with its mappers.
set -euo pipefail

NAMESPACE="proxy-demo"

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

echo "[playground] Waiting for Keycloak and the workloads (this can take a few minutes)..."
kubectl -n "$NAMESPACE" rollout status deployment/keycloak --timeout=600s
kubectl -n "$NAMESPACE" rollout status deployment/tester --timeout=300s

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

# The bootstrap administrator can need a few seconds after /health/ready.
for _ in $(seq 1 30); do
  kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin >/dev/null 2>&1 && break
  sleep 5
done

if kcadm get realms/inventory >/dev/null 2>&1; then
  echo "[playground] The realm inventory already exists."
else
  echo "[playground] Creating the realm inventory and its objects..."
  kcadm create realms -s realm=inventory -s enabled=true
  GROUP_ID="$(kcadm create groups -r inventory -s name=staff -i | tr -d '\r')"
  USER_ID="$(kcadm create users -r inventory -s username=alice -s enabled=true \
    -s email=alice@example.com -s emailVerified=true \
    -s firstName=Alice -s lastName=Example -i | tr -d '\r')"
  kcadm set-password -r inventory --username alice --new-password alice-password
  kcadm update "users/$USER_ID/groups/$GROUP_ID" -r inventory -s realm=inventory -s userId="$USER_ID" -s groupId="$GROUP_ID" -n
  kcadm create clients -r inventory -s clientId=web-proxy -s enabled=true -s publicClient=false \
    -s clientAuthenticatorType=client-secret -s secret=web-proxy-secret \
    -s standardFlowEnabled=true -s directAccessGrantsEnabled=true \
    -s 'redirectUris=["https://app.example.com/oauth2/callback"]'
  PROXY_ID="$(client_uuid web-proxy)"
  kcadm create "clients/$PROXY_ID/protocol-mappers/models" -r inventory \
    -s name=audience -s protocol=openid-connect -s protocolMapper=oidc-audience-mapper \
    -s 'config."included.client.audience"=web-proxy' \
    -s 'config."access.token.claim"=true' -s 'config."id.token.claim"=false'
  kcadm create "clients/$PROXY_ID/protocol-mappers/models" -r inventory \
    -s name=groups -s protocol=openid-connect -s protocolMapper=oidc-group-membership-mapper \
    -s 'config."claim.name"=groups' -s 'config."full.path"=false' \
    -s 'config."access.token.claim"=true' -s 'config."id.token.claim"=true' -s 'config."userinfo.token.claim"=true'
fi

echo "[playground] Ready."
kubectl -n "$NAMESPACE" get pods -o wide
echo "[playground] Keycloak answers at http://keycloak:8080 from the tester pod."
