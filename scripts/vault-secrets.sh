#!/usr/bin/env bash
#
# vault-secrets.sh — Store Unleash's admin and DB passwords in Vault and
# bootstrap its AppRole (role_id/secret_id saved under .secrets/, gitignored).
# Idempotent: re-running keeps existing values unless FORCE=1.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS_DIR="${SCRIPT_DIR}/../.secrets"
VAULT_DIR="${SCRIPT_DIR}/../vault"
VAULT_ADDR="http://127.0.0.1:8201"
FORCE="${FORCE:-0}"

mkdir -p "${SECRETS_DIR}"

echo "=== Checking Vault is running and unsealed ==="

if [[ ! -x "${VAULT_DIR}/scripts/add-service.sh" ]]; then
    echo "[FAIL] ${VAULT_DIR}/scripts/add-service.sh not found." >&2
    echo "       Vault is a sibling project in this repo (aws/vault)." >&2
    exit 1
fi

HEALTH="$(curl -s -o /dev/null -w '%{http_code}' "${VAULT_ADDR}/v1/sys/health?uninitcode=200&sealedcode=200")"
case "${HEALTH}" in
    200) ;;
    501|503) echo "[FAIL] Vault not initialized or sealed — run 'make init'/'make unseal' in ../vault first." >&2; exit 1 ;;
    *) echo "[FAIL] Vault unreachable at ${VAULT_ADDR} (HTTP ${HEALTH}). Is the stack up?" >&2; exit 1 ;;
esac
echo "[OK] Vault reachable at ${VAULT_ADDR}"

echo ""
echo "=== Registering AppRole 'unleash' ==="

"${VAULT_DIR}/scripts/add-service.sh" unleash "" --read-policy secret/data/unleash/*

ROLE_ID_FILE="${SECRETS_DIR}/vault-role-id.txt"
SECRET_ID_FILE="${SECRETS_DIR}/vault-secret-id.txt"

if [[ -s "${ROLE_ID_FILE}" && -s "${SECRET_ID_FILE}" ]]; then
    echo "[OK] AppRole credentials already present in ${SECRETS_DIR}"
else
    echo "[FAIL] AppRole registration did not persist role_id/secret_id." >&2
    exit 1
fi
chmod 600 "${ROLE_ID_FILE}" "${SECRET_ID_FILE}" 2>/dev/null || true

echo ""
echo "=== Storing secrets in secret/data/unleash/dev ==="

TOKEN="$(curl -s -X POST "${VAULT_ADDR}/v1/auth/approle/login" \
    -d "{\"role_id\":\"$(cat "${ROLE_ID_FILE}")\",\"secret_id\":\"$(cat "${SECRET_ID_FILE}")\"}" \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["auth"]["client_token"])')"

EXISTING="$(curl -s -H "X-Vault-Token: ${TOKEN}" "${VAULT_ADDR}/v1/secret/data/unleash/dev" \
    | python3 -c 'import json,sys; d=json.load(sys.stdin)["data"]["data"]; print("yes" if d.get("UNLEASH_ADMIN_PASSWORD") and d.get("UNLEASH_DB_PASSWORD") else "")' 2>/dev/null || true)"

if [[ -n "${EXISTING}" && "${FORCE}" != "1" ]]; then
    echo "[OK] UNLEASH_ADMIN_PASSWORD / UNLEASH_DB_PASSWORD already stored (FORCE=1 rotates them)"
elif [[ -z "${EXISTING}" || "${FORCE}" == "1" ]]; then
    ADMIN_PASSWORD="$(openssl rand -base64 18 | tr -d '/+=' | head -c 20)"
    DB_PASSWORD="$(openssl rand -hex 16)"
    curl -s -H "X-Vault-Token: ${TOKEN}" \
        -X POST "${VAULT_ADDR}/v1/secret/data/unleash/dev" \
        -d "{\"data\":{\"UNLEASH_ADMIN_PASSWORD\":\"${ADMIN_PASSWORD}\",\"UNLEASH_DB_PASSWORD\":\"${DB_PASSWORD}\"}}" > /dev/null
    echo "[OK] Secrets stored in Vault"
fi

echo ""
echo "=== Done ==="
echo "Next: make env   # generates .env from Vault"
