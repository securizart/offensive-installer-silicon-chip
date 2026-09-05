#!/bin/bash
# steps/01a_network.sh
# Basado en 0a_network.sh original, con dos correcciones de seguridad:
#  1) ya no se guardan copias de la contraseña fuera de /etc (el original
#     dejaba una copia en /base_inst_kali/preparacion/).
#  2) el fichero de credenciales queda con permisos 600.
# Además usa wpa_passphrase (si está disponible) para no manipular la
# contraseña con sed, evitando problemas si contiene caracteres especiales.
STEP_ID="01a"
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${BASE_DIR}/lib/state.sh"
source "${BASE_DIR}/lib/i18n.sh"
[ -z "${IAC_LANG:-}" ] && IAC_LANG="$(i18n_detect_default_lang)"
i18n_load "$IAC_LANG"
source "${BASE_DIR}/lib/common.sh"
CURRENT_STEP_ID="$STEP_ID"
init_step_log "$STEP_ID"
require_root

echo "$(t step01a_title)"
echo "$(t step01a_intro)"
echo "$(t step01a_warn_plaintext)"
echo

nombre_wifi="$(ui_inputbox "$(t step01a_title)" "$(t step01a_ask_ssid)")"
paso_wifi="$(ui_passwordbox "$(t step01a_title)" "$(t step01a_ask_password)")"

WPA_CONF="/etc/wpa_supplicant/wpa_supplicant.conf"

if command -v wpa_passphrase >/dev/null 2>&1; then
    # wpa_passphrase escapa correctamente el SSID/passphrase por nosotros.
    wpa_passphrase "$nombre_wifi" "$paso_wifi" > "$WPA_CONF"
    # wpa_passphrase deja la passphrase en texto plano comentada; la quitamos.
    sed -i '/^\s*#psk=/d' "$WPA_CONF"
else
    {
        echo 'network={'
        printf '        ssid="%s"\n' "${nombre_wifi//\"/\\\"}"
        echo '        scan_ssid=1'
        echo '        key_mgmt=WPA-PSK'
        printf '        psk="%s"\n' "${paso_wifi//\"/\\\"}"
        echo '}'
    } > "$WPA_CONF"
fi
unset paso_wifi

chmod 600 "$WPA_CONF"
chown root:root "$WPA_CONF"
log_info "$(t step01a_perm_fixed)"
echo "$(t step01a_perm_fixed)"

echo "$(t step01a_saved)"
mark_step_done "$STEP_ID"
