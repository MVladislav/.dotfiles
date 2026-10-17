---
name: vm-git-commit
description: Split working-tree changes into topic-related commits and write conventional commit messages, presented as step-by-step commands for manual execution
license: MIT
compatibility: opencode
metadata:
  audience: maintainers
  workflow: git
---

## What I do

Turn a dirty working tree into a clean sequence of topic-related commits. I
inspect what actually changed, group files by concern, write conventional
commit messages that match the repository's history style, and present exact
`git add` + `git commit` commands the user can run by hand, step by step.

The output is a plan for the user to execute - I never commit or push unless
explicitly asked.

---

## Step-by-step

### 1. Survey the working tree

- `git status --short` - every modified/untracked file, plus staged (`MM`)
  vs unstaged state.
- `git diff --cached --stat` - size of staged changes.
- `git diff --stat` - size of unstaged changes.
- `git diff --cached -- <file>` and `git diff -- <file>` - inspect both layers
  for files with staged and unstaged hunks; never group by filename alone.
- `git log --oneline -15` - learn the repo's message style (prefixes,
  casing, length) and mirror it.
- `git status -sb` - note branch sync with origin.

### 2. Group files into topic-related commits

- One topic per commit: infra/config, docs, feature, fix, formatting.
- Separate the _user's own feature work_ from the _lint/formatting fixes_
  you applied - they belong in different commits.
- A single file carrying multiple concerns (e.g. `setup-ai` containing both
  UX changes and a new tool install) can be split with `git add -p`; if the
  mix is too entangled, bundle it and say so explicitly in the plan.
- New files plus the `.gitignore` exceptions that track them should land in
  the same commit.
- Preserve the existing index. Keep staged and unstaged changes as separate
  layers when grouping; do not reset or restage merely to simplify the plan.
- Order commits logically: infra/foundation first, features after.

### 3. Write commit messages

- Conventional commits: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`,
  `test:`, `perf:`, `ci:`.
- **Scopes are optional and rarely used here.** Decide from the repository's own
  history, not from the spec's `type(scope):` muscle memory: run
  `git log --format='%s' -40` and look for scoped subjects first. Feature work is
  unscoped (`feat:`, `fix:`, `refactor:`). Scopes are reserved for mechanical,
  self-describing sweeps - `chore(deps):` version bumps, `chore(config):` config
  refreshes, `chore(lint):` tool passes, `fix(#N):` issue references. Never
  invent a scope from a file or component name (`feat(setup-ai):`, `fix(api):`);
  that pattern appears nowhere in this history.
- Imperative mood, lowercase after the prefix, subject ≤ ~72 chars.
- Match the repository's historical style (some repos use long-form
  subjects like `chore: enhance setup-ai with fzf preselects`).
- Only add a body when it explains _why_, not what. Default to the subject alone:
  a bullet list of implementation facts ("added flag X", "uses Y") restates the
  diff and is noise. Put that material in the code or its docs instead, and add a
  body only when the change is genuinely surprising and cannot be explained
  anywhere cheaper.

### Repository commit policy for this dotfiles repository

The repository's `git/commit-msg` hook is the source of truth for accepted
subjects. It checks the first line only. Its general format is:

```text
<type>(<scope>): <subject>
```

- Types are limited to: `init`, `docs`, `refactor`, `update`, `merge`,
  `security`, `build`, `test`, `fix`, `publish`, `ci`, `feat`, `perf`, `chore`,
  `revert`, `style`, and `release`.
- Scopes are optional and, when present, limited to: `core`, `docs`, `tests`,
  `ci`, `deps`, `infra`, `config`, `api`, `auth`, `release`, `lint`, and
  `scripts`. The hook expects the lowercase spellings shown here.
- The general pattern requires at least three characters in the subject; the
  special `fix(#N)` pattern only requires a non-empty subject.
- Bare `fix: ...` is rejected. The hook has a special accepted form
  `fix(#123): ...` for an issue number. Its implementation also accepts
  `fix(<allowed-scope>): ...` without an issue number, despite the comment in
  `git/commit-msg`; avoid relying on that inconsistency and use `fix(#123): ...`
  when an issue exists.
- `release: ...` is accepted with a warning. Prefer `chore(release): ...` as
  the hook recommends.
- Most recent repository subjects are unscoped `feat:`, `chore:`, `refactor:`,
  or `docs:` forms. Use scopes sparingly and only when they add useful grouping;
  `chore(deps): ...` is an established scoped example.

`git/.gitconfig` sets `core.hooksPath` to `~/.git-hooks`. The `setup` workflow
links `git/commit-msg` and `git/pre-commit` there. The commit-msg hook validates
the subject and the pre-commit hook checks the configured global email before
running `prek` or `pre-commit`. The Git config template uses SSH signing format;
`setup_gitconfig` enables signing only when a signing key is selected. Check the
effective user config rather than assuming signing is enabled.

Hook caveat: `git/pre-commit` uses `exec` to replace itself with `prek` or
`pre-commit`, so the non-ASCII filename and trailing `diff-index --check`
commands later in that script are unreachable on those paths. Do not claim those
checks ran unless the hook is repaired and verified. The configured hook
framework may also modify files; inspect staged and unstaged diffs separately
after it runs.

### 4. Present the plan

For each commit, output a copy-pasteable block:

```bash
git add <paths...>
git commit -m "<subject>"
```

Number the commits and give a step-by-step walkthrough. Keep the user's
existing staging intact and state which changes are staged versus unstaged.

### 5. Verification

End with the checks the user should run after the last commit:

```bash
git status --short       # compare against the agreed pre-commit baseline
git diff --cached        # confirm the intended staged set
git log --oneline -N     # expect: the N new commits
```

Do not expect an empty worktree if unrelated staged or unstaged work existed
before the plan.

Optionally `pre-commit run --all-files` as a final gate before pushing.

## Constraints

- Never run `git commit`, `git add`, `git push`, or `git reset` yourself
  unless the user explicitly asks - the user executes the plan manually.
- Never amend, rebase, force-push, or commit on behalf of the user.
- Never propose commit messages that include secrets or credentials.
- Respect pre-existing staging: check for `MM`-style states and re-stage
  edited-but-unstaged files in the plan.
