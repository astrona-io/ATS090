# Question

Solve this question on: `terminal`

**Time:** about 15 minutes · **Topic:** Protocol mappers

## Scenario

A new inventory API reads two claims from the access token: `groups`, the names of the user's groups, and `tenant`, which must be `outpost` for every caller of this client. The client `inventory-cli` in the realm `inventory` sends neither claim. The user `alice` is a member of the group `logistics`.

Keycloak runs in the namespace `scopes-demo`. The user `alice` has the password `alice-password`.

## Your task

In the realm `inventory`:

1. Sign in as `alice` with the password grant and decode the access token. Confirm that `groups` and `tenant` are missing.
2. Add a group membership mapper to the client `inventory-cli`. It writes the claim `groups`, with group names and not full paths.
3. Add a hardcoded claim mapper to the same client. It writes the claim `tenant` with the value `outpost`.
4. Make sure `tenant` appears in the access token only, not in the ID token.

## Constraints

- Add the mappers to the client `inventory-cli`. Do not change the realm, the user or the group.
- Do not use Full Scope Allowed or role settings for this task.

## Done when

- The access token for `alice` has `groups` containing `logistics`.
- The access token has `tenant` with the value `outpost`.
- The ID token has no `tenant` claim.
