# Section 050: Client Credentials And Service Accounts

Not every client acts for a person. A reporting job, a synchronisation task and a gateway call APIs on their own behalf, and they have no browser and no password. Keycloak gives each of them a token for the client itself, and the roles in that token come from a service account user.

This section follows a service client from its first token request to a rotated secret. You request tokens, read what is in them, repair a client that cannot authenticate and replace a leaked secret.

**Topic covered:** Service clients

## What you will learn

- How the client credentials grant works, and what its response contains and leaves out.
- What a service account is, where its roles come from, and why a token keeps the roles it had when it was issued.
- The four client authentication methods and what each one sends and stores.
- How to regenerate a client secret, what happens to the old one, and why a client should cache its token.

## The learning path

The section has one module. It has a landing page, 4 short parts, a graded lab right after the part it tests, and a summary. The module has its own playground, and the landing page starts it for you.

### 1. Authenticate Service Clients With Client Credentials

The playground holds the namespace `m2m-demo` with Keycloak, the realm `inventory`, the role `inventory-reader` and the service clients `inventory-reporter` and `inventory-sync`.

1. The Client Credentials Grant
2. Service Accounts And Their Roles, followed by the lab **Repair A Service Client**
3. Client Authentication Methods
4. Rotating Secrets And Calling APIs
5. Summary

## Section capstone: Secure The Service Clients Of A Realm

The capstone is one graded scenario that brings the module together. A reporting client is refused although its secret is right, its secret was leaked, and a synchronisation client was created as a public client. Each problem has its own fix, and none of them gives an administration role to a service account. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS090.git -c sections/section-050/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-050/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-090-capstone-050
```
