#!/usr/bin/env bash
# PASS when: Confirms the back-channel logout URL is set
set -uo pipefail

NAMESPACE="logout-demo"

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

VALUE="$(kcadm get "clients/$(client_uuid inventory-cli)" -r inventory --fields attributes | sed -n 's/.*"backchannel.logout.url" *: *"\([^"]*\)".*/\1/p')"
if [ "$VALUE" != "http://app-backend.logout-demo.svc:8080/backchannel-logout" ]; then
  echo "FAIL: backchannel.logout.url is '$VALUE'."
  exit 1
fi
echo "PASS: the back-channel logout URL is set."
exit 0
