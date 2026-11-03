# Authenticate Service Clients With Client Credentials

A nightly job needs to read the inventory from an API. No person signs in for it: there is no browser, no password and no user. The job still has to prove who it is, and the API still has to decide what it may do.

The **client credentials grant** is the OAuth 2.0 flow for this case. A **service client** is a confidential client that calls APIs on its own behalf. It sends its client ID and a credential to Keycloak's token endpoint and gets an access token for itself. Keycloak does not ask for a user, so the token describes the client and nothing else.

This module follows one service client, `inventory-reporter`, from its first token request to a rotated secret. Keep one sentence in mind: **with the client credentials grant, the client is the user.** Keycloak creates a hidden user for the client, called the service account, and every role the client has comes from that user.

The module has four parts. **The Client Credentials Grant** sends the token request and reads the response. **Service Accounts And Their Roles** shows where the roles in the token come from. **Client Authentication Methods** compares the ways a service client can prove its identity. **Rotating Secrets And Calling APIs** replaces a secret without breaking the job. A graded lab follows the second part.

## Learning objectives

After this module you can:

- Request an access token with the client credentials grant and explain what the response contains and what it leaves out.
- Turn on service accounts for a client, find its service account user and give it roles.
- Explain why a public client cannot use the client credentials grant.
- Name the client authentication methods Keycloak supports and choose between them.
- Regenerate a client secret and check that the old one stops working.
- Explain why a service client should cache its token until it nears expiry.

## Before you start

You need Kubernetes basics, `curl` and `jq`, and you should know what a realm, a client and an access token are. You will decode JSON Web Tokens (JWT): tokens made of three Base64URL parts, a header, a payload with claims, and a signature, separated by dots.

Your playground is a single-node `kind` cluster with **Keycloak 26.8.1** in development mode. The namespace **`m2m-demo`** runs these workloads:

| Workload | What it is |
| --- | --- |
| `keycloak` | One Keycloak pod, behind the Service `keycloak` on port `8080` |
| `tester` | A client pod with `curl` and `jq`. Every request is sent from here |

Inside Keycloak, the realm `inventory` holds the user `alice` (password `alice-password`) and the realm role `inventory-reader`. It also holds two confidential clients with service accounts: `inventory-reporter` (secret `inventory-reporter-secret`) and `inventory-sync` (secret `inventory-sync-secret`), and one public client, `inventory-cli`. The administrator of the `master` realm is `admin` with the password `admin`; these are lab-only credentials.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
