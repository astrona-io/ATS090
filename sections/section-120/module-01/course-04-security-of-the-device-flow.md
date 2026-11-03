# Security Of The Device Flow

The device flow trades some safety for convenience. The user approves a request that started on a different device, and the user cannot always tell who started it. Knowing the risks lets you set limits.

## Phishing with a user code

An attacker starts a device request on their own machine, gets a user code, and asks the victim to "enter this code to sign in". The victim signs in and approves, and the attacker's device now holds the victim's tokens. This is real and is called device code phishing.

The defences are:

- **Short code lifetimes.** An attacker has less time to talk the victim into it.
- **A clear consent screen** that names the client, so the user sees what they approve.
- **Training and wording.** Tell users to enter codes only for a device in front of them.
- **Limited scopes.** A device client should get the smallest set of scopes that it needs.

## Brute force on user codes

User codes are short. Keycloak limits them in length, rate and lifetime. A short lifetime also limits this attack, because a guessed code works only while the request is alive. Do not raise the lifetime to be kind to slow users.

## Which clients may use the grant

Enable the grant only on the clients that need it. A client with the grant on and a broad scope list is a way for tokens to leave through an approval a user does not understand. Review which clients have the attribute set:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=device-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm get clients -r inventory --fields clientId,publicClient,directAccessGrantsEnabled,attributes
```

Look for `oauth2.device.authorization.grant.enabled` set to `true` and check the lifetime, the interval, and whether `directAccessGrantsEnabled` is also on.

## A checklist for a device client

1. The client is public and has no redirect URIs it does not use.
2. The device grant is enabled on this client only.
3. The code lifetime is 600 seconds or less.
4. The polling interval is 5 seconds or more.
5. Direct access grants and the standard flow are off if the device does not use them.
6. Consent is on when the device is shared or hard to inspect.
7. Sessions of lost devices can be ended by an administrator.

## Common pitfalls

> [!WARNING]
> - **Long lifetimes to make setup easier.** They help attackers more than users.
> - **Enabling the device grant on an existing web client.** Create a client for the device.
> - **Leaving direct access grants on.** A second, weaker path to tokens.
> - **Showing no client name on the consent screen.** Users cannot judge what they approve.
