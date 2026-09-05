# Changelog

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/).
Todas las fechas en AAAA-MM-DD.

## [Unreleased]

## [0.3.0] — soporte multi-SO (Parrot OS)
### Added
- `lib/os_catalog.sh`: catálogo de sistemas operativos soportados
  (`kali`, `parrot`), con derivación automática de etiquetas de
  partición, grupo LVM, nombre del mapper LUKS y punto de montaje por SO.
- Soporte para **Parrot OS** como segundo sistema operativo instalable
  en el mismo disco externo (repositorio oficial `deb.parrot.sh`,
  metapaquetes `parrot-core`/`parrot-tools-full`).
- Progreso namespaceado por sistema operativo (`os_state_*`,
  `mark_os_step_done`, `os_step_status`) para que Kali y Parrot lleven
  contadores de pasos independientes.
- Cálculo automático de números de partición libres por SO, para que un
  segundo sistema operativo no pise las particiones del primero en el
  mismo disco.
- Menú principal dividido en pasos "de host" (00, 01, 01a — una sola
  vez) y "por sistema operativo" (02-09 — repetibles), con selector de
  "sistema operativo activo".
- Documentación bilingüe ampliada: `docs/{es,en}/SISTEMAS_OPERATIVOS.md`
  / `OPERATING_SYSTEMS.md`, y actualización del resto de documentos para
  reflejar el diseño multi-SO.
- Ficheros de repositorio: `CHANGELOG.md`, `CONTRIBUTING.md`, `LICENSE`.
### Changed
- La creación del usuario `iac` y del fichero `sudoers` se movió del
  antiguo paso 02 (particionado) al paso 01 (preparación de host), por
  ser una acción de una sola vez, no por sistema operativo.
- `steps/02_particiones.sh` a `07_fusion_grub.sh` reescritos para operar
  sobre el sistema operativo activo (`$TARGET_OS`), no sobre un disco
  con partición fija `1/2/3`.
- `09_instalacion_kali.sh` renombrado a `09_instalacion_paquetes.sh` y
  generalizado por SO.

## [0.2.0] — whiptail
### Added
- `lib/ui.sh`: capa de UI (`ui_msgbox`, `ui_yesno`, `ui_inputbox`,
  `ui_passwordbox`, `ui_menu`) con `whiptail` cuando está disponible y
  fallback a texto plano (`read`/`echo`) en caso contrario.
- `whiptail` añadido a la lista de paquetes base del paso 01.
### Changed
- Menú principal, selector de idioma, selección de disco destino (paso
  00) y credenciales WiFi (paso 01a) migrados a la capa de UI.
### Fixed
- Bug en el fallback de texto de `ui_menu`: la cabecera/listado se
  colaba en el valor devuelto por `$(...)`, al no separar salida visual
  (stderr) de valor de retorno (stdout).

## [0.1.0] — versión inicial del framework
### Added
- `install.sh`: menú principal con progreso persistente
  (`✓ hecho`/`▶ siguiente`/`bloqueado`/`✖ falló, reintentar`).
- `lib/common.sh`, `lib/i18n.sh`, `lib/state.sh`: núcleo de logging,
  control de errores (`set -e -u -o pipefail` + `trap ERR`), i18n
  (castellano/inglés) y persistencia de estado entre reinicios.
- Refactor 1:1 de los 10 scripts originales
  (`0_preparacion.sh` … `8_red_e_instala.sh`) a `steps/00`…`09`, con
  logging por paso y confirmaciones destructivas explícitas.
- Nuevo paso `00_check_prerreq.sh`: comprobación de arquitectura arm64,
  aviso si no se detecta la base Asahi/Debian, y selección validada del
  disco externo (evita elegir por error el NVMe interno).
- Corrección de seguridad: la contraseña WiFi deja de guardarse fuera de
  `/etc`, y el fichero de credenciales queda con permisos `600`.
