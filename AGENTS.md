# Repository instructions

## Purpose and structure

This is a personal Ubuntu/amd64 dotfiles and workflow repository, not a conventional application. It contains shell startup configuration, editor/terminal settings, setup scripts, operational helpers, and an OpenCode skill/knowledge catalog. The maintainer's two main entry points are `setup` for a basic device and `setup-ai` for an AI-focused device.

- `setup` is the general device setup. It does not install tools by default; it links `bin/`, Ghostty, Neovim, Zed, profiles, lazygit, and Git hooks/config, with interactive Git identity setup. Zsh, tmux, VS Code, btop, and hunk setup are opt-in. `setup-ai` is the additional AI-workstation layer; its install and config toggles default off and are enabled explicitly with flags. Both use `setup-helper` for shared behavior; `setup-sec` is a separate optional security-tool workflow that follows the same install skeleton and shares the `-upc` update-check pattern.
- `profiles/` is the day-to-day shell layer: environment settings, aliases, and functions for workflows such as Git, containers, Ansible, and security tools. `profile-append` loads the general modules in order; `profile-sec` loads security modules. Keep shell startup lightweight; put substantial standalone tasks in `bin/` rather than expanding profiles.
- `bin/` contains those standalone Bash helpers, including project sessionizers, Git sync/release helpers, Docker/Proxmox operations, and system/network tests. `bin/_sessionizer-common` is sourced by the sessionizer entry points. Do not leave build artifacts in `bin/`: the directory is symlinked onto `PATH`, and `.gitignore` only allows files there.
- `zsh/`, `tmux/`, `nvim/`, `code/`, `zed/`, and `git/` hold multi-file or tool-specific configuration. `configs-single/` is for services/tools with a single managed config or unit file; keep multi-file configurations in their tool directory.
- `ai/` is both the OpenCode setup catalog and a growing reusable skill/knowledge base. `setup-ai -soc` interactively configures OpenCode providers, MCPs, agents, LSPs, and skills; `setup-ai-config` links repository-owned skills and fetches selected upstream skills. `ai/setup-ai-opencode.conf` owns skill candidates, bundles, defaults, and pinned source revisions. `ai/LLAMACPP.md` documents the local model-server workflow and `ai/REA.md` documents the reverse-engineering stack.
- `setup-install`, `setup-config`, and `setup-upc` are sourced by `setup`; `setup-ai-install`, `setup-ai-config`, and `setup-ai-upc` are sourced by `setup-ai`; `ai/setup-ai-opencode.conf` and `ai/setup-ai-llamacpp.conf` are sourced Bash configuration, not standalone data formats. In each group the executable keeps the banner, CLI flags, `main`/`usage`/`parse_args`, and the config data (toggles, version pins, paths); `*-install` holds the `install_*` functions, `*-config` the `setup_*` functions, `*-upc` the update-check functions, and none is ever run on its own.
- Zsh plugins/themes and tmux TPM are Git submodules. `setup_zsh`/`setup_tmux` (and `./setup -usub`) run `git submodule update --remote`, so the checkout follows each upstream branch while the recorded gitlink stays put. `.gitmodules` sets `ignore = all`: moved pins never show in `git status`, `git add -A` and `git commit -a` never record them, and freezing a pin needs an explicit `git add <submodule-path>`.

The root `.gitignore` is deny-by-default and explicitly allow-lists tracked paths. Add a matching exception when introducing a new file or directory; otherwise Git will hide it.

## Startup and setup behavior

`setup_profiles` links `profiles/profile-append` and `profiles/profile-sec`, creates `~/.profile-secrets` with mode `600`, then appends sources for those files and the secrets file to both `~/.zshenv` and `~/.bashrc`. Because Zsh reads `.zshenv` for every shell, keep these profiles fast and non-interactive; Bash reads the added lines from `.bashrc` in shells that load it. Keep the secrets file at mode `600` when changing profile setup. `setup_zsh` separately links `zsh/zshrc` to `~/.zshrc`.

`setup_bin` links repository `bin/` to `~/.local/bin/vm`; `profiles/profile1-base` prepends that directory when present, prepends `~/.local/bin`, and adds language-tool paths. This is how the standalone `vm-*` helpers enter the shell command path. Installer scripts set their own PATH; interactive-shell PATH comes from `profiles/profile1-base`, not `zsh/zshrc`. The default `setup` does not link Zsh plugins/config or tmux config; those have separate opt-in setup flags.

Run setup scripts from the repository root: they use relative paths and `$PWD`. `setup` and `setup-ai` keep installation separate from config setup; inspect their flag defaults and target paths before execution. Optional paths can invoke `sudo`, apt/dpkg, downloads/builds, GNOME settings, user systemd, or interactive model/skill selection.

`setup-ai -soc` generates/merges `~/.config/opencode/opencode.jsonc` from the repository config and interactive selections, backing up an existing file. In its config-section pickers, `none` removes the whole section; in the skill picker, it prunes managed upstream copies while repository-owned skill links remain. Edit the source config/generator rather than treating the live file as canonical. For llama.cpp generated runtime files and service behavior, read `ai/LLAMACPP.md` first.

Internet research uses the built-in `webfetch` (no configuration) and `websearch` (an Exa/Firecrawl/Parallel/Tavily/TinyFish key or Console hosted search via `/connect`). `setup_opencode` auto-detects provider keys and replaces the generated `websearch` block; read `ai/WEB-RESEARCH.md` for provider setup and safe-research practice.

Replacement policy is per target; do not impose one blanket backup/prompt policy. Many managed dotfiles intentionally replace the user's config: `create_symlink` and `copy_config` remove an existing destination first. Other paths preserve or back up data: Git setup makes a timestamped `~/.gitconfig` backup, Filebrowser keeps an existing config/database, llama.cpp backs up its generated environment file, and OpenLogi only seeds its config when missing, then leaves it to the GUI. Profile setup edits shell startup files. Before changing a target's behavior, establish whether it is a replaceable config or user/runtime data, then document its specific policy.

## Setup installer shape

New `setup` installers follow one order so they are easy to scan and to make
failure-safe: current version, preflight, dependencies, clone/build, install,
configure, dependency cleanup, new version, completion. Copy this skeleton:

```bash
# SERVICE :: install <name> ----------------------------------------------------
install_<name>() {
  print_info2 "\n🚀 <NAME> :: install <name>..."
  print_notes "   💡 current installed version :: '$(installed_version "$USER_LOCAL_PREFIX_BIN/<name>" --version)'"

  require_cmds <cmds> || return 1

  local packages_tools=(...)
  local packages_build=(...)
  install_dependencies_needs packages_tools[@] packages_build[@]

  clone_repo "$VERSION_<NAME>_REPO" "$DEPS_INSTALL_PATH/<name>" "$VERSION_<NAME>"
  pushd "$DEPS_INSTALL_PATH/<name>" 1>/dev/null
  # build...
  popd 1>/dev/null
  rm -rf "$DEPS_INSTALL_PATH/<name>" 1>/dev/null

  # install and configure...
  install_dependencies_needs_rm
  print_notes "   💡 new installed version :: '...'"
  print_info2 "✅ <NAME> :: <name> installed!"
}
```

Installer rules:

- Reuse shared helpers instead of inline copies: `apt_install`, `apt_remove`,
  `install_udev_rules`, `refresh_desktop_caches`, `clone_repo`, `fzf_select`,
  and `fzf_multi_select`.
- Declare every variable `local`; use `local -a` for arrays and
  `${LN_X:-...}` for every overridable path.
- Treat fzf exit 130 as "cancelled": skip the step without aborting under
  `set -e`.
- On a failure after dependencies are installed, run
  `install_dependencies_needs_rm` and remove the checkout before returning.
- Use `disable_setups` for setup flags that must not run, and keep the
  version-check path separate from install and setup flags.
- Follow the `vm-bash-script-style` conventions for quoting, headers, emoji,
  and blank lines.

## Compatibility and dependencies

The maintainer confirms Ubuntu on amd64 as the primary target. Installer paths use apt/dpkg, GNU/Linux utilities, and some GNOME/systemd integrations; several downloads explicitly target x86_64. Treat other distributions and architectures as unsupported unless requested and validated. The required minimum Ubuntu release is not documented.

Setup and utility scripts are primarily Bash. Zsh startup is configured in `zsh/zshrc`, while profile files are sourced by both Bash and Zsh. `fzf`, `git`, `curl`, `jq`, `sudo`, apt/dpkg, and tool-specific commands are conditional or required depending on the selected workflow. There is no repository-owned application test suite or root CI workflow in the tracked files; vendored submodules have their own tests and are not this repository's test suite.

## Safe changes and validation

- Preserve existing behavior unless a requested change is explicit. Before changing shell startup, PATH, aliases, environment variables, symlink targets, or setup defaults, trace the loading/install path and check effects in both Bash and Zsh.
- Preserve the user's staging workflow: leave AI-authored edits unstaged for review, do not stage, unstage, commit, reset, or amend unless explicitly asked, and inspect `git diff --cached` separately from `git diff`. If a file already has staged content, preserve it and make new changes visible as unstaged hunks.
- For Bash changes, apply the `vm-bash-script-style` skill. For repository audits, use `vm-repo-setup`; for adding/updating OpenCode skills, use `vm-skill-authoring`; for commit planning, use `vm-git-commit`. Load the relevant skill rather than copying its full procedure into this file.
- Write skills for reuse across projects. Keep the core procedure generic: inspect the active project's tools, paths, conventions, and risks instead of assuming this dotfiles repository. Preserve verified local expertise in a clearly labeled repository-specific section or companion reference, and state when it applies. For local skill integration, use `setup-ai-config` symlink entries and `.gitignore` allow-list entries; upstream candidates/pins live in `ai/setup-ai-opencode.conf`.
- GitHub skills use read-only credentials and never write to GitHub, even when asked. They may research, make requested local project changes, and prepare drafts or manual instructions for the user. Ensure `GH_TOKEN` does not override `GITHUB_TOKEN` with a write-capable value; see `ai/GITHUB.md`.
- When a reusable OpenCode workflow is discovered or changed, consider improving the relevant repository skill in `ai/` as well as implementation/docs. Use `vm-skill-authoring` for skill changes. For model catalog, generated provider, or service changes, read `ai/LLAMACPP.md`; `setup-ai` configures llama.cpp before OpenCode so the selected provider is merged.
- OpenCode V2 loads global and project `AGENTS.md` files as persistent instructions; it does not use `CLAUDE.md` as a fallback. Instructions are combined, not conflict-resolved. Keep this root file to repo-wide context and add nested files only for genuinely different subdirectory rules.
- Use skills for on-demand procedures, agents for distinct roles/models/permissions or delegation, and commands for repeatable prompt templates. In V2, a skill ID comes from its installed path; frontmatter `name` is a display label. Command shell blocks run outside the agent's tool permission flow, so treat them as executable trusted configuration.
- `AGENTS.md` is guidance, not enforcement. Use OpenCode `permissions` for tool allow/ask/deny rules and `policies` for hard restrictions. Shell tools have the host user's authority. Avoid duplicating the same guidance across instructions, skills, agents, and commands.
- For OpenCode schema and behavior changes, consult the V2 [Instructions](https://opencode.ai/v2/docs/instructions/), [Skills](https://opencode.ai/v2/docs/skills/), [Agents](https://opencode.ai/v2/docs/agents/), [Permissions](https://opencode.ai/v2/docs/permissions/), [Policies](https://opencode.ai/v2/docs/policies/), and [Commands](https://opencode.ai/v2/docs/commands/) documentation.
- Prefer parsing and static checks before sourcing or running scripts. Setup, profile, firewall, Docker, Proxmox, and systemd commands can modify the host or remote systems; run them only with explicit authorization and a suitable isolated target where possible.
- Be especially cautious with `bin/vm-quick-wg-vpn` (its firewall setup resets UFW rules), Docker volume backup modes that stop Docker or scale services, and Proxmox restore operations.
- `github-workflow` uses OpenCode V2's `subagent` interface, denies GitHub-side write actions, and asks before local Git mutations. If the GitHub MCP server or its tools change, verify its read/write permission action names against the registered tools.
- `rea-investigator` handles reverse engineering (APKs, firmware, native binaries) via the `rea` MCP server and the upstream `reverse-engineer-anything` skill. It confines writes to `reverse-engineer/`, asks before runtime execution of untrusted targets, and never uploads artifacts. REA never installs analysis engines; `setup-ai -irea` installs a free baseline (adb, binwalk, wabt, gdb, sigrok-cli, tshark, procps), the pinned jadx-headless-mcp JAR plus a full JDK, and optionally the free Hopper demo after a prompt, while Ghidra, Apktool, IDA, Kuna, and JEB remain caller-supplied, so expect missing prerequisites. `setup-ai -irea` installs the pinned `rea-agents` CLI into `~/.local`, `setup-ai -soc` writes the MCP entry, and `setup-ai -upc` compares the REA pin with npm and verifies the local JADX bridge against its pinned SHA-256. Do not let `rea setup --client opencode` write the generated `opencode.jsonc`; edit the conf instead. Read `ai/REA.md` for prerequisites and version bumps.
- Validate Bash changes with `bash -n <files>` and Zsh startup/profile changes with `zsh -n <files>`. Use `shellcheck -x` on Bash entry points that source other files; the repo `.shellcheckrc` sets `external-sources=true`, so a plain `shellcheck` run from the repo follows sourced files (without it, cross-file variables read as unused, SC2034). `.pre-commit-config.yaml` defines formatters/fixers as well as checks; review the resulting diff after running hooks.
- Update the README or relevant tool documentation when installation behavior, dependencies, supported environments, or operational steps change. Keep `AGENTS.md` concise and repository-specific; keep reusable skill workflows portable and scope local details separately.
- Use the ASCII hyphen-minus (`-`) for dash punctuation in prose, headings, comments, and examples. Avoid typographic em and en dashes.
