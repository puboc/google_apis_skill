#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

google_apis::load_env
credentials_path="$(google_apis::resolve_credentials_path || true)"
if [[ -z "${credentials_path}" ]]; then
  echo "Missing Google OAuth client secret JSON." >&2
  exit 1
fi
export GOOGLE_APIS_CREDENTIALS_PATH="${credentials_path}"
: "${GOOGLE_APIS_REFRESH_TOKEN:?Missing GOOGLE_APIS_REFRESH_TOKEN}"

client_id="$(google_apis::client_secret_json "${credentials_path}" client_id)"
client_secret="$(google_apis::client_secret_json "${credentials_path}" client_secret)"

response="$(
  curl -fsS \
    -X POST "https://oauth2.googleapis.com/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "client_id=${client_id}" \
    --data-urlencode "client_secret=${client_secret}" \
    --data-urlencode "refresh_token=${GOOGLE_APIS_REFRESH_TOKEN}" \
    --data-urlencode "grant_type=refresh_token"
)"

access_token="$(python3 - <<'PY' <<<"${response}"
import json
import sys

data = json.load(sys.stdin)
token = data.get("access_token", "")
if not token:
    raise SystemExit("Refresh response did not contain access_token")
print(token)
PY
)"

expires_in="$(python3 - <<'PY' <<<"${response}"
import json
import sys

data = json.load(sys.stdin)
print(int(data.get("expires_in", 3600)))
PY
)"

expires_at="$(google_apis::expires_at_from_seconds "${expires_in}")"
google_apis::update_env_file "${GOOGLE_APIS_ENV_PATH}" "${access_token}" "${expires_at}"

echo "Refreshed Google APIs access token."
echo "Env file: ${GOOGLE_APIS_ENV_PATH}"
echo "Expires at: ${expires_at}"
