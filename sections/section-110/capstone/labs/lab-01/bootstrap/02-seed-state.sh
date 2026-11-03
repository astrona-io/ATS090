#!/usr/bin/env bash
# Creates the starting state for ats-090-capstone-110.
#
# Creates the realm inventory with the profile partner-baseline and the
# policy partners, with two faults:
#   1. the policy partners lists no profile, so nothing is applied;
#   2. the profile has no reject-ropc-grant executor.
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
kcadm update client-policies/profiles -r inventory -n -b '{"profiles":[{"name":"partner-baseline","description":"Rules for partner clients","executors":[{"executor":"pkce-enforcer","configuration":{"auto-configure":true}}]}]}'
kcadm update client-policies/policies -r inventory -n -b '{"policies":[{"name":"partners","description":"Baseline for every client","enabled":true,"profiles":[],"conditions":[{"condition":"any-client","configuration":{}}]}]}'

echo "[lab] Starting state ready."
kubectl -n "$NAMESPACE" get pods
