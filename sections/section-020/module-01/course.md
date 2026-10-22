# Sign Users In With The Authorization Code Flow And PKCE

A single page application asks Keycloak to sign a user in. The browser goes to Keycloak, the user types a password, and the browser comes back to the application with a code. The application posts the code to Keycloak and gets tokens. Anyone who gets hold of that code in between, and knows the client ID, can do the same, because a public client has no secret to prove it is the real application.

The **authorization code flow** is the browser sign-in of OAuth 2.0 and OpenID Connect (OIDC). The **authorization code** is a short-lived, one-time value that Keycloak gives to the browser, and that the application exchanges for tokens. **Proof Key for Code Exchange (PKCE)** ties that code to the application that started the flow, so that a stolen code is useless.

This module runs the flow by hand. Keep one sentence in mind: **every value the application sends at the start comes back at a later step, and that is where it is checked.** The redirect URI comes back with the code, the code challenge comes back as the code verifier, and the nonce comes back inside the ID token.

The module has three parts. **The Authorization Code Flow Step By Step** sends each request of the flow from a terminal and reads Keycloak's answer. **Proof Key For Code Exchange (PKCE)** adds the code verifier and the code challenge, and makes Keycloak require them. **State, Nonce And The ID Token** shows the two values that protect the client against forged answers and replayed tokens. A graded lab follows the second part.

## Learning objectives

After this module you can:

- Name each request of the authorization code flow and say whether it passes through the browser.
- Send the authorization request, post the login form, read the code and exchange it, with `curl`.
- Explain why a code works only once and only for a short time.
- Create a code verifier and an `S256` code challenge, and explain why `plain` is weaker.
- Make Keycloak require PKCE with `S256` for a client, and prove it refuses requests without it.
- Explain what `state` and `nonce` protect against, and check the nonce in an ID token.

## Before you start

You need Kubernetes basics, `curl`, and an idea of what a public client is and what a redirect URI is. A public client is a client that cannot keep a secret, such as an application in a browser. A redirect URI is the address Keycloak sends the browser back to; Keycloak only uses one the client lists as valid.

Your playground is a single-node `kind` cluster with **Keycloak 26.8.1** in development mode. The namespace **`pkce-demo`** runs these workloads:

| Workload | What it is |
| --- | --- |
| `keycloak` | One Keycloak pod, behind the Service `keycloak` on port `8080` |
| `tester` | A client pod with `curl`, `jq` and `openssl`. You run every step of the flow from a shell in this pod |

Inside Keycloak, the realm `inventory` holds the user `alice` (password `alice-password`) and the public client `inventory-web`, with the standard flow on, the valid redirect URI `http://localhost:5173/callback` and the web origin `+`. No real application runs at `http://localhost:5173`: the flow stops when Keycloak redirects there, and you read the code from the redirect. The administrator of the `master` realm is `admin` with the password `admin`; these are lab-only credentials.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
