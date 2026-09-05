#!/bin/bash
# steps/07_fusion_grub.sh
# Basado en 6_finiquitar_fs.sh original. Se ejecuta FUERA del chroot
# (tras salir con `exit`), con el disco del SO activo todavía montado.
#
# NOTA sobre varios sistemas operativos en el mismo disco: cada vez que
# este paso se ejecuta para un SO nuevo, "update-grub" regenera el
# grub.cfg del host desde cero. Si ya habías fusionado antes la entrada
# de otro SO (p. ej. Kali) y ahora hay una copia bien formada del sistema
# en el disco (con su propio fstab), es muy probable que os-prober la
# detecte automáticamente y la vuelva a añadir (como entrada "chainload"
# genérica, no la nativa que este script construye a mano). El SO que se
# procesa AHORA sí recibe la entrada nativa completa. Comprueba el menú
# de arranque tras añadir un segundo SO para confirmar que ambas entradas
# siguen ahí.
STEP_ID="07"
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
MNT="$(os_mountpoint "$TARGET_OS")"

echo "$(t step07_title "$(t "os_${TARGET_OS}_name")")"
echo "$(t step07_intro)"
echo

if [ ! -f "${MNT}/boot/grub/grub.cfg" ]; then
    log_error "${MNT}/boot/grub/grub.cfg no existe. ¿Sigue montado ${MNT}? Repite el paso 05/06."
    exit 1
fi

if [ -f /base_inst_kali/preparacion/grub ]; then
    run_cmd "copiar grub host" cp /base_inst_kali/preparacion/grub /etc/default/grub
fi
if [ -f /base_inst_kali/preparacion/modules.txt ]; then
    run_cmd "copiar modules host" cp /base_inst_kali/preparacion/modules.txt /etc/initramfs-tools/modules
fi
run_cmd "update-initramfs host" update-initramfs -c -k all
run_cmd "update-grub host" update-grub

echo "$(t step07_merging)"
a1=$(awk '/BEGIN \/etc\/grub.d\/10_linux/{ print NR }' "${MNT}/boot/grub/grub.cfg")
b1=$(awk '/END \/etc\/grub.d\/10_linux/{ print NR }' "${MNT}/boot/grub/grub.cfg")
c1=$(awk '/END \/etc\/grub.d\/30_os-prober/{ print NR }' /boot/grub/grub.cfg)
d1=$(wc -l < /boot/grub/grub.cfg)

if [ -z "$a1" ] || [ -z "$b1" ] || [ -z "$c1" ]; then
    log_error "No se han podido localizar los marcadores esperados en grub.cfg. Revisa manualmente antes de continuar."
    exit 1
fi

a2=$((a1+1))
b2=$((b1-1))
log_info "Marcadores ($TARGET_OS): a1=$a1 b1=$b1 c1=$c1 d1=$d1 a2=$a2 b2=$b2"

MERGED="$(mktemp)"
sed -n "1,${c1}p" /boot/grub/grub.cfg > "$MERGED"
sed -n "${a2},${b2}p" "${MNT}/boot/grub/grub.cfg" >> "$MERGED"
sed -n "${c1},${d1}p" /boot/grub/grub.cfg >> "$MERGED"

BACKUP="/boot/grub/grub.orig.$(date '+%Y%m%d_%H%M%S')"
run_cmd "backup grub.cfg" cp /boot/grub/grub.cfg "$BACKUP"
echo "$(t step07_backup_orig "$BACKUP")"
mv "$MERGED" /boot/grub/grub.cfg

# El disco externo sigue montado en $MNT en este punto: aprovechamos
# para dejar ahí el estado ya actualizado antes de que el usuario
# reinicie y arranque la nueva instalación clonada.
sync_state_to_mount "$MNT"

mark_os_step_done "$TARGET_OS" "$STEP_ID"
echo
echo "$(t step07_done)"
