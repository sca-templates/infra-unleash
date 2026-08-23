#!/usr/bin/env bash
#
# gen-env.sh — Generate .env from Vault using the 'unleash' AppRole.
# Reads secret/data/unleash/dev (admin + DB passwords) and merges it with
# non-secret defaults (.env.example). .env is chmod 600 and gitignored.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."
ENV_FILE="${ROOT_DIR}/.env"
ENV_EXAMPLE="${ROOT_DIR}/.env.example"
SECRETS_DIR="${ROOT_DIR}/.secrets"
VAULT_ADDR="http://127.0.0.1:8201"

ROLE_ID_FILE="${SECRETS_DIR}/vault-role-id.txt"
SECRET_ID_FILE="${SECRETS_DIR}/vault-secret-id.txt"

[[ -f "${ENV_EXAMPLE}" ]] || { echo "[FAIL] .env.example not found" >&2; exit 1; }
[[ -s "${ROLE_ID_FILE}" && -s "${SECRET_ID_FILE}" ]] || {
    echo "[FAIL] Missing AppRole creds in .secrets/ — run 'make vault-secrets' first" >&2
    exit 1
}

echo "=== Logging into Vault via AppRole ==="
TOKEN="$(curl -s -X POST "${VAULT_ADDR}/v1/auth/approle/login" \
    -d "{\"role_id\":\"$(cat "${ROLE_ID_FILE}")\",\"secret_id\":\"$(cat "${SECRET_ID_FILE}")\"}" \
    | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d["auth"]["client_token"])')"

echo "=== Reading secret/data/unleash/dev ==="
SECRETS_JSON="$(curl -s -H "X-Vault-Token: ${TOKEN}" "${VAULT_ADDR}/v1/secret/data/unleash/dev")"

read -r ADMIN_PASSWORD DB_PASSWORD <<< "$(python3 -c "
import json
d = json.loads('''${SECRETS_JSON}''')['data']['data']
print(d.get('UNLEASH_ADMIN_PASSWORD', ''), d.get('UNLEASH_DB_PASSWORD', ''), sep='|')
" | tr '|' ' ')"

if [[ -z "${ADMIN_PASSWORD}" || -z "${DB_PASSWORD}" ]]; then
    echo "[FAIL] UNLEASH secrets missing in Vault — run 'make vault-secrets'" >&2
    exit 1
fi

echo "=== Writing ${ENV_FILE} ==="
{
    grep '^#' -v "${ENV_EXAMPLE}" | grep -E '^[A-Z_]+=' | grep -v -e '^UNLEASH_ADMIN_PASSWORD=' -e '^UNLEASH_DB_PASSWORD='
    echo "UNLEASH_ADMIN_PASSWORD=${ADMIN_PASSWORD}"
    echo "UNLEASH_DB_PASSWORD=${DB_PASSWORD}"
} > "${ENV_FILE}"
chmod 600 "${ENV_FILE}"

echo "[OK] .env generated (chmod 600). Next: make up"
