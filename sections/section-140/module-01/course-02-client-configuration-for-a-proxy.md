# Client Configuration For A Proxy

A reverse proxy is a **confidential client** that uses the authorization code flow. The proxy keeps the client secret and exchanges the code on the server side. Its Keycloak client must match the proxy's settings exactly.

## The settings that matter

| Setting | Value for a proxy |
| --- | --- |
| Client authentication | On, so the client is confidential and has a secret |
| Standard flow | On, because the proxy uses the code flow |
| Direct access grants | Off in production |
| Valid redirect URIs | Exactly the callback address of the proxy, for example `https://app.example.com/oauth2/callback` |
| Web origins | Not needed for a server-side proxy |
| Valid post logout redirect URIs | The address the proxy sends users to after logout |

The redirect address must be **exact**. A wildcard such as `https://app.example.com/*` lets an attacker who finds an open redirect on that host receive the authorization code.

## Claims the proxy needs

Most proxies check two things in the tokens, and Keycloak does not add both by default.

**The audience.** A proxy checks that the token was meant for it. The `aud` claim must contain the client ID of the proxy. The ID token has it by default. An access token usually does not, so add an **audience mapper** to the client:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=proxy-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
CLIENT_ID=$(kcadm get clients -r inventory -q clientId=web-proxy --fields id --format csv --noquotes | tr -d '\r')
kcadm create "clients/$CLIENT_ID/protocol-mappers/models" -r inventory \
  -s name=audience -s protocol=openid-connect -s protocolMapper=oidc-audience-mapper \
  -s 'config."included.client.audience"=web-proxy' \
  -s 'config."access.token.claim"=true' -s 'config."id.token.claim"=false'
```

**The groups.** To allow only some groups, the proxy reads a claim. Add a **group membership mapper** whose claim name matches the proxy setting:

```sh
kcadm create "clients/$CLIENT_ID/protocol-mappers/models" -r inventory \
  -s name=groups -s protocol=openid-connect -s protocolMapper=oidc-group-membership-mapper \
  -s 'config."claim.name"=groups' -s 'config."full.path"=false' \
  -s 'config."access.token.claim"=true' -s 'config."id.token.claim"=true' -s 'config."userinfo.token.claim"=true'
```

With `full.path` off, a member of the group `staff` gets the value `staff`. With it on, the value is `/staff`. The proxy's allowed group must use the same form.

## A typical proxy command

The values below show how the Keycloak settings map to the proxy. They are an example of the options of oauth2-proxy, not output from the playground:

```text
--provider=keycloak-oidc
--oidc-issuer-url=https://auth.example.com/realms/inventory
--client-id=web-proxy
--client-secret=<secret>
--redirect-url=https://app.example.com/oauth2/callback
--oidc-groups-claim=groups
--allowed-group=staff
--upstream=http://app:8080
--cookie-secret=<random 32 bytes>
```

Each option corresponds to a Keycloak setting: the issuer is the realm URL, the client ID and secret are the client's, the redirect URL is a valid redirect URI, and the groups claim is the mapper's claim name.

## Look at the token

Get a token for `alice` with the test client and read the claims the proxy would see:

```sh
ACCESS=$(kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=web-proxy -d client_secret=web-proxy-secret \
    -d username=alice -d password=alice-password | jq -r .access_token)
echo "$ACCESS" | jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson | {iss, aud, azp, groups, exp}'
```

## Common pitfalls

> [!WARNING]
> - **A wildcard redirect address.** Use the exact callback.
> - **No audience mapper.** The proxy rejects the token with an audience error.
> - **Different forms of the group name.** `/staff` and `staff` are not the same value.
> - **Leaving direct access grants on.** It lets a client with the secret and a password skip the browser.
