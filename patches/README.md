# Patches

One-off migration scripts for machines that already have rat-linux installed,
for changes that a plain `git pull` + re-run of `install/*.sh` can't express
(renaming a file, one-time cleanup, fixing something a past install left in a
bad state, etc.).

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

## Tracking

The current patch level is stored per-machine at
`~/.local/state/rat-linux/patch-level` — NOT in the repo, since different
machines may be at different levels. A **fresh** install seeds this to the
highest patch number already in this directory at install time (module
`install/12-rat-cli.sh`), since a fresh checkout already reflects that state
and shouldn't replay history. Check a machine's level with `rat patch-status`.
