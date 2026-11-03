# Requesting And Evaluating Permissions

With the model in place, a client asks Keycloak whether a user may do something. The request uses the **UMA ticket grant**, an OAuth extension from User-Managed Access, at the normal token endpoint.

## The request

The client sends the user's access token as a bearer token, names the resource server as the `audience`, and lists the permissions it wants as `resource#scope`:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=authz-demo
decision() {
  # decision USER PERMISSION: prints allow or deny
  ACCESS=$(kubectl -n "$NAMESPACE" exec deploy/tester -- \
    curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=password -d client_id=inventory-cli \
      -d "username=$1" -d "password=$1-password" -d scope=openid | jq -r .access_token)
  CODE=$(kubectl -n "$NAMESPACE" exec deploy/tester -- \
    curl -s -o /dev/null -w '%{http_code}' http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -H "Authorization: Bearer $ACCESS" \
      -d grant_type=urn:ietf:params:oauth:grant-type:uma-ticket \
      -d audience=invoice-api --data-urlencode "permission=$2" -d response_mode=decision)
  if [ "$CODE" = "200" ]; then echo allow; else echo "deny ($CODE)"; fi
}
decision alice 'invoice#view'
decision bob 'invoice#view'
decision alice 'invoice#edit'
```

With the response mode `decision`, Keycloak answers `200` with `{"result":true}` for a grant and `403` with the error `access_denied` for a denial. For `alice` and `invoice#view` the answer is `allow`. For `bob`, who has no finance role, and for `invoice#edit`, which no permission covers, the answer is `deny (403)`.

## Getting a token with the permissions

Without `response_mode=decision`, Keycloak answers with a **Requesting Party Token** (RPT): an access token that carries an `authorization` claim listing the granted permissions. The API can read the granted resources and scopes from that claim and enforce them locally:

```sh
ACCESS=$(kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=inventory-cli -d username=alice -d password=alice-password -d scope=openid | jq -r .access_token)
kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -H "Authorization: Bearer $ACCESS" \
    -d grant_type=urn:ietf:params:oauth:grant-type:uma-ticket -d audience=invoice-api \
  | jq -r .access_token | jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson | .authorization'
```

A request without a `permission` parameter asks for all permissions the user has. The claim lists each resource with its granted scopes.

## Why a request is denied

When a decision surprises you, check in this order:

1. Does a permission cover the resource and scope? If not, the request is denied.
2. Does the policy of that permission pass for this user? Read its type, roles and logic.
3. Is the logic `NEGATIVE`? Then the result is inverted.
4. Is the enforcement mode of the resource server `DISABLED` or `PERMISSIVE`? Then the decision may not be what you expect.
5. Is the audience the client ID of the resource server?

The admin console also has an **Evaluate** tool on the authorization tab that runs a request for a chosen user and shows which policies passed.

## Your mission: Grant Access With A Role Policy Lab

The mission starts from a resource server where the right permission exists but nobody passes it. You find the cause with decisions for two users and fix it.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-090-playground-100-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS090.git -c sections/section-100/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-100/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-090-lab-100-01
astrona start ats-090-playground-100-01
```

## Common pitfalls

> [!WARNING]
> - **Sending the request without the bearer token.** The grant needs the user's access token.
> - **Using the realm name as the audience.** The audience is the resource server's client ID.
> - **Encoding `#` wrongly.** Send `resource#scope` with `--data-urlencode`.
> - **Trusting the Evaluate tool for a user without checking roles.** It evaluates the roles the user has now.
