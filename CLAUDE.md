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

1. **`rsync` everything else into `$HOME`** (excluding `.git/`, `setup.sh`, `README.md`, `wsl/`, `.lane/`, `AGENTS.md`). Files like `.bash_profile`, `.aliases`, `.functions`, `.paths`, `.gitconfig`, `.completions`, `.bashrc` are *copied* — editing the copy in `$HOME` will not feed back into the repo. Edit them here and re-run `setup.sh` to propagate.
2. **`ln -sf` for a few specific files** — `tmux.conf`. These are *symlinks*, so changes in `$HOME` and in this repo are the same file.

If you add a new file to either group, update `setup.sh` accordingly. After running, `setup.sh` sources `~/.bash_profile` so the current shell picks up changes.

Anything that belongs to the repo but **not** to `$HOME` must be added to the rsync `--exclude` list, or it gets copied into the home directory. `.lane/`, `AGENTS.md`, and `.extra` are excluded for exactly this reason.

`.extra` is excluded deliberately. It is gitignored per-machine state — git identity and tokens — that README step 4 tells you to create by hand, so it is never provisioned from this repo. Any `.extra` sitting in this directory is stale local scratch; without the exclude, `setup.sh` would rsync it over `~/.extra` and destroy secrets that exist only there.

`.extra` is git-ignored and must exist on each machine — it holds per-machine git identity (see README).

Claude Code configuration (`~/.claude/`) is **not** part of this public repo for privacy reasons. It lives in a separate, private repo at `~/claude-config/` (see its README). The symlinks at `~/.claude/settings.json`, `~/.claude/statusline-shadcn.sh`, and `~/.claude/hooks/dotfiles-context.sh` point into that repo.

## lane

This repo is lane-initialized (`.lane/` + the `AGENTS.md` protocol block). Before editing a tracked file here, run `lane why <path>` to read any recorded constraints, and record non-obvious ones with `lane note add`. See the user-level `lane` skill for the full workflow.

Use `lane new <name>` for an isolated worktree instead of editing `$HOME`-copied files in place. Note that this machine is **ext4 with no reflink support**, so a lane is a plain worktree — nothing ignored is cloned.

## Shell load order (`.bash_profile`)

Order is load-bearing — do not reshuffle without understanding it:

1. `~/.paths` — sets `PATH`, `PNPM_HOME`, `BUN_INSTALL`, `NVM_DIR`, brew shellenv, krew, then runs WSL-specific `PATH` cleanup (strips `/mnt/c/...` Node/npm/pnpm/herd entries when `/proc/version` matches Microsoft/WSL) and a final `awk` dedupe pass. Always sourced, login or interactive.
2. `~/.aliases`, `~/.bash_logout`, `~/.functions`, `~/.extra` — sourced unconditionally if readable.
3. Early `return` for non-interactive shells — anything below this line (history, prompt, vi mode, starship, nvm, completions, just) only runs in interactive shells.
4. `nvm.sh` is loaded *before* `~/.completions`, because completions registers `kubectl`/`just`/`nvm` completions that may depend on those tools being on `PATH`.
5. `nvm use default --silent` runs on every interactive shell, so a new shell may briefly switch the active Node version.

## Claude Code integration

Lives in `~/.claude-config/` (separate private repo). The session-start snapshot you see in this repo's context still flows from `~/.gitconfig`, `~/.aliases`, `~/.functions` — the hook script that emits it is `~/.claude-config/hooks/dotfiles-context.sh`. If you change those files, restart the Claude session (or re-source) to refresh the snapshot.

## Conventions when editing here

- Prefer the user's own aliases when invoking commands the user would naturally use (e.g. `git s` over `git status -s`, `g`, `j`, `k`). The session-start snapshot lists them.
- Functions in `.functions` follow a consistent shape: a `--help` / `-h` flag prints a heredoc help block before any work runs. Keep that pattern when adding functions.
- `.gitconfig` has **two `[alias]` sections** — this is intentional (logical grouping); don't merge them.
- Most `.functions` were written for macOS originally. The `o` / `open` shim and `is_wsl` already paper over Linux/WSL; some others (`cdf`, `phpserver`, `targz`'s `stat -f`) still assume macOS and will silently no-op or fall through on Linux. Don't "fix" these unless asked.
