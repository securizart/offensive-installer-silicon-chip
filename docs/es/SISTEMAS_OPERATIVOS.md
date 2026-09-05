# Varios sistemas operativos en el mismo disco — base_inst_kali

## Sistemas soportados actualmente

| Id | Nombre | Repositorio | Soporte arm64 |
|---|---|---|---|
| `kali` | Kali Linux | `http.kali.org/kali` (kali-rolling) | Oficial y maduro |
| `parrot` | Parrot OS | `deb.parrot.sh/parrot` (lts) | Oficial, pero menos probado que Kali en Apple Silicon |

Ambos son distribuciones basadas en Debian con repositorio propio para
`arm64`, lo que permite el mismo método que ya usaba el proyecto para
Kali: añadir su repositorio y clave sobre la base Debian/Asahi clonada,
en vez de instalar una imagen ISO completa (que ninguna de las dos
distribuciones ofrece de forma oficial y probada para Apple Silicon).

> **Nota sobre Parrot OS**: su soporte arm64 es real (repositorio oficial
> con `arch=arm64`), pero menos maduro y con menos usuarios probándolo en
> Apple Silicon que Kali. Si algún metapaquete de `parrot-tools-full`
> falla, revisa el log (`logs/paso_09_*.log`) e instala las herramientas
> sueltas que necesites en vez de bloquear toda la instalación por un
> paquete problemático.

## Cómo conviven varios sistemas en el mismo disco externo

Cada sistema operativo activo (`ACTIVE_OS` en el estado) tiene:

- **Sus propias particiones** en el disco externo (números calculados
  automáticamente por el paso 02 a partir de las que ya existan).
- **Su propio grupo de volúmenes LVM** (`vg<id>`) y su propio
  contenedor LUKS (`<id>_root_crypt`), con su propia passphrase.
- **Su propio progreso** en el menú (`OS_<id>_STEP_<N>_STATUS`), así que
  puedes tener Kali completado del todo y Parrot a medias, y el menú te
  lo muestra correctamente para cada uno.

Los pasos de host (00, 01, 01a) se hacen **una sola vez**, no por cada
sistema: el usuario `iac`, la contraseña de root, el WiFi y los paquetes
base son del sistema Debian/Asahi de origen, no de cada clon.

## Qué comprobar tras añadir un segundo sistema operativo

El paso 07 (fusión de `grub.cfg`) ejecuta `update-grub` en el host antes
de fusionar la entrada del sistema que se está procesando en ese
momento. Eso **regenera desde cero** el `grub.cfg` del host, así que:

- La entrada del sistema que procesaste **primero** (p. ej. Kali) puede
  reaparecer gracias a `os-prober` (que detecta instalaciones Linux ya
  existentes), pero como una entrada de arranque genérica ("chainload"),
  no la nativa con los parámetros de kernel correctos que este script
  construye a mano.
- La entrada del sistema que procesas **ahora** (p. ej. Parrot) sí recibe
  el tratamiento completo y nativo.

**Recomendación**: después de añadir un segundo sistema operativo,
arranca y comprueba que ambas entradas siguen apareciendo en el menú de
GRUB y que ambas arrancan correctamente. Si la entrada más antigua ya no
aparece o falla, puedes volver a ejecutar el paso 07 para ese sistema
(cambiando el SO activo a él y relanzando 07) para regenerar su fusión
nativa.

## Añadir un sistema operativo nuevo al catálogo

Todo el trabajo de generalización ya está hecho en el framework; añadir
un sistema operativo nuevo (por ejemplo, BlackArch) solo requiere tocar
tres sitios:

### 1. `lib/os_catalog.sh`

```bash
SUPPORTED_OS=(kali parrot blackarch)

declare -A OS_LABEL_CODE=(
    [kali]="KALI"
    [parrot]="PARROT"
    [blackarch]="BLKARCH"   # máx. 11 caracteres para la etiqueta EFI (FAT)
)
```

### 2. `i18n/strings.es.sh` y `i18n/strings.en.sh`

```bash
STRINGS[os_blackarch_name]="BlackArch Linux"
STRINGS[os_blackarch_desc]="Descripción breve..."
```

### 3. `steps/08_repositorios.sh` y `steps/09_instalacion_paquetes.sh`

Añadir una rama `blackarch)` al `case "$TARGET_OS" in ... esac` de cada
uno, con las claves/repositorios y los metapaquetes correspondientes,
siguiendo el mismo patrón que las de `kali`/`parrot`.

**No hace falta tocar nada más**: el menú, el cálculo de particiones, el
particionado, el cifrado LUKS, el clonado, el chroot y la fusión de
`grub.cfg` son completamente genéricos y funcionan para cualquier id que
aparezca en `SUPPORTED_OS`.

### Antes de añadir un sistema, comprobar

- Que la distribución tenga un **repositorio apt oficial con
  arquitectura `arm64`** (no basta con que exista una ISO de escritorio
  para x86/amd64). Es el mismo requisito que cumplen Kali y Parrot.
- Qué **metapaquete(s)** instalan el conjunto de herramientas deseado
  (equivalente a `kali-linux-default` o `parrot-tools-full`).
- Si necesita algún ajuste específico de arranque para Apple
  Silicon/u-boot que no esté ya cubierto por el paso 06 genérico (poco
  probable si es una distribución basada en Debian, pero conviene
  revisarlo).
