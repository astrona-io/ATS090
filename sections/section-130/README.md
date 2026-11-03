# Section 130: Sender-Constrained Tokens: DPoP And Mutual TLS

A bearer token works for whoever holds it. Sender-constrained tokens are bound to a key, so a leaked token alone is not enough to use it.

This section covers the weakness of bearer tokens, DPoP in Keycloak, mutual TLS and certificate-bound tokens, and how to choose and roll out. You check the DPoP settings by requesting tokens without a proof.

**Topic covered:** sender-constrained tokens

## What you will learn

- Why bearer tokens are a risk and what the cnf claim does.
- How a DPoP proof is built and how Keycloak requires it.
- What certificate-bound tokens need on the server and at a proxy.
- How to choose between DPoP and mutual TLS and roll out safely.

## The learning path

The section has one module. It has a landing page, 4 short parts, a graded lab right after the part it tests, and a summary. The module has its own playground, and the landing page starts it for you.

### 1. Sender-Constrained Tokens: DPoP And Mutual TLS

The playground holds the namespace `bound-demo` with Keycloak, the realm `inventory`, the client `payments-client` that requires DPoP and the client `legacy-client` that does not. You request tokens without a proof and change client attributes with `kcadm.sh`.

1. Bearer Tokens And Their Weakness
2. DPoP In Keycloak, followed by the lab **Require DPoP Binding**
3. Mutual TLS And Certificate-Bound Tokens
4. Choosing And Rolling Out
5. Summary

## Section capstone: Bind Tokens For Payments

The capstone is one graded scenario that brings the module together. A payments client does not require DPoP and its tokens live an hour, and a partner client requires DPoP although it cannot send proofs. Fix all three and test with token requests. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS090.git -c sections/section-130/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-130/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-090-capstone-130
```
