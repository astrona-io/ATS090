# Section 100: Authorization Services

Roles in a token tell an application who the user is. Authorization Services lets Keycloak decide what a user may do with a protected resource, using policies and permissions kept in one place.

This section covers resource servers, resources and scopes, policies and permissions, permission requests and evaluation, and decision strategies with enforcement modes. You check every change by asking Keycloak for a decision.

**Topic covered:** authorization services

## What you will learn

- How a client becomes a resource server and how resources and scopes are modelled.
- How policies and permissions combine, including POSITIVE and NEGATIVE logic.
- How to request a decision with the UMA ticket grant.
- How decision strategies and enforcement modes shape the final answer.

## The learning path

The section has one module. It has a landing page, 4 short parts, a graded lab right after the part it tests, and a summary. The module has its own playground, and the landing page starts it for you.

### 1. Authorization Services

The playground holds the namespace `authz-demo` with Keycloak, the realm `inventory`, the users `alice` (role `finance`) and `bob`, and the resource server `invoice-api`. You create resources, policies and permissions with `kcadm.sh` and ask for decisions with `curl`.

1. Resource Servers, Resources And Scopes
2. Policies And Permissions
3. Requesting And Evaluating Permissions, followed by the lab **Grant Access With A Role Policy**
4. Decision Strategies And Enforcement
5. Summary

## Section capstone: Correct Report API Permissions

The capstone is one graded scenario that brings the module together. A report API has an inverted finance policy and a delete permission bound to the wrong policy. Fix both and verify six decisions. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS090.git -c sections/section-100/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-100/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-090-capstone-100
```
