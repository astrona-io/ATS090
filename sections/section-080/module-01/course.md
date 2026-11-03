# Shape Tokens With Client Scopes And Protocol Mappers

An API reads claims from a token to decide what a caller may do. A claim is only in the token if Keycloak put it there, and Keycloak puts it there because of a setting you made. When the API says "no `groups` claim", or when a token carries a role the client should never see, the fix is in the way the client's tokens are built.

Two Keycloak objects build every token. A **protocol mapper** writes one claim into a token, for example the groups of the user. A **client scope** is a named bundle of protocol mappers and role scope mappings that clients share. A client gets the mappers of its **dedicated scope**, a scope that exists only for that client, and the mappers of the client scopes assigned to it.

Keep one sentence in mind: **a claim reaches a token only if a mapper writes it, the mapper's token switches allow it, and the client uses the scope that holds the mapper.** Each of the three has its own failure.

The module has four parts. **Client Scopes: Default And Optional** shows how a client gets its scopes and how the `scope` parameter changes a token. **Protocol Mappers And Custom Claims** adds claims for groups, a user property and a fixed value. **Roles In Tokens: Full Scope And Scope Mappings** limits which roles reach a token. **Which Token Carries What** compares the access token, the ID token, the UserInfo endpoint and introspection. A graded lab follows the second part.

## Learning objectives

After this module you can:

- Tell a default client scope from an optional one, and request an optional scope with the `scope` parameter.
- Create a client scope with a protocol mapper and assign it to a client.
- Add a group claim, a user property claim and a hardcoded claim to a token.
- Control whether a claim goes into the access token, the ID token, the UserInfo response or introspection.
- Limit the roles in a token with Full Scope Allowed and scope mappings.
- Decide which token an application or an API should read a claim from.

## Before you start

You need Kubernetes basics, `curl` and `jq`, and you should know what a realm, a user, a client and an access token are. You will decode JSON Web Tokens (JWT): tokens made of three Base64URL parts, a header, a payload with claims, and a signature, separated by dots.

Your playground is a single-node `kind` cluster with **Keycloak 26.8.1** in development mode. The namespace **`scopes-demo`** runs these workloads:

| Workload | What it is |
| --- | --- |
| `keycloak` | One Keycloak pod, behind the Service `keycloak` on port `8080` |
| `tester` | A client pod with `curl` and `jq`. Every request is sent from here |

Inside Keycloak, the realm `inventory` holds the user `alice` (password `alice-password`), who has the realm roles `inventory-reader` and `inventory-admin` and is a member of the group `logistics`. The public client `inventory-cli` can use the password grant, so you can get tokens from a terminal. The administrator of the `master` realm is `admin` with the password `admin`; these are lab-only credentials. OAuth 2.1 drops the password grant, and a real application uses the authorization code flow; here it only saves you a browser.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
