# Mantenimiento de casas en renta · v1.0.0

## Qué hay
- `app.R`: toda la app.
- `data/`: se crea sola. Guarda casas, administradores, recibos, inspecciones y el registro de cambios en archivos JSON.
- `secrets/`: aquí va el archivo de la cuenta de servicio de Google. **No lo comparta.**

## Clave y accesos
- **Dueño:** clave `718718` (constante `OWNER_PIN` al inicio de `app.R`).
- **Administradores:** entran con su correo, que el dueño aprueba en la pestaña *Administradores*.

## Primer uso
1. Instale R y los paquetes: `shiny`, `DT`, `jsonlite`, `writexl`, `googledrive`.
2. Ejecute la app: `shiny::runApp("ruta/a/esta/carpeta")`.
3. Como dueño, cree las casas con su periodo y apruebe a los administradores.

## Google Drive (comprobantes)
1. En Google Cloud, cree una cuenta de servicio y active la API de Google Drive.
2. Descargue su archivo JSON y guárdelo en `secrets/`.
3. Cree una carpeta en Drive y compártala con el correo de la cuenta de servicio (permiso de editor).
4. En el dueño → *Configuración*, escriba el ID de la carpeta (la parte final de su enlace) y el nombre del archivo JSON.

Mientras no esté configurado, los recibos se guardan en `data/recibos_locales/`.

## Publicar en shinyapps.io
- **Atención:** los archivos que la app escribe en el servidor pueden perderse al reiniciar o redeployar. Antes de publicar hay que resolver dónde guardar los datos (por ejemplo, un respaldo periódico de `data/`).
