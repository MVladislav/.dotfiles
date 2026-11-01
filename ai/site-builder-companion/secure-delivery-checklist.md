# Secure delivery and publication checklist

Use the sections appropriate to the app. This is a practical review aid, not a substitute for a formal security assessment for high-risk systems.

## Before implementing

- [ ] Identify whether the app handles personal, confidential, regulated, or otherwise sensitive data.
- [ ] Identify who can access the site and whether sign-in is required.
- [ ] Identify trusted sources and external integrations.
- [ ] Identify the persistence model and how data will be backed up and restored.
- [ ] Confirm deployment target and intended network exposure before configuring it.

## Source, dependencies, and secrets

- [ ] No secrets in source code, browser-visible environment variables, sample content, logs, screenshots, or generated static assets.
- [ ] `.env` files are excluded from version control; sanitized `.env.example` lists variable names only.
- [ ] Dependencies are justified and use the project's package manager and lockfile.
- [ ] Package scripts and code from untrusted sources are not run blindly.
- [ ] Uploaded files, imported documents, and external page content are treated as untrusted input.

## Application controls

- [ ] Server-side validation is applied to untrusted input.
- [ ] Server-side authorization protects every sensitive read/write/action; UI visibility alone is not security.
- [ ] Data belonging to one user cannot be read or modified by another without permission.
- [ ] File uploads have sensible size/type limits, safe storage names, and access checks.
- [ ] Errors do not reveal secrets, stack traces, or internal service details to visitors.
- [ ] External integrations request least-privilege access and handle missing/expired permissions, rate limits, and service failures.
- [ ] Consider rate limiting, CSRF protection, secure cookie/session settings, security headers, and dependency updates according to the framework and threat model.

## Data and migrations

- [ ] Durability assumptions match the selected runtime and hosting platform.
- [ ] Database migrations preserve existing records and have a rollback/recovery plan appropriate to risk.
- [ ] Backup and restore requirements are documented for important records and uploads.
- [ ] Demo/sample records are clearly labelled and removed or replaced before sharing if misleading.
- [ ] Source-data provenance and refresh behavior are explicit where freshness matters.

## Before publishing or exposing to a network

- [ ] The user explicitly approved the target, audience, and deployment action.
- [ ] The final build and relevant tests passed, or failures and omissions are clearly disclosed.
- [ ] The site does not contain private prompts, source documents, credentials, internal paths, or data meant only for the builder.
- [ ] Authentication and authorization were tested for expected and denied cases.
- [ ] HTTPS/TLS, host binding, firewall/reverse proxy, and security headers are appropriate for the target.
- [ ] Required environment variables are configured through the target's secret mechanism.
- [ ] Data migration, backup, rollback, costs, and operational ownership are understood where relevant.
- [ ] The resulting URL/endpoint was actually checked after deployment.

## Destructive or costly actions

Stop and request explicit confirmation before deleting data, dropping tables, replacing user files, running destructive migrations, exposing a service beyond localhost, changing DNS/firewall rules, enabling public access, provisioning paid resources, or making irreversible account/provider changes.
