#!/usr/bin/env bash
# PASS when: Confirms inventory-app has the default scopes email and profile
set -uo pipefail

NAMESPACE="pkce-demo"

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

APP_ID="$(client_uuid inventory-app)"
if [ -z "$APP_ID" ]; then echo "FAIL: the client inventory-app does not exist."; exit 1; fi
NAMES="$(kcadm get "clients/$APP_ID/default-client-scopes" -r inventory --fields name | jq -r '.[].name')"
for want in email profile; do
  case "
$NAMES
" in
    *"
$want
"*) ;;
    *) echo "FAIL: the default client scopes of inventory-app do not include $want."; exit 1 ;;
  esac
done
echo "PASS: inventory-app has the default scopes email and profile."
exit 0
