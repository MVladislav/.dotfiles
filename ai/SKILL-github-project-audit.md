---
name: github-project-audit
description: Audit and verify a repository's GitHub helper setup (Renovate, Codecov, pre-commit, CI workflows and their security, labels, templates, branch protection); then produce a detailed improvement markdown with how/what/where and machine-checkable evidence
license: MIT
compatibility: opencode
metadata:
  audience: maintainers
  workflow: github
---

## What I do

Check a repository against a minimal, recommended set of GitHub "functional
helpers", verify they are actually _working_ (config present AND app granted
AND observable behavior), and produce a `GITHUB-PROJECT-IMPROVEMENT.md` report
that says what to fix, how, where (file/app URL), and where to learn more.

Reactive-by-nature helpers that are configured but never fire (e.g. a CodeRabbit
app with no reviews, a release drafter with labels that do not exist, a Codecov
status nobody enforces) are the core of what this audit catches.

This skill learns from real audits (e.g. the `MVladislav/bumper` audit):
misconfigurations are usually _app grants_, _label existence_, _schema
mismatches_ and _scope inconsistencies_, not missing files.

Prerequisite: `GITHUB_TOKEN` set (see `GITHUB.md` in this skill folder) and
`gh` installed. The token drives `gh api` reads of commits, check runs, branch
protection/rulesets, labels and releases — use a read-only PAT that includes
`administration: read` (for rulesets/branch-protection reads) together with the
`contents`/`issues`/`pull_requests` reads documented in `GITHUB.md`.

Scope note: this skill audits the **GitHub-side** helper setup and is
complementary to the `project-bootstrap` skill, which covers the **repository
side** (structure, tooling, CI config files, quality gates). Run `github-project-audit`
when you want the GitHub view, `project-bootstrap` when you want the repo-local view.

## Step-by-step

### 1. Orient

- Get `owner/repo`: `gh repo view --json nameWithOwner -q .nameWithOwner`.
- Check the runner/agent actually has permission to _see_ the relevant state
  (`gh auth status`). Fine-grained PATs often cannot read secrets, app
  installations, or branch protection, and cannot create/edit labels — report
  those as "manual action for the maintainer" instead of failing.
- Read README, AGENTS.md/CLAUDE.md and the main config files to learn
  conventions (commit style, changelog, release process) before judging.

### 2. Inventory GitHub-side state (via `gh api`)

- Recent behavior: `gh api "repos/{o}/{r}/commits"` → pick the latest
  `sha`, then `gh api "repos/{o}/{r}/commits/{sha}/check-runs"` (note which
  **app** produced each check: `github-actions`, `codecov`, `dependabot`,
  `renovate`, `coderabbit`…).
- Bot presence on PRs: search
  `gh pr list --state all --limit 100` and inspect authors/commenters for
  `renovate[bot]`, `dependabot[bot]`, `coderabbitai[bot]`, `pre-commit-ci[bot]`.
- Branch protection: `gh api "repos/{o}/{r}/branches/main/protection"` (404 =
  none). Rulesets: `gh api "repos/{o}/{r}/rulesets"` (REST, new API).
- Labels: `gh label list --json name` (compare against every label referenced
  in renovate.json, release drafter, cleanup/labeler workflows).
- Releases/tags: `gh release list` and `gh tag list` to understand the release
  process (tag-driven? continuously drafted?).

### 3. Inventory repository files

Use Glob/Grep for:

- Configs: `renovate.json`, `.renovaterc*`, `.codecov.yml`, `.pre-commit-config.yaml`,
  `.github/release-drafter.yml`, `.github/release-please.yml`, `dependabot.yml`.
- Workflows: everything under `.github/workflows/*`.
- Community: `PULL_REQUEST_TEMPLATE.md`, `ISSUE_TEMPLATE/*`, `CONTRIBUTING.md`,
  `CODEOWNERS`, `SECURITY.md`, `LICENSE`, `AGENTS.md`.
- CI security extras: `zizmor.yml`, `.github/workflows/*` permissions block,
  SHA pinning (`uses: action@<sha>` vs floating tags).

### 4. Verify each helper (statuses: OK / ISSUE / NEEDS ACTION / N/A)

**Renovate** — config file at a valid location (root, `.github/`, `renovate.json`,
`.renovaterc.json`), valid JSON, `extends` a preset (`config:recommended`),
labels referenced in `packageRules` **exist** in the repo, and behavior is
visible (merged `renovate/*` PRs authored by `app/renovate`). If the app never
opens PRs → installation/grant problem, not config.

**Codecov** — `.codecov.yml` parses; CI has a `codecov/codecov-action` step;
newer action versions support tokenless upload via the Codecov app + GitHub
OIDC (`permissions: id-token: write`), otherwise a `CODECOV_TOKEN` secret is
required. Coverage should be scoped to the _shipped package_, not the whole
repo (check `--cov=<package>` vs `.coveragerc` `source`); contradictory scoped
vs. whole-repo numbers on one PR = scope mismatch. Statuses must match repo
reality; a red `codecov/project/*` that never blocks is a classic silent break.

**pre-commit** — `.pre-commit-config.yaml` exists and its hooks/versions are
valid. Note: the top-level `ci:` block is **only** read by the pre-commit.ci
service; local/CI pre-commit ignores it (dead config when pre-commit.ci is not
used). Skips in CI are done via `SKIP`/`PREK_SKIP` env vars, not the `ci:`
block. pre-commit.ci GitHub App vs a GH Actions step (`pre-commit/action` or
`j178/prek-action`) are the two execution options; check the chosen one is
actually running.

**CI workflows (minimal set)** — lint + type-check + test on `push`/`pull_request`;
`concurrency` group to cancel superseded runs; `workflow_dispatch` where useful;
no `pull_request_target` without required-dispatch safety. Gate logic sanity:
if tests `needs:` lint, a flaky lint kills coverage/tests entirely — flag it as
a decision point.

**CI security** — actions pinned to full SHAs (or at least exact `@vX.Y.Z`
tags), minimal top-level `permissions: contents: read`, secrets never echoed,
`actions/checkout` without `persist-credentials` where possible. Optional but
recommended: `step-security/harden-runner`, `woodruffw/zizmor` (workflow
linter, supports config `.github/zizmor.yml`), CodeQL (`github/codeql-action`).

**Release automation** — either Release Drafter (draft updated as PRs merge,
good for manual release flow) or release-please (fully automated). Verify the
config uses the schema of the action version you pin (release-drafter v7 uses
`when:`/`semver-increment`, not the legacy `include-labels`/`version-resolver`),
and every label referenced in categories exists. A draft that never fills in =
broken labels, not a broken draft.

**Labels** — every label referenced by Renovate/Dependabot/release tooling must
exist. Create missing ones or drop the reference. Keep a tidy default set
(`bug`, `enhancement`, `documentation`, `dependencies`, `help wanted`, …).

**Dependabot vs Renovate** — running both duplicates security PRs. Pick one:
Renovate (recommended, one config file, broad managers) or Dependabot
(Settings→Code security and analysis). If Renovate is the bot of record,
suggest disabling Dependabot AllKnownVulnerabilities/advisory updates.

**Community files** — PR and issue templates, `SECURITY.md` (reporting path),
`CONTRIBUTING.md`, `CODEOWNERS` (review requirements), `LICENSE`.

### 5. Branch protection / rulesets

- `gh api repos/{o}/{r}/rulesets` and `/branches/main/protection`.
- If none: recommend a ruleset on `main` per the reference below, listing which
  required status checks must match the **actual** check names (inspect recent
  check runs to quote the exact names, e.g. `CI`, `Run CodeQL`, `codecov/project`).
- If protection exists: verify the required checks actually exist in CI, and
  that they are not trivially skipped when their upstream job fails.

### 6. Write the improvement report

Produce `GITHUB-PROJECT-IMPROVEMENT.md` in the repo root using the report
template below. Chat summary: verdict per area (OK / needs action / manual),
prioritized fix list (config fixes we can apply, vs. app/label/settings actions
only the maintainer can do).

## Configuration reference

### Renovate — dependency updates

- What: bot that opens PRs for outdated deps/lockfiles. Docs:
  https://docs.renovatebot.com/ · Repo:
  https://github.com/renovatebot/renovate · Schema:
  https://docs.renovatebot.com/renovate-schema.json
- Config file locations (any of): `renovate.json`, `.github/renovate.json`,
  `.renovaterc.json`, `.renovaterc`. Extends the curated preset
  `config:recommended`.
- App: install "Renovate" GitHub App (https://github.com/apps/renovate), grant
  the repo; Renovate then opens an onboarding PR. In orgs, the app may need
  "approve" if GitHub requires app approval.
- Minimal:
  ```json
  {
    "$schema": "https://docs.renovatebot.com/renovate-schema.json",
    "extends": ["config:recommended"],
    "dependencyDashboard": true,
    "lockFileMaintenance": { "enabled": true },
    "packageRules": [
      {
        "matchManagers": ["github-actions"],
        "rangeStrategy": "pin",
        "groupName": "GitHub Actions"
      },
      { "matchManagers": ["pep621"], "groupName": "Python dependencies" }
    ]
  }
  ```
- Gotchas: `addLabels:`/`labels:` must exist in the repo; `dependencyDashboard`
  is a useful visibility toggle; semantic-commit style auto-matches conventional
  repos.

### Codecov — coverage reporting/status checks

- What: coverage upload + PR status checks + report comments. Docs:
  https://docs.codecov.com · Config reference:
  https://docs.codecov.com/docs/codecov-yaml · Action:
  https://github.com/codecov/codecov-action
- App: install "Codecov" GitHub App
  (https://github.com/apps/codecov) and grant the repo; with recent action
  versions this enables _tokenless_ upload (also on forks) via OIDC:
  ```yaml
  - name: Upload coverage
    uses: codecov/codecov-action@v7
    with:
      fail_ci_if_error: true
  ```
  Requires `permissions: id-token: write` on the job. With a token, add
  `token: ${{ secrets.CODECOV_TOKEN }}` (secret must exist in the repo).
- `.codecov.yml` minimal (single-project repos: one scope, small threshold):
  ```yaml
  coverage:
    status:
      project:
        default:
          target: auto
          threshold: 0.5%
      patch:
        default:
          target: auto
  ```
- Gotchas: coverage must be scoped to the shipped package (`--cov=<pkg>`
  matching `.coveragerc` `source`), else scoped-vs-whole-repo statuses
  contradict each other; multi-component repos (e.g. DeebotUniverse/client.py:
  `python`+`rust`) legitimately use one status per component; `target: auto`
  without a threshold makes any decline red.

### pre-commit — commit-time quality gates

- What: run linters/formatters on commit and in CI. Docs:
  https://pre-commit.com · Hooks: https://pre-commit.com/hooks.html ·
  Repo: https://github.com/pre-commit/pre-commit
- Execution options: (a) pre-commit.ci App (https://pre-commit.ci —
  the `ci:` block in `.pre-commit-config.yaml` configures **only this**); (b)
  GH Actions step `pre-commit/action`
  (https://github.com/pre-commit/action) or `j178/prek-action`
  (https://github.com/j178/prek-action, run `pre-commit run --all-files` with
  the concourse-friendly prek wrapper).
- Skipping hooks in CI: use the `SKIP`/`PREK_SKIP` env var, e.g.
  `PREK_SKIP: no-commit-to-branch,mypy,pylint`.
- Renovate can auto-update hook `rev`s (manager `pre-commit`).
- Gotchas: if hooks are installed in CI via pre-commit.ci, keep `ci:
autofix_prs`/`skip` in sync; if not, drop the `ci:` block (dead config).

### Required CI workflows (minimal recommended set)

- `ci.yml`: lint (fast, cheap) + type-check + tests, on `push: [main, dev]`
  and `pull_request:` + `workflow_dispatch`, with `concurrency`:
  ```yaml
  concurrency:
    group: ci-${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}
    cancel-in-progress: true
  ```
- `codeql-analysis.yml`: scheduled + on PR, `github/codeql-action`
  (https://github.com/github/codeql-action).
- Release: `release-drafter` (see below) or release-please
  (https://github.com/googleapis/release-please).
- Optional: `actions/labeler` (https://github.com/actions/labeler) to
  auto-label PRs from paths so release/cleanup tooling works; `actions/stale`
  (https://github.com/actions/stale).
- CI security: pin actions to SHAs or exact tags (`actions/checkout@v7.0.1`),
  minimal `permissions:`, no secrets in logs, `step-security/harden-runner`
  (https://github.com/step-security/harden-runner), audit workflows with
  `woodruffw/zizmor` (https://github.com/woodruffw/zizmor).

### Release Drafter — draft changelog

- What: a GitHub Release **draft** that aggregates merged PRs. Repo:
  https://github.com/release-drafter/release-drafter ·
  Marketplace: https://github.com/marketplace/actions/release-drafter
- Workflow triggers: `push: branches: [main]` (living draft) and optionally
  `push: tags: ["v*"]` (refreshed at release time) + `workflow_dispatch`;
  permissions `contents: write` + `pull-requests: read`.
- v7 config uses `when:`/`semver-increment`/`conventional` — match the schema to
  the pinned action version. Only reference labels that exist (or pair with an
  autolabeler).

### Labels — cross-cutting dependency of Renovate/Dependabot/release tooling

- Create via Issues → **Labels** button, or
  `gh label create <name> --color <hex> --description "..."`.
- Verify: `gh label list --json name`; cross-reference every label referenced in
  `renovate.json`, release configs, stale/labeler configs.

### Dependabot

- Docs: https://docs.github.com/en/code-security/dependabot. Config:
  `.github/dependabot.yml` (same locations as Renovate). Decide one bot of
  record to avoid duplicate security PRs.

### Community files

- PR template: `.github/PULL_REQUEST_TEMPLATE.md`; issue templates:
  `.github/ISSUE_TEMPLATE/*.yml` (+ `config.yml`).
- `SECURITY.md`: https://docs.github.com/en/code-security/getting-started/adding-a-security-policy
- `CODEOWNERS`, `CONTRIBUTING.md`, `LICENSE`, `AGENTS.md` for AI contributors.

## Branch protection — best practice

Prefer **rulesets** (newer API) over classic protected branches.

Meaning of key settings:

- `pull_request` — require N approvals, dismiss stale reviews, require code
  owner review (`CODEOWNERS` must exist), require resolving conversations;
  "last push approval" re-requires review after force-push-less updates.
- `required_status_checks` — `strict` = branch must be up to date before merge;
  `contexts` = the **exact** check names from CI (verify against real check
  runs; missing names make the rule no-op). Include CI, CodeQL and Codecov.
- `deletion` + `non_fast_forward` — nobody deletes the branch or force-pushes.
- `required_signatures` — commits signed (GPG/SSH).
- `required_linear_history` — squash-only, clean history (match your merge
  method on the repo).

Create the rule via `gh api` (adjust owner/repo and check names):

```bash
gh api --method POST repos/{owner}/{repo}/rulesets \
  -f name='main protection' \
  -f target='branch' \
  -f enforcement='active' \
  -F conditions='{"ref_name":{"include":["refs/heads/main"],"exclude":[]}}' \
  -F rules='[
    {"type":"pull_request","parameters":{"required_approving_review_count":1,"dismiss_stale_reviews_on_push":true,"require_code_owner_review":true,"require_last_push_approval":true,"required_review_thread_resolution":true}},
    {"type":"required_status_checks","parameters":{"strict_required_status_checks_policy":true,"contexts":["CI","Run CodeQL","codecov/project"]}},
    {"type":"deletion"},
    {"type":"non_fast_forward"},
    {"type":"required_signatures"},
    {"type":"required_linear_history"}
  ]'
```

Docs: rulesets
(https://docs.github.com/en/repositories/configuring-branches-and-merges/managing-rulesets),
protected branches
(https://docs.github.com/en/repositories/configuring-branches-and-merges/rules/managing-protected-branches),
required status checks
(https://docs.github.com/en/repositories/configuring-branches-and-merges/rules/required-status-checks).

## Improvement report template

`GITHUB-PROJECT-IMPROVEMENT.md`:

```markdown
# GitHub Project Improvement — <owner>/<repo>

Date: <date> · Scope: <what was checked> · Tooling: <agent + skill version>

## Summary

| Area     | Status   | Note |
| -------- | -------- | ---- |
| Renovate | OK/ISSUE | ...  |

## What / How / Where

### 1. <Area>

- **Problem:** ... (evidence: file:line, API output, missing label `x`)
- **Fix:** exact config/JSON/UI steps
- **Where:** file path or URL (`Settings → ...`)
- **Learn more:** <link>
  ...

## Manual actions (agent cannot do, needs maintainer)

- GitHub App grant: ...
- Secret/branch-protection settings: ...

## Optional decisions

- Dependabot vs Renovate; decouple lint from tests; ChatGPT-style review app...
```

## Constraints

- Read-only by default for settings/accounts; do not create remote labels or
  change GitHub settings unless asked (fine-grained PATs usually cannot anyway).
- Evidence everywhere: quote check runs, PR authors, file:line, missing labels.
- Never touch git history, branch protection rules themselves, or secrets.
- Distinguish what the audit can fix (repo files) from what only the
  maintainer can (App grants, secrets, protection rules) — and say so.
- Where possible, verify _behavior_, not just file presence: a configured app
  that never fired is still broken.
