# Validate Access Tokens In An API

`alice` signs in, her client gets an access token, and the client sends it to `inventory-api` in the `Authorization: Bearer` header. The API answers `401`. The token has a valid signature from the right realm, it has not expired, and `alice` is a real user. The API still refuses it, and the API is right to.

An **access token** is a token a client sends to an API to show what it may do. A **resource server** is an API that accepts access tokens. The resource server never asks Keycloak whether a token is good; it checks the token itself, with the realm's public keys and a short list of rules. When one rule fails, the API refuses, and the fix is almost always in Keycloak, not in the API.

This module is about those rules. Keep one sentence in mind: **a valid signature proves who issued a token, not who it is for.** Every token of the realm has a valid signature. The audience and the roles in the token decide whether this API should accept it.

The module has four parts. **What An API Checks In An Access Token** walks through the API's checks and reads its log. **Signatures, The JWKS And Key Rotation** shows how the API gets Keycloak's public keys and keeps working when they change. **Audience, Audience Mappers And Client Scopes** puts the right audience in the token. **Roles In Tokens And Token Introspection** covers the role check and the case where the API asks Keycloak instead. A graded lab follows the third part.

## Learning objectives

After this module you can:

- List the checks an API runs on an access token and say what each one protects against.
- Decode a token and compare its claims with what an API expects.
- Read the realm's JWKS, match a token's `kid`, and explain what happens when the realm's keys rotate.
- Add an audience to a client's tokens with an audience mapper, on the client or in a client scope.
- Explain why an audience belongs only to the clients that call the API.
- Explain how realm roles reach a token, and the difference between `401` and `403`.
- Introspect a token, and explain when introspection gives a different answer than local validation.

## Before you start

You need Kubernetes basics, `curl` and `jq`, and you should know what a realm, a user, a client and an access token are. You will decode JSON Web Tokens (JWT): tokens made of three Base64URL parts, a header, a payload with claims, and a signature, separated by dots.

Your playground is a single-node `kind` cluster with **Keycloak 26.8.1** in development mode. The namespace **`tokens-demo`** runs these workloads:

| Workload | What it is |
| --- | --- |
| `keycloak` | One Keycloak pod, behind the Service `keycloak` on port `8080` |
| `inventory-api` | The API, on port `8080`. `GET /items` needs a valid access token from the realm `inventory` with `inventory-api` in `aud` and the realm role `inventory-reader`. It logs one line per request, with the reason when it refuses |
| `tester` | A client pod with `curl` and `jq`. Every request is sent from here |

Inside Keycloak, the realm `inventory` holds the user `alice` (password `alice-password`, realm role `inventory-reader`) and three clients: `inventory-cli`, a public client used to get a token for `alice` from a terminal; `inventory-reporter`, a confidential service client with the secret `inventory-reporter-secret`; and `inventory-api`, a client that stands for the API so it can be named as an audience. The administrator of the `master` realm is `admin` with the password `admin`; these are lab-only credentials.

To get a token for `alice` from a terminal, the pages use the password grant of `inventory-cli`. OAuth 2.1 drops that grant, and a real application uses the authorization code flow; here it only saves you a browser.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
