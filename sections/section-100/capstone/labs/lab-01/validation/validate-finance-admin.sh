#!/usr/bin/env bash
# PASS when: Confirms a finance and report-admin user may read and delete
set -uo pipefail

NAMESPACE="authz-demo"

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

# decision USER PERMISSION: prints allow or deny for a permission request on invoice-api.
decision() {
  ACCESS="$(tester curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=inventory-cli \
    -d "username=$1" -d "password=$1-password" -d scope=openid | jq -r '.access_token // empty')"
  if [ -z "$ACCESS" ]; then echo "error"; return; fi
  CODE="$(tester curl -s -o /dev/null -w '%{http_code}' http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -H "Authorization: Bearer $ACCESS" \
    -d grant_type=urn:ietf:params:oauth:grant-type:uma-ticket \
    -d audience=invoice-api --data-urlencode "permission=$2" -d response_mode=decision)"
  if [ "$CODE" = "200" ]; then echo allow; else echo deny; fi
}
READ="$(decision carol 'report#read')"
DELETE="$(decision carol 'report#delete')"
if [ "$READ" != "allow" ] || [ "$DELETE" != "allow" ]; then
  echo "FAIL: carol gets read=$READ delete=$DELETE. Expected read=allow delete=allow."
  exit 1
fi
echo "PASS: carol gets read=allow and delete=allow."
exit 0
