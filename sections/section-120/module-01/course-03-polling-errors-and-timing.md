# Polling, Errors And Timing

After the device shows the code, it loops on the token endpoint. The loop is where most device bugs happen.

## The polling request

<!-- astrona:playground:renew -->

```sh
NAMESPACE=device-demo
DEVICE=$(kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/auth/device -d client_id=kiosk)
DEVICE_CODE=$(echo "$DEVICE" | jq -r .device_code)
kubectl -n "$NAMESPACE" exec deploy/tester -- \
  curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=urn:ietf:params:oauth:grant-type:device_code \
    -d client_id=kiosk -d device_code="$DEVICE_CODE" | jq .
```

The grant type is the long value `urn:ietf:params:oauth:grant-type:device_code`. Until the user approves, the answer is an error. That is normal.

## The error codes

| Error | Meaning | What the device does |
| --- | --- | --- |
| `authorization_pending` | The user has not approved yet | Wait the interval, then poll again |
| `slow_down` | The device polled too fast | Add 5 seconds to the interval and poll again |
| `access_denied` | The user refused the request | Stop and tell the user |
| `expired_token` | The code expired | Stop and start a new request |

A device that ignores `slow_down` can be blocked by the server. A device that never stops after `expired_token` wastes requests forever. Stop on any error other than the first two.

## Timing

`expires_in` is the total time the user has. `interval` is the time between polls. A 600 second lifetime with a 5 second interval gives up to 120 polls. Pick values like these:

- **Lifetime**: long enough for a person to find a phone and sign in, short enough to limit guessing. Ten minutes is typical.
- **Interval**: five seconds is the standard minimum. One second floods the server for no gain.

## Approving from the second device

The user opens the `verification_uri`, signs in and enters the user code. The admin console cannot approve for them. In a lab without a browser you can read the state of the polling only; the approval needs a person with a browser. After approval, the next poll returns an access token, a refresh token and an ID token if the scope `openid` was requested. The device then behaves like any client with tokens.

## Refresh and long lives

A TV stays signed in for months. The device keeps the refresh token and uses it to get new access tokens. Set the offline or refresh lifetimes of the realm to match how long a device may stay signed in, and use revocation or session removal when a device is lost.

## Common pitfalls

> [!WARNING]
> - **Polling without waiting.** Respect the interval and `slow_down`.
> - **Treating `authorization_pending` as a failure.** It is the normal waiting answer.
> - **Not stopping on `expired_token`.** Start a new device request instead.
> - **Storing the refresh token in clear text on a shared device.** Anyone with the device can use it.
