# Section 110: Client Registration And Client Policies

Some systems need to create clients on their own: a partner portal, a developer platform or a deployment tool. Keycloak supports this with dynamic client registration, and keeps control with client policies.

This section covers registration endpoints and initial access tokens, registration policies, client profiles and policies, and the management of registered clients. You check each rule by creating test clients and reading the result.

**Topic covered:** client registration

## What you will learn

- How the registration endpoints and initial access tokens work.
- What the registration policies check on requests.
- How profiles, executors, conditions and policies combine.
- How to manage and review dynamically registered clients.

## The learning path

The section has one module. It has a landing page, 4 short parts, a graded lab right after the part it tests, and a summary. The module has its own playground, and the landing page starts it for you.

### 1. Client Registration And Client Policies

The playground holds the namespace `reg-demo` with Keycloak, the realm `inventory`, the client profile `strict-public` and the enabled client policy `public-clients`. You register clients with an initial access token and change profiles and policies with `kcadm.sh`.

1. Registration Methods And Initial Access Tokens
2. Client Registration Policies
3. Client Profiles And Policies, followed by the lab **Enforce PKCE With A Client Policy**
4. Managing Registered Clients
5. Summary

## Section capstone: Lock Down Partner Registration

The capstone is one graded scenario that brings the module together. A partner policy names no profile and its profile lacks a password-grant rule. Fix both and test through the admin API and dynamic registration. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS090.git -c sections/section-110/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-110/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-090-capstone-110
```
