---
name: bash-script
description: Write, edit, or proofread bash scripts in house style (standalone bin/ scripts and config-driven setup tools): shebang, set -euo pipefail, usage/parse_args/main flow, print helpers, quoting, error handling, validation
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: generic
---

## What I do

When asked to write, edit/improve, or proofread a bash script in any
project, follow the house dotfiles style so the result matches the rest
of the user's scripts. Three script shapes exist — pick the right one:

- **Standalone script** (`bin/` family) — a single self-contained tool
  with plain `echo` output and inline dependency checks. Canonical:
  `bin/md2pdf`, `bin/sessionizer-tmux`, `bin/vm-diff-gsettings`.
- **Config-driven tool** (`setup-ai` family) — install/config tooling
  with toggle flags, version pins, colored print helpers and fzf
  selection. Canonical: `setup-ai` + `setup-helper`.
- **Sourced library** (`setup-helper` style) — functions only, sourced
  by entry scripts; uses `return` (never `exit`) and includes the ERR trap.

The skill also applies when **proofreading**: review an existing script
against the quoting, error-handling, and validation rules below and
report deviations (as a list, not by silently rewriting).

## Step-by-step

### 1. Choose the script shape

| Shape           | Use when                                     | Structure                                                       |
| --------------- | -------------------------------------------- | --------------------------------------------------------------- |
| Standalone      | one job, few options, output to stdout       | `usage()`/`parse_args()`/`main()`, plain `echo`                 |
| Config-driven   | install/setup with flags + multiple services | `CONFIG ::` flags, `main()` with `run_if`, colored helpers, fzf |
| Sourced library | shared helpers imported by scripts           | functions only, no top-level execution                          |

Ask the user if the intent is ambiguous. For a generic "write me a
script", default to **standalone**.

### 2. Write the preamble

**Standalone** (`bin/` family) — minimal, optional fixed `PATH`, optional
traps:

```bash
#!/usr/bin/env bash
PATH=/usr/bin:/usr/local/bin:/bin:/usr/sbin:/sbin
set -euo pipefail
# optional: consistent error line reporting
trap 'echo "ERROR: Unexpected error on line $LINENO (command: $BASH_COMMAND)." >&2' ERR
# add cleanup trap only when temp files are created
trap cleanup EXIT INT TERM
```

**Config-driven** (`setup-ai` family) — `PATH` also includes the
`~/.local/bin` user prefix:

```bash
#!/usr/bin/env bash
PATH="/usr/bin/:/usr/local/bin/:/bin:/usr/sbin/:/sbin:/snap/bin/:$HOME/.local/bin"
set -euo pipefail
```

**Sourced library** — shebang + `set -euo pipefail` + colored ERR trap,
no `PATH` (the sourcing script owns the environment), no `main()`,
`return` not `exit`:

```bash
#!/usr/bin/env bash
set -euo pipefail
trap 'echo -e "${BRED}ERROR: Unexpected error on line $LINENO (command: $BASH_COMMAND).${NC}" >&2' ERR
```

### 3. Structure the body

**Standalone** (from `bin/md2pdf`) — section banners with `***`:

```
# *** Main Flow ***              main() { validate_environment; prepare_*; build_*; echo "tool: OK in -> out"; }
# *** Build Functions ***        validate_environment(), prepare_*, build_*()
# *** Utility Functions ***      cleanup(), exit_with_error()
# *** Usage and Argument Parsing ***   usage(), parse_args()
# *** Entrypoint ***             parse_args "$@"; main
```

**Config-driven** (from `setup-ai`) — category-prefixed headers + a
`CONFIG ::` block:

```
preamble
  ├── config block          (flags, version pins, paths)
  ├── section separators    (****...****)
  ├── helper functions      (utility, reusable)
  ├── service functions     (one per major job)
  ├── main()                (dispatch, run_if pattern)
  ├── parse_args()          (CLI parsing via case)
  ├── bottom boilerplate    (print_info2 "▶️ Starting…"; parse_args "$@"; main)
```

### 4. Validate before considering done

```bash
bash -n script.sh
shellcheck -x script.sh       # follows sourced files
editorconfig-checker -config .editorconfig script.sh   # if available
```

If `editorconfig-checker` is not installed, do the manual checks that
mimic it: ensure LF line endings, final newline, UTF-8, and 2-space
indent, and confirm `.editorconfig` is honoured if present.

---

## Style reference

### Standalone script style (`bin/` family)

- Plain `echo` output — no colors, no emoji. Optionally prefixed with
  the tool name: `md2pdf: OK $INPUT_MD -> $OUTPUT_PDF`.
- Errors to stderr via a single helper:

  ```bash
  exit_with_error() {
    echo "tool: ERROR: $1" >&2
    exit 1
  }
  ```

- Inline dependency check at the top (loop or per-command):

  ```bash
  for cmd in gsettings diff date; do
    command -v "$cmd" >/dev/null 2>&1 || {
      echo "Error: '$cmd' is not installed. Exiting."
      exit 1
    }
  done
  ```

- Globals in `UPPER_SNAKE_CASE` at the top, with defaults:
  `OUTPUT_DIR="gsettings_states"`, `TMP_DEFAULTS=""`.
- Resolve script-adjacent assets via `BASH_SOURCE`:

  ```bash
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
  ASSET_DIR="${SCRIPT_DIR}/md2pdf.d"
  ```

- Build command arrays and run them as one word-split array:

  ```bash
  local -a cmd=(pandoc)
  cmd+=(--defaults "$TMP_DEFAULTS" --template "$TEMPLATE_FILE")
  "${cmd[@]}"
  ```

- `usage()` + `parse_args()` handle `-h | --help`; `parse_args` validates
  args (`exit_with_error` on bad input); entrypoint is
  `parse_args "$@"` then `main`.

### Naming

| What                            | Convention                                  | Example                                                  |
| ------------------------------- | ------------------------------------------- | -------------------------------------------------------- |
| Functions                       | `snake_case` (lowercase)                    | `create_symlink()`, `parse_args()`, `exit_with_error()`  |
| Local variables                 | `snake_case`                                | `local file_name="${asset_url##*/}"`                     |
| Config/toggle flags             | `UPPER_SNAKE_CASE`                          | `RUN_INSTALL_OPENCODE=0`, `VERSION_GH=v2.97.0`           |
| Globals (standalone)            | `UPPER_SNAKE_CASE`                          | `OUTPUT_DIR`, `TMP_DEFAULTS`                             |
| Paths (env-overridable)         | `UPPER_SNAKE_CASE` with `${VAR:-"default"}` | `LN_OPENCODE="${LN_OPENCODE:-"$HOME/.config/opencode"}"` |
| Output binary / script filename | `lowercase-hyphen` (no underscores)         | `setup-ai`, `md2pdf`, `sessionizer-tmux`                 |

### Comments and section dividers

Top-level separators use a row of asterisks:

```bash
# ******************************************************************************
```

Standalone scripts use `*** Section Name ***` banners:

```bash
# *** Main Flow ***
# *** Entrypoint ***
```

Config-driven scripts use the prefix style `CATEGORY :: short description ---`:

```bash
# CONFIG :: toggle flags -------------------------------------------------------
# CONFIG :: version pins -------------------------------------------------------
# HELPERS :: create symlink ----------------------------------------------------
# SERVICE :: install opencode --------------------------------------------------
# CLI :: parse args ------------------------------------------------------------
# MAIN :: entry point ----------------------------------------------------------
```

Categories: `CONFIG`, `HELPERS`, `SERVICE`, `CLI`, `MAIN`, `BINARY`,
`UPDATE`.

Every function with non-obvious args gets a short comment block above it:

```bash
# HELPERS :: fzf multiselect ----------------------------------------------------
# Run a multi-select fzf prompt. Prints the selected lines; empty when nothing
# was chosen. ESC/abort (exit 130) is treated as "no selection", NOT an error.
# Args: $1 list (newline-joined), $2 space-separated preselect defaults,
#       $3 header, $4 prompt, $5 (optional) preview command ({} = current line).
fzf_pick() {
```

### Quoting

- **Always double-quote variable expansions**: `"$1"`, `"$var"`, `"${arr[@]}"`, `"${var:-default}"`.
- **Single quotes** for literal strings: `'config:recommended'`, regex patterns.
- Redirects: `command -v foo >/dev/null 2>&1`, `1>/dev/null` (not `>/dev/null 2>&1` everywhere — use contextually).

### Variables and arrays

```bash
local out_dir="${3:-$USER_LOCAL_PREFIX_BIN}"        # positional with default
local missing=()                                     # empty array
missing+=("$cmd")                                    # append
for item in "${arr[@]}"; do ...; done                # iterate
[[ ${#missing[@]} -eq 0 ]] && return 0              # check empty
```

Namerefs for passing arrays by name:

```bash
local -n tools_ref="${1%\[@\]}"
local -n build_ref="${2%\[@\]}"
local packages_tools=("${tools_ref[@]}")
```

Always prefix `local` at the top of a function. One `local` per line.

### Error handling

**Fatal errors** — guard with `|| { print_error; return 1; }`, `|| exit_with_error "..."`, or `exit 1`:

```bash
release_json=$(github_api "$api_url") || {
  print_error "   ❌ Failed to fetch GitHub-api '$api_url'."
  return 1
}
```

**Dependency check** — standalone: inline `command -v` loop (above);
config-driven: `require_cmds`:

```bash
require_cmds curl jq || return 1
```

**Argument validation** — guard at function top:

```bash
if [[ -z "$repo_url" || -z "$binary_regex" ]]; then
  print_error "❌ Missing argument."
  return 1
fi
```

**Exit codes**: `return 0` success, `return 1` non-fatal failure (caller decides), `exit 1` for fatal in entry-point scripts. Libraries never `exit`.

### Print helpers (config-driven only)

Always source the helper library (`setup-helper` or equivalent) if
available in the project. If not, create a local copy of these helpers:

```bash
NC='\033[0m'         # No Color
BRED='\033[1;31m'    # Red
BPURPLE='\033[1;35m' # Purple
BYELLOW='\033[1;33m' # Yellow
BCYAN='\033[1;36m'   # Cyan

print_info()    { echo -e "${BPURPLE}$1${NC}"; }
print_info2()   { echo -e "${BYELLOW}$1${NC}"; }
print_read()    { printf "%b%s%b" "${BYELLOW}" "$1" "${NC}"; }
print_notes()   { echo -e "${BCYAN}$1${NC}"; }
print_error()   { echo -e "${BRED}$1${NC}" >&2; }
print_section() {
  echo -e "\n${BCYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  print_info2 "  $1"
  echo -e "${BCYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}
```

Use consistent emoji prefixes in messages:

| Prefix                      | Meaning                            |
| --------------------------- | ---------------------------------- |
| `🚀 TOOL ::`                | start of a service/install section |
| `✅ TOOL ::`                | completed                          |
| `❌`                        | error                              |
| `⚠️`                        | warning (non-fatal)                |
| `   💡`                     | informational note                 |
| `   📥`                     | dependency / package action        |
| `   ⚙️`                     | extraction / processing            |
| `   🔍`                     | found / matched                    |
| `   ⬇️`                     | download                           |
| `   📌`                     | install / place                    |
| `▶️ Starting script $0 ...` | entry-point banner                 |

### Flow patterns

**Config flags** at the top, toggled by `parse_args`, dispatched by `main`:

```bash
RUN_INSTALL_OPENCODE=0
# ...

main() {
  sudo_drop
  run_if $RUN_INSTALL_OPENCODE && install_opencode
  # ...
  print_info2 "\n✅ All finished!"
}

parse_args "$@"
main
```

**Version pins** and **paths** (env-overridable) grouped under `CONFIG ::`:

```bash
VERSION_GH=v2.97.0
VERSION_GH_REPO=https://github.com/cli/cli
LN_OPENCODE="${LN_OPENCODE:-"$HOME/.config/opencode"}"
```

**`parse_args`** — long/short flag pairs, `case ... esac`, shift on every iteration.

**Interactive selection** — use `fzf_pick` with preselect defaults and
a clear header/prompt (from `setup-helper` or inline equivalent).

**`run_if`** — toggle-gate pattern: `run_if $FLAG && function_name`

**Symlinks** — always use `create_symlink()`:

```bash
create_symlink() {
  local target="$1" link_name="$2"
  mkdir -p "$(dirname "$link_name")"
  rm -f "$link_name"
  ln -sf "$target" "$link_name"
}
```

### Sourcing and shellcheck

When sourcing external files, guard with existence check and disable
relevant shellcheck warnings:

```bash
[[ -f "./setup-helper" ]] || { echo 'ERROR: "./setup-helper" not found.'; exit 1; }
# shellcheck disable=SC1091
source "./setup-helper"
```

For conf files with unusual content (JSON in single-quoted vars, etc.),
add `# shellcheck shell=bash` and `# shellcheck disable=SC2034` as needed.

Use `# NOTE: lint with 'shellcheck -x <script>' (follows the sourced conf)`
to document the correct lint invocation.

### Shellcheck suppressions

Use the narrowest suppression needed:

- `SC2034` — unused variable (config vars are often `SC2034`)
- `SC1091` — can't follow sourced file
- Add the suppression as close to the offending line as possible
- Prefer `# shellcheck disable=SCnnnn` per-line over file-wide

---

## Canonical reference

Your canonical implementations live in `/home/ai/.dotfiles/`:

- `bin/md2pdf`, `bin/sessionizer-tmux`, `bin/vm-diff-gsettings` — standalone family
- `setup-helper` — sourced helper library (print helpers, fzf_pick, download_github_binary, etc.)
- `setup-ai` — config-driven entry-point script (flags, parse_args, main, service functions)
- `.editorconfig` — LF, UTF-8, 2-space indent, final newline

Use these as the living style reference. Do not invent conventions that
contradict them.

## Constraints

- Every new script must pass `bash -n`, `shellcheck -x` (if sourcing),
  and `editorconfig-checker` (if `.editorconfig` is present).
- LF line endings only, UTF-8, final newline, no trailing whitespace
  (except `*.md` where trailing whitespace is allowed per `.editorconfig`).
- Never hardcode absolute paths that differ per machine; use
  `${VAR:-"default"}` with env override.
- Never echo secrets (API keys, tokens, passwords). Print a redacted
  placeholder if logging is needed.
- `sudo` usage: gate behind `RUN_WITH_SUDO` and call `sudo -k` after
  the install step. Never `sudo` without the guard.
- `set -x` (debug) is toggled via `-d` / `--debug` flag, never hardcoded.
- When the script is a helper library (sourced, not run directly):
  include the ERR trap; do not use `exit` (use `return`).
- When proofreading, report deviations against these rules as a list
  with references; do not silently rewrite the script.
