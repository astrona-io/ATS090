#!/usr/bin/env bash
# PASS when: Confirms the full scope is not allowed
set -uo pipefail

NAMESPACE="clients-demo"

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

WEB_ID="$(client_uuid inventory-web)"
FULL="$(kcadm get "clients/$WEB_ID" -r inventory --fields fullScopeAllowed | jq -r .fullScopeAllowed)"
if [ "$FULL" != "false" ]; then
  echo "FAIL: fullScopeAllowed is $FULL. The client must not carry every role of the user."
  exit 1
fi
echo "PASS: full scope is off."
exit 0
