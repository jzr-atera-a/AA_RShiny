# Pruebas de la app: ejecutar desde una COPIA de la carpeta (crea datos de prueba en data/)
# LANG=C.UTF-8 Rscript -e 'source("pruebas/pruebas.R", encoding="UTF-8")'
suppressPackageStartupMessages(library(shiny))
ex <- new.env()
for (e in parse("app.R", encoding = "UTF-8")) invisible(eval(e, ex))
attach(ex, name = "appenv", warn.conflicts = FALSE)
ok <- function(cond, msg) { if (!isTRUE(cond)) stop("FALLA: ", msg); cat("  ✔", msg, "\n") }
tmp <- tempfile(fileext = ".jpg"); writeBin(as.raw(1:50), tmp)
fdf <- function(n = "r.jpg") data.frame(name = n, size = 50, type = "image/jpeg", datapath = tmp, stringsAsFactors = FALSE)
H <- as.character(Sys.Date()); MES <- format(Sys.Date(), "%Y-%m")
render <- function(x) invisible(x)

testServer(ex$server, {
  session$setInputs(pin = "718718", btn_dueno = 1)
  # Casas
  session$setInputs(cas_nuevo = 1)
  session$setInputs(f_cas_nombre_1 = "Casa Reforma", f_cas_tipo_prop_1 = "Casa", f_cas_direccion_1 = "Reforma 100",
                    f_cas_inicio_1 = as.Date("2026-01-01"), f_cas_fin_1 = as.Date("2027-06-30"), f_cas_activa_1 = "si", f_cas_notas_1 = "", cas_guardar = 1)
  session$setInputs(cas_nuevo = 2)
  session$setInputs(f_cas_nombre_2 = "Depto Roma", f_cas_tipo_prop_2 = "Departamento", f_cas_direccion_2 = "Roma 5",
                    f_cas_inicio_2 = as.Date("2026-01-01"), f_cas_fin_2 = as.Date("2026-12-31"), f_cas_activa_2 = "si", f_cas_notas_2 = "", cas_guardar = 2)
  cs <- read_tbl("casas"); ok(nrow(cs) == 2, "el dueño crea 2 casas"); id1 <- cs$id[cs$nombre == "Casa Reforma"]; id2 <- cs$id[cs$nombre == "Depto Roma"]
  # periodo inválido
  session$setInputs(cas_nuevo = 3)
  session$setInputs(f_cas_nombre_3 = "Mala", f_cas_tipo_prop_3 = "Casa", f_cas_direccion_3 = "", f_cas_inicio_3 = as.Date("2026-05-01"),
                    f_cas_fin_3 = as.Date("2026-01-01"), f_cas_activa_3 = "si", f_cas_notas_3 = "", cas_guardar = 3)
  ok(nrow(read_tbl("casas")) == 2, "rechaza periodo con fin antes del inicio")
  # Administrador
  session$setInputs(adm_nuevo = 1)
  session$setInputs(f_adm_email_1 = "Ana@Example.com", f_adm_nombre_1 = "Ana López", f_adm_telefono_1 = "555", f_adm_casas_1 = id1, adm_guardar = 1)
  ok(nrow(read_tbl("admins")) == 1 && read_tbl("admins")$email == "ana@example.com", "aprueba administrador (correo en minúsculas)")
  ok(identical(read_tbl("asignaciones")$casa_id, id1), "asigna solo la Casa Reforma")
  # Contrato
  session$setInputs(con_nuevo = 1)
  session$setInputs(f_con_casa_id_1 = id1, f_con_inquilino_1 = "Familia Pérez", f_con_telefono_1 = "", f_con_email_1 = "",
                    f_con_renta_1 = 15000, f_con_dia_pago_1 = 5, f_con_inicio_1 = as.Date("2026-01-01"), f_con_fin_1 = as.Date("2026-12-31"),
                    f_con_deposito_1 = 15000, f_con_estado_1 = "Vigente", f_con_notas_1 = "", con_guardar = 1)
  ok(nrow(read_tbl("contratos")) == 1, "registra contrato")
  # Proveedor
  session$setInputs(prv_nuevo = 1)
  session$setInputs(f_prv_nombre_1 = "Plomería Juárez", f_prv_especialidad_1 = "Plomería", f_prv_telefono_1 = "55 1234 5678",
                    f_prv_email_1 = "", f_prv_calificacion_1 = "5", f_prv_notas_1 = "", prv_guardar = 1)
  ok(nrow(read_tbl("proveedores")) == 1, "agrega proveedor")
  # Salidas del dueño
  for (o in c("inicio_kpis", "inicio_alertas", "inicio_casas", "cas_tabla", "adm_tabla", "con_tabla", "casas_cards_dueno", "prv_tabla"))
    render(output[[o]])
  ok(TRUE, "pantallas del dueño se generan sin error")

  # ---------------- Administrador
  session$setInputs(email = " ANA@example.com ", btn_admin = 1)
  session$setInputs(mat_nuevo = 1)
  session$setInputs(f_mat_casa_id_1 = id1, f_mat_fecha_1 = as.Date("2026-03-10"), f_mat_categoria_1 = "Plomería", f_mat_monto_1 = 850.5,
                    f_mat_concepto_1 = "Tubo PVC y codos", f_mat_proveedor_1 = "Plomería Juárez", f_mat_orden_id_1 = "", f_mat_notas_1 = "", mat_guardar = 1)
  ok(nrow(read_tbl("recibos")) == 0, "sin foto del recibo no se guarda")
  session$setInputs(f_mat_archivo_1 = fdf(), mat_guardar = 2)
  r <- read_tbl("recibos"); ok(nrow(r) == 1 && r$monto == 850.5 && r$admin_email == "ana@example.com" && r$archivo_tipo == "local", "guarda recibo con foto (copia local)")
  ok(file.exists(file.path(RECIBOS_DIR, r$archivo)), "la foto quedó guardada")
  session$setInputs(f_mat_casa_id_1 = id2, mat_guardar = 3)
  ok(nrow(read_tbl("recibos")) == 1, "no deja registrar en una casa que no administra")
  session$setInputs(f_mat_casa_id_1 = id1, f_mat_fecha_1 = as.Date("2027-08-01"), mat_guardar = 4)
  ok(nrow(read_tbl("recibos")) == 1, "no deja registrar fuera del periodo")
  # Servicio
  session$setInputs(srv_nuevo = 1)
  session$setInputs(f_srv_casa_id_1 = id1, f_srv_fecha_1 = as.Date("2026-04-02"), f_srv_categoria_1 = "Electricidad (CFE)", f_srv_monto_1 = 1200,
                    f_srv_concepto_1 = "Luz bimestre", f_srv_proveedor_1 = "CFE", f_srv_orden_id_1 = "", f_srv_notas_1 = "", f_srv_archivo_1 = fdf("l.pdf"), srv_guardar = 1)
  r <- read_tbl("recibos"); ok(sum(r$tipo == "Servicio") == 1 && r$servicio[r$tipo == "Servicio"] == "Electricidad (CFE)", "guarda pago de servicio")
  # Orden de trabajo
  session$setInputs(ord_nuevo = 1)
  session$setInputs(f_ord_casa_id_1 = id1, f_ord_fecha_1 = as.Date("2026-10-01"), f_ord_titulo_1 = "Fuga en baño", f_ord_descripcion_1 = "Gotea el lavabo",
                    f_ord_reportado_por_1 = "Inquilino", f_ord_prioridad_1 = "Urgente", f_ord_estado_1 = "Abierta", f_ord_proveedor_1 = "Plomería Juárez",
                    f_ord_costo_estimado_1 = 900, f_ord_fecha_cierre_1 = NA, f_ord_notas_1 = "", ord_guardar = 1)
  o <- read_tbl("ordenes"); ok(nrow(o) == 1 && o$estado == "Abierta", "crea orden de trabajo urgente")
  # Recibo ligado a la orden
  session$setInputs(mat_nuevo = 2)
  session$setInputs(f_mat_casa_id_2 = id1, f_mat_fecha_2 = as.Date("2026-10-03"), f_mat_categoria_2 = "Plomería", f_mat_monto_2 = 320,
                    f_mat_concepto_2 = "Llave de paso", f_mat_proveedor_2 = "Ferretería", f_mat_orden_id_2 = o$id, f_mat_notas_2 = "", f_mat_archivo_2 = fdf(), mat_guardar = 5)
  ok(sum(read_tbl("recibos")$orden_id %in% o$id) == 1, "recibo ligado a la orden")
  # Editar la orden → Terminada (fecha de cierre automática)
  session$setInputs(crud_evt = list(k = "ord", a = "editar", id = o$id, n = 1))
  session$setInputs(f_ord_casa_id_2 = id1, f_ord_fecha_2 = as.Date("2026-10-01"), f_ord_titulo_2 = "Fuga en baño", f_ord_descripcion_2 = "Gotea el lavabo",
                    f_ord_reportado_por_2 = "Inquilino", f_ord_prioridad_2 = "Urgente", f_ord_estado_2 = "Terminada", f_ord_proveedor_2 = "Plomería Juárez",
                    f_ord_costo_estimado_2 = 900, f_ord_fecha_cierre_2 = NA, f_ord_notas_2 = "Cambiada la llave", ord_guardar = 2)
  o <- read_tbl("ordenes"); ok(o$estado == "Terminada" && o$fecha_cierre == H, "cerrar orden pone la fecha de cierre")
  # Preventivo vencido y marcarlo hecho
  session$setInputs(pre_nuevo = 1)
  session$setInputs(f_pre_casa_id_1 = id1, f_pre_tarea_1 = "Fumigación", f_pre_frecuencia_1 = 6, f_pre_ultima_1 = as.Date("2026-01-10"),
                    f_pre_responsable_1 = "", f_pre_notas_1 = "", pre_guardar = 1)
  p <- read_tbl("preventivo"); ok(estado_prev(p)$estado == "Vencida", "tarea preventiva detectada como vencida")
  render(output$inicio_alertas)
  ok(any(grepl("Fumigación", alertas(ctx())$texto)), "aparece en las alertas")
  session$setInputs(crud_evt = list(k = "pre", a = "hecho", id = p$id, n = 2))
  session$setInputs(prev_hecho_fecha = Sys.Date(), prev_hecho_nota = "Fumigó Plagas SA", prev_hecho_ok = 1)
  p <- read_tbl("preventivo"); ok(p$ultima == H && estado_prev(p)$estado == "Al día", "marcar como hecho recalcula la próxima fecha")
  # Renta
  session$setInputs(pag_nuevo = 1)
  session$setInputs(f_pag_casa_id_1 = id1, f_pag_mes_1 = MES, f_pag_fecha_1 = Sys.Date(), f_pag_monto_1 = 15000, f_pag_metodo_1 = "Transferencia",
                    f_pag_notas_1 = "", pag_guardar = 1)
  er <- estado_rentas(ctx(), 1); ok(er$estado[er$casa_id == id1] == "pagada", "renta del mes queda pagada")
  # Inspección
  session$setInputs(ins_nuevo = 1)
  session$setInputs(f_ins_casa_id_1 = id1, f_ins_fecha_1 = Sys.Date(), f_ins_tipo_insp_1 = "Rutina", f_ins_estado_general_1 = "Bueno",
                    f_ins_con_inquilinos_1 = "Piden revisar el boiler", f_ins_plan_1 = "Servicio al boiler", f_ins_comentario_dueno_1 = "Todo bien", ins_guardar = 1)
  ok(nrow(read_tbl("inspecciones")) == 1, "guarda inspección")
  # Editar recibo y eliminar
  rid <- read_tbl("recibos"); rid <- rid$id[rid$concepto == "Tubo PVC y codos"]
  session$setInputs(crud_evt = list(k = "mat", a = "editar", id = rid, n = 3))
  session$setInputs(f_mat_casa_id_3 = id1, f_mat_fecha_3 = as.Date("2026-03-11"), f_mat_categoria_3 = "Plomería", f_mat_monto_3 = 900,
                    f_mat_concepto_3 = "Tubo PVC y codos", f_mat_proveedor_3 = "Plomería Juárez", f_mat_orden_id_3 = "", f_mat_notas_3 = "", mat_guardar = 6)
  r <- read_tbl("recibos"); ok(r$monto[r$id == rid] == 900 && r$editado_por[r$id == rid] == "ana@example.com", "edición guardada con autor")
  session$setInputs(crud_evt = list(k = "mat", a = "borrar", id = rid, n = 4), mat_borrar_ok = 1)
  ok(!(rid %in% read_tbl("recibos")$id), "eliminación")
  # Seguridad: no puede editar contratos (solo dueño)
  cid <- read_tbl("contratos")$id
  session$setInputs(crud_evt = list(k = "con", a = "editar", id = cid, n = 5))
  for (o in c("inicio_kpis", "inicio_alertas", "inicio_casas", "mat_tabla", "srv_tabla", "ord_tabla", "pre_tabla", "pag_tabla",
              "ins_tabla", "rentas_tablero", "casas_cards_admin", "rep_kpis", "rep_tabla", "rep_categorias", "mat_resumen", "ord_resumen"))
    render(output[[o]])
  ok(TRUE, "pantallas del administrador se generan sin error")
  cam <- read_tbl("cambios")
  ok(all(c("Crear", "Editar", "Eliminar", "Realizado", "Entrar") %in% cam$accion), "historial con crear/editar/eliminar/realizado/entrar")
  det <- cam$detalle[cam$accion == "Editar" & cam$entidad == "Recibo de material"]
  ok(grepl("Monto ($ MXN): «850.5» → «900»", det, fixed = TRUE) && grepl("10/03/2026", det), "el historial guarda el valor anterior y el nuevo")
  ok(grepl("datos:", cam$detalle[cam$accion == "Eliminar"]), "al eliminar se guarda una copia completa del registro")
  # Dueño otra vez: ve todo
  session$setInputs(pin = "718718", btn_dueno = 2)
  for (o in c("his_tabla", "inicio_actividad", "cfg_info", "cfg_estado", "pl_gastos_mes", "pl_rentas", "pl_categorias")) render(output[[o]])
  ok(TRUE, "historial, gráficas y configuración del dueño sin error")
  # Casa con registros no se puede borrar
  session$setInputs(crud_evt = list(k = "cas", a = "borrar", id = id1, n = 6))
  ok(id1 %in% read_tbl("casas")$id, "no se borra una casa con registros")
  # Respaldo y restauración
  f <- tempfile(fileext = ".json"); writeLines(respaldo_json(), f)
  n0 <- nrow(read_tbl("recibos")); write_tbl("recibos", empty_tbl(COLS$recibos))
  restaurar_respaldo(f); ok(nrow(read_tbl("recibos")) == n0, "respaldo y restauración")
})

# Compatibilidad con datos de la versión 1

writeLines('[{"id":"m1","casa_id":"c1","tipo":"Servicio","servicio":"Agua","fecha":"2026-02-01","monto":300,"concepto":"Agua","archivo":"x.jpg","archivo_tipo":"local","archivo_link":"","admin_email":"a@b.com","creado":"2026-02-01 10:00:00"}]', file.path(DATA_DIR, "recibos.json"))
writeLines('[{"email":"viejo@b.com","nombre":"Viejo"}]', file.path(DATA_DIR, "admins.json"))
r <- read_tbl("recibos"); a <- read_tbl("admins")
ok(r$categoria == "Agua" && a$id == "viejo@b.com", "lee datos de la versión 1 (recibos y administradores)")
cat("\nTODAS LAS PRUEBAS PASARON\n")
