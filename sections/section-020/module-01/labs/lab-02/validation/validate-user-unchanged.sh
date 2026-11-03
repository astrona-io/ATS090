#!/usr/bin/env bash
# PASS when: Confirms the user alice was not changed
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

U="$(kcadm get users -r inventory -q username=alice --fields email,emailVerified)"
if [ "$(printf '%s' "$U" | jq -r '.[0].email')" != "alice@example.com" ] || [ "$(printf '%s' "$U" | jq -r '.[0].emailVerified')" != "true" ]; then
  echo "FAIL: the user alice was changed. The fix belongs to the client."
  exit 1
fi
echo "PASS: the user alice is unchanged."
exit 0
