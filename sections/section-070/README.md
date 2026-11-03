# Section 070: Logout, Back-Channel Logout And Session Control

Signing out is not one action. A session ends by logout, by time or by an administrator, applications learn about it only if Keycloak tells them, and access tokens that were already issued stay valid until they expire.

This section covers the ways a session ends, the logout endpoint with safe redirects, back-channel and front-channel logout, and the admin tools for sessions. You check each change by reading the client and the session list.

**Topic covered:** Logout and session control

## What you will learn

- Which events end a session and what each leaves behind.
- How to log out from a back end and from a browser, and how to register post-logout redirect URIs safely.
- How back-channel logout works and what the logout token carries.
- How to list and end sessions for a user or a realm and how to set the session limits.

## The learning path

The section has one module. It has a landing page, 4 short parts, a graded lab right after the part it tests, and a summary. The module has its own playground, and the landing page starts it for you.

### 1. End Sessions With Logout And Admin Control

The playground holds the namespace `logout-demo` with Keycloak, the realm `inventory`, the user `alice` and the public client `inventory-cli`, which can sign in with the password grant so you can create sessions from a terminal.

1. How Keycloak Sessions End
2. RP-Initiated Logout And Post-Logout Redirects
3. Back-Channel And Front-Channel Logout
4. Administering Sessions, followed by the lab **Sign Out A User Everywhere**
5. Summary

## Section capstone: Repair The Logout Of A Client

The capstone is one graded scenario that brings the module together. A client accepts any logout redirect, has no back-channel URL and no session id in the logout token, and a user is signed in twice. Four fixes, each checked in Keycloak. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS090.git -c sections/section-070/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-070/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-090-capstone-070
```
