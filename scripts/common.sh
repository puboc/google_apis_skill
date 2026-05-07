#!/usr/bin/env bash
set -euo pipefail

google_apis::skill_dir() {
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd
}

google_apis::candidate_env_paths() {
  if [[ -n "${GOOGLE_APIS_ENV_PATH:-}" ]]; then
    printf '%s\n' "${GOOGLE_APIS_ENV_PATH}"
  fi
  printf '%s\n' \
    "/data/.openclaw/workspace/google_apis_oauth.env" \
    "/opt/data/google_apis_oauth.env" \
    "/opt/openclaw/data/.openclaw/workspace/google_apis_oauth.env"
}

google_apis::resolve_env_path() {
  local path
  while IFS= read -r path; do
    [[ -n "${path}" ]] || continue
    if [[ -f "${path}" ]]; then
      printf '%s' "${path}"
      return 0
    fi
  done < <(google_apis::candidate_env_paths)
  return 1
}

google_apis::load_env() {
  local env_path="${1:-}"
  if [[ -z "${env_path}" ]]; then
    env_path="$(google_apis::resolve_env_path || true)"
  fi
  if [[ -z "${env_path}" ]]; then
    echo "Missing Google APIs env file. Set GOOGLE_APIS_ENV_PATH or create google_apis_oauth.env." >&2
    return 1
  fi
  # shellcheck disable=SC1090
  set -a
  source "${env_path}"
  set +a
  export GOOGLE_APIS_ENV_PATH="${env_path}"
}

google_apis::resolve_credentials_path() {
  if [[ -n "${GOOGLE_APIS_CREDENTIALS_PATH:-}" && -f "${GOOGLE_APIS_CREDENTIALS_PATH}" ]]; then
    printf '%s' "${GOOGLE_APIS_CREDENTIALS_PATH}"
    return 0
  fi

  local candidate
  for candidate in \
    "/data/.openclaw/workspace/google_client_secret.json" \
    "/opt/data/google_client_secret.json" \
    "/opt/openclaw/data/.openclaw/workspace/google_client_secret.json"; do
    if [[ -f "${candidate}" ]]; then
      printf '%s' "${candidate}"
      return 0
    fi
  done
  return 1
}

google_apis::require_loaded_auth() {
  : "${GOOGLE_APIS_ACCESS_TOKEN:?Missing GOOGLE_APIS_ACCESS_TOKEN}"
  : "${GOOGLE_APIS_REFRESH_TOKEN:?Missing GOOGLE_APIS_REFRESH_TOKEN}"
  : "${GOOGLE_APIS_CREDENTIALS_PATH:?Missing GOOGLE_APIS_CREDENTIALS_PATH}"
}

google_apis::redact() {
  local value="${1:-}"
  local length="${#value}"
  if (( length <= 10 )); then
    printf '<redacted:%s>' "${length}"
    return
  fi
  printf '%s...%s(len=%s)' "${value:0:6}" "${value: -4}" "${length}"
}

google_apis::utc_now() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

google_apis::expires_at_from_seconds() {
  local seconds="$1"
  python3 - "${seconds}" <<'PY'
from datetime import datetime, timezone, timedelta
import sys

seconds = int(sys.argv[1])
print((datetime.now(timezone.utc) + timedelta(seconds=seconds)).replace(microsecond=0).isoformat().replace("+00:00", "Z"))
PY
}

google_apis::client_secret_json() {
  local path="$1"
  local field="$2"
  python3 - "${path}" "${field}" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
field = sys.argv[2]
data = json.loads(path.read_text(encoding="utf-8"))
root = data.get("installed") or data.get("web") or data
value = root.get(field, "")
if not value:
    raise SystemExit(f"Missing {field} in {path}")
print(value)
PY
}

google_apis::update_env_file() {
  local env_path="$1"
  local access_token="$2"
  local expires_at="$3"
  local tmp="${env_path}.tmp.$$"

  install -d "$(dirname -- "${env_path}")"
  if [[ -f "${env_path}" ]]; then
    awk '
      index($0, "GOOGLE_APIS_ACCESS_TOKEN=") != 1 &&
      index($0, "GOOGLE_APIS_ACCESS_TOKEN_EXPIRES_AT=") != 1 { print }
    ' "${env_path}" > "${tmp}"
  else
    : > "${tmp}"
  fi
  printf 'GOOGLE_APIS_ACCESS_TOKEN=%s\n' "${access_token}" >> "${tmp}"
  printf 'GOOGLE_APIS_ACCESS_TOKEN_EXPIRES_AT=%s\n' "${expires_at}" >> "${tmp}"
  mv "${tmp}" "${env_path}"
  chmod 0600 "${env_path}"
}
