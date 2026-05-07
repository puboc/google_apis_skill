# Google REST Patterns

## Drive

List files with narrow fields:

```bash
scripts/google-api-request.sh GET \
  "https://www.googleapis.com/drive/v3/files?pageSize=10&fields=files(id,name,mimeType,modifiedTime)"
```

Get account info:

```bash
scripts/google-api-request.sh GET \
  "https://www.googleapis.com/drive/v3/about?fields=user,storageQuota"
```

Create or update permissions only after confirmation.

## Gmail

List messages:

```bash
scripts/google-api-request.sh GET \
  "https://gmail.googleapis.com/gmail/v1/users/me/messages?maxResults=10"
```

Read message metadata before modifying labels, archiving, deleting, or sending. Draft before send when content matters.

## Sheets

Read values:

```bash
scripts/google-api-request.sh GET \
  "https://sheets.googleapis.com/v4/spreadsheets/{spreadsheetId}/values/{range}"
```

Write values with a JSON body:

```json
{
  "range": "Sheet1!A1:B2",
  "majorDimension": "ROWS",
  "values": [["Name", "Value"], ["Example", "42"]]
}
```

Use:

```bash
scripts/google-api-request.sh PUT \
  "https://sheets.googleapis.com/v4/spreadsheets/{spreadsheetId}/values/Sheet1!A1:B2?valueInputOption=USER_ENTERED" \
  body.json
```

## Docs

Fetch the document before editing:

```bash
scripts/google-api-request.sh GET \
  "https://docs.googleapis.com/v1/documents/{documentId}"
```

Use `documents.batchUpdate` with precise indexes. Avoid replacing full documents when a targeted request works.

## Calendar

List upcoming events:

```bash
scripts/google-api-request.sh GET \
  "https://www.googleapis.com/calendar/v3/calendars/primary/events?singleEvents=true&orderBy=startTime&maxResults=10"
```

Confirm before changing attendee lists, recurrence, reminders, or event times.

## Apps Script

Check deployment and execution permissions carefully. Treat script deployments as production changes.

## High-Impact APIs

For YouTube, Analytics, Ads, and public publishing APIs:

- Confirm API enablement and scopes.
- Ask before spending money, publishing public content, changing ads, or deleting data.
- Keep logs free of tokens and client secrets.
