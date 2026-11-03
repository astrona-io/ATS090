# Control Token Lifetimes, Refresh Tokens And Sessions

An access token is a bearer credential: whoever holds it can use it until it expires. A short lifetime limits the damage of a stolen token, but a short lifetime alone would force users to sign in every few minutes. Keycloak solves this with a second token, the refresh token, and with sessions on the server that decide how long a user stays signed in.

This module shows which setting controls which lifetime. A user signs in once and gets an **access token** for APIs and a **refresh token**, which the client sends to the token endpoint to get a new access token without asking the user again. Behind both sits a **session**: the record Keycloak keeps of the user's sign-in. When the session ends, the refresh token stops working.

Keep one sentence in mind: **the access token is valid until it expires, the refresh token is valid while its session is alive.** Almost every lifetime question in Keycloak comes down to which of the two you are asking about.

The module has four parts. **Token And Session Lifespans** reads and changes the realm settings and a client override. **The Refresh Token Grant And Rotation** refreshes tokens and stops a refresh token from being used twice. **Offline Tokens** covers long-lived refresh tokens for background work. **Ending Sessions And Revoking Tokens** shows how to stop a token on purpose. A graded lab follows the second part.

## Learning objectives

After this module you can:

- Name the realm settings that set the lifetime of an access token, an SSO session and an offline session.
- Override the access token lifespan for one client and check the result in a token.
- Refresh an access token with the refresh token grant.
- Turn on refresh token rotation and explain what happens when a refresh token is used twice.
- Request an offline token with the `offline_access` scope and say where it is stored.
- End a session, revoke a token and say what an API that validates tokens locally still accepts.

## Before you start

You need Kubernetes basics, `curl` and `jq`, and you should know what a realm, a user, a client and an access token are. You will decode JSON Web Tokens (JWT): tokens made of three Base64URL parts, a header, a payload with claims, and a signature, separated by dots.

Your playground is a single-node `kind` cluster with **Keycloak 26.8.1** in development mode. The namespace **`sessions-demo`** runs these workloads:

| Workload | What it is |
| --- | --- |
| `keycloak` | One Keycloak pod, behind the Service `keycloak` on port `8080` |
| `tester` | A client pod with `curl` and `jq`. Every request is sent from here |

Inside Keycloak, the realm `inventory` holds the user `alice` (password `alice-password`) and the public client `inventory-cli`, which can use the password grant so you can get tokens from a terminal. The administrator of the `master` realm is `admin` with the password `admin`; these are lab-only credentials. OAuth 2.1 drops the password grant, and a real application uses the authorization code flow; here it only saves you a browser.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
