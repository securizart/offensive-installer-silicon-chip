#!/bin/bash
# install.sh — Menú principal / Main menu
#
# Punto de entrada único. Sobrevive a los reboots del proceso: si se añade
# a .bashrc de root (ver docs/), se reabre solo tras cada reinicio y
# muestra en qué paso te quedaste.
#
# El disco externo puede alojar VARIOS sistemas operativos (Kali, Parrot,
# ...). Por eso los pasos se dividen en dos grupos:
#   - HOST_STEPS (00, 01, 01a): se hacen UNA VEZ, no dependen de qué SO
#     vayas a clonar después.
#   - OS_STEPS (02..09): se repiten POR CADA sistema operativo que
#     instales en el disco. Su progreso se guarda por separado para cada
#     uno (ver lib/state.sh, funciones os_*).

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/state.sh
source "${BASE_DIR}/lib/state.sh"
# shellcheck source=lib/os_catalog.sh
source "${BASE_DIR}/lib/os_catalog.sh"
# shellcheck source=lib/i18n.sh
source "${BASE_DIR}/lib/i18n.sh"

state_init
IAC_LANG="$(i18n_detect_default_lang)"
i18n_load "$IAC_LANG"

# shellcheck source=lib/common.sh
source "${BASE_DIR}/lib/common.sh"

# ---------------------------------------------------------------------------
# Definición ordenada de los pasos
# ---------------------------------------------------------------------------
HOST_STEPS=(00 01 01a)
OS_STEPS=(02 03 04 05 06 07 08 09)

declare -A STEP_FILE=(
    [00]="steps/00_check_prerreq.sh"
    [01]="steps/01_preparacion.sh"
    [01a]="steps/01a_network.sh"
    [02]="steps/02_particiones.sh"
    [03]="steps/03_formateo.sh"
    [04]="steps/04_clonado.sh"
    [05]="steps/05_chroot_prep.sh"
    [06]="steps/06_grub_finiquitar.sh"
    [07]="steps/07_fusion_grub.sh"
    [08]="steps/08_repositorios.sh"
    [09]="steps/09_instalacion_paquetes.sh"
)
declare -A STEP_TITLE_KEY=(
    [00]="step00_title" [01]="step01_title" [01a]="step01a_title"
    [02]="step02_title_short" [03]="step03_title_short" [04]="step04_title_short"
    [05]="step05_title_short" [06]="step06_title_short" [07]="step07_title_short"
    [08]="step08_title_short" [09]="step09_title_short"
)
# Pasos OS que NO requieren que el anterior esté "done" para ejecutarse
# sin aviso (06 se ejecuta manualmente dentro del chroot abierto por 05,
# así que su marca de progreso no llega al estado que ve el host).
NO_GATE_STEPS=("06")

is_no_gate() {
    local id="$1" x
    for x in "${NO_GATE_STEPS[@]}"; do [ "$x" = "$id" ] && return 0; done
    return 1
}

# --- estado de pasos de host (00/01/01a), progreso global -------------------
compute_host_status_label() {
    local id="$1" idx="$2"
    local st
    st="$(step_status "$id")"
    if [ "$st" = "done" ]; then t menu_status_done; return; fi
    if [ "$st" = "failed" ]; then t menu_status_failed; return; fi
    local i prev_all_done=1
    for ((i=0; i<idx; i++)); do
        [ "$(step_status "${HOST_STEPS[$i]}")" != "done" ] && { prev_all_done=0; break; }
    done
    [ "$prev_all_done" -eq 1 ] && t menu_status_next || t menu_status_locked
}

# --- estado de pasos por SO (02..09), progreso namespaceado -----------------
compute_os_status_label() {
    local os="$1" id="$2" idx="$3"
    local st
    st="$(os_step_status "$os" "$id")"
    if [ "$st" = "done" ]; then t menu_status_done; return; fi
    if [ "$st" = "failed" ]; then t menu_status_failed; return; fi
    if is_no_gate "$id"; then t menu_status_pending; return; fi
    local i prev_all_done=1
    for ((i=0; i<idx; i++)); do
        local prev_id="${OS_STEPS[$i]}"
        is_no_gate "$prev_id" && continue
        [ "$(os_step_status "$os" "$prev_id")" != "done" ] && { prev_all_done=0; break; }
    done
    [ "$prev_all_done" -eq 1 ] && t menu_status_next || t menu_status_locked
}

os_progress_summary() {
    # "3/8 pasos" para el SO $1
    local os="$1" done_count=0 id
    for id in "${OS_STEPS[@]}"; do
        [ "$(os_step_status "$os" "$id")" = "done" ] && done_count=$((done_count+1))
    done
    echo "${done_count}/${#OS_STEPS[@]}"
}

print_header_text() {
    local disk active_os
    disk="$(state_get TARGET_DISK)"
    active_os="$(state_get ACTIVE_OS)"
    local header="$(t menu_title)
$(t menu_current_lang "${STRINGS[lang_name]}")"
    if [ -n "$disk" ]; then
        header="${header}
$(t menu_current_disk "$disk")"
    else
        header="${header}
$(t menu_current_disk_unset)"
    fi
    if [ -n "$active_os" ]; then
        header="${header}
$(t menu_active_os "$(t "os_${active_os}_name") ($(os_progress_summary "$active_os"))")"
    else
        header="${header}
$(t menu_active_os_unset)"
    fi
    echo "$header"
}

build_menu_args() {
    # Rellena el array global MENU_ARGS con pares tag/item para ui_menu.
    MENU_ARGS=()
    local i id
    for ((i=0; i<${#HOST_STEPS[@]}; i++)); do
        id="${HOST_STEPS[$i]}"
        MENU_ARGS+=("$id" "$(t "${STEP_TITLE_KEY[$id]}") [$(compute_host_status_label "$id" "$i")]")
    done

    MENU_ARGS+=("OS" "$(t menu_option_os)")

    local active_os
    active_os="$(state_get ACTIVE_OS)"
    if [ -n "$active_os" ]; then
        for ((i=0; i<${#OS_STEPS[@]}; i++)); do
            id="${OS_STEPS[$i]}"
            MENU_ARGS+=("$id" "$(t "${STEP_TITLE_KEY[$id]}") [$(compute_os_status_label "$active_os" "$id" "$i")]")
        done
    fi

    MENU_ARGS+=("LANG" "$(t menu_option_lang)")
    MENU_ARGS+=("LOGS" "$(t menu_option_logs)")
    MENU_ARGS+=("EXIT" "$(t menu_option_exit)")
}

switch_language() {
    local choice
    choice="$(ui_menu "$(t menu_title)" "$(t menu_choose_lang_prompt)" \
        es "Castellano" en "English")"
    case "$choice" in
        es|en) i18n_load "$choice" ;;
        *) return ;;
    esac
    state_set LANG_SEL "$IAC_LANG"
    ui_msgbox "$(t menu_title)" "$(t menu_lang_set "${STRINGS[lang_name]}")"
}

manage_os() {
    # Menú para elegir/crear el "sistema operativo activo". Cada entrada
    # muestra su progreso si ya se había empezado.
    local args=() os label
    for os in "${SUPPORTED_OS[@]}"; do
        label="$(t "os_${os}_name")"
        if [[ ",$(os_list_get)," == *",${os},"* ]]; then
            label="${label} ($(os_progress_summary "$os"))"
        else
            label="${label} — $(t menu_os_not_started)"
        fi
        args+=("$os" "$label")
    done
    local choice
    choice="$(ui_menu "$(t menu_os_title)" "$(t menu_os_prompt)" "${args[@]}")"
    case "$choice" in
        "") return ;;
        *)
            state_set ACTIVE_OS "$choice"
            ui_msgbox "$(t menu_os_title)" "$(t menu_os_switched "$(t "os_${choice}_name")")"
            ;;
    esac
}

run_step() {
    local id="$1"
    local file="${BASE_DIR}/${STEP_FILE[$id]}"
    if [ ! -f "$file" ]; then
        echo "[$id] script no encontrado: $file" >&2
        pause_enter
        return
    fi
    CURRENT_STEP_ID="$id" IAC_LANG="$IAC_LANG" bash "$file"
    local rc=$?
    if [ $rc -ne 0 ]; then
        echo
        echo "$(t step_failed_console "$id")"
        pause_enter
    fi
}

main_menu_loop() {
    local choice
    while true; do
        clear
        build_menu_args
        choice="$(ui_menu "$(t menu_title)" "$(print_header_text)" "${MENU_ARGS[@]}")"
        case "$choice" in
            "") echo "$(t menu_exit_bye)"; break ;;
            OS) manage_os ;;
            LANG) switch_language ;;
            LOGS) ui_msgbox "$(t menu_title)" "$(t menu_logs_path "$LOG_DIR")" ;;
            EXIT) echo "$(t menu_exit_bye)"; break ;;
            *)
                if [ -z "$(state_get ACTIVE_OS)" ]; then
                    local is_os_step=0 sid
                    for sid in "${OS_STEPS[@]}"; do [ "$sid" = "$choice" ] && is_os_step=1; done
                    if [ "$is_os_step" -eq 1 ]; then
                        ui_msgbox "$(t menu_title)" "$(t menu_os_required_first)"
                        continue
                    fi
                fi
                run_step "$choice"
                ;;
        esac
    done
}

main_menu_loop
