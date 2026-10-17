---
name: vm-github-advisories
description: Triage GitHub security advisories with read-only access, verify reports against code, prepare local fixes and tests, and draft advisory updates for the maintainer without writing to GitHub.
license: MIT
compatibility: opencode
metadata:
  audience: maintainers
  workflow: security
---

## What I do

For a GitHub repository, research open security advisories in dependency order
(oldest GHSA first), verify each report against the real code, and prepare local
remediation when requested. Draft recommended severity, summary, body,
affected/patched versions, and state transitions for the maintainer. GitHub
access is read-only: this skill never edits or publishes advisory records.

The report is a hypothesis, never the truth. Every claim in the advisory must
be verified against the repository at HEAD before anything is changed.

## Step-by-step

### 1. Fetch

- Identify the repo: `gh repo view --json nameWithOwner -q .nameWithOwner`, or
  infer `owner/repo` from the reporting issue/PR URL.
- Check `gh auth status` first; if access is missing, tell the user to configure
  the read-only token described in `GITHUB.md` before starting.
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

- **CONFIRMED** - real vulnerability; needs local remediation when requested.
- **FIXED** - the same (or logically identical) bug was already fixed in a
  prior commit, e.g. fixed on one path while the report covers another. Report
  the evidence; do not update the advisory record.
- **FALSE / NOT APPLICABLE** - not a vulnerability here: intended behavior, or
  the report describes a configuration/context this project does not enable.
- **NOT EXPLOITABLE** - the vulnerable code exists but is not reachable from
  any entry point.
- **DUPLICATE** - the same bug is already covered by another advisory. Identify
  the earliest advisory and recommend closing the rest.

Common traps:

- **Incomplete fix** - a prior fix covered one path but a sibling path is
  still vulnerable. That is a new CONFIRMED advisory, not a duplicate.
- **Wrong project** - the described code lives in another repo or dependency;
  match file paths and behavior before believing it.
- **Legacy code** - the bug was removed long ago; confirm with
  `git log -S` / `git log -G` that the vulnerable code no longer exists.
- **Already fixed upstream** - a vulnerable dependency fixed the bug in a newer
  version; only the project's own reachable code counts.
- **Overlapping reports** - the same root cause reached through different
  entry points is one advisory (DUPLICATE), but verify every entry point is
  actually covered by the fix.
- **Known, unaddressed class** - e.g. a known-unfixed stdlib issue: only a
  vulnerability if the project reaches the affected code; mark NOT APPLICABLE
  or follow project policy.

### 3. Prepare a local fix

- When the user requests remediation, make one focused local change set per
  advisory. Keep changes unstaged for review and do not commit or push.
- Include a regression test when the project has a suitable test setup.
- If branches diverge on the vulnerable path, centralize the fix in the
  common ancestor code rather than patching every divergence point.
- If the code base has diverged since the advisory was filed, re-verify the
  bug still exists before fixing (the local patch should be based on the
  current HEAD).

### 4. Regression tests

- Add a regression test that exercises the reported input/attack path and
  asserts the fix holds.
- Confirm the test fails against the pre-fix code (or say why that is not
  possible) and passes after.
- Run the full project test suite before moving on.

### 5. Recommend severity and CVSS

- Do not hand-assert a severity. Compute the CVSS v3.1 vector and let the
  mapping decide. Include the proposed vector and mapped severity in the local
  report; never patch the GitHub advisory.
- Vector guidance: `AC:H` when a configuration precondition is required;
  `PR:N`/`PR:L` per actual preconditions; `S:C` when impact crosses a trust
  boundary.
- Prefer a vector consistent with any predecessor CVE published for the same
  bug (e.g. in a vulnerable dependency).
- When unsure, show the user the vector and mapped severity as a recommendation.

### 6. Summary and title

- One line, sentence-case, advisory style (the bug, not the exploit), no
  backticks, no trailing period, e.g. "HTTP request smuggling via
  Transfer-Encoding header".
- The summary may become public on publication. Draft it for disclosure, but
  leave publication to the maintainer.

### 7. Body

Rewrite the description into the standard sections, in maintainer voice,
reusing the reporter's wording where it is accurate:

- **Summary** - what the vulnerability is, in one paragraph.
- **Details** - the code path and exact `file:line` references.
- **PoC** - minimal reproduction/attacker steps (keep it short).
- **Impact** - what an attacker gains.
- **Patches** - the local fix and the version expected to contain it.
- **Workarounds** - real mitigations for users who cannot upgrade, else "None".
- **Out of scope** - anything explicitly not covered.
- **References** - advisories, CVEs, related issues/PRs. Match the actual
  changes; never invent links.

Include the draft body in the local report for the maintainer to review and
copy into GitHub. Do not call an advisory update endpoint.

### 8. Affected and patched versions

- The package metadata `{ "ecosystem": ..., "name": ... }` must match the actual
  package manifest (PyPI, Go, npm, …). A wrong package name breaks
  dependabot notifications - ask the maintainer when unsure.
- `vulnerable_version_range` - range of versions containing the bug (e.g.
  `< x.y.z`).
- `patched_versions` - the next real release that contains the fix. Leave
  empty until that release exists; fill it in once tagged.
- If any range is uncertain, ask the maintainer instead of guessing. Record
  proposed metadata locally; do not update GitHub.

### 9. State transitions

- Recommend `triage` to `draft` after a fix is merged, and recommend `closed`
  for duplicate or unconfirmed reports. Include the rationale in the report;
  never change the advisory state.
- DEFERRED is a policy decision, not a verdict. Record it as an open decision
  for the maintainer rather than changing the advisory.

### 10. Release and publish

- When the fix release ships, recommend the patched version and whether the
  advisory is ready to publish. Publishing is public and starts CVE assignment;
  the maintainer performs that action outside this skill.

## Constraints

- The report is a hypothesis; verify everything against the code at HEAD.
- One local change set per advisory; no unrelated changes. Leave changes
  unstaged and do not commit unless separately requested.
- Do not hand-assert severity; derive it from the CVSS vector.
- Never invent links, references, or version ranges - ask when unsure.
- GitHub access is read-only. Never create, edit, close, or publish advisories;
  never comment, push, or otherwise change GitHub state, even when asked.
  Prepare local drafts and instructions for the maintainer instead.
- The REST API cannot comment on advisories: prepare draft replies for the
  maintainer to paste in the GitHub UI (e.g. notifying the reporter of the
  verdict and fix version).
