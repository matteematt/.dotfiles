---
name: jira-token
description: Use the Jira API token in the macOS keychain to do things the Atlassian MCP cannot — download issue attachments, upload files, or call any Jira Cloud REST v3 endpoint the MCP does not wrap. Use when an attachment needs reading, when an MCP call 403s on a content URL, or when no MCP tool exists for the Jira operation needed.
---

# Jira API token

A personal Atlassian API token is stored in the macOS keychain. It exists to cover the gaps in
the first-party Atlassian MCP — most importantly attachments, which the MCP cannot read at all.

**The token expires on 10 September 2027.** Atlassian API tokens last one year. After that date
every call below returns `401` and a new token must be created at
https://id.atlassian.com/manage-profile/security/api-tokens and re-stored (see *When it fails*).

## Setting up the shell variables

Every example below assumes these three. The account is read from the keychain item itself, so
no address is hardcoded:

```bash
TOKEN=$(security find-generic-password -s jira-api-token -w)
ACCOUNT=$(security find-generic-password -s jira-api-token | awk -F'"' '/"acct"/{print $4}')
SITE=your-site.atlassian.net
```

Find `SITE` from the browser URL of any issue, or from the MCP's
`getAccessibleAtlassianResources`. Never print, echo, log or write `$TOKEN` — keep it in a shell
variable used inline, so the value never reaches the transcript, shell history or a file.

## Why the MCP is not enough

The Atlassian MCP exposes no attachment tool of any kind. The `content` URL it hands back on an
issue's `attachment[]` entries is the OAuth form:

```
https://api.atlassian.com/ex/jira/{cloudId}/rest/api/3/attachment/content/{id}
```

That path only accepts a bearer token — Basic auth returns `401` there, and an unauthenticated
fetch returns `403`. Use the **site domain** instead, which accepts Basic auth with an API token:

```
https://$SITE/rest/api/3/...
```

(The cloud id, if ever needed for the OAuth form, appears in the `context` block of every MCP
response and in `getAccessibleAtlassianResources`.)

## Download an attachment

Get the attachment id from the MCP first — `getJiraIssue` with `fields: ["attachment"]` returns
`id`, `filename`, `size` and `mimeType` for each one. Then:

```bash
curl -sL -u "$ACCOUNT:$TOKEN" \
  -o "$SCRATCHPAD/whatever.md" \
  "https://$SITE/rest/api/3/attachment/content/<ATTACHMENT_ID>"
```

`-L` is required: the endpoint redirects to a signed media URL and without it you get an empty
file. Write to the session scratchpad, not the repo — these are someone else's files and they
should not end up untracked in a worktree.

For a large attachment (a multi-MB diagnostics dump), download it and then read it with
`jq`/`grep` rather than pulling the whole thing into context.

## An inline `![](blob:...)` in a description is a FILE, not a screenshot

The MCP's markdown conversion renders an inline **file** attachment as image syntax:

```
![](blob:https://media.staging.atl-paas.net/?type=file&id=<uuid>...)
```

This looks like a pasted screenshot and is not one. To find out what it actually is, call
`getJiraIssue` with `expand: "renderedFields"`. The rendered HTML carries
`data-attachment-name`, `data-media-services-type` (`file` vs `image`) and
`href="/rest/api/3/attachment/content/<attachmentId>"` — i.e. it maps the media-services id in
the blob URL to a real attachment id, which is the lookup Atlassian's own developer community
says is unsupported through the media API.

Do this **before** telling anyone an issue has a screenshot you cannot see.

## Upload an attachment

```bash
curl -s -u "$ACCOUNT:$TOKEN" \
  -X POST -H "X-Atlassian-Token: no-check" \
  -F "file=@./report.md" \
  "https://$SITE/rest/api/3/issue/PROJ-123/attachments"
```

The `X-Atlassian-Token: no-check` header is mandatory; without it the request is rejected as XSRF.
Uploading to a shared tracker is outward-facing — confirm before doing it unless already asked.

## Anything else

The same auth works against any Jira Cloud platform REST v3 endpoint, so it is the general escape
hatch when no MCP tool exists. Prefer the MCP for anything it already covers — searching,
reading, editing, transitioning, commenting — and reach for curl only for the gaps.

Reference: https://developer.atlassian.com/cloud/jira/platform/rest/v3/

## When it fails

Check authentication first — this distinguishes a bad credential from a permissions or endpoint
problem:

```bash
curl -s -u "$ACCOUNT:$TOKEN" "https://$SITE/rest/api/3/myself" | head -c 200
```

Expect `200` and the account's `displayName`. A `401` means the token is wrong or expired.

A truncated paste is the likeliest cause and it is silent — the value still starts with `ATATT`
but is short. Check the shape without revealing it:

```bash
printf 'length: %s\n' "${#TOKEN}"
printf '%s' "$TOKEN" | grep -qE '^ATATT[A-Za-z0-9_-]+=[0-9A-F]{8}$' \
  && echo "structure OK" || echo "TRUNCATED or altered"
```

A complete token is 192 characters and ends with `=` plus an 8-character hex checksum.

To re-store without an interactive prompt (which is where truncation happens), copy the token to
the clipboard and:

```bash
security add-generic-password -U -s jira-api-token -a "<your-atlassian-email>" -w "$(pbpaste)"
```

`-U` updates the existing item instead of failing on the duplicate.
