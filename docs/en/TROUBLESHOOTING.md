# Troubleshooting — base_inst_kali

## "No active operating system"

Steps 02-09 need an active OS. Go to the menu, "Operating systems"
option, and pick Kali or Parrot before continuing.

## "TARGET_DISK is not set or invalid"

Step 00 hasn't run, or it ran but the selected disk later disappeared
(e.g. you unplugged the USB). Check:

```bash
cat /var/lib/base_inst_kali/state.conf | grep TARGET_DISK
lsblk
```

Re-run step 00 if it needs fixing. Note: `TARGET_DISK` is shared across
every operating system you install on that disk, no need to repeat it
per OS.

## The menu marks a step as "✖ failed, retry"

Look at that specific step's log:

```bash
ls -t logs/paso_<ID>_*.log | head -1 | xargs cat
```

The full run output (including `apt`, `sgdisk`, etc.) is there. The
master log (`logs/install.log`) only has the summary line with where and
with what exit code it failed.

## whiptail doesn't show up even though I already ran step 01

Check the package actually installed:

```bash
dpkg -l whiptail
```

If it's missing, install it manually (`apt install whiptail`) and retry
the step; you don't need to redo anything earlier, `lib/ui.sh` picks it
up on its own the next time any script runs.

If `whiptail` is installed but the installer still runs in text mode,
there may be no real interactive terminal (for example, you're piping
input/output, or running inside `screen`/`tmux` in a way that doesn't
expose a tty). Run the script directly in a normal terminal.

## Exiting the chroot (step 06) doesn't mark "06" as done on the host menu

This is expected, not a bug: step 06 runs inside the chroot and writes
its progress to the mounted external disk's filesystem, not the host's.
That's why step 07 doesn't depend on that mark (see `NO_GATE_STEPS` in
`install.sh` and the corresponding section in
`docs/en/ARCHITECTURE.md`). Just continue with step 07 as normal.

## "/part/dest_<os>/boot/grub/grub.cfg does not exist" in step 07

The external disk got unmounted between step 05/06 and 07 (for example,
if you rebooted by accident). Repeat from step 05 (with the same active
OS) to mount and enter the chroot again, run 06 again, and continue with
07 without rebooting.

## I forgot an operating system's LUKS passphrase

There's no way to recover the data without it; it's real encryption.
You'll have to repeat from step 02 (repartition) or step 03
(reformat/re-encrypt) **for that specific operating system**, losing
whatever was on its partitions up to that point. Other operating systems
on the same disk are unaffected.

## After adding a second operating system, the first one no longer boots

See the corresponding section in `docs/en/OPERATING_SYSTEMS.md`: step 07
regenerates `grub.cfg` from scratch every time, and the most recently
processed system is the one that gets the full native entry. Switch the
active OS to the affected system and re-run step 07 to regenerate its
entry.

## I want to redo a step already marked "done"

Pick it from the menu anyway (it isn't locked — only the steps *after*
the first pending one are) or run it standalone:

```bash
sudo bash steps/04_clonado.sh
```

Keep in mind that partitioning/formatting/cloning steps are destructive
and will ask you for explicit confirmation, but redoing them means
losing whatever was done afterwards **for that operating system**.

## WiFi doesn't connect after step 01a

Check the generated file:

```bash
cat /etc/wpa_supplicant/wpa_supplicant.conf
```

If the SSID or password contain special characters and `wpa_passphrase`
wasn't used (because it wasn't available at the time), retry the step:
the script itself tries to use it automatically whenever it's present on
the system.

## A Parrot OS metapackage fails to install (step 09)

Parrot's arm64 support is official but less mature than Kali's. Check
`logs/paso_09_*.log` to see which specific package failed, then install
or replace it manually afterwards (`apt install <package>`); there's no
need to redo the whole step 09 over a single problematic package.
