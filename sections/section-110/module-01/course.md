# Client Registration And Client Policies

Most clients are created by an administrator. Some are not: a partner portal, a developer platform or a tool that deploys many applications may need to create clients by itself. Keycloak supports this with **dynamic client registration**, and it lets you limit what registered clients may look like with **client policies**.

Keep one sentence in mind: **registration decides who may create a client, and client policies decide what a client is allowed to look like, no matter who created it.** Without limits, a registration endpoint is a way for anyone with a token to create a client with any redirect address.

The module has four parts. **Registration Methods And Initial Access Tokens** covers the endpoints and the tokens that open them. **Client Registration Policies** covers the realm checks that run on registration requests. **Client Profiles And Policies** covers executors and conditions that apply to every client change. **Managing Registered Clients** covers the registration access token and cleanup. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Name the ways to create a client and say who each one is meant for.
- Create an initial access token and register a client with it.
- Explain what the registration policies for anonymous and authenticated requests check.
- Write a client profile with executors and a client policy with conditions.
- Find why a registration request is rejected.

## Before you start

You need Kubernetes basics, `curl` and `jq`, and you should know what a realm and a client are.

Your playground is a single-node `kind` cluster with **Keycloak 26.8.1** in development mode. The namespace **`reg-demo`** runs these workloads:

| Workload | What it is |
| --- | --- |
| `keycloak` | One Keycloak pod, behind the Service `keycloak` on port `8080` |
| `tester` | A client pod with `curl` and `jq`. Every request is sent from here |

Inside Keycloak, the realm `inventory` is empty except for the built-in objects, and has one client profile `strict-public` and one client policy `public-clients` defined in the playground. The administrator of the `master` realm is `admin` with the password `admin`; these are lab-only credentials.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
