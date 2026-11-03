# UserInfo, Scopes And The openid Scope

The ID token tells the application who signed in, but an application can also ask Keycloak about the user later, with a plain request and the access token. This part shows that request, the **UserInfo endpoint**, and the setting that decides which facts about the user it returns: client scopes.

## The UserInfo endpoint

The **UserInfo endpoint** answers one question: who owns this access token? You send the access token in an `Authorization: Bearer` header, and Keycloak returns the claims about the user as JSON. For the realm `inventory` the address is `/realms/inventory/protocol/openid-connect/userinfo`, and the discovery document lists it as `userinfo_endpoint`.

The claims depend on the **scopes** of the token. A scope is a name the client puts in the `scope` parameter to say what it wants to read. Keycloak ties each name to a **client scope**, a bundle of mappers that decide which claims go into the token and into the UserInfo answer. The `openid` scope has a special meaning: it turns an OAuth 2.0 request into an OpenID Connect request. Without it there is no ID token, and no UserInfo.

To try the endpoint, create a small public client that may use the password grant, so that you can get a token with one request. This is a lab shortcut. A browser application would use the code flow from the earlier parts. Define the helper and sign in as the administrator:

```sh
NAMESPACE=pkce-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm create clients -r inventory -s clientId=inventory-tool -s enabled=true \
  -s publicClient=true -s standardFlowEnabled=false -s directAccessGrantsEnabled=true
```

Now get a token with the scope `openid` and call the UserInfo endpoint with it:

```sh
userinfo() {
  # userinfo SCOPE: gets a token for alice with that scope and prints the UserInfo answer.
  kubectl -n pkce-demo exec deploy/tester -- sh -c '
    TOKEN=$(curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=password -d client_id=inventory-tool \
      -d username=alice -d password=alice-password -d "scope=$0" | jq -r .access_token)
    curl -s -w "\nstatus=%{http_code}\n" http://keycloak:8080/realms/inventory/protocol/openid-connect/userinfo \
      -H "Authorization: Bearer $TOKEN"' "$1"
}
userinfo openid
```

The answer is a JSON object with `sub`, `preferred_username`, `email`, `email_verified`, `given_name`, `family_name` and `name`, and then `status=200`. Those claims come from the default client scopes `profile` and `email`. The `sub` claim is the user's ID in Keycloak. It is the only claim that is always there, and the one an application should use as the key for its own records, because an email address can change.

## What the openid scope changes

Ask for a token without `openid`, and call UserInfo with it:

```sh
userinfo profile
```

The token request still works, because the password grant does not need OpenID Connect. The UserInfo call does: Keycloak answers with an error status and no claims, because the token was not issued for an OpenID Connect sign-in. An application that signs users in must always send `scope=openid`. Without it, the application gets an access token and nothing that says who the user is.

## Default scopes and optional scopes

A client has two lists of client scopes. The **default client scopes** are added to every token the client gets, whether the request names them or not. The **optional client scopes** are added only when the request names them in `scope`. The built-in `profile` and `email` scopes are default scopes of a new client. Scopes such as `address`, `phone` and `offline_access` are optional.

Read the lists for the new client:

```sh
TOOL_ID=$(kcadm get clients -r inventory -q clientId=inventory-tool --fields id --format csv --noquotes | tr -d '\r')
echo "default:";  kcadm get "clients/$TOOL_ID/default-client-scopes" -r inventory --fields name | jq -r '.[].name'
echo "optional:"; kcadm get "clients/$TOOL_ID/optional-client-scopes" -r inventory --fields name | jq -r '.[].name'
```

`email` and `profile` are default. Remove `email` from the defaults and read the UserInfo answer again:

```sh
EMAIL_ID=$(kcadm get client-scopes -r inventory --fields id,name --format csv --noquotes | tr -d '\r' | awk -F, '$2 == "email" {print $1}')
kcadm delete "clients/$TOOL_ID/default-client-scopes/$EMAIL_ID" -r inventory
userinfo openid
```

The answer still has `sub` and the profile claims, and `email` and `email_verified` are gone. The user did not change. The client stopped asking for those claims. This is the usual cause of the report "the application does not get the user's email address": look at the client's scopes, not at the user.

You do not need a mapper to bring `email` back. Put the scope back on the list and read the answer once more:

```sh
kcadm update "clients/$TOOL_ID/default-client-scopes/$EMAIL_ID" -r inventory \
  -s realm=inventory -s clientId="$TOOL_ID" -s clientScopeId="$EMAIL_ID" -n
userinfo openid
```

`email` is back. Moving `email` to the optional list would give a middle way: the claim appears only for a request with `scope=openid email`. That is the right choice for data that only some parts of an application need.

## Common pitfalls

> [!WARNING]
> - **Forgetting `scope=openid`.** The sign-in works and the token is fine, but there is no ID token and UserInfo refuses the call.
> - **Looking for a missing claim in the user.** If the user has the attribute and the claim is missing, check the client scopes of the client first.
> - **Using the email address as the user's key.** It can change and it is not always set. The `sub` claim does not change.
> - **Calling UserInfo with an expired access token.** The answer is an error, not an empty object. Refresh the token and call again.

## Your mission: Give An Application The Claims It Asks For

You can now call UserInfo, read the default and optional scopes of a client and tell a missing claim from a missing scope. The graded lab gives you a client whose users sign in fine but whose UserInfo answer has no email address, and asks you to find the cause and fix it without touching the user.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-090-playground-020-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS090.git -c sections/section-020/module-01/labs/lab-02
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-01/labs/lab-02
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-090-lab-020-02
astrona start ats-090-playground-020-01
```
