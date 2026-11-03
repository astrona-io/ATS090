# Section 140: Securing Applications With Libraries, Proxies And Gateways

Keycloak no longer ships adapters. You secure an application with a standard OpenID Connect library, a reverse proxy or a gateway, and Keycloak supplies the endpoints, the keys and the claims.

This section covers choosing an option, client configuration for a proxy, token validation in an API, and headers, issuer and logout. You check each setting by decoding real tokens.

**Topic covered:** securing applications

## What you will learn

- How a library, a proxy and a gateway differ.
- How to configure a confidential client with an exact redirect address, an audience and a groups claim.
- Which checks a resource server must make on a token.
- How identity headers, the issuer and logout behave behind a proxy.

## The learning path

The section has one module. It has a landing page, 4 short parts, a graded lab right after the part it tests, and a summary. The module has its own playground, and the landing page starts it for you.

### 1. Securing Applications With Libraries, Proxies And Gateways

The playground holds the namespace `proxy-demo` with Keycloak, the realm `inventory`, the user `alice` in the group `staff` and the confidential client `web-proxy` with an audience mapper and a groups mapper. You read tokens with `curl` and `jq` and change the client with `kcadm.sh`.

1. Choosing How To Secure An Application
2. Client Configuration For A Proxy
3. Validating Tokens In A Resource Server, followed by the lab **Make Tokens Acceptable To A Proxy**
4. Gateways, Headers And Logout
5. Summary

## Section capstone: Protect An Orders API

The capstone is one graded scenario that brings the module together. A gateway client has a wildcard redirect address, a one hour token lifetime, a misspelled audience and a misnamed groups claim. Fix all four and read the tokens. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS090.git -c sections/section-140/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-140/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-090-capstone-140
```
