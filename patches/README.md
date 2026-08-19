# Patches

One-off scripts for changes that don't belong in `install/*.sh` as an
ongoing step: system tweaks, one-time cleanup, migrations for state a past
install left behind. `rat update` only pulls the repo and upgrades packages,
and does **not** re-run `install/*.sh`, so a patch is the only way an
already-installed machine picks up a change like this.

A **fresh** install runs every patch that exists too (at the end of
`install.sh`, same mechanism as `rat update`), so patches apply equally
whether the box is brand new or has been running for a year. Don't assume
"fresh install" means a patch can be skipped.

## Naming

```
NNNN-short-description.sh
```

`NNNN` is a zero-padded, strictly increasing number (`0001`, `0002`, ...).
`rat update` runs every patch numbered higher than the machine's current
patch level, oldest first, and stops at the first failure: nothing after a
broken patch runs until it's fixed and `rat update` is re-run.

## Writing one

A patch is a plain shell script, sourced with `lib/common.sh` already loaded
(same as `install/*.sh`), so `log`/`ok`/`warn`/`die`, `$RAT_DIR`,
`pac_install`, `aur_install`, and `read_list` are all available. Exit non-zero
(or let `set -e` do it) on failure.

Give it one or more `# CHANGELOG: ...` comment lines up top. `rat update`
greps these straight out of the file (without running it) and prints them as
a bullet list before applying the patch, so whoever's watching the update
knows what's about to change:

```sh
#!/usr/bin/env bash
# CHANGELOG: Disable the baloo file indexer, which was causing lag
# CHANGELOG: Mask kde-baloo.service so it doesn't come back on next login
```

## Tracking

The current patch level is stored per-machine at
`~/.local/state/rat-linux/patch-level`, **not** in the repo, since different
machines may be at different levels. It starts at 0 (unset), so on a brand
new machine every patch in this directory runs once, in order, before the
install is considered done. Check a machine's level with `rat patch-status`.
