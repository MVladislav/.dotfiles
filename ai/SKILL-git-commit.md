---
name: vm-git-commit
description: Inspect Git changes, group them into logical commits, draft clear conventional commit titles and bodies, and prepare manual staging/commit, branch, and pull request plans without performing Git mutations
license: MIT
compatibility: opencode
metadata:
  audience: maintainers
  workflow: git
---

## What I do

Turn a dirty working tree into a reviewable, topic-based commit plan. Inspect
the actual changes, preserve and account for the index as it is, group changes
into independently understandable commits, and provide each commit's staging
instructions, title, and (when useful) body for the user to execute manually.

This skill is advisory only. The user performs every Git mutation themselves.
Never stage or unstage, run `git add`, `git commit`, `git reset`, `git stash`,
switch or create branches, cherry-pick, rebase, merge, push, or otherwise change
the repository or Git metadata. This remains true even if a prompt asks for the
workflow to be carried out: give the user the exact plan and commands, but do
not execute the mutations. Read-only inspection commands are allowed.

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
- Identify the current branch. If it is `main` (or the repository's default
  branch), flag that contribution work should normally go on a topic branch;
  do not create or switch to one. If staged and unstaged versions of a file
  differ, inspect both before proposing how to split or preserve them.

### 2. Group files into topic-related commits

- One coherent, independently reviewable topic per commit. Separate unrelated
  features, fixes, docs, generated files, or formatting-only work; do not split
  a tightly coupled change just to minimize commit size.
- Separate the _user's own feature work_ from the _lint/formatting fixes_
  you applied - they belong in different commits.
- For every proposed commit, list the exact paths (and, if needed, hunks) that
  belong in it, then provide the matching manual staging command and message.
  Check whether path-based `git add` is sufficient. When one file contains
  changes for multiple commits, explain a safe interactive split (`git add -p`
  or `git add -e`) and which hunks belong in each commit; never stage it for the
  user. If changes cannot be cleanly separated, keep them together and explain
  why.
- New files plus the `.gitignore` exceptions that track them should land in
  the same commit.
- Preserve the existing index. Distinguish already-staged changes from
  unstaged/untracked changes. Do not recommend a blanket reset or broad add that
  sweeps unrelated user work into a commit. If a file has staged and unstaged
  hunks, make clear which version the commit command will include; explain any
  user-run staging needed to make the planned sequence possible.
- Order commits by dependency and review flow; state each commit's intended
  contents, not just its paths.

### 3. Write commit messages

- Build each message as a **title (header) plus an optional body**. The title
  is a concise, standalone summary of the commit's primary change; the body is
  for key highlights, rationale, tradeoffs, or context a reviewer needs. Do
  not cram a change list into the title, and do not make the body merely repeat
  the title. Separate title and body with a blank line. Use concise bullets in
  the body when there are several important highlights. Omit the body only
  when the title fully communicates a simple change; when the user asks for
  highlights, put them in the body.
- Choose the type by the **intent**, not the file extension:
  - `feat`: add or materially expand user-facing capability.
  - `fix`: correct a defect or unintended behavior; use only when existing
    behavior was wrong. Do not use it for new functionality, routine updates,
    cleanup, or documentation-only changes.
  - `docs`: documentation-only changes.
  - `refactor`: restructure without changing intended behavior.
  - `test`: test-only changes.
  - `chore`: maintenance that does not fit a more meaningful type. Use `build`,
    `ci`, `perf`, `security`, `style`, or another allowed type when that is the
    actual intent.
    Use other types only when they accurately describe the change. Never invent
    a type that repository policy does not allow.
- **Fix syntax is policy-specific.** Inspect the repository's hook/contributing
  docs and recent history before proposing `fix`. In this dotfiles repository,
  bare `fix: ...` is rejected: use `fix(#123): ...` only for a real issue
  number, or `fix(<allowed-scope>): ...` with a scope the hook permits. Never
  invent an issue number or scope to make a title pass. If there is no truthful
  permitted form, explain the constraint and ask how the user wants to proceed
  rather than mislabeling the change. Other repositories may allow bare `fix:`;
  follow their verified policy, not this local exception.
- **Scopes are optional and rarely used here.** Decide from the repository's own
  history, not from the spec's `type(scope):` muscle memory: run
  `git log --format='%s' -40` and look for scoped subjects first. Feature work is
  unscoped (`feat:`, `fix:`, `refactor:`). Scopes are reserved for mechanical,
  self-describing sweeps - `chore(deps):` version bumps, `chore(config):` config
  refreshes, and `chore(lint):` tool passes. Never invent a scope from a file
  or component name (`feat(setup-ai):`, `fix(api):`); that pattern appears
  nowhere in this history. A fix must follow the special local syntax below.
- Keep type/scope lowercase and write a clear, specific title naming the
  outcome. Avoid vague titles, implementation trivia, and trailing
  punctuation. Aim for ≤ ~72 characters while prioritizing a truthful summary.
- Match the repository's historical style (some repos use long-form
  subjects like `chore: enhance setup-ai with fzf preselects`).
- Include a body when the title alone leaves important reviewer context
  unclear. Capture key highlights and why they matter, notable behavior or
  compatibility implications, and relevant validation. Do not narrate every
  file or restate the diff. Keep it concise and specific to that commit.

### Repository commit policy for this dotfiles repository

The repository's `git/commit-msg` hook is the source of truth for accepted
**titles** (it checks the first line only). Its general format is:

```text
<type>(<scope>): <subject>
```

- Types are limited to: `init`, `docs`, `refactor`, `update`, `merge`,
  `security`, `build`, `test`, `fix`, `publish`, `ci`, `feat`, `perf`, `chore`,
  `revert`, `style`, and `release`.
- Prefer the type that best matches intent from this allowed list. Common
  choices are `feat`, `fix` (with the special syntax below), `docs`,
  `refactor`, `test`, `chore`, `build`, `ci`, `perf`, and `security`.
- Do not use `update` as a catch-all for ordinary changes: although the hook
  accepts it, prefer the more precise type (`feat`, `docs`, `chore`, etc.).
- Scopes are optional and, when present, limited to: `core`, `docs`, `tests`,
  `ci`, `deps`, `infra`, `config`, `api`, `auth`, `release`, `lint`, and
  `scripts`. The hook expects the lowercase spellings shown here.
- The general pattern requires at least three characters after the prefix; the
  special `fix(#N)` pattern only requires a non-empty subject.
- Bare `fix: ...` is rejected. The hook has a special accepted form
  `fix(#123): ...` for an issue number. Its implementation also accepts
  `fix(<allowed-scope>): ...` without an issue number, despite the comment in
  `git/commit-msg`. This is actual hook behavior: a scoped fix such as
  `fix(config): preserve client ip` passes the regex, while a bare `fix:` does
  not. Prefer `fix(#123): ...` when there is a real issue; otherwise use a
  truthful allowed scope for a defect. Never invent either one.
- Treat the hook as a format gate, not the complete message style guide. It
  checks only the first line; the body is not validated. It checks the type,
  optional exact allowed scope, `: ` separator, and minimum title length, but
  does not enforce the recommended 72-character limit, imperative wording,
  semantic correctness, or a meaningful body. Its regex is not end-anchored,
  so do not treat every string it happens to accept as a good title. Follow
  this skill's quality guidance in addition to passing the hook.
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

### Message example

```text
feat: add CrowdSec protection for Traefik

- Add the Compose and middleware guidance for LAPI decisions and AppSec.
- Document secret-file configuration and end-to-end verification.
```

Use body bullets only when they convey meaningful highlights; adapt the type
to the actual change and repository policy. For this repository, a fix example
needs a real issue or permitted scope, such as
`fix(#123): preserve client ip behind proxy` (real issue required) or
`fix(config): preserve client ip behind proxy` (only if `config` is an allowed
hook scope).

### 4. Branch and contribution plan

When the current branch is `main` or the repository's default branch, recommend
that the user create a topic branch before committing. Suggest a short,
lowercase, hyphenated name based on the change, such as
`feat/crowdsec-traefik-skill` or `fix/sessionizer-path`, and show the manual
command, for example `git switch -c feat/crowdsec-traefik-skill`. Adapt the
prefix/format to repository convention and state assumptions; do not create or
switch branches. Inspect repository guidance/history rather than assuming the
base, remote, or naming convention.

For work intended for contribution/review, draft a copy-pasteable PR title and
description. Include the outcome, key implementation highlights, validation
actually performed (and checks still needed), and relevant risks or notes.
Inspect and follow a repository PR template when present. Never claim tests or
checks that were not performed. For clearly local-only work, a PR draft is
optional.

### 5. Present the plan

For each commit, state its purpose and included paths/hunks, then output the
matching manual staging and commit commands. Include a body when warranted:

```bash
git add <paths...>
git commit -m "<type>(<scope>): <clear title>" \
  -m "<key highlights and/or rationale>"
```

Use one `-m` for the title and a second for the body; omit the second only
when a body is unnecessary. Number commits in execution order. Keep the user's
existing staging intact and state what is staged, unstaged, and what manual
staging each commit requires. Commands are proposals for the user, never
actions for the agent.

Remember that `git commit` records the **entire index**, not only the paths
listed in the most recent `git add`. Before each proposed commit, compare the
index with that commit's intended contents. If unrelated changes are already
staged, call that out and explain the manual index adjustment needed; never
suggest committing while unrelated staged work would be swept in. Do not use
`git add .` or `git add -A` when it could include unrelated files.

### 6. Verification

End with the checks the user should run after the last commit:

```bash
git status --short       # compare against the agreed pre-commit baseline
git diff --cached        # confirm the intended staged set
git log --oneline -N     # expect: the N new commits
```

Do not expect an empty worktree if unrelated staged or unstaged work existed
before the plan.

Optionally recommend relevant tests or `pre-commit run --all-files` as a final
gate before pushing. Distinguish checks already run from checks the user should
run. Never push.

## Constraints

- Never perform Git mutations: no staging/unstaging, `git add`, `git commit`,
  `git reset`, `git stash`, branch creation/switching, cherry-pick, rebase,
  merge, push, amend, or force-push. This is unconditional, including when
  explicitly asked; provide detailed manual instructions instead.
- Never propose commit messages that include secrets or credentials.
- Respect pre-existing staging: inspect and account for `MM`-style states.
  Never alter the index; explain how the user can stage only intended changes,
  including interactive hunk selection when necessary.
