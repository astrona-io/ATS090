#!/usr/bin/env bash
# PASS when: Confirms Keycloak refuses response_type=token for inventory-web
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

N="$(tester sh -c 'curl -s "http://keycloak:8080/realms/inventory/protocol/openid-connect/auth?client_id=inventory-web&scope=openid&redirect_uri=http%3A%2F%2Flocalhost%3A5173%2Fcallback&response_type=token" | grep -c login-actions/authenticate || true' | tr -d '\r')"
if [ "$N" != "0" ]; then
  echo "FAIL: Keycloak still shows a login page for response_type=token."
  exit 1
fi
echo "PASS: the implicit flow is refused."
exit 0
