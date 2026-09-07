# Varios sistemas operativos en el mismo disco — base_inst_kali

## Sistemas soportados actualmente

| Id | Nombre | Método | Base de origen requerida | Soporte arm64 |
|---|---|---|---|---|
| `kali` | Kali Linux | Conversión: añade repos sobre la base clonada | Debian/Asahi | Oficial y maduro |
| `parrot` | Parrot OS | Conversión: añade repos sobre la base clonada | Debian/Asahi | Oficial, pero menos probado que Kali en Apple Silicon |
| `ubuntu` | Ubuntu | Clonado tal cual, sin conversión | Ubuntu/Asahi | Es la base nativa; no aplica |

Kali y Parrot son distribuciones basadas en Debian con repositorio
propio para `arm64`: se obtienen **convirtiendo** una base Debian/Asahi
ya clonada, añadiendo su repositorio y clave encima (pasos 08-09).
Ubuntu es distinto: no hay "conversión" posible ni con sentido (ni Kali
ni Parrot son oficialmente Ubuntu-based, y Ubuntu ya es Ubuntu), así que
se **clona tal cual** desde una instalación de **Ubuntu/Asahi genuina y
separada** en el disco interno (ver
[Ubuntu Asahi](https://ubuntuasahi.org/), proyecto comunitario que
instala Ubuntu Desktop 24.04/24.10 nativamente en Apple Silicon).

### Verificación de base de origen (bloqueante)

Como Kali/Parrot necesitan Debian/Asahi arrancado y Ubuntu necesita
Ubuntu/Asahi arrancado, el instalador comprueba automáticamente, antes
de particionar (paso 02), formatear (03) y clonar (04), que el sistema
**actualmente arrancado** coincide con lo que exige `$TARGET_OS`
(`lib/os_catalog.sh`, función `verify_source_base`, leyendo `ID=` de
`/etc/os-release`). Si no coincide, para en seco con instrucciones
claras de qué entrada de arranque interna elegir — ver
`docs/es/ARQUITECTURA.md` para el detalle técnico completo.

> **Nota sobre Parrot OS**: su soporte arm64 es real (repositorio oficial
> con `arch=arm64`), pero menos maduro y con menos usuarios probándolo en
> Apple Silicon que Kali. Si algún metapaquete de `parrot-tools-full`
> falla, revisa el log (`logs/paso_09_*.log`) e instala las herramientas
> sueltas que necesites en vez de bloquear toda la instalación por un
> paquete problemático.

## Ubuntu: qué hacen los pasos 08-09

- **Paso 08**: sin repositorios que añadir (ya es Ubuntu genuino) — solo
  `apt update && apt full-upgrade`, para dejar el clon al día.
- **Paso 09**:
  1. Instala `ubuntu-desktop` de forma **idempotente** (comprueba con
     `dpkg -l` si ya está, y lo omite si es así — la imagen de Ubuntu
     Asahi ya suele venir con escritorio).
  2. Ofrece, **de forma opcional** (`confirm_yes_no`, nunca automático),
     instalar **SIFT Workstation** (SANS), el conjunto de herramientas
     forenses — ver el veredicto completo más abajo.

## Herramientas forenses investigadas para Ubuntu: veredicto

Se evaluaron tres distribuciones/conjuntos forenses candidatos para
ejecutarse sobre el Ubuntu ya clonado. Resultado:

### ✅ SIFT Workstation (SANS) — integrado como opción en el paso 09

El propio proyecto (`teamdfir/sift-saltstack`) declara en su README
oficial, en vivo: **soporte para Ubuntu 22.04 (Jammy) y 24.04 (Noble)**,
**tanto `amd64` como `arm64`**, con un aviso conocido: *"a handful of
packages are amd64-only and are skipped on arm64"*. Esto coincide
exactamente con la versión que usa Ubuntu Asahi (24.04), y es soporte
arm64 **oficial del propio equipo mantenedor**, no un parche de
comunidad.

Se instala con `cast` (el instalador oficial, sucesor de `sift-cli`),
cuyo binario arm64 se descarga y resuelve automáticamente sin
hardcodear ninguna versión (`lib/common.sh`, función
`install_cast_arm64` — sigue la redirección de
`.../releases/latest` en vez de usar la API de GitHub, que tiene un
límite de peticiones/hora fácil de agotar).

*Nota histórica*: existe un proyecto de comunidad,
[`jonathanlooi/sift-on-arm`](https://github.com/jonathanlooi/sift-on-arm),
que documenta cómo parchear manualmente SIFT para arm64 — pero está
escrito contra **Ubuntu 22.04**, una versión anterior a la que soporta
oficialmente el proyecto hoy (22.04 y 24.04, con arm64 ya integrado).
Ha quedado superado por el soporte oficial actual; no hace falta ni se
recomienda seguir esa guía.

### 🟡 REMnux — en duda, no descartado del todo (investigación abierta)

La documentación oficial de REMnux (`docs.remnux.org`) sigue declarando,
repetida y recientemente actualizada en varias páginas: *"REMnux is
currently based on an x86/amd64 version of Ubuntu, and won't run on ARM
processors such as Apple's M-series chips"*. Su base es también Ubuntu
24.04 (coincide con Ubuntu Asahi). Sin embargo, una comparación directa
de sus `.sls` (SaltStack) con los de SIFT (`teamdfir/sift-saltstack`,
que sí soporta arm64 oficialmente) matiza ese "no" categórico:

**A favor de reconsiderarlo:**
- `remnux/packages/cast.sls` (el bootstrap del propio instalador) **ya
  tiene rama arm64 nativa**, sin necesitar ningún parche — al contrario
  que el `docker.sls` de SIFT, que `jonathanlooi/sift-on-arm` tuvo que
  arreglar a mano por un bug de arquitectura.
- `remnux/repos/remnux.sls` (el repositorio principal) usa un **PPA de
  Launchpad** (`pkgrepo.managed`, `ppa: remnux/stable`), un mecanismo
  arquitectura-transparente por diseño — no tiene el mismo tipo de bug
  que rompía el repo de Docker en SIFT.

**En contra — un riesgo de categoría distinta al de SIFT:**
- `remnux/packages/runsc.sls` (y previsiblemente otras herramientas de
  análisis de malware Windows) dependen de **Wine**, cuyo soporte arm64
  sigue siendo inmaduro (necesita FEX-Emu/box86 o el WoW64 nativo de
  Wine, todavía en desarrollo). Esto es un problema **arquitectónico**,
  no de packaging — no se arregla con un parche de una línea.
- `remnux/tools/polarproxy.sls` descarga directamente un binario
  `linux-x64` sin ninguna rama por arquitectura, porque el fabricante
  (NETRESEC) **solo publica build x64**. No hay parche posible sin que
  el proveedor externo publique un build arm64.

**Conclusión**: a diferencia de SIFT, que declara sus huecos arm64 como
"a handful of packages", REMnux, centrado en análisis de malware de
Windows, probablemente tenga una fracción mayor de sus ~300
herramientas afectadas por dependencias de Wine o binarios
vendor-specific solo-amd64 — un problema más extendido y de naturaleza
distinta. No se automatiza en el paso 09 por ahora. Ver la hoja de ruta
del README para el plan de investigación previsto:
probar `cast install --mode=addon` con un subconjunto reducido de
`.sls` que no dependan de Wine, para medir qué fracción real funciona
antes de decidir si se integra como opción (igual que SIFT) o se
documenta como "no soportado, prueba bajo tu responsabilidad".

### ❌ CAINE — descartado, no es un modelo de repositorio convertible

CAINE se distribuye como una **ISO Live modificada** ("a simple Ubuntu
18.04 customized for the computer forensics", según su propia
documentación), no como un repositorio APT que se pueda añadir sobre
una base ya instalada. No existe el mecanismo de "conversión" que sí
tienen Kali, Parrot o SIFT. Descartado por incompatibilidad de modelo,
no por falta de soporte arm64.

## Cómo conviven varios sistemas en el mismo disco externo

Cada sistema operativo activo (`ACTIVE_OS` en el estado) tiene:

- **Sus propias particiones** en el disco externo (números calculados
  automáticamente por el paso 02 a partir de las que ya existan).
- **Su propio grupo de volúmenes LVM** (`vg<id>`) y su propio
  contenedor LUKS (`<id>_root_crypt`), con su propia passphrase.
- **Su propio progreso** en el menú (`OS_<id>_STEP_<N>_STATUS`), así que
  puedes tener Kali completado del todo y Ubuntu a medias, y el menú te
  lo muestra correctamente para cada uno.

Los pasos de host (00, 01, 01a) se hacen **una sola vez**, no por cada
sistema: el usuario `iac`, la contraseña de root, el WiFi y los paquetes
base son del sistema Debian/Asahi de origen, no de cada clon. (Si vas a
clonar también hacia Ubuntu, ten en cuenta que esos pasos de host se
hicieron sobre el Debian/Asahi arrancado en su momento — el Ubuntu/Asahi
que arrancarás para clonar hacia `ubuntu` es un sistema de ficheros
distinto con su propio usuario/paquetes de partida, ver
`docs/es/ARQUITECTURA.md`.)

## Qué comprobar tras añadir un segundo sistema operativo

El paso 07 (fusión de `grub.cfg`) ejecuta `update-grub` en el host antes
de fusionar la entrada del sistema que se está procesando en ese
momento. Eso **regenera desde cero** el `grub.cfg` del host, así que:

- La entrada del sistema que procesaste **primero** (p. ej. Kali) puede
  reaparecer gracias a `os-prober` (que detecta instalaciones Linux ya
  existentes), pero como una entrada de arranque genérica ("chainload"),
  no la nativa con los parámetros de kernel correctos que este script
  construye a mano.
- La entrada del sistema que procesas **ahora** (p. ej. Parrot o Ubuntu)
  sí recibe el tratamiento completo y nativo.

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
SUPPORTED_OS=(kali parrot ubuntu blackarch)

declare -A OS_LABEL_CODE=(
    [kali]="KALI"
    [parrot]="PARROT"
    [ubuntu]="UBUNTU"
    [blackarch]="BLKARCH"   # máx. 11 caracteres para la etiqueta EFI (FAT)
)

# Si el nuevo SO necesita CONVERSIÓN (como Kali/Parrot), su base de
# origen es "debian". Si se CLONA TAL CUAL (como Ubuntu), su base de
# origen es su propio id, y hace falta una instalación separada de ese
# SO en el disco interno.
declare -A OS_SOURCE_BASE=(
    [kali]="debian"
    [parrot]="debian"
    [ubuntu]="ubuntu"
    [blackarch]="debian"   # o lo que corresponda
)
```

### 2. `i18n/strings.es.sh` y `i18n/strings.en.sh`

```bash
STRINGS[os_blackarch_name]="BlackArch Linux"
STRINGS[os_blackarch_desc]="Descripción breve..."
```

### 3. `steps/08_repositorios.sh` y `steps/09_instalacion_paquetes.sh`

Añadir una rama `blackarch)` al `case "$TARGET_OS" in ... esac` de cada
uno, con las claves/repositorios y los metapaquetes correspondientes
(si el SO requiere conversión), o solo un `apt update/upgrade` (si se
clona tal cual, como Ubuntu).

**No hace falta tocar nada más**: el menú, el cálculo de particiones, el
particionado, el cifrado LUKS, el clonado, el chroot, la verificación de
base de origen y la fusión de `grub.cfg` son completamente genéricos y
funcionan para cualquier id que aparezca en `SUPPORTED_OS`.

### Antes de añadir un sistema, comprobar

- Si requiere **conversión**: que tenga un **repositorio apt oficial con
  arquitectura `arm64`** (no basta con que exista una ISO de escritorio
  para x86/amd64). Es el mismo requisito que cumplen Kali y Parrot.
- Si se **clona tal cual** (como Ubuntu): que exista una instalación
  nativa de ese SO para Apple Silicon con la que arrancar el disco
  interno (equivalente a Ubuntu Asahi).
- Qué **metapaquete(s)** instalan el conjunto de herramientas deseado
  (equivalente a `kali-linux-default`, `parrot-tools-full` o
  `ubuntu-desktop`).
- Si necesita algún ajuste específico de arranque para Apple
  Silicon/u-boot que no esté ya cubierto por el paso 06 genérico (poco
  probable si es una distribución basada en Debian/Ubuntu, pero conviene
  revisarlo).
- Comprobar la disponibilidad real de paquetes en `arm64` antes de dar
  nada por hecho: ver el método general (con comandos concretos) en
  `docs/es/TROUBLESHOOTING.md`.
