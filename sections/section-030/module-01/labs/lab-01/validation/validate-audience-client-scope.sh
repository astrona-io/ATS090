#!/usr/bin/env bash
# PASS when: the client scope inventory-api-audience holds the audience mapper and is a default scope of inventory-cli.
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

SCOPE_ID="$(scope_uuid inventory-api-audience)"
if [ -z "$SCOPE_ID" ]; then
  echo "FAIL: the client scope inventory-api-audience does not exist."
  exit 1
fi
MAPPERS="$(kcadm get "client-scopes/$SCOPE_ID/protocol-mappers/models" -r inventory 2>/dev/null | tr -d ' \n\r')"
if ! printf '%s' "$MAPPERS" | grep -q '"protocolMapper":"oidc-audience-mapper"' || \
   ! printf '%s' "$MAPPERS" | grep -q '"included.client.audience":"inventory-api"'; then
  echo "FAIL: the client scope inventory-api-audience has no audience mapper for inventory-api."
  exit 1
fi
DEFAULTS="$(kcadm get "clients/$(client_uuid inventory-cli)/default-client-scopes" -r inventory --fields name --format csv --noquotes 2>/dev/null | tr -d '\r')"
if ! printf '%s\n' "$DEFAULTS" | grep -qx 'inventory-api-audience'; then
  echo "FAIL: inventory-api-audience is not a default client scope of inventory-cli."
  exit 1
fi
echo "PASS: the client scope inventory-api-audience adds inventory-api to the audience of inventory-cli's tokens."
exit 0
