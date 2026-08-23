---
name: unleash-lifecycle
description: Start, stop and troubleshoot the Unleash feature-flag stack. Use when the user asks to make up/down/stop/restart, edit flags-as-code, check the seeded toggles or health endpoints, or fix an unhealthy Unleash/Postgres container.
---

# Unleash lifecycle

- `make up` — start Unleash + private Postgres (imports the seed)
- `make all` — `setup` + `up` + `validate`
- `make validate` — containers, health endpoint, UI, seeded flag
- `make down` — stop and remove containers
- `make stop` / `make restart` — stop without removing / down + up
- `make ps` — container status
- `make logs` — follow logs
- `make clean` — `down -v` + remove `.env`

## Health checks

- `curl http://127.0.0.1:4242/health` — must return `{"health":"GOOD"}`
- `curl -o /dev/null -w '%{http_code}' http://127.0.0.1:4242/` — UI 200
- `make ps` — both containers must be `healthy`

## Flags-as-code

- Seed lives in `unleash/sca-flags.json`; imported on startup with
  KEEP_EXISTING=true. Edit → `make restart`.
- Durable definitions belong in the file; UI edits are experimentation only.

## Troubleshooting

- First-boot restart loop: Postgres still initializing — wait out the 45s
  start_period, then `docker logs unleash`.
- Login rejected: creds come from Vault — re-run `make env`.
- Flag changes missing: import runs at startup — restart after editing.
- DB auth errors after rotation: rotate both secrets and recreate the volume:
  `FORCE=1 make vault-secrets && make clean && make all`.
- `make env` fails: Vault not running/unsealed — `cd ../vault && make up &&
  make unseal`; missing AppRole creds — run `make vault-secrets` first.
