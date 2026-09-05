# Resolución de problemas — base_inst_kali

## "No hay un sistema operativo activo"

Los pasos 02-09 necesitan un SO activo. Ve al menú, opción "Sistemas
operativos", y elige Kali o Parrot antes de continuar.

## "TARGET_DISK no está definido o no es válido"

El paso 00 no se ha ejecutado, o se ejecutó pero se seleccionó un disco
que luego desapareció (p. ej. desconectaste el USB). Comprueba:

```bash
cat /var/lib/base_inst_kali/state.conf | grep TARGET_DISK
lsblk
```

Vuelve a ejecutar el paso 00 si hace falta corregirlo. Nota: `TARGET_DISK`
es común a todos los sistemas operativos que instales en ese disco, no
hace falta repetirlo por SO.

## El menú marca un paso como "✖ falló, reintentar"

Mira el log de ese paso concreto:

```bash
ls -t logs/paso_<ID>_*.log | head -1 | xargs cat
```

El log completo de la ejecución (incluida la salida de `apt`, `sgdisk`,
etc.) está ahí. El log maestro (`logs/install.log`) tiene solo el
resumen con la línea y el código de salida donde falló.

## whiptail no aparece aunque ya pasé el paso 01

Comprueba que el paquete se instaló:

```bash
dpkg -l whiptail
```

Si no está, instálalo a mano (`apt install whiptail`) y reintenta el
paso; no hace falta rehacer nada anterior, `lib/ui.sh` lo detecta solo en
la siguiente ejecución de cualquier script.

Si tienes `whiptail` instalado pero el instalador sigue en modo texto,
puede ser que no haya una terminal interactiva real (por ejemplo, estás
canalizando la entrada/salida, o ejecutando dentro de `screen`/`tmux` de
una forma que no expone una tty). Ejecuta el script directamente en una
terminal normal.

## Al salir del chroot (paso 06) el menú del host no marca "06" como hecho

Es el comportamiento esperado, no un bug: el paso 06 se ejecuta dentro
del chroot y escribe su progreso en el filesystem del disco externo
montado, no en el del host. Por eso el paso 07 no depende de esa marca
(ver `NO_GATE_STEPS` en `install.sh` y la sección correspondiente en
`docs/es/ARQUITECTURA.md`). Simplemente continúa con el paso 07 con
normalidad.

## "/part/dest_<os>/boot/grub/grub.cfg no existe" en el paso 07

El disco externo se ha desmontado entre el paso 05/06 y el 07 (por
ejemplo, si reiniciaste sin querer). Repite desde el paso 05 (con el
mismo SO activo) para volver a montar y entrar en el chroot, ejecuta de
nuevo el 06, y sin reiniciar continúa con el 07.

## Se me olvidó la passphrase de LUKS de un sistema operativo

No hay forma de recuperar los datos sin ella; es cifrado real. Tendrás
que repetir desde el paso 02 (reparticionar) o el 03 (reformatear/volver
a cifrar) **para ese sistema operativo concreto**, perdiendo lo que
hubiera en sus particiones hasta ese punto. El resto de sistemas
operativos en el mismo disco no se ven afectados.

## Tras añadir un segundo sistema operativo, el primero ya no arranca

Ver la sección correspondiente en `docs/es/SISTEMAS_OPERATIVOS.md`: el
paso 07 regenera `grub.cfg` desde cero cada vez, y el sistema procesado
más recientemente es el que recibe la entrada nativa completa. Cambia el
SO activo al sistema afectado y vuelve a ejecutar el paso 07 para
regenerar su entrada.

## Quiero repetir un paso ya marcado como "hecho"

Selecciónalo igualmente desde el menú (no está bloqueado, solo los
pasos *posteriores* al primero pendiente lo están) o ejecútalo suelto:

```bash
sudo bash steps/04_clonado.sh
```

Ten en cuenta que los pasos de particionado/formateo/clonado son
destructivos y te lo van a confirmar explícitamente, pero repetirlos
significa perder lo que se hubiera hecho después **para ese sistema
operativo**.

## El WiFi no conecta tras el paso 01a

Revisa el fichero generado:

```bash
cat /etc/wpa_supplicant/wpa_supplicant.conf
```

Si el SSID o la contraseña tienen caracteres especiales y no se usó
`wpa_passphrase` (por no estar disponible en ese momento), repite el
paso: el propio script lo intenta usar automáticamente si existe en el
sistema.

## Un metapaquete de Parrot OS falla al instalar (paso 09)

El soporte arm64 de Parrot es oficial pero menos maduro que el de Kali.
Revisa `logs/paso_09_*.log` para ver qué paquete concreto falló, e
instálalo o sustitúyelo manualmente después (`apt install <paquete>`);
no hace falta repetir todo el paso 09 por un único paquete problemático.
