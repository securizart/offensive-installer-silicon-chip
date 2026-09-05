# base_inst_kali

Instalador con menú, multiidioma (ES/EN) y soporte para **varios
sistemas operativos ofensivos** (Kali Linux, Parrot OS) en un disco
externo USB, clonados a partir de una base **Debian/Asahi** ya instalada
en un MacBook Air Apple Silicon (M1/M2).

```
Debian/Asahi (NVMe interno, ya instalado) ──clona──▶ disco externo USB
                                                       ├── Kali Linux (particiones propias)
                                                       └── Parrot OS  (particiones propias)
```

## Requisito indispensable antes de usar esto

**El MacBook Air debe tener ya instalado y actualizado el sistema
operativo base Asahi Linux / Debian** en su disco interno (NVMe), antes
de ejecutar nada de este repositorio. Este proyecto **no instala macOS
ni Asahi/Debian**: parte de que esa base ya existe y funciona, y clona
ese sistema en marcha hacia un disco externo para convertirlo en Kali
y/o Parrot.

Sigue la guía oficial si todavía no la tienes:
<https://wiki.debian.org/InstallingDebianOn/Apple/M1> (proyecto Bananas
de Debian, basado en el trabajo de Asahi Linux). El paso `00` de este
instalador comprueba indicios de esa instalación (arquitectura arm64,
paquetes `asahi-*`) y te avisa si no los encuentra, pero la
responsabilidad de tener esa base lista y actualizada es previa a usar
este repositorio.

## Qué hace este proyecto

- Particiona, cifra (LUKS) y formatea un **disco externo USB**.
- **Clona** el sistema Debian/Asahi en marcha a ese disco externo.
- Añade los repositorios y metapaquetes de **Kali Linux** y/o **Parrot
  OS** sobre esa base clonada, convirtiéndola en una distribución de
  pentesting completa, arrancable desde el menú de GRUB junto al sistema
  original.
- Permite instalar **más de un sistema ofensivo en el mismo disco
  externo**, cada uno en sus propias particiones, sin pisar los datos de
  los demás.
- Todo ello guiado por un **menú único** (`install.sh`) con progreso
  persistente (sobrevive a los múltiples reinicios que exige el
  proceso), **logging** por paso, y textos en **castellano e inglés**.

## Empezar

```bash
git clone <url-de-este-repositorio> base_inst_kali
cd base_inst_kali
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
[CONTRIBUTING.md](CONTRIBUTING.md) · [LICENSE](LICENSE)

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

## Aviso legal / uso responsable

Este proyecto instala herramientas de pentesting (Kali Linux, Parrot
OS). Su uso está pensado para pruebas de seguridad autorizadas, análisis
forense y aprendizaje en entornos propios o con permiso explícito. El
uso de estas herramientas contra sistemas de terceros sin autorización
puede ser ilegal según la jurisdicción; la responsabilidad de un uso
correcto es de quien opera el sistema.

## Licencia

Ver [LICENSE](LICENSE).
