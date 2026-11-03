#!/usr/bin/env bash
# PASS when: Confirms payments-client is refused without a DPoP proof
set -uo pipefail

NAMESPACE="bound-demo"

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

# token_code CLIENT: prints the HTTP status of a client credentials request without a DPoP proof.
token_code() {
  tester curl -s -o /dev/null -w '%{http_code}' http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=client_credentials -d "client_id=$1-client" -d "client_secret=$1-secret"
}
# attr CLIENT KEY: prints one string attribute of the client.
attr() {
  kcadm get clients -r inventory -q clientId=$1-client --fields attributes | sed -n "s/.*\"$2\" *: *\"\([^\"]*\)\".*/\1/p"
}
CODE="$(token_code payments)"
if [ "$CODE" = "200" ]; then
  echo "FAIL: payments-client got a token without a DPoP proof (HTTP 200)."
  exit 1
fi
echo "PASS: payments-client is refused without a proof (HTTP $CODE)."
exit 0
