#!/usr/bin/env bash
# PASS when: Confirms inventory-sync is a confidential service client that gets a token with inventory-reader
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

# token_status CLIENT SECRET: prints the HTTP status of a client credentials request.
token_status() {
  tester curl -s -o /dev/null -w '%{http_code}' -u "$1:$2" \
    http://keycloak:8080/realms/inventory/protocol/openid-connect/token -d grant_type=client_credentials
}
# token_roles CLIENT SECRET: prints the realm roles in the client's access token, one per line.
token_roles() {
  tester sh -c 'curl -s -u "$1:$2" http://keycloak:8080/realms/inventory/protocol/openid-connect/token -d grant_type=client_credentials \
    | jq -r .access_token | jq -R "split(\".\")[1] | gsub(\"-\";\"+\") | gsub(\"_\";\"/\") | @base64d | fromjson | .realm_access.roles[]?"' sh "$1" "$2"
}
# client_secret CLIENT_ID: prints the current secret of a client.
client_secret() {
  kcadm get "clients/$(client_uuid "$1")/client-secret" -r inventory | sed -n 's/.*"value" *: *"\([^"]*\)".*/\1/p'
}
SECRET="$(client_secret inventory-sync)"
if [ -z "$SECRET" ]; then
  echo "FAIL: inventory-sync has no secret. It must be a confidential client."
  exit 1
fi
if [ "$(token_status inventory-sync "$SECRET")" != "200" ]; then
  echo "FAIL: inventory-sync cannot get a token with the client credentials grant."
  exit 1
fi
if ! token_roles inventory-sync "$SECRET" | grep -qx 'inventory-reader'; then
  echo "FAIL: the token of inventory-sync has no inventory-reader role."
  exit 1
fi
echo "PASS: inventory-sync gets a token with inventory-reader."
exit 0
