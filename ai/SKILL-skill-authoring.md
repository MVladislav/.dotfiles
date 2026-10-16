---
name: vm-skill-authoring
description: Add, rename, retire, or externally source a skill in this dotfiles repo - the wiring steps (ai/SKILL-*.md, setup-ai-config symlink, .gitignore allowlist), naming and description conventions, shared companion docs, the external-repo skill fetch and prune logic, and the sibling MCP/agent/LSP/provider pickers a skill often also needs.
license: MIT
compatibility: opencode
metadata:
  audience: maintainers
  opencode/autoinvoke: "false"
  workflow: development
---

## What I do

Turn "I want a skill that does X" into a skill that is **wired, tracked, and
discoverable** in this repo, and tell you honestly when the request is better
served by a script or an agent instead.

A `SKILL.md` on disk is not a skill. It becomes one only when three more things
are true: it is symlinked into `~/.config/opencode/skills/<id>/`, it is
allow-listed in `.gitignore` (the `ai/` tree is ignored wholesale), and its
`name:` matches the id you will type. Miss any one and you get a skill that
appears to work locally and vanishes later - the exact failure this skill exists
to prevent.

---

## Step-by-step

### 1. Pick the id - the name you will type

- Lowercase kebab-case, `^[a-z0-9]+(-[a-z0-9]+)*$`, 1-64 chars.
- `vm-` prefix for skills this repo owns. Upstream-fetched skills keep their
  upstream name (`code-review`, `gh-review-requests`) because their directory
  comes from the fetch, not from us.
- Short, and it says **what it does**, not what category it is in:
  `vm-git-commit`, `vm-repo-setup`, `vm-docker-stack-ops` - good;
  `vm-github`, `vm-skills`, `vm-vm` - bad, they collide with siblings and tell
  you nothing at the `@` picker.
- The id must be **identical** in four places (steps 2-4). One character off and
  opencode silently drops the skill from its list.

### 2. Write the file - `ai/SKILL-<id>.md`

Frontmatter contract (opencode v2, `~/.config/opencode/skills/<id>/SKILL.md`):

```yaml
---
name: vm-skill-authoring # MUST equal <id>
description: <what it does> + <when to reach for it>
license: MIT
compatibility: opencode
metadata:
  audience: maintainers # free-form, our own convention
  workflow: development
  opencode/autoinvoke: "false" # only for niche skills (see step 6)
---
```

**The description is the only part always loaded** (~15 lines of context per
skill, every session), and it is what the model matches against to pick the
skill. Write it as one sentence of _what_ plus one of _when_:

> `Write conventional changelog and release notes for a version range from git
log plus GitHub PR data, and propose the semver bump.`

Rules of thumb, from the renames done in this repo:

- Lead with the action, not the noun: "Work GitHub issues and pull requests
  day-to-day…", not "Helper for GitHub".
- Name the trigger words a user would actually type ("bump a version", "review
  this PR") - that is what makes auto-selection work.
- Cross-reference the sibling skill when two could be confused:
  `repo-setup` says "For GitHub-side settings use github-repo-audit", and
  `vm-github-repo-audit` says the reverse.
- Keep it under ~250 chars, which is where 9 of the 11 `vm-*` skills sit. The
  outliers are the meta-skills that name several variables
  (`vm-skill-authoring`) and the multi-paragraph `home-assistant-best-practices`;
  anything past ~350 belongs in the body.
- The v1 `metadata.opencode/slash` key does nothing in v2 and was removed. Do not
  re-add it.

Body shape that matches the other skills here: `## What I do` (a paragraph),
`## Step-by-step` (numbered, each step with the exact commands), `## Constraints`
(the never-do list). Add a `## When to use me` only when a skill is likely to be
invoked in the wrong context.

### 3. Wire it - `setup-ai-config`, `setup_opencode_skills()`

One line in the symlink block, grouped with its topic neighbours:

```bash
create_symlink "${PWD}/ai/SKILL-<id>.md" "$skills_dir/<id>/SKILL.md"
```

Notes:

- `${PWD}` because `setup-ai` runs from the repo root.
- The same function fetches upstream skills and, at the end, calls
  `reconcile_opencode_skills()` - see step 7.
- Companion files get their own `create_symlink` lines pointing **into the same
  skill directory** (see `vm-unifi-network`, `vm-opnsense-firewall`).
- `create_symlink` (setup-helper) already does `mkdir -p "$(dirname …)"`,
  `rm -f` and `ln -sf`, so the line is **idempotent** - re-running `-soc`
  refreshes the link rather than failing. Never hand-roll `ln -s` in this repo;
  use the helper so a rerun cannot fail on an existing link.

### 4. Track it - `.gitignore` allow-list (the silent trap)

`.gitignore` has `ai/**` and then allow-lists each tracked file. A new skill is
ignored until you add its line:

```
!ai/SKILL-<id>.md
```

Prove it rather than assume it:

```bash
git check-ignore -v ai/SKILL-<id>.md   # no output = tracked correctly
```

If it prints a rule, the file is ignored and will disappear on the next clone.
This is the single most common way a new skill gets lost here.

### 5. Verify it is live

```bash
ls -l ~/.config/opencode/skills/<id>/SKILL.md   # symlink resolving into ai/
opencode --version                              # v2 config is read at startup
```

Then restart opencode (skills are discovered at startup) and confirm the id shows
up in the `@` picker, or ask for it by name: "use the vm-<id> skill".

Server-side check without the TUI (the endpoint answers `{"data":[…]}` and the
server password is printed on startup, so redirect the log):

```bash
opencode serve --port 4610 >/tmp/oc-skill.log 2>&1 &
sleep 8
pw=$(grep -o 'server password .*' /tmp/oc-skill.log | awk '{print $3}')
curl -su "opencode:$pw" http://127.0.0.1:4610/api/skill |
  python3 -c "import json,sys; print([s['id'] for s in json.load(sys.stdin)['data'] if s['id']=='<id>'])"
```

Grepping the raw body for `"<id>"` is not enough: the endpoint also returns each
skill's **full `content`**, so the id appears inside other skills' text too and a
naive `grep` gives false positives. Parse the JSON and match `id` exactly, as
above. Kill the server afterwards (`kill $(ss -ltnp | grep :4610 | grep -o 'pid=[0-9]*' | cut -d= -f2)`).

### 6. Agent, or skill alone?

Default: **skill alone.** An agent is a system prompt plus permissions; a skill
is loaded on demand. An agent earns its place only when it adds something the
skill cannot:

- **permissions** - e.g. `code-review` must not edit:
  `permissions: [{action: "edit", resource: "*", effect: "deny}]`
- **delegation** - a target another agent can hand work to
  (`security-engineer` is delegated to from `github-workflow`)
- **isolation / parallelism** - a child session for a long job
- **a different model** for that class of work

If it only restates the skill's steps, it is duplication: it burns prompt
context in every session (14 agents cost 17.6k chars before the trim) and creates
a second place to update. Current agents: `security-engineer`, `github-workflow`.

To add one: a snippet in `ai/setup-ai-opencode.conf` plus its name in
`OPENCODE_CONFIG_AGENTS_NAMES`, and optionally in `OPENCODE_CONFIG_AGENTS_DEFAULT`
for the fzf preselect. v2 shape only - `system` (not `prompt`), a
`permissions` rule array (not a `permission` object), and no `enabled` key.

**The conf is a sourced bash file, not a data file.** `setup-ai` does
`source ./ai/setup-ai-opencode.conf` into its own scope (and bails if it is
missing), which is why the agent snippets are quoted JSON blobs and the header
says "do NOT turn this into a data file". Consequences for editing it:

- Lint with `shellcheck -x setup-ai` (it follows the sourced conf), not with
  plain `shellcheck ai/setup-ai-opencode.conf`. On this host shellcheck is a
  **snap** build that cannot read the repo (permission denied on every file), so
  verify bash syntax with `bash -n setup-ai` and leave the real shellcheck to CI
  or to a machine where it is not snap-confined.
- An agent name in `_NAMES` whose `OPENCODE_CONFIG_AGENTS_<UPPERNAME>` variable
  does not exist is silently skipped at run time
  (`No config found for '<name>'`). Variable name = agent name uppercased with
  `-` to `_`: `github-workflow` -> `OPENCODE_CONFIG_AGENTS_GITHUB_WORKFLOW`.
- A section you do not preselect still exists and can be selected later; the
  merge preserves keys the current run does not produce, so `github-workflow`
  and `security-engineer` survive in the live config even though only
  `github-workflow` is in `AGENTS_DEFAULT` today.
- Keep secrets as `{env:VAR}` references and add `# pragma: allowlist secret` to
  any line a secret scanner would otherwise flag (see the getsentry pin in
  `_SOURCES`). Never inline a token.

### 7. Retiring or renaming a skill

Renaming = change the file name, the frontmatter `name:`, the symlink line and
the allow-list line. The old directory is **not** your problem:
`reconcile_opencode_skills()` in `setup-ai-config` deletes it on the next
`setup-ai -soc`, because its `SKILL.md` is then a dangling symlink.

Same reconciler handles upstream skills: anything in
`OPENCODE_SKILL_NAMES` or the `.managed` manifest that is no longer selected is
removed from `~/.config/opencode/skills`. Directories it does not recognise are
left alone and reported. Adding a _new_ upstream candidate therefore means
adding it to `OPENCODE_SKILL_NAMES` (and `OPENCODE_SKILL_SOURCES` if it comes
from a different repo) - dropping it from the list is enough to uninstall it.

### 7a. Shared docs a skill may need

Not every reference belongs to one skill. `ai/GITHUB.md` is shared by every
GitHub-related skill and agent, and `ai/LLAMACPP.md` documents the local model
server. Both are symlinked **into each consumer's skill directory** rather than
referenced by path, because a skill can only read files relative to its own base
directory:

```bash
create_symlink "${PWD}/ai/GITHUB.md" "$skills_dir/vm-github-pr-issues/GITHUB.md"
```

So when a skill needs a shared doc, the doc is symlinked next to its
`SKILL.md` and the skill body says "see `GITHUB.md` in this skill folder" - not
"see `ai/GITHUB.md`". Each consumer gets its own link, so adding a skill that
needs the same doc is one more `create_symlink` line and nothing else.

### 7b. Sourcing a skill from an external repo

`ai/SKILL-*.md` is only half the picture. `setup_opencode_skills()` also
**fetches skills from external git repos** and copies them into
`~/.config/opencode/skills/`, so a skill can be vendored from a public repo
without living in this dotfiles tree. The source, candidate, bundle, and default
selection variables in
`ai/setup-ai-opencode.conf` drive it:

```bash
# "label|repo|rev|subdir" - one line per source.
#   label  : qualifies skill names as "label/name"; also the clone cache key
#   repo   : clone URL
#   rev    : commit to pin (empty = default branch) - ALWAYS PIN, see below
#   subdir : repo-relative dir that holds the skills, optionally with another
#            path level (mattpocock nests skills/<category>/<name>/); the
#            installer flattens to the LEAF name, which is the opencode skill ID
OPENCODE_SKILL_SOURCES=(
  "getsentry|https://github.com/getsentry/skills|e7a87fa72645158f9b5e722cbb1c7e09266f48f1|skills" # pragma: allowlist secret
  "homeassistant|https://github.com/homeassistant-ai/skills|91fe20f6a3da24a61692cfc7dbdc02e379c8fbf2|skills" # pragma: allowlist secret
  "mattpocock|https://github.com/mattpocock/skills|49dd158d1076134a641b33efb035946536778336|skills" # pragma: allowlist secret
)

# candidates offered in the fzf picker. "label/name" picks the source
# explicitly; a bare "name" falls back to the FIRST source in _SOURCES.
# _NAMES is every skill you MAY pick; _SKILLS_DEFAULT is what is pre-selected,
# so _NAMES is deliberately longer. (mattpocock entries truncated here.)
OPENCODE_SKILL_NAMES=(
  "security-review" "gh-review-requests" "code-review" "gha-security-review"
  "homeassistant/home-assistant-best-practices"
  "mattpocock/engineering/ask-matt" "mattpocock/engineering/code-review" # ...
)

# Optional fzf aliases expand to candidate names with the matching prefix.
OPENCODE_SKILL_BUNDLES=("mattpocock/engineering-stack|mattpocock/")

# pre-selected in the picker; a bundle is one choice for the whole set
OPENCODE_SKILLS_DEFAULT='security-review mattpocock/engineering-stack'
```

Two sources whose names share a leaf (getsentry `code-review` vs
`mattpocock/engineering/code-review`) collide on install - the first selected
wins, the rest are skipped with a warning. Selected bundles expand before
individual names, so the bundled source wins collisions. Without a bundle, the
first selected candidate wins.

The gap between candidates and defaults is normal: `_NAMES` is the catalogue of
individual skills (nothing is fetched until selected), `_BUNDLES` adds optional
group choices, and `_SKILLS_DEFAULT` is the starting selection.
`gh-review-requests` and `gha-security-review` are offered but not default,
which is why the getsentry install is smaller than its candidate list.

How they interact at `setup-ai -soc`:

1. `_NAMES` builds the fzf list, with `_BUNDLES` as optional aliases (`none` =
   cleanup, then the whole selection is removed). `_SKILLS_DEFAULT` preselects
   entries. Selecting a bundle expands to all candidate names matching its
   source prefix; individual skills remain selectable too.
2. The preview pane resolves each line to `install target` + `source` via
   `label|repo|subdir`, so you see where a skill will come from before pressing
   ENTER; bundle entries preview their matched candidate prefix.
3. Selected individual names resolve to a source: `label/name` is explicit, a
   bare `name` maps to the **first** entry in `_SOURCES` (hence `code-review` =
   getsentry, and `homeassistant/…` needs the prefix). Bundle aliases expand to
   every candidate under their configured prefix before individual selections;
   that also gives bundle members precedence in a duplicate-name collision.
4. Each source is `git clone --depth 1`'d **once per run** into a temp dir, and
   when `rev` is set it does a shallow `fetch` of that commit and checks out
   `FETCH_HEAD`. Then `<subdir>/<name-path>/` is copied **flattened to its leaf
   dir** into the skills dir and the presence of `SKILL.md` is verified
   (`no SKILL.md after install` = broken skill).
5. `reconcile_opencode_skills()` then drops anything previously installed that
   is no longer selected (see step 7).

Consequences worth knowing:

- **Never widen a pinned source silently.** A bare name resolving to the first
  source means adding `foo` to `_NAMES` can fetch it from getsentry rather than
  where you meant. Use `label/name` when a name exists in more than one repo.
- **Pin the rev.** An empty `rev` tracks the default branch, so `-soc` can
  silently change what a skill contains. Bump the commit hash deliberately.
- **Only the selected skills are copied**, so a source's other skills never
  appear. To see what a repo offers, list its `<subdir>/` on GitHub - there is
  no browse step in the picker (discovery aid: agentskills.in).
- **Upstream skills are not tracked in git** - they are copies in your home
  config. Editing one is lost on the next fetch; fix it upstream and bump the
  pin, or fork it into `ai/` as `vm-…` if you own the change.
- If `fzf` is missing the fetch is skipped _and_ nothing is pruned, so a missing
  dependency never silently uninstalls your skills.

### 7c. The llama.cpp model catalog (why it is not skill territory)

`ai/setup-ai-llamacpp.conf` looks like another config file but is a different
kind of thing: it is a **data-only** catalog (`LLAMACPP_MODELS`, KV/ctx
settings) that `setup_llamacpp()` reads to plan a memory budget and generate
`llamacpp.env`, `models.ini` and the opencode `llama.cpp` provider. Editing the
opencode provider by hand is pointless - the provider block is **regenerated**
from the model you pick in the fzf selector (`setup-ai -sll`), and the conf says
`GENERATED, DO NOT EDIT HERE` for that reason. The same "one source of truth"
rule as step 8: change the generator input, not the generated output. A skill
that documents model selection belongs in `ai/LLAMACPP.md`; a skill that
_provisions_ a model is a script, not a skill.

### 7d. The other three pickers in the same conf

A skill frequently needs a **tool**, not just prose: an MCP server for live
docs, an LSP for a language, a provider for a model endpoint. Those live in the
same conf, share the same `*_NAMES` / `*_DEFAULT` shape, and are wired by the
same `select_opencode_section()` helper - so the authoring ritual is identical to
step 6. The four sections, and what each snippet must be wrapped in:

| Section     | Prefix     | `*_NAMES`                        | Merged into  | Snippet shape                             |
| ----------- | ---------- | -------------------------------- | ------------ | ----------------------------------------- |
| MCP servers | `MCP`      | `OPENCODE_CONFIG_MCP_NAMES`      | `.mcp`       | **wrapped**: `{"servers": {<name>: {…}}}` |
| Agents      | `AGENTS`   | `OPENCODE_CONFIG_AGENTS_NAMES`   | `.agents`    | flat `{<name>: {…}}`                      |
| Providers   | `PROVIDER` | `OPENCODE_CONFIG_PROVIDER_NAMES` | `.providers` | flat `{<provider-id>: {…}}`               |
| LSP servers | `LSP`      | `OPENCODE_CONFIG_LSP_NAMES`      | `.lsp`       | **no snippet** - see below                |

**The MCP wrapper is the trap.** v2 moved servers under `mcp.servers`, so an MCP
snippet must carry the extra `"servers"` level, while agents and providers stay
flat. The three commented-out MCP examples at the top of the conf (filesystem,
puppeteer, sequential-thinking, memory) all show the correct nesting - copy one
rather than writing it from memory.

Adding an MCP server:

```bash
OPENCODE_CONFIG_MCP_NAMES=("github" "context7" "<new>")   # offer it in fzf
OPENCODE_CONFIG_MCP_DEFAULT='github'                      # pre-selected
OPENCODE_CONFIG_MCP_<UPPERNAME>='
{
  "servers": {
    "<new>": { "type": "remote", "url": "https://…", "enabled": true }
  }
}
'
```

Name → variable mapping is the same `config_varname()` rule as agents
(`<new>` -> `OPENCODE_CONFIG_MCP_<NEW_UPPER>`), and a name in `_NAMES` with no
matching variable is silently skipped at run time. Every local example uses
`"command": ["npx", "-y", "…"]`; remote ones use `url` plus `headers` for auth.
**API keys stay as `{env:VAR}`** - the github snippet is
`"Authorization": "Bearer {env:GITHUB_TOKEN}"` - and `setup_opencode()` prints
every env var it finds in the merged config so you can set them afterwards.

Adding a provider: same flat pattern, keyed by **provider id** (the part before
`/` in `provider/model-id` you will pass to `opencode --model`). Custom
OpenAI-compatible endpoints use `"npm": "@ai-sdk/openai-compatible"` with
`options.baseURL` and `options.apiKey`, and each model needs at least
`limit.context` and `limit.output`. The per-model rationale lives in a comment
above the snippet, because the model schema has no free-text `description`
field. The `llama.cpp` provider is the exception: it is **generated** (step 7c).

Adding an LSP server needs **no snippet at all** - `_NAMES` is a flat list of
built-in server names, and `select_opencode_lsp()` inverts the selection into
`{"<server>": {"disabled": true}}` for everything you did _not_ pick. `ALL`
enables everything. So a language you want is one word in
`OPENCODE_CONFIG_LSP_NAMES`; a language you want gone is one word in
`_NAMES` that you leave unselected.

Two behaviours worth knowing before you touch any of these:

- **`none` is destructive in these pickers.** Choosing `none` sets the section to
  `CLEANUP`, which makes the next `-soc` run `del()` that key from the live
  config. It removes the whole section, not the one entry.
- **A section you skip is preserved, not cleared.** The merge is
  `jq -s '.[0] * .[1]'` (new config `*` existing config), so keys the current run
  does not produce survive. That is why `github-workflow` and
  `security-engineer` are still in the live config although only
  `github-workflow` is in `AGENTS_DEFAULT`.

### 8. What not to touch

- `~/.config/opencode/opencode.jsonc` is **generated** by `setup_opencode()`
  (base object, then the MCP / agents / LSP / providers sections). Change the
  source - the conf file or the generator - and re-run, never the live file.
- `bin/` scripts are for things that run; a skill is for things the model does.
  If the deliverable is a script, write the script and link it from the skill.

---

## Constraints

- Never leave out the `.gitignore` allow-list line; verify with
  `git check-ignore -v` before declaring the skill done.
- Never edit `ai/setup-ai-opencode.conf` with a data-file mindset: it is
  `source`d by `setup-ai`, so it must stay valid bash with quoted JSON blobs,
  and it must be linted with `shellcheck -x setup-ai`.
- Never hand-edit anything `setup-ai` generates: `opencode.jsonc`, the
  `llamacpp.env` / `models.ini` runtime files, or the generated `llama.cpp`
  provider. Fix the input (the conf, the picker choice) and re-run.
- Never add an MCP snippet without the `"servers"` wrapper - v2 nests servers
  under `mcp.servers`, while agent and provider snippets stay flat.
- Never let the frontmatter `name:` and the directory name diverge - opencode
  then advertises a skill it cannot load by that id.
- Never hand-edit `~/.config/opencode/opencode.jsonc`; it is generated.
- Never add `metadata.opencode/slash` (no-op in v2) or `enabled` to an agent
  (v2 files it under an internal request body).
- Never `git add` or commit on the user's behalf - present the commands and let
  them run.
- Prefer editing an existing skill over adding a near-duplicate one; two skills
  with overlapping descriptions make auto-selection guess.
