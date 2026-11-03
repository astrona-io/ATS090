#!/usr/bin/env bash
# PASS when: Confirms polling answers authorization_pending
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
BODY="$(device_request kiosk | sed '$d')"
DEVICE_CODE="$(printf '%s' "$BODY" | tester jq -r '.device_code // empty')"
if [ -z "$DEVICE_CODE" ]; then
  echo "FAIL: no device code was issued, so polling cannot be tested."
  exit 1
fi
POLL="$(tester curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
  -d grant_type=urn:ietf:params:oauth:grant-type:device_code -d client_id=kiosk -d "device_code=$DEVICE_CODE")"
if ! printf '%s' "$POLL" | grep -q 'authorization_pending'; then
  echo "FAIL: polling did not answer authorization_pending. $POLL"
  exit 1
fi
echo "PASS: polling answers authorization_pending until the user approves."
exit 0
