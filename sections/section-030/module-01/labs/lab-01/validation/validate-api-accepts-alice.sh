#!/usr/bin/env bash
# PASS when: inventory-api answers 200 to alice's access token from inventory-cli.
set -uo pipefail

NAMESPACE="tokens-demo"

kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
# client_uuid CLIENT_ID: prints the internal id of a client in the realm inventory.
client_uuid() {
  kcadm get clients -r inventory -q clientId="$1" --fields id --format csv --noquotes | tr -d '\r'
}
# scope_uuid NAME: prints the internal id of a client scope in the realm inventory.
scope_uuid() {
  kcadm get client-scopes -r inventory --fields id,name --format csv --noquotes \
    | tr -d '\r' | awk -F, -v name="$1" '$2 == name {print $1}'
}
# user_token: prints an access token for alice from the public client
# inventory-cli, with the password grant (lab-only; OAuth 2.1 drops this grant).
user_token() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- sh -c '
    curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=password -d client_id=inventory-cli \
      -d username=alice -d password=alice-password -d scope=openid \
    | jq -r ".access_token // empty"' 2>/dev/null
}
# token_claims TOKEN: prints the payload of a JWT as one line of JSON.
token_claims() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- sh -c '
    printf "%s" "$1" | jq -rR "split(\".\")[1] | gsub(\"-\";\"+\") | gsub(\"_\";\"/\") | @base64d" | tr -d "\n"' sh "$1" 2>/dev/null
}
# call_api SERVICE TOKEN: prints the HTTP status of GET /items on SERVICE.
call_api() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- \
    curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $2" "http://$1:8080/items" 2>/dev/null
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin >/dev/null 2>&1

TOKEN="$(user_token)"
if [ -z "$TOKEN" ]; then
  echo "FAIL: alice cannot get a token from inventory-cli."
  exit 1
fi
STATUS="$(call_api inventory-api "$TOKEN")"
if [ "$STATUS" != "200" ]; then
  REASON="$(kubectl -n "$NAMESPACE" logs deploy/inventory-api --tail=1 2>/dev/null)"
  echo "FAIL: inventory-api answers $STATUS to alice's token. Last API log line: $REASON"
  exit 1
fi
echo "PASS: inventory-api accepts alice's access token."
exit 0
