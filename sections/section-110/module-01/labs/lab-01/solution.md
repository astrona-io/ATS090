# Solution: Enforce PKCE With A Client Policy

Work the task yourself first. Running `astrona submit -c sections/section-110/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

## Step 1: Read the profile and the policy

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

The policy `public-clients` names the profile `strict-public`, but its `enabled` value is `false`.

## Step 2: Test a client

```sh
kcadm create clients -r inventory -s clientId=probe -s publicClient=true -s standardFlowEnabled=true
kcadm get clients -r inventory -q clientId=probe --fields attributes
```

The attribute is missing. Delete the test client with `kcadm delete clients/<id> -r inventory`.

## Step 3: Enable the policy

```sh
kcadm update client-policies/policies -r inventory -n \
  -b '{"policies":[{"name":"public-clients","description":"PKCE for all clients","enabled":true,"profiles":["strict-public"],"conditions":[{"condition":"any-client","configuration":{}}]}]}'
```

## Step 4: Test again

Create the test client again and read the attribute. It is now `S256`. Delete the test client. Run `astrona submit` to grade the lab.
