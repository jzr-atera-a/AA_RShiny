# Casas en Renta · v2.0.0

App para administrar el mantenimiento de casas en renta. Hay dos tipos de usuario:

- **Dueño:** entra con su clave y tiene acceso completo.
- **Administradores:** entran con un correo aprobado por el dueño y solo ven sus casas, dentro del periodo de cada una.

## Qué hace cada sección

| Sección | Dueño | Administrador |
|---|---|---|
| Panel general / Mi panel | Indicadores, gráficas, alertas, resumen por casa, actividad reciente | Lo mismo, pero solo de sus casas |
| Casas y periodos | Crea casas con su periodo y las activa o desactiva | (ve *Mis casas*) |
| Contratos e inquilinos | Inquilino, renta, día de pago, vigencia | Ve los datos en *Mis casas* |
| Administradores | Aprueba correos y asigna casas | — |
| Materiales / Servicios | Consulta | Registra fecha, monto, concepto y foto del recibo |
| Rentas | Consulta el tablero | Registra los pagos recibidos |
| Órdenes de trabajo | Crea y consulta | Crea y da seguimiento: prioridad, estado, proveedor, costo |
| Mantenimiento preventivo | Crea y marca como hecho | Crea y marca como hecho |
| Inspecciones | Consulta | Registra las visitas |
| Proveedores | Directorio compartido | Directorio compartido |
| Reportes y Excel | Totales por casa y Excel con todo | Lo mismo, de sus casas |
| Historial de cambios | Quién hizo qué, con valor anterior y nuevo | — |
| Configuración | Google Drive, respaldo y restauración | — |

**Reglas de acceso**
- El administrador solo puede registrar fechas dentro del periodo de la casa.
- Solo ve los registros de ese periodo.
- Cada vez que alguien crea, edita, elimina o marca algo como hecho, queda en el historial. Al eliminar, se guarda una copia completa del registro.

## Ejecutar en una computadora
1. Instale R y estos paquetes: `install.packages(c("shiny","shinydashboard","DT","jsonlite","writexl","ggplot2","googledrive"))`
2. Ejecute: `shiny::runApp("ruta/a/esta/carpeta")`
3. Entre como **Dueño** (clave `718718`). Cree las casas, apruebe a los administradores y registre los contratos.

## Archivos
- `app.R`: arranque, menú y acceso.
- `codigo/`: datos, lógica, componentes, motor de registros (`crud.R`), secciones (`entidades.R`), páginas y servidor.
  - Se llama `codigo/` y no `R/` a propósito: Shiny carga sola la carpeta `R/` en orden alfabético y eso rompe el orden de carga.
- `www/`: estilos y JavaScript.
- `data/`: **toda la información**, en archivos JSON de texto. Se crea sola y **no debe ir en el ZIP** de una versión nueva.
- `secrets/`: aquí va la llave de Google Drive. **No la comparta.**

## Google Drive para los comprobantes
1. En Google Cloud, cree una cuenta de servicio y active la API de Google Drive.
2. Guarde su llave JSON en `secrets/`.
3. Cree una carpeta en Drive y compártala con el correo de la cuenta de servicio, con permiso de editor.
4. En **Configuración**, escriba el ID de la carpeta y el nombre del archivo JSON.

Mientras Drive no esté configurado, las fotos se guardan en `data/recibos_locales/`.

## Clave del dueño
Por defecto es `718718`. Para cambiarla:
- En el servidor, defina la variable de entorno `OWNER_PIN`.
- O cambie `OWNER_PIN` en `codigo/datos.R`.

## Publicar en shinyapps.io: importante
**shinyapps.io puede borrar `data/` al reiniciar o al publicar una versión nueva.** Use **Configuración → Descargar respaldo** con frecuencia, y siempre antes de publicar. Después de publicar, use **Restaurar** con ese archivo.

Para guardar los datos de forma permanente hay dos opciones:
- Guardarlos fuera del servidor, por ejemplo en Google Drive o en una base de datos.
- Usar Posit Connect con almacenamiento persistente.

## Pasar a versiones nuevas
- Los datos de la versión 1.0 se leen sin cambios.
- **Reglas para quien programe la siguiente versión:**
  - Solo agregar columnas en `COLS` (`codigo/datos.R`); nunca renombrar ni quitar.
  - Los `id` no cambian.
  - Subir `APP_VERSION` en cada versión.
