#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

ONLINE=0
if [[ "${1:-}" == "--online" ]]; then
  ONLINE=1
fi

google_apis::load_env
credentials_path="$(google_apis::resolve_credentials_path || true)"
if [[ -z "${credentials_path}" ]]; then
  echo "FAIL credentials JSON: missing" >&2
  exit 1
fi
export GOOGLE_APIS_CREDENTIALS_PATH="${credentials_path}"

python3 -m json.tool "${credentials_path}" >/dev/null

missing=0
for name in GOOGLE_APIS_ACCESS_TOKEN GOOGLE_APIS_REFRESH_TOKEN GOOGLE_APIS_CREDENTIALS_PATH; do
  if [[ -z "${!name:-}" ]]; then
    echo "FAIL ${name}: missing" >&2
    missing=1
  else
    case "${name}" in
      GOOGLE_APIS_ACCESS_TOKEN|GOOGLE_APIS_REFRESH_TOKEN)
        echo "PASS ${name}: $(google_apis::redact "${!name}")"
        ;;
      *)
        echo "PASS ${name}: ${!name}"
        ;;
    esac
  fi
done

if (( missing )); then
  exit 1
fi

echo "PASS env file: ${GOOGLE_APIS_ENV_PATH}"
echo "PASS credentials JSON: valid"
if [[ -n "${GOOGLE_APIS_ACCESS_TOKEN_EXPIRES_AT:-}" ]]; then
  echo "INFO access token expires at: ${GOOGLE_APIS_ACCESS_TOKEN_EXPIRES_AT}"
fi

if (( ONLINE )); then
  echo "INFO tokeninfo: checking access token online"
  curl -fsS "https://oauth2.googleapis.com/tokeninfo?access_token=${GOOGLE_APIS_ACCESS_TOKEN}" |
    python3 -m json.tool
fi
