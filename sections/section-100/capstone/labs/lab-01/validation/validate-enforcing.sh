#!/usr/bin/env bash
# PASS when: Confirms the resource server is still in enforcing mode
set -uo pipefail

NAMESPACE="authz-demo"

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
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin >/dev/null 2>&1

MODE="$(kcadm get "clients/$(client_uuid invoice-api)/authz/resource-server" -r inventory --fields policyEnforcementMode | sed -n 's/.*"policyEnforcementMode" *: *"\([A-Z]*\)".*/\1/p')"
if [ "$MODE" != "ENFORCING" ]; then
  echo "FAIL: policyEnforcementMode is '$MODE', not ENFORCING."
  exit 1
fi
echo "PASS: the resource server is enforcing."
exit 0
