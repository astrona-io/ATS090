# Section 060: Token Lifetimes, Refresh Tokens And Sessions

A token is valid until it expires, and a stolen token is usable for exactly that long. Keycloak sets the lifetime of tokens and sessions in several places, and the right value depends on who holds the token: a browser, a mobile application or a background job.

This section reads each lifetime setting, refreshes tokens, makes refresh tokens single-use, requests an offline token and ends sessions. You check every setting by decoding a real token.

**Topic covered:** Token lifetimes and sessions

## What you will learn

- Which realm settings set the access token, SSO session and offline session lifetimes, and how a client overrides the access token lifespan.
- How the refresh token grant works and what refresh token rotation does when a token is used twice.
- What an offline token is, the two conditions for getting one and the setting that limits it.
- How to revoke a token, log a user out and end sessions, and why an API that validates locally still accepts an issued access token.

## The learning path

The section has one module. It has a landing page, 4 short parts, a graded lab right after the part it tests, and a summary. The module has its own playground, and the landing page starts it for you.

### 1. Control Token Lifetimes, Refresh Tokens And Sessions

The playground holds the namespace `sessions-demo` with Keycloak, the realm `inventory`, the user `alice` and the public client `inventory-cli`, which can sign in with the password grant so you can get tokens from a terminal.

1. Token And Session Lifespans
2. The Refresh Token Grant And Rotation, followed by the lab **Shorten Access Tokens And Rotate Refresh Tokens**
3. Offline Tokens
4. Ending Sessions And Revoking Tokens
5. Summary

## Section capstone: Fix The Token Lifetimes Of A Client

The capstone is one graded scenario that brings the module together. A client keeps day-long access tokens through a hidden override, refresh tokens can be reused, the offline scope is gone and offline sessions last one minute. Four separate fixes, each checked with a real request. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS090.git -c sections/section-060/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-060/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-090-capstone-060
```
