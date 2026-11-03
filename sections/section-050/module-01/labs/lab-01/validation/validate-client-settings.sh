#!/usr/bin/env bash
# PASS when: Confirms inventory-reporter is still a confidential client with service accounts on
set -uo pipefail

NAMESPACE="m2m-demo"

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

FIELDS="$(kcadm get clients -r inventory -q clientId=inventory-reporter --fields publicClient,serviceAccountsEnabled)"
if printf '%s' "$FIELDS" | grep -q '"publicClient" *: *true'; then
  echo "FAIL: inventory-reporter is a public client. It must stay confidential."
  exit 1
fi
if ! printf '%s' "$FIELDS" | grep -q '"serviceAccountsEnabled" *: *true'; then
  echo "FAIL: service accounts are still off for inventory-reporter."
  exit 1
fi
echo "PASS: inventory-reporter is confidential and service accounts are on."
exit 0
