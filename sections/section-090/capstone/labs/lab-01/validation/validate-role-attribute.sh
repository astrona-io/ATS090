#!/usr/bin/env bash
# PASS when: Confirms the role list mapper writes the attribute Role
set -uo pipefail

NAMESPACE="saml-demo"

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

MAPPERS="$(kcadm get "clients/$(client_uuid urn:app:billing)/protocol-mappers/models" -r inventory | tr -d '\n ')"
if ! printf '%s' "$MAPPERS" | grep -q '"protocolMapper":"saml-role-list-mapper"'; then
  echo "FAIL: the role list mapper is gone."
  exit 1
fi
if ! printf '%s' "$MAPPERS" | grep -q '"attribute.name":"Role"'; then
  echo "FAIL: no mapper writes the attribute named Role."
  exit 1
fi
echo "PASS: the role list is written to the attribute Role."
exit 0
