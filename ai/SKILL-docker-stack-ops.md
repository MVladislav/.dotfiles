---
name: vm-docker-stack-ops
description: Operate a Traefik-fronted Docker Compose/Swarm stack collection: prove and bump image versions from registry tags and release notes, align stacks with the __template__ anchors, keep pins Renovate-trackable, harden config, run the repo gates, prepare commits.
license: MIT
compatibility: opencode
metadata:
  audience: maintainers
  opencode/autoinvoke: false
  workflow: infrastructure
---

## What I do

Maintain a collection of self-contained Docker Compose stacks (one folder per
app, Traefik-fronted, Renovate-updated) without guessing. Every change is
evidence-backed: a version moves only after the target tag is proven to exist
and the whole upstream release range has been read; a stack is aligned against
the canonical template on purpose, not by accident; image pins stay trackable;
and the repository's own gates are green before anything is handed over.

The reference implementation is **vm-docker-collection**
(`composer/<category>/<app>/`, canonical knowledge in `AGENTS.md`, skeleton in
`__template/`). When working in that repository, `AGENTS.md` is the source of
truth and this skill is the procedure around it. Do not duplicate repository
knowledge here — read `AGENTS.md` first and follow it over any generic advice in
this skill.

I never stage, commit, or push. I prepare the change and the commit commands for
the user to run.

---

## Step-by-step

### 1. Orient

- Read `AGENTS.md` (or the repo's equivalent) fully before judging anything. It
  is canonical and outranks every generic instruction in this skill: it holds the
  intentional divergences, the current gate set, and the per-app knowledge.
- Read the target stack's `README.md` and `docker-compose*.yaml`, and the
  canonical `__template/docker-compose-quick.yaml` (normal app) /
  `docker-compose.yaml` (full stack).
- `git status --short`, `git diff HEAD --stat`, `git log --oneline -20` for
  state and commit style. Check whether files are already staged — it changes
  what the handover should output (§10).
- Identify the target: a version bump, a new stack, a config hardening pass, a
  cleanup, or a full audit of one stack. For a multi-stack sweep, agree the scope
  before starting; a repository-wide pass and a single-stack fix are different
  jobs with different risk.

### 2. Version bump — with proof

Work in this order; stop and ask if any step cannot be evidenced.

1. Find the pin: the `VERSION*` variable in the active `image:` line of the
   stack's `docker-compose*.yaml`. Note the sibling `README.md` `.env` example —
   it must move in the same change.
2. **Prove the tag exists** by querying the registry `tags/list` API, not by
   guessing from the changelog. A tag existing is the entry condition:

   ```sh
   # Docker Hub (anonymous token first)
   repo=library/nginx
   TOKEN=$(curl -fsSL "https://auth.docker.io/token?service=registry.docker.io&scope=repository:${repo}:pull" \
     | python3 -c 'import json,sys; print(json.load(sys.stdin)["token"])')
   curl -fsSL -H "Authorization: Bearer $TOKEN" \
     "https://registry-1.docker.io/v2/${repo}/tags/list" \
     | python3 -c 'import json,sys; print("\n".join(sorted(json.load(sys.stdin)["tags"])))'

   # ghcr.io (personal access token as password)
   curl -fsSL -u ":$GHCR_TOKEN" "https://ghcr.io/token?scope=repository:OWNER/REPO:pull&service=ghcr.io" \
     | python3 -c 'import json,sys; print(json.load(sys.stdin)["token"])'
   ```

   `quay.io`, `registry.k8s.io` and ECR use the same standard flow. A vendor
   host (`data.forgejo.org`, …) may serve a plain `tags/list` with no auth.
   Record the tag list output as the proof.

3. **Read the release notes for the whole range**, not just the new tag
   (`A..B`, every minor/RC/beta between). Check specifically:
   - DB migrations on boot / schema changes (raise `start_period`, check
     `update_config: stop-first`);
   - new, renamed or removed required env vars (a missing var fails only at
     runtime);
   - dropped columns or data-format changes;
   - image internals: probe binaries (`curl`/`wget` can be dropped), base image
     and runtime user change;
   - companion/bundled images and their supported ranges;
   - a prerelease→stable gap is a wide range, not one tag — diff the env surface
     across all of it.
4. Read the image at the target tag, not the docs page: fetch the upstream
   `Dockerfile*` (baked `ENV`, `USER`, ports, installed probes) and
   `entrypoint.sh` (validated vars, created paths). For compiled apps, verify env
   names in the source constants, not in prose.
5. Update BOTH the compose pin and the README `.env` example. If multiple
   compose files share one image, they share one commit; distinct images get
   separate commits.
6. Preserve trackability: the pin is `${VAR:-x.y.z}` with a **full three-part
   version**. A rolling tag (`16`, `16.0`, `latest`, `15-slim`) is satisfied the
   moment any matching tag exists, so Renovate never proposes an update — it is
   a silent no-op, not a bump.

Record the proof for the handover: registry tag, release-notes URL,
`file:line`, commit hash.

### 3. Template & anchor alignment

- Diff the stack's `x-basic`, `x-basic-deploy`, `x-basic-deploy-labels` against
  `__template/docker-compose-quick.yaml`, then decide every difference on
  purpose. `AGENTS.md` §0 holds the current divergence table; the durable
  reasoning behind the usual ones:
  - `proxy` joined per-service rather than blanket — a blanket `proxy` puts
    every datastore on the Traefik-facing overlay.
  - `cap_drop: ["ALL"]` plus a per-service `cap_add` — stricter than the
    template, which leaves the capability list commented out for reference.
  - `mem_limit` absent — compose-only; `docker service create` has no
    `--mem-limit`, so swarm ignores it and the key is noise in a deployed spec.
  - An added logging anchor and `tmpfs /tmp` — hardening the template omits;
    the platform is otherwise on unbounded json-file.
- Verify the full Traefik label set, **every** key the template defines,
  including the most-forgotten one:
  `traefik.http.routers.<name>.tls.certresolver=${CERT_RESOLVER:-}`. Without it
  the router serves Traefik's default certificate and the ACME resolver is
  silently ignored.
- Anchors do **not** cross files: redeclare `x-basic` / `x-basic-deploy` in
  every compose file of a multi-file stack.
- `cap_add` is **not** merged by `<<: *basic` — YAML merge does not merge
  sequences. Every service spells out its complete cap set; never rely on the
  anchor for capabilities. Under `cap_drop: ["ALL"]` a forgotten capability is
  a silent, delayed boot failure.
- `update_config: order: start-first` only if `max_replicas_per_node > 1`;
  otherwise `stop-first`.
- Do not add `hostname`, `expose`, or a published HTTP port just to make a
  service reachable. Declare only networks a service joins.

### 4. Adding a new stack

Follow `AGENTS.md` §12 for the full procedure; the shape is:

1. Copy `__template/docker-compose-quick.yaml` (or the full one for a stack
   needing `sysctls`, NFS/SMB or logging) — never start from another app's
   stack, they carry app-specific baggage.
2. `__template/docker-compose-example-services.yaml` is a catalogue to copy
   service blocks from, not a stack to base one on.
3. Pull hardware acceleration in with `extends:`, never `-f`.
4. Pin every image as `${VERSION_X:-x.y.z}` after proving each tag exists (§2).
5. Add the `.env` example to the stack `README.md` documenting **exactly one**
   value per pinned var (§5), plus a `config/secrets/` dir with a committed
   `.gitempty` placeholder.
6. Add the stack to the top-level README index and regenerate with
   `readme_gen.py`.
7. Run the full gate set (§5).

### 5. Gates & pin trackability

Run the repository's gates and fix what they report. `AGENTS.md` §8 is
authoritative for the current set — read it, do not work from a remembered list.
In vm-docker-collection the shape is:

```sh
# narrowest first — while iterating
uvx pre-commit run check-yaml --files <compose files>
uvx pre-commit run yamllint  --files <compose files>
docker compose -f <stack>/docker-compose.yaml config -q

# full set — before handover
pre-commit run --all-files
git diff --check
# plus every tools/ gate script AGENTS.md §8 lists, each with its --check mode
```

**Verify which of these are actually enforced before promising a guarded
commit.** A gate that is documented but not wired into
`.pre-commit-config.yaml` runs only when a human runs it — say so explicitly in
the handover rather than implying `pre-commit run` covered it.

`docker compose config` works without a running daemon (the dev box usually has
it stopped); `docker stack deploy` needs swarm. A stack whose `.env` does not
exist yet still needs one to parse:

```sh
printf 'DOMAIN=x ENCRYPTION_KEY=x AUTH_SECRET=x POSTGRES_PW=x\n' > /tmp/stack.env
ENV_FILE=/tmp/stack.env docker compose --env-file /tmp/stack.env \
  -f <stack>/docker-compose.yaml config -q
```

Reading a gate's findings matters as much as running it:

- **README-vs-compose pin comparison** — its `--write` mode fixes value drift in
  place only; it never inserts or deletes a line, because where a var belongs is
  a human decision. Findings that mean "documented inconsistently" are manual.
  Two traps: the staleness check is a plain word search, so a var appearing only
  in a commented-out block still counts as live; and a README must document
  **exactly one** value per pinned var — a second `VERSION_X=` line, even
  commented, is drift that `--write` will silently revert. Document an
  alternative edition in prose, never as a second assignment.
- **Pin audit** — findings split into blocking (the pin cannot be resolved or
  cannot even be parsed, so the updater will never move it) and advisory (it
  resolves but is too loose to ever propose anything). Read the tool's
  allowlists before reporting either. `--online` queries registries, so it needs
  network; Docker Hub rate limits surface as lookup failures, not real problems.
- **Docs generator** — the `--check` mode is the gate; `--write` is not. Never
  run `--write` to make a check pass: it regenerates from git history, so bulk
  dependency commits shift the derived classification and you will bury a real
  finding in churn.
- **Env freeze helper** — deliberately manual. It pins a deployed stack to the
  compose default so a later pull does not silently change the running version.
  Never wire it into a hook; that would adopt every upstream bump, the opposite
  of freezing.
- **`docker compose config -q`** — parse/interpolate every file, including
  multi-file combos (`-f base -f extension`).

**Every Compose image must use a `${VAR:-default}` pin.** The two untrackable
shapes are a variable in the repository name and a nested default
(`${A:-${B:-}x}`) — replace them with a commented sibling `image:` line and move
the switch into the compose file (update the README; delete the now-dead var).
Never point a pin at a token-gated registry; prefer the vendor's plain
data/mirror host.

### 6. Missing-config hardening

For every stack touched (and every new stack), check and set:

- **Telemetry / analytics / update-check opt-outs.** Self-hosted stacks must not
  phone home. Find the app's product telemetry, analytics/scarf, crash reporting
  and "check for new version" flags and set the opt-out in `.env`-configurable
  form (`VAR: ${VAR:-false}` — mind the polarity). Beware look-alikes: a
  self-hosted OTel export is not product telemetry, and a "feature module"
  switch is not telemetry either — but check both.
- **Trusted proxy behind Traefik.** Apps that log the real client IP or enforce
  IP-scoped policy need the proxy-CIDR trust var, or they honour
  `X-Forwarded-For` from anyone.
- **A real probe endpoint.** An SPA console often answers every path with
  `index.html` and a 200; confirm the health route is registered on the API/
  worker port before trusting it. Use `start_period` in the multi-minute range
  for apps that migrate at startup.
- **Resource limits clear the baked heap.** If the image bakes a heap ceiling
  (`NODE_OPTIONS=--max-old-space-size`, JVM `-Xmx`), the cgroup limit must sit
  above it or the OOM killer fires before the app's own limit. Leave native
  headroom.
- **Secrets** via swarm `secrets` / `configs`, never plain env, and never logged.
  A `*_FILE` var requires the entrypoint to expand it — verify, because that
  expansion creates a `docker exec` trap: `docker exec` starts from the
  container's `Config.Env`, which holds the literal `PASSWORD_FILE` and not the
  derived `PASSWORD`, so admin commands run via `exec` fail with
  `using password: NO` while the app itself is healthy. Fix the exec'd command
  (re-read the file, or `source /etc/environment`) — never by moving the secret
  back into a plain env var.
- **The external `proxy` network is always `external: true`**, and only the
  Traefik-fronted service joins it. A blanket `proxy` in `x-basic` puts every
  datastore on the Traefik-facing overlay.
- **Never `tmpfs: /run` in a stack that mounts file-based secrets** — the tmpfs
  masks `/run/secrets`.
- **Only pass vars the image actually reads.** Grep the source constants; drop
  leftovers.
- Multiple services → service-suffixed resource vars
  (`RESOURCES_LIMITS_MEMORY_<SVC>`).

### 7. Swarm vs plain compose

The stacks are authored for Swarm, so "it parses" is a much weaker check than
"it means the same thing once deployed". Before calling a stack done:

- Fields that only exist in one mode are the usual source of silent divergence —
  a compose-only key is ignored by Swarm, and a swarm-only key (`deploy:`,
  placement, `update_config`) is ignored by `docker compose up`. Know which mode
  the stack claims to support and validate against that one; `AGENTS.md` records
  the escape hatch for running a stack under plain compose.
- `depends_on` in a Swarm stack orders start-up on one node only; anything that
  must come up in order across the stack belongs in an orchestrator or an
  entrypoint wait, not in `depends_on`.
- `restart:` and `restart_policy:` are the same intent in different modes — pick
  the one the target mode reads.
- If the deployment cannot be exercised here, say which mode you validated and
  which you could not, rather than implying both.

### 8. Cleanup

- Dead env vars and options nothing reads; stale README `.env` assignments;
  leftover commented service blocks; orphaned stacks; README index drift.
- Keep the stack README a config reference, not a manual — long upgrade notes,
  sizing tables and architecture explainers belong in `AGENTS.md` or a
  `docs/RUNBOOK-<app>.md`.

### 9. Proof / evidence discipline

Base every claim on evidence and cite it:

- registry tag list (`tags/list`), release-notes / changelog URL, `AGENTS.md`
  section, upstream `Dockerfile`/`entrypoint` at the tag, source constant;
- `file:line` for code/config, commit hash for history, issue/PR number for
  GitHub context. Never invent a tag, a release note, a URL or a version range.

### 10. Report and hand off

- Summary per area: what changed, why, the evidence, and anything needing a
  human decision (irreversible migration, data-dir change, secret rotation).
- Present the commit plan separately, following the `git-commit` skill
  (conventional commits, one topic per commit). Output `git add` +
  `git commit` commands only — never execute them.

Repo conventions that override the generic skill:

- Subjects: `chore(deps): update <app> to version <X.Y.Z>` for a bump, plus
  `feat: add <app>`, `chore(config): ...` for config-only, `refactor: ...` for
  restructuring, `chore(deps): update pre-commit hooks` for tooling.
- **One small commit by default.** A version bump plus the config tweaks that
  belong with it go in a single commit, e.g.
  `chore(deps): update beszel to version 0.20.0 + enhance configs/setup`. Do not
  stage a multi-commit `git add -p` dance unless asked.
- If the files are **already staged**, output the plain `git commit` — no
  re-staging, no `git reset`. If unrelated work sits in the index, add a
  pathspec (`git commit ... -- composer/<category>/<app>/`) instead of touching
  it.
- Leave working changes **unstaged** so the user can review. Stashed autostash
  entries exist; do not touch them unasked.

---

## Configuration reference

### Canonical paths (vm-docker-collection)

| path                                              | purpose                                                            |
| ------------------------------------------------- | ------------------------------------------------------------------ |
| `AGENTS.md`                                       | canonical knowledge — read first, it outranks this skill           |
| `MAINTENANCE.md`                                  | generated, gitignored                                              |
| `.github/renovate.json`                           | dependency updater; also an input to the pin audit                 |
| `.pre-commit-config.yaml`                         | which hooks actually run                                           |
| `__template/docker-compose-quick.yaml`            | base skeleton for a normal app                                     |
| `__template/docker-compose.yaml`                  | full variant (+ `sysctls`, `pull_policy`, NFS/SMB, logging)        |
| `__template/docker-compose-example-services.yaml` | service catalogue — **not** a stack                                |
| `__template/docker-hwaccel.yaml`                  | pulled in with `extends:`, **never** with `-f`                     |
| `composer/<category>/<app>/`                      | one self-contained stack                                           |
| `tools/*.py`                                      | gate scripts — `AGENTS.md` §8 is authoritative for the current set |
| `docs/RUNBOOK-<app>.md`                           | long upgrade notes, sizing, architecture                           |

### The three anchors (diff these against quick.yaml)

- `x-basic-deploy-labels` — Traefik routing labels, **all 11 keys**.
- `x-basic-deploy` — `mode: replicated`, placement, `update_config`, resources,
  `restart_policy`.
- `x-basic` — hardening: `env_file`, `cap_drop`, `security_opt`, ulimits,
  `tmpfs`, `restart`.

Full template only: `x-logging-json` / `x-logging-syslog` (`json-file`,
`max-size 10m`, `max-file 3`, `compress`) and `x-base-env` (`TZ`, `PUID`,
`PGID`). Note `quick.yaml` writes router names bare (`<name>`) while the full
template suffixes them with `${SERVICE_NAME_POST:-}` so a second instance can
run beside the first.

### Renovate: the durable rules

What Renovate's own config contains is repo state — read it, never assume it,
and never restate it here. `AGENTS.md` §5 owns that inventory. What is stable
is _how Renovate fails_, and all four modes are silent:

- **Release-age gating.** A `minimumReleaseAge` hides fresh releases, so "Renovate
  did not propose it" is never evidence the tag is bad. Prove tags against the
  registry directly (§2).
- **Version ceilings.** `allowedVersions` in `packageRules` deliberately caps
  some stacks below latest. Check for a matching rule before proposing a bump
  there — the ceiling is a decision, not an oversight.
- **Pinned tags, not branches.** Where a stack pins an exact tag, Renovate will
  not move it for you; that is what a bump commit is for.
- **`ignorePaths`/`ignoreDeps` are load-bearing and invisible.** The audit tool
  derives its file set from the updater config, so editing that config silently
  changes what the gate covers. Diff it before committing anything that touches
  it, and re-read it when a finding points at generated or intentionally
  unscanned content.

### Cert resolver and routing

```
traefik.http.routers.<name>.tls.certresolver=${CERT_RESOLVER:-}
traefik.http.routers.<name>.rule=Host(`${DOMAIN?domain variable not set}`)
traefik.http.services.<name>.loadbalancer.server.port=${PORT:-...}
```

`${VAR?msg}` fails fast on a missing required var (no `:` in the message);
`${VAR:-default}` supplies a default. `LB_SWARM=false` + `NETWORK_MODE=bridge`
runs a stack under plain `docker compose`.

### Pin shapes

| shape                                 | Renovate                                               | verdict                                    |
| ------------------------------------- | ------------------------------------------------------ | ------------------------------------------ |
| `image: repo:${VAR:-1.2.3}`           | tracks `1.2.3`                                         | correct                                    |
| `image: repo:${VAR:-1.2.3}-suffix`    | tracks the tag including the suffix                    | correct                                    |
| `image: repo:${VAR:-16}`              | rolling — satisfied the moment any matching tag exists | silent no-op                               |
| `image: re${X:-}po:${VAR:-1.2.3}`     | repo has `$`                                           | untrackable — banned                       |
| `image: repo:${V:-${OTHER:-}1.2.3}`   | nested default                                         | untrackable — banned                       |
| `image: repo` (local build, untagged) | no repository, nothing to look up                      | allowlist with a written reason, or remove |

The rule is precision, not arity: `16` and `16.0` match any `16.x` and are
therefore satisfied forever, while `16.0.0` is a concrete version and gets
compared. A full version is the safe default.

**Before reporting a pin as broken, check whether the audit tool already
allowlists it.** Upstream schemes that legitimately break the default — a vendor
that picks the OS variant, an upstream with no patch releases — are allowlisted
advisory with the reason recorded. Adding an entry is a judgement that has to be
justified in writing, not a silencer: never add one to make a gate go green, and
never allowlist a real dependency that simply has not been converted yet.

### Recurring gotchas (vm-docker-collection)

Durable traps in how this repo is wired — the kind that cost an hour when
missed. Anything that is merely _current state_ lives in `AGENTS.md`; do not
duplicate it here. Verify with a command rather than trusting this list.

- **The updater config is an input to the gate.** `tools/image_pin_audit.py`
  derives its audited file set from `.github/renovate.json`
  (`customManagers[0].managerFilePatterns` + `ignorePaths`), so guard and
  Renovate cannot drift apart — but nothing keeps those entries present, and a
  revert re-opens the audit silently. Generated stacks are the exposure: a
  generator that emits a variable in the tag without a default produces a pin
  the parser cannot read. When a finding points at generated or unscanned
  content, diff the updater config before "fixing" the pin — the pin may be
  correct and the exclusion may be missing.
- **A generated file can also be the source of truth for a gate.** Check whether
  a reported file is tracked before editing it; if a script regenerates it, edit
  the generator.
- **Generated docs are not hand-editable.** `readme_gen.py` writes both
  `README.md` and `MAINTENANCE.md`; a hand-edit to either is lost on the next
  `--write`, and the status column is derived from git history, so a bulk
  dependency commit churns it.
- **The repo is ignore-everything with a whitelist.** `.gitignore` opens with
  `*`; `AGENTS.md` and `MAINTENANCE.md` are therefore local-only and never
  committed. A new tool or file stays invisible to git until whitelisted — check
  with `git check-ignore -v <path>`.
- **Do not assume the gate hooks run.** `pre-commit run` only invokes what
  `.pre-commit-config.yaml` lists; check whether the gate scripts are wired
  there before promising that a commit is guarded. If they are not, run them by
  hand and say so in the handover.
- **A stack's `.env` is usually untracked**, so `docker compose config -q` fails
  on a missing one; point `ENV_FILE` at a throwaway file and feed the same vars
  as interpolation input.
- **No `python` symlink on the dev box** — run the tools as `python3`.
- **Commented-out config is compared as a variant on purpose.** Do not "clean"
  it into an active line without checking intent; a commented `image:` line is
  also invisible to the updater, which is what makes it the safe way to document
  an alternative edition.

---

## Constraints

- **Never restate repo state as fact.** This skill carries method and durable
  traps. The current gate set, tool inventory, updater config and per-app
  knowledge live in `AGENTS.md` — read them at the time you need them. A skill
  that hardcodes state rots silently and is worse than no skill.
- Read-only for staging/committing: never run `git add`/`commit`/`push` unless
  explicitly asked. Present copy-pasteable commands.
- `AGENTS.md` wins over this skill; documented intentional divergences are not
  bugs. Never "fix" a per-service `proxy`, a stricter `cap_drop`, or an absent
  `mem_limit`.
- Read the image at the tag, not the docs page; verify env names in source
  constants. Never infer "the app never does X" from a single-file grep — check
  entrypoint scripts and management commands too.
- Never invent a tag, release note, URL or version range; if proof is missing,
  stop and say so.
- Never point a pin at a token-gated registry or leave an untrackable pin shape.
- When bumping a version, update the README `.env` example in the same change.
- Never run a generator's `--write` to make a `--check` pass.
- Confirm irreversible actions (data-dir move, one-way migration, secret
  rotation) with the user before proposing them.

## When to use me

Use when maintaining an existing Compose/Swarm stack collection: bumping a
service version, adding or aligning a stack against the template, hardening a
stack, running the validation gates, or doing a cleanup pass. Pair with
`vm-git-commit` for the commit plan and `vm-github-pr-issues`/`vm-github-issue-research`
when an issue/PR needs evidence.
