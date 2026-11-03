# Client Registration Policies

Registration policies are checks that Keycloak runs on every request to the registration endpoints. They are **realm settings**, and they come in two sets: one for **anonymous** requests (no token or an initial access token) and one for **authenticated** requests (a bearer token of an account). They apply only to the registration endpoints, not to the admin console.

## The built-in policies

| Policy | What it checks |
| --- | --- |
| Trusted Hosts | The caller's host, and optionally that every redirect URI is on a trusted host |
| Allowed Client Scopes | Which client scopes the new client may have |
| Allowed Protocol Mapper Types | Which mapper types the new client may use |
| Max Clients | How many clients the realm may hold before registration stops |
| Consent Required | Forces consent on the new client |
| Full Scope Disabled | Turns off full scope allowed on the new client |
| Client Disabled | Creates the client disabled, so an administrator must enable it |

A realm starts with a default set. Look at it:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=reg-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm get components -r inventory -q type=org.keycloak.services.clientregistration.policy.ClientRegistrationPolicy --fields name,providerId,subType
```

Each entry is a component. Its `subType` is `anonymous` or `authenticated`.

## Trusted hosts

The Trusted Hosts policy has three settings: the list of trusted hosts, whether the host sending the request must match, and whether the client URIs must match. With "client URIs must match" on, a request whose redirect URI points to a host outside the list is rejected. With "host sending the request must match" on, the caller itself must come from a trusted host or address.

A trusted host entry is a name or an address. The default list holds `localhost` and the address of the server. For a real partner you list the partner's domain and nothing else.

## Allowed scopes and mapper types

**Allowed Client Scopes** stops a registered client from asking for powerful scopes. **Allowed Protocol Mapper Types** stops a client from adding a mapper that could write sensitive data into tokens, such as a script mapper. The default list is conservative; widen it only when you can say why.

## What happens when a policy fails

The request is rejected with an error such as `invalid_client_metadata` or `forbidden`, and no client is created. The server log names the policy. Because the policy sits on the endpoint, the same client created through the admin API is not blocked by it. If you need rules that also apply to the admin API, use client policies, which the next part covers.

## Common pitfalls

> [!WARNING]
> - **Editing the authenticated set when the caller is anonymous.** The two sets are separate; check the `subType`.
> - **Putting `*` or a broad domain in the trusted hosts.** Every redirect URI on that domain becomes valid.
> - **Expecting registration policies to protect the admin API.** They apply to the registration endpoints only.
> - **Leaving Max Clients at a high value.** A flood of registrations can fill a realm.
