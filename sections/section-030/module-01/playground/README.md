# Validate Access Tokens In An API — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-090-playground-030-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A single sandbox environment that spins up, deploys Keycloak 26.8.1 in the
namespace `tokens-demo`, creates the realm inventory, the user alice with the realm role inventory-reader, the clients inventory-cli, inventory-reporter and inventory-api, and stays running so you can
explore the module's topic. Nothing to submit.

> **Not yet run.** This playground was written from the Keycloak 26.8.1
> documentation and has not been started yet.

## Run it

```sh
astrona run -c .
astrona destroy ats-090-playground-030-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-090-playground-030-01`), not
the config path. `astrona submit` and `astrona test` do not apply — there is no
grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | Deploys the workloads and creates the realm, user and clients |
| `manifests/lab-start.yaml` | Namespace, Keycloak, tester and the module's API workloads |
| `docs/overview.md` | What the environment contains and ideas to try |
