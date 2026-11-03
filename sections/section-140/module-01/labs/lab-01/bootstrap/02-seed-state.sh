#!/usr/bin/env bash
# Creates the starting state for ats-090-lab-140-01.
#
# Creates the realm inventory with the group staff, the user alice and the
# client web-proxy, the WRONG way: the client has no audience mapper and no
# groups mapper, so a proxy rejects its tokens.
#
# The corrected state is NOT created here: producing it is the task.
set -euo pipefail

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
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin

echo "[lab] Creating the starting state in the realm inventory..."
kcadm create realms -s realm=inventory -s enabled=true
GROUP_ID="$(kcadm create groups -r inventory -s name=staff -i | tr -d '\r')"
USER_ID="$(kcadm create users -r inventory -s username=alice -s enabled=true \
  -s email=alice@example.com -s emailVerified=true \
  -s firstName=Alice -s lastName=Example -i | tr -d '\r')"
kcadm set-password -r inventory --username alice --new-password alice-password
kcadm update "users/$USER_ID/groups/$GROUP_ID" -r inventory -s realm=inventory -s userId="$USER_ID" -s groupId="$GROUP_ID" -n
kcadm create clients -r inventory -s clientId=web-proxy -s enabled=true -s publicClient=false \
  -s clientAuthenticatorType=client-secret -s secret=web-proxy-secret \
  -s standardFlowEnabled=true -s directAccessGrantsEnabled=true \
  -s 'redirectUris=["https://app.example.com/oauth2/callback"]'


echo "[lab] Starting state ready."
kubectl -n "$NAMESPACE" get pods
