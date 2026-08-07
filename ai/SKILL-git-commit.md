---
name: git-commit
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

The output is a plan for the user to execute — I never commit or push unless
explicitly asked.

---

## Step-by-step

### 1. Survey the working tree

- `git status --short` — every modified/untracked file, plus staged (`MM`)
  vs unstaged state.
- `git diff HEAD --stat` — size of each change (splitting a 700-line rework
  from a 2-line fix matters).
- `git diff HEAD -- <file>` — read the actual hunks of files you are unsure
  about _before_ grouping them; never group by filename alone.
- `git log --oneline -15` — learn the repo's message style (prefixes,
  casing, length) and mirror it.
- `git status -sb` — note branch sync with origin.

### 2. Group files into topic-related commits

- One topic per commit: infra/config, docs, feature, fix, formatting.
- Separate the _user's own feature work_ from the _lint/formatting fixes_
  you applied — they belong in different commits.
- A single file carrying multiple concerns (e.g. `setup-ai` containing both
  UX changes and a new tool install) can be split with `git add -p`; if the
  mix is too entangled, bundle it and say so explicitly in the plan.
- New files plus the `.gitignore` exceptions that track them should land in
  the same commit.
- Order commits logically: infra/foundation first, features after.

### 3. Write commit messages

- Conventional commits: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`,
  `test:`, `perf:`, `ci:`.
- Imperative mood, lowercase after the prefix, subject ≤ ~72 chars.
- Match the repository's historical style (some repos use long-form
  subjects like `chore: enhance setup-ai with fzf preselects`).
- Only add a body when it explains _why_, not what.

### 4. Present the plan

For each commit, output a copy-pasteable block:

```bash
git add <paths...>
git commit -m "<subject>"
```

Number the commits and give a step-by-step walkthrough. Start with a
`git reset` if everything is staged and you want a clean slate, or keep the
user's existing staging — state which you chose.

### 5. Verification

End with the checks the user should run after the last commit:

```bash
git status --short      # expect: empty
git log --oneline -N    # expect: the N new commits
```

Optionally `pre-commit run --all-files` as a final gate before pushing.

## Constraints

- Never run `git commit`, `git add`, `git push`, or `git reset` yourself
  unless the user explicitly asks — the user executes the plan manually.
- Never amend, rebase, force-push, or commit on behalf of the user.
- Never propose commit messages that include secrets or credentials.
- Respect pre-existing staging: check for `MM`-style states and re-stage
  edited-but-unstaged files in the plan.
