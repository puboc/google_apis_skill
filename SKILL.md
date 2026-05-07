---
name: google-apis
description: Google APIs Agent skill for OAuth-backed Google API workflows using a deployed workspace credential file and refresh token. Use when Codex needs to inspect Google APIs Agent setup, load Google OAuth credentials, refresh an access token, call Google REST APIs such as Drive, Gmail, Sheets, Docs, Calendar, YouTube, Analytics, or Apps Script, or create safe automation plans that use GOOGLE_APIS_CREDENTIALS_PATH, GOOGLE_APIS_ACCESS_TOKEN, and GOOGLE_APIS_REFRESH_TOKEN.
---

# Google APIs Agent

## Purpose

Use this skill to work with a Google APIs Agent workspace that already has OAuth client credentials and user OAuth tokens provisioned. The product setup writes the credentials and token environment into the agent workspace; this skill tells the agent how to find them, keep them private, refresh access safely, and call Google APIs directly.

## Runtime Contract

Prefer existing environment variables. If variables are missing, load the workspace env file before calling Google APIs.

Primary variables:

```bash
GOOGLE_APIS_CREDENTIALS_PATH=/path/to/google_client_secret.json
GOOGLE_APIS_ACCESS_TOKEN=...
GOOGLE_APIS_REFRESH_TOKEN=...
GOOGLE_APIS_ACCESS_TOKEN_EXPIRES_AT=...
```

Known OpenClaw paths:

```text
/data/.openclaw/workspace/google_apis_oauth.env
/data/.openclaw/workspace/google_client_secret.json
/opt/openclaw/data/.openclaw/workspace/google_apis_oauth.env
/opt/openclaw/data/.openclaw/workspace/google_client_secret.json
```

Known Hermes-style paths if the skill is installed into a Hermes data volume:

```text
/opt/data/google_apis_oauth.env
/opt/data/google_client_secret.json
```

Use `scripts/check-auth.sh` to discover and validate the local setup without printing secrets:

```bash
scripts/check-auth.sh
```

## Workflow

1. Identify the user's target Google product and action.
2. Load the OAuth env file if needed.
3. Validate the client secret JSON and token variables.
4. Refresh the access token if it is missing, expired, or rejected.
5. Call the target Google REST API with the bearer token.
6. Persist only refreshed access token metadata; never rotate or replace the refresh token automatically.
7. Return concise results and local file paths or object IDs. Never print raw tokens, client secrets, or full credential files.

## Credential Handling

Never ask the user to paste Google credentials if the runtime files exist. Check the configured env and known paths first.

Never display:

- `GOOGLE_APIS_ACCESS_TOKEN`
- `GOOGLE_APIS_REFRESH_TOKEN`
- `client_secret`
- full contents of `google_client_secret.json`
- bearer headers or request URLs that include tokens

You may display:

- credential/env file paths
- token presence
- token expiry time
- redacted token fingerprints
- Google resource IDs returned by API calls

Do not rotate refresh tokens automatically. If a refresh token is invalid or revoked, explain that the Google OAuth authorization flow must be repeated by the product/extension flow.

## Helper Scripts

Run scripts from this skill directory, or call them by absolute path.

Validate local setup:

```bash
scripts/check-auth.sh
```

Refresh access token and update the env file:

```bash
scripts/refresh-access-token.sh
```

Call a Google API endpoint:

```bash
scripts/google-api-request.sh GET "https://www.googleapis.com/drive/v3/about?fields=user,storageQuota"
scripts/google-api-request.sh POST "https://sheets.googleapis.com/v4/spreadsheets/{spreadsheetId}:batchUpdate" body.json --refresh
```

The scripts use only Bash, Python 3, and curl. They intentionally avoid `jq` so they work in small VPS images.

## API Calling Rules

Use the REST API directly unless the repo already contains a stronger local client. Pin explicit API versions in URLs, for example:

```text
https://www.googleapis.com/drive/v3/files
https://gmail.googleapis.com/gmail/v1/users/me/messages
https://sheets.googleapis.com/v4/spreadsheets/{spreadsheetId}/values/{range}
https://www.googleapis.com/calendar/v3/calendars/primary/events
```

Prefer least privilege operations:

- Read before write when changing existing resources.
- Use dry-run or preview requests when an API supports them.
- Request user confirmation before destructive changes, large sends, public publishing, or operations that notify other people.
- For batch updates, explain the intended changes before submission.
- For long-running operations, poll status with backoff instead of resubmitting.

When a request fails:

- `401`: refresh once, retry once, then stop.
- `403`: report likely missing scope, disabled API, permission, or app verification issue.
- `404`: verify resource ID and account context.
- `429` or `5xx`: retry with backoff only for idempotent operations.

## Google Product Notes

Drive:
- Use `files.list`, `files.get`, `files.create`, `files.update`, and `permissions.*`.
- Use `fields` query parameters to avoid large responses.
- Avoid broad permission changes without confirmation.

Gmail:
- Use `users.me` unless the user explicitly gives another mailbox identity.
- Draft before send when content is non-trivial.
- Do not send mail, delete mail, or modify labels in bulk without confirmation.

Sheets:
- Read target ranges before update.
- Prefer `spreadsheets.values.*` for simple cell values.
- Use `spreadsheets.batchUpdate` for formatting, sheets, filters, protected ranges, and structural changes.

Docs:
- Fetch document structure before editing.
- Use batchUpdate and preserve indexes carefully.
- Avoid rewriting whole documents if a targeted edit is possible.

Calendar:
- Read event details before update/delete.
- Confirm attendee-impacting updates.
- Preserve time zones and recurrence rules.

YouTube, Analytics, Ads, and Apps Script:
- Verify the enabled API and scopes first.
- Treat publish, deploy, spend, or public visibility changes as high-impact and ask for confirmation.

## References

Read these only when needed:

- `references/runtime-contract.md`: deployed file paths, env variables, and product setup behavior.
- `references/oauth-refresh.md`: token refresh details and failure handling.
- `references/google-rest-patterns.md`: common request patterns by Google product.
