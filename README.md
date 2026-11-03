# ATS090 — Securing Applications & Services (Keycloak)

Course material for the **Securing Applications & Services** domain of the
Astrona Keycloak training path ([ATP018](https://github.com/astrona-io/ATP018)),
which is **25% of the path**. Written for **Keycloak 26.8.1**.

> **Status: draft, not yet run.** Every page, playground and lab was written
> from the Keycloak 26.8.1 documentation and the specifications. None has been
> started on a cluster, and no lab has passed `astrona test` yet. See
> `CLAUDE.md` for what to check first.

The course opens with an Introduction in `sections/intro/` (welcome, machine setup,
how the course is made). Everything else lives under `sections/`. Each section
contains:

- **Modules** — a reading chapter split into a short landing page, ordered
  deep-dive parts and a summary page, a throwaway **playground** to explore in,
  and a graded **lab** placed right after the part it tests.
- **A capstone** — one larger graded lab combining that section's modules into a
  single scenario with several independent faults.

---

## Sections

| Section | Title | Modules | Labs | Topic |
| --- | --- | --- | --- | --- |
| [010](sections/section-010) | Clients, Redirect URIs And Web Origins | 1 | 2 + capstone | Clients |
| [020](sections/section-020) | The Authorization Code Flow With PKCE | 1 | 2 + capstone | Browser sign-in |
| [030](sections/section-030) | Validating Access Tokens In An API | 1 | 1 + capstone | Token validation |
| [040](sections/section-040) | Token Propagation Through An API Gateway | 1 | 2 + capstone | Token propagation |
| [050](sections/section-050) | Client Credentials And Service Accounts | 1 | 1 + capstone | Service clients |
| [060](sections/section-060) | Token Lifetimes, Refresh Tokens And Sessions | 1 | 1 + capstone | Token lifetimes and sessions |
| [070](sections/section-070) | Logout, Back-Channel Logout And Session Control | 1 | 1 + capstone | Logout and session control |
| [080](sections/section-080) | Client Scopes, Protocol Mappers And Token Claims | 1 | 1 + capstone | Client scopes, mappers and token claims |
| [090](sections/section-090) | Keycloak As A SAML Identity Provider | 1 | 1 + capstone | SAML clients |
| [100](sections/section-100) | Authorization Services | 1 | 1 + capstone | authorization services |
| [110](sections/section-110) | Client Registration And Client Policies | 1 | 1 + capstone | client registration |
| [120](sections/section-120) | OAuth 2.0 Device Authorization Grant | 1 | 1 + capstone | the device authorization grant |
| [130](sections/section-130) | Sender-Constrained Tokens: DPoP And Mutual TLS | 1 | 1 + capstone | sender-constrained tokens |
| [140](sections/section-140) | Securing Applications With Libraries, Proxies And Gateways | 1 | 1 + capstone | securing applications |

The order follows one request: how the application is registered in
Keycloak, how the user signs in through it, how the API checks the token it
receives, and how the token travels through a gateway to a second API.

---

## Modules

| Module | Reader | Parts | Labs |
| --- | --- | --- | --- |
| 010-01 | [Configure Clients For Applications And Services](sections/section-010/module-01/course.md) | 4 | [lab-01](sections/section-010/module-01/labs/lab-01), [lab-02](sections/section-010/module-01/labs/lab-02) |
| 020-01 | [Sign Users In With The Authorization Code Flow And PKCE](sections/section-020/module-01/course.md) | 4 | [lab-01](sections/section-020/module-01/labs/lab-01), [lab-02](sections/section-020/module-01/labs/lab-02) |
| 030-01 | [Validate Access Tokens In An API](sections/section-030/module-01/course.md) | 4 | [lab-01](sections/section-030/module-01/labs/lab-01) |
| 040-01 | [Propagate Tokens Through An API Gateway](sections/section-040/module-01/course.md) | 4 | [lab-01](sections/section-040/module-01/labs/lab-01), [lab-02](sections/section-040/module-01/labs/lab-02) |
| 050-01 | [Authenticate Service Clients With Client Credentials](sections/section-050/module-01/course.md) | 4 | [lab-01](sections/section-050/module-01/labs/lab-01) |
| 060-01 | [Control Token Lifetimes, Refresh Tokens And Sessions](sections/section-060/module-01/course.md) | 4 | [lab-01](sections/section-060/module-01/labs/lab-01) |
| 070-01 | [End Sessions With Logout And Admin Control](sections/section-070/module-01/course.md) | 4 | [lab-01](sections/section-070/module-01/labs/lab-01) |
| 080-01 | [Shape Tokens With Client Scopes And Protocol Mappers](sections/section-080/module-01/course.md) | 4 | [lab-01](sections/section-080/module-01/labs/lab-01) |
| 090-01 | [Keycloak As A SAML Identity Provider](sections/section-090/module-01/course.md) | 4 | [lab-01](sections/section-090/module-01/labs/lab-01) |
| 100-01 | [Authorization Services](sections/section-100/module-01/course.md) | 4 | [lab-01](sections/section-100/module-01/labs/lab-01) |
| 110-01 | [Client Registration And Client Policies](sections/section-110/module-01/course.md) | 4 | [lab-01](sections/section-110/module-01/labs/lab-01) |
| 120-01 | [OAuth 2.0 Device Authorization Grant](sections/section-120/module-01/course.md) | 4 | [lab-01](sections/section-120/module-01/labs/lab-01) |
| 130-01 | [Sender-Constrained Tokens: DPoP And Mutual TLS](sections/section-130/module-01/course.md) | 4 | [lab-01](sections/section-130/module-01/labs/lab-01) |
| 140-01 | [Securing Applications With Libraries, Proxies And Gateways](sections/section-140/module-01/course.md) | 4 | [lab-01](sections/section-140/module-01/labs/lab-01) |

---

## Capstones

| Capstone | Scenario | Faults |
| --- | --- | --- |
| [010](sections/section-010/capstone/labs/lab-01) | Secure The Clients Of A Realm | implicit flow on, wildcard redirect URIs and origins, a service client that cannot authenticate |
| [020](sections/section-020/capstone/labs/lab-01) | Repair The Login Of A Single Page Application | a confidential browser client, the standard flow off, a mistyped redirect URI, no PKCE |
| [030](sections/section-030/capstone/labs/lab-01) | Make An API Accept The Right Tokens | no audience, a missing realm role, the roles scope removed from the client |
| [040](sections/section-040/capstone/labs/lab-01) | Propagate A User To A Second API | subject token without the gateway audience, exchange off, an audience not available, a missing role |
| [050](sections/section-050/capstone/labs/lab-01) | Secure The Service Clients Of A Realm | a signed-JWT-only client, a leaked secret, a public client that should be a service client, a missing role |
| [060](sections/section-060/capstone/labs/lab-01) | Fix The Token Lifetimes Of A Client | a client override of one day, no refresh token rotation, the offline_access scope removed from the client, a one-minute offline idle time |
| [070](sections/section-070/capstone/labs/lab-01) | Repair The Logout Of A Client | a wildcard post-logout redirect, no back-channel logout URL, a logout token without the session id, live sessions of a suspect account |
| [080](sections/section-080/capstone/labs/lab-01) | Repair The Token Contents Of A Client | a groups mapper that skips the access token, Full Scope Allowed leaking an admin role, a needed client scope that is only optional |
| [090](sections/section-090/capstone/labs/lab-01) | Secure A SAML Service Provider | a wildcard ACS address, an unsigned assertion, no email attribute, a misnamed role attribute |
| [100](sections/section-100/capstone/labs/lab-01) | Correct The Permissions Of A Report API | an inverted finance policy and a delete permission bound to the wrong policy |
| [110](sections/section-110/capstone/labs/lab-01) | Lock Down Partner Client Registration | a policy that names no profile and a profile without a password-grant rule |
| [120](sections/section-120/capstone/labs/lab-01) | Secure A Device Login For A TV App | a confidential client, a long code lifetime, a fast polling interval and direct access grants on |
| [130](sections/section-130/capstone/labs/lab-01) | Bind Tokens For A Payments Platform | a payments client without DPoP, a long token lifetime and a partner client that wrongly requires DPoP |
| [140](sections/section-140/capstone/labs/lab-01) | Protect An Orders API Behind A Gateway | a wildcard redirect address, a long token lifetime, a misspelled audience and a misnamed groups claim |

---

## The example API

Sections 030 and 040 deploy `inventory-api`, a Node.js server that uses core
modules only (`server.js` in the ConfigMap `inventory-api-code`). It loads the
realm's JWKS, checks the RS256 signature, `iss`, `aud`, `exp`, `typ` and one
realm role, and logs one line per request with the reason for a rejection.
Labs keep a copy of the code in the ConfigMap `lab-baseline`: the fix is
always in Keycloak, never in the API.

The infrastructure files of every playground and lab (configs, manifests,
bootstrap, seed, reference solution, graders) share the same building blocks,
including one shell script that runs the authorization code flow from the
`tester` pod. Change a shared piece in every environment at once.

## Running a playground

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS090.git -c sections/<section>/<module>/playground
astrona destroy <name>
```

## Running a lab

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS090.git -c sections/<section>/<module>/labs/lab-01
astrona submit -c sections/<section>/<module>/labs/lab-01
astrona destroy <name>
```

Each lab grades the **final state** with independent checks that run a real
sign-in, API call or token exchange, and several of them reject the
plausible-but-wrong fix (a wildcard, changing the API, an audience added to
every client, extra roles for the user).
