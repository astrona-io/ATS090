# Managing Registered Clients

Registering a client is the start of its life. This part covers how the caller manages its client, how you as administrator keep control, and a checklist for opening registration to partners.

## The registration access token

The answer to a registration holds a `registration_access_token` and a `registration_client_uri`. The caller uses them to read, update or delete only that client:

```sh
curl -s "$REGISTRATION_CLIENT_URI" -H "Authorization: Bearer $REGISTRATION_ACCESS_TOKEN"
```

Every update returns a new registration access token, and the old one stops working. A caller that updates a client and drops the new token has lost control of it. Administrators can always manage the client through the admin API.

## Find clients that were registered dynamically

Dynamically registered clients look like other clients. Name them so you can find them, for example by requiring a prefix in the name, and review them on a schedule:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=reg-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm get clients -r inventory --fields clientId,enabled,redirectUris
```

Look for wildcard redirect URIs, `fullScopeAllowed` and clients that nobody remembers.

## What a safe partner registration looks like

1. Hand the partner an initial access token with count 1 and a short expiration.
2. Keep Trusted Hosts for anonymous requests set to the partner's domain with client URIs required to match.
3. Create a client policy for the partner profile: PKCE required, password grant rejected, secure redirect URIs.
4. Keep Client Disabled on if you want to review each client before it can sign users in.
5. Review registered clients and delete the ones no longer used.

## Why both layers

Registration policies stop bad requests on the registration endpoints. Client policies make sure that no client, however created, breaks the rules. Together they close the gap: an administrator who changes a client in the console is still held to the same rules.

## Events

Registration and client updates create admin events when admin events are on. Turn on admin events for the realm so you can answer who created a client and when.

## Common pitfalls

> [!WARNING]
> - **Dropping the new registration access token after an update.** The old one no longer works.
> - **Opening registration to all and filtering later.** Close first, then open for named callers.
> - **Never reviewing registered clients.** Unused clients with valid secrets stay a way in.
> - **Relying on one layer.** Use registration policies and client policies together.
