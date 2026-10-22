#!/usr/bin/env bash
# Deploys Keycloak 26.8.1, the tester pod and the lab's workloads for
# ats-090-capstone-030, then waits until the bootstrap administrator can sign in.
#
# Graded lab bootstrap: this prepares the environment ONLY. It never creates
# the objects the task asks for.
set -euo pipefail

NAMESPACE="tokenscapstone-demo"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

echo "[lab] Applying starting workloads..."
kubectl apply -f "$MANIFESTS/lab-start.yaml"

# The first rollout pulls a large image and Keycloak takes a while to start.
echo "[lab] Waiting for Keycloak and the workloads (this can take a few minutes)..."
kubectl -n "$NAMESPACE" rollout status deployment/keycloak --timeout=600s
kubectl -n "$NAMESPACE" rollout status deployment/tester --timeout=300s
kubectl -n "$NAMESPACE" rollout status deployment/inventory-api --timeout=300s

kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}

# The bootstrap administrator can need a few seconds after /health/ready.
for _ in $(seq 1 30); do
  if kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin >/dev/null 2>&1; then
    echo "[lab] Keycloak ready."
    exit 0
  fi
  sleep 5
done
echo "[lab] ERROR: the administrator could not sign in to Keycloak." >&2
exit 1
