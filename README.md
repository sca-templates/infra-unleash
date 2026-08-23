# Unleash

Feature flag management for the platform: toggles live as code in this repo ([unleash/sca-flags.json](unleash/sca-flags.json)), are imported on startup, and are consumed by first-party services through the Unleash SDKs.

> **Status: local dev stack.** Production is declared in [infra-kubernetes](https://github.com/sca-templates/infra-kubernetes).

## Stack

| Container | Image | Host port | Purpose |
| --- | --- | --- | --- |
| unleash | `unleashorg/unleash-server:6.4.1` | 4242 (loopback) | Flag server: UI, admin + frontend APIs |
| unleash-postgres | `postgres:16-alpine` | none (internal) | Private state |

Bridge network internal to the stack; only the server publishes `127.0.0.1:4242`.

## Quick start

```sh
make all        # setup + up + validate
```

First time requires Vault running and unsealed (`cd ../vault && make up && make unseal`): `make setup` registers the AppRole, stores the generated admin and DB passwords, and generates `.env`. The UI login uses those credentials (`secret/unleash/dev`).

```sh
curl -s http://127.0.0.1:4242/health    # → {"health":"GOOD"}
```

## Flags-as-code

- [`unleash/sca-flags.json`](unleash/sca-flags.json) is the seed: imported on every startup with `UNLEASH_IMPORT_KEEP_EXISTING=true`, so repo-defined flags converge while runtime-created ones survive.
- Edit the file, `make restart`, done — the toggle appears with its strategies per environment.
- Runtime changes in the UI are for experimentation; durable definitions belong in this file.

## Commands

`make help`

| Target | Description |
| --- | --- |
| `make setup` | Vault secrets + `.env` (idempotent) |
| `make all` | `setup` + `up` + `validate` |
| `make up` / `make down` | Start / stop and remove |
| `make validate` | Containers, health, UI, seeded flag |
| `make vault-secrets` | Store admin/DB passwords + bootstrap AppRole |
| `make env` | Generate `.env` from Vault (`chmod 600`) |
| `make restart` / `stop` | Restart / stop without removing |
| `make logs` / `ps` / `clean` | Logs, status, cleanup (+ volume) |

## Validation & CI

- `make validate`: both containers healthy, `/health` GOOD, UI reachable, seeded `sca-demo-flag` visible through the public frontend API.
- CI (`.github/workflows/validate.yml`): shellcheck, compose config, seed-file schema checks, `.env.example` completeness, markdownlint + link check.

## Troubleshooting

- **Restart loop on first boot**: Postgres is still initializing — the server waits out a 45s `start_period`; check `docker logs unleash`.
- **Login rejected**: credentials come from Vault — `cat .env | grep UNLEASH_ADMIN` or re-run `make env`.
- **Flag edits not appearing**: the import runs at startup — `make restart` after editing the seed.
- **DB auth errors after rotation**: rotate both secrets together (`FORCE=1 make vault-secrets && make clean && make all`) — the old DB password is baked into the volume.

## Connections

- [infra-keycloak](https://github.com/sca-templates/infra-keycloak) / [infra-kong](https://github.com/sca-templates/infra-kong) — first consumers pattern: services gate features by account-type roles + flags.
- [infra-vault](https://github.com/sca-templates/infra-vault) — source of the admin and DB passwords (AppRole `unleash`).
- [infra-loki](https://github.com/sca-templates/infra-loki) — container logs shipped by Promtail.
- [infra-kubernetes](https://github.com/sca-templates/infra-kubernetes) — declares the production deployment.

## License

MIT — see [LICENSE](LICENSE).
