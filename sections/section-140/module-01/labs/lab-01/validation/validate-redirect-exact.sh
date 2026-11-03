#!/usr/bin/env bash
# PASS when: Confirms the redirect address stayed exact
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

URIS="$(kcadm get "clients/$(client_uuid web-proxy)" -r inventory --fields redirectUris --format csv --noquotes | tr -d '\r')"
if [ "$URIS" != "https://app.example.com/oauth2/callback" ]; then
  echo "FAIL: redirectUris is '$URIS'. It must be only https://app.example.com/oauth2/callback."
  exit 1
fi
echo "PASS: the redirect address is exact."
exit 0
