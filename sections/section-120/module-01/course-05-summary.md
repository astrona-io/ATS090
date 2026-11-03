# Summary

The device authorization grant lets an input-limited device get tokens through an approval on a second device. The device never sees a password.

## What you learned

The device sends its client ID to the device authorization endpoint and receives a device code, a user code, a verification address, a lifetime and an interval. The user signs in on a second device and approves the user code. The device polls the token endpoint with the device grant type until it gets tokens. The grant is enabled per client with the attribute `oauth2.device.authorization.grant.enabled`, and the lifetime and interval are client attributes. A client with the grant off answers `unauthorized_client`.

The key facts to remember are these:

- Poll no faster than the interval; wait on `authorization_pending`, slow down on `slow_down`, stop on `access_denied` and `expired_token`.
- Keep lifetimes short and intervals at 5 seconds or more.
- Use a public client made for the device, and leave other grants off.
- Device code phishing is real; limit scopes and show consent.

<!-- astrona:playground:destroy -->
