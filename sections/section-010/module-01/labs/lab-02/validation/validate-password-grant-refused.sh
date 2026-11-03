#!/usr/bin/env bash
# PASS when: Confirms the password grant is refused for inventory-web
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

OUT="$(tester curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
  -d grant_type=password -d client_id=inventory-web -d username=alice -d password=alice-password)"
if printf '%s' "$OUT" | jq -e 'has("access_token")' >/dev/null 2>&1; then
  echo "FAIL: inventory-web still got a token with the password grant."
  exit 1
fi
ERR="$(printf '%s' "$OUT" | jq -r '.error // empty' 2>/dev/null)"
if [ "$ERR" != "unauthorized_client" ]; then
  echo "FAIL: the password grant answered '$ERR'. It must answer unauthorized_client."
  exit 1
fi
echo "PASS: the password grant is refused for inventory-web."
exit 0
