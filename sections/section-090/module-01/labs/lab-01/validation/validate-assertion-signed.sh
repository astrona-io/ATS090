#!/usr/bin/env bash
# PASS when: Confirms the assertion is signed
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

# client_attr NAME: prints one attribute of the client urn:app:billing.
client_attr() {
  kcadm get "clients/$(client_uuid urn:app:billing)" -r inventory --fields attributes \
    | sed -n "s/.*\"$1\" *: *\"\([^\"]*\)\".*/\1/p"
}
VALUE="$(client_attr saml.assertion.signature)"
if [ "$VALUE" != "true" ]; then
  echo "FAIL: saml.assertion.signature is '$VALUE', not true."
  exit 1
fi
echo "PASS: the assertion is signed."
exit 0
