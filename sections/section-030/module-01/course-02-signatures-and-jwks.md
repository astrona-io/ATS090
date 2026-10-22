# Signatures, The JWKS And Key Rotation

The signature check needs Keycloak's public key, and the API needs it without asking Keycloak on every request. Keycloak publishes its keys at a fixed address, and every token says which key signed it. This part follows that link from a token's header to a key, proves that a changed token fails, and rotates the realm's key to show how the API keeps up.

## The header and the key set

A JWT's first part, the **header**, says how the token was signed: `alg` is the algorithm and `kid` is the **key ID**, the name of the key in the realm. Keycloak publishes the public keys of the realm as a **JSON Web Key Set (JWKS)** at `/realms/<realm>/protocol/openid-connect/certs`. The API loads that set once, keeps it in memory, and picks the key whose `kid` matches the token's header.

Define the helpers again if this is a new terminal, then decode the header of a fresh token and list the realm's keys:

<!-- astrona:playground:renew -->

```sh
get_alice_token() {
  kubectl -n tokens-demo exec deploy/tester -- sh -c '
    curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=password -d client_id=inventory-cli \
      -d username=alice -d password=alice-password -d scope=openid \
    | jq -r .access_token'
}
call_api() {
  kubectl -n tokens-demo exec deploy/tester -- \
    curl -s -w '\nHTTP %{http_code}\n' -H "Authorization: Bearer $1" http://inventory-api:8080/items
}
TOKEN=$(get_alice_token)
printf '%s' "$TOKEN" | jq -R 'split(".")[0] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson'
kubectl -n tokens-demo exec deploy/tester -- \
  curl -s http://keycloak:8080/realms/inventory/protocol/openid-connect/certs \
  | jq '.keys[] | {kid, kty, alg, use}'
```

The header has `alg` set to `RS256`, an RSA signature over a SHA-256 hash, and a `kid`. The key set lists at least one key with `kty` set to `RSA` and `use` set to `sig`, and one of them has the same `kid` as the header. Its other fields, `n` and `e`, are the RSA public key itself. Keycloak may list keys for other uses as well, such as encryption; the API only takes signing keys.

## A changed token fails

The signature covers the header and the payload together. To see that, change one claim of a real token and send it. The commands below replace `alice` with `admin` in the payload, keep the original signature, and call the API:

```sh
HEADER=$(printf '%s' "$TOKEN" | cut -d. -f1)
SIGNATURE=$(printf '%s' "$TOKEN" | cut -d. -f3)
PAYLOAD=$(printf '%s' "$TOKEN" | jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson | .preferred_username = "admin" | tojson' -r \
  | base64 | tr -d '\n=' | tr '+/' '-_')
call_api "$HEADER.$PAYLOAD.$SIGNATURE"
call_api "$TOKEN"
```

The changed token gets `401` with the reason that the token signature does not verify. The original token gets `401` too, but with the audience reason: its signature passed, and the API moved on to the next check. The API's log shows the two reasons one after the other.

## Key rotation

A realm's signing key is not forever. An administrator adds a new key, Keycloak signs new tokens with it, and the old key is removed once the tokens it signed have expired. That is a **key rotation**. In Keycloak, keys come from **key providers**, and the active provider with the highest **priority** signs new tokens.

An API that loaded the JWKS once would refuse every token signed with the new key. `inventory-api` does what a well-built API does: when a token names a `kid` it does not know, it loads the JWKS again. Rotate the key to see it. First sign `kcadm.sh`, Keycloak's administration command-line tool, in to the `master` realm; it runs inside the Keycloak pod:

```sh
NAMESPACE=tokens-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
REALM_ID=$(kcadm get realms/inventory --fields id --format csv --noquotes | tr -d '\r')
```

Add a new RSA key provider with a higher priority than the default one, which has priority `100`:

```sh
kcadm create components -r inventory -s name=rsa-rotated -s providerId=rsa-generated \
  -s providerType=org.keycloak.keys.KeyProvider -s parentId="$REALM_ID" \
  -s 'config.priority=["200"]' -s 'config.keySize=["2048"]' -s 'config.algorithm=["RS256"]'
NEW_TOKEN=$(get_alice_token)
printf '%s' "$NEW_TOKEN" | jq -R 'split(".")[0] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson | .kid'
call_api "$NEW_TOKEN"
call_api "$TOKEN"
```

The new token's `kid` is different from the old one. The API still gets past the signature check for both tokens and stops at the audience check: for the new token, it loaded the JWKS again and found the new key; for the old token, the old key is still in the set. Both keys stay published until an administrator disables or deletes the old provider, which is what lets tokens signed before the rotation keep working until they expire.

You now know how the API connects a token to Keycloak's public key, why a changed token fails, and how a rotation works without breaking either the API or tokens already issued. Every token in this part still failed for one reason: its audience. That is the next thing to fix, and it is a setting in Keycloak.

## Common pitfalls

> [!WARNING]
> - **Copying the public key into the API's configuration.** The first key rotation breaks the API. Load the JWKS from the realm, and load it again for an unknown `kid`.
> - **Deleting the old key provider right after a rotation.** Tokens it signed fail at once. Wait until they have expired.
> - **Trusting the `alg` in the header without a list.** An API should accept only the algorithms it expects, such as `RS256`.
> - **Loading the JWKS for every request.** It adds a request to Keycloak per call. Cache it and refresh on an unknown `kid`.
