#!/usr/bin/env bash
# PASS when: Confirms inventory-cli can get an offline token
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
# refresh_status REFRESH_TOKEN: prints the HTTP status of a refresh token request.
refresh_status() {
  tester curl -s -o /dev/null -w '%{http_code}' http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=refresh_token -d client_id=inventory-cli -d refresh_token="$1"
}
REFRESH="$(password_tokens 'openid offline_access' | jq -r '.refresh_token // empty')"
if [ -z "$REFRESH" ]; then
  echo "FAIL: no refresh token came back for the scope offline_access."
  exit 1
fi
TYPE="$(claims "$REFRESH" | jq -r .typ)"
if [ "$TYPE" != "Offline" ]; then
  echo "FAIL: the refresh token has the type '$TYPE', not Offline."
  exit 1
fi
echo "PASS: inventory-cli gets an offline token."
exit 0
