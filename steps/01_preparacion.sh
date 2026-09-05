#!/bin/bash
# steps/01_preparacion.sh
# Basado en 0_preparacion.sh original. Ahora sin la parte de red (ver 01a).
STEP_ID="01"
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${BASE_DIR}/lib/state.sh"
source "${BASE_DIR}/lib/i18n.sh"
[ -z "${IAC_LANG:-}" ] && IAC_LANG="$(i18n_detect_default_lang)"
i18n_load "$IAC_LANG"
source "${BASE_DIR}/lib/common.sh"
CURRENT_STEP_ID="$STEP_ID"
init_step_log "$STEP_ID"
require_root

echo "$(t step01_title)"
echo "$(t step01_intro)"
echo

echo "$(t step01_change_root_pass)"
passwd

echo
echo "$(t step01_installing_packages)"
run_cmd "apt update" apt update
run_cmd "apt upgrade" apt upgrade -y
run_cmd "apt install paquetes base" apt install -y \
    initramfs-tools pciutils wpasupplicant tcpdump vim tmux vlan ntpdate \
    parted curl wget grub-efi-arm64 mtr-tiny dbus ca-certificates sudo \
    openssh-client mtools gdisk cryptsetup cryptsetup-initramfs lvm2 \
    os-prober rsync dosfstools gnupg1 gnupg2 locales keyboard-configuration \
    console-data whiptail
run_cmd "apt update" apt update
run_cmd "apt upgrade" apt upgrade -y

echo
echo "$(t step01_locale_keyboard)"
if [ -f /base_inst_kali/preparacion/keyboard ]; then
    run_cmd "copiar keyboard" cp /base_inst_kali/preparacion/keyboard /etc/default/keyboard
else
    log_warn "No existe /base_inst_kali/preparacion/keyboard, se omite la copia."
fi
if [ -f /base_inst_kali/preparacion/locale ]; then
    run_cmd "copiar locale" cp /base_inst_kali/preparacion/locale /etc/default/locale
else
    log_warn "No existe /base_inst_kali/preparacion/locale, se omite la copia."
fi
dpkg-reconfigure locales
dpkg-reconfigure keyboard-configuration
dpkg-reconfigure console-data
command -v setupcon >/dev/null 2>&1 && setupcon
run_cmd "update-initramfs" update-initramfs -c -k all

echo
echo "$(t step01_create_user)"
if id iac >/dev/null 2>&1; then
    log_warn "El usuario 'iac' ya existe, se omite la creación."
else
    run_cmd "useradd iac" useradd -m -c 'Ignacio Arduengo Cuesta' -s /bin/bash iac
fi
echo "$(t step01_ask_user_password)"
passwd iac

if [ -f /base_inst_kali/preparacion/sudoers ]; then
    run_cmd "copiar sudoers" cp /base_inst_kali/preparacion/sudoers /etc/sudoers
    echo "$(t step01_sudoers_copied)"
else
    log_warn "No existe /base_inst_kali/preparacion/sudoers, se omite (revisa manualmente los permisos sudo de 'iac')."
fi

echo
echo "$(t step01_done)"
mark_step_done "$STEP_ID"
