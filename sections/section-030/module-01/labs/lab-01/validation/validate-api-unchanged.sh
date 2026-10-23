#!/usr/bin/env bash
# PASS when: the API code and settings were not changed.
set -uo pipefail
# grep -q stops reading at the first match; under pipefail the command
# writing into the pipe then fails with SIGPIPE and a match looks like a
# failure. This wrapper reads all input instead and keeps grep's exit status.
grep() {
  local arg quiet=0 args=()
  for arg in "$@"; do
    case "$arg" in
      --quiet|--silent) quiet=1 ;;
      --*) args+=("$arg") ;;
      -*q*) quiet=1; [ "$arg" = "-q" ] || args+=("${arg//q/}") ;;
      *) args+=("$arg") ;;
    esac
  done
  if [ "$quiet" = 1 ]; then command grep "${args[@]}" >/dev/null; else command grep "$@"; fi
}

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

CURRENT="$(kubectl -n "$NAMESPACE" get configmap inventory-api-code -o jsonpath='{.data.server\.js}')"
BASELINE="$(kubectl -n "$NAMESPACE" get configmap lab-baseline -o jsonpath='{.data.server\.js}')"
if [ -z "$BASELINE" ] || [ "$CURRENT" != "$BASELINE" ]; then
  echo "FAIL: the API code in the ConfigMap inventory-api-code was changed. Fix Keycloak, not the API."
  exit 1
fi
ENV="$(kubectl -n "$NAMESPACE" get deployment inventory-api -o jsonpath='{range .spec.template.spec.containers[0].env[*]}{.name}={.value};{end}')"
for expected in "ISSUER=http://keycloak:8080/realms/inventory" "AUDIENCE=inventory-api" "REQUIRED_ROLE=inventory-reader"; do
  if ! printf '%s' "$ENV" | grep -q "$expected;"; then
    echo "FAIL: the settings of inventory-api were changed ($expected is missing). Fix Keycloak, not the API."
    exit 1
  fi
done
echo "PASS: the API code and settings are unchanged."
exit 0
