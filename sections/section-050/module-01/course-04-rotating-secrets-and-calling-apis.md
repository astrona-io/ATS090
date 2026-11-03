# Rotating Secrets And Calling APIs

A client secret does not stay secret forever. It ends up in a pipeline log, a backup or a chat message, and a person who knew it leaves the team. Keycloak lets you replace the secret at any time. This part rotates the secret of a service client, shows what happens to the old one, and ends with the habit a service client needs when it calls an API many times.

## Regenerate the secret

The Admin REST API has an endpoint that generates a new secret for a client: `POST clients/<id>/client-secret`. With `kcadm` that is `create clients/<id>/client-secret`. The answer holds the new secret in the field `value`. Reading it later uses `get` on the same path.

Define the helpers, keep the old secret, and regenerate:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=m2m-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
request_status() {
  kubectl -n "$NAMESPACE" exec deploy/tester -- \
    curl -s -o /dev/null -w '%{http_code}\n' -u "$1:$2" \
      http://keycloak:8080/realms/inventory/protocol/openid-connect/token -d grant_type=client_credentials
}
SYNC_ID=$(kcadm get clients -r inventory -q clientId=inventory-sync --fields id --format csv --noquotes | tr -d '\r')
OLD_SECRET=inventory-sync-secret
kcadm create "clients/$SYNC_ID/client-secret" -r inventory
NEW_SECRET=$(kcadm get "clients/$SYNC_ID/client-secret" -r inventory | jq -r .value)
```

Keycloak generates a long random value and stores it. The variable `NEW_SECRET` now holds it. Test both secrets:

```sh
request_status inventory-sync "$OLD_SECRET"
request_status inventory-sync "$NEW_SECRET"
```

The old secret answers `401` and the new one answers `200`. Regeneration takes effect at once: Keycloak keeps no grace period by default, so every job that still holds the old secret fails on its next token request. Plan the change: update the secret where the job reads it, then regenerate, or regenerate and update in one step.

## Rotation with a grace period

Keycloak can keep the old secret valid for a while. The client policy executor `secret-rotation` does that. A **client policy** is a rule set that Keycloak applies to clients that match a condition. The executor limits how long a secret lives, and keeps the previous secret valid for a configured time after rotation, so a running job has time to switch. Remember that this setting exists, and that without it a regeneration cuts off the old secret immediately.

## Using the token

A service client that requests a new token for every API call wastes work on both sides. The response says how long the token lives in `expires_in`, in seconds. A good client keeps the token in memory, uses it for each call and asks for a new one shortly before it expires, for example 30 seconds early. The access token lifespan of a realm is five minutes by default, and a client can have its own lifespan.

Read the lifetime of a token and the client's own setting:

```sh
request_status inventory-reporter inventory-reporter-secret
kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s -u inventory-reporter:inventory-reporter-secret \
    http://keycloak:8080/realms/inventory/protocol/openid-connect/token -d grant_type=client_credentials | jq '{expires_in, token_type}'
```

The first command prints `200`. The second prints `expires_in` with the realm's access token lifespan in seconds and `token_type` `Bearer`. If a job needs tokens that live longer or shorter, the client can override the lifespan, but a short lifespan with caching is the safer choice: a stolen token stops working soon.

When the token reaches the API, the API runs the same checks as for any token: signature, issuer, audience and roles. The service client therefore also needs the audience of the API in its tokens, added with an audience mapper, and the role the API demands, held by its service account. A service client that gets `401` from an API usually lacks the audience; one that gets `403` lacks the role.

You can now replace a secret, tell what happens to the old one, and keep token requests to the minimum a job needs. Together with the grant, the service account and the authentication method, that is everything a service client needs to work safely.

## Common pitfalls

> [!WARNING]
> - **Regenerating before the job has the new secret.** The old secret stops working at once unless a rotation policy keeps it valid.
> - **Asking for a token on every call.** Cache it and renew it before `expires_in` runs out.
> - **Forgetting the audience.** A token with a good role can still get `401` if the API's client is not in `aud`.
> - **Printing the secret in a log.** A secret in a pipeline log must be treated as leaked: rotate it.
