# Question

Solve this question on: `terminal`

**Time:** about 15 minutes · **Topic:** Session administration

## Scenario

Security suspects that the account of `alice` in the realm `inventory` was used from an unknown device. She is signed in twice. The realm also lets an inactive session live for a whole day.

Keycloak runs in the namespace `logout-demo`. The user `alice` has the password `alice-password`.

## Your task

In the realm `inventory`:

1. List the sessions of `alice` and count them.
2. End all sessions of `alice`.
3. Set the SSO session idle limit to 900 seconds.
4. Check that the session list of `alice` is empty and that she can still sign in.

## Constraints

- End the sessions of `alice` only. Do not call the realm-wide `logout-all`.
- Do not disable the user and do not delete the user.
- Change the idle limit on the realm, not on the client.

## Done when

- `alice` has no live sessions.
- `ssoSessionIdleTimeout` is `900` or less.
- A new password-grant sign-in for `alice` still works.
