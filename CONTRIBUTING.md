# Contribuir a base_inst_kali

Gracias por el interés en mejorar este proyecto. Antes de nada, lee
[docs/es/ARQUITECTURA.md](docs/es/ARQUITECTURA.md) (o
[docs/en/ARCHITECTURE.md](docs/en/ARCHITECTURE.md)) para entender el
diseño: pasos "de host" vs "por sistema operativo", los tres entornos de
ejecución (host / chroot / sistema clonado ya arrancado), y por qué el
estado se sincroniza a mano entre ellos.

## Cómo probar cambios sin hardware real

La mayoría de la lógica (menú, estado, i18n, cálculo de particiones) se
puede probar sin tocar discos reales:

```bash
# Comprobar sintaxis de todo el proyecto
for f in install.sh lib/*.sh i18n/*.sh steps/*.sh; do bash -n "$f" || echo "ERROR: $f"; done

# Probar el menú en modo texto, sin ejecutar ningún paso destructivo
rm -f /var/lib/base_inst_kali/state.conf   # estado limpio
printf '\n' | bash install.sh              # navega con números + Enter
```

Los pasos que sí tocan disco (`02_particiones.sh` en adelante) requieren
un disco real o una máquina virtual con un disco de pruebas — **nunca**
los pruebes contra el disco donde vive tu sistema operativo principal.

## Convenciones de código

Todas viven también en `docs/*/ARQUITECTURA.md` / `ARCHITECTURE.md`;
resumen:

1. Cualquier operación irreversible sobre un disco pasa por
   `confirm_destructive` (obliga a teclear una palabra de confirmación
   completa, no un simple s/n).
2. Ningún dato sensible se guarda fuera de los ficheros de configuración
   del propio sistema, y esos ficheros quedan con permisos `600`.
3. Todo comando que pueda fallar va envuelto en
   `run_cmd "descripción" comando...` para quedar registrado en el log.
4. Con `pipefail` activo, un `grep`/`awk` sin coincidencias hace fallar
   la línea bajo `set -e`; añade `|| true` cuando "vacío" sea un
   resultado válido y compruébalo explícitamente después.
5. Cualquier nombre derivado del sistema operativo (partición, VG,
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
- Describe cómo lo has probado (aunque sea solo `bash -n` + navegación
  del menú, si no tenías hardware real a mano).

## Reportar problemas

Al abrir un issue, incluye:
- El paso concreto donde ocurre (`00`…`09`) y su log
  (`logs/paso_<id>_<fecha>.log`), con cualquier dato sensible (SSID,
  contraseñas, UUID si te preocupa) eliminado a mano.
- Si el problema aparece con un sistema operativo concreto (Kali,
  Parrot), indícalo.
- Salida de `uname -m` y de `dpkg -l | grep asahi-` si el problema
  parece relacionado con el paso 00.
