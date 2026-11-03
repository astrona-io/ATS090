# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Device authorization grant

## Scenario

A TV application signs in users with the client `tv-app` in the realm `inventory` and the device authorization grant. A review finds that the client is unsafe: the codes live far too long, a device can poll every second, the client has a secret that would ship on every TV, and a second sign-in path is open.

Keycloak runs in the namespace `device-demo`. The administrator of the `master` realm is `admin` with the password `admin`.

## Your task

In the realm `inventory`:

1. Read the client and note the device grant settings.
2. Make the client safe for a device you hand out: a public client, codes that live no longer than 10 minutes, a polling interval of at least 5 seconds, and no direct access grants.
3. Keep the device grant working. Request a device code and poll once.

## Constraints

- Keep the device grant enabled on `tv-app`.
- Do not create another client.
- Do not enable the standard flow.

## Done when

- `tv-app` is a public client with direct access grants off.
- The device request returns `expires_in` of 600 or less and `interval` of 5 or more.
- Polling answers `authorization_pending`.
