# Offensive Installer Silicon Chip (base_inst_kali)

**[Read this in English → README.en.md](README.en.md)**

Instalador con menú, multiidioma (ES/EN) y soporte para **varios
sistemas operativos ofensivos** (Kali Linux, Parrot Security OS) en un
disco externo USB con particiones cifradas, clonados a partir de una
base **Debian/Asahi** ya instalada en un MacBook Air/Pro Apple Silicon
(M1/M2). El `/boot` (EFI + kernel) se mantiene en el disco interno del
Mac; el sistema de ficheros raíz vive en el disco externo.

```
Debian/Asahi (NVMe interno, ya instalado) ──clona──▶ disco externo USB
                                                       ├── Kali Linux (particiones propias)
                                                       └── Parrot Security OS (particiones propias)
```

> ⚠️ **Estado del proyecto:** en desarrollo activo. Los scripts son
> funcionales pero no están pensados para un uso "a ciegas". Lee la
> sección de riesgos antes de ejecutar nada.

## Requisito indispensable antes de usar esto

**El MacBook debe tener ya instalado y actualizado el sistema operativo
base Asahi Linux / Debian** en su disco interno (NVMe), antes de
ejecutar nada de este repositorio. Este proyecto **no instala macOS ni
Asahi/Debian**: parte de que esa base ya existe y funciona, y clona ese
sistema en marcha hacia un disco externo para convertirlo en Kali y/o
Parrot.

Sigue la guía oficial si todavía no la tienes:
<https://wiki.debian.org/InstallingDebianOn/Apple/M1> (proyecto Bananas
de Debian, basado en el trabajo de Asahi Linux). El paso `00` de este
instalador comprueba indicios de esa instalación (arquitectura arm64,
paquetes `asahi-*`) y te avisa si no los encuentra, pero la
responsabilidad de tener esa base lista y actualizada es previa a usar
este repositorio.

## Qué hace este proyecto

Automatiza y encadena un flujo que hoy exige combinar varias guías
sueltas y bastante prueba-error manual:

- Comprueba los prerrequisitos y particiona, cifra (LUKS) y formatea un
  **disco externo USB**.
- **Clona** el sistema Debian/Asahi en marcha a ese disco externo.
- Añade los repositorios y metapaquetes de **Kali Linux** y/o **Parrot
  Security OS** sobre esa base clonada, usando los mecanismos oficiales
  de cada distribución, convirtiéndola en una distribución de pentesting
  completa arrancable desde el menú de GRUB junto al sistema original.
- Permite instalar **más de un sistema ofensivo en el mismo disco
  externo**, cada uno en sus propias particiones, sin pisar los datos de
  los demás.
- Todo ello guiado por un **menú único** (`install.sh`) con progreso
  persistente (sobrevive a los múltiples reinicios que exige el
  proceso), **logging** por paso, y textos en **castellano e inglés**.

## Requisitos

- MacBook con chip Apple M1 o M2, con Asahi Linux/Debian ya instalado y
  actualizado (ver arriba).
- Disco duro/SSD externo con espacio suficiente (se recomiendan 60 GB o
  más por cada sistema operativo que instales).
- Conexión a internet estable durante todo el proceso.
- Copia de seguridad completa de tus datos antes de empezar (ver Riesgos).
- Conocimientos básicos de línea de comandos y particionado de discos.

## ⚠️ Riesgos y advertencias

- Este proceso modifica el particionado y el firmware de arranque del
  disco externo, y añade entradas al `grub.cfg` del sistema interno. Un
  fallo durante estos pasos puede impedir temporal o permanentemente que
  el sistema arranque correctamente.
- Todavía no hay un desinstalador automático. Revertir los cambios exige
  edición manual de particiones.
- Usa este proyecto bajo tu propia responsabilidad. Recomendado solo en
  máquinas de prueba o con una copia de seguridad completa y verificada.

## Empezar

```bash
git clone https://github.com/securizart/offensive-installer-silicon-chip.git
cd offensive-installer-silicon-chip
sudo bash install.sh
```

Documentación completa (arquitectura, guía de uso paso a paso, gestión
de varios sistemas operativos, resolución de problemas):

| Documento | Castellano | English |
|---|---|---|
| Arquitectura | [docs/es/ARQUITECTURA.md](docs/es/ARQUITECTURA.md) | [docs/en/ARCHITECTURE.md](docs/en/ARCHITECTURE.md) |
| Guía de uso | [docs/es/GUIA_USO.md](docs/es/GUIA_USO.md) | [docs/en/USAGE.md](docs/en/USAGE.md) |
| Varios sistemas operativos | [docs/es/SISTEMAS_OPERATIVOS.md](docs/es/SISTEMAS_OPERATIVOS.md) | [docs/en/OPERATING_SYSTEMS.md](docs/en/OPERATING_SYSTEMS.md) |
| Resolución de problemas | [docs/es/TROUBLESHOOTING.md](docs/es/TROUBLESHOOTING.md) | [docs/en/TROUBLESHOOTING.md](docs/en/TROUBLESHOOTING.md) |

Otros ficheros del repositorio: [CHANGELOG.md](CHANGELOG.md) ·
[CONTRIBUTING.md](CONTRIBUTING.md) ([English](CONTRIBUTING.en.md)) ·
[LICENSE](LICENSE)

## Estructura del repositorio

```
install.sh          menú principal (ejecutar siempre desde aquí)
lib/
  common.sh           logging, set -e/trap, confirmaciones destructivas
  i18n.sh             motor de traducción: t clave arg1 arg2...
  ui.sh               whiptail con fallback a texto plano
  state.sh            progreso persistente (global y por SO)
  os_catalog.sh        catálogo de sistemas operativos soportados
i18n/
  strings.es.sh        textos en castellano
  strings.en.sh        textos en inglés
steps/
  00_check_prerreq.sh          host, una vez: prerrequisitos + disco
  01_preparacion.sh            host, una vez: paquetes base + usuario
  01a_network.sh               host, una vez: WiFi
  02_particiones.sh            por SO: particionar
  03_formateo.sh                por SO: LUKS + LVM + mkfs
  04_clonado.sh                 por SO: clonar el sistema actual
  05_chroot_prep.sh             por SO: montar + chroot
  06_grub_finiquitar.sh         por SO: GRUB (dentro del chroot)
  07_fusion_grub.sh             por SO: fusionar grub.cfg
  08_repositorios.sh            por SO: repos de Kali o Parrot
  09_instalacion_paquetes.sh    por SO: metapaquetes de Kali o Parrot
logs/
  install.log                  log maestro
  paso_<id>_<fecha>.log        log detallado de cada ejecución
docs/
  es/, en/                     documentación detallada (ver tabla arriba)
```

Para el detalle de por qué los pasos están divididos en "de host" (una
vez) y "por sistema operativo" (repetibles), y cómo el estado de
progreso viaja entre el sistema original, el chroot y el sistema
clonado ya arrancado, ver
[docs/es/ARQUITECTURA.md](docs/es/ARQUITECTURA.md).

## Añadir un sistema operativo nuevo al catálogo

Ver [docs/es/SISTEMAS_OPERATIVOS.md](docs/es/SISTEMAS_OPERATIVOS.md) —
en resumen: añadir su id a `lib/os_catalog.sh`, sus textos a
`i18n/strings.*.sh`, y su rama de repos/metapaquetes en
`steps/08_repositorios.sh` y `steps/09_instalacion_paquetes.sh`. El
resto del framework (menú, particionado, clonado, GRUB) es genérico y no
hay que tocarlo.

## Compatibilidad probada

| Modelo | Estado |
|---|---|
| MacBook Air M1 | Por probar |
| MacBook Air M2 | Por probar |
| MacBook Pro M1 | Por probar |
| MacBook Pro M2 | Por probar |

Actualiza esta tabla según se vaya confirmando en los `Issues` del
repositorio.

## Trabajo previo / Créditos

Este proyecto no parte de cero: se apoya en y da crédito a trabajo
previo de la comunidad, entre otros:

- [AsahiLinux/asahi-installer](https://github.com/AsahiLinux/asahi-installer) —
  el instalador base de Linux para Apple Silicon.
- [kali-asahi](https://github.com/allamiro/kali-asahi) — imagen nativa
  de Kali para Apple Silicon.
- Documentación oficial de Kali sobre
  [repositorios APT](https://www.kali.org/docs/general-use/kali-apt-sources/)
  y metapaquetes (`kali-linux-headless`, `kali-linux-everything`).
- [Debian Conversion Script de ParrotSec](https://gitlab.com/parrotsec/project/debian-conversion-script) —
  el script oficial del equipo de Parrot para convertir una base Debian.
- La guía de [Void Linux en Apple Silicon](https://docs.voidlinux.org/installation/guides/arm-devices/apple-silicon.html),
  usada como referencia para el patrón de partición externa con
  `/boot/efi` interno.
- La guía de Debian para Apple Silicon
  (<https://wiki.debian.org/InstallingDebianOn/Apple/M1>, proyecto
  Bananas), como referencia del prerrequisito de base Asahi/Debian.

**Lo que este proyecto añade sobre lo anterior:** integra y automatiza en
un único flujo repetible, con menú, progreso persistente, logging e
idioma configurable, pasos que antes estaban dispersos en guías
independientes — y permite instalar **varios sistemas ofensivos a la
vez** en el mismo disco externo, sin colisionar entre ellos.

## Aviso legal y uso ético

Este proyecto instala herramientas orientadas a pentesting y seguridad
ofensiva (Kali Linux, Parrot Security OS). Su uso está permitido
**únicamente** en sistemas de tu propiedad o para los que tengas
autorización explícita del propietario. El uso de estas herramientas
contra sistemas de terceros sin autorización puede ser ilegal según la
jurisdicción; el autor no se hace responsable del mal uso de las
herramientas instaladas a través de este proyecto.

## Licencia

Distribuido bajo licencia GPLv3. Ver el fichero [LICENSE](LICENSE).

## Contribuir

Las contribuciones son bienvenidas. Abre un Issue para reportar
problemas o una Pull Request para mejoras. Ver
[CONTRIBUTING.md](CONTRIBUTING.md).
