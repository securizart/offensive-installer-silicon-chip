#!/bin/bash
# lib/os_catalog.sh
# Catálogo de sistemas operativos "ofensivos" que este instalador sabe
# clonar/convertir sobre la base Debian/Asahi, en el disco externo.
#
# Añadir un sistema operativo nuevo:
#   1) añadir su id a SUPPORTED_OS
#   2) añadir OS_LABEL_CODE[id] (3-4 letras MAYÚSCULAS, para las etiquetas
#      de partición FAT, que tienen un límite de 11 caracteres)
#   3) añadir los textos os_<id>_name / os_<id>_desc en i18n/strings.*.sh
#   4) añadir la rama correspondiente en steps/08_repositorios.sh y
#      steps/09_instalacion_paquetes.sh (repos, claves, metapaquetes)
#
# No hace falta tocar install.sh ni el resto de steps/*: son genéricos y
# usan $TARGET_OS para derivar nombres de partición/VG/mapper.

SUPPORTED_OS=(kali parrot)

declare -A OS_LABEL_CODE=(
    [kali]="KALI"
    [parrot]="PARROT"
)

# os_partition_label PREFIJO OS -> etiqueta corta y válida para el
# sistema de ficheros correspondiente (FAT: máx. 11 caracteres).
os_efi_label()  { echo "EFI-${OS_LABEL_CODE[$1]}"; }
os_boot_label() { echo "boot_${1}"; }
os_root_label() { echo "rootfs_${1}"; }
os_vg_name()    { echo "vg${1}"; }
os_crypt_name() { echo "${1}_root_crypt"; }
os_mountpoint() { echo "/part/dest_${1}"; }
