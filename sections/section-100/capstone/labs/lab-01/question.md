# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** Authorization services

## Scenario

The resource server `invoice-api` in the realm `inventory` protects the resource `report` with the scopes `read` and `delete`. The rules are: users with the role `finance` may read a report; only users with the role `report-admin` may delete one; users with no role may do neither. The users are `alice` (finance), `carol` (finance and report-admin) and `bob` (no role). The tests show that the rules are broken: `bob` can read and `alice` cannot, and `alice` can delete.

Keycloak runs in the namespace `authz-demo`. The users have the passwords `<name>-password`.

## Your task

In the realm `inventory`:

1. Request `report#read` and `report#delete` for `alice`, `bob` and `carol` with the UMA ticket grant and `response_mode=decision`.
2. Find why the read permission gives the opposite result of what is intended, and fix it.
3. Find why `alice` can delete, and make the delete permission use the policy for `report-admin`.
4. Request the six decisions again.

## Constraints

- Keep the resource server in `ENFORCING` mode.
- Do not change the roles of the users.
- Do not delete the permissions or the resource.

## Done when

- `alice` is allowed `report#read` and denied `report#delete`.
- `carol` is allowed both.
- `bob` is denied both.
- The resource server is in `ENFORCING` mode.
