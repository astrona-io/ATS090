#!/usr/bin/env bash
# PASS when: Confirms the realm has a short access token lifespan and refresh token rotation
set -uo pipefail

NAMESPACE="sessions-demo"

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

SETTINGS="$(kcadm get realms/inventory --fields accessTokenLifespan,revokeRefreshToken,refreshTokenMaxReuse)"
LIFESPAN="$(printf '%s' "$SETTINGS" | sed -n 's/.*"accessTokenLifespan" *: *\([0-9]*\).*/\1/p')"
if [ -z "$LIFESPAN" ] || [ "$LIFESPAN" -gt 600 ]; then
  echo "FAIL: accessTokenLifespan is '$LIFESPAN'. It must be 600 seconds or less."
  exit 1
fi
if ! printf '%s' "$SETTINGS" | grep -q '"revokeRefreshToken" *: *true'; then
  echo "FAIL: revokeRefreshToken is not true."
  exit 1
fi
if ! printf '%s' "$SETTINGS" | grep -q '"refreshTokenMaxReuse" *: *0'; then
  echo "FAIL: refreshTokenMaxReuse is not 0."
  exit 1
fi
echo "PASS: short access tokens and single-use refresh tokens are configured."
exit 0
