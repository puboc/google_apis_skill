#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

usage() {
  cat >&2 <<'EOF'
Usage:
  scripts/google-api-request.sh METHOD URL [json-body-file] [--refresh]

Examples:
  scripts/google-api-request.sh GET "https://www.googleapis.com/drive/v3/about?fields=user,storageQuota"
  scripts/google-api-request.sh POST "https://sheets.googleapis.com/v4/spreadsheets/{id}:batchUpdate" body.json --refresh
EOF
}

if [[ $# -lt 2 || "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 2
fi

method="$1"
url="$2"
body_file="${3:-}"
refresh=0

if [[ "${body_file}" == "--refresh" ]]; then
  body_file=""
  refresh=1
fi
if [[ "${4:-}" == "--refresh" ]]; then
  refresh=1
fi

if (( refresh )); then
  "${SCRIPT_DIR}/refresh-access-token.sh" >/dev/null
fi

google_apis::load_env
credentials_path="$(google_apis::resolve_credentials_path || true)"
if [[ -n "${credentials_path}" ]]; then
  export GOOGLE_APIS_CREDENTIALS_PATH="${credentials_path}"
fi
google_apis::require_loaded_auth

curl_args=(
  -fsS
  -X "${method}"
  -H "Authorization: Bearer ${GOOGLE_APIS_ACCESS_TOKEN}"
  -H "Accept: application/json"
)

if [[ -n "${body_file}" ]]; then
  [[ -f "${body_file}" ]] || {
    echo "Missing JSON body file: ${body_file}" >&2
    exit 1
  }
  curl_args+=(-H "Content-Type: application/json" --data-binary "@${body_file}")
fi

curl "${curl_args[@]}" "${url}"
