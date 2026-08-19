#!/usr/bin/env bash
# CHANGELOG: Install and enable the ufw firewall, defaulting to deny incoming / allow outgoing
# CHANGELOG: Open KDE Connect (1714-1764), plus Steam in-home streaming if the gaming category is selected
# CHANGELOG: Open SSH first if sshd is running, so this can't cut an SSH session

# Same setup a fresh install gets. Every step is idempotent, so re-running it
# on a machine that already has ufw configured is a no-op.
source "$RAT_DIR/install/17-firewall.sh"
