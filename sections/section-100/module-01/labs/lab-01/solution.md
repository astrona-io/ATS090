# Solution: Grant Access With A Role Policy

Work the task yourself first. Running `astrona submit -c sections/section-100/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

## Step 1: Ask for the decisions

```sh
NAMESPACE=authz-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
decision() {
  ACCESS=$(kubectl -n "$NAMESPACE" exec deploy/tester -- \
    curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=password -d client_id=inventory-cli \
      -d "username=$1" -d "password=$1-password" -d scope=openid | jq -r .access_token)
  kubectl -n "$NAMESPACE" exec deploy/tester -- \
    curl -s -o /dev/null -w '%{http_code}\n' http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -H "Authorization: Bearer $ACCESS" \
      -d grant_type=urn:ietf:params:oauth:grant-type:uma-ticket \
      -d audience=invoice-api --data-urlencode "permission=$2" -d response_mode=decision
}
decision alice 'invoice#view'
decision bob 'invoice#view'
```

Both print `403`.

## Step 2: Read the policy

```sh
RS_ID=$(kcadm get clients -r inventory -q clientId=invoice-api --fields id --format csv --noquotes | tr -d '\r')
kcadm get "clients/$RS_ID/authz/resource-server/policy" -r inventory -q name=finance-only
```

The policy `finance-only` is a role policy, but its role is `auditor`, which nobody has.

## Step 3: Point the policy at the finance role

```sh
POLICY_ID=$(kcadm get "clients/$RS_ID/authz/resource-server/policy" -r inventory -q name=finance-only --fields id --format csv --noquotes | tr -d '\r')
ROLE_ID=$(kcadm get roles/finance -r inventory --fields id --format csv --noquotes | tr -d '\r')
kcadm update "clients/$RS_ID/authz/resource-server/policy/role/$POLICY_ID" -r inventory \
  -b "{\"id\":\"$POLICY_ID\",\"name\":\"finance-only\",\"type\":\"role\",\"logic\":\"POSITIVE\",\"decisionStrategy\":\"UNANIMOUS\",\"roles\":[{\"id\":\"$ROLE_ID\",\"required\":false}]}"
```

## Step 4: Ask again

```sh
decision alice 'invoice#view'
decision bob 'invoice#view'
decision alice 'invoice#edit'
```

The answers are `200`, `403` and `403`. Run `astrona submit` to grade the lab.
