# Offensive Installer Silicon Chip

An installer that automates the deployment of an offensive security
distribution (**Kali Linux** or **Parrot Security OS**) on Apple Silicon
MacBooks (M1/M2), using an **external hard drive** to host the root
filesystem, while the `/boot` partition (EFI + kernel) stays on the Mac's
internal disk.

> ⚠️ **Project status:** actively in development (v0.1). The scripts are
> functional but not yet meant for "blind" use. Read the risks section
> before running anything.

## What does this project do?

It automates and chains together a workflow that today requires combining
several scattered guides and a fair amount of manual trial and error:

1. Installing a minimal Debian/Asahi base on the Mac's internal disk.
2. Partitioning the external disk to host the root filesystem.
3. Installing the packages needed for a full graphical environment.
4. Converting that Debian base into Kali Linux or Parrot Security OS using
   each distribution's official mechanisms.

## Requirements

- MacBook with an Apple M1 or M2 chip.
- External hard drive/SSD with enough free space (60 GB or more recommended).
- Stable internet connection throughout the whole process.
- A full backup of your data before starting (see Risks below).
- Basic command-line and disk-partitioning knowledge.

## ⚠️ Risks and warnings

- This process modifies the Mac's partition layout and boot firmware. A
  failure during these steps can temporarily or permanently prevent macOS
  from booting.
- There is no automatic uninstaller yet. Reverting the changes requires
  manual partition editing.
- Use this project at your own risk. Recommended only on test machines or
  with a full, verified backup (Time Machine or otherwise).

## Prior art / Credits

This project doesn't start from scratch: it builds on and credits prior
community work, including:

- [AsahiLinux/asahi-installer](https://github.com/AsahiLinux/asahi-installer) —
  the base Linux installer for Apple Silicon.
- [kali-asahi](https://github.com/allamiro/kali-asahi) — native Kali image
  for Apple Silicon.
- Official Kali documentation on
  [APT repositories](https://www.kali.org/docs/general-use/kali-apt-sources/)
  and metapackages (`kali-linux-headless`, `kali-linux-everything`).
- [ParrotSec's Debian Conversion Script](https://gitlab.com/parrotsec/project/debian-conversion-script) —
  the Parrot team's official script for converting a Debian base.
- The [Void Linux on Apple Silicon](https://docs.voidlinux.org/installation/guides/arm-devices/apple-silicon.html)
  guide, used as a reference for the external-partition pattern with an
  internal `/boot/efi`.

**What this project adds on top of the above:** it integrates and automates
into a single repeatable flow steps that were previously scattered across
independent guides, specifically designed to install the system on an
external disk instead of partitioning the Mac's internal disk.

## Repository structure

```
scripts/
  01-asahi-base.sh          # Installs the minimal Debian/Asahi base on the internal disk
  02-partition-external.sh  # Prepares the external disk to host the root filesystem
  03-desktop-base.sh        # Installs the graphical environment on top of the Debian base
  04-convert-kali.sh        # Converts the base into Kali Linux
  04-convert-parrot.sh      # Converts the base into Parrot Security OS
config.example.sh           # Configuration variables to customize
docs/                       # Diagrams, screenshots and compatibility notes
```

## Usage

```bash
git clone https://github.com/<your-username>/offensive-installer-silicon-chip.git
cd offensive-installer-silicon-chip
cp config.example.sh config.sh
# edit config.sh with your machine's values (external disk, chosen distro, etc.)
./scripts/01-asahi-base.sh
```

Each script is documented in more detail in its own header.

## Tested compatibility

| Model          | Status      |
|----------------|-------------|
| MacBook Air M1 | To be tested|
| MacBook Air M2 | To be tested|
| MacBook Pro M1 | To be tested|
| MacBook Pro M2 | To be tested|

Update this table with community-reported `Issues`.

## Legal notice and ethical use

This project installs tools aimed at penetration testing and offensive
security. Its use is permitted **only** on systems you own or for which you
have explicit authorization from the owner. The author is not responsible
for any misuse of the tools installed through this project.

## License

Distributed under the GPLv3 license. See the [LICENSE](LICENSE) file.

## Contributing

Contributions are welcome. Open an Issue to report problems or a Pull
Request for improvements. See [CONTRIBUTING.md](CONTRIBUTING.md).
