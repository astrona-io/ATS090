# Writing style for this repo

All study text here (course pages, lab docs, READMEs, comments in YAML and
scripts) is for people learning a technical subject, often for a
certification exam. Many of them are not native English speakers and have no
university degree.

## Technical documentation in plain English

This is technical documentation. Say exactly what the system does, with the
real technical terms, in clear and simple English. Never hide a concept
behind a metaphor, a made-up name or a vague word: the reader must learn the
words they will meet in the product, the logs and the exam.

Strict guidelines:

1. Use the correct technical term every time (request, response, pod,
   namespace, Service, sidecar proxy, certificate, mTLS, JWT, listener). The
   first time a term appears in a file, define it in one plain sentence that
   says what it is and what it does. Spell out every acronym on first use.
2. No metaphors or analogies in explanations. Not "the communications
   officer", but "the sidecar proxy (Envoy)"; not "a signal", but "a
   request"; not "the planet", but "the namespace".
3. Simple sentences. Target a Flesch-Kincaid Grade Level of 8 or 9 for the
   prose around the terms. Keep sentences direct; split long sentences into
   two. No corporate buzzwords.
4. Use short paragraphs (max 3-4 sentences per paragraph).
5. Use the active voice ("istiod sends the configuration", not "the
   configuration is sent").

## How this applies to course material

- **Know which file you are in.** A module has a short landing page, a few
  deep-dive parts and a summary page. The landing page is a map: goals, what
  to know first, the order of the parts. The real teaching goes in the parts.
  The summary closes the module. A lab
  has a task, a step-by-step solution and a short intro. Keep each file to its
  job. Do not add "Prerequisite: ... Next: ..." navigation lines to pages;
  the landing page and the course outline already give the order.
- **Keep each part short.** One idea per part, about 5 to 8 minutes of
  reading and at most about 8 command blocks, so a learner can finish it with
  the playground in one sitting of about 15 minutes. Split at a natural seam
  where each half ends with something the learner has seen work. Never split
  only to hit a number. When you split, renumber the files, fix every "Part N"
  reference in the module and `astrona.yaml`.
- **Read like a book, not like a web page.** Each part reads as a chapter of
  a technical book. Open with a short paragraph on the problem it solves and
  why it matters. Link each paragraph to the next with a transition sentence.
  Close with a paragraph that sums up what the reader now knows and the
  question still open, before `## Common pitfalls` and the mission. Write
  explanations as prose; keep bullets for real lists (fields, ordered steps,
  options). Use `##` only when the topic changes and `###` only inside a long
  section, never for a single command. Weave hands-on steps into the text:
  one or two sentences on what to run and why, the command, the real output,
  then a sentence or two on what it shows.
- **The module ends with a summary.** The last page of every module is
  `course-0N-summary.md` with the title `# Summary`: a few short prose
  paragraphs on what the reader learned, organised by idea, optionally with
  one short list of key facts. It names no parts, modules, sections or
  chapters, and has no links, lab table, quiz or commands. Its last line is
  `<!-- astrona:playground:destroy -->` on its own line; the platform turns it
  into the step that removes the playground.
- **Every heading gets an intro.** A `##` section that has `###`
  subsections starts with one to three sentences that say what the section
  is about and why it matters, before the first `###`. Never put a `###`
  directly under a `##`.
- **Every module stands on its own.** Never refer to other sections or
  modules: no "see section 040", "as module 3 showed", "you met this in
  section 000", and no links to pages in another module. If the reader needs
  a fact from elsewhere, state the fact directly in one or two sentences.
  This also goes for parts of the same module: never write "Part 2 shows",
  "from Part 1" or "as in Part 3". Say the fact itself ("the commands below
  need the `scout` `DestinationRule` applied"). This includes the summary.
  The landing page does not have a "Where this fits" section.
- **Write words out in full.** Do not use informal short forms in prose:
  write "communications", "configuration", "repository", "administrator",
  "for example" and "that is", never "comms", "config", "repo", "admin",
  "e.g." or "i.e.". Names in code, commands and file paths stay as they are.
- **Exam terms stay.** The product's own names are what the reader must learn
  (for example a resource kind, a field, a command). Use them as they are and
  define each one in plain technical words the first time it appears in a
  file. Spell out acronyms on first use, with a short plain meaning.
- **The space theme is only for examples.** Space appears in two places and
  nowhere else: the names of the example workloads (the Starfleet: `bridge`,
  `scout`, `shuttle`, `probe`, the `starfleet` and `outpost` namespaces) and
  the short scenario that opens a lab task or a practice exercise (for
  example "the `drifter` in `outpost` must keep reaching the probe"). The
  explanation around an example is plain technical text: write "the
  `shuttle` pod sends a request to the `probe` Service", never "the shuttle
  sends a signal to the probe ship". Do not address the reader as an
  astronaut, and do not use space metaphors (communications officer, mission
  control, badge, airlock, guest list, star chart) for Istio or Kubernetes
  concepts. Titles of pages and labs name the technical task ("Require mTLS
  With PeerAuthentication"), not a space story.
- **Show one real example before the rule.** Start with a concrete case the
  reader can run, then give the general rule.
- **Say which part does the work.** Readers often mix up the parts of a system
  that sit close together. Whenever something happens, say which component
  did it.
- **Never change code to fit the style.** Commands, configuration files, field
  names, resource names, log lines and command output stay exactly as they
  are. They were run and checked on a real system. Never make up command
  output. If you shorten it, say that you did.
- **Prose only.** The grade-level and sentence rules apply to explanations.
  They do not apply to code blocks, tables of field names or reference lists
  (those may stay short and dense).
- **Keep the page furniture the same.** Hands-on steps are part of the prose
  (see "Read like a book"), not boxes or headings of their own. A `> [!TIP]` box is
  only for a real tip: advice the reader can reuse beyond this one step (a
  habit, a shortcut, how to spot a problem, an exam habit). Everything else
  is a normal sentence: notes about the current step ("if the log line is
  old, run it again"), background facts, optional extra steps, and plain
  information. Never a command snippet, never two in a row, and most pages
  need zero or one tip. Each part ends with a
  `## Common pitfalls` `> [!WARNING]` block for that part only. Use a Mermaid
  diagram for a flow, an order or a state change, keep it under about 12
  boxes, and follow it with one sentence that says what it shows.
- **Labs come right after the part they practise.** Do not collect all
  graded labs at the end of a module. In `astrona.yaml`, put each lab (its
  `question.md` reading and the `lab` entry) right after the reading part it
  tests. If a part teaches a gradeable skill and no lab covers it, create a
  new lab. That part then ends with a `## Your mission: <lab title>` section:
  one sentence on what the reader can now do, one on what the mission asks,
  then pause the playground (`astrona stop <playground name>`), the
  `astrona run` and `astrona submit` commands, and finally
  `astrona destroy <lab name>` plus `astrona start <playground name>`.
- **Renew the playground before hands-on work.** Every reading part that
  runs commands has `<!-- astrona:playground:renew -->` exactly once, on its
  own line, right before the first hands-on step (the first "Save this as"
  or the first command block), so the playground timer is reset before the
  learner needs the playground. Not on landing pages (they carry
  `<!-- astrona:playground -->`), summary pages (they carry
  `<!-- astrona:playground:destroy -->`) or pages without commands.
- **Mermaid without HTML.** The platform renders Mermaid with HTML labels
  switched off, so `<br/>` and any other HTML tag break the drawing. Rules:
  - One line per box, no `<br/>`, no HTML. Keep the box to the thing's name
    (`"scout-v2"`, `"istiod"`, `"Service: scout"`).
  - Put the logic on the arrows: `E -->|"version: v2"| P2`,
    `I -->|"CDS"| C`, `A -->|"end-user: jason"| B`. Keep edge labels short.
  - Quote every label. Prefer `flowchart TB`; use `LR` only for a short chain.
  - Sequence diagrams: short participant aliases (`participant S as shuttle`)
    and short message text.
  - Anything longer (cluster names, full hostnames) goes in the sentence under
    the diagram.
- **Every course starts with an Introduction.** It lives in `sections/intro/`
  and is the first entry in `astrona.yaml` (`id: module-intro`, title
  "Introduction"). It has exactly these four pages, in this order:
  - `README.md`, `# Introduction`: what the introduction covers and its three
    pages, named in prose (no links), ending with the topic the course starts
    with.
  - `course-01-welcome.md`, `# Welcome To The Course`: who the course is for,
    the exam domain and what the reader can do at the end, the words the
    course uses, the example app, how the course is laid out and how to read
    a page.
  - `course-02-get-your-machine-ready.md`, `# Get Your Machine Ready`: the
    tools to install, the `astrona` commands used every day, and what to do
    when a start goes wrong.
  - `course-03-how-this-course-is-made.md`, `# How This Course Is Made`: how
    content is written and checked, the maintainers, how to report a mistake,
    and the license.
  The Introduction teaches no product content and has no playground, labs or
  summary. Its only links are the repository's contributors page, issues
  page and license.
- **No links to other course files.** A course page (every reading listed in
  `astrona.yaml`, the playground guide `docs/overview.md`, and a lab's
  `question.md` and `solution.md`) never links to or points the reader at
  another page or file of the repository: no links to parts, summaries,
  labs, `question.md`, other modules, sections or the Introduction, and no
  "see `practice.md`" or "open `config.yaml`". The platform shows the pages in
  the order of `astrona.yaml`, so a link only adds a second, often wrong,
  path. Name a thing in plain words when the reader needs it ("the task is on
  the next page"), and state a fact on the page itself instead of sending the
  reader somewhere else. Repository files for authors (the root `README.md`,
  a lab's or playground's `README.md`) may link.
- **No links to outside sources.** Course pages, labs and playground docs do
  not link to or point at outside websites (the one exception is the
  `resources` field of a lab entry in `astrona.yaml`) (official docs, GitHub, blogs,
  RFCs), and they have no "Reference" or "Official docs" lists. Everything the
  reader needs is explained on the page itself. Not affected: addresses the
  reader actually uses in a command or browser (`http://127.0.0.1:9080`,
  `curl https://httpbin.org`), and the Introduction's contributors and
  "report a mistake" links.
- **Configuration goes to a file first.** Whenever the reader should apply
  YAML (course parts, playground docs, labs), use three separate steps:
  1. "Save this as `virtualservice-scout.yaml`:" followed by a plain
     ` ```yaml ` block with only the YAML. No `cat > file <<'EOF'`, no
     `kubectl apply -f - <<EOF`, no shell around it.
  2. "Apply it:" followed by a ` ```sh ` block with only
     `kubectl apply -f virtualservice-scout.yaml`.
  3. "Then check the result:" followed by the check commands, if any.
  The file name says the kind and the object. If a value must come from the
  reader's cluster (an IP address), use a placeholder like `<PARTNER>` in the
  YAML and say how to get the value (`echo $PARTNER`); never put shell
  variables inside YAML. Apply an object the first time its YAML appears; do
  not show it once "to read" and paste it again later. Never tell the reader
  to apply something from the playground's `examples/` folder: they start the
  playground with `astrona run`, so that folder is not on their machine.
- **Helpers have readable names.** Shell helper functions and variables use
  names that say what they do (`check_route`, `count_versions`,
  `$SERVICE_URL`), never single letters.


## About this repo (ATS090 only)

Everything above is general and can be copied to other course repositories. This
section is only true for this one.

### What the student is trying to learn

- **The goal:** master the **Securing Applications & Services** domain of the
  **Keycloak** training path (`ATP018`). It is 25% of the path, the largest
  domain. There is no official Keycloak certification exam; the path's domains
  and weights are Astrona's own, set in `ATP018/path.yaml`.
- **What the domain really tests:** connecting applications to Keycloak so
  that only the right user, the right client and the right API get through.
  The student must *do* things (lock down a client's redirect URIs and web
  origins, run the authorization code flow with PKCE from a terminal, decode a
  token and compare it with what an API checks, add an audience, exchange a
  token at a gateway). Every explanation should lead to a command they can
  run, and every fix should be proved with a real flow or API call that failed
  before and succeeds after.
- **The four topics:** clients (public and confidential, client
  authentication, redirect URIs, web origins and CORS), the authorization code
  flow with Proof Key for Code Exchange (PKCE), validating access tokens in an
  API (signature, JSON Web Key Set (JWKS), `iss`, `aud`, `exp`, roles), and
  token propagation through an API gateway (forwarding against token
  exchange).
- **The sections:**

  | Section | Title | Topic |
  | --- | --- | --- |
  | 010 | Clients, Redirect URIs And Web Origins | Clients |
  | 020 | The Authorization Code Flow With PKCE | Browser sign-in |
  | 030 | Validating Access Tokens In An API | Token validation |
  | 040 | Token Propagation Through An API Gateway | Token propagation |

- **The version:** everything is written for **Keycloak 26.8.1**, image
  `quay.io/keycloak/keycloak:26.8.1`, on a single-node `kind` cluster. Do not
  teach fields, flags or output from other versions without saying so. Pin the
  image tag in every manifest; never use `latest`.
- **The main sources:** the Keycloak Securing Applications guides,
  <https://www.keycloak.org/guides#securing-apps>, the Server Administration
  Guide, <https://www.keycloak.org/docs/latest/server_admin/index.html>, and
  the specifications listed under "Where to find trusted sources". Check every
  page against them.

### Status: built, not yet run

The first version of this repository was written from the Keycloak 26.8.1
documentation **without a live run**. No playground or lab has been started,
and no `astrona test` has passed yet. Until a maintainer runs them:

- Pages describe results in words. Do not add `text` output blocks until the
  output comes from a real run, and then paste it exactly.
- Treat every lab as unverified. Run `astrona validate` and `astrona test` on
  each one, one cluster at a time, before the course goes past `maturity:
  draft`.
- Check these first, because most graders depend on them:
  - The login form of the `keycloak.v2` theme has an `action` URL that
    contains `login-actions/authenticate`; the code flow script finds the form
    by that text.
  - `nicolaka/netshoot:v0.13` has `openssl` (for the S256 code challenge) and
    a `jq` whose `@base64d` decodes unpadded Base64URL.
  - The client attribute `standard.token.exchange.enabled` is the attribute
    behind the console switch **Standard token exchange**.
  - The token endpoint answers a request with an `Origin` header that the
    client allows with `Access-Control-Allow-Origin`, and leaves the header
    out for an origin it does not allow.
- Remove this subsection when every lab has passed `astrona test`.

### Terms, not metaphors

Explanations use Keycloak's, OAuth's, OpenID Connect's and Kubernetes' own
words. Define each one in plain technical language on first use in a file,
for example:

| Term | First-use definition (example wording) |
| --- | --- |
| Client | An application or service that asks Keycloak to sign users in or to issue tokens |
| Public client / confidential client | A client that cannot keep a secret (a single page application or a command-line tool) / a client that can, and authenticates to the token endpoint |
| Client authentication | How a confidential client proves who it is at the token endpoint: a client secret, or a JWT signed with its own key (`private_key_jwt`) or with the secret (`client_secret_jwt`) |
| Redirect URI | The address Keycloak sends the browser back to, with the authorization code; Keycloak only uses one the client lists as valid |
| Web origin | A scheme, host and port (`http://localhost:5173`) that may read Keycloak's responses from JavaScript; `+` means "the origins of the valid redirect URIs" |
| CORS | Cross-Origin Resource Sharing: the browser rule that lets a page read a response from another origin only when the response says `Access-Control-Allow-Origin` |
| Authorization code flow | The browser flow: the user signs in at Keycloak, the browser comes back with a short-lived code, and the client exchanges the code for tokens |
| PKCE | Proof Key for Code Exchange: the client sends a hash of a random `code_verifier` with the authorization request, and the verifier itself with the code, so a stolen code is useless |
| `state` / `nonce` | A random value the client checks on the way back, against forged responses / a random value Keycloak copies into the ID token, against replayed tokens |
| Implicit flow | An older browser flow that returns tokens in the URL; OAuth 2.1 drops it |
| Front channel / back channel | Messages that pass through the browser (redirects) / direct server-to-server requests (the token request) |
| JWKS | JSON Web Key Set: the realm's public signing keys, at `/realms/<realm>/protocol/openid-connect/certs`, each with a key ID (`kid`) |
| Audience (`aud`) | The claim that names who a token is for; an API must refuse a token whose `aud` does not name it |
| Audience mapper | A protocol mapper (`oidc-audience-mapper`) that adds a client to the `aud` of tokens |
| Client scope | A reusable set of protocol mappers and role scopes that Keycloak adds to the tokens of the clients that use it (as a default or an optional scope) |
| Token introspection | Asking Keycloak whether a token is still active, at `/realms/<realm>/protocol/openid-connect/token/introspect` |
| Token exchange | RFC 8693: a client sends a token it received and gets a new token for another audience |
| Resource server | An API that accepts access tokens |

Do not invent friendly names for these (no "the bouncer", "the ticket", "the
stamp"). The product's names are what the student meets in the console and
the logs.

### The example workloads

Every module deploys its own namespace (`clients-demo`, `pkce-demo`,
`tokens-demo`, `exchange-demo`; capstones use `clientscapstone-demo`,
`pkcecapstone-demo`, `tokenscapstone-demo` and `exchangecapstone-demo`).

| Kubernetes name | Image | What it is |
| --- | --- | --- |
| `keycloak` (Deployment and Service) | `quay.io/keycloak/keycloak:26.8.1` | One Keycloak pod in development mode. Service port `8080` (`http`) and `9000` (`management`) |
| `keycloak-admin` (Secret) | | Bootstrap administrator: user `admin`, password `admin`. Lab-only credentials; say so when a page uses them |
| `tester` | `nicolaka/netshoot:v0.13` | Client pod with `curl`, `jq` and `openssl`. Every flow and API call is sent from here |
| `inventory-api` (Deployment and Service) | `node:22-alpine` | The example API on port `8080`, sections 030 and 040. Its code, `server.js` in the ConfigMap `inventory-api-code`, uses Node.js core modules only: it loads the JWKS, checks the RS256 signature, `iss`, `aud`, `exp`, `typ` and the realm role in `REQUIRED_ROLE`, and logs one line per request with the reason for a rejection |
| `reporting-api` | `node:22-alpine` | The same code with `AUDIENCE=reporting-api` and `REQUIRED_ROLE=reporting-reader`; the 040 capstone only |
| `inventory-gateway` (Deployment and Service) | `nginx:1.27-alpine` | A reverse proxy on port `8080` in front of `inventory-api`; it forwards the `Authorization` header unchanged; section 040 |

Inside Keycloak, every module uses the same names:

| Keycloak name | What it is |
| --- | --- |
| realm `inventory` | The application realm |
| user `alice` | Password `alice-password`, complete profile. Gets the realm role `inventory-reader` in sections 030 and 040 |
| client `inventory-web` | The single page application: public, standard flow, redirect URI `http://localhost:5173/callback`, web origin `+` |
| client `inventory-cli` | Public client with direct access grants, used to get a token for `alice` from a terminal |
| client `inventory-reporter` | Confidential client with a service account, secret `inventory-reporter-secret` |
| client `inventory-api` / `reporting-api` | Clients that stand for the APIs, so they can be named as an audience; every flow is off |
| client `inventory-gateway` | Confidential client for the gateway, secret `inventory-gateway-secret`; it exchanges tokens in section 040 |

No real single page application runs. `http://localhost:5173` is the origin a
local development server would use; the code flow script stops at the
redirect and reads the code from the `Location` header, so nothing needs to
answer on that address. Say so where a page first uses it.

The password grant (`grant_type=password`, "Direct access grants") is used
**only** to get a token for `alice` from a terminal in the token sections. Say
every time it is used that OAuth 2.1 drops it and a real application uses the
authorization code flow.

### Environment facts the text must respect

- **Keycloak runs as plain Kubernetes manifests**, as in ATS088.
- **The administration helper** is the same as in ATS088: `kcadm.sh` inside
  the Keycloak pod with `--config /tmp/kcadm.config`, signed in with
  `kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin`.
- **The issuer is `http://keycloak:8080/realms/inventory`** for every token
  requested from `tester`. `inventory-api` expects exactly that issuer, so
  tokens requested through a port-forward (`localhost`) are rejected with an
  `iss` reason. Pages that use the Admin Console in a browser still request
  tokens from `tester`.
- **The code flow script.** Labs and the PKCE pages run the whole flow from
  `tester` with one shell script (`run_code_flow` in the graders). It sends
  the authorization request with `state`, `nonce` and, unless `PKCE=none`, a
  code challenge; finds the login form; posts `alice`'s credentials; reads the
  code from the `Location` header; and exchanges it with an `Origin` header.
  It prints `KEY=VALUE` lines (`FORM_FOUND`, `CODE_FOUND`, `TOKEN_STATUS`,
  `ACAO`, `ACCESS_CLAIMS`, `ID_CLAIMS`). Every grader that runs a flow holds
  its own copy; change all copies together and never let two drift.
- **Keycloak 26.8.1 facts (from the documentation, not yet seen on a run):**
  - PKCE is required per client with the attribute
    `pkce.code.challenge.method` (`S256` or `plain`); the console shows it as
    **Proof Key for Code Exchange Code Challenge Method** under the client's
    advanced settings.
  - Standard token exchange (V2, RFC 8693) is on by default in Keycloak 26.
    It is allowed per client with the **Standard token exchange** switch.
    Only a confidential client may exchange. The subject token's `aud` must
    contain the requesting client. The `audience` parameter only filters:
    every requested audience must already be available to the requester
    through its client scopes or role scope mappings, or the request fails.
    `subject_token_type` must be `urn:ietf:params:oauth:token-type:access_token`.
  - Keycloak sets `typ` to `Bearer` in access tokens and `ID` in ID tokens.
- **Many environments start broken on purpose.** The seed script creates the
  fault after Keycloak is up. Never "fix" it in the bootstrap.
- **APIs are never the fault.** Every lab with an API keeps a copy of its code
  in the ConfigMap `lab-baseline`, and a grader fails when the code or the
  `ISSUER`, `AUDIENCE` or `REQUIRED_ROLE` variables change. The fix is always
  in Keycloak.

### Where things are in this repo

| What | Where |
| --- | --- |
| Course outline the platform reads: every reading page and lab, in order. Never list `solution.md` here | `astrona.yaml` |
| Overview, sections and modules tables, how to run things | `README.md` |
| Introduction | `sections/intro/` |
| Section overview and its modules | `sections/section-0N0/README.md` |
| Module reading: landing page, deep-dive parts, closing page | `sections/section-0N0/module-0M/course.md`, `course-0N-*.md` |
| Graded lab: task, walkthrough, setup, grader | `.../labs/lab-01/` (`question.md`, `solution.md`, `prerequisites.md`, `bootstrap/`, `manifests/`, `solution/`, `testing/`, `validation/`) |
| Ungraded sandbox for a module | `.../playground/` (`config.yaml`, `bootstrap/prepare.sh`, `manifests/`, `docs/overview.md`, which is the only learner page) |
| One graded integration lab per section | `sections/section-0N0/capstone/labs/lab-01/` |

The infrastructure files (every `config.yaml`, `README.md` of a lab or
playground, `prerequisites.md`, `manifests/lab-start.yaml`, `bootstrap/`,
`solution/apply.sh`, `testing/` and `validation/`) were generated from one
source so they stay identical. When you change a shared piece (the
Keycloak manifest, `server.js`, the code flow script), change it in every
environment.

### Lab metadata in `astrona.yaml`

`astrona.yaml` has a `training:` block (id `ATS090`, domain
`Securing Applications & Services`, weight `25`) and one entry per section
under `modules:` (`module-010` to `module-040`), laid out as in ATS088.

- `difficulty`: `beginner`, `intermediate` or `advanced`.
- `estimated_duration`: realistic time to solve it, for example `15m`, `30m`.
- `topic`: exactly one of `clients`, `browser-flows`, `token-validation`,
  `token-propagation`.
- `task_kind`: exactly one of `build`, `troubleshooting` or `migration`.
- `tags`: 4 to 8 ids, only from the tag list below. Add a new tag to the list
  first if nothing fits.
- `learning_goals`: 2 or 3 plain sentences, each starting with a verb.
- `resources`: 1 to 4 pages on `keycloak.org` or the specifications, each
  with a `name` and a `url` that loads. The **only** place outside links are
  allowed.

**Tag list** (lower case, hyphens, never synonyms):

- Clients: `public-client`, `confidential-client`, `client-authentication`,
  `client-secret`, `redirect-uris`, `web-origins`, `cors`, `implicit-flow`,
  `service-account`
- Browser flows: `authorization-code`, `pkce`, `s256`, `state`, `nonce`,
  `id-token`, `single-page-application`
- Tokens: `access-token`, `jwt`, `jwks`, `signature`, `issuer`, `audience`,
  `audience-mapper`, `client-scopes`, `realm-roles`, `introspection`
- Propagation: `api-gateway`, `token-forwarding`, `token-exchange`,
  `downscoping`, `kcadm`

### Running things

```bash
# Playground (ungraded)
astrona run --git ssh://git@github.com/astrona-io/ATS090.git -c sections/section-010/module-01/playground
astrona destroy ats-090-playground-010-01   # takes metadata.name from config.yaml, not the path

# Lab or capstone (graded against the live cluster)
astrona run --git ssh://git@github.com/astrona-io/ATS090.git -c sections/section-010/module-01/labs/lab-01
astrona submit -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-090-lab-010-01

# Authors: run a local, uncommitted copy, and prove a lab passes with its reference solution
astrona run -c sections/section-010/module-01/playground
astrona test -c sections/section-010/module-01/labs/lab-01
```

Names: a playground is `ats-090-playground-<section>-<module>`, a module lab
is `ats-090-lab-<section>-<module>` and a capstone is
`ats-090-capstone-<section>`; keep those names. Every lab must pass
`astrona validate` and `astrona test`.

Graders check **behaviour**, not just settings: a real code flow, a real API
call, a real token exchange. Graders also reject the plausible but wrong fix
(a wildcard redirect URI, every origin allowed, changing the API instead of
Keycloak, adding an audience to every client, giving the user administration
roles, adding the API's audience to the user's own client instead of
exchanging at the gateway). A lab's `question.md` and `solution.md` must match
what its `validation/` scripts actually check.

Test clusters on the maintainer's machine: one at a time.

### Where to find trusted sources

Check facts here before writing them down. Prefer these over memory.

- **Keycloak:**
  [Securing applications: OpenID Connect](https://www.keycloak.org/securing-apps/oidc-layers),
  [token exchange](https://www.keycloak.org/securing-apps/token-exchange),
  [Server Administration Guide](https://www.keycloak.org/docs/latest/server_admin/index.html)
  (OpenID Connect clients, client scopes, protocol mappers, audience support)
- **Specifications:**
  [RFC 6749 OAuth 2.0](https://datatracker.ietf.org/doc/html/rfc6749),
  [RFC 7636 PKCE](https://datatracker.ietf.org/doc/html/rfc7636),
  [RFC 7519 JWT](https://datatracker.ietf.org/doc/html/rfc7519),
  [RFC 7517 JWK](https://datatracker.ietf.org/doc/html/rfc7517),
  [RFC 7662 introspection](https://datatracker.ietf.org/doc/html/rfc7662),
  [RFC 8693 token exchange](https://datatracker.ietf.org/doc/html/rfc8693),
  [OpenID Connect Core 1.0](https://openid.net/specs/openid-connect-core-1_0.html),
  [OAuth 2.0 for browser-based applications](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-browser-based-apps)

### Skills to use here

The `astrona-course-*` skills do most authoring jobs in this repository:
planning (`domain-plan`), creating the tree (`domain-scaffold`), building
modules (`domain-build`), deep-dive parts (`deep-dive`), labs and playgrounds
(`lab`), lab docs (`lab-docs`), challenges (`create-challenge`), quizzes
(`generate-assessment`) and fact-checking (`review-accuracy`).
