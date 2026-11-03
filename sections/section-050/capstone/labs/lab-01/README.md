---
estimated_duration: 30m
---

# Secure The Service Clients Of A Realm

- **ID:** LAB
- **Slug:** ats-090-capstone-050
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Graded lab for the namespace `m2m-demo`. Read `question.md` for the task; `solution.md` is the walkthrough.

> **Not yet run.** This lab was written from the Keycloak 26.8.1 documentation
> and has not passed `astrona test` yet.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-090-capstone-050
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-090-capstone-050`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | Environment preparation run once at startup |
| `manifests/` | Starting workloads applied by the bootstrap |
| `solution/` | Reference solution used by `astrona test` |
| `testing/` | Helpers `astrona test` runs before the reference solution |
| `validation/` | Grading scripts, one per check |
