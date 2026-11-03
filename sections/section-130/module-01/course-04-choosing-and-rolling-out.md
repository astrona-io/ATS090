# Choosing And Rolling Out

Both methods bind a token to a key. The choice depends on where the client runs and who controls the network.

## Compare

| Question | DPoP | mTLS |
| --- | --- | --- |
| Works in a browser or mobile app | Yes | Rarely |
| Needs HTTPS client certificates | No | Yes |
| Survives a TLS-ending proxy | Yes, since the proof is in the request | Only if the proxy forwards the certificate |
| Cost per request | One signature | None beyond the handshake |
| Work at the resource server | Verify the proof and the `ath` hash | Compare the certificate thumbprint |

A good default for new public-facing APIs is DPoP. For service-to-service calls with a mesh that already issues certificates, mTLS is natural.

## The resource server must take part

Binding only works if the resource server checks the proof or the certificate. A resource server that accepts a DPoP token as a bearer token gets no benefit. Check the libraries you use: they must read the `DPoP` scheme, check `htm`, `htu`, `ath` and `jti`, and compare the key thumbprint with `cnf.jkt`.

## A rollout plan

1. **Inventory** the clients and the APIs they call.
2. **Prepare the resource servers** so they can verify proofs before any client changes.
3. **Update one client** to send proofs, then require binding on that client.
4. **Keep lifetimes short** for access tokens.
5. **Repeat** client by client; do not switch a whole realm in one step.
6. **Monitor** the rejected requests after each change.

Read which clients require binding:

<!-- astrona:playground:renew -->

```sh
NAMESPACE=bound-demo
kcadm() {
  kubectl -n "$NAMESPACE" exec -i deploy/keycloak -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master --user admin --password admin
kcadm get clients -r inventory --fields clientId,attributes
```

## Common pitfalls

> [!WARNING]
> - **Requiring binding on a client before its software supports it.** Test with a non-production client first.
> - **Skipping the resource server work.** Issuing bound tokens that are accepted as bearer tokens gains nothing.
> - **Leaving a long access token lifetime.** Binding and short lifetimes work together.
> - **Switching every client at once.** One broken client is easier to find than fifty.
