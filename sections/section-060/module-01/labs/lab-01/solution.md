# Solution: Shorten Access Tokens And Rotate Refresh Tokens

Work the task yourself first. Running `astrona submit -c sections/section-060/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

## Step 1: Read the settings

```sh
NAMESPACE=sessions-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm get realms/inventory --fields accessTokenLifespan,revokeRefreshToken,refreshTokenMaxReuse
```

`accessTokenLifespan` is `86400`, one day, and `revokeRefreshToken` is `false`.

## Step 2: Change the realm settings

```sh
kcadm update realms/inventory -s accessTokenLifespan=300 -s revokeRefreshToken=true -s refreshTokenMaxReuse=0
```

## Step 3: Measure a new access token

```sh
get_tokens() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- \
    curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=password -d client_id=inventory-cli \
      -d username=alice -d password=alice-password -d scope=openid
}
get_tokens | jq -r .access_token | jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson | .exp - .iat'
```

The answer is `300`. A token you held before the change still has the old expiry; only new tokens use the new setting.

## Step 4: Prove the rotation

```sh
refresh_status() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- \
    curl -s -o /dev/null -w '%{http_code}\n' http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=refresh_token -d client_id=inventory-cli -d refresh_token="$1"
}
FIRST=$(get_tokens | jq -r .refresh_token)
refresh_status "$FIRST"
refresh_status "$FIRST"
```

The first call prints `200`. The second prints `400`, because Keycloak accepts each refresh token once. Run `astrona submit` to grade the lab.
