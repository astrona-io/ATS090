# End Sessions: Logout, Back-Channel Logout And Admin Control

Signing in is half of the life of a session. The other half is ending it. A user who clicks "Sign out" in one application expects to be signed out of the others, a security team expects to cut off a stolen account at once, and an operator expects old sessions to disappear. Keycloak ends sessions in several ways, and each ends a different part of the picture.

Keep one sentence in mind: **ending a session in Keycloak does not by itself end the session in every application; the applications must be told, and tokens that were already issued stay valid until they expire.** The module shows each way of telling.

The module has four parts. **How Keycloak Sessions End** lists the ways a session ends. **RP-Initiated Logout And Post-Logout Redirects** covers the logout endpoint a browser application uses. **Back-Channel And Front-Channel Logout** covers how Keycloak tells other applications. **Administering Sessions** covers the admin API and the realm limits. A graded lab follows the fourth part.

## Learning objectives

After this module you can:

- Name the ways a user session ends and what each leaves behind.
- Log a user out with the logout endpoint, with and without a redirect.
- Register post-logout redirect URIs safely.
- Configure back-channel logout for a client and explain what the logout token carries.
- List and end sessions with the admin API.

## Before you start

You need Kubernetes basics, `curl` and `jq`, and you should know what a realm, a user, a client, a refresh token and an ID token are.

Your playground is a single-node `kind` cluster with **Keycloak 26.8.1** in development mode. The namespace **`logout-demo`** runs these workloads:

| Workload | What it is |
| --- | --- |
| `keycloak` | One Keycloak pod, behind the Service `keycloak` on port `8080` |
| `tester` | A client pod with `curl` and `jq`. Every request is sent from here |

Inside Keycloak, the realm `inventory` holds the user `alice` (password `alice-password`) and the public client `inventory-cli`, which can use the password grant so you can get tokens from a terminal. The administrator of the `master` realm is `admin` with the password `admin`; these are lab-only credentials.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
