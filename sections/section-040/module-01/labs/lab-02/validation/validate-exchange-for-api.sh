#!/usr/bin/env bash
# PASS when: Confirms the gateway exchanges alice's token for one meant for inventory-api
set -uo pipefail

NAMESPACE="exchange-demo"

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

# alice_token: prints alice's access token from inventory-cli (scope openid).
alice_token() {
  tester curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=inventory-cli \
    -d username=alice -d password=alice-password -d scope=openid | jq -r '.access_token // empty'
}
# exchange SUBJECT_TOKEN [AUDIENCE]: prints the token response of an exchange by inventory-gateway.
exchange() {
  tester sh -c '
    if [ -n "$2" ]; then AUD="-d audience=$2"; else AUD=""; fi
    curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=urn:ietf:params:oauth:grant-type:token-exchange \
      -d client_id=inventory-gateway -d client_secret=inventory-gateway-secret \
      --data-urlencode subject_token="$1" \
      -d subject_token_type=urn:ietf:params:oauth:token-type:access_token $AUD' sh "$1" "${2:-}"
}
# claims_of: reads a JSON token response on stdin, prints the payload of its access token (or {}).
claims_of() {
  local t
  t="$(jq -r '.access_token // empty')"
  if [ -z "$t" ]; then echo "{}"; return; fi
  printf '%s' "$t" | jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson'
}
ACCESS="$(alice_token)"
C="$(exchange "$ACCESS" inventory-api | claims_of)"
if [ "$(printf '%s' "$C" | jq -r '.preferred_username // empty')" != "alice" ] \
  || [ "$(printf '%s' "$C" | jq -r '.azp // empty')" != "inventory-gateway" ] \
  || ! printf '%s' "$C" | jq -e '(.aud | if type == "array" then . else [.] end) | index("inventory-api")' >/dev/null; then
  echo "FAIL: the exchange for inventory-api did not return a token for alice from inventory-gateway with the audience inventory-api. Claims: $(printf '%s' "$C" | jq -c '{preferred_username, azp, aud}')."
  exit 1
fi
echo "PASS: the gateway exchanges alice's token for one meant for inventory-api."
exit 0
