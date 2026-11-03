# Summary

Every claim in a token comes from a protocol mapper, and every mapper reaches a client through a client scope or the client's dedicated scope. This module built tokens step by step and checked each change by decoding the result.

## What you learned

A client scope bundles mappers and role scope mappings and is shared by clients. A client holds a scope as default or optional. A default scope applies to every request, and an optional scope applies only when the request names it in the `scope` parameter. If an application cannot send the parameter, the scope must be a default scope.

A protocol mapper writes one claim. Its type decides the source: group membership, a user property, a custom attribute or a fixed value. Its switches decide the target: the access token, the ID token, the UserInfo response and token introspection. A missing claim usually means a switch is off, the scope is not assigned to the client, or the token was issued before the change.

Roles follow their own rule. With Full Scope Allowed on, a token holds every role of the user. With it off, a token holds only the roles that appear in both the user's roles and the client's scope mappings. The access token is read by the API, the ID token by the client application, and the UserInfo response and introspection answer on request. The key facts to remember are these:

- Decode a new token after every change.
- Optional scopes need the `scope` parameter; default scopes do not.
- Each mapper has one switch per token.
- Turn off Full Scope Allowed and map only the roles a client needs.

<!-- astrona:playground:destroy -->
