# Changelog

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/).
Todas las fechas en AAAA-MM-DD.

## [Unreleased]
### Planned
- Cobertura explícita de "distros forenses" como eje de la próxima
  versión (no solo herramientas sueltas sobre Ubuntu): rematar la
  investigación de REMnux y evaluar otras distros de referencia
  (Tsurugi Linux, DEFT/DEFT Zero) con la misma metodología de
  comprobación real de arm64, documentando un veredicto explícito para
  cada una en `docs/{es,en}/SISTEMAS_OPERATIVOS.md`/
  `OPERATING_SYSTEMS.md`. Anotado en la hoja de ruta de ambos README.

## [0.4.0] — Ubuntu como tercer sistema operativo (sin conversión)
### Changed
- Veredicto de REMnux suavizado de "descartado" a "en duda, investigación
  abierta": comparación directa de `.sls` (SaltStack) con los de SIFT
  reveló que el mecanismo central de REMnux (repo vía PPA de Launchpad,
  `cast.sls` ya arm64-aware) no tiene el mismo bug estructural que tenía
  SIFT antes de su soporte arm64 oficial, aunque persiste un riesgo de
  categoría distinta (herramientas dependientes de Wine, binarios de
  terceros solo-amd64 como PolarProxy). Añadido a la hoja de ruta de
  ambos README como investigación planeada para una próxima versión
  (`cast install --mode=addon` con subconjunto sin Wine). Documentado
  con detalle en `docs/{es,en}/SISTEMAS_OPERATIVOS.md`/
  `OPERATING_SYSTEMS.md`.
### Added
- `ubuntu` añadido a `SUPPORTED_OS` (`lib/os_catalog.sh`): a diferencia
  de Kali/Parrot, no se convierte, se **clona tal cual** desde una
  instalación de Ubuntu/Asahi genuina y separada en el disco interno.
- Nuevo mapeo `OS_SOURCE_BASE` y función **bloqueante**
  `verify_source_base "$TARGET_OS"`: comprueba, leyendo
  `/etc/os-release`, que el sistema arrancado coincide con la base que
  necesita el SO activo (Debian/Asahi para Kali/Parrot, Ubuntu/Asahi
  para Ubuntu) antes de particionar (02), formatear (03) y clonar (04).
- `steps/08_repositorios.sh`, rama `ubuntu)`: sin repos que añadir, solo
  `apt update && apt full-upgrade`.
- `steps/09_instalacion_paquetes.sh`, rama `ubuntu)`: instalación
  idempotente de `ubuntu-desktop`, y instalación **opcional**
  (confirmación explícita) de **SIFT Workstation (SANS)** — soporte
  arm64 oficial confirmado en Ubuntu 22.04/24.04 directamente por el
  proyecto `teamdfir/sift-saltstack`.
- `lib/common.sh`, función `install_cast_arm64`: descarga e instala la
  última versión de `cast` (ekristen/cast, instalador de SIFT) para
  arm64, resolviendo la versión sin hardcodearla y sin usar la API de
  GitHub (límite de peticiones/hora), siguiendo en su lugar la
  redirección de `.../releases/latest`. Probado de extremo a extremo
  (descarga real verificada, arquitectura del `.deb` confirmada).
- Documentación (`docs/{es,en}/SISTEMAS_OPERATIVOS.md`/
  `OPERATING_SYSTEMS.md`, `ARQUITECTURA.md`/`ARCHITECTURE.md`,
  `TROUBLESHOOTING.md`): veredicto final de las tres herramientas
  forenses investigadas para Ubuntu — SIFT integrado (arm64 oficial),
  REMnux descartado (sin soporte ARM según su propia documentación,
  confirmado en vivo), CAINE descartado (no es un modelo de repositorio
  convertible). Añadido también el método general para comprobar
  disponibilidad de un paquete en arm64 (`apt-cache policy`, `rmadison`,
  búsquedas por arquitectura en Debian/Ubuntu/Launchpad).
- Requisito de base de origen actualizado en ambos README y en la guía
  de uso: ahora depende del sistema destino (Debian/Asahi para
  Kali/Parrot, Ubuntu Asahi para Ubuntu).
### Changed
- Hoja de ruta de ambos README actualizada: Ubuntu pasa de "planeado"
  a "implementado".

## [Unreleased]
### Added
- `README.en.md` y `CONTRIBUTING.en.md`: versión en inglés de los dos
  ficheros de nivel raíz (antes solo estaban en castellano, a pesar de
  que `docs/` ya era bilingüe). Enlaces cruzados entre idiomas añadidos
  en `README.md` y `CONTRIBUTING.md`.
- Documentado el workaround de firmware/u-boot cuando no detecta el
  disco externo al arrancar (`env set boot_efi_mgr` + `run
  bootcmd_usb0`), en `docs/{es,en}/TROUBLESHOOTING.md`, con referencia
  cruzada desde la guía de uso.
- Tabla de compatibilidad actualizada: MacBook Air M1 y M2 confirmados
  como probados (Kali y Parrot), en ambos README.
- Sección "Demo en vídeo" completada con el enlace real
  (<https://youtu.be/JsPsCAa4XBU>) y miniatura clicable en ambos README.
- Sección "Hoja de ruta" añadida a ambos README y nota correspondiente
  en `docs/{es,en}/SISTEMAS_OPERATIVOS.md`/`OPERATING_SYSTEMS.md`:
  Ubuntu como tercer sistema operativo planeado (segunda versión del
  instalador), con el objetivo de mejorar la integración de Parrot OS.
  Todavía no implementado.
- Advertencias reforzadas en ambos README y en la guía de uso
  (`GUIA_USO.md`/`USAGE.md`): se exige conocimiento profundo de
  administración de sistemas Linux (no apto para principiantes), se
  insta a comprobar la compatibilidad de versión entre la base
  Debian/Asahi y la distro elegida (Kali/Parrot) antes de los pasos
  08-09, y se recomienda hacer tantas copias de seguridad del macOS
  como sean necesarias, verificadas antes de empezar.

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
