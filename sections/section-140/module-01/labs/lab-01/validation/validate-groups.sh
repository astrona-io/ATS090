#!/usr/bin/env bash
# PASS when: Confirms the groups claim contains staff
set -uo pipefail

NAMESPACE="proxy-demo"

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

# claims_for CLIENT SECRET: prints the payload of alice's access token for that client as JSON.
claims_for() {
  ACCESS="$(tester curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d "client_id=$1" -d "client_secret=$2" \
    -d username=alice -d password=alice-password | jq -r '.access_token // empty')"
  if [ -z "$ACCESS" ]; then echo "{}"; return; fi
  printf '%s' "$ACCESS" | jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson'
}
CLAIMS="$(claims_for web-proxy web-proxy-secret)"
if ! printf '%s' "$CLAIMS" | jq -e '.groups | index("staff")' >/dev/null 2>&1; then
  echo "FAIL: the access token has no groups claim with staff. groups is $(printf '%s' "$CLAIMS" | jq -c .groups)."
  exit 1
fi
echo "PASS: the groups claim contains staff."
exit 0
