# Securing Applications With Libraries, Proxies And Gateways

Older Keycloak versions shipped adapters for many languages. Current Keycloak does not. You secure an application with **standard OpenID Connect** parts: a certified client library, a reverse proxy in front of the application, or a gateway that validates tokens for many services. Keycloak is then only the identity provider, and the quality of the setup depends on the client settings and on how the application checks tokens.

Keep one sentence in mind: **the application, proxy or gateway must prove who signed the token, who issued it, who it is for and when it expires, and Keycloak must put the right claims in the token for that check to pass.** Most failures are a missing audience, a wrong issuer, a misnamed claim or a wide redirect address.

The module has four parts. **Choosing How To Secure An Application** compares the options. **Client Configuration For A Proxy** sets up the client and the claims a proxy needs. **Validating Tokens In A Resource Server** covers the checks an API must make. **Gateways, Headers And Logout** covers identity headers, issuer behind a proxy and logout. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Choose between a library, a proxy and a gateway for an application.
- Configure a confidential client for a proxy with an exact redirect address, an audience and a groups claim.
- List the checks a resource server makes on an access token.
- Explain how the issuer and the public hostname relate behind a reverse proxy.
- Find why a proxy or an API rejects a token that Keycloak issued.

## Before you start

You need Kubernetes basics, `curl` and `jq`, and you should know what a token, a claim, a client and a group are.

Your playground is a single-node `kind` cluster with **Keycloak 26.8.1** in development mode. The namespace **`proxy-demo`** runs these workloads:

| Workload | What it is |
| --- | --- |
| `keycloak` | One Keycloak pod, behind the Service `keycloak` on port `8080` |
| `tester` | A client pod with `curl` and `jq`. Every request is sent from here |

Inside Keycloak, the realm `inventory` holds the user `alice` with the password `alice-password`, who is a member of the group `staff`, and the confidential client `web-proxy` with the secret `web-proxy-secret`. For the exercises, the client allows the password grant so that you can get tokens from a terminal; a real proxy uses the authorization code flow. The administrator of the `master` realm is `admin` with the password `admin`; these are lab-only credentials.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
