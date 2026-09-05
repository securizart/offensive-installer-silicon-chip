#!/bin/bash
# steps/02_particiones.sh
# Particiona el disco externo PARA EL SISTEMA OPERATIVO ACTIVO
# ($TARGET_OS). Es un paso "por SO": si el disco ya tiene particiones de
# otro sistema (p. ej. Kali) y ahora activas Parrot, este script calcula
# automáticamente los siguientes números de partición libres, para no
# tocar lo que ya existe.
STEP_ID="02"
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
if [ -z "$TARGET_OS" ]; then
    log_error "No hay un sistema operativo activo. Elígelo antes desde el menú (opción 'Sistemas operativos')."
    echo "No hay un sistema operativo activo. Elígelo antes desde el menú."
    exit 1
fi
TARGET_DISK="$(state_get TARGET_DISK)"
if [ -z "$TARGET_DISK" ] || [ ! -b "$TARGET_DISK" ]; then
    log_error "TARGET_DISK no está definido o no es válido (ejecuta antes el paso 00)."
    echo "TARGET_DISK no está definido o no es válido. Ejecuta antes el paso 00."
    exit 1
fi

echo "$(t step02_title "$(t "os_${TARGET_OS}_name")")"
echo "$(t step02_intro "$TARGET_DISK" "$(t "os_${TARGET_OS}_name")")"
echo

# --- calcular números de partición libres para este SO --------------------
PART_EFI="$(os_state_get "$TARGET_OS" PART_EFI)"
PART_BOOT="$(os_state_get "$TARGET_OS" PART_BOOT)"
PART_ROOT="$(os_state_get "$TARGET_OS" PART_ROOT)"

if [ -z "$PART_EFI" ]; then
    MAXPART="$(sgdisk -p "$TARGET_DISK" 2>/dev/null | awk '/^[[:space:]]*[0-9]+/{print $1}' | sort -n | tail -n1 || true)"
    MAXPART="${MAXPART:-0}"
    PART_EFI=$((MAXPART+1))
    PART_BOOT=$((MAXPART+2))
    PART_ROOT=$((MAXPART+3))
    os_state_set "$TARGET_OS" PART_EFI "$PART_EFI"
    os_state_set "$TARGET_OS" PART_BOOT "$PART_BOOT"
    os_state_set "$TARGET_OS" PART_ROOT "$PART_ROOT"
    log_info "Particiones calculadas para $TARGET_OS en $TARGET_DISK: EFI=$PART_EFI BOOT=$PART_BOOT ROOT=$PART_ROOT (disco ya tenía hasta la partición $MAXPART)"
else
    log_info "Reutilizando particiones ya calculadas para $TARGET_OS: EFI=$PART_EFI BOOT=$PART_BOOT ROOT=$PART_ROOT"
fi
echo "$(t step02_partitions_planned "$PART_EFI" "$PART_BOOT" "$PART_ROOT")"

confirm_destructive "${TARGET_DISK} (particiones ${PART_EFI}, ${PART_BOOT}, ${PART_ROOT})"

EFI_LABEL="$(os_efi_label "$TARGET_OS")"
BOOT_LABEL="$(os_boot_label "$TARGET_OS")"
ROOT_LABEL="$(os_root_label "$TARGET_OS")"

echo "$(t step02_partitioning "$TARGET_DISK")"
run_cmd "sgdisk new efi" sgdisk --new=${PART_EFI}:0:+512M "$TARGET_DISK"
run_cmd "sgdisk new boot" sgdisk --new=${PART_BOOT}:0:+2G "$TARGET_DISK"
run_cmd "sgdisk new root" sgdisk --new=${PART_ROOT}:0:+87G "$TARGET_DISK"
run_cmd "sgdisk typecode" sgdisk --typecode=${PART_EFI}:ef00 --typecode=${PART_BOOT}:8301 --typecode=${PART_ROOT}:8301 "$TARGET_DISK"
run_cmd "sgdisk change-name" sgdisk --change-name=${PART_EFI}:${EFI_LABEL} --change-name=${PART_BOOT}:${BOOT_LABEL} --change-name=${PART_ROOT}:${ROOT_LABEL} "$TARGET_DISK"
run_cmd "sgdisk hybrid" sgdisk --hybrid ${PART_EFI}:${PART_BOOT}:${PART_ROOT} "$TARGET_DISK"

os_list_add "$TARGET_OS"
mark_os_step_done "$TARGET_OS" "$STEP_ID"
echo
echo "$(t step02_done_reboot)"
echo "$(t generic_rebooting)"
sleep 5
reboot
