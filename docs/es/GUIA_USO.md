# Guía de uso — base_inst_kali

## Antes de empezar

- **El MacBook Air debe tener ya instalada y actualizada Asahi
  Linux/Debian** en el disco interno (NVMe), siguiendo
  <https://wiki.debian.org/InstallingDebianOn/Apple/M1>. Este instalador
  no la instala ni la sustituye; parte de que ya está ahí y funciona.
- Necesitas un **disco USB externo**. Puede alojar más de un sistema
  operativo (Kali y Parrot a la vez, por ejemplo), cada uno en sus
  propias particiones. Anota su tamaño para diferenciarlo del NVMe
  interno cuando el paso 00 te pida elegirlo.
- Debes ejecutar todo como **root** (`sudo bash install.sh` o ya logueado
  como root).
- Ten a mano el directorio `/base_inst_kali/preparacion/` con los
  ficheros de apoyo si los usas (`sudoers`, `grub`, `modules.txt`,
  `interfaces`, `keyboard`, `locale`, el `.deb` del keyring de Kali). Si
  no existen, cada paso lo detecta y avisa qué se omite, pero no falla.

## Arrancar el instalador

```bash
sudo bash install.sh
```

Verás un menú (whiptail si ya está instalado, texto plano si no) con:

- Los pasos de **host** (00, 01, 01a) — se hacen una sola vez.
- Un selector de **sistema operativo activo** (opción "Sistemas
  operativos").
- Los pasos **02-09**, que corresponden siempre al sistema operativo
  activo en ese momento.

| Estado | Significado |
|---|---|
| `✓ hecho` | Paso completado con éxito. |
| `▶ siguiente` | Es el próximo paso pendiente, en orden. |
| `pendiente` | Todavía no le toca (hay pasos anteriores sin completar). |
| `✖ falló, reintentar` | La última ejecución terminó con error; revisa el log antes de reintentar. |
| `bloqueado` | Requiere completar el paso anterior primero (aviso, no impide seleccionarlo a mano si sabes lo que haces). |

## Orden recomendado — primera instalación (por ejemplo, Kali)

1. **00 · Comprobar requisitos y elegir disco** — detecta la arquitectura,
   avisa si no ve paquetes `asahi-*`, y te hace elegir el disco externo
   de una lista (o escribirlo a mano). Se guarda para el resto de pasos
   y para todos los sistemas operativos que instales en él.
2. **01 · Preparación base** — cambia la contraseña de root, instala los
   paquetes base (incluido `whiptail`), configura locale/teclado y crea
   el usuario `iac`. Se hace una sola vez.
3. **01a · Red WiFi** — opcional si ya tienes red por cable. Una sola vez.
4. **Sistemas operativos → elige "Kali Linux"** — a partir de aquí, los
   pasos 02-09 del menú son los de Kali.
5. **02 · Particionar disco externo** — calcula y crea las particiones de
   Kali en el disco elegido. **Pide confirmación destructiva explícita.**
6. **03 · LUKS + LVM + formateo** — cifra la partición root de Kali.
   **Aquí se te pedirá una passphrase: apúntala en un lugar seguro, sin
   ella no hay forma de recuperar los datos.**
7. **04 · Clonado** — copia el sistema actual a las particiones de Kali
   (tarda, depende del tamaño usado).
8. **05 · Montar y entrar en chroot** — al terminar te deja dentro de un
   `chroot`. Desde ahí ejecuta:
   ```bash
   /base_inst_kali_installer/steps/06_grub_finiquitar.sh
   ```
9. **06 · Finalizar GRUB** (dentro del chroot) — al terminar, sal con
   `exit`.
10. **07 · Fusionar grub.cfg** — se ejecuta ya fuera del chroot, en el
    host. Al terminar reinicia.
11. **Reinicia y elige la entrada de Kali** en el menú de arranque de
    GRUB (no la entrada normal de Debian/Asahi).
12. **08 · Repositorios de Kali** — ya arrancado en el sistema clonado.
13. **09 · Instalar metapaquetes de Kali** — último paso para Kali.

## Añadir un segundo sistema operativo (por ejemplo, Parrot) en el mismo disco

No hace falta repetir los pasos 00/01/01a (ya están hechos a nivel de
host). Simplemente:

1. Arranca de nuevo con el sistema Debian/Asahi original (no con Kali).
2. Abre `install.sh`, opción **"Sistemas operativos" → "Parrot OS"**.
3. Repite los pasos **02-09** tal cual, pero ahora se ejecutan para
   Parrot: el paso 02 calculará automáticamente particiones nuevas
   (p. ej. 4, 5 y 6 si Kali ya ocupaba 1, 2 y 3), sin tocar lo que Kali
   ya tiene.
4. Al terminar, el menú de arranque de GRUB debería mostrar **tres**
   entradas: el Debian/Asahi original, Kali y Parrot. Ver
   `docs/es/SISTEMAS_OPERATIVOS.md` para el detalle de por qué conviene
   comprobar esto tras añadir un segundo sistema.

## Reanudar tras un reinicio

El estado se guarda en `/var/lib/base_inst_kali/state.conf` y sobrevive a
los `reboot`. Para que el menú se reabra solo, añade a `/root/.bashrc`:

```bash
if [ -t 0 ]; then
    bash /base_inst_kali/install.sh
fi
```

## Cambiar de idioma

Desde el menú principal, opción `i`/`LANG`. Se guarda para las próximas
veces.

## Ver los logs

Desde el menú, opción `l`/`LOGS`, o directamente:

```bash
ls logs/
cat logs/install.log              # resumen de todos los pasos
cat logs/paso_03_<fecha>.log      # salida completa de un paso concreto
```

## Ejecutar un paso suelto sin pasar por el menú

Cada script es autónomo (lee `ACTIVE_OS`/`TARGET_DISK` del estado
guardado):

```bash
sudo bash steps/03_formateo.sh
```

Útil para depurar o repetir un paso que falló, aunque lo normal es
hacerlo desde `install.sh` para que el sistema operativo activo y el
estado queden sincronizados.
