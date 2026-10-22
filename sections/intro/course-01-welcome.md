# Welcome To The Course

This course trains you for the **Securing Applications & Services** part of the Astrona **Keycloak** training path. That part is 25% of the path, the largest one. This page tells you who the course is for, what you can do at the end, which words and example setup it uses, and how its pages fit together.

## Who this course is for

You know your way around Kubernetes: namespaces, Deployments, Services, ConfigMaps, `kubectl logs` and `kubectl exec`. You have used `curl` and you can read JSON. You know what a Keycloak realm, a user and a client are, and you have requested a token from a realm's token endpoint before. Each new idea in this course is explained the first time it appears.

## What you can do at the end

Securing an application means that only the right user, the right application and the right API get through. So this course does not ask you to remember words. It asks you to connect applications and APIs to Keycloak, break into the gaps a wrong setting leaves, and close them. The course has four topics, and each one turns into a set of skills you will practise.

The first topic is **clients**: how each application is registered in Keycloak. You will learn to:

- Choose between a public client and a confidential client, and explain how a confidential client authenticates.
- Lock down the valid redirect URIs of a browser client.
- Set web origins so that only the application's own origin may read Keycloak's responses.

Most users sign in through a browser, so the second topic is **the authorization code flow with PKCE**. You will learn to:

- Run every step of the authorization code flow by hand from a terminal.
- Require Proof Key for Code Exchange (PKCE) with the S256 method.
- Explain what `state` and `nonce` protect against, and check the nonce in an ID token.

A token is only useful if the API checks it, so the third topic is **validating access tokens in an API**. You will learn to:

- Name every check an API makes: signature, issuer, audience, expiry and roles.
- Explain the JSON Web Key Set (JWKS) and how an API follows a key rotation.
- Put the right audience in a token with an audience mapper and a client scope.
- Choose between local validation and token introspection.

The fourth topic is **token propagation through an API gateway**. You will learn to:

- Explain what goes wrong when a gateway forwards a user's token unchanged.
- Exchange a user's token at the gateway for one meant for the API behind it.
- Limit an exchanged token to the one audience it needs.

Everything is written for **Keycloak 26.8.1**.

## The words this course uses

The pages use Keycloak's, OAuth's, OpenID Connect's and Kubernetes' own terms, because those are the words you meet in the product, the logs and the specifications. Each term gets a short, plain definition the first time it appears on a page. A few terms come back on almost every page, so here they are up front.

A **client** is an application or service that asks Keycloak to sign users in or to issue tokens. An **access token** is a token a client sends to an API, and an **ID token** tells the client who the signed-in user is. Both are **JSON Web Tokens (JWT)**: three Base64URL parts, a header, a payload with **claims** and a signature, separated by dots. A **claim** is one field in the payload, for example `iss` (the issuer), `aud` (the audience) or `exp` (the expiry time).

Four claims come back on almost every page:

| Claim | What it says |
| --- | --- |
| `iss` | The realm that issued and signed the token |
| `aud` | Who the token is for; an API must find its own name here |
| `azp` | The client the token was issued to |
| `realm_access.roles` | The realm roles of the user, which an API uses to decide what the user may do |

## The example setup in your playground

Every playground and lab runs the same small setup. One Keycloak pod answers on the Service `keycloak`, port `8080`. You send every request from the `tester` pod, a client with `curl`, `jq` and `openssl`. From the token sections on, an API called `inventory-api` checks every token it receives and writes the reason for each rejection to its log. In the last section, an nginx gateway, `inventory-gateway`, sits in front of it.

Inside Keycloak, the realm is `inventory` and the user is `alice`. The pages use the same clients everywhere: `inventory-web` for a browser application, `inventory-cli` for a command-line tool, `inventory-reporter` for a background service, and `inventory-gateway` for the gateway. No real browser application runs: the address `http://localhost:5173` is the one a local development server would use, and the scripts stop when Keycloak redirects to it.

Each module puts this setup in its own namespace, for example `clients-demo` or `tokens-demo`, so the pages always tell you the namespace to use. Many labs start with something broken on purpose. That is the material, not a fault in the course.

## How the course is laid out

The course has four sections. It follows a request from the application to the API: how the application is registered, how the user signs in, how the API checks the token, and how the token travels through a gateway.

| Section | What it covers |
| --- | --- |
| 010 | Clients, Redirect URIs And Web Origins |
| 020 | The Authorization Code Flow With PKCE |
| 030 | Validating Access Tokens In An API |
| 040 | Token Propagation Through An API Gateway |

Each section has one or more **modules**, and each module teaches one skill. A module brings together four kinds of material:

| What | What it is for | Graded? |
| --- | --- | --- |
| **Reading** | A short landing page, a few chapters that teach one idea each, and a summary | No |
| **Playground** | A small cluster on your own machine, to try everything you read | No |
| **Lab** | A cluster in a starting state, a task, and a grader that checks your work | Yes |
| **Capstone** | The last lab in a section, with several faults at once | Yes |

The best order is simple: read the chapters with the playground open next to them, take each lab when a chapter sends you to it, and finish each section with its capstone. The next part of this page explains how a module's pages guide you through that order.

## How to read a page

A module starts with a **landing page**. It says what the module teaches, what you should know first, and the order of its chapters. At the bottom of the landing page you start the module's playground, and you keep it running while you read.

The chapters (the parts of a module) read like the chapters of a technical book. Each one opens with the problem it solves, explains one idea in connected paragraphs, and closes with what you now know. The hands-on steps sit right in the text: a sentence or two on what to run and why, the command, and then what the result shows. Run each step in your playground as you reach it. You learn more from one real result than from a page of text.

Every chapter ends with a box of common pitfalls, the mistakes people make most often with what the chapter taught, and how to spot them. Now and then a page also has a tip box with a habit or shortcut you can use again, well beyond that page. The two boxes look like this:

> [!TIP]
> **A tip.** A habit or shortcut you can use again, well beyond this one page.

> [!WARNING]
> **Common pitfalls.** The mistakes people make most often with what you just learned, and how to spot them. Every chapter ends with one.

When a graded lab tests what a chapter taught, that chapter ends with a **Your mission** section. It tells you what the lab asks, then gives every command you need, in order: pause the playground with `astrona stop`, start the lab with `astrona run`, and send your work for grading with `astrona submit`. Solve the lab on your own before you look at its solution. When the lab is done, remove it with `astrona destroy` and start the playground again with `astrona start`, so you can carry on reading where you left off.

The last page of every module is the **Summary**. It sums up what you learned in a few short paragraphs, organised by idea. It also ends the module's hands-on work: the Summary page removes the playground, so your machine is clean before the next module.

One rule holds on every page. Code blocks are exactly what you type. Never change a command to make it "look right". If the result is different from what the page describes, that difference is the lesson.
