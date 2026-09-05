#!/bin/bash
# lib/i18n.sh
# Motor mínimo de internacionalización.
# Los textos viven en i18n/strings.<lang>.sh como entradas de un array
# asociativo STRINGS[clave]="texto con %s placeholders (formato printf)".
#
# Uso:
#   t clave arg1 arg2   -> imprime el texto traducido con printf, ya con
#                          los argumentos sustituidos.
#
# Añadir un idioma nuevo = copiar i18n/strings.es.sh, traducir los
# valores y añadir el código en i18n_available_langs().

I18N_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../i18n" && pwd)"
declare -A STRINGS=()
IAC_LANG="${IAC_LANG:-}"

i18n_available_langs() {
    # Deriva la lista de idiomas de los ficheros strings.<lang>.sh presentes,
    # así añadir un idioma nuevo no requiere tocar este fichero.
    local f lang
    for f in "$I18N_DIR"/strings.*.sh; do
        lang="$(basename "$f" .sh)"
        lang="${lang#strings.}"
        printf '%s\n' "$lang"
    done
}

i18n_detect_default_lang() {
    # 1) idioma ya guardado en el estado (si existe state.sh cargado)
    if declare -F state_get >/dev/null 2>&1; then
        local saved
        saved="$(state_get LANG_SEL 2>/dev/null || true)"
        if [ -n "$saved" ]; then
            echo "$saved"
            return
        fi
    fi
    # 2) $LANG del sistema
    case "${LANG:-}" in
        es*|ES*) echo "es"; return ;;
        en*|EN*) echo "en"; return ;;
    esac
    # 3) fallback
    echo "es"
}

# i18n_load LANG -> carga i18n/strings.LANG.sh en STRINGS[]
i18n_load() {
    local lang="$1"
    local file="${I18N_DIR}/strings.${lang}.sh"
    if [ ! -f "$file" ]; then
        echo "i18n: no existe $file, usando 'es' por defecto" >&2
        lang="es"
        file="${I18N_DIR}/strings.es.sh"
    fi
    STRINGS=()
    # shellcheck source=/dev/null
    source "$file"
    IAC_LANG="$lang"
    export IAC_LANG
}

# t clave [args...] -> traduce e interpola con printf
t() {
    local key="$1"; shift || true
    local fmt="${STRINGS[$key]:-}"
    if [ -z "$fmt" ]; then
        # Clave no encontrada: devolvemos la propia clave para que sea
        # evidente en pantalla/logs que falta traducir, en vez de fallar.
        printf '[[%s]]' "$key"
        return
    fi
    # shellcheck disable=SC2059
    printf "$fmt\n" "$@"
}

# t_raw: igual que t pero sin salto de línea final (para prompts inline)
t_raw() {
    local key="$1"; shift || true
    local fmt="${STRINGS[$key]:-}"
    if [ -z "$fmt" ]; then
        printf '[[%s]]' "$key"
        return
    fi
    # shellcheck disable=SC2059
    printf "$fmt" "$@"
}
