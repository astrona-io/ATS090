# Authorization Services: Resources, Policies And Permissions

Roles answer a coarse question: is this user a finance user? An API often needs a finer one: may this user **delete** this **report**? Keycloak Authorization Services moves such decisions out of application code. The application registers its resources and scopes in Keycloak, administrators define policies and permissions, and Keycloak answers permission requests.

Keep one sentence in mind: **a permission connects a resource, or a scope of it, to one or more policies, and a policy decides yes or no for the user who asks.** A request is denied when no permission covers it or when its policies say no.

The module has four parts. **Resource Servers, Resources And Scopes** enables the feature and models what is protected. **Policies And Permissions** decides who may do what. **Requesting And Evaluating Permissions** asks Keycloak for a decision with the UMA grant. **Decision Strategies And Enforcement** covers logic, strategies and modes. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Enable Authorization Services on a client and name its parts.
- Create resources, scopes, role policies and permissions with the admin API.
- Ask Keycloak for a permission decision with the UMA ticket grant.
- Explain positive and negative logic, decision strategies and enforcement modes.
- Find why a permission request is denied.

## Before you start

You need Kubernetes basics, `curl` and `jq`, and you should know what a realm, a user, a role and a client are.

Your playground is a single-node `kind` cluster with **Keycloak 26.8.1** in development mode. The namespace **`authz-demo`** runs these workloads:

| Workload | What it is |
| --- | --- |
| `keycloak` | One Keycloak pod, behind the Service `keycloak` on port `8080` |
| `tester` | A client pod with `curl` and `jq`. Every request is sent from here |

Inside Keycloak, the realm `inventory` holds the users `alice` (role `finance`) and `bob` (no role), both with the password `<name>-password`, the public client `inventory-cli` for password-grant sign-in, and the client `invoice-api` with Authorization Services enabled. The administrator of the `master` realm is `admin` with the password `admin`; these are lab-only credentials.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
