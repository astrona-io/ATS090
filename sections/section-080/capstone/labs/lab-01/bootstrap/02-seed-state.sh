#!/usr/bin/env bash
# Creates the starting state for ats-090-capstone-080.
#
# Creates the realm inventory with three problems on inventory-cli:
#   1. the groups mapper does not write into the access token;
#   2. Full Scope Allowed is on, so inventory-admin reaches the token;
#   3. the client scope inventory-audit is optional, but the API cannot send
#      the scope parameter and needs the audit claim in every token.
#
# The corrected state is NOT created here: producing it is the task.
set -euo pipefail

NAMESPACE="scopes-demo"

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
kcadm create roles -r inventory -s name=inventory-reader
kcadm create roles -r inventory -s name=inventory-admin
GROUP_ID="$(kcadm create groups -r inventory -s name=logistics -i | tr -d '\r')"
USER_ID="$(kcadm create users -r inventory -s username=alice -s enabled=true \
  -s email=alice@example.com -s emailVerified=true \
  -s firstName=Alice -s lastName=Example -i | tr -d '\r')"
kcadm set-password -r inventory --username alice --new-password alice-password
kcadm update "users/$USER_ID/groups/$GROUP_ID" -r inventory -s realm=inventory -s userId="$USER_ID" -s groupId="$GROUP_ID" -n
kcadm add-roles -r inventory --uusername alice --rolename inventory-reader --rolename inventory-admin
kcadm create clients -r inventory -s clientId=inventory-cli -s enabled=true \
  -s publicClient=true -s standardFlowEnabled=false -s directAccessGrantsEnabled=true
CLI_ID="$(client_uuid inventory-cli)"
kcadm create "clients/$CLI_ID/protocol-mappers/models" -r inventory \
  -s name=groups -s protocol=openid-connect -s protocolMapper=oidc-group-membership-mapper \
  -s 'config."claim.name"=groups' -s 'config."full.path"=false' \
  -s 'config."access.token.claim"=false' -s 'config."id.token.claim"=true' -s 'config."userinfo.token.claim"=true'
kcadm create client-scopes -r inventory -s name=inventory-audit -s protocol=openid-connect \
  -s 'attributes."include.in.token.scope"=true' -s 'attributes."display.on.consent.screen"=false'
AUDIT_ID="$(kcadm get client-scopes -r inventory --fields id,name --format csv --noquotes | tr -d '\r' | awk -F, '$2 == "inventory-audit" {print $1}')"
kcadm create "client-scopes/$AUDIT_ID/protocol-mappers/models" -r inventory \
  -s name=audit-claim -s protocol=openid-connect -s protocolMapper=oidc-hardcoded-claim-mapper \
  -s 'config."claim.name"=audit' -s 'config."claim.value"=true' -s 'config."jsonType.label"=boolean' \
  -s 'config."access.token.claim"=true' -s 'config."id.token.claim"=false' -s 'config."userinfo.token.claim"=false'
kcadm update "clients/$CLI_ID/optional-client-scopes/$AUDIT_ID" -r inventory

echo "[lab] Starting state ready."
kubectl -n "$NAMESPACE" get pods
