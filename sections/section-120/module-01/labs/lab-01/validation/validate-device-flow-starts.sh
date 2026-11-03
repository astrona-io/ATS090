#!/usr/bin/env bash
# PASS when: Confirms kiosk gets a device code and a user code
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
OUT="$(device_request kiosk)"
CODE="$(printf '%s\n' "$OUT" | tail -n 1)"
BODY="$(printf '%s\n' "$OUT" | sed '$d')"
if [ "$CODE" != "200" ]; then
  echo "FAIL: the device endpoint returned HTTP $CODE for kiosk. $BODY"
  exit 1
fi
if ! printf '%s' "$BODY" | grep -q '"device_code"' || ! printf '%s' "$BODY" | grep -q '"user_code"'; then
  echo "FAIL: the answer has no device_code and user_code."
  exit 1
fi
echo "PASS: kiosk can start the device flow."
exit 0
