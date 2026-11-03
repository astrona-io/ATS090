# Attributes, Roles And Single Logout

The name ID says who the user is. Attributes say more: email, name, roles. A SAML client gets them through **protocol mappers**, the same idea as for OpenID Connect with different mapper types.

## SAML mappers

| Mapper type | Writes |
| --- | --- |
| `saml-user-property-mapper` | A user property such as `email` as an attribute |
| `saml-role-list-mapper` | The user's roles as one attribute |
| `saml-group-membership-mapper` | The user's groups as an attribute |
| `saml-hardcode-attribute-mapper` | A fixed attribute value |

Each mapper has an `attribute.name`, the name the SP reads, and an `attribute.nameformat` such as `Basic`. Add mappers to the billing client:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=saml-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
CLIENT_ID=$(kcadm get clients -r inventory -q clientId=urn:app:billing --fields id --format csv --noquotes | tr -d '\r')
kcadm create "clients/$CLIENT_ID/protocol-mappers/models" -r inventory \
  -s name=email -s protocol=saml -s protocolMapper=saml-user-property-mapper \
  -s 'config."user.attribute"=email' -s 'config."attribute.name"=email' \
  -s 'config."friendly.name"=email' -s 'config."attribute.nameformat"=Basic'
kcadm create "clients/$CLIENT_ID/protocol-mappers/models" -r inventory \
  -s name=roles -s protocol=saml -s protocolMapper=saml-role-list-mapper \
  -s 'config."attribute.name"=Role' -s 'config."attribute.nameformat"=Basic' -s 'config."single"=false'
kcadm get "clients/$CLIENT_ID/protocol-mappers/models" -r inventory --fields name,protocolMapper
```

The role list mapper writes the realm roles of the user, such as `billing-user`, into the attribute `Role`. With `single` false each role is its own attribute value; with `single` true all roles are in one value. The SP documentation says which one it reads. Roles reach the assertion only if the client's role scope allows them, as with OpenID Connect: Full Scope Allowed and scope mappings apply.

## Single logout

**Single logout** (SLO) ends the session at the IdP and at every SP that took part. The client settings are `saml_single_logout_service_url_post` and `saml_single_logout_service_url_redirect`, the addresses where Keycloak sends a `LogoutRequest` to the SP. When the user logs out at one SP, the SP sends a `LogoutRequest` to Keycloak. Keycloak ends the session and sends logout requests to the other SPs that have a logout address.

If a client has no logout address, Keycloak cannot tell that SP, and the user stays signed in there. With front-channel logout on (`frontchannelLogout=true`), which is the default for SAML clients, the browser carries the messages.

You now have a full picture: the SP is a client with the right entity ID and ACS address, the assertion is signed, and attributes and logout are configured through mappers and addresses.

## Common pitfalls

> [!WARNING]
> - **Mapping the role attribute under another name.** The SP looks for its own name and finds no role.
> - **Expecting roles in the assertion when the role scope excludes them.** Check the client scope mappings.
> - **No logout address on a client.** That SP never learns of a logout.
> - **Sending too many attributes.** Send only what the SP needs.
