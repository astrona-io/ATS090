# Solution: Lock Down Partner Client Registration

Work the task yourself first. Running `astrona submit -c sections/section-110/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

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

The policy `partners` has an empty list of profiles, so no rule applies. The profile `partner-baseline` has only `pkce-enforcer`; it has no executor that rejects the password grant.

## Step 2: Add the executor to the profile

```sh
kcadm update client-policies/profiles -r inventory -n \
  -b '{"profiles":[{"name":"partner-baseline","description":"Rules for partner clients","executors":[{"executor":"pkce-enforcer","configuration":{"auto-configure":true}},{"executor":"reject-ropc-grant","configuration":{}}]}]}'
```

## Step 3: Attach the profile to the policy

```sh
kcadm update client-policies/policies -r inventory -n \
  -b '{"policies":[{"name":"partners","description":"Baseline for every client","enabled":true,"profiles":["partner-baseline"],"conditions":[{"condition":"any-client","configuration":{}}]}]}'
```

## Step 4: Test

Create a public client and read its attributes; the PKCE method is `S256`. Try to create a client with `directAccessGrantsEnabled` true; it is rejected. Create an initial access token with `kcadm create clients-initial-access -r inventory -s count=1 -s expiration=600 -o`, register a normal client with it, and delete your test clients. Run `astrona submit` to grade the capstone.
