# GitHub Token for AI workflows

A single token is used by three things:

| Consumer                                                | Where                                           | Variable       |
| ------------------------------------------------------- | ----------------------------------------------- | -------------- |
| opencode GitHub MCP (read issues/PRs)                   | `setup-ai` → `OPENCODE_CONFIG_MCP_GITHUB`       | `GITHUB_TOKEN` |
| `gh` CLI (pr view, pr checkout, issue list)             | honors `GH_TOKEN`, falls back to `GITHUB_TOKEN` | `GITHUB_TOKEN` |
| dotfiles update checks (`github_api` in `setup-helper`) | raises API rate limit to 5000/h                 | `GITHUB_TOKEN` |

So **one variable, `GITHUB_TOKEN`, is enough for everything**.

## 1. Create a token

**Fastest: open this pre-filled link** — GitHub supports URL parameters that
pre-select everything (name, expiration, and read-only repository permissions):

<https://github.com/settings/personal-access-tokens/new?name=Personal+Access+(read+only)&description=Read-only+token+for+opencode+and+gh&expires_in=90&administration=read&contents=read&issues=read&pull_requests=read>

Then only:

1. Pick **Resource owner** (your account).
2. Pick **Repository access** → _All repositories_ or _Only select repositories_.
   ⚠️ The **"Repositories" permission tab only appears** for those two options —
   with _Public repositories_ selected, GitHub hides repository permissions
   entirely.
3. Verify the **"Repositories" tab** already shows `Metadata`, `Contents`,
   `Issues`, `Pull requests` = **Read-only** — the URL pre-filled them.
4. Click **Generate token**. Copy the token (`github_pat_...`), it is shown only once.

**Manual way** (if you prefer clicking through): under **Permissions** the
page uses a tabbed permission picker with two tabs — **"Repositories"** and
**"Account"** (plus "Organization" if the resource owner is an org). Note: the
**"Repositories" tab only appears when Repository access is _All repositories_
or _Only select repositories_** — with _Public repositories_ selected it is
hidden. The empty state you see by default ("No account permissions added
yet", "User permissions permit access to resources under your personal GitHub
account") belongs to the **Account** tab — **leave it untouched**. Click the
**"Repositories"** tab, then **"Add permissions"** (search box, top right),
search for and select each of these, and set the access level to **Read-only**:

- `Metadata` → Read-only (**always auto-included**, cannot be disabled — required)
- `Administration` → Read-only _(needed by `gh dash` to read branch protection rules — see `SKILL-github.md`; requires admin access to the repos it is scoped to)_
- `Issues` → Read-only _(to list/read issues and author info)_
- `Pull requests` → Read-only _(to read PRs, diffs, reviews)_
- `Contents` → Read-only _(to read files/commits/branches via the MCP `get_file_contents`, `list_commits`, …)_

> "Read-only" means exactly that: the AI can browse and review, but cannot
> comment on or create PRs. If you later want AI to open/comment on PRs,
> create a **separate** token with `Pull requests → Read and write` — never
> widen this one.
>
> Note: fine-grained tokens show all MCP tools regardless of permissions
> (GitHub API enforces), so you'll get clear `403 Insufficient permissions`
> errors for anything the token can't do — that is expected.

## 2. Store it

The token must exist in the **shell environment** when opencode starts —
opencode does not auto-load `.env` files for `{env:}` substitution. Your
profiles already source a dedicated, gitignored secrets file:

```bash
echo 'export GITHUB_TOKEN=github_pat_xxxxxxxx' >> ~/.profile-secrets
chmod 600 ~/.profile-secrets
```

`~/.profile-secrets` is created by `setup_profiles`, lives outside the dotfiles
repo (never committed), and is sourced from `.zshenv`/`.bashrc`, so opencode and
`gh` inherit it in every new shell.

Start a new shell (or `source ~/.zshenv`) and verify:

```bash
echo ${GITHUB_TOKEN:+set}   # -> set
curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
  https://api.github.com/rate_limit | jq .resources.core
```

### Alternative: project `.env`

A project-local `.env` (gitignored) works for `gh` and tools that read `.env`
themselves, but **not** for opencode's `{env:GITHUB_TOKEN}` substitution — that
feature is still an open request (anomalyco/opencode#10458, #21187). If you use
a project `.env`, you must also export it from your shell profile. Prefer
`~/.profile-secrets`.

## 3. gh CLI

`gh` picks up `GITHUB_TOKEN` automatically (precedence: `GH_TOKEN` →
`GITHUB_TOKEN` → stored credentials), so no `gh auth login` is needed. Note
that the environment variables **override** stored credentials, so while
`GITHUB_TOKEN` is exported, gh always uses the fine-grained token.

### Known limitation: `gh status`

`gh status` reads `GET /notifications`, which fine-grained tokens **cannot
access at all** — GitHub offers no fine-grained "notifications" permission
(it is classic-token-only). No permission addition fixes this; the command
keeps returning `HTTP 403: Resource not accessible by personal access token`.
Everything needed for the AI workflow (`gh pr view/checkout/diff`,
`gh issue list`, `gh api`, …) works fine.
