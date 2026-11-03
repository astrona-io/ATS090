#!/usr/bin/env bash
# PASS when: Confirms inventory-web is public and only the standard flow is on
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
if [ -z "$WEB_ID" ]; then echo "FAIL: the client inventory-web does not exist."; exit 1; fi
C="$(kcadm get "clients/$WEB_ID" -r inventory --fields publicClient,standardFlowEnabled,implicitFlowEnabled,directAccessGrantsEnabled)"
for want in publicClient:true standardFlowEnabled:true implicitFlowEnabled:false directAccessGrantsEnabled:false; do
  key="${want%%:*}"; val="${want##*:}"
  got="$(printf '%s' "$C" | jq -r ".$key")"
  if [ "$got" != "$val" ]; then
    echo "FAIL: $key is $got. It must be $val."
    exit 1
  fi
done
echo "PASS: inventory-web is public and only the standard flow is on."
exit 0
