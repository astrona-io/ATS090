# Section 030: Validating Access Tokens In An API

An access token is only as safe as the checks the API runs on it. An API that accepts any well-formed JSON Web Token (JWT) accepts a forged one; an API that skips the audience check accepts a token meant for another service. Keycloak issues the token, but the API decides whether to trust it, and Keycloak's settings decide whether a token can pass the API's checks at all.

This section looks at a token from the API's side. You call a small API, read in its log why it refuses a token, and fix Keycloak until the token passes every check for the right reasons.

**Topic covered:** Token validation

## What you will learn

- The checks an API runs on an access token, and the order that makes sense: signature, issuer, audience, expiry, type, then roles.
- How an API gets the realm's public keys from the JSON Web Key Set (JWKS), and how it follows a key rotation by the key ID (`kid`).
- What the audience (`aud`) of a token is for, and how an audience mapper puts the right audience in a token.
- What a client scope is, and why a client scope keeps an audience limited to the clients that need it.
- How realm roles get into a token, and why a missing role gives `403` and not `401`.
- When an API should ask Keycloak with token introspection instead of checking the token itself.

## The learning path

The section has one module. It has a landing page, four short parts, a graded lab right after the part it tests, and a summary. The module has its own playground, and the landing page starts it for you.

### 1. Validate Access Tokens In An API

The playground holds the namespace `tokens-demo` with Keycloak, the realm `inventory`, the user `alice`, and `inventory-api`, an API that checks every token and logs why it refuses one. At the start, it refuses all of `alice`'s tokens.

1. What An API Checks In An Access Token
2. Signatures, The JWKS And Key Rotation
3. Audience, Audience Mappers And Client Scopes, followed by the lab **Add The API Audience With A Client Scope**
4. Roles In Tokens And Token Introspection
5. Summary

## Section capstone: Make An API Accept The Right Tokens

The capstone is one graded scenario that brings the module together. `inventory-api` refuses every token `alice` gets, for three separate reasons, and each fix uncovers the next one. The API itself is correct and must not change. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS090.git -c sections/section-030/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-090-capstone-030
```
