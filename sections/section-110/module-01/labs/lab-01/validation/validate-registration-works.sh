#!/usr/bin/env bash
# PASS when: Confirms dynamic registration still works
set -uo pipefail

NAMESPACE="reg-demo"

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

# make_iat: prints a new initial access token that allows one registration.
make_iat() {
  kcadm create clients-initial-access -r inventory -s count=1 -s expiration=600 -o \
    | sed -n 's/.*"token" *: *"\([^"]*\)".*/\1/p'
}
# register BODY: registers a client with a new initial access token. Sets REG_CODE and REG_CLIENT.
register() {
  IAT="$(make_iat)"
  RESP="$(tester curl -s -w '\n%{http_code}' http://keycloak:8080/realms/inventory/clients-registrations/openid-connect \
    -H "Authorization: Bearer $IAT" -H 'Content-Type: application/json' -d "$1")"
  REG_CODE="$(printf '%s\n' "$RESP" | tail -n 1)"
  REG_CLIENT="$(printf '%s\n' "$RESP" | sed '$d' | tester jq -r '.client_id // empty' 2>/dev/null || true)"
}
# admin_create_code BODY: creates a client with the admin API and prints the HTTP status.
admin_create_code() {
  TOKEN="$(tester curl -s http://keycloak:8080/realms/master/protocol/openid-connect/token \
    -d grant_type=password -d client_id=admin-cli -d username=admin -d password=admin | jq -r '.access_token // empty')"
  tester curl -s -o /dev/null -w '%{http_code}' -X POST http://keycloak:8080/admin/realms/inventory/clients \
    -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -d "$1"
}
# drop_client CLIENT_ID: deletes a client if it exists.
drop_client() {
  if [ -z "${1:-}" ]; then return 0; fi
  ID="$(kcadm get clients -r inventory -q clientId=$1 --fields id --format csv --noquotes | tr -d '\r')"
  if [ -n "$ID" ]; then kcadm delete "clients/$ID" -r inventory; fi
}
register '{"client_name":"probe-dcr","client_uri":"https://partner.example.com","redirect_uris":["https://partner.example.com/callback"],"grant_types":["authorization_code"],"token_endpoint_auth_method":"client_secret_basic"}'
CODE="$REG_CODE"
drop_client "$REG_CLIENT"
if [ "$CODE" != "201" ]; then
  echo "FAIL: registering a normal client returned HTTP $CODE, not 201."
  exit 1
fi
echo "PASS: registration with an initial access token works."
exit 0
