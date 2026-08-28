# AGENTS

<!-- lane:protocol -->
## Context memory

- Before editing a file, read `.lane/memory/<path>/` if it exists, or run `lane why <path>`.
- Record non-obvious findings with `lane note add <path> -a <anchor> "..."`.
- Do not edit `.lane/` by hand; landing manages it.
- Land with `lane merge`, or `lane push` where trunk is protected, then `lane prune` once it merges.
- Detailed workflow lives in `.agents/skills/lane/SKILL.md`; run `lane install skill` if it is absent.
<!-- /lane:protocol -->

## This repo

The detailed lane workflow lives in the user-level skill at
`~/claude-config/skills/lane/SKILL.md`, loaded in every Claude session. No need
to run `lane install skill` here.

Read `CLAUDE.md` before editing: `setup.sh` rsyncs this directory into `$HOME`,
so most files here are *copies*, and anything that must not reach `$HOME` needs
an `--exclude` entry.
