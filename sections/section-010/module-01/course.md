# Configure Clients For Applications And Services

A browser application, a command-line tool and a background service all ask Keycloak for tokens, but they do not ask the same way. The browser application cannot keep a secret, because anyone can read its code. The background service can. Keycloak needs to know which is which, or it either refuses the application that is set up right or trusts the one that is not.

A **client** is an application or service that asks Keycloak to sign users in or to issue tokens. Each client is registered in a realm, a space in Keycloak with its own users, clients and settings. The client's settings decide which ways of getting a token, called grants or flows, it may use, how it proves who it is, and where Keycloak may send its users.

This module is about those settings. Keep one sentence in mind: **a client setting is a promise about who can use the client, and Keycloak keeps exactly the promise you wrote.** A wildcard redirect URI promises that any website may receive a user's authorization code, and Keycloak keeps that promise too.

The module has three parts. **Public Clients, Confidential Clients And Client Authentication** shows the two client types and how a confidential client proves who it is at the token endpoint. **Valid Redirect URIs And The Front Channel** shows where Keycloak sends the authorization code and why it compares the address exactly. **Web Origins And CORS** shows which websites may read Keycloak's answers in a browser. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Say whether an application needs a public or a confidential client, and why.
- Describe client authentication with a client secret (`client_secret_basic` and `client_secret_post`) and with a signed JWT.
- Read and change a client's settings with `kcadm.sh`.
- Explain the front channel and the back channel of a browser sign-in.
- Explain how Keycloak matches a redirect URI, and why `*` is dangerous.
- Explain what a web origin is, what `+` means, and what CORS protects.
- Prove a client's settings with a real sign-in, and with a redirect URI and an origin that Keycloak refuses.

## Before you start

You need Kubernetes basics (namespaces, Deployments, Services, `kubectl exec`) and `curl`. You should know what a realm, a user and a client are in Keycloak, and you should have requested a token from a realm's token endpoint before.

Your playground is a single-node `kind` cluster with **Keycloak 26.8.1** in development mode. The namespace **`clients-demo`** runs these workloads:

| Workload | What it is |
| --- | --- |
| `keycloak` | One Keycloak pod, behind the Service `keycloak` on port `8080` |
| `tester` | A client pod with `curl`, `jq` and `openssl`. Every request in this module is sent from here |

Inside Keycloak, the realm `inventory` holds the user `alice` (password `alice-password`) and three clients:

| Client | What it stands for |
| --- | --- |
| `inventory-cli` | A command-line tool on a laptop |
| `inventory-reporter` | A background service with no user, client secret `inventory-reporter-secret` |
| `inventory-web` | A single page application served from `http://localhost:5173` |

No real browser application runs. `http://localhost:5173` is the address a local development server would use, and every page stops at the moment Keycloak sends the browser there. The administrator of the `master` realm is `admin` with the password `admin`; these are lab-only credentials.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
