# SAML Clients And Name IDs

A SAML client in Keycloak is the record of one service provider. Three settings decide whether a sign-in reaches the right place, and a fourth decides what the SP calls the user.

## Create the client

The client ID must equal the entity ID that the SP puts into its `AuthnRequest`. The valid redirect URIs list the ACS addresses that Keycloak may send the response to. Create a client for the billing application:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=saml-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm create clients -r inventory -s clientId=urn:app:payroll -s protocol=saml -s enabled=true \
  -s 'redirectUris=["https://payroll.example.com/saml/acs"]' \
  -s 'attributes."saml_assertion_consumer_url_post"=https://payroll.example.com/saml/acs' \
  -s 'attributes."saml_name_id_format"=username'
kcadm get clients -r inventory -q clientId=urn:app:payroll --fields clientId,protocol,redirectUris,attributes
```

`saml_assertion_consumer_url_post` is the ACS address for the POST binding. A request that names an ACS address not in the redirect URI list is refused, in the same way a wrong redirect URI is refused for OpenID Connect. A wildcard `*` in the list lets a forged request steal the assertion, so list exact addresses.

## The name ID

The **name ID** is the identifier of the user in the assertion. The attribute `saml_name_id_format` chooses its kind:

| Value | The name ID is |
| --- | --- |
| `username` | The Keycloak user name |
| `email` | The user's email address |
| `persistent` | A stable, opaque identifier unique to this SP |
| `transient` | A random value that changes on every sign-in |

The SP decides which format it understands. An application that finds users by email breaks when it receives `transient`. Set `email` and read it back:

```sh
CLIENT_ID=$(kcadm get clients -r inventory -q clientId=urn:app:payroll --fields id --format csv --noquotes | tr -d '\r')
kcadm update "clients/$CLIENT_ID" -r inventory -s 'attributes."saml_name_id_format"=email'
kcadm get "clients/$CLIENT_ID" -r inventory --fields attributes
```

Another attribute, `saml_force_name_id_format`, forces the client setting even when the SP asks for a different format in its request.

## Bindings and IdP-initiated sign-in

The attribute `saml.force.post.binding` makes Keycloak always answer through the POST binding. An IdP-initiated flow needs the attribute `saml_idp_initiated_sso_url_name`: its value becomes a path under `/realms/<realm>/protocol/saml/clients/` that signs the user in and sends an unrequested assertion to the SP. Leave it empty when the SP always starts the sign-in, which is safer because there is no request to match.

You can create a client in one step by importing the SP's own metadata. Keycloak reads the entity ID, the ACS addresses and the certificate from the SP descriptor, which saves typing and mistakes.

You now know what a SAML client holds and what the name ID is. The next part covers what is signed.

## Your mission: Fix A SAML Client Lab

The mission starts from a SAML client whose assertions are not signed and whose name ID changes on every sign-in. You fix both.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-090-playground-090-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS090.git -c sections/section-090/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-090/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-090-lab-090-01
astrona start ats-090-playground-090-01
```

## Common pitfalls

> [!WARNING]
> - **A client ID that differs from the SP's entity ID.** Keycloak answers that the client was not found.
> - **A wildcard in the valid redirect URIs.** It lets an attacker choose where the assertion goes.
> - **Using `transient` when the SP matches users by name.** Every sign-in creates a new user in the SP.
