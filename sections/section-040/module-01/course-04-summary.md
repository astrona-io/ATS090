# Summary

A user's request often passes a gateway before it reaches an API, and each service must receive a token meant for it. This module followed `alice`'s token through a gateway and set up the hand-over with standard token exchange.

## What you learned

A gateway that forwards a request passes the `Authorization` header unchanged, so the next service receives a token meant for the gateway and refuses it at the audience check. Adding every API to the client's audience makes the request work, but the client can then bypass the gateway, and a token leaked by one service works on all of them.

Standard token exchange (RFC 8693) gives the gateway a new token instead. The gateway, a confidential client, sends the token it received as `subject_token` to the token endpoint, with the grant type `urn:ietf:params:oauth:grant-type:token-exchange`. Keycloak 26 allows it for a client with the **Standard token exchange** switch on. Two rules decide the result: the subject token's `aud` must contain the requesting client, and the new token can only carry audiences that are already available to the requester through its audience mappers or client scopes. The new token keeps the user's `sub` and roles, names the gateway as `azp`, and names the API in `aud`.

The `audience` parameter only filters. Without it, the new token names everything available to the gateway; with it, only the API that will receive it. That is downscoping. An audience that is not available gives an error, and a missing role still gives `403` at the API. The key facts to remember are these:

- Each hop gets a token meant for the next service only.
- Only a confidential client with standard token exchange allowed may exchange.
- The subject token must name the requester; the requester must already have the audience.
- Always send `audience` when the gateway may call more than one API.

<!-- astrona:playground:destroy -->
