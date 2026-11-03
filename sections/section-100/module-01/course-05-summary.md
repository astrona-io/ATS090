# Summary

Authorization Services moves fine-grained decisions into Keycloak. A client with the feature on is a resource server that holds resources, scopes, policies and permissions.

## What you learned

A resource is something protected, and a scope is an action on it. A policy decides yes or no for a user with a type such as role, user, group or time, and a logic that can invert the result. A permission joins a resource or scopes to policies. What no permission covers is denied while the server is in `ENFORCING` mode.

A client asks for a decision with the UMA ticket grant at the token endpoint: the user's access token as bearer, the resource server as audience and `resource#scope` as permission. With `response_mode=decision` the answer is `200` or `403`; without it the answer is a Requesting Party Token with an `authorization` claim. Decision strategies `UNANIMOUS`, `AFFIRMATIVE` and `CONSENSUS` combine results. The key facts to remember are these:

- Default is deny; test a user who must be denied.
- Check the logic of a policy when a decision is inverted.
- Use `AFFIRMATIVE` when either policy is enough.
- Keep the server in `ENFORCING` mode.

<!-- astrona:playground:destroy -->
