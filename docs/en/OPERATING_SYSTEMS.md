# Several operating systems on the same disk — base_inst_kali

## Currently supported systems

| Id | Name | Repository | arm64 support |
|---|---|---|---|
| `kali` | Kali Linux | `http.kali.org/kali` (kali-rolling) | Official and mature |
| `parrot` | Parrot OS | `deb.parrot.sh/parrot` (lts) | Official, but less tested than Kali on Apple Silicon |

Both are Debian-based distributions with their own `arm64` repository,
which enables the same method the project already used for Kali: adding
its repository and signing key on top of the cloned Debian/Asahi base,
instead of installing a full ISO image (which neither distribution
officially offers in a well-tested form for Apple Silicon).

> **Note on Parrot OS**: its arm64 support is real (official repository
> with `arch=arm64`), but less mature and with fewer users testing it on
> Apple Silicon than Kali. If some `parrot-tools-full` metapackage fails
> to install, check the log (`logs/paso_09_*.log`) and install the
> individual tools you need afterwards instead of blocking the whole
> install over one problematic package.

## How several systems coexist on the same external disk

Each active operating system (`ACTIVE_OS` in the state) has:

- **Its own partitions** on the external disk (numbers computed
  automatically by step 02 from whatever already exists).
- **Its own LVM volume group** (`vg<id>`) and its own LUKS container
  (`<id>_root_crypt`), with its own passphrase.
- **Its own progress** in the menu (`OS_<id>_STEP_<N>_STATUS`), so you
  can have Kali fully done and Parrot half-way through, and the menu
  shows the right thing for each.

Host steps (00, 01, 01a) are done **only once**, not per system: the
`iac` user, the root password, WiFi and the base packages belong to the
source Debian/Asahi system, not to each clone.

## What to check after adding a second operating system

Step 07 (grub.cfg merge) runs `update-grub` on the host before merging
the entry of the system being processed at that moment. That
**regenerates the host's `grub.cfg` from scratch**, so:

- The entry of the system you processed **first** (e.g. Kali) may
  reappear thanks to `os-prober` (which detects existing Linux
  installations), but as a generic "chainload" boot entry, not the
  native one with the correct kernel parameters that this script builds
  by hand.
- The entry of the system you're processing **now** (e.g. Parrot) does
  get the full, native treatment.

**Recommendation**: after adding a second operating system, boot and
check that both entries still appear in the GRUB menu and that both boot
correctly. If the older entry is missing or fails, you can re-run step
07 for that system (switch the active OS to it and re-run 07) to
regenerate its native merge.

## Adding a new operating system to the catalogue

All the generalization work is already done in the framework; adding a
new operating system (e.g. BlackArch) only requires touching three
places:

### 1. `lib/os_catalog.sh`

```bash
SUPPORTED_OS=(kali parrot blackarch)

declare -A OS_LABEL_CODE=(
    [kali]="KALI"
    [parrot]="PARROT"
    [blackarch]="BLKARCH"   # max. 11 characters for the EFI (FAT) label
)
```

### 2. `i18n/strings.es.sh` and `i18n/strings.en.sh`

```bash
STRINGS[os_blackarch_name]="BlackArch Linux"
STRINGS[os_blackarch_desc]="Short description..."
```

### 3. `steps/08_repositorios.sh` and `steps/09_instalacion_paquetes.sh`

Add a `blackarch)` branch to the `case "$TARGET_OS" in ... esac` in each
one, with the corresponding keys/repositories and metapackages,
following the same pattern as `kali`/`parrot`.

**Nothing else needs to change**: the menu, partition-number
calculation, partitioning, LUKS encryption, cloning, chroot and
`grub.cfg` merging are all fully generic and work for any id that
appears in `SUPPORTED_OS`.

### Before adding a system, check

- That the distribution has an **official apt repository with `arm64`
  architecture** (a desktop ISO for x86/amd64 alone isn't enough). Same
  requirement Kali and Parrot both meet.
- Which **metapackage(s)** install the desired toolset (the equivalent
  of `kali-linux-default` or `parrot-tools-full`).
- Whether it needs any Apple Silicon/u-boot-specific boot tweak not
  already covered by the generic step 06 (unlikely for a Debian-based
  distribution, but worth checking).
