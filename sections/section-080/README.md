# Section 080: Client Scopes, Protocol Mappers And Token Claims

An API trusts a token only for what is inside it. Every claim in a token comes from a protocol mapper, and every role comes from a scope rule. When a claim is missing or a role is too much, the fix is in how the client's tokens are built.

This section assigns client scopes as default or optional, adds mappers for groups, user properties and fixed values, limits roles with scope mappings, and compares the access token, the ID token, the UserInfo response and introspection. You check every change by decoding a real token.

**Topic covered:** Client scopes, mappers and token claims

## What you will learn

- How a client holds a client scope as default or optional and how the scope parameter switches an optional scope on.
- How to add protocol mappers for groups, user properties and fixed values, and which switches choose the tokens that receive the claim.
- How Full Scope Allowed and role scope mappings decide which roles reach a token.
- Which token an application and an API should read, and when to use UserInfo or introspection.

## The learning path

The section has one module. It has a landing page, 4 short parts, a graded lab right after the part it tests, and a summary. The module has its own playground, and the landing page starts it for you.

### 1. Shape Tokens With Client Scopes And Protocol Mappers

The playground holds the namespace `scopes-demo` with Keycloak, the realm `inventory`, the user `alice` in the group `logistics` with two roles, and the public client `inventory-cli`, which can sign in with the password grant so you can get tokens from a terminal.

1. Client Scopes: Default And Optional
2. Protocol Mappers And Custom Claims, followed by the lab **Add Group And Tenant Claims To A Client**
3. Roles In Tokens: Full Scope And Scope Mappings
4. Which Token Carries What
5. Summary

## Section capstone: Repair The Token Contents Of A Client

The capstone is one graded scenario that brings the module together. A groups mapper skips the access token, a reader client leaks the admin role and a needed scope is only optional. Three separate fixes, each checked in a real token. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS090.git -c sections/section-080/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-080/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-090-capstone-080
```
