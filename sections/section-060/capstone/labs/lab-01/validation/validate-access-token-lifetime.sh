#!/usr/bin/env bash
# PASS when: Confirms a new access token for inventory-cli lives 600 seconds or less
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
ACCESS="$(password_tokens openid | jq -r .access_token)"
LIFETIME="$(claims "$ACCESS" | jq '.exp - .iat')"
if [ -z "$LIFETIME" ] || [ "$LIFETIME" -gt 600 ]; then
  echo "FAIL: a new access token lives '$LIFETIME' seconds. It must live 600 or less."
  exit 1
fi
echo "PASS: a new access token lives $LIFETIME seconds."
exit 0
