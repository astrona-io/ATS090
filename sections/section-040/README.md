# Section 040: Token Propagation Through An API Gateway

A user's request rarely ends at the first service. A client calls a gateway, the gateway calls an API, and that API may call another one. Each hop needs to know who the user is, and each service must still refuse a token that was not meant for it. Passing the same token along every hop breaks the second rule; dropping the user breaks the first.

This section follows a user's token through a gateway. You see what goes wrong when the gateway forwards the token unchanged, and you set up standard token exchange, so the gateway gets a new token for the API behind it, for the same user and for that API only.

**Topic covered:** Token propagation

## What you will learn

- What a gateway does with the `Authorization` header when it forwards a request.
- Why a forwarded token fails the next service's audience check, and why widening the audience is the wrong fix.
- Standard token exchange (RFC 8693) in Keycloak 26: who may exchange, what the request looks like, and what the new token contains.
- The audience rules of token exchange: the subject token must name the requester, and the requester can only get audiences it was given.
- Downscoping: asking for a token with one audience only.

## The learning path

The section has one module. It has a landing page, three short parts, a graded lab right after the part it tests, and a summary. The module has its own playground, and the landing page starts it for you.

### 1. Propagate Tokens Through An API Gateway

The playground holds the namespace `exchange-demo` with Keycloak, the API `inventory-api`, the gateway `inventory-gateway` in front of it, and the realm `inventory` with the user `alice`.

1. Forwarding The Token Through A Gateway
2. Standard Token Exchange, followed by the lab **Exchange A User Token At The Gateway**
3. Downscoping And A Second API
4. Summary

## Section capstone: Propagate A User To A Second API

The capstone is one graded scenario that brings the module together. A second API, `reporting-api`, joins `inventory-api` behind the gateway, and `alice`'s requests fail on the way for four separate reasons. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS090.git -c sections/section-040/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-090-capstone-040
```
