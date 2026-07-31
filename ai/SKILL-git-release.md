---
name: git-release
description: Generate conventional changelog and release notes from git log and GitHub PRs between two refs
license: MIT
compatibility: opencode
metadata:
  audience: maintainers
  workflow: release
---

## What I do

Generate structured markdown release notes for the range between two git refs and write them to a file. I handle the full workflow: ref selection, log parsing, PR enrichment, grouping, link generation, file output, and release process output.

Release notes are PR-first: whenever a commit can be linked to a merged pull request, the PR is the source of truth (title, number, author), with the commit as fallback.

---

## Step-by-step

### 1. Determine refs to compare

Ask the user which two refs to diff, e.g. `v0.2.2..v0.3.0` or `origin/main..HEAD`. Default to latest tag vs `origin/main`.

Extract short names with `basename "$REF"` for display.

### 2. Get remote slug

Parse `git remote get-url origin` to extract `owner/repo`:

- **SSH** (`git@github.com:owner/repo.git`) → strip `git@`, `github.com:`, `.git`
- **HTTPS** (`https://github.com/owner/repo.git`) → strip `https://github.com/`, `.git`

Used for commit links, PR links, issue links, and the full changelog compare URL.

### 3. Get commit log

Run:

```
git log --no-merges \
  --pretty=format:"%s|%H|%h|%an|%ae" \
  --reverse --left-right \
  BASE..COMPARE
```

Each line: `subject|full_hash|short_hash|author_name|author_email`

Also collect merge commits to discover PR numbers:

```
git log --merges \
  --pretty=format:"%s|%H|%h" \
  --reverse --left-right \
  BASE..COMPARE
```

If both are empty, report no new commits and exit.

### 4. Parse each commit

Strip leading/trailing whitespace from subject.

Parse conventional commit format:

```
type(scope): message
type: message
```

**Regex**: `^([a-zA-Z0-9_\-]+)(\([a-zA-Z0-9_\-\.]+\))?:\s*(.+)$`

Lowercase the type. Detect `BREAKING CHANGE:` in the commit body or `!` after type/scope (e.g. `feat!:` or `feat(api)!:`) and flag as breaking.

### 5. Classify by type

Map types to display labels (order matters):

| Type       | Section                                    |
| ---------- | ------------------------------------------ |
| `feat`     | ✨ Features                                |
| `fix`      | 🐛 Fixes                                   |
| `docs`     | 📝 Documentation                           |
| `refactor` | ♻️ Refactoring                             |
| `perf`     | ⚡ Performance                             |
| `test`     | ✅ Tests                                   |
| `chore`    | 🔧 Chores                                  |
| `security` | 🔒 Security                                |
| `init`     | 📦 Init                                    |
| `release`  | 🏷️ Release                                 |
| `other`    | 📦 Other (fallback for unrecognized types) |

Known types per the commit-msg hook: `init`, `docs`, `refactor`, `update`, `merge`, `security`, `build`, `test`, `fix`, `publish`, `ci`, `feat`, `perf`, `chore`, `revert`, `style`, `release`.

Unknown types should fall back to `other`.

If a commit has a scope, group it under a `#### scope` subheading within its type section (e.g. `chore(deps): ...` → `#### deps` under `### 🔧 Chores`).

Supported scopes: `core`, `docs`, `tests`, `ci`, `deps`, `infra`, `config`, `api`, `auth`, `release`, `lint`, `scripts`.

### 6. Enrich with GitHub PR data (PR-first)

For each commit in the range, try to find the merged PR:

1. **Extract PR number from subject** (fast, always): patterns `(#123)`, `PR #123`, standalone `#123` (heuristic, prefer explicit patterns), and from merge-commit subjects (`Merge pull request #123 from ...`).
2. **Verify via GitHub API** (if available): for each candidate PR number, run:
   - `gh pr view N --json number,title,url,author,mergedAt,body` (if `gh` is installed and authenticated), or
   - `curl -s "https://api.github.com/repos/OWNER/REPO/pulls/N"` (respect rate limits; honor `GITHUB_TOKEN` if set)
3. **Use the PR as the primary entry** when confirmed: display the PR title (often more descriptive than the commit subject), link the PR number, and attribute to the PR author.
4. **Fallback**: if the API is unavailable (no gh, rate-limited, no network), keep the commit subject and any heuristically extracted PR number.
5. **Prefer PR title** only when it is meaningfully more descriptive than the commit subject; otherwise keep the commit subject and just attach the PR link.

Note: if the API reports an error or the PR is not found, silently fall back — never block release generation on network failures.

### 7. Detect notices

Scan commit bodies and PR bodies for:

- `BREAKING CHANGE:` description → render as `⚠️ Breaking: description`
- `MIGRATION:` or similar → render as `⚠️ Migration: description`
- `DEPRECATED:` / "is deprecated" → render as `⚠️ Deprecated: description`

If the subject contains `!` after type/scope (e.g. `feat(api)!:`) also mark as breaking.

Place these notices at the top of the release notes, before `## Highlights` / `## What's Changed`.

### 8. Detect new contributors

Collect unique author names across all commits and PRs. Compare against previous release contributors (check `git shortlog -sn BASE..COMPARE` or diff authors against commits reachable from BASE). List first-time contributors under a `## New Contributors` section, linking their first PR if known.

### 9. Compute release stats

Run `git diff --shortstat BASE..COMPARE` to get changed files/insertions/deletions, and count commits and contributors. Use for the summary line and footer.

### 10. Assemble the markdown

```
# 🚀 Release `base..compare` - YYYY-MM-DD

> N commits · M contributors · K files changed (+X −Y)

⚠️ Breaking: description
⚠️ Migration: description
⚠️ Deprecated: description

## Highlights
- **Top feature 1**: one-line summary
- **Top feature 2**: one-line summary

## What's Changed

### ✨ Features
- PR/commit message ([`hash`](commit/link)) ([#PR](pr/link)) - by @author <email>

### 🐛 Fixes
...

### 📝 Documentation
...

### ♻️ Refactoring
...

### 🔧 Chores
- message ...
#### deps
- message ...
#### ci
- message ...

### ... (all sections in order, skip empty ones)

## New Contributors
- @user made their first contribution in https://github.com/owner/repo/pull/NNN

**Full Changelog**: https://github.com/owner/repo/compare/base...compare
```

#### Highlights

Write a short curated `## Highlights` section with the 2–5 most user-visible changes (new features, major fixes, deprecations). If the release is small (fewer than ~5 commits), omit the Highlights section.

#### Section ordering

Always output sections in this fixed order (skip empty ones):

1. ✨ Features
2. 🐛 Fixes
3. 📝 Documentation
4. ♻️ Refactoring
5. ⚡ Performance
6. ✅ Tests
7. 🔧 Chores
8. 🔒 Security
9. 🏷️ Release
10. 📦 Init
11. 📦 Other

#### Link format

For each entry, prefer the PR link, fall back to the commit link:

```
- PR title ([`hash`](commit/link)) ([#PR](pr/link)) - by @author <email>
```

For `chore(deps)` updates by bots (dependabot/renovate), keep them grouped under `#### deps` — do not list each bot PR under the main Chores list unless there are only a few.

### 11. Propose version bump

Apply semver based on commit types:

- **Major**: any `BREAKING CHANGE` commits
- **Minor**: any `feat` commits (without breaking)
- **Patch**: only `fix`, `docs`, `refactor`, `perf`, `test`, `chore`, etc.

Consider project conventions (e.g. `v` prefix, initial `0.x` phases). Ask the user to confirm the proposed version before finalizing.

### 12. Write to file

Always write the generated release notes to a file. Use the version as filename:

```
release-v{MAJOR}.{MINOR}.{PATCH}.md
```

For initial releases with no prior tag, use `release-v0.1.0.md`.

Show the file path to the user after writing so they know where to find it.

---

## When to use me

Use this when you are preparing a tagged release. I handle the full workflow from log analysis and PR enrichment to proposing the version bump and providing copy-pasteable release commands.

Ask clarifying questions if the target versioning scheme is unclear or if there are multiple possible base refs.
