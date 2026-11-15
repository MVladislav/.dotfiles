# .dotfiles

Personal Ubuntu/amd64 dotfiles: shell startup, terminal and editor configs,
setup scripts, standalone helpers, and an OpenCode skill catalog.

## Quick start

Run from the repository root.

```sh
bash ./setup       # link dotfiles and optionally install base tools
bash ./setup-ai    # AI layer: OpenCode, llama.cpp, and related tools
bash ./setup-sec   # optional security tooling and wordlists
```

Each entry point keeps installation (`-i...`) separate from config setup
(`-s...`). Run `--help` for the available flags.

## What is here

- `profiles/` - shell startup modules for Bash and Zsh
- `bin/` - standalone helpers added to `PATH`
- `zsh/`, `nvim/`, `tmux/`, `zed/`, `code/`, `git/` - tool configs
- `configs-single/` - single-file configs for other tools
- `ai/` - OpenCode setup and skills

See `AGENTS.md` for conventions, script structure, and validation.
