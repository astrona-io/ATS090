#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the student.
# Taken from solution.md - if one changes, change the other.
set -eu

NAMESPACE="reg-demo"

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

kcadm update client-policies/profiles -r inventory -n -b '{"profiles":[{"name":"partner-baseline","description":"Rules for partner clients","executors":[{"executor":"pkce-enforcer","configuration":{"auto-configure":true}},{"executor":"reject-ropc-grant","configuration":{}}]}]}'
kcadm update client-policies/policies -r inventory -n -b '{"policies":[{"name":"partners","description":"Baseline for every client","enabled":true,"profiles":["partner-baseline"],"conditions":[{"condition":"any-client","configuration":{}}]}]}'
