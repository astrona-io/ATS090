#!/usr/bin/env bash
# PASS when: Confirms the access token holds inventory-reader and not inventory-admin
set -uo pipefail

NAMESPACE="scopes-demo"

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

# password_tokens SCOPE: prints the token response for alice, signed in with the password grant.
password_tokens() {
  tester curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=inventory-cli \
    -d username=alice -d password=alice-password -d "scope=$1"
}
# claims TOKEN: prints the payload of a JWT as JSON.
claims() {
  printf '%s' "$1" | jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson'
}
ACCESS="$(password_tokens openid | jq -r .access_token)"
ROLES="$(claims "$ACCESS" | jq -c '.realm_access.roles // []')"
if [ "$(printf '%s' "$ROLES" | jq 'index("inventory-reader") != null')" != "true" ]; then
  echo "FAIL: the access token does not hold inventory-reader. Roles: $ROLES"
  exit 1
fi
if [ "$(printf '%s' "$ROLES" | jq 'index("inventory-admin") != null')" = "true" ]; then
  echo "FAIL: the access token still holds inventory-admin. Roles: $ROLES"
  exit 1
fi
echo "PASS: the access token holds inventory-reader and not inventory-admin."
exit 0
