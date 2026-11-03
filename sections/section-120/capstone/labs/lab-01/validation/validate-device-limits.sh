#!/usr/bin/env bash
# PASS when: Confirms the code lifetime and the interval are safe
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
BODY="$(device_request tv-app | sed '$d')"
LIFE="$(printf '%s' "$BODY" | tester jq -r '.expires_in // empty')"
INT="$(printf '%s' "$BODY" | tester jq -r '.interval // empty')"
if [ -z "$LIFE" ] || [ -z "$INT" ]; then
  echo "FAIL: the device endpoint gave no expires_in and interval for tv-app. $BODY"
  exit 1
fi
if [ "$LIFE" -gt 600 ]; then
  echo "FAIL: expires_in is $LIFE seconds. It must be 600 or less."
  exit 1
fi
if [ "$INT" -lt 5 ]; then
  echo "FAIL: interval is $INT seconds. It must be 5 or more."
  exit 1
fi
echo "PASS: lifetime $LIFE seconds and interval $INT seconds."
exit 0
