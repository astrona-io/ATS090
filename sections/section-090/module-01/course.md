# Keycloak As A SAML Identity Provider

Many business applications do not speak OpenID Connect. They speak **SAML 2.0** (Security Assertion Markup Language), a standard from before OAuth that moves a signed XML document, the **assertion**, from the identity provider to the application. Keycloak can play the identity provider (IdP) for SAML applications, which are called **service providers** (SP).

Keep one sentence in mind: **a SAML sign-in works only if both sides agree on who the service provider is, where the assertion goes, how it is signed and which attributes it carries.** Each of the four is a setting in Keycloak, and each fails in its own way.

The module has four parts. **SAML Basics And The Keycloak Descriptor** shows the flow and the IdP metadata. **SAML Clients And Name IDs** creates a SAML client and chooses the name ID. **Signatures And Encryption** covers which documents are signed. **Attributes, Roles And Single Logout** covers mappers and logout. A graded lab follows the second part.

## Learning objectives

After this module you can:

- Describe the SAML browser SSO flow and its HTTP bindings.
- Read the Keycloak IdP descriptor and give it to a service provider.
- Create a SAML client with the right entity ID, assertion consumer address and name ID format.
- Decide which of the response, the assertion and the request are signed or encrypted.
- Add attribute and role mappers and configure single logout.

## Before you start

You need Kubernetes basics, `curl` and `jq`, and you should know what a realm, a user and a client are. You do not need a SAML application: you read what Keycloak publishes and what a client stores.

Your playground is a single-node `kind` cluster with **Keycloak 26.8.1** in development mode. The namespace **`saml-demo`** runs these workloads:

| Workload | What it is |
| --- | --- |
| `keycloak` | One Keycloak pod, behind the Service `keycloak` on port `8080` |
| `tester` | A client pod with `curl` and `jq`. Every request is sent from here |

Inside Keycloak, the realm `inventory` holds the user `alice` (password `alice-password`) with the realm role `billing-user`, and the SAML client `urn:app:billing`. The administrator of the `master` realm is `admin` with the password `admin`; these are lab-only credentials.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
