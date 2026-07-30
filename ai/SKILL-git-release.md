---
name: git-release
description: Generate conventional changelog and release notes from git log between two refs
license: MIT
compatibility: opencode
metadata:
  audience: maintainers
  workflow: release
---

## What I do

Generate structured markdown release notes from conventional commits between two git refs and write them to a file. I handle the full workflow: ref selection, log parsing, grouping, link generation, file output, and release process output.

---

## Step-by-step

### 1. Determine refs to compare

Ask the user which two refs to diff, e.g. `v0.2.2..v0.3.0` or `origin/main..HEAD`. Default to latest tag vs `origin/main`.

Extract short names with `basename "$REF"` for display.

### 2. Get remote slug

Parse `git remote get-url origin` to extract `owner/repo`:

- **SSH** (`git@github.com:owner/repo.git`) → strip `git@`, `github.com:`, `.git`
- **HTTPS** (`https://github.com/owner/repo.git`) → strip `https://github.com/`, `.git`

Used for commit links, PR links, and the full changelog compare URL.

### 3. Get commit log

Run:

```
git log --no-merges \
  --pretty=format:"%s|%H|%h|%an|%ae" \
  --reverse --left-right \
  BASE..COMPARE
```

Each line: `subject|full_hash|short_hash|author_name|author_email`

If empty, report no new commits and exit.

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

### 6. Build links

For each commit, construct:

- **Commit link**: ``[`short_hash`](https://github.com/owner/repo/commit/full_hash)``
- **PR link**: Extract PR number from subject patterns:
  - `(#123)` → `[#123](https://github.com/owner/repo/pull/123)`
  - `PR #123` → same
  - Standalone `#123` → same (heuristic, prefer explicit patterns)
- **Author**: `by @author_name <author_email>`

Format each line:

```
- message ([`hash`](commit/link)) ([#PR](pr/link)) - by @author <email>
```

### 7. Detect breaking changes and migration notices

Scan commit bodies for:

- `BREAKING CHANGE:` description → render as `⚠️ Breaking: description`
- `MIGRATION:` or similar → render as `⚠️ Migration: description`

If the subject contains `!` after type/scope (e.g. `feat(api)!:`) also mark as breaking.

Place these notices at the top of the release notes, before `## What's Changed`.

### 8. Detect new contributors

Collect unique author names across all commits. Compare against previous release contributors (check `git shortlog -sn BASE..COMPARE` or diff authors). List first-time contributors under a `## New Contributors` section.

### 9. Assemble the markdown

```
# 🚀 Release `base..compare` - YYYY-MM-DD

⚠️ Breaking: description
⚠️ Migration: description
✨ New:
- bullet for each feature

## What's Changed

### ✨ Features
- message ([`hash`](commit/link)) ([#PR](pr/link)) - by @author <email>

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

---

## Notes
- Create release branch: `git checkout -b release/x.x.x`
- Update version file (pyproject.toml, package.json, etc.)
- Run dependency sync: `uv sync --all-groups` (Python) / `npm ci` (Node)
- Release commit: `chore(release): bump version x.x.x`
- Create PR and merge/rebase into main
- Tag: `git tag -a vx.x.x -m 'Release version x.x.x'`
- Push tag: `git push origin vx.x.x`
```

### Section ordering

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

### 10. Propose version bump

Apply semver based on commit types:

- **Major**: any `BREAKING CHANGE` commits
- **Minor**: any `feat` commits (without breaking)
- **Patch**: only `fix`, `docs`, `refactor`, `perf`, `test`, `chore`, etc.

Ask the user to confirm the proposed version before finalizing.

### 11. Write to file

Always write the generated release notes to a file. Use the version as filename:

```
release-v{MAJOR}.{MINOR}.{PATCH}.md
```

For initial releases with no prior tag, use `release-v0.1.0.md`.

Show the file path to the user after writing so they know where to find it.

---

## When to use me

Use this when you are preparing a tagged release. I handle the full workflow from log analysis to proposing the version bump and providing copy-pasteable release commands.

Ask clarifying questions if the target versioning scheme is unclear or if there are multiple possible base refs.
