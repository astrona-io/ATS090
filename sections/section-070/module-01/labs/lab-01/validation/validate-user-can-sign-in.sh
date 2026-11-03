#!/usr/bin/env bash
# PASS when: Confirms alice is still enabled and can sign in
set -uo pipefail

NAMESPACE="logout-demo"

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

# password_tokens: prints the token response for alice, signed in with the password grant.
password_tokens() {
  tester curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=inventory-cli \
    -d username=alice -d password=alice-password -d scope=openid
}
# user_id: prints the internal id of alice.
user_id() {
  kcadm get users -r inventory -q username=alice --fields id --format csv --noquotes | tr -d '\r'
}
# session_count: prints how many sessions alice has.
session_count() {
  kcadm get "users/$(user_id)/sessions" -r inventory --fields id --format csv --noquotes | tr -d '\r' | grep -c . || true
}
ACCESS="$(password_tokens | jq -r '.access_token // empty')"
if [ -z "$ACCESS" ]; then
  echo "FAIL: alice cannot sign in. Do not disable the user."
  exit 1
fi
echo "PASS: alice can still sign in."
exit 0
