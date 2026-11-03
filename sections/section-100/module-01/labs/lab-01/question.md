# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Authorization services

## Scenario

The client `invoice-api` in the realm `inventory` is a resource server. It protects the resource `invoice` with the scopes `view` and `edit`. The permission `invoice-view` should let users with the realm role `finance` view invoices. `alice` has the role `finance`, `bob` has no role. But `alice` is denied.

Keycloak runs in the namespace `authz-demo`. The users have the passwords `alice-password` and `bob-password`.

## Your task

In the realm `inventory`:

1. Request the permission `invoice#view` for `alice` and for `bob` with the UMA ticket grant and the audience `invoice-api`, using `response_mode=decision`.
2. Find out why `alice` is denied: read the permission and its policy.
3. Fix the policy so that the role `finance` passes.
4. Request the permission again for `alice`, `bob`, and `invoice#edit`.

## Constraints

- Keep the resource server in `ENFORCING` mode.
- Do not add a permission for `edit`.
- Do not give `bob` the role `finance`.

## Done when

- `alice` is allowed `invoice#view`.
- `bob` is denied `invoice#view`.
- `alice` is denied `invoice#edit`.
- The resource server is in `ENFORCING` mode.
