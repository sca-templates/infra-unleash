# Contributing to infra-unleash

> Feature flag management — flags-as-code seed imported on startup, consumed by first-party services via SDKs. Docs-as-code: all changes land through a PR with review.

## Ground rules

- **English only** — notes, commits, and PR descriptions are written in English.
- **No secrets in the repo** — `.env` is gitignored and generated from Vault (`secret/unleash/dev`); `.secrets/` holds the AppRole role_id/secret_id and is gitignored. Never commit tokens, role IDs or passwords.
- **Docs-as-code** — every change goes through a pull request and is reviewed.

## Repository layout

```text
compose.yml               Unleash server + private Postgres (bridge network)
unleash/sca-flags.json    Flags-as-code seed (imported on startup, SSOT)
Makefile                  help | setup | all | up | validate | vault-secrets | env | down | stop | restart | logs | ps | clean
scripts/                  vault-secrets.sh | gen-env.sh | validate.sh
.env.example              Non-secret defaults, port and secret placeholders
.github/                  CI, PR template, dependabot, markdown link-check config
```

## Changing flags

1. Edit `unleash/sca-flags.json` (export format v4) — durable definitions live here, not in the UI.
2. `make restart` to re-import.
3. Run `make validate` — the seeded flag must be served.
4. Update the README "Flags-as-code" section if the model changes.

## Contribution flow

1. Branch off `main`: `git checkout -b feat/<topic>`.
2. Create or edit the files following the conventions above.
3. Run the checks (see Tooling).
4. Open a PR and fill the checklist from the template.

## Definition of done

- [ ] Content is in English.
- [ ] Flags-as-code invariants hold (format v4, default project, strategies on enabled envs).
- [ ] No secrets or tokens are committed (`.env`, `.secrets/` stay gitignored).
- [ ] `bash -n scripts/*.sh` and `shellcheck scripts/*.sh` pass.
- [ ] `docker compose -f compose.yml config --quiet` passes.
- [ ] `make validate` passes locally.
- [ ] `markdownlint` and link check pass (CI runs them too).
- [ ] `README.md` is updated when the stack, ports or commands change.

## Tooling

```sh
# Validate (needs the stack running)
make validate

# Lint markdown
npx --yes markdownlint-cli2 README.md AGENTS.md CLAUDE.md .github/PULL_REQUEST_TEMPLATE.md .github/CONTRIBUTING.md docs/**/*.md .claude/skills/**/SKILL.md .opencode/command/*.md

# Check links in a single file (config lives in .github/)
npx --yes markdown-link-check -c .github/markdown-link-check.json <file>
```

## License

This repository is licensed under the MIT License (see [LICENSE](LICENSE)).
