#!/bin/bash
# lib/ui.sh
# Capa de UI: usa whiptail si está disponible (y hay una tty real),
# y si no cae automáticamente a prompts de texto plano con read/echo.
#
# IMPORTANTE — orden de dependencias: whiptail NO viene garantizado en la
# base mínima Debian/Asahi. El paso 00 (y este propio menú) se ejecuta
# ANTES de que el paso 01 instale el resto de paquetes, así que aquí se
# hace un "bootstrap" mínimo: si falta whiptail, se intenta instalar solo
# ese paquete (no la lista completa) con lo que ya haya en
# /etc/apt/sources.list. Si no hay red o apt falla, se sigue en modo texto
# sin romper el instalador.
#
# Se debe cargar después de lib/i18n.sh (usa t()).

UI_MODE=""
UI_H=20
UI_W=70

ui_detect_mode() {
    [ -n "$UI_MODE" ] && return
    if command -v whiptail >/dev/null 2>&1 && [ -t 0 ] && [ -t 1 ]; then
        UI_MODE="whiptail"
    else
        UI_MODE="text"
    fi
}

# ui_ensure_whiptail: detecta si whiptail está disponible AHORA MISMO y fija
# UI_MODE en consecuencia. Ya NO intenta instalarlo sobre la marcha: en los
# primeros pasos (00, 01) todavía no existe en el sistema, así que ahí se
# usa el modo texto de forma natural; en cuanto el paso 01 instala el
# paquete "whiptail" junto con el resto de paquetes base, los pasos
# siguientes lo detectan solos y pasan a usar los diálogos.
ui_ensure_whiptail() {
    ui_detect_mode
    if [ "$UI_MODE" = "whiptail" ]; then
        log_info "whiptail disponible, usando menús gráficos de terminal." 2>/dev/null || true
    else
        log_info "whiptail no disponible todavía, usando modo texto plano." 2>/dev/null || true
    fi
}

# ui_msgbox "titulo" "texto"
ui_msgbox() {
    local title="$1" text="$2"
    ui_detect_mode
    if [ "$UI_MODE" = "whiptail" ]; then
        whiptail --title "$title" --msgbox "$text" "$UI_H" "$UI_W"
    else
        echo "== $title =="
        echo "$text"
        pause_enter
    fi
}

# ui_yesno "titulo" "texto" -> 0 = sí, 1 = no
ui_yesno() {
    local title="$1" text="$2"
    ui_detect_mode
    if [ "$UI_MODE" = "whiptail" ]; then
        whiptail --title "$title" --yesno "$text" "$UI_H" "$UI_W"
        return $?
    else
        local resp
        read -r -p "$text $(t prompt_yes_no) " resp
        case "$resp" in
            [Ss][Ii]|[Yy][Ee][Ss]|[Yy]) return 0 ;;
            *) return 1 ;;
        esac
    fi
}

# ui_inputbox "titulo" "texto" ["valor_por_defecto"] -> imprime el valor por stdout
ui_inputbox() {
    local title="$1" text="$2" default="${3:-}"
    ui_detect_mode
    if [ "$UI_MODE" = "whiptail" ]; then
        whiptail --title "$title" --inputbox "$text" "$UI_H" "$UI_W" "$default" 3>&1 1>&2 2>&3
    else
        local val
        read -r -p "$text " val
        echo "${val:-$default}"
    fi
}

# ui_passwordbox "titulo" "texto" -> imprime el valor por stdout (sin eco en pantalla)
ui_passwordbox() {
    local title="$1" text="$2"
    ui_detect_mode
    if [ "$UI_MODE" = "whiptail" ]; then
        whiptail --title "$title" --passwordbox "$text" "$UI_H" "$UI_W" 3>&1 1>&2 2>&3
    else
        local val
        read -r -s -p "$text " val
        echo >&2
        echo "$val"
    fi
}

# ui_menu "titulo" "texto" tag1 item1 tag2 item2 ... -> imprime el tag elegido
ui_menu() {
    local title="$1" text="$2"; shift 2
    ui_detect_mode
    if [ "$UI_MODE" = "whiptail" ]; then
        local n=$(( ($#/2) + 2 ))
        [ "$n" -gt 20 ] && n=20
        whiptail --title "$title" --menu "$text" "$UI_H" "$UI_W" "$n" "$@" 3>&1 1>&2 2>&3
    else
        echo "== $title ==" >&2
        echo "$text" >&2
        local i=1 tag item tags=()
        while [ "$#" -gt 0 ]; do
            tag="$1"; item="$2"; shift 2
            tags+=("$tag")
            printf '  %d) %-8s %s\n' "$i" "$tag" "$item" >&2
            i=$((i+1))
        done
        local choice
        read -r -p "$(t menu_prompt)" choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#tags[@]}" ]; then
            echo "${tags[$((choice-1))]}"
        else
            echo ""
        fi
    fi
}
