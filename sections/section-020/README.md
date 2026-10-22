# Section 020: The Authorization Code Flow With PKCE

Most users sign in to an application through a browser, and the standard way to do that with Keycloak is the authorization code flow. It looks like one click to the user, but it is a series of requests and redirects, and each one carries a value that protects the next. When a sign-in fails, or when it works for the wrong party, the cause is in one of those steps.

This section takes the flow apart. You run every step by hand from a terminal, so that you can see what each request sends and what Keycloak answers, and then you add the protections a public client needs.

**Topic covered:** Browser sign-in

## What you will learn

- Every request of the authorization code flow, and which of them pass through the browser.
- Why the authorization code is short-lived and works only once.
- Proof Key for Code Exchange (PKCE): the code verifier, the code challenge, and the methods `S256` and `plain`.
- How to make Keycloak require PKCE with `S256` for a client.
- What the `state` and `nonce` values protect against, and where each one comes back.
- Which claims of the ID token a client checks.

## The learning path

The section has one module. It has a landing page, three short parts, a graded lab right after the part it tests, and a summary. The module has its own playground, and the landing page starts it for you.

### 1. Sign Users In With The Authorization Code Flow And PKCE

The playground holds the namespace `pkce-demo` with Keycloak, the realm `inventory`, the user `alice` and the public client `inventory-web`.

1. The Authorization Code Flow Step By Step
2. Proof Key For Code Exchange (PKCE), followed by the lab **Require PKCE With S256 For A Public Client**
3. State, Nonce And The ID Token
4. Summary

## Section capstone: Repair The Login Of A Single Page Application

The capstone is one graded scenario that brings the module together. The single page application `inventory-web` cannot sign anyone in, and it fails at a different step for each of four reasons. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS090.git -c sections/section-020/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-090-capstone-020
```
