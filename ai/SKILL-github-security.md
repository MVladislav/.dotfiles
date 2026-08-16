---
name: github-security
description: Handle GitHub security advisories end-to-end — triage and verify each report against the actual code, fix with one commit per advisory, and manage the advisory record (CVSS, summary, body, versions, state, publication)
license: MIT
compatibility: opencode
metadata:
  audience: maintainers
  workflow: security
---

## What I do

For a GitHub repository, work through the open security advisories in
dependency order (oldest `GHSA-…` first), verify each report against the real
code, fix confirmed vulnerabilities with one commit per advisory, and shepherd
the advisory record itself: severity, summary, body, affected/patched
versions, state transitions, and publication once the fix ships.

The report is a hypothesis, never the truth. Every claim in the advisory must
be verified against the repository at HEAD before anything is changed.

## Step-by-step

### 1. Fetch

- Identify the repo: `gh repo view --json nameWithOwner -q .nameWithOwner`, or
  infer `owner/repo` from the reporting issue/PR URL.
- Check `gh auth status` first; if gh is unauthenticated, tell the user to run
  `gh auth login` before starting.
- List advisories by state (use `--paginate` on large sets):
  - `gh api /repos/{owner}/{repo}/security-advisories?state=triage`
  - `gh api /repos/{owner}/{repo}/security-advisories?state=draft`
  - `gh api /repos/{owner}/{repo}/security-advisories?state=published`
  - `gh api /repos/{owner}/{repo}/security-advisories?state=closed`
- Work triage advisories oldest-first (ascending ghsa_id). Fixes must remain
  mergeable in this order, so do not skip ahead.
- Pull the published set too: a new report may duplicate an already-published
  advisory.

### 2. Verify each report

Assign exactly one verdict and record it per advisory with `file:line`
evidence. Allowed verdicts: **CONFIRMED**, **FIXED**, **FALSE**, **NOT
APPLICABLE**, **NOT EXPLOITABLE**, **DUPLICATE**.

- **CONFIRMED** — real vulnerability; needs a fix commit.
- **FIXED** — the same (or logically identical) bug was already fixed in a
  prior commit, e.g. fixed on one path while the report covers another. No new
  code change; only update the advisory record.
- **FALSE / NOT APPLICABLE** — not a vulnerability here: intended behavior, or
  the report describes a configuration/context this project does not enable.
- **NOT EXPLOITABLE** — the vulnerable code exists but is not reachable from
  any entry point.
- **DUPLICATE** — the same bug is already covered by another advisory. Keep
  the earliest advisory; close the rest.

Common traps:

- **Incomplete fix** — a prior fix covered one path but a sibling path is
  still vulnerable. That is a new CONFIRMED advisory, not a duplicate.
- **Wrong project** — the described code lives in another repo or dependency;
  match file paths and behavior before believing it.
- **Legacy code** — the bug was removed long ago; confirm with
  `git log -S` / `git log -G` that the vulnerable code no longer exists.
- **Already fixed upstream** — a vulnerable dependency fixed the bug in a newer
  version; only the project's own reachable code counts.
- **Overlapping reports** — the same root cause reached through different
  entry points is one advisory (DUPLICATE), but verify every entry point is
  actually covered by the fix.
- **Known, unaddressed class** — e.g. a known-unfixed stdlib issue: only a
  vulnerability if the project reaches the affected code; mark NOT APPLICABLE
  or follow project policy.

### 3. Fix

- One commit per advisory, one advisory per commit — never mix fixes.
- Commit message references the advisory, e.g. `security: fix GHSA-xxxx-xxxx-xxxx — description`.
- Minimal change that closes the vulnerability, plus tests.
- If branches diverge on the vulnerable path, centralize the fix in the
  common ancestor code rather than patching every divergence point.
- If the code base has diverged since the advisory was filed, re-verify the
  bug still exists before fixing (the fix commit should be made against the
  current HEAD).

### 4. Regression tests

- Add a regression test that exercises the reported input/attack path and
  asserts the fix holds.
- Confirm the test fails against the pre-fix code (or say why that is not
  possible) and passes after.
- Run the full project test suite before moving on.

### 5. Severity and CVSS

- Do not hand-assert a severity. Compute the CVSS v3.1 vector and let the
  mapping decide:
  - `gh api -X PATCH /repos/{owner}/{repo}/security-advisories/{ghsa_id} -f cvss_vector_string="{vector}"`
- Vector guidance: `AC:H` when a configuration precondition is required;
  `PR:N`/`PR:L` per actual preconditions; `S:C` when impact crosses a trust
  boundary.
- Prefer a vector consistent with any predecessor CVE published for the same
  bug (e.g. in a vulnerable dependency).
- When unsure, show the user the vector and the mapped severity before
  PATCHing.

### 6. Summary and title

- One line, sentence-case, advisory style (the bug, not the exploit), no
  backticks, no trailing period, e.g. "HTTP request smuggling via
  Transfer-Encoding header".
- The summary becomes public on publication — write it for disclosure.

### 7. Body

Rewrite the description into the standard sections, in maintainer voice,
reusing the reporter's wording where it is accurate:

- **Summary** — what the vulnerability is, in one paragraph.
- **Details** — the code path and exact `file:line` references.
- **PoC** — minimal reproduction/attacker steps (keep it short).
- **Impact** — what an attacker gains.
- **Patches** — the fix commit(s) with hashes and the version that contains them.
- **Workarounds** — real mitigations for users who cannot upgrade, else "None".
- **Out of scope** — anything explicitly not covered.
- **References** — advisories, CVEs, related issues/PRs. Match the actual
  changes; never invent links.

Post with `jq -Rs .` to avoid shell-escaping problems:

```bash
jq -Rs . > /tmp/ghsa-body.json <<'EOF'
…body text…
EOF
gh api -X PATCH /repos/{owner}/{repo}/security-advisories/{ghsa_id} \
  -F description=@/tmp/ghsa-body.json
```

### 8. Affected and patched versions

- The package metadata `{ "ecosystem": …, "name": … }` must match the actual
  package manifest (PyPI, Go, npm, …). A wrong package name breaks
  dependabot notifications — ask the maintainer when unsure.
- `vulnerable_version_range` — range of versions containing the bug (e.g.
  `< x.y.z`).
- `patched_versions` — the next real release that contains the fix. Leave
  empty until that release exists; fill it in once tagged.
- If any range is uncertain, ask the maintainer instead of guessing.

### 9. State transitions

- Fix merged: move `triage` → `draft`
  (`gh api -X PATCH … -f state=draft`).
- **DUPLICATE / FALSE / NOT APPLICABLE / NOT EXPLOITABLE** → close
  (`-f state=closed`); the verdict explains why.
- DEFERRED is a policy decision, not a verdict: leave the advisory in `triage`
  until the user decides. Never close without a decision.

### 10. Release and publish

- When the fix release ships, set `patched_versions` and publish:
  - `gh api -X POST /repos/{owner}/{repo}/security-advisories/{ghsa_id}/publish`
- Publishing is public and starts CVE assignment — confirm with the maintainer
  first, and only after the fix is released.

## Constraints

- The report is a hypothesis; verify everything against the code at HEAD.
- One commit per advisory; no unrelated changes.
- Do not hand-assert severity; derive it from the CVSS vector.
- Never invent links, references, or version ranges — ask when unsure.
- Confirm irreversible actions (closing, publishing) with the user.
- The REST API cannot comment on advisories: prepare draft replies for the
  maintainer to paste in the GitHub UI (e.g. notifying the reporter of the
  verdict and fix version).
