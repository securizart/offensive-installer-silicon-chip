#!/bin/bash
# lib/os_catalog.sh
# Catálogo de sistemas operativos "ofensivos"/destino que este instalador
# sabe clonar (y, según el caso, convertir) sobre una base ya instalada
# en el disco interno, hacia el disco externo.
#
# Añadir un sistema operativo nuevo:
#   1) añadir su id a SUPPORTED_OS
#   2) añadir OS_LABEL_CODE[id] (máx. 11 caracteres en total para la
#      etiqueta EFI resultante "EFI-<code>", límite del sistema FAT)
#   3) añadir OS_SOURCE_BASE[id]: qué base debe estar arrancada en el
#      disco interno para poder clonar hacia este SO (ver más abajo)
#   4) añadir los textos os_<id>_name / os_<id>_desc en i18n/strings.*.sh
#   5) añadir la rama correspondiente en steps/08_repositorios.sh y
#      steps/09_instalacion_paquetes.sh (repos/conversión si aplica,
#      metapaquetes)
#
# No hace falta tocar install.sh ni el resto de steps/*: son genéricos y
# usan $TARGET_OS para derivar nombres de partición/VG/mapper.

SUPPORTED_OS=(kali parrot ubuntu)

declare -A OS_LABEL_CODE=(
    [kali]="KALI"
    [parrot]="PARROT"
    [ubuntu]="UBUNTU"
)

# --- base de origen esperada por SO destino --------------------------------
# Kali y Parrot se obtienen CONVIRTIENDO una base Debian/Asahi ya clonada
# (añadiendo repos propios encima, ver steps/08 y 09). Ubuntu, en cambio,
# se clona TAL CUAL desde una instalación de Ubuntu/Asahi genuina y
# separada en el disco interno — no hay conversión posible ni con
# sentido: Parrot y Kali son oficialmente distribuciones basadas en
# Debian, no en Ubuntu, así que "convertir desde Ubuntu" no está
# soportado y no se contempla aquí.
declare -A OS_SOURCE_BASE=(
    [kali]="debian"
    [parrot]="debian"
    [ubuntu]="ubuntu"
)

# Mapeo del campo ID= de /etc/os-release del sistema arrancado a nuestro
# id interno de "base de origen". Ampliar aquí si se añade un SO destino
# con una base de origen distinta a debian/ubuntu.
declare -A OS_RELEASE_ID_TO_BASE=(
    [debian]="debian"
    [ubuntu]="ubuntu"
)

# os_partition_label PREFIJO OS -> etiqueta corta y válida para el
# sistema de ficheros correspondiente (FAT: máx. 11 caracteres).
os_efi_label()  { echo "EFI-${OS_LABEL_CODE[$1]}"; }
os_boot_label() { echo "boot_${1}"; }
os_root_label() { echo "rootfs_${1}"; }
os_vg_name()    { echo "vg${1}"; }
os_crypt_name() { echo "${1}_root_crypt"; }
os_mountpoint() { echo "/part/dest_${1}"; }

# os_source_base OS -> id de la base de origen esperada (debian|ubuntu)
os_source_base() { echo "${OS_SOURCE_BASE[$1]:-}"; }

# verify_source_base OS
# Comprueba que el sistema ACTUALMENTE ARRANCADO en el disco interno es
# la base de origen esperada para clonar hacia $OS. Es una comprobación
# BLOQUEANTE a propósito: si no coincide, para en seco con un mensaje
# claro en vez de continuar y clonar el sistema equivocado hacia
# particiones ya destructivas. Ver docs/es/ARQUITECTURA.md para el
# razonamiento completo.
#
# Requiere lib/common.sh (log_*, t) y lib/i18n.sh ya cargados.
verify_source_base() {
    local target_os="$1"
    local expected_base actual_id actual_base

    expected_base="$(os_source_base "$target_os")"
    if [ -z "$expected_base" ]; then
        log_warn "No hay base de origen definida para '$target_os' en OS_SOURCE_BASE; se omite la verificación."
        return 0
    fi

    if [ ! -r /etc/os-release ]; then
        log_error "No se puede leer /etc/os-release para verificar la base de origen arrancada."
        echo "$(t source_base_cannot_detect)"
        exit 1
    fi

    # Se sourcea en un subshell aislado (set +u local) para no arrastrar
    # variables de /etc/os-release al script que llama, y para no romper
    # con `set -u` si el fichero no define alguna clave.
    actual_id="$(set +u; . /etc/os-release; echo "${ID:-}")"
    actual_base="${OS_RELEASE_ID_TO_BASE[$actual_id]:-}"

    if [ "$actual_base" != "$expected_base" ]; then
        log_error "Base de origen incorrecta para '$target_os': se esperaba '$expected_base', detectado ID='${actual_id:-vacío}' (base resuelta: '${actual_base:-ninguna}')."
        echo
        echo "$(t source_base_mismatch \
            "$(t "os_${target_os}_name")" \
            "$(t "source_base_${expected_base}_name")" \
            "${actual_id:-desconocido}")"
        exit 1
    fi

    log_info "Base de origen verificada para '$target_os': $actual_base (ID=$actual_id) — OK."
}
