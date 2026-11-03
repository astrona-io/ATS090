#!/usr/bin/env bash
# PASS when: Confirms the offline session idle time is at least seven days
set -uo pipefail

NAMESPACE="sessions-demo"

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

IDLE="$(kcadm get realms/inventory --fields offlineSessionIdleTimeout | sed -n 's/.*"offlineSessionIdleTimeout" *: *\([0-9]*\).*/\1/p')"
if [ -z "$IDLE" ] || [ "$IDLE" -lt 604800 ]; then
  echo "FAIL: offlineSessionIdleTimeout is '$IDLE'. It must be at least 604800 seconds."
  exit 1
fi
echo "PASS: offlineSessionIdleTimeout is $IDLE seconds."
exit 0
