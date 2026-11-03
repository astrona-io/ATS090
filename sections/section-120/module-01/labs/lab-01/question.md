# Question

Solve this question on: `terminal`

**Time:** about 15 minutes · **Topic:** Device authorization grant

## Scenario

A display in a shop signs in with the public client `kiosk` in the realm `inventory`. The device cannot start the flow: its request for a device code is refused.

Keycloak runs in the namespace `device-demo`. The administrator of the `master` realm is `admin` with the password `admin`.

## Your task

In the realm `inventory`:

1. Send the device request for `kiosk` and read the error and the status.
2. Read the client and find the setting that is wrong.
3. Fix the client.
4. Send the device request again, then poll the token endpoint once with the device code.

## Constraints

- Keep `kiosk` a public client.
- Do not enable direct access grants.
- Do not change the code lifetime or the polling interval.

## Done when

- The device request for `kiosk` returns a device code and a user code.
- Polling with the device code answers `authorization_pending`.
- `kiosk` is public and has direct access grants off.
