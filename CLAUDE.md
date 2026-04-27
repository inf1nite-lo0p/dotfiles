# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles, not an application. There is no build, no tests, no package manager. "Installing" means copying / symlinking the tracked files into `$HOME` via `setup.sh`.

## Install / sync workflow

```sh
./setup.sh        # prompts before overwriting $HOME files
./setup.sh -f     # skip the prompt (also: --force)
```

`setup.sh` does two different things and the distinction matters when editing it:

1. **`rsync` everything else into `$HOME`** (excluding `.git/`, `setup.sh`, `README.md`). Files like `.bash_profile`, `.aliases`, `.functions`, `.paths`, `.gitconfig`, `.completions`, `.bashrc` are *copied* — editing the copy in `$HOME` will not feed back into the repo. Edit them here and re-run `setup.sh` to propagate.
2. **`ln -sf` for a few specific files** — `tmux.conf`, `.inputrc`, `.claude/settings.json`, `.claude/statusline-shadcn.sh`, `.claude/hooks/dotfiles-context.sh`. These are *symlinks*, so changes in `$HOME` and in this repo are the same file.

If you add a new file to either group, update `setup.sh` accordingly. After running, `setup.sh` sources `~/.bash_profile` so the current shell picks up changes.

`.extra` is git-ignored and must exist on each machine — it holds per-machine git identity (see README).

## Shell load order (`.bash_profile`)

Order is load-bearing — do not reshuffle without understanding it:

1. `~/.paths` — sets `PATH`, `PNPM_HOME`, `BUN_INSTALL`, `NVM_DIR`, brew shellenv, krew, then runs WSL-specific `PATH` cleanup (strips `/mnt/c/...` Node/npm/pnpm/herd entries when `/proc/version` matches Microsoft/WSL) and a final `awk` dedupe pass. Always sourced, login or interactive.
2. `~/.aliases`, `~/.bash_logout`, `~/.functions`, `~/.extra` — sourced unconditionally if readable.
3. Early `return` for non-interactive shells — anything below this line (history, prompt, vi mode, starship, nvm, completions, just) only runs in interactive shells.
4. `nvm.sh` is loaded *before* `~/.completions`, because completions registers `kubectl`/`just`/`nvm` completions that may depend on those tools being on `PATH`.
5. `nvm use default --silent` runs on every interactive shell, so a new shell may briefly switch the active Node version.

## Claude Code integration (`.claude/`)

- `settings.json` registers two `SessionStart` hooks (run in order on every session start):
  - starts `wsl-screenshot-cli` as a daemon (stopped on `SessionEnd`).
  - runs `hooks/dotfiles-context.sh`, which dumps the user's git aliases, shell aliases, and shell function names as `additionalContext` JSON. **This is why a "User dotfiles snapshot" appears in the session context** — that snapshot is generated live from `~/.gitconfig`, `~/.aliases`, `~/.functions` on session start. If you change those files, restart the Claude session (or re-source) to refresh the snapshot.
- `statusline-shadcn.sh` reads a JSON blob on stdin (model, cwd, context %, cost, rate limits) and prints up to three styled lines. The branch is rendered as an OSC 8 hyperlink to the GitHub branch when `origin` is GitHub.
- `dotfiles-context.sh` requires `jq` (it constructs the JSON output safely via `jq -n`). If `jq` is missing the hook fails — leave the `jq` invocation alone.

## Conventions when editing here

- Prefer the user's own aliases when invoking commands the user would naturally use (e.g. `git s` over `git status -s`, `g`, `j`, `k`). The session-start snapshot lists them.
- Functions in `.functions` follow a consistent shape: a `--help` / `-h` flag prints a heredoc help block before any work runs. Keep that pattern when adding functions.
- `.gitconfig` has **two `[alias]` sections** — this is intentional (logical grouping); don't merge them.
- Most `.functions` were written for macOS originally. The `o` / `open` shim and `is_wsl` already paper over Linux/WSL; some others (`cdf`, `phpserver`, `targz`'s `stat -f`) still assume macOS and will silently no-op or fall through on Linux. Don't "fix" these unless asked.
