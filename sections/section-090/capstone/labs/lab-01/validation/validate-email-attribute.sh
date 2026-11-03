#!/usr/bin/env bash
# PASS when: Confirms a mapper writes the email attribute from the user's email
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

MAPPERS="$(kcadm get "clients/$(client_uuid urn:app:billing)/protocol-mappers/models" -r inventory)"
if ! printf '%s' "$MAPPERS" | tr -d '\n ' | grep -q '"user.attribute":"email"'; then
  echo "FAIL: no mapper copies the user property email."
  exit 1
fi
if ! printf '%s' "$MAPPERS" | tr -d '\n ' | grep -q '"attribute.name":"email"'; then
  echo "FAIL: no mapper writes the attribute named email."
  exit 1
fi
echo "PASS: the email attribute is mapped."
exit 0
