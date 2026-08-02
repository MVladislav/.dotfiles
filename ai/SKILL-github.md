---
name: github
description: Browse GitHub issues and pull requests, review PRs locally with AI, comment on or create PRs
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: github
---

## What I do

Work with GitHub issues and pull requests from a local clone: browse issues and
PRs (including author info), fetch a PR branch locally, review it with AI, post
reviews/comments, and create new PRs. Uses the GitHub MCP server tools for
reading and the `gh` CLI for actions that touch the local git state.

Prerequisites: `GITHUB_TOKEN` set (see `GITHUB.md` in this skill folder), and
`gh` installed.

---

## Step-by-step

1. **Identify the repository**: run `gh repo view --json nameWithOwner -q .nameWithOwner` (or `git remote get-url origin`) to get `owner/repo`.

2. **Browse issues / PRs** (read side — prefer MCP tools so results are structured):
   - List: `list_repository_issues` / `list_repository_pull_requests` with the MCP server, or `gh issue list` / `gh pr list`.
   - Details: `get_issue` / `get_pull_request` (author login, created date, labels, state).
   - Search with `gh issue list --search "..."` / `gh pr list --search "..."` when scoping by text.

3. **Fetch a PR to work on it** (always use `gh` for local git work):
   - `gh pr checkout <number>` — downloads the PR branch and switches to it.
   - `opencode pr <number>` — native alternative that fetches the PR branch and
     immediately starts opencode on it (outside the TUI).
   - Confirm state: `git status`, `git log --oneline -5` to see the PR's commits.

4. **Review the change**:
   - `gh pr diff <number>` — full diff (or `git diff <base>..HEAD` for committed work).
   - `gh pr view <number>` — title, body, author, base/head refs, mergeable state.
   - Read the changed files and assess correctness, security, and tests.

5. **Work with the author info**: PR/issue results include `author.login`; use
   `gh api users/<login>` if profile details (name, bio) are needed.

6. **Comment or review**:
   - General comment: `gh pr comment <number> --body "..."`.
   - Formal review: `gh pr review <number> --approve` / `--comment` / `--request-changes` (optionally with `--body`).
   - Issue comment: `gh issue comment <number> --body "..."`.
   - For line-level suggestions prefer the MCP tools (`create_pull_request_review` with a threaded review payload) when available.

7. **Create a new PR** (after implementing):
   - Commit and push: `git push -u origin <branch>`.
   - `gh pr create --title "..." --body "..."` (add `--fill` to reuse the commit/PR template).
   - Show the result with the returned PR URL.

## Constraints

- Never push to `main` directly; always work on a feature branch.
- Never modify the token or environment files.
- If `gh` is not installed, stop and tell the user to install it
  (`setup-ai -igh`); if `gh` reports an auth problem, tell the user to set
  `GITHUB_TOKEN` (see `GITHUB.md`) — do not attempt to work around it.
