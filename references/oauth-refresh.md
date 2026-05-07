# OAuth Refresh

Google OAuth access tokens expire. Refresh them with:

```bash
scripts/refresh-access-token.sh
```

The script:

1. Loads `google_apis_oauth.env`.
2. Reads `GOOGLE_APIS_CREDENTIALS_PATH`.
3. Extracts `client_id` and `client_secret` from either the `installed` or `web` section.
4. Calls `https://oauth2.googleapis.com/token`.
5. Writes `GOOGLE_APIS_ACCESS_TOKEN` and `GOOGLE_APIS_ACCESS_TOKEN_EXPIRES_AT` back to the env file.

## Manual Request Shape

```bash
curl -X POST "https://oauth2.googleapis.com/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "client_id=${client_id}" \
  --data-urlencode "client_secret=${client_secret}" \
  --data-urlencode "refresh_token=${GOOGLE_APIS_REFRESH_TOKEN}" \
  --data-urlencode "grant_type=refresh_token"
```

## Failure Handling

- `invalid_grant`: refresh token is expired, revoked, malformed, or issued to a different client. Stop and ask the user to rerun the OAuth setup flow.
- `invalid_client`: client secret JSON does not match the refresh token or is malformed.
- `unauthorized_client`: OAuth client type or project policy is wrong.
- `access_denied`: user or organization policy blocks the operation.

Do not retry refresh failures in a loop. Do not silently switch Google projects or client secret files.

## Token Use

Use the refreshed access token as a bearer token:

```bash
Authorization: Bearer ${GOOGLE_APIS_ACCESS_TOKEN}
```

Do not put access tokens in query strings.
