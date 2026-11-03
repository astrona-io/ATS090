# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Logout configuration

## Scenario

The client `inventory-cli` in the realm `inventory` backs the application at `https://app.example.com`. After a review of its logout, you find four problems. Any address is accepted as a post-logout redirect. No back-channel logout URL is set, so the application back end never learns about logouts. The logout token would not carry the session ID. And `alice` is signed in on two devices that should be closed.

Keycloak runs in the namespace `logout-demo`. The back end of the application listens at `http://app-backend.logout-demo.svc:8080/backchannel-logout`.

## Your task

In the realm `inventory`:

1. Restrict the post-logout redirect URIs of the client to `https://app.example.com/signed-out`.
2. Set the back-channel logout URL of the client to the back-end address above.
3. Make the logout token carry the session ID.
4. End all sessions of `alice`.

## Constraints

- Change the client `inventory-cli`. Do not create new clients.
- Do not use `*` or `+` for the redirect URIs.
- Do not use the realm-wide `logout-all` and do not disable the user.

## Done when

- The client attribute `post.logout.redirect.uris` is exactly `https://app.example.com/signed-out`.
- The back-channel logout URL is set to the back-end address.
- Back-channel logout requires the session ID.
- `alice` has no live sessions.
