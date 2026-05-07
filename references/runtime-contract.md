# Runtime Contract

This skill was extracted from `product_configuration_google_apis_agent`.

## Product Setup Behavior

During provisioning, the product setup:

1. Requires `GOOGLE_APIS_CREDENTIALS_JSON_B64`, `GOOGLE_APIS_ACCESS_TOKEN`, and `GOOGLE_APIS_REFRESH_TOKEN`.
2. Decodes the base64 OAuth client secret JSON.
3. Writes the JSON to the OpenClaw workspace.
4. Validates it with `python3 -m json.tool`.
5. Writes an OAuth env file with credential and token paths.
6. Installs an `AGENTS.md` workspace guide.

## OpenClaw Host Paths

```text
/opt/openclaw/data/.openclaw/workspace/google_client_secret.json
/opt/openclaw/data/.openclaw/workspace/google_apis_oauth.env
```

## OpenClaw Container Paths

```text
/data/.openclaw/workspace/google_client_secret.json
/data/.openclaw/workspace/google_apis_oauth.env
```

## Env File Format

```bash
GOOGLE_APIS_CREDENTIALS_PATH=/opt/openclaw/data/.openclaw/workspace/google_client_secret.json
GOOGLE_APIS_ACCESS_TOKEN=...
GOOGLE_APIS_REFRESH_TOKEN=...
GOOGLE_APIS_ACCESS_TOKEN_EXPIRES_AT=...
```

`GOOGLE_APIS_ACCESS_TOKEN_EXPIRES_AT` may be absent on first provision. Add it after a successful refresh.

## Runtime Invariants

- The refresh token is the durable credential. Do not rewrite it unless the user reruns OAuth setup.
- The access token is short-lived and can be refreshed.
- The client secret JSON is required to refresh.
- The env file is secret-bearing and should be mode `0600`.
- Do not print full env file contents.

## Agent Safety Rules

- Keep Google credentials local to the VPS/container.
- Never paste credential file contents into chat.
- Prefer direct REST calls with scoped `fields` parameters.
- Confirm destructive or user-visible operations.
- Persist a newly refreshed access token back to the env file.
