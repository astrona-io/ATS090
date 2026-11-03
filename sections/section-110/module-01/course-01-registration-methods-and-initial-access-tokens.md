# Registration Methods And Initial Access Tokens

A client can come into a realm in four ways. Each has a different audience, and the difference decides how much you must trust the caller.

## The ways to create a client

| Method | Who uses it | Needs |
| --- | --- | --- |
| Admin console or admin REST API | Administrators and automation | An admin token with the right to manage clients |
| Client registration endpoint, Keycloak format | Tools that know Keycloak | An initial access token, a bearer token, or nothing if anonymous registration is allowed |
| Client registration endpoint, OpenID Connect format | Standard clients | The same as above |
| Import of a realm file | Setup and migration | Access to the server |

The two registration endpoints live under the realm:

```text
/realms/<realm>/clients-registrations/default
/realms/<realm>/clients-registrations/openid-connect
```

The `default` endpoint takes and returns the Keycloak client representation. The `openid-connect` endpoint follows the OpenID Connect dynamic registration specification: fields such as `client_name`, `redirect_uris`, `grant_types` and `token_endpoint_auth_method`. A client written against the standard can register with any server that supports it.

## Who may call the endpoint

A registration request can carry:

- **No token.** This is anonymous registration. Only the registration policies for anonymous requests protect the realm.
- **An initial access token.** An administrator creates it for a limited number of registrations and a limited time.
- **A bearer token of a user or service account.** The account needs the client management role. This is authenticated registration.

Prefer initial access tokens. They put a number and a time limit on what a caller can do, and they can be handed to a partner without giving an account.

## Create and use an initial access token

<!-- astrona:playground:renew -->

```sh
NAMESPACE=reg-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm create clients-initial-access -r inventory -s count=1 -s expiration=600 -o
```

The answer holds the `token`, the `count` and the `expiration` in seconds. The token is shown only now. Use it once with the OpenID Connect endpoint:

```sh
IAT=<the token>
kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s http://keycloak:8080/realms/inventory/clients-registrations/openid-connect \
    -H "Authorization: Bearer $IAT" -H 'Content-Type: application/json' \
    -d '{"client_name":"partner-app","redirect_uris":["https://partner.example.com/callback"],"grant_types":["authorization_code"],"token_endpoint_auth_method":"client_secret_basic"}' | jq .
```

The answer is the registered client: `client_id`, `client_secret` for a confidential client, and a `registration_access_token` with a `registration_client_uri`. Keep the last two values. They are the only way for the caller to read, change or delete this client later.

## Count and expiration

The initial access token has a **count**: how many registrations it allows. It also has an **expiration**: how many seconds it lives. Once either runs out, the token is rejected. List tokens and remove one:

```sh
kcadm get clients-initial-access -r inventory
```

The list shows ids, counts, remaining counts and expiration, never the token itself. A token for many clients with a long life is almost as dangerous as an open endpoint, so make it small.

## Common pitfalls

> [!WARNING]
> - **Allowing anonymous registration to avoid managing tokens.** Anyone who reaches the endpoint can create clients.
> - **Losing the registration access token.** Only an administrator can then manage that client.
> - **Creating a token with a large count and no expiration thinking.** Pick the smallest count and shortest time that fit the job.
> - **Posting Keycloak fields to the OpenID Connect endpoint.** Use the field names of the standard there.
