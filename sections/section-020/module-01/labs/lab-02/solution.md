# Solution: Give An Application The Claims It Asks For

Work the task yourself first. Running `astrona submit -c sections/section-020/module-01/labs/lab-02` after a step tells you which checks pass, without telling you what is left.

## Step 1: Call UserInfo

```sh
NAMESPACE=pkce-demo
kubectl -n "$NAMESPACE" exec deploy/tester -- sh -c '
  TOKEN=$(curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=inventory-app \
    -d username=alice -d password=alice-password -d scope=openid | jq -r .access_token)
  curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/userinfo \
    -H "Authorization: Bearer $TOKEN"' | jq
```

The answer has `sub`, `preferred_username`, `given_name` and `family_name`, but no `email` and no `email_verified`.

## Step 2: Find the cause

The user has the email address, so the problem is in the client. Read its default client scopes:

```sh
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
APP_ID=$(kcadm get clients -r inventory -q clientId=inventory-app --fields id --format csv --noquotes | tr -d '\r')
kcadm get "clients/$APP_ID/default-client-scopes" -r inventory --fields name | jq -r '.[].name'
```

`profile` is on the list and `email` is not.

## Step 3: Put the scope back

```sh
EMAIL_ID=$(kcadm get client-scopes -r inventory --fields id,name --format csv --noquotes | tr -d '\r' | awk -F, '$2 == "email" {print $1}')
kcadm update "clients/$APP_ID/default-client-scopes/$EMAIL_ID" -r inventory \
  -s realm=inventory -s clientId="$APP_ID" -s clientScopeId="$EMAIL_ID" -n
```

Repeat step 1. The answer has `email` and `email_verified` now. Run `astrona submit` to grade the lab.
