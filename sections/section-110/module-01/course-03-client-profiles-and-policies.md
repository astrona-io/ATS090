# Client Profiles And Policies

Client policies are a second layer that applies to **every** way a client is created or changed: the admin console, the admin API and the registration endpoints. They have two parts that are easy to mix up.

- A **profile** is a named list of **executors**. An executor is a rule about the client, for example "PKCE is required".
- A **policy** is a named list of **conditions** and the profiles that apply when all conditions match. A condition decides which clients or requests the policy covers.

So: conditions decide *when*, profiles decide *what*.

## Executors

An executor runs on events such as the registration or update of a client, and on authorization and token requests. Some useful built-in executors:

| Executor | What it enforces |
| --- | --- |
| `pkce-enforcer` | Clients must use PKCE. With `auto-configure` it sets the client to S256 |
| `reject-ropc-grant` | Clients must not use the password grant |
| `secure-client-uris` | Redirect URIs must be exact, secure addresses |
| `secure-client-authenticator` | Confidential clients must use an approved authenticator |
| `consent-required` | Clients must require consent |
| `full-scope-disabled` | Clients must not have full scope allowed |

An executor either **rejects** the change or, with an `auto-configure` option where it exists, **fixes** the client so that it complies.

## Conditions

| Condition | Matches |
| --- | --- |
| `any-client` | Every client |
| `client-access-type` | Clients of a type such as public or confidential |
| `client-roles` | Clients that have a given role |
| `client-scopes` | Clients that use a given scope |
| `client-updater-source-host` | Requests from given hosts |

## Read, write and enable

Profiles and policies are read and written as a whole document. The admin API paths are `client-policies/profiles` and `client-policies/policies`. A write **replaces** everything custom in the realm, so send the full list.

<!-- astrona:playground:renew -->

```sh
NAMESPACE=reg-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm get client-policies/profiles -r inventory
kcadm get client-policies/policies -r inventory
```

To change them, send a complete document and turn merging off:

```sh
kcadm update client-policies/policies -r inventory -n \
  -b '{"policies":[{"name":"public-clients","description":"PKCE for all clients","enabled":true,"profiles":["strict-public"],"conditions":[{"condition":"any-client","configuration":{}}]}]}'
```

A policy has an `enabled` flag. A disabled policy exists but does nothing, which is a quiet way to lose a control.

## Test with a client

Create a public client and read back its PKCE attribute:

```sh
kcadm create clients -r inventory -s clientId=probe -s publicClient=true -s standardFlowEnabled=true
kcadm get clients -r inventory -q clientId=probe --fields clientId,attributes
```

When `pkce-enforcer` with `auto-configure` applies, the attribute `pkce.code.challenge.method` is `S256`. Delete the probe afterwards:

```sh
kcadm delete "clients/$(kcadm get clients -r inventory -q clientId=probe --fields id --format csv --noquotes | tr -d '\r')" -r inventory
```

## Your mission: Enforce PKCE With A Client Policy Lab

The mission starts from a realm that has a PKCE profile and a policy, but new public clients are not set to S256. You find out why and fix it.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-090-playground-110-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS090.git -c sections/section-110/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-110/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-090-lab-110-01
astrona start ats-090-playground-110-01
```

## Common pitfalls

> [!WARNING]
> - **Sending only the changed policy in a write.** The write replaces every custom policy; send the full list.
> - **Forgetting `-n` with `kcadm update`.** The merge with the old document gives unexpected lists.
> - **Defining a profile and not attaching it.** A profile does nothing until an enabled policy names it.
> - **Leaving `enabled` false.** The policy exists but no condition is evaluated.
