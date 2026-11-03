#!/usr/bin/env bash
# PASS when: Confirms the SSO session idle limit is 900 seconds or less
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

IDLE="$(kcadm get realms/inventory --fields ssoSessionIdleTimeout | sed -n 's/.*"ssoSessionIdleTimeout" *: *\([0-9]*\).*/\1/p')"
if [ -z "$IDLE" ] || [ "$IDLE" -gt 900 ]; then
  echo "FAIL: ssoSessionIdleTimeout is '$IDLE'. It must be 900 seconds or less."
  exit 1
fi
echo "PASS: ssoSessionIdleTimeout is $IDLE seconds."
exit 0
