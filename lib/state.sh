#!/bin/bash
# lib/state.sh
# Estado persistente del instalador: qué paso se completó, idioma elegido,
# disco destino confirmado, etc. Vive en disco para sobrevivir a los
# múltiples `reboot` que hace el proceso.
#
# Formato: fichero de líneas CLAVE=valor (shell-safe, sin espacios en clave).

STATE_DIR="/var/lib/base_inst_kali"
STATE_FILE="${STATE_DIR}/state.conf"

state_init() {
    mkdir -p "$STATE_DIR"
    [ -f "$STATE_FILE" ] || : > "$STATE_FILE"
}

# state_get CLAVE -> valor o "" si no existe.
# Nota: no encontrar la clave es un caso normal (aún no se ha llegado a ese
# paso), así que esta función siempre devuelve 0 aunque no haya match; de
# lo contrario, con `set -e` activo en common.sh, cualquier consulta de una
# clave todavía no definida abortaría el script que la llama.
state_get() {
    local key="$1"
    state_init
    grep -E "^${key}=" "$STATE_FILE" 2>/dev/null | tail -n1 | cut -d'=' -f2- || true
}

# state_set CLAVE valor
state_set() {
    local key="$1" val="$2"
    state_init
    local tmp
    tmp="$(mktemp)"
    grep -vE "^${key}=" "$STATE_FILE" > "$tmp" 2>/dev/null || true
    echo "${key}=${val}" >> "$tmp"
    mv "$tmp" "$STATE_FILE"
    chmod 600 "$STATE_FILE"
}

# --- helpers específicos de progreso de pasos -------------------------------

# mark_step_done STEP_ID
mark_step_done() {
    state_set "STEP_${1}_STATUS" "done"
    state_set "STEP_${1}_TS" "$(date '+%Y-%m-%d %H:%M:%S')"
    state_set "LAST_STEP_OK" "$1"
}

# mark_step_failed STEP_ID
mark_step_failed() {
    state_set "STEP_${1}_STATUS" "failed"
    state_set "STEP_${1}_TS" "$(date '+%Y-%m-%d %H:%M:%S')"
}

# step_status STEP_ID -> done|failed|pending
step_status() {
    local v
    v="$(state_get "STEP_${1}_STATUS")"
    echo "${v:-pending}"
}

# --- helpers "por sistema operativo" -----------------------------------
# El disco externo puede alojar VARIOS sistemas operativos (Kali, Parrot,
# ...), cada uno con sus propias particiones/estado. Estas funciones
# namespacean las claves con el id del SO (p.ej. "kali", "parrot") para
# que el progreso de uno no pise el del otro.

# os_state_get OS CLAVE
os_state_get() { state_get "OS_${1}_${2}"; }
# os_state_set OS CLAVE valor
os_state_set() { state_set "OS_${1}_${2}" "$3"; }

# mark_os_step_done OS STEP_ID
mark_os_step_done() {
    state_set "OS_${1}_STEP_${2}_STATUS" "done"
    state_set "OS_${1}_STEP_${2}_TS" "$(date '+%Y-%m-%d %H:%M:%S')"
}
# mark_os_step_failed OS STEP_ID
mark_os_step_failed() {
    state_set "OS_${1}_STEP_${2}_STATUS" "failed"
    state_set "OS_${1}_STEP_${2}_TS" "$(date '+%Y-%m-%d %H:%M:%S')"
}
# os_step_status OS STEP_ID -> done|failed|pending
os_step_status() {
    local v
    v="$(state_get "OS_${1}_STEP_${2}_STATUS")"
    echo "${v:-pending}"
}

# os_list_add OS -> añade OS a la lista de SO's con instalación empezada
# (idempotente; separador ',').
os_list_add() {
    local os="$1" current
    current="$(state_get OS_LIST)"
    case ",${current}," in
        *",${os},"*) return 0 ;;
    esac
    if [ -z "$current" ]; then
        state_set OS_LIST "$os"
    else
        state_set OS_LIST "${current},${os}"
    fi
}
# os_list_get -> lista separada por comas de SO's con instalación empezada
os_list_get() { state_get OS_LIST; }

# sync_state_to_mount /part/dest
# Copia el estado actual (del sistema en el que se ejecuta el instalador)
# al sistema de ficheros del disco externo montado en $1, para que al
# arrancar desde ese disco el instalador recuerde qué pasos ya se hicieron
# durante el clonado/chroot. Es un "best effort": si el destino no existe
# o no es escribible, avisa pero no aborta el paso que la llama.
sync_state_to_mount() {
    local mnt="$1"
    if [ -d "$mnt" ]; then
        mkdir -p "${mnt}${STATE_DIR}" 2>/dev/null || return 0
        cp -f "$STATE_FILE" "${mnt}${STATE_DIR}/state.conf" 2>/dev/null || true
    fi
}
