#!/usr/bin/env bash
# Runs before the reference solution is applied.
#
# `astrona test` bootstraps and applies in one go. Keycloak reports ready a
# moment before the Admin REST API accepts the bootstrap administrator, so
# wait until kcadm.sh can sign in.
set -eu

NAMESPACE="pkce-demo"

kubectl -n "$NAMESPACE" rollout status deployment/keycloak --timeout=600s

for _ in $(seq 1 60); do
  if kubectl -n "$NAMESPACE" exec deploy/keycloak -- \
       /opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080 \
       --realm master --user admin --password admin --config /tmp/kcadm.config >/dev/null 2>&1; then
    exit 0
  fi
  sleep 3
done
echo "Keycloak did not accept the administrator in time." >&2
exit 1
