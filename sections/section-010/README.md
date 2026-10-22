# Section 010: Clients, Redirect URIs And Web Origins

Every application that talks to Keycloak is registered in a realm as a **client**. The client's settings decide who may use it, how it proves who it is, where Keycloak may send a user's authorization code, and which websites may read Keycloak's answers. A wrong setting here does not break anything you can see. It quietly lets another application, or another website, get what was meant for yours.

This section comes first because every later topic depends on it. A browser sign-in only works with the right client type and redirect URI, and an API can only trust a token if the client that asked for it was the right one.

**Topic covered:** Clients

## What you will learn

- The difference between a public client and a confidential client, and which one each kind of application needs.
- How a confidential client authenticates at the token endpoint: a client secret sent two ways, or a signed JSON Web Token (JWT).
- What a valid redirect URI is, why Keycloak compares it exactly, and why a wildcard is dangerous.
- The front channel and the back channel of a browser sign-in.
- What web origins and Cross-Origin Resource Sharing (CORS) protect, and what the `+` value means.

## The learning path

The section has one module. It has a landing page, three short parts, a graded lab right after the part it tests, and a summary. The module has its own playground, a cluster where you can explore freely, and the landing page starts it for you.

### 1. Configure Clients For Applications And Services

The playground holds the namespace `clients-demo` with Keycloak, the realm `inventory`, the user `alice` and three clients: a command-line client, a service client and a browser client.

1. Public Clients, Confidential Clients And Client Authentication
2. Valid Redirect URIs And The Front Channel
3. Web Origins And CORS, followed by the lab **Lock Down The Redirect URIs And Web Origins Of A Browser Client**
4. Summary

## Section capstone: Secure The Clients Of A Realm

The capstone is one graded scenario that brings the module together. The realm `inventory` has a browser client that is far too open and a service client that cannot authenticate at all. Several faults are not visible until you try a sign-in or a token request. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS090.git -c sections/section-010/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-090-capstone-010
```
