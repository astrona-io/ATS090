# Sender-Constrained Tokens: DPoP And Mutual TLS

A normal access token is a **bearer token**: whoever holds it can use it. If a token leaks from a log, a proxy or a stolen device, the thief has the same rights as the user until it expires. **Sender-constrained tokens** close that gap. The token is bound to a key that only the real client holds, so a copy of the token alone is useless.

Keep one sentence in mind: **a sender-constrained token carries a fingerprint of the client's key, and the resource server accepts it only together with a proof that the caller holds that key.** Keycloak supports two ways to do this: **DPoP** at the application layer and **mutual TLS** at the transport layer.

The module has four parts. **Bearer Tokens And Their Weakness** explains the problem and the idea of binding. **DPoP In Keycloak** covers the proof, the token and the client setting. **Mutual TLS And Certificate-Bound Tokens** covers the transport layer approach. **Choosing And Rolling Out** compares the two and gives a rollout plan. A graded lab follows the second part.

## Learning objectives

After this module you can:

- Explain why a bearer token is a risk and how a bound token reduces it.
- Describe a DPoP proof and the `cnf` claim of a bound token.
- Require DPoP-bound tokens on a client and find a client that rejects plain requests.
- Describe certificate-bound access tokens and what the server needs to issue them.
- Choose between DPoP and mutual TLS for a client.

## Before you start

You need Kubernetes basics, `curl` and `jq`, and you should know what an access token, a client and a client secret are.

Your playground is a single-node `kind` cluster with **Keycloak 26.8.1** in development mode. The namespace **`bound-demo`** runs these workloads:

| Workload | What it is |
| --- | --- |
| `keycloak` | One Keycloak pod, behind the Service `keycloak` on port `8080` |
| `tester` | A client pod with `curl`, `jq` and `openssl`. Every request is sent from here |

Inside Keycloak, the realm `inventory` holds two confidential clients with service accounts: `payments-client` with the secret `payments-secret`, which requires DPoP-bound tokens, and `legacy-client` with the secret `legacy-secret`, which does not. The administrator of the `master` realm is `admin` with the password `admin`; these are lab-only credentials.

The playground uses plain HTTP, so mutual TLS cannot run in it. That part is read-only and shows the settings.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
