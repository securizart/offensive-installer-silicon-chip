#!/bin/bash
# steps/09_instalacion_paquetes.sh
# Instala los metapaquetes del sistema operativo elegido ($TARGET_OS).
STEP_ID="09"
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${BASE_DIR}/lib/state.sh"
source "${BASE_DIR}/lib/i18n.sh"
[ -z "${IAC_LANG:-}" ] && IAC_LANG="$(i18n_detect_default_lang)"
i18n_load "$IAC_LANG"
source "${BASE_DIR}/lib/common.sh"
CURRENT_STEP_ID="$STEP_ID"
init_step_log "$STEP_ID"
require_root

TARGET_OS="$(state_get ACTIVE_OS)"
if [ -z "$TARGET_OS" ]; then
    log_error "No se ha podido determinar el SO activo (ACTIVE_OS vacío en el estado de este sistema)."
    exit 1
fi

echo "$(t step09_title "$(t "os_${TARGET_OS}_name")")"
echo "$(t step09_intro "$(t "os_${TARGET_OS}_name")")"
echo

case "$TARGET_OS" in
    kali)
        echo "$(t step09_installing "kali-linux-default, kali-desktop-gnome, kali-linux-large, kali-linux-arm")"
        run_cmd "kali-linux-default" apt-get install -y kali-linux-default -t kali-rolling
        run_cmd "kali-desktop-gnome" apt-get install -y kali-desktop-gnome -t kali-rolling
        run_cmd "kali-linux-large" apt-get install -y kali-linux-large -t kali-rolling
        run_cmd "kali-linux-arm" apt-get install -y kali-linux-arm -t kali-rolling
        ;;
    parrot)
        echo "$(t step09_installing "parrot-core, parrot-tools-full")"
        run_cmd "parrot-core" apt-get install -y parrot-core -t lts
        run_cmd "parrot-tools-full" apt-get install -y parrot-tools-full -t lts
        ;;
    ubuntu)
        # 1) Entorno de escritorio, de forma idempotente: la imagen de
        #    Ubuntu Asahi ya suele venir con escritorio, pero si el clon
        #    viene de una base servidor/mínima, lo completamos aquí.
        if dpkg -l ubuntu-desktop 2>/dev/null | grep -q '^ii'; then
            log_info "ubuntu-desktop ya está instalado, se omite."
            echo "$(t step09_ubuntu_desktop_already)"
        else
            echo "$(t step09_installing "ubuntu-desktop")"
            run_cmd "apt update" apt update
            run_cmd "ubuntu-desktop" apt-get install -y ubuntu-desktop
        fi

        # 2) SIFT Workstation (SANS), opcional: soporte arm64 oficial
        #    confirmado en Ubuntu 22.04/24.04 por el propio proyecto
        #    (teamdfir/sift-saltstack), con un aviso conocido: algunos
        #    paquetes son amd64-only y se omiten automáticamente en arm64.
        echo
        if confirm_yes_no "$(t step09_ubuntu_ask_sift)"; then
            echo "$(t step09_ubuntu_sift_notice)"
            install_cast_arm64 || {
                log_error "No se pudo instalar 'cast'. Se omite la instalación de SIFT."
                echo "$(t step09_ubuntu_cast_install_failed)"
            }
            if command -v cast >/dev/null 2>&1; then
                echo "$(t step09_ubuntu_installing_sift)"
                run_cmd "cast install sift" cast install teamdfir/sift-saltstack
                echo "$(t step09_ubuntu_sift_done)"
            fi
        else
            log_info "Instalación de SIFT omitida por el usuario."
            echo "$(t step09_ubuntu_sift_skipped)"
        fi
        ;;
    *)
        log_error "Sistema operativo desconocido: $TARGET_OS"
        exit 1
        ;;
esac

mark_os_step_done "$TARGET_OS" "$STEP_ID"
echo
echo "$(t step09_all_done "$(t "os_${TARGET_OS}_name")")"
echo "$(t step09_done_reboot)"
echo "$(t generic_rebooting)"
sleep 5
reboot
