#!/bin/bash
# steps/00_check_prerreq.sh
STEP_ID="00"
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/state.sh
source "${BASE_DIR}/lib/state.sh"
# shellcheck source=../lib/i18n.sh
source "${BASE_DIR}/lib/i18n.sh"
[ -z "${IAC_LANG:-}" ] && IAC_LANG="$(i18n_detect_default_lang)"
i18n_load "$IAC_LANG"
# shellcheck source=../lib/common.sh
source "${BASE_DIR}/lib/common.sh"
CURRENT_STEP_ID="$STEP_ID"
init_step_log "$STEP_ID"
require_root

echo "$(t step00_title)"
echo "$(t step00_intro)"
echo

# --- arquitectura ------------------------------------------------------
echo "$(t step00_checking_arch)"
ARCH="$(uname -m)"
if [ "$ARCH" != "aarch64" ] && [ "$ARCH" != "arm64" ]; then
    log_error "$(t step00_arch_fail "$ARCH")"
    echo "$(t step00_arch_fail "$ARCH")"
    exit 1
fi
log_info "Arquitectura OK: $ARCH"

# --- base Asahi/Debian ya instalada -------------------------------------
echo "$(t step00_checking_asahi)"
if ! dpkg -l 2>/dev/null | grep -qE '^ii\s+asahi-'; then
    if ! confirm_yes_no "$(t step00_asahi_not_found_warn)

$(t step00_confirm_continue_anyway)"; then
        log_warn "$(t log_aborted_by_user "$STEP_ID")"
        echo "$(t aborted_by_user)"
        exit 1
    fi
else
    log_info "Paquetes asahi-* detectados."
fi

# --- selección de disco destino -----------------------------------------
ROOT_SRC_DISK=""
if command -v findmnt >/dev/null 2>&1; then
    ROOT_SRC_DEV="$(findmnt -no SOURCE / 2>/dev/null || true)"
    # /dev/mapper/xxx-root o /dev/nvme0n1p2 -> intenta resolver el disco físico
    ROOT_SRC_DISK="$(lsblk -no PKNAME "$ROOT_SRC_DEV" 2>/dev/null | head -n1 || true)"
fi

# Construimos la lista de discos candidatos (excluyendo el disco raíz
# actual, que se asume que es el NVMe interno con macOS/Debian).
DISK_MENU_ARGS=()
while IFS= read -r line; do
    name="$(awk '{print $1}' <<<"$line")"
    [ "$name" = "$ROOT_SRC_DISK" ] && continue
    [ -z "$name" ] && continue
    rest="$(cut -d' ' -f2- <<<"$line")"
    DISK_MENU_ARGS+=("/dev/$name" "$rest")
done < <(lsblk -d -n -o NAME,SIZE,MODEL,TRAN)

TARGET_DISK=""
if [ "${#DISK_MENU_ARGS[@]}" -gt 0 ]; then
    TARGET_DISK="$(ui_menu "$(t step00_title)" "$(t step00_lsblk_hint)" "${DISK_MENU_ARGS[@]}")"
fi

while true; do
    if [ -z "$TARGET_DISK" ]; then
        TARGET_DISK="$(ui_inputbox "$(t step00_title)" "$(t step00_ask_target_disk)")"
    fi
    if [ ! -b "$TARGET_DISK" ]; then
        ui_msgbox "$(t step00_title)" "$(t step00_target_disk_invalid "$TARGET_DISK")"
        TARGET_DISK=""
        continue
    fi
    TARGET_BASENAME="$(basename "$TARGET_DISK")"
    if [ -n "$ROOT_SRC_DISK" ] && [ "$TARGET_BASENAME" = "$ROOT_SRC_DISK" ]; then
        ui_msgbox "$(t step00_title)" "$(t step00_target_disk_is_internal_warn "$TARGET_DISK")"
        TARGET_DISK=""
        continue
    fi
    break
done

state_set TARGET_DISK "$TARGET_DISK"
log_info "$(t step00_target_disk_confirmed "$TARGET_DISK")"
echo "$(t step00_target_disk_confirmed "$TARGET_DISK")"

echo
echo "$(t step00_done)"
mark_step_done "$STEP_ID"
