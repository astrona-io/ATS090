#!/usr/bin/env bash
# Creates the starting state for ats-090-lab-110-01.
#
# Creates the realm inventory with the client profile strict-public (executor
# pkce-enforcer) and the client policy public-clients, the WRONG way: the
# policy is disabled, so nothing is enforced.
#
# The corrected state is NOT created here: producing it is the task.
set -euo pipefail

NAMESPACE="reg-demo"

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
kcadm update client-policies/profiles -r inventory -n -b '{"profiles":[{"name":"strict-public","description":"Require PKCE","executors":[{"executor":"pkce-enforcer","configuration":{"auto-configure":true}}]}]}'
kcadm update client-policies/policies -r inventory -n -b '{"policies":[{"name":"public-clients","description":"PKCE for all clients","enabled":false,"profiles":["strict-public"],"conditions":[{"condition":"any-client","configuration":{}}]}]}'

echo "[lab] Starting state ready."
kubectl -n "$NAMESPACE" get pods
