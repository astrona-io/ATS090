#!/usr/bin/env bash
# PASS when: inventory-gateway exchanges alice's token for audience reporting-api, and reporting-api accepts it.
set -uo pipefail

NAMESPACE="exchangecapstone-demo"

kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
# client_uuid CLIENT_ID: prints the internal id of a client in the realm inventory.
client_uuid() {
  kcadm get clients -r inventory -q clientId="$1" --fields id --format csv --noquotes | tr -d '\r'
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
# exchange_token SUBJECT_TOKEN AUDIENCE: exchanges a user's access token as the
# confidential client inventory-gateway and prints the response, then a last
# line HTTP_STATUS=<code>.
exchange_token() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- sh -c '
    curl -s -w "\nHTTP_STATUS=%{http_code}" \
      http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=urn:ietf:params:oauth:grant-type:token-exchange \
      -d client_id=inventory-gateway -d client_secret=inventory-gateway-secret \
      --data-urlencode subject_token="$1" \
      -d subject_token_type=urn:ietf:params:oauth:token-type:access_token \
      -d audience="$2"' sh "$1" "$2" 2>/dev/null
}
# add_audience_mapper CLIENT_ID AUDIENCE: adds an audience mapper to the
# client's dedicated scope, so its access tokens carry AUDIENCE in aud.
add_audience_mapper() {
  kcadm create "clients/$(client_uuid "$1")/protocol-mappers/models" -r inventory \
    -s name="audience-$2" -s protocol=openid-connect -s protocolMapper=oidc-audience-mapper \
    -s 'config."included.client.audience"='"$2" \
    -s 'config."access.token.claim"=true' -s 'config."id.token.claim"=false' \
    -s 'config."introspection.token.claim"=true'
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin >/dev/null 2>&1

TOKEN="$(user_token)"
if [ -z "$TOKEN" ]; then
  echo "FAIL: alice cannot get a token from inventory-cli."
  exit 1
fi
RESPONSE="$(exchange_token "$TOKEN" reporting-api)"
STATUS="$(printf '%s\n' "$RESPONSE" | sed -n 's/^HTTP_STATUS=//p')"
if [ "$STATUS" != "200" ]; then
  echo "FAIL: inventory-gateway cannot exchange alice's token for audience reporting-api (HTTP $STATUS): $(printf '%s\n' "$RESPONSE" | head -n 1)"
  exit 1
fi
EXCHANGED="$(printf '%s\n' "$RESPONSE" | head -n 1 | kubectl -n "$NAMESPACE" exec -i deploy/tester -- jq -r '.access_token // empty' 2>/dev/null)"
CLAIMS="$(token_claims "$EXCHANGED")"
for expected in '"preferred_username":"alice"' '"azp":"inventory-gateway"' 'reporting-api'; do
  if ! printf '%s' "$CLAIMS" | grep -q "$expected"; then
    echo "FAIL: the exchanged token does not contain $expected."
    exit 1
  fi
done
API_STATUS="$(call_api reporting-api "$EXCHANGED")"
if [ "$API_STATUS" != "200" ]; then
  echo "FAIL: reporting-api answers $API_STATUS to the exchanged token. Last API log line: $(kubectl -n "$NAMESPACE" logs deploy/reporting-api --tail=1 2>/dev/null)"
  exit 1
fi
echo "PASS: inventory-gateway exchanges alice's token for one with audience reporting-api, and reporting-api accepts it with the role reporting-reader."
exit 0
