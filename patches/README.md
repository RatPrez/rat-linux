# Patches

One-off migration scripts for machines that already have rat-linux installed.
`rat update` only pulls the repo and upgrades packages — it does **not**
re-run `install/*.sh` (that only happens on a fresh box) — so any change an
already-installed machine needs to pick up (renaming a file, one-time
cleanup, fixing something a past install left in a bad state, etc.) needs a
patch here.

## Naming

```
NNNN-short-description.sh
```

`NNNN` is a zero-padded, strictly increasing number (`0001`, `0002`, ...).
`rat update` runs every patch numbered higher than the machine's current
patch level, oldest first, and stops at the first failure — nothing after a
broken patch runs until it's fixed and `rat update` is re-run.

## Writing one

A patch is a plain shell script, sourced with `lib/common.sh` already loaded
(same as `install/*.sh`), so `log`/`ok`/`warn`/`die`, `$RAT_DIR`,
`pac_install`, `aur_install`, and `read_list` are all available. Exit non-zero
(or let `set -e` do it) on failure.

Give it one or more `# CHANGELOG: ...` comment lines up top — `rat update`
greps these straight out of the file (without running it) and prints them as
a bullet list before applying the patch, so whoever's watching the update
knows what's about to change:

```sh
#!/usr/bin/env bash
# CHANGELOG: Disable the baloo file indexer — it was causing lag
# CHANGELOG: Mask kde-baloo.service so it doesn't come back on next login
```

## Tracking

The current patch level is stored per-machine at
`~/.local/state/rat-linux/patch-level` — NOT in the repo, since different
machines may be at different levels. A **fresh** install seeds this to the
highest patch number already in this directory at install time (module
`install/12-rat-cli.sh`), since a fresh checkout already reflects that state
and shouldn't replay history. Check a machine's level with `rat patch-status`.
