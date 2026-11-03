#!/usr/bin/env bash
# PASS when: Confirms the post logout redirect URI is the exact application address
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

VALUE="$(kcadm get "clients/$(client_uuid inventory-cli)" -r inventory --fields attributes | sed -n 's/.*"post.logout.redirect.uris" *: *"\([^"]*\)".*/\1/p')"
if [ "$VALUE" != "https://app.example.com/signed-out" ]; then
  echo "FAIL: post.logout.redirect.uris is '$VALUE'. It must be exactly https://app.example.com/signed-out."
  exit 1
fi
echo "PASS: only the exact post-logout address is registered."
exit 0
