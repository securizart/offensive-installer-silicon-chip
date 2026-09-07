# Offensive Installer Silicon Chip (base_inst_kali)

**[Leer esto en castellano → README.md](README.md)**

A menu-driven, multilingual (ES/EN) installer with support for
**several offensive operating systems** (Kali Linux, Parrot Security
OS, and Ubuntu) on an external USB disk with encrypted partitions,
cloned from a **Debian/Asahi** (or **Ubuntu/Asahi**, depending on the
target) base already installed on an Apple Silicon MacBook Air/Pro
(M1/M2). `/boot` (EFI + kernel) stays on the Mac's internal disk; the
root filesystem lives on the external disk.

```
Debian/Asahi (internal NVMe, already installed) ──clones──▶ external USB disk
                                                              ├── Kali Linux (its own partitions)
                                                              └── Parrot Security OS (its own partitions)
```

> ⚠️ **Project status:** actively in development. The scripts are
> functional but not yet meant for "blind" use. Read the risks section
> before running anything.

## Non-negotiable prerequisite before using this

**The MacBook must already have, installed and up to date on its
internal disk (NVMe), the base operating system matching whichever
target you want to clone toward**, before running anything from this
repository:

- **Asahi Linux / Debian** — to clone toward **Kali** or **Parrot**
  (converted by adding their repository on top of this base).
- **Ubuntu Asahi** — to clone toward **Ubuntu** (cloned as-is, no
  conversion; see [ubuntuasahi.org](https://ubuntuasahi.org/)).

This project **does not install macOS or any of these bases**: it
assumes they already exist and work, and clones whichever one matches
onto an external disk. The installer automatically checks, before
partitioning or cloning, that the booted system matches what the chosen
target requires (see
[docs/en/OPERATING_SYSTEMS.md](docs/en/OPERATING_SYSTEMS.md)).

Follow the official guide if you don't have it yet:
<https://wiki.debian.org/InstallingDebianOn/Apple/M1> (Debian's Bananas
project, based on Asahi Linux's work). This installer's step `00`
checks for signs of that installation (arm64 architecture, `asahi-*`
packages) and warns you if it can't find them, but making sure that
base is ready and up to date is a prerequisite for using this
repository, not something it does for you.

## What does this project do?

It automates and chains together a workflow that today requires
combining several scattered guides and a fair amount of manual
trial-and-error:

- Checks prerequisites, then partitions, encrypts (LUKS) and formats an
  **external USB disk**.
- **Clones** the running system (Debian/Asahi or Ubuntu/Asahi,
  depending on the chosen target) onto that external disk.
- Adds the repositories and metapackages of **Kali Linux** and/or
  **Parrot Security OS** on top of that cloned base, using each
  distribution's official mechanisms, turning it into a full
  penetration-testing distribution bootable from the GRUB menu
  alongside the original system. **Ubuntu**, on the other hand, is
  cloned as-is (no conversion), with the option to add **SIFT
  Workstation (SANS)** on top for forensics.
- Lets you install **more than one offensive system on the same
  external disk**, each in its own partitions, without overwriting each
  other's data.
- All of it guided by a **single menu** (`install.sh`) with persistent
  progress (survives the multiple reboots the process requires),
  per-step **logging**, and text in **Spanish and English**.

## Requirements

- MacBook with an Apple M1 or M2 chip, with Asahi Linux/Debian already
  installed and up to date (see above).
- External hard drive/SSD with enough free space (60 GB or more
  recommended per operating system you install).
- Stable internet connection throughout the whole process.
- A full backup of your data before starting (see Risks below).
- **Deep knowledge of Linux system administration and operation**
  (partitioning, LVM, LUKS, chroot, GRUB, APT package management). This
  is NOT an installer meant for someone new to Linux: any
  misunderstood step can leave the Mac unable to boot. If any of the
  terms above aren't familiar to you, learn them first before touching
  the internal or external disk.

## ⚠️ Risks and warnings

- This process modifies the external disk's partition layout and boot
  firmware, and adds entries to the internal system's `grub.cfg`. A
  failure during these steps can temporarily or permanently prevent the
  system from booting correctly.
- **Make as many backups of your macOS as necessary** before starting
  (Time Machine and, if possible, a full disk clone with a tool such as
  Carbon Copy Cloner or SuperDuper). This isn't "one backup just in
  case": make repeated backups to different destinations if the machine
  holds data you can't afford to lose, and verify they're actually
  restorable before you start, not afterwards.
- **Check for yourself that the Debian/Asahi base version you have
  installed is compatible with the version of Kali Linux or Parrot OS
  you're about to install.** This installer adds Kali's (`kali-rolling`)
  or Parrot's (`lts`) repositories on top of whatever Debian base you
  already have; if that base is too old, too new, or doesn't match what
  each distribution expects as its starting point, the `dist-upgrade` in
  steps 08-09 can leave the system broken or half-upgraded. Check Kali's
  and Parrot's official documentation on base requirements before
  running those steps, and don't assume "the latest available Debian
  version" is automatically the right one.
- There is no automatic uninstaller yet. Reverting the changes requires
  manual partition editing.
- Use this project at your own risk. Recommended only on test machines
  or with a full, verified backup.

## Getting started

```bash
git clone https://github.com/securizart/offensive-installer-silicon-chip.git
cd offensive-installer-silicon-chip
sudo bash install.sh
```

Full documentation (architecture, step-by-step usage guide, managing
several operating systems, troubleshooting):

| Document | English | Castellano |
|---|---|---|
| Architecture | [docs/en/ARCHITECTURE.md](docs/en/ARCHITECTURE.md) | [docs/es/ARQUITECTURA.md](docs/es/ARQUITECTURA.md) |
| Usage guide | [docs/en/USAGE.md](docs/en/USAGE.md) | [docs/es/GUIA_USO.md](docs/es/GUIA_USO.md) |
| Several operating systems | [docs/en/OPERATING_SYSTEMS.md](docs/en/OPERATING_SYSTEMS.md) | [docs/es/SISTEMAS_OPERATIVOS.md](docs/es/SISTEMAS_OPERATIVOS.md) |
| Troubleshooting | [docs/en/TROUBLESHOOTING.md](docs/en/TROUBLESHOOTING.md) | [docs/es/TROUBLESHOOTING.md](docs/es/TROUBLESHOOTING.md) |

Other repository files: [CHANGELOG.md](CHANGELOG.md) ·
[CONTRIBUTING.en.md](CONTRIBUTING.en.md) · [LICENSE](LICENSE)

## Repository structure

```
install.sh          main menu (always run from here)
lib/
  common.sh           logging, set -e/trap, destructive confirmations
  i18n.sh             translation engine: t key arg1 arg2...
  ui.sh               whiptail with plain-text fallback
  state.sh            persistent progress (global and per OS)
  os_catalog.sh        catalogue of supported operating systems
i18n/
  strings.es.sh        Spanish strings
  strings.en.sh        English strings
steps/
  00_check_prerreq.sh          host, once: prerequisites + disk
  01_preparacion.sh            host, once: base packages + user
  01a_network.sh               host, once: WiFi
  02_particiones.sh            per OS: partitioning
  03_formateo.sh                per OS: LUKS + LVM + mkfs
  04_clonado.sh                 per OS: clone the current system
  05_chroot_prep.sh             per OS: mount + chroot
  06_grub_finiquitar.sh         per OS: GRUB (inside the chroot)
  07_fusion_grub.sh             per OS: merge grub.cfg
  08_repositorios.sh            per OS: Kali or Parrot repositories
  09_instalacion_paquetes.sh    per OS: Kali or Parrot metapackages
logs/
  install.log                  master log
  paso_<id>_<date>.log         detailed log of each run
docs/
  es/, en/                     detailed documentation (see table above)
```

For details on why steps are split into "host" (once) and "per
operating system" (repeatable), and how progress state travels between
the original system, the chroot, and the already-booted cloned system,
see [docs/en/ARCHITECTURE.md](docs/en/ARCHITECTURE.md).

## Adding a new operating system to the catalogue

See [docs/en/OPERATING_SYSTEMS.md](docs/en/OPERATING_SYSTEMS.md) — in
short: add its id to `lib/os_catalog.sh`, its strings to
`i18n/strings.*.sh`, and its repository/metapackage branch in
`steps/08_repositorios.sh` and `steps/09_instalacion_paquetes.sh`. The
rest of the framework (menu, partitioning, cloning, GRUB) is generic and
doesn't need to change.

## Tested compatibility

| Model | Status |
|---|---|
| MacBook Air M1 | ✅ Tested (Kali and Parrot) |
| MacBook Air M2 | ✅ Tested (Kali and Parrot) |
| MacBook Pro M1 | To be tested |
| MacBook Pro M2 | To be tested |

Update this table as confirmed via the repository's `Issues`.

> If the firmware/u-boot doesn't detect the external disk at boot, see
> ["The firmware doesn't detect the external disk at boot"](docs/en/TROUBLESHOOTING.md#the-firmware-doesnt-detect-the-external-disk-at-boot)
> in the troubleshooting guide.

## Video demo

[![Demo: installing Kali, Parrot and Ubuntu on Debian/Asahi on Apple Silicon](https://img.youtube.com/vi/JsPsCAa4XBU/hqdefault.jpg)](https://youtu.be/JsPsCAa4XBU)

▶️ **[Watch on YouTube](https://youtu.be/JsPsCAa4XBU)**

The video also shows the installation and use of **Ubuntu** on top of
this same base, as a proof of concept — see the roadmap below.

## Roadmap

- ~~Ubuntu as a third installable operating system~~ — **implemented**:
  `ubuntu` is now in the catalogue (`lib/os_catalog.sh`), cloned as-is
  from a genuine Ubuntu/Asahi installation (no conversion, unlike
  Kali/Parrot). Includes idempotent `ubuntu-desktop` install and,
  optionally, **SIFT Workstation (SANS)** — official arm64 support
  confirmed on Ubuntu 22.04/24.04. See
  [docs/en/OPERATING_SYSTEMS.md](docs/en/OPERATING_SYSTEMS.md) for the
  full detail, including why CAINE and REMnux were discarded.
- Next: keep improving Parrot OS integration (its arm64 support is
  still less mature than Kali's) and evaluate more forensic tools on
  top of the now-available Ubuntu base.
- **REMnux, under investigation (not fully discarded)**: a direct
  comparison of its `.sls` files against SIFT's (which does have
  official arm64 support) shows REMnux's core mechanism (Launchpad-PPA
  repo, already arm64-aware `cast` bootstrap) doesn't have the same
  structural problem SIFT had, but does carry a different risk
  category: Wine-dependent tools (immature arm64 support) and
  third-party binaries published amd64-only (e.g. PolarProxy). Plan:
  try `cast install --mode=addon` with a subset of `.sls` files with no
  Wine dependencies, to measure what fraction actually works, before
  deciding whether to integrate it as an option in step 09 (like SIFT)
  or document it as "unsupported." See
  [docs/en/OPERATING_SYSTEMS.md](docs/en/OPERATING_SYSTEMS.md).

## Prior art / Credits

This project doesn't start from scratch: it builds on and credits prior
community work, including:

- [AsahiLinux/asahi-installer](https://github.com/AsahiLinux/asahi-installer) —
  the base Linux installer for Apple Silicon.
- [kali-asahi](https://github.com/allamiro/kali-asahi) — native Kali
  image for Apple Silicon.
- Official Kali documentation on
  [APT repositories](https://www.kali.org/docs/general-use/kali-apt-sources/)
  and metapackages (`kali-linux-headless`, `kali-linux-everything`).
- [ParrotSec's Debian Conversion Script](https://gitlab.com/parrotsec/project/debian-conversion-script) —
  the Parrot team's official script for converting a Debian base.
- The [Void Linux on Apple Silicon](https://docs.voidlinux.org/installation/guides/arm-devices/apple-silicon.html)
  guide, used as a reference for the external-partition pattern with an
  internal `/boot/efi`.
- Debian's guide for Apple Silicon
  (<https://wiki.debian.org/InstallingDebianOn/Apple/M1>, Bananas
  project), as the reference for the Asahi/Debian base prerequisite.

**What this project adds on top of the above:** it integrates and
automates into a single repeatable flow, with a menu, persistent
progress, logging and a configurable language, steps that were
previously scattered across independent guides — and lets you install
**several offensive systems at once** on the same external disk,
without them colliding.

## Legal notice and ethical use

This project installs tools aimed at penetration testing and offensive
security (Kali Linux, Parrot Security OS). Its use is permitted
**only** on systems you own or for which you have explicit
authorization from the owner. Using these tools against third-party
systems without authorization may be illegal depending on jurisdiction;
the author is not responsible for any misuse of the tools installed
through this project.

## License

Distributed under the GPLv3 license. See the [LICENSE](LICENSE) file.

## Contributing

Contributions are welcome. Open an Issue to report problems or a Pull
Request for improvements. See [CONTRIBUTING.en.md](CONTRIBUTING.en.md).
