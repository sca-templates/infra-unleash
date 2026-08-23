# unleash — Feature flag management

## What this repo is

Feature flag management: toggles live as code in this repo (`unleash/sca-flags.json`), are imported on startup, and are consumed by first-party services through the Unleash SDKs. **Local dev stack** — production is declared in [infra-kubernetes](https://github.com/sca-templates/infra-kubernetes).

## Skills

| Skill | Use for |
| --- | --- |
| [`unleash-lifecycle`](.claude/skills/unleash-lifecycle/SKILL.md) | up/down/restart, flags-as-code edits, seeded toggles, unhealthy container |

## Reference

> Reference: <https://github.com/sca-templates/sca-docs>

Ecosystem conventions and infrastructure notes live there; consult them
before documenting or touching topology/ports/networks:

- `00-ecosystem/conventions.md` — repo layout, ports, naming, commit style.
- `04-infrastructure/unleash.md` — canonical note for this component.

Keep the vault in sync when this repo changes.

## Commands

```sh
make help        # all targets
make all         # setup + up + validate
make validate    # containers, health endpoint, UI, seeded flag
```

## Conventions (strict)

- English only.
- Conventional commits (`feat(flags): ...`, `fix(scripts): ...`, `docs(readme): ...`).
- Docs-as-code: every change through PR + review.
- Never commit `.env`, `.secrets/` or any secret material.
- Flags-as-code is the SSOT: durable definitions go in `unleash/sca-flags.json`, not the UI.
- Run `make validate` before finishing changes that affect the stack.
