# Enabling The Grant On A Client

The device grant is off by default. It is a setting on each client, and there are two more settings that shape it.

## Client settings

| Attribute | Meaning |
| --- | --- |
| `oauth2.device.authorization.grant.enabled` | `true` allows the client to start the device flow |
| `oauth2.device.code.lifespan` | Seconds the device code and user code are valid |
| `oauth2.device.polling.interval` | Minimum seconds between two polls |

If the realm does not set them, the client falls back to defaults of 600 seconds for the lifetime and 5 seconds for the interval. In the admin console they are on the client settings page as "OAuth 2.0 Device Authorization Grant", under capability config.

## Read the client

<!-- astrona:playground:renew -->

```sh
NAMESPACE=device-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm get clients -r inventory -q clientId=kiosk --fields clientId,publicClient,attributes
```

## What a disabled client returns

With the grant off, the device endpoint refuses the request:

```sh
kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s -w '\n%{http_code}\n' http://keycloak:8080/realms/inventory/protocol/openid-connect/auth/device \
    -d client_id=kiosk
```

The body holds the error `unauthorized_client` and the status is `400`. This is the first thing to check when a device cannot start.

## Turn it on

```sh
CLIENT_ID=$(kcadm get clients -r inventory -q clientId=kiosk --fields id --format csv --noquotes | tr -d '\r')
kcadm update "clients/$CLIENT_ID" -r inventory \
  -s 'attributes."oauth2.device.authorization.grant.enabled"=true' \
  -s 'attributes."oauth2.device.code.lifespan"=600' \
  -s 'attributes."oauth2.device.polling.interval"=5'
```

Run the request again. The answer is now `200` with the code pair.

## Public or confidential

A device that ships to many users cannot keep a secret, so its client should be **public**. A confidential client can also use the flow, but then the device must send the secret and the secret is on every device. Prefer a public client with short lifetimes.

## Other settings that matter

- **Standard flow and direct access grants** can stay off. The device grant does not need them.
- **Client scopes** decide the claims in the tokens, as for any client. Keep the default scopes small.
- The **consent** setting still applies, and a device is a good case for it, because the user approves a device they cannot fully see.

## Your mission: Enable The Device Grant Lab

The mission starts from a client that is set up for a shop display, but the device cannot start the flow. You find out why and fix it.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-090-playground-120-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS090.git -c sections/section-120/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-120/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-090-lab-120-01
astrona start ats-090-playground-120-01
```

## Common pitfalls

> [!WARNING]
> - **Setting the attribute on the wrong client.** The grant is per client.
> - **Forgetting the quotes around the attribute name in `kcadm`.** The dots must stay inside the name.
> - **Enabling direct access grants as well.** It is a different, weaker flow.
> - **Using a confidential client on a device you hand out.** The secret leaves your control.
