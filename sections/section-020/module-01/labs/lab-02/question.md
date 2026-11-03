# Question

Solve this question on: `terminal`

**Time:** about 15 minutes · **Topic:** Browser sign-in

## Scenario

An inventory application reads the signed-in user's email address from the UserInfo endpoint, to send stock reports. Since last week the address is missing from the answer, and the report job fails. The user `alice` has the email address `alice@example.com`, verified, and she can sign in.

The application uses the client `inventory-app` in the realm `inventory`. For the lab, the client allows the password grant, so that you can get tokens from a terminal. `alice` has the password `alice-password`. Keycloak runs in the namespace `pkce-demo`.

## Your task

In the realm `inventory`:

1. Get an access token for `alice` with the client `inventory-app` and the scope `openid`, and call the UserInfo endpoint with it.
2. Find out why the email claims are missing.
3. Fix the cause, then call UserInfo again and read the answer.

## Constraints

- Do not change the user `alice`, and do not change the realm settings.
- Do not add a protocol mapper to the client. Use the client scope that already exists.
- `inventory-app` stays a public client.

## Done when

- The default client scopes of `inventory-app` include `email` and `profile`.
- The UserInfo answer for `alice` contains `email` set to `alice@example.com` and `email_verified` set to `true`.
- The UserInfo answer still contains `preferred_username` and `given_name`.
