# Solution: Fix A SAML Client

Work the task yourself first. Running `astrona submit -c sections/section-090/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

## Step 1: Read the client

```sh
NAMESPACE=saml-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
CLIENT_ID=$(kcadm get clients -r inventory -q clientId=urn:app:billing --fields id --format csv --noquotes | tr -d '\r')
kcadm get "clients/$CLIENT_ID" -r inventory --fields attributes
```

`saml.assertion.signature` is `false` and `saml_name_id_format` is `transient`.

## Step 2: Fix both attributes

```sh
kcadm update "clients/$CLIENT_ID" -r inventory \
  -s 'attributes."saml.assertion.signature"=true' \
  -s 'attributes."saml_name_id_format"=email'
```

## Step 3: Read it back

```sh
kcadm get "clients/$CLIENT_ID" -r inventory --fields attributes,redirectUris
```

Both attributes show the new values, and the redirect URI list is unchanged. Run `astrona submit` to grade the lab.
