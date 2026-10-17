---
name: vm-github-pr-issues
description: Research and review GitHub issues and pull requests with read-only access, and make requested changes locally. Never write to GitHub; prepare drafts for the user to apply themselves.
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: github
---

## What I do

Use authenticated read-only GitHub MCP tools or `gh` to identify repositories,
browse issues and PRs, and review changes. Make local project changes when the
user requests them. Never perform a write to GitHub, even when asked; prepare
drafts and manual instructions for the user instead.

Use the credentials already configured for the active GitHub tools. Never ask
the user to paste a token or expose one in output. For this dotfiles repository,
see `GITHUB.md` in this skill folder for the `GITHUB_TOKEN` setup.

---

## Step-by-step

1. **Identify the repository**: run `gh repo view --json nameWithOwner -q .nameWithOwner` (or `git remote get-url origin`) to get `owner/repo`.

2. **Browse issues / PRs** (read side - prefer MCP tools so results are structured):
   - List: `list_repository_issues` / `list_repository_pull_requests` with the MCP server, or `gh issue list` / `gh pr list`.
   - Details: `get_issue` / `get_pull_request` (author login, created date, labels, state).
   - Search with `gh issue list --search "..."` / `gh pr list --search "..."` when scoping by text.

3. **Fetch a PR locally only when requested**:
   - First inspect `git status --short`, `git diff --cached`, and `git diff`.
     Preserve staged and unstaged changes separately.
   - `gh pr checkout <number>` switches the current checkout. If it is not
     clean, do not switch branches in place; ask or use a separately authorized
     worktree.
   - Confirm the resulting branch and commits with `git status --short` and
     `git log --oneline -5`.
   - Use `gh pr checkout` for local checkout. If another installed OpenCode
     integration offers PR checkout, verify its own documentation first.

4. **Review the change without submitting anything**:
   - `gh pr diff <number>` - full diff (or `git diff <base>..HEAD` for committed work).
   - `gh pr view <number>` - title, body, author, base/head refs, mergeable state.
   - Read the changed files and assess correctness, security, and tests.
   - If the review surfaces security concerns (secrets, injection, auth/authz
     problems, vulnerable dependencies), delegate a deep dive to the
     configured `security-engineer` agent through OpenCode V2's `subagent`
     tool. Give it a bounded review task and the `security-review` skill. If it
     is unavailable, report the concerns directly. Bring findings back to the
     user; do not post them automatically.

5. **Use available author information**: issue and PR results include the
   author's login and other metadata. Use a read-only MCP user lookup if
   available; otherwise omit profile details rather than adding an API call.

6. **Prepare comments or reviews, never submit them**:
   - Draft the requested comment or review body locally.
   - If useful, show the user a manual command such as
     `gh pr comment <number> --body "..."` or `gh pr review <number> --comment --body "..."`.
     Label it for the user to run; never execute it or call an MCP write tool.
   - A request to review is not a request to publish the review.

7. **Prepare a PR, never create or push it**:
   - Inspect staged and unstaged changes separately. Do not include pre-existing
     staged work in a commit unless the user identifies it as part of the PR.
   - Keep new AI edits unstaged for review. Use `vm-git-commit` if the user wants
     local commit commands. Draft a PR title/body and list the manual steps the
     user can perform after reviewing the changes.
   - A direct request to create a PR does not grant this skill write access.

## Constraints

- Preserve existing staged and unstaged changes. Never reset, clean, stage, or
  commit unless the user explicitly requests the local Git action.
- GitHub access is read-only for this skill. Never push, post a review/comment,
  change labels, create/edit/close issues or PRs, merge, or write through the
  GitHub API, even when asked. Prepare a draft or manual instructions instead.
- Never modify the token or environment files.
- If `gh` is not installed, report the blocker; in this dotfiles repository,
  `setup-ai -igh` installs it. If authentication fails, direct the user to the
  read-only token steps in `GITHUB.md`; do not suggest a write-capable login.
