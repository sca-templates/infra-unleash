#!/usr/bin/env bash
#
# validate.sh — Verify the Unleash stack: both containers healthy, health
# endpoint answering, UI reachable, and the flags-as-code seed imported
# (the seeded toggle appears in the public state endpoint).
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/../compose.yml"
PROJECT_NAME=unleash

PASS=0
FAIL=0

ok()   { echo "[OK]   $1"; PASS=$((PASS+1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL+1)); }

# ── 1. Containers healthy ─────────────────────────────────────────────────────
STATES="$(docker compose -f "${COMPOSE_FILE}" -p "${PROJECT_NAME}" ps --format '{{.Name}} {{.Health}}' 2>/dev/null)"
for name in unleash unleash-postgres; do
    STATE="$(echo "${STATES}" | awk -v n="${name}" '$1==n{print $2}')"
    if [[ "${STATE}" == "healthy" ]]; then
        ok "Container ${name} is healthy"
    else
        fail "Container ${name} health='${STATE:-missing}' (expected healthy)"
    fi
done

# ── 2. Health endpoint ────────────────────────────────────────────────────────
BODY="$(curl -s "http://127.0.0.1:${UNLEASH_PORT:-4242}/health" || true)"
if echo "${BODY}" | grep -q '"health":"GOOD"'; then
    ok "Health endpoint reports GOOD"
else
    fail ":${UNLEASH_PORT:-4242}/health returned '${BODY}'"
fi

# ── 3. UI reachable ───────────────────────────────────────────────────────────
HTTP_CODE="$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:${UNLEASH_PORT:-4242}/" || true)"
if [[ "${HTTP_CODE}" == "200" ]]; then
    ok "UI answers on :${UNLEASH_PORT:-4242}"
else
    fail "UI :${UNLEASH_PORT:-4242}/ returned '${HTTP_CODE}'"
fi

# ── 4. Flags-as-code seed imported (public frontend API) ──────────────────────
TOGGLES="$(curl -s "http://127.0.0.1:${UNLEASH_PORT:-4242}/api/frontend/getAll" \
    -H 'unleash-appname: sca-validate' -H 'unleash-clientid: validate' || true)"
if echo "${TOGGLES}" | grep -q 'sca-demo-flag'; then
    ok "Seed flag 'sca-demo-flag' present (flags-as-code pipeline works)"
else
    fail "Seed flag 'sca-demo-flag' missing from frontend API (import failed?)"
fi

echo ""
echo "=== Validation complete: ${PASS} passed, ${FAIL} failed ==="
exit "${FAIL}"
