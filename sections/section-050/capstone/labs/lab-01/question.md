# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Service clients

## Scenario

Two jobs read the inventory API. The reporting job uses the client `inventory-reporter`. Last week its secret, `leaked-secret`, was pasted into a chat room. The security team wants it replaced. The same job has also been failing since someone changed how the client authenticates. The synchronisation job uses `inventory-sync`, which was created as a public client and cannot get a token at all.

The realm `inventory` runs in the namespace `m2m-demo`. The API needs the realm role `inventory-reader` in each token.

## Your task

In the realm `inventory`:

1. Find why `inventory-reporter` cannot get a token with its secret, and fix it.
2. Replace the leaked secret with a new one. The old value must stop working.
3. Make sure the token of `inventory-reporter` carries `inventory-reader`.
4. Make `inventory-sync` a confidential service client that gets a token with the client credentials grant, and give it `inventory-reader`.

## Constraints

- Do not give any service account the role `inventory-admin`.
- Do not create new clients and do not delete the existing ones.
- Do not change the secret of `inventory-reporter` back to `leaked-secret`.

## Done when

- `leaked-secret` no longer gets a token for `inventory-reporter`, and the new secret does.
- The token of `inventory-reporter` and the token of `inventory-sync` both carry `inventory-reader` and neither carries `inventory-admin`.
- `inventory-sync` is confidential, has a secret and gets a token with the client credentials grant.
