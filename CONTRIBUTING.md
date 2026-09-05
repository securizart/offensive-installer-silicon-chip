# Contribuir a base_inst_kali (Offensive Installer Silicon Chip)

Gracias por el interés en mejorar este proyecto. Antes de nada, lee
[docs/es/ARQUITECTURA.md](docs/es/ARQUITECTURA.md) (o
[docs/en/ARCHITECTURE.md](docs/en/ARCHITECTURE.md)) para entender el
diseño: pasos "de host" vs "por sistema operativo", los tres entornos de
ejecución (host / chroot / sistema clonado ya arrancado), y por qué el
estado se sincroniza a mano entre ellos.

## Reportar un problema

Abre un [Issue](../../issues) incluyendo:

- Modelo exacto de Mac (Air/Pro, M1/M2) y cantidad de RAM.
- Versión de macOS desde la que partiste antes de instalar Asahi/Debian.
- Distribución elegida (Kali o Parrot) y en qué paso (`00`…`09`) falló el
  proceso.
- Salida completa del error, junto con el log del paso concreto
  (`logs/paso_<id>_<fecha>.log`), con cualquier dato sensible (SSID,
  contraseñas, UUID si te preocupa) eliminado a mano. Usa bloques de
  código (```` ``` ````) para pegarlo.

## Proponer una mejora

1. Haz un fork del repositorio.
2. Crea una rama descriptiva: `git checkout -b fix/particionado-externo`.
3. **Prueba tu cambio en una máquina real antes de abrir el PR.** Dado el
   riesgo que implican estos scripts (particionado, cifrado, GRUB), no se
   aceptarán cambios sin evidencia de haberse probado — al menos en un
   modelo de Mac concreto, indicando cuál.
4. Abre el Pull Request describiendo qué problema resuelve y en qué
   modelo de Mac lo probaste. Indica también si afecta a Kali, a Parrot,
   o a ambos.

## Cómo probar cambios sin hardware real (solo para lógica, no para pasos destructivos)

La lógica de menú, estado, i18n y cálculo de particiones se puede probar
sin tocar discos reales:

```bash
# Comprobar sintaxis de todo el proyecto
for f in install.sh lib/*.sh i18n/*.sh steps/*.sh; do bash -n "$f" || echo "ERROR: $f"; done

# Probar el menú en modo texto, sin ejecutar ningún paso destructivo
rm -f /var/lib/base_inst_kali/state.conf   # estado limpio
printf '\n' | bash install.sh              # navega con números + Enter
```

Esto **no sustituye** la prueba en hardware real exigida en el punto 3
de arriba para cualquier cambio que toque los pasos `02` en adelante
(particionado, LUKS, clonado, GRUB, repositorios): esos solo se
consideran probados si se han ejecutado de verdad en un Mac Apple
Silicon con un disco externo.

## Estilo de los scripts

- Bash con `set -euo pipefail` al principio de cada script (heredado
  automáticamente al cargar `lib/common.sh`).
- Comentarios que expliquen el *por qué*, no solo el *qué* — especialmente
  en las partes no obvias (por ejemplo, por qué el paso 06 no bloquea el
  menú del host, o por qué se namespacea el estado por sistema
  operativo; ver `docs/es/ARQUITECTURA.md`).
- Cualquier paso destructivo (particionar, formatear, borrar) debe pedir
  confirmación explícita del usuario antes de ejecutarse
  (`confirm_destructive` en `lib/common.sh`).
- Todo comando que pueda fallar va envuelto en
  `run_cmd "descripción" comando...` para quedar registrado en el log.
- Con `pipefail` activo, un `grep`/`awk` sin coincidencias hace fallar
  la línea bajo `set -e`; añade `|| true` cuando "vacío" sea un
  resultado válido y compruébalo explícitamente después.
- Cualquier nombre derivado del sistema operativo (partición, VG,
  mapper, mountpoint) sale de `lib/os_catalog.sh`, nunca hardcodeado.

## Añadir un sistema operativo nuevo

Ver [docs/es/SISTEMAS_OPERATIVOS.md](docs/es/SISTEMAS_OPERATIVOS.md) —
solo hace falta tocar `lib/os_catalog.sh`, los ficheros de `i18n/`, y las
ramas `case` de `steps/08_repositorios.sh` y
`steps/09_instalacion_paquetes.sh`.

## Añadir o traducir textos (i18n)

Los textos viven en `i18n/strings.es.sh` y `i18n/strings.en.sh`, como
entradas de un array asociativo `STRINGS[clave]="texto con %s"`. Ambos
ficheros deben mantener exactamente las mismas claves. Para añadir un
idioma nuevo, copia uno de los dos ficheros, tradúcelo, y añade su
código en el selector de idioma de `install.sh`
(función `switch_language`).

## Pull requests

- Un PR por cambio lógico (no mezcles, por ejemplo, un fix de seguridad
  con la adición de un sistema operativo nuevo).
- Actualiza `CHANGELOG.md` en la sección `[Unreleased]`.
- Si el cambio afecta al comportamiento documentado, actualiza también
  la documentación correspondiente en **ambos** idiomas (`docs/es/` y
  `docs/en/`).
- Describe cómo lo has probado: en qué modelo de Mac (obligatorio para
  cambios en los pasos `02`-`09`), o solo `bash -n` + navegación del
  menú si el cambio no toca lógica destructiva.
