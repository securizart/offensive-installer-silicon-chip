#!/bin/bash
# steps/05_chroot_prep.sh
STEP_ID="05"
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${BASE_DIR}/lib/state.sh"
source "${BASE_DIR}/lib/os_catalog.sh"
source "${BASE_DIR}/lib/i18n.sh"
[ -z "${IAC_LANG:-}" ] && IAC_LANG="$(i18n_detect_default_lang)"
i18n_load "$IAC_LANG"
source "${BASE_DIR}/lib/common.sh"
CURRENT_STEP_ID="$STEP_ID"
init_step_log "$STEP_ID"
require_root

TARGET_OS="$(state_get ACTIVE_OS)"
TARGET_DISK="$(state_get TARGET_DISK)"
PART_EFI="$(os_state_get "$TARGET_OS" PART_EFI)"
PART_BOOT="$(os_state_get "$TARGET_OS" PART_BOOT)"
PART_ROOT="$(os_state_get "$TARGET_OS" PART_ROOT)"
VG="$(os_vg_name "$TARGET_OS")"
CRYPTNAME="$(os_crypt_name "$TARGET_OS")"
MNT="$(os_mountpoint "$TARGET_OS")"

if [ -z "$TARGET_OS" ] || [ -z "$PART_ROOT" ]; then
    log_error "Faltan datos de SO/disco/particiones (ejecuta antes los pasos 00, 02, 03 y 04)."
    exit 1
fi

echo "$(t step05_title "$(t "os_${TARGET_OS}_name")")"
echo "$(t step05_intro)"
echo

if [ -f /base_inst_kali/preparacion/grub ]; then
    run_cmd "copiar grub host" cp /base_inst_kali/preparacion/grub /etc/default/grub
else
    log_warn "No existe /base_inst_kali/preparacion/grub en el host, se omite."
fi

[ -e "/dev/mapper/${CRYPTNAME}" ] || run_cmd "luksOpen" cryptsetup open "${TARGET_DISK}${PART_ROOT}" "$CRYPTNAME"

mkdir -p "$MNT"
echo "$(t step05_mounting)"
run_cmd "mount root" mount "/dev/mapper/${VG}-root" "$MNT"
if [ -f /base_inst_kali/preparacion/modules.txt ]; then
    run_cmd "copiar modules.txt" cp /base_inst_kali/preparacion/modules.txt "${MNT}/etc/initramfs-tools/modules"
else
    log_warn "No existe /base_inst_kali/preparacion/modules.txt, se omite."
fi
run_cmd "mount boot" mount "${TARGET_DISK}${PART_BOOT}" "${MNT}/boot"
run_cmd "mount efi" mount "${TARGET_DISK}${PART_EFI}" "${MNT}/boot/efi"
run_cmd "mount sysfs" mount -t sysfs none "${MNT}/sys"
run_cmd "mount efivarfs" mount -t efivarfs none "${MNT}/sys/firmware/efi/efivars"
run_cmd "mount proc" mount -t proc none "${MNT}/proc"
run_cmd "bind dev" mount -o bind /dev "${MNT}/dev"
run_cmd "bind dev/pts" mount -o bind /dev/pts "${MNT}/dev/pts"

echo "$(t step05_copying_grub_script)"
# Copiamos TODO el instalador (lib/i18n/steps) dentro del chroot, así el
# paso 06 puede ejecutarse con el mismo framework de logging/idioma.
run_cmd "copiar instalador al chroot" rsync -a --exclude logs "$BASE_DIR"/ "${MNT}/base_inst_kali_installer/"
if [ -f /base_inst_kali/preparacion/grub ]; then
    run_cmd "copiar grub.iac" cp /base_inst_kali/preparacion/grub "${MNT}/etc/default/grub.iac"
fi

mark_os_step_done "$TARGET_OS" "$STEP_ID"
echo
echo "$(t step05_entering_chroot)"
chroot "$MNT"
