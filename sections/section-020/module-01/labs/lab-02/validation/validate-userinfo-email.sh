#!/usr/bin/env bash
# PASS when: Confirms UserInfo returns alice's verified email address
set -uo pipefail

NAMESPACE="pkce-demo"

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

# userinfo_json SCOPE: prints the UserInfo answer for alice, with a token for inventory-app that has that scope.
userinfo_json() {
  tester sh -c '
    TOKEN=$(curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=password -d client_id=inventory-app \
      -d username=alice -d password=alice-password -d "scope=$0" | jq -r ".access_token // empty")
    if [ -z "$TOKEN" ]; then echo "{}"; exit 0; fi
    curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/userinfo -H "Authorization: Bearer $TOKEN"' "$1"
}

INFO="$(userinfo_json openid)"
EMAIL="$(printf '%s' "$INFO" | jq -r '.email // empty')"
VERIFIED="$(printf '%s' "$INFO" | jq -r '.email_verified // empty')"
if [ "$EMAIL" != "alice@example.com" ] || [ "$VERIFIED" != "true" ]; then
  echo "FAIL: UserInfo has email '$EMAIL' and email_verified '$VERIFIED'. It must have alice@example.com and true."
  exit 1
fi
echo "PASS: UserInfo returns the verified email address."
exit 0
