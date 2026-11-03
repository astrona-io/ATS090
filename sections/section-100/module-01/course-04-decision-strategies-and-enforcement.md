# Decision Strategies And Enforcement

One permission can have several policies, and one request can touch several permissions. Keycloak combines the results with a **decision strategy**. The resource server as a whole has an **enforcement mode**. This part covers both and the safe defaults.

## Decision strategies

| Strategy | The permission grants when |
| --- | --- |
| `UNANIMOUS` | Every policy passes. This is the default |
| `AFFIRMATIVE` | At least one policy passes |
| `CONSENSUS` | More policies pass than fail |

The strategy is set on a permission for its policies, and on the resource server for its permissions. Two policies "finance" and "manager" on one permission with `UNANIMOUS` mean both are needed. With `AFFIRMATIVE`, either one is enough. A common mistake is to want "either" and keep the default.

The same idea applies to an **aggregated policy**, which bundles policies and has its own strategy. Use it to give a name to a combination you reuse.

## Required roles

A role policy lists roles. By default one is enough. Marking a role as **required** needs every required role plus, when none is marked, at least one of the listed roles. This gives "finance and manager" inside one policy without an aggregate.

## Enforcement mode

The resource server setting `policyEnforcementMode` has three values:

| Mode | Behaviour |
| --- | --- |
| `ENFORCING` | A request is denied unless a permission grants it. The default |
| `PERMISSIVE` | A request for a resource that no permission covers is granted |
| `DISABLED` | Policies are not evaluated and everything is granted |

Read and set it:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=authz-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
RS_ID=$(kcadm get clients -r inventory -q clientId=invoice-api --fields id --format csv --noquotes | tr -d '\r')
kcadm get "clients/$RS_ID/authz/resource-server" -r inventory --fields policyEnforcementMode,decisionStrategy,allowRemoteResourceManagement
```

`PERMISSIVE` and `DISABLED` are for development. A production resource server stays on `ENFORCING`, because then a resource that someone forgot to protect is closed, not open.

## Protection API and user-managed access

Resource servers can also let users share their own resources. The **protection API** lets the resource server register resources at runtime, and the setting `allowRemoteResourceManagement` allows it. Users then grant access to others through permission tickets, the UMA flow. This module does not use it; know that it exists for per-user sharing, for example a user who shares a document with a colleague.

## Putting it together

A good model has few resources, scopes that name actions, reusable role or group policies, one scope permission per action, `ENFORCING` mode and a test of the decision for each kind of user. Test the allow and the deny, because a missing deny is the dangerous failure.

## Common pitfalls

> [!WARNING]
> - **Leaving `UNANIMOUS` when you want either policy to pass.** Use `AFFIRMATIVE`.
> - **Switching to `PERMISSIVE` to make an error go away.** It opens every unprotected resource.
> - **Testing only the allowed user.** Test a user who must be denied.
> - **Putting secrets in script policies.** The feature is off by default for good reasons.
