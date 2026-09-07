#!/bin/bash
# lib/common.sh
# Núcleo común: logging, control de errores, helpers de confirmación.
# Se debe cargar SIEMPRE después de lib/i18n.sh (usa t()) y lib/state.sh.

set -u
set -o pipefail

# ---------------------------------------------------------------------------
# Rutas base
# ---------------------------------------------------------------------------
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="${BASE_DIR}/logs"
MASTER_LOG="${LOG_DIR}/install.log"
mkdir -p "$LOG_DIR"

# ---------------------------------------------------------------------------
# UI (whiptail con fallback a texto). Se hace bootstrap aquí: si falta
# whiptail se intenta instalar en este mismo momento (ver lib/ui.sh), antes
# de que el resto del paso necesite pedir nada al usuario.
# ---------------------------------------------------------------------------
# shellcheck source=ui.sh
source "${BASE_DIR}/lib/ui.sh"
ui_ensure_whiptail

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
# _ts: timestamp legible
_ts() { date '+%Y-%m-%d %H:%M:%S'; }

# log_line LEVEL "mensaje"  -> escribe en el log maestro
log_line() {
    local level="$1"; shift
    printf '[%s] [%s] %s\n' "$(_ts)" "$level" "$*" >> "$MASTER_LOG"
}

log_info()  { log_line "INFO"  "$*"; }
log_warn()  { log_line "WARN"  "$*"; echo "⚠ $*" >&2; }
log_error() { log_line "ERROR" "$*"; echo "✖ $*" >&2; }
log_ok()    { log_line "OK"    "$*"; }

# init_step_log STEP_ID -> crea/asigna el log individual del paso y
# redirige toda la salida (stdout+stderr) también a ese fichero, sin
# perder la interactividad del terminal (usa tee).
STEP_LOG=""
init_step_log() {
    local step_id="$1"
    local stamp
    stamp="$(date '+%Y%m%d_%H%M%S')"
    STEP_LOG="${LOG_DIR}/paso_${step_id}_${stamp}.log"
    : > "$STEP_LOG"
    # Duplicamos toda la salida del paso a su log individual,
    # manteniendo la consola visible para el usuario.
    exec > >(tee -a "$STEP_LOG") 2> >(tee -a "$STEP_LOG" >&2)
    log_info "$(t log_step_start "$step_id" "$STEP_LOG")"
}

# ---------------------------------------------------------------------------
# Control de errores
# ---------------------------------------------------------------------------
CURRENT_STEP_ID="${CURRENT_STEP_ID:-desconocido}"

on_error() {
    local exit_code=$?
    local line_no=$1
    log_error "$(t log_step_failed "$CURRENT_STEP_ID" "$line_no" "$exit_code")"
    mark_step_failed "$CURRENT_STEP_ID" 2>/dev/null || true
    echo
    echo "$(t step_failed_console "$CURRENT_STEP_ID")"
    echo "$(t log_saved_at "$STEP_LOG")"
    exit "$exit_code"
}
trap 'on_error $LINENO' ERR

# run_cmd "descripcion" cmd arg1 arg2...
# Ejecuta un comando, lo registra en el log (comando + resultado) y
# propaga el fallo a través de `set -e`/trap ERR.
run_cmd() {
    local desc="$1"; shift
    log_info "$(t log_running "$desc" "$*")"
    "$@"
    local rc=$?
    if [ $rc -eq 0 ]; then
        log_ok "$(t log_ok_cmd "$desc")"
    fi
    return $rc
}

# ---------------------------------------------------------------------------
# Comprobaciones básicas
# ---------------------------------------------------------------------------
require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "$(t err_root_required)" >&2
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# Interacción con el usuario
# ---------------------------------------------------------------------------
# confirm "pregunta_i18n_key" [args...]
# Devuelve 0 si el usuario confirma, 1 si no. En modo whiptail muestra un
# diálogo sí/no; en modo texto no acepta 'y/n' de un solo caracter mal
# tecleado (ver ui_yesno).
confirm_yes_no() {
    ui_yesno "$(t confirm_title)" "$1"
}

# confirm_destructive DISK_OR_TARGET
# Para pasos irreversibles (particionar, formatear, luksFormat...).
# Obliga a teclear literalmente la palabra de confirmación, tanto en modo
# whiptail (inputbox) como en modo texto.
confirm_destructive() {
    local target="$1"
    local word resp
    word="$(t confirm_word)"
    log_warn "$(t warn_destructive "$target")"
    resp="$(ui_inputbox "$(t confirm_title)" "$(t warn_destructive "$target")
$(t type_to_confirm "$word")" "")"
    if [ "$resp" != "$word" ]; then
        log_warn "$(t log_aborted_by_user "$CURRENT_STEP_ID")"
        ui_msgbox "$(t confirm_title)" "$(t aborted_by_user)"
        exit 1
    fi
}

pause_enter() {
    read -r -p "$(t press_enter_continue)" _
}

# ---------------------------------------------------------------------------
# Instaladores de utilidades externas puntuales
# ---------------------------------------------------------------------------

# install_cast_arm64
# Descarga e instala la última versión de "cast" (ekristen/cast, el
# instalador de SIFT/REMnux basado en SaltStack) para arm64.
#
# Resuelve la versión SIN hardcodearla y SIN usar la API de GitHub (que
# tiene un límite de peticiones/hora fácil de agotar): sigue la
# redirección de .../releases/latest, cuya URL final ya contiene el tag
# de la última versión (p. ej. .../releases/tag/v1.0.32). Verificado a
# mano: es el mismo patrón que usa el propio proyecto REMnux para
# resolver su binario de cast.
#
# Devuelve 0 si "cast" queda instalado y disponible en PATH, 1 en caso
# de fallo (sin abortar el script llamador gracias a `set -e`: se debe
# invocar como `install_cast_arm64 || ...`).
install_cast_arm64() {
    local ver url tmp
    ver="$(curl -fsSL -o /dev/null -w '%{url_effective}' \
        https://github.com/ekristen/cast/releases/latest 2>/dev/null \
        | sed 's#.*/tag/##' || true)"
    if [ -z "$ver" ]; then
        log_error "No se ha podido resolver la última versión de cast (ekristen/cast)."
        return 1
    fi
    url="https://github.com/ekristen/cast/releases/download/${ver}/cast-${ver}-linux-arm64.deb"
    tmp="$(mktemp --suffix=.deb)"
    log_info "Descargando cast ${ver} (arm64) desde $url"
    if ! curl -fsSL -o "$tmp" "$url"; then
        log_error "Fallo al descargar $url"
        rm -f "$tmp"
        return 1
    fi
    if ! dpkg -i "$tmp" >>"$MASTER_LOG" 2>&1; then
        apt-get install -f -y >>"$MASTER_LOG" 2>&1 || true
    fi
    rm -f "$tmp"
    if command -v cast >/dev/null 2>&1; then
        log_ok "cast ${ver} instalado correctamente."
        return 0
    else
        log_error "cast no quedó disponible en PATH tras el intento de instalación."
        return 1
    fi
}
