# Section 090: Keycloak As A SAML Identity Provider

Many business applications speak SAML 2.0 and not OpenID Connect. Keycloak can be their identity provider: it publishes a descriptor, keeps a client per service provider and issues signed XML assertions.

This section covers the SAML browser flow, SAML clients and name IDs, signatures and encryption, and attribute mappers with single logout. You check each setting by reading the client back.

**Topic covered:** SAML clients

## What you will learn

- How the SAML browser SSO flow and its bindings work.
- How to read the IdP descriptor and create a SAML client with the right entity ID and ACS address.
- Which documents Keycloak signs or encrypts and what each switch does.
- How to map attributes and roles and how single logout reaches other service providers.

## The learning path

The section has one module. It has a landing page, 4 short parts, a graded lab right after the part it tests, and a summary. The module has its own playground, and the landing page starts it for you.

### 1. Keycloak As A SAML Identity Provider

The playground holds the namespace `saml-demo` with Keycloak, the realm `inventory`, the user `alice` with the role `billing-user`, and the SAML client `urn:app:billing`. You read the descriptor and change the client with `kcadm.sh`.

1. SAML Basics And The Keycloak Descriptor
2. SAML Clients And Name IDs, followed by the lab **Fix A SAML Client**
3. Signatures And Encryption
4. Attributes, Roles And Single Logout
5. Summary

## Section capstone: Secure A SAML Service Provider

The capstone is one graded scenario that brings the module together. A SAML client accepts any ACS address, sends unsigned assertions, has no email attribute and writes the roles to the wrong attribute. Four fixes, each read back from Keycloak. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS090.git -c sections/section-090/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-090/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-090-capstone-090
```
