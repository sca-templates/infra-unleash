---
description: Start the Unleash stack (compose up) and confirm the seed is imported.
agent: build
---

# Up

Run `make up` from the repo root and confirm the server is healthy
(`curl http://127.0.0.1:4242/health` must return `{"health":"GOOD"}`); the
first start waits out a 45s healthcheck `start_period`.
