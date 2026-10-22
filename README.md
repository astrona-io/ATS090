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
| [010](sections/section-010) | Clients, Redirect URIs And Web Origins | 1 | 1 + capstone | Clients |
| [020](sections/section-020) | The Authorization Code Flow With PKCE | 1 | 1 + capstone | Browser sign-in |
| [030](sections/section-030) | Validating Access Tokens In An API | 1 | 1 + capstone | Token validation |
| [040](sections/section-040) | Token Propagation Through An API Gateway | 1 | 1 + capstone | Token propagation |

The order follows one request: how the application is registered in
Keycloak, how the user signs in through it, how the API checks the token it
receives, and how the token travels through a gateway to a second API.

---

## Modules

| Module | Reader | Parts | Labs |
| --- | --- | --- | --- |
| 010-01 | [Configure Clients For Applications And Services](sections/section-010/module-01/course.md) | 3 | [lab-01](sections/section-010/module-01/labs/lab-01) |
| 020-01 | [Sign Users In With The Authorization Code Flow And PKCE](sections/section-020/module-01/course.md) | 3 | [lab-01](sections/section-020/module-01/labs/lab-01) |
| 030-01 | [Validate Access Tokens In An API](sections/section-030/module-01/course.md) | 4 | [lab-01](sections/section-030/module-01/labs/lab-01) |
| 040-01 | [Propagate Tokens Through An API Gateway](sections/section-040/module-01/course.md) | 3 | [lab-01](sections/section-040/module-01/labs/lab-01) |

---

## Capstones

| Capstone | Scenario | Faults |
| --- | --- | --- |
| [010](sections/section-010/capstone/labs/lab-01) | Secure The Clients Of A Realm | implicit flow on, wildcard redirect URIs and origins, a service client that cannot authenticate |
| [020](sections/section-020/capstone/labs/lab-01) | Repair The Login Of A Single Page Application | a confidential browser client, the standard flow off, a mistyped redirect URI, no PKCE |
| [030](sections/section-030/capstone/labs/lab-01) | Make An API Accept The Right Tokens | no audience, a missing realm role, the roles scope removed from the client |
| [040](sections/section-040/capstone/labs/lab-01) | Propagate A User To A Second API | subject token without the gateway audience, exchange off, an audience not available, a missing role |

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
