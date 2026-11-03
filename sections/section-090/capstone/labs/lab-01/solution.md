# Solution: Secure A SAML Service Provider

Work the task yourself first. Running `astrona submit -c sections/section-090/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

## Step 1: Read the client and its mappers

```sh
NAMESPACE=saml-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
CLIENT_ID=$(kcadm get clients -r inventory -q clientId=urn:app:billing --fields id --format csv --noquotes | tr -d '\r')
kcadm get "clients/$CLIENT_ID" -r inventory --fields redirectUris,attributes
kcadm get "clients/$CLIENT_ID/protocol-mappers/models" -r inventory
```

## Step 2: Restrict the address and sign the assertion

```sh
kcadm update "clients/$CLIENT_ID" -r inventory \
  -s 'redirectUris=["https://billing.example.com/saml/acs"]' \
  -s 'attributes."saml.assertion.signature"=true'
```

## Step 3: Add the email mapper

```sh
kcadm create "clients/$CLIENT_ID/protocol-mappers/models" -r inventory \
  -s name=email -s protocol=saml -s protocolMapper=saml-user-property-mapper \
  -s 'config."user.attribute"=email' -s 'config."attribute.name"=email' \
  -s 'config."friendly.name"=email' -s 'config."attribute.nameformat"=Basic'
```

## Step 4: Rename the role attribute

```sh
MAPPER_ID=$(kcadm get "clients/$CLIENT_ID/protocol-mappers/models" -r inventory --fields id,name --format csv --noquotes | tr -d '\r' | awk -F, '$2 == "roles" {print $1}')
kcadm update "clients/$CLIENT_ID/protocol-mappers/models/$MAPPER_ID" -r inventory -s 'config."attribute.name"=Role'
```

Run `astrona submit` to grade the capstone.
