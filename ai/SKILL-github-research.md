---
name: github-research
description: Research issues, PRs, or discussions against the project itself — existing issues, pull requests, discussions, code, docs, and git history — to answer requests with knowledge already available, falling back to online research when the project has no answer; writes a research report file for later use
license: MIT
compatibility: opencode
metadata:
  audience: maintainers
  workflow: github
---

## What I do

For a given issue or discussion, find out whether the answer or requested
information already exists inside the project: previously answered issues,
open or merged pull requests, discussions, code, docs, and git history. Output
an evidence-backed verdict so the requester can be helped fast, and clearly
separate what is known in-project from what still needs manual or online
research.

Prerequisites: `gh` installed and `GITHUB_TOKEN` set (see `GITHUB.md` in the
`github` skill folder), plus a local clone of the project.

---

## Step-by-step

### 1. Identify the target

- Get `owner/repo` with `gh repo view --json nameWithOwner -q .nameWithOwner`
  (or `git remote get-url origin`).
- Fetch the target item:
  - Issue: `gh issue view <number>` (add `--comments` for the full thread).
  - PR: `gh pr view <number>`.
  - Discussion: `gh discussion view <number>` (add `--comments` for the
    thread; `gh discussion view` also accepts a discussion URL or comment
    URL). If `gh discussion` is not available on your gh version, fall back
    to a GraphQL search:
    `gh api graphql -f query='query($q: String!) { search(query: $q, type: DISCUSSION, first: 5) { nodes { ... on Discussion { title url number body } } } }' -F q="repo:<owner/repo> <terms>"`.
- Restate the question in one or two sentences — searching works much better
  against a distilled question than against the raw wall of text.

### 2. Search inside the project first (in this order)

- **Code**: grep the working tree for key terms, exact error messages, API or
  CLI option names, and feature names (e.g. `grep -ri "term" .` or the Grep
  tool). Look at README, `docs/`, and `*.md` files too.
- **Git history**: `git log --all --oneline --grep="<term>"` and
  `git log -S"<term>" --all` to find where a feature was added, changed, or
  removed.
- **Issues**: `gh issue list --state all --search "<terms>"` — search terms
  are AND-joined; quote phrases and add `OR` between alternatives.
- **PRs**: `gh pr list --state all --search "<terms>"` (or
  `gh search prs --repo <owner/repo> <terms>`).
- **Discussions**: `gh discussion list --search "<terms>"` (add
  `--state all` to include answered ones; preview command — fall back to the
  GraphQL `search` from step 1 if unavailable).
- **Labels**: `gh issue list --label <label>` when the target fits a known
  label (bug, enhancement, wontfix, ...).

### 3. Classify the finding

- **ANSWERED** — an existing issue/PR/discussion/code/doc directly answers
  it: cite the number, URL, and a short snippet, plus `file:line` or commit
  hash for code findings.
- **PARTIAL** — related context exists but the exact question is not covered:
  cite what exists and name the gap explicitly.
- **NOT FOUND IN PROJECT** — nothing relevant found; move to online research.

### 4. Online fallback (only when the project has no answer)

- Search the web for the exact error message, feature name, or question.
- Check official documentation (project site, GitHub docs, man pages),
  package/API references, and the upstream tracker if this is a fork or
  depends on another project.
- Cite every external source with its URL and label it as external.

### 5. Write the research report file

- Save the full report to `research/<type>-<number>.md` relative to the
  current working directory (create the `research/` folder if needed), with
  `<type>` being `issue`, `pr`, or `discussion`.
- Include: the target (type, number, title, URL), the restated question, the
  verdict, the evidence (with citations), the search terms tried, any online
  sources with URLs, and the draft reply.
- Mention the report file path in your chat answer so the user knows where to
  find it.

### 6. Report

- One-line verdict: `answered in project` / `partially answered` / `needs
manual or online research`.
- For answered: the answer itself (summary), the evidence, and where it lives.
- For partial: what is known, what is missing.
- For not found: which search terms were tried, what online research found,
  and a suggested next step (reproduce locally, ask upstream, open a new
  issue).
- Close with a short draft reply the user can adapt for the requester,
  marking project facts vs external sources.

## Constraints

- Read-only for project files and GitHub items: never modify project files,
  never create or edit issues/PRs/discussions, never push. The only write is
  the research report file from step 5.
- Base every claim on evidence: issue/PR numbers, `file:line`, commit hashes,
  or URLs. Never invent search results.
- Search the project first; web research is only the fallback.
- Respect the local clone state: use `git log` for history, grep/Glob for
  current code, `gh` for everything remote.
- If the item is not accessible (private repo, missing token, unknown
  discussion), stop and tell the user how to fix access instead of guessing.
