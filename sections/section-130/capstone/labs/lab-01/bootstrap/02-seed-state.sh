#!/usr/bin/env bash
# Creates the starting state for ats-090-capstone-130.
#
# Creates the realm inventory with three faults:
#   1. payments-client does not require DPoP-bound tokens;
#   2. payments-client access tokens live 3600 seconds;
#   3. partner-client requires DPoP although its software cannot send proofs.
#
# The corrected state is NOT created here: producing it is the task.
set -euo pipefail

NAMESPACE="bound-demo"

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
kcadm create clients -r inventory -s clientId=payments-client -s enabled=true -s publicClient=false \
  -s clientAuthenticatorType=client-secret -s secret=payments-secret \
  -s standardFlowEnabled=false -s directAccessGrantsEnabled=false -s serviceAccountsEnabled=true \
  -s 'attributes."dpop.bound.access.tokens"=false' \
  -s 'attributes."access.token.lifespan"=3600'
kcadm create clients -r inventory -s clientId=partner-client -s enabled=true -s publicClient=false \
  -s clientAuthenticatorType=client-secret -s secret=partner-secret \
  -s standardFlowEnabled=false -s directAccessGrantsEnabled=false -s serviceAccountsEnabled=true \
  -s 'attributes."dpop.bound.access.tokens"=true'


echo "[lab] Starting state ready."
kubectl -n "$NAMESPACE" get pods
