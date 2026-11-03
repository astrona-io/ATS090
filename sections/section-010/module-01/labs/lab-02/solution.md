# Solution: Trim A Browser Client To The One Flow It Uses

Work the task yourself first. Running `astrona submit -c sections/section-010/module-01/labs/lab-02` after a step tells you which checks pass, without telling you what is left.

## Step 1: Read the capability settings

```sh
NAMESPACE=clients-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm get clients -r inventory -q clientId=inventory-web \
  --fields clientId,publicClient,standardFlowEnabled,implicitFlowEnabled,directAccessGrantsEnabled,fullScopeAllowed
```

The standard flow, the implicit flow and direct access grants are all `true`, and `fullScopeAllowed` is `true`.

## Step 2: Show the problem

```sh
kubectl -n clients-demo exec deploy/tester -- \
  curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=inventory-web \
    -d username=alice -d password=alice-password | jq -c '{has_token: has("access_token")}'
```

The password grant returns a token. Request `response_type=token` the same way as in the reading: the login page appears, so the implicit flow is open too.

## Step 3: Trim the client

The standard flow stays on. Turn off the other two flows and the full scope:

```sh
WEB_ID=$(kcadm get clients -r inventory -q clientId=inventory-web --fields id --format csv --noquotes | tr -d '\r')
kcadm update "clients/$WEB_ID" -r inventory \
  -s implicitFlowEnabled=false -s directAccessGrantsEnabled=false -s fullScopeAllowed=false
```

## Step 4: Prove it

Repeat the password grant. The answer is now `unauthorized_client` and has no token. Repeat the request with `response_type=token`: no login page. A request with `response_type=code` still shows the login page. Run `astrona submit` to grade the lab.
