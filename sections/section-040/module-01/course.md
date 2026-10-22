# Propagate Tokens Through An API Gateway

`alice`'s command-line tool sends her access token to `inventory-gateway`, and the gateway forwards the request to `inventory-api`. The gateway accepts the token, because its audience names the gateway. The API refuses the same token, because its audience does not name the API. Both services are right, and the request still fails.

An **API gateway** is a service in front of one or more APIs that receives every client request and forwards it to the right API. **Token propagation** is how the user's identity travels with the request from one service to the next. Keycloak supports **standard token exchange**, defined in RFC 8693: a service sends the token it received and gets a new token, for the same user, meant for the next service.

This module is about that hand-over. Keep one sentence in mind: **each service should receive a token meant for it, and only for it.** A token whose audience lists every service works everywhere, so a service that leaks it leaks access to all of them.

The module has three parts. **Forwarding The Token Through A Gateway** sends a token through the gateway and shows why it fails, and why widening its audience is the wrong fix. **Standard Token Exchange** lets the gateway exchange the token for one meant for the API. **Downscoping And A Second API** shows how the gateway asks for exactly one audience when it may call several APIs. A graded lab follows the second part.

## Learning objectives

After this module you can:

- Explain what happens to a bearer token when a gateway forwards a request.
- Explain why adding every API to a client's audience is the wrong fix.
- Allow standard token exchange for a confidential client in Keycloak 26.
- Send a token exchange request and read the new token's `sub`, `azp` and `aud`.
- State the two audience rules of token exchange.
- Ask for a token limited to one audience, and recognise the error for an audience that is not available.

## Before you start

You need Kubernetes basics, `curl` and `jq`, and you should know how an API checks an access token: its signature, `iss`, `aud`, `exp` and roles. `aud`, the audience, lists who a token is for, and an API accepts a token only when its own name is in that list. An audience mapper is a Keycloak setting that adds a client to the audience of a client's tokens.

Your playground is a single-node `kind` cluster with **Keycloak 26.8.1** in development mode. The namespace **`exchange-demo`** runs these workloads:

| Workload | What it is |
| --- | --- |
| `keycloak` | One Keycloak pod, behind the Service `keycloak` on port `8080` |
| `inventory-gateway` | An nginx reverse proxy on port `8080` that forwards every request, with its `Authorization` header unchanged, to `inventory-api` |
| `inventory-api` | The API on port `8080`. `GET /items` needs a token from the realm `inventory` with `inventory-api` in `aud` and the realm role `inventory-reader`; it logs the reason for each refusal |
| `tester` | A client pod with `curl` and `jq`. Every request is sent from here |

Inside Keycloak, the realm `inventory` holds the user `alice` (password `alice-password`, realm role `inventory-reader`) and three clients. `inventory-cli` is the public client of the command-line tool; an audience mapper puts `inventory-gateway` into its tokens. `inventory-gateway` is the confidential client of the gateway, with the secret `inventory-gateway-secret`. `inventory-api` stands for the API so it can be named as an audience. The administrator of the `master` realm is `admin` with the password `admin`; these are lab-only credentials.

To get a token for `alice` from a terminal, the pages use the password grant of `inventory-cli`. OAuth 2.1 drops that grant, and a real application uses the authorization code flow; here it only saves you a browser.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
