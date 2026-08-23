---
description: Run the full Unleash validation suite (containers, health, seeded flag).
agent: build
---

# Validate

Run `make validate` from the repo root and report the result.
`validate.sh` checks both containers' health, the `/health` endpoint, UI
reachability and that the seed flag `sca-demo-flag` is served by the public
frontend API. If a check fails, isolate it with the individual curls in the
`unleash-lifecycle` skill and fix it, then re-run.
