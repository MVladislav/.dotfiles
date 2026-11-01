# Storage, identity, integrations, and deployment choices

Choose based on required behavior, not on the fact that a UI has fields or buttons. Explain material trade-offs briefly. Do not introduce a database, identity provider, or external service without a reason.

## Storage decision guide

| Requirement | Typical choice | Important boundary |
|---|---|---|
| Mostly static reference or content site | Static files / content source | No durable application database unless required |
| Theme, expanded panel, temporary filters | Component state or browser storage | Not suitable for sensitive data or shared business records |
| Single-user app on one machine | SQLite or local files with validated formats | Back up the data directory; do not expose files over the web |
| Multiple users or multiple app instances | PostgreSQL or a supported managed relational database | Shared, durable server-side storage and migrations |
| User uploads or large binary files | Object storage or a deliberately managed file store | Store metadata separately; enforce upload and download authorization |
| Uploaded documents with searchable metadata | Object storage plus a relational metadata index, where useful | Keep file bytes and metadata consistent; validate file type and size |
| External live data | Documented API / approved connector | Handle credentials, scopes, rate limits, stale data, pagination, and errors |

SQLite is a sensible default for many local applications, but not an automatic default for a multi-instance hosted app. Filesystem persistence may be ephemeral in container or serverless environments; verify the selected host's guarantees.

## Identity and authorization

- A single-user local tool may not need authentication if it remains bound to localhost and has no sensitive threat exposure.
- Shared or public applications need an explicit identity and access model before sensitive or user-owned data is implemented.
- Use a real authentication mechanism. Do not invent a login form that only changes client-side state.
- Enforce authorization on the server for every record or privileged action. Check record ownership and role, not only whether the visitor is signed in.
- Test denied access, cross-user isolation, signed-out behavior, and expired/unavailable identity sessions.
- Do not trust identity or role values supplied by the browser without server-verifiable validation.

## Data source and connected services

Distinguish among:

1. **Snapshot:** import a copy of a supplied file or data export. State when it was imported.
2. **Manual refresh:** retrieve current source data only when a user requests it.
3. **Scheduled/continuous sync:** implement only when requested and supported; define freshness, failure, retry, and conflict behavior.
4. **Per-visitor connection:** read through each visitor's own permitted account only when a real connector or OAuth/API integration is configured.

Sharing a site does not itself grant access to a third-party service. Do not reuse the builder's credentials to impersonate visitors. Never expose API secrets in client bundles, logs, source maps, generated pages, or public environment variables.

## Deployment target

| Target | Default posture | Additional work to consider |
|---|---|---|
| Local development | Bind to `127.0.0.1` | Dev server and local test data |
| Private LAN | Requires explicit approval | Bind interface, firewall scope, authentication, TLS/reverse proxy as appropriate |
| Private hosted service | Requires explicit approval | Network boundaries, secrets, backups, monitoring, TLS, update/rollback plan |
| Public website/app | Requires explicit approval | Public data review, abuse/rate limiting, auth, TLS, security headers, privacy notices, backup/restore, costs and operational owner |

A URL being reachable is not proof of production readiness. Choose a real deployment target - such as the user's existing Docker/Traefik environment or an approved provider - and check current provider documentation before configuring it. Never assume the provider, region, cost, domain, or persistence model.
