#!/usr/bin/env bash
# PASS when: Confirms kiosk is public and has direct access grants off
set -uo pipefail

NAMESPACE="device-demo"

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

# device_request CLIENT: prints the response body, then the HTTP status on a last line.
device_request() {
  tester curl -s -w '\n%{http_code}' http://keycloak:8080/realms/inventory/protocol/openid-connect/auth/device -d "client_id=$1"
}
# attr CLIENT KEY: prints one boolean field of the client, for example publicClient.
field() {
  kcadm get clients -r inventory -q clientId=$1 --fields $2 | sed -n "s/.*\"$2\" *: *\([a-z]*\).*/\1/p"
}
for C in kiosk; do
  ROPC="$(field $C directAccessGrantsEnabled)"
  PUB="$(field $C publicClient)"
  if [ "$ROPC" != "false" ]; then echo "FAIL: $C has direct access grants on."; exit 1; fi
  if [ "$PUB" != "true" ]; then echo "FAIL: $C is not a public client."; exit 1; fi
done
echo "PASS: kiosk stays public with direct access grants off."
exit 0
