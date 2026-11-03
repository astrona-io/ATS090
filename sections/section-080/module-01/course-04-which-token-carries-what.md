# Which Token Carries What

A single sign-in produces several artifacts: an access token, an ID token, a refresh token, and an endpoint that returns user data on request. Each has a different reader. Putting a claim into the wrong one is a common mistake: an application reads the access token, which belongs to the API, or an API trusts the ID token, which belongs to the application. This part says who reads what and how to check each.

## The access token

The **access token** is for the resource server, the API. It states who the caller is and what it may do: the audience, the scopes and the roles. The application that holds the token should treat it as opaque. Reading its claims is allowed, but the format can change, and Keycloak can issue tokens that are not JWTs in other setups. The API validates the token and reads its roles.

## The ID token

The **ID token** is for the client application. It tells the application who signed in: the subject, the user name, the email and the time of sign-in. It is a JWT in a fixed format defined by OpenID Connect, and the application validates it, including the `nonce`. The API must never accept an ID token as an access token, because its audience is the client, not the API.

Define the helpers, then compare the claims of both tokens for the mappers you added in the last parts:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=scopes-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
decode_token() {
  jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson'
}
get_tokens() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- \
    curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=password -d client_id=inventory-cli \
      -d username=alice -d password=alice-password -d scope=openid
}
TOKENS=$(get_tokens)
printf '%s' "$TOKENS" | jq -r .access_token | decode_token | jq '{typ, aud, azp}'
printf '%s' "$TOKENS" | jq -r .id_token | decode_token | jq '{typ, aud, azp}'
```

The access token has the type `Bearer`. The ID token has the type `ID`, and its audience is the client `inventory-cli` itself. The first line of each answer already tells you which reader the token is for.

## The UserInfo endpoint

The **UserInfo endpoint**, `/realms/<realm>/protocol/openid-connect/userinfo`, returns claims about the signed-in user as JSON. The client calls it with the access token in the `Authorization: Bearer` header. Only mappers whose **Add to userinfo** switch is on appear in the response. This keeps the ID token small and lets the application fetch more data only when it needs it:

```sh
ACCESS=$(printf '%s' "$TOKENS" | jq -r .access_token)
kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s -H "Authorization: Bearer $ACCESS" http://keycloak:8080/realms/inventory/protocol/openid-connect/userinfo | jq 'keys'
```

The response always holds `sub`, and holds the claims of the mappers that write to userinfo, such as `preferred_username`, `email` and, if you created the mappers in the last part, `groups` and `contact`. It does not hold `tenant`, because that mapper's userinfo switch is off.

## Introspection and lightweight tokens

Token introspection, which a confidential client calls at `/realms/<realm>/protocol/openid-connect/token/introspect`, returns the claims of an access token and `active: true` while the token is valid. The switch **Add to token introspection** decides which claims appear there. Keycloak also offers lightweight access tokens, a client setting called **Always use lightweight access token**, which leaves most claims out of the token and lets the resource server fetch them through introspection. This keeps tokens small and moves the data to a call that always shows current values.

| Where | Reader | Switch on the mapper |
| --- | --- | --- |
| Access token | The API | Add to access token |
| ID token | The client application | Add to ID token |
| UserInfo response | The client application, on request | Add to userinfo |
| Introspection response | The API, on request | Add to token introspection |

## Choosing the place for a claim

Put a claim into the access token if the API decides on it, such as roles and tenant. Put it into the ID token if the application shows it, such as the display name. Put it into userinfo if the application needs it sometimes and the ID token should stay small. A claim needed in two places has its switch on in both. When a claim is missing, find out which reader looks for it, and then check the matching switch on the mapper.

You have followed a claim from the mapper to every token that can hold it. The scope decides whether the mapper runs, the switch decides where it writes and the role scope decides which roles come along.

## Common pitfalls

> [!WARNING]
> - **Reading the access token in the application.** The access token is for the API; use the ID token or the UserInfo endpoint.
> - **Accepting an ID token at an API.** Its audience is the client, not the API.
> - **Expecting a userinfo claim from a mapper with the userinfo switch off.** Each token has its own switch.
> - **Putting large claims in every token.** Use userinfo or introspection for data that is not needed on every request.
