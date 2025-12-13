# Menú Degustación - Sistema Integral de Gestión Gastronómica COMPLETO
# Versión ACTUALIZADA con modelo de costos fijos

library(shiny)
library(shinydashboard)
library(DT)
library(shinyWidgets)
library(ggplot2)
library(plotly)
library(dplyr)
library(tidyr)

# ============================================================================
# DATOS DE COSTOS COMPLETOS
# ============================================================================

costos_df <- data.frame(
  Platillo = c(
    rep("Dumplings de Camarones", 6),
    rep("Ensalada Shirazi", 6),
    rep("Sopa de Lentejas Turca", 7),
    rep("Falafel con Jocoque", 7),
    rep("Pollo al Tandoori", 10),
    rep("Pescado al Wok", 7),
    rep("Lokma", 5),
    rep("Kunafa", 5)
  ),
  Ingrediente = c(
    "Pasta para wonton", "Camarones sin cáscara", "Jengibre", "Cebollín", "Salsa de soya", "Aceite de ajonjolí",
    "Pepino persa", "Tomate bola", "Cebolla morada", "Menta fresca", "Limón", "Aceite de oliva",
    "Lentejas rojas", "Cebolla", "Zanahoria", "Mantequilla", "Caldo de pollo", "Tomate concentrado", "Menta seca",
    "Garbanzos secos", "Cilantro y perejil", "Cebolla blanca", "Comino", "Ajo", "Aceite para freír", "Jocoque",
    "Muslo de pollo", "Yogurt natural", "Pasta ajo-jengibre", "Garam Masala", "Pimentón ahumado", "Cúrcuma", "Comino", "Limón", "Aceite vegetal", "Arroz jazmín",
    "Filete tilapia", "Brócoli", "Zanahoria", "Pimiento morrón", "Salsa de soya", "Aceite vegetal", "Ajo y jengibre",
    "Harina de trigo", "Levadura seca", "Agua tibia", "Aceite para freír", "Miel",
    "Fideos Kunafa", "Mantequilla clarificada", "Queso dulce", "Jarabe de azúcar", "Pistachos"
  ),
  Cantidad_1_Porcion = c(
    4, 100, 2, 5, 5, 2,
    1, 1, 20, 5, 15, 10,
    50, 20, 20, 5, 250, 5, 1,
    50, 15, 15, 2, 3, 200, 30,
    200, 50, 5, 3, 2, 1, 1, 5, 5, 100,
    150, 50, 20, 20, 15, 10, 5,
    50, 2, 60, 200, 30,
    100, 50, 80, 50, 10
  ),
  Unidad = c(
    "piezas", "g", "g", "g", "ml", "ml",
    "pieza", "pieza", "g", "g", "ml", "ml",
    "g", "g", "g", "g", "ml", "g", "g",
    "g", "g", "g", "g", "g", "ml", "g",
    "g", "ml", "g", "g", "g", "g", "g", "ml", "ml", "g",
    "g", "g", "g", "g", "ml", "ml", "g",
    "g", "g", "ml", "ml", "ml",
    "g", "g", "g", "ml", "g"
  ),
  Costo_Porcion = c(
    4.0, 36.0, 1.0, 2.0, 1.6, 2.4,
    16.0, 10.0, 3.0, 4.0, 3.0, 6.0,
    7.0, 2.0, 2.0, 3.0, 10.0, 2.0, 1.0,
    5.0, 4.0, 2.0, 2.0, 1.0, 12.0, 16.0,
    56.0, 12.0, 4.0, 6.0, 4.0, 3.0, 1.0, 1.0, 1.0, 16.0,
    48.0, 6.0, 2.0, 4.0, 4.8, 2.0, 2.0,
    3.0, 2.0, 0.0, 12.0, 16.0,
    50.0, 30.0, 40.0, 6.0, 16.0
  ),
  stringsAsFactors = FALSE
)

# ============================================================================
# PARÁMETROS DE COSTOS FIJOS
# ============================================================================

# Costos fijos mensuales
RENTA_MENSUAL <- 40000
SALARIOS_MENSUAL <- 50000
ENERGIA_AGUA_MENSUAL <- 14000
COSTOS_FIJOS_TOTALES <- RENTA_MENSUAL + SALARIOS_MENSUAL + ENERGIA_AGUA_MENSUAL

# Estimación de comensales
COMENSALES_ESTIMADOS_MES <- 2000

# Costo fijo por comensal
COSTO_FIJO_POR_COMENSAL <- COSTOS_FIJOS_TOTALES / COMENSALES_ESTIMADOS_MES

# Margen de ganancia
MARGEN_GANANCIA <- 0.15  # 15%

# ============================================================================
# CÁLCULOS DE COSTOS CON NUEVO MODELO
# ============================================================================

# Calcular costos de materia prima por platillo
costos_por_platillo <- costos_df %>%
  group_by(Platillo) %>%
  summarise(
    Costo_Materia_Prima = round(sum(Costo_Porcion), 2),
    Num_Ingredientes = n()
  ) %>%
  mutate(
    # Costo fijo asignado por platillo (mismo para todos)
    Costo_Fijo_Asignado = round(COSTO_FIJO_POR_COMENSAL, 2),
    
    # Costo total del platillo (materia prima + costos fijos)
    Costo_Total_Platillo = round(Costo_Materia_Prima + Costo_Fijo_Asignado, 2),
    
    # Precio de venta con margen del 15%
    Precio_Venta = round(Costo_Total_Platillo * (1 + MARGEN_GANANCIA), 2),
    
    # Margen en pesos
    Margen_Pesos = round(Precio_Venta - Costo_Total_Platillo, 2),
    
    # Margen en porcentaje
    Margen_Porcentaje = round(MARGEN_GANANCIA * 100, 1),
    
    # Food Cost % (materia prima / precio venta)
    Food_Cost_Pct = round((Costo_Materia_Prima / Precio_Venta) * 100, 1),
    
    # Costo Total % (incluye costos fijos)
    Costo_Total_Pct = round((Costo_Total_Platillo / Precio_Venta) * 100, 1)
  )

# Totales del menú completo (8 platillos)
costo_materia_prima_menu <- sum(costos_por_platillo$Costo_Materia_Prima)
costo_fijos_menu <- sum(costos_por_platillo$Costo_Fijo_Asignado)
costo_total_menu <- sum(costos_por_platillo$Costo_Total_Platillo)
precio_total_menu <- sum(costos_por_platillo$Precio_Venta)
margen_total_menu_pesos <- sum(costos_por_platillo$Margen_Pesos)
margen_total_menu_pct <- round((margen_total_menu_pesos / precio_total_menu) * 100, 1)

# ============================================================================
# UI
# ============================================================================

ui <- dashboardPage(
  dashboardHeader(title = "Menú Ruta de la Seda"),
  
  dashboardSidebar(
    div(
      style = "padding: 20px 15px; text-align: center; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); margin-bottom: 10px; border-radius: 8px; margin: 10px;",
      h3("Sarai Mazu", style = "color: #ffffff; margin: 0; font-weight: bold; text-shadow: 2px 2px 4px rgba(0,0,0,0.3);"),
      p("Metodología Gastronómica", style = "color: #e0e7ff; margin: 5px 0 0 0; font-size: 12px;")
    ),
    sidebarMenu(
      menuItem("Menú Degustación", tabName = "menu", icon = icon("utensils")),
      menuItem("Estructura de Costos", tabName = "estructura_costos", icon = icon("calculator")),
      menuItem("Tabla de Costos Completa", tabName = "costos_tabla", icon = icon("table")),
      menuItem("Resumen por Platillo", tabName = "resumen", icon = icon("chart-pie")),
      menuItem("Recetas Estandarizadas", tabName = "recetas", icon = icon("book")),
      menuItem("Análisis Rentabilidad", tabName = "rentabilidad", icon = icon("chart-line")),
      menuItem("Control HACCP", tabName = "haccp", icon = icon("shield-alt")),
      menuItem("Planeación Estratégica", tabName = "planeacion", icon = icon("chess")),
      menuItem("Control de Desviaciones", tabName = "control", icon = icon("clipboard-check")),
      menuItem("Mejora Continua", tabName = "mejora", icon = icon("sync-alt")),
      menuItem("Bitácoras", tabName = "bitacoras", icon = icon("list-alt"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .skin-blue .main-header .navbar {
          background: linear-gradient(90deg, #1e3c72 0%, #2a5298 50%, #4a90e2 100%) !important;
        }
        .skin-blue .main-sidebar {
          background: linear-gradient(180deg, #0a1128 0%, #1e3c72 50%, #2a5298 100%) !important;
        }
        .content-wrapper { 
          background: linear-gradient(135deg, #0a1128 0%, #1a2744 100%) !important; 
        }
        .box { 
          background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%) !important; 
          border: 2px solid #4a90e2 !important; 
          border-radius: 12px !important; 
        }
        .box-body { 
          background: linear-gradient(135deg, #0f1f3f 0%, #1a2f5a 100%) !important; 
          color: #e0e7ff !important; 
          padding: 20px !important;
        }
        p { color: #c7d2fe !important; line-height: 1.7 !important; }
        strong { color: #7ec8e3 !important; font-weight: 600; }
        h3, h4, h5, h6 { color: #ffffff !important; }
        .alert-info { 
          background: linear-gradient(135deg, #2a5298 0%, #4a90e2 100%); 
          border: 2px solid #7ec8e3; 
          color: #fff; 
          padding: 20px; 
          border-radius: 8px; 
          margin: 15px 0;
        }
        .calculo-box {
          background: linear-gradient(135deg, #1a2f5a 0%, #2a4070 100%);
          border: 2px solid #667eea;
          border-radius: 8px;
          padding: 20px;
          margin-top: 20px;
        }
        .calculo-box h5 {
          color: #7ec8e3 !important;
          border-bottom: 2px solid #4a90e2;
          padding-bottom: 10px;
          margin-bottom: 15px;
        }
        .formula {
          background: #0a1128;
          padding: 10px;
          border-left: 4px solid #667eea;
          margin: 10px 0;
          font-family: monospace;
        }
        table.dataTable { 
          background: linear-gradient(135deg, #1a2f5a 0%, #2a4070 100%) !important; 
          color: #e0e7ff !important; 
        }
        table.dataTable thead th { 
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; 
          color: #ffffff !important; 
          border-bottom: 2px solid #4a90e2 !important;
        }
        table.dataTable tbody tr {
          background: linear-gradient(135deg, #1a2f5a 0%, #2a4070 100%) !important;
          color: #e0e7ff !important;
        }
        table.dataTable tbody tr:hover {
          background: linear-gradient(135deg, #2a5298 0%, #4a90e2 100%) !important;
        }
      "))
    ),
    
    tabItems(
      # ========================================================================
      # TAB 1: MENÚ DEGUSTACIÓN
      # ========================================================================
      tabItem(tabName = "menu",
              fluidRow(
                box(width = 12, title = "Odisea Culinaria... De Persia a Cantón", 
                    status = "primary", solidHeader = TRUE,
                    h4("Un Recorrido por la Ruta de la Seda"),
                    h5("Menú Degustación de 8 Tiempos"),
                    p(strong("Costo Total del Menú (Materia Prima + Costos Fijos):"), " $", round(costo_total_menu, 2), " MXN"),
                    p(strong("Precio de Venta:"), " $", round(precio_total_menu, 2), " MXN"),
                    p(strong("Margen de Ganancia:"), " 15%"))
              ),
              fluidRow(
                column(4, box(width = 12, title = "1. Dumplings de Camarones", status = "info",
                              p(strong("Origen:"), " China / Cantón"),
                              p(strong("Método:"), " Vapor"),
                              p(strong("Costo Total:"), " $", costos_por_platillo$Costo_Total_Platillo[1]),
                              p(strong("Precio:"), " $", costos_por_platillo$Precio_Venta[1]))),
                column(4, box(width = 12, title = "2. Ensalada Shirazi", status = "info",
                              p(strong("Origen:"), " Irán / Shiraz"),
                              p(strong("Método:"), " Fresco"),
                              p(strong("Costo Total:"), " $", costos_por_platillo$Costo_Total_Platillo[2]),
                              p(strong("Precio:"), " $", costos_por_platillo$Precio_Venta[2]))),
                column(4, box(width = 12, title = "3. Sopa de Lentejas Turca", status = "info",
                              p(strong("Origen:"), " Turquía"),
                              p(strong("Método:"), " Hervido"),
                              p(strong("Costo Total:"), " $", costos_por_platillo$Costo_Total_Platillo[3]),
                              p(strong("Precio:"), " $", costos_por_platillo$Precio_Venta[3])))
              ),
              fluidRow(
                column(4, box(width = 12, title = "4. Falafel con Jocoque", status = "info",
                              p(strong("Origen:"), " Egipto"),
                              p(strong("Método:"), " Fritura"),
                              p(strong("Costo Total:"), " $", costos_por_platillo$Costo_Total_Platillo[4]),
                              p(strong("Precio:"), " $", costos_por_platillo$Precio_Venta[4]))),
                column(4, box(width = 12, title = "5. Pollo al Tandoori", status = "info",
                              p(strong("Origen:"), " India"),
                              p(strong("Método:"), " Tandoor"),
                              p(strong("Costo Total:"), " $", costos_por_platillo$Costo_Total_Platillo[5]),
                              p(strong("Precio:"), " $", costos_por_platillo$Precio_Venta[5]))),
                column(4, box(width = 12, title = "6. Pescado al Wok", status = "info",
                              p(strong("Origen:"), " Tailandia"),
                              p(strong("Método:"), " Salteado"),
                              p(strong("Costo Total:"), " $", costos_por_platillo$Costo_Total_Platillo[6]),
                              p(strong("Precio:"), " $", costos_por_platillo$Precio_Venta[6])))
              ),
              fluidRow(
                column(6, box(width = 12, title = "7. Lokma", status = "info",
                              p(strong("Origen:"), " Turquía"),
                              p(strong("Método:"), " Confitado"),
                              p(strong("Costo Total:"), " $", costos_por_platillo$Costo_Total_Platillo[7]),
                              p(strong("Precio:"), " $", costos_por_platillo$Precio_Venta[7]))),
                column(6, box(width = 12, title = "8. Kunafa", status = "info",
                              p(strong("Origen:"), " Arabia Saudita"),
                              p(strong("Método:"), " Horneado"),
                              p(strong("Costo Total:"), " $", costos_por_platillo$Costo_Total_Platillo[8]),
                              p(strong("Precio:"), " $", costos_por_platillo$Precio_Venta[8])))
              )
      ),
      
      # ========================================================================
      # TAB 2: ESTRUCTURA DE COSTOS (NUEVO)
      # ========================================================================
      tabItem(tabName = "estructura_costos",
              fluidRow(
                box(width = 12, title = "Estructura de Costos del Restaurante", 
                    status = "primary", solidHeader = TRUE,
                    h4("Modelo de Costos Fijos y Variables"))
              ),
              fluidRow(
                valueBoxOutput("vb_costos_fijos_totales", width = 3),
                valueBoxOutput("vb_comensales_mes", width = 3),
                valueBoxOutput("vb_costo_fijo_comensal", width = 3),
                valueBoxOutput("vb_margen_ganancia", width = 3)
              ),
              fluidRow(
                box(width = 6, title = "Desglose de Costos Fijos Mensuales", status = "info",
                    div(class = "calculo-box",
                        p(strong("Renta del Local:"), " $", format(RENTA_MENSUAL, big.mark = ",")),
                        p(strong("Salarios del Personal:"), " $", format(SALARIOS_MENSUAL, big.mark = ",")),
                        p(strong("Energía y Agua:"), " $", format(ENERGIA_AGUA_MENSUAL, big.mark = ",")),
                        hr(),
                        h5("Total Costos Fijos Mensuales:"),
                        h3(paste0("$", format(COSTOS_FIJOS_TOTALES, big.mark = ",")), 
                           style = "color: #7ec8e3; text-align: center;")
                    )),
                box(width = 6, title = "Distribución de Costos Fijos", status = "success",
                    plotlyOutput("grafico_costos_fijos", height = "300px"))
              ),
              fluidRow(
                box(width = 12, title = "Metodología de Cálculo de Precios", status = "warning",
                    div(class = "calculo-box",
                        h5("Fórmula de Cálculo de Precio de Venta"),
                        p(strong("Paso 1: Calcular Costo Fijo por Comensal")),
                        div(class = "formula",
                            paste0("Costo Fijo por Comensal = $", format(COSTOS_FIJOS_TOTALES, big.mark = ","), 
                                   " ÷ ", COMENSALES_ESTIMADOS_MES, " = $", round(COSTO_FIJO_POR_COMENSAL, 2))
                        ),
                        hr(),
                        p(strong("Paso 2: Calcular Costo Total del Platillo")),
                        div(class = "formula",
                            "Costo Total = Costo Materia Prima + Costo Fijo Asignado"
                        ),
                        p("Ejemplo: Dumplings = $", costos_por_platillo$Costo_Materia_Prima[1], 
                          " + $", round(COSTO_FIJO_POR_COMENSAL, 2), 
                          " = $", costos_por_platillo$Costo_Total_Platillo[1]),
                        hr(),
                        p(strong("Paso 3: Aplicar Margen de Ganancia")),
                        div(class = "formula",
                            paste0("Precio Venta = Costo Total × (1 + ", MARGEN_GANANCIA * 100, "%)")
                        ),
                        p("Ejemplo: Dumplings = $", costos_por_platillo$Costo_Total_Platillo[1], 
                          " × 1.15 = $", costos_por_platillo$Precio_Venta[1]),
                        hr(),
                        p(strong("Nota:"), " Este modelo asegura que todos los costos fijos del restaurante 
                          se distribuyen proporcionalmente entre los comensales y se incluyen en el precio de venta.")
                    ))
              ),
              fluidRow(
                box(width = 12, title = "Comparativo: Costo vs Precio por Platillo", status = "info",
                    plotlyOutput("grafico_comparativo_costos", height = "400px"))
              )
      ),
      
      # ========================================================================
      # TAB 3: TABLA DE COSTOS COMPLETA
      # ========================================================================
      tabItem(tabName = "costos_tabla",
              fluidRow(
                box(width = 12, title = "Tabla Completa de Costos por Ingrediente", 
                    status = "primary", solidHeader = TRUE,
                    div(class = "alert-info",
                        h4(icon("info-circle"), " Información sobre los Costos de Materia Prima"),
                        p(strong("Total de ingredientes:"), " ", nrow(costos_df)),
                        p(strong("Costo total de materia prima del menú:"), " $", round(costo_materia_prima_menu, 2), " MXN"),
                        p(strong("Costos fijos asignados al menú:"), " $", round(costo_fijos_menu, 2), " MXN"),
                        p(strong("Costo total del menú:"), " $", round(costo_total_menu, 2), " MXN")
                    ))
              ),
              fluidRow(
                box(width = 12, title = "Desglose Completo de Ingredientes", status = "info",
                    DT::dataTableOutput("tabla_costos_completa"))
              ),
              fluidRow(
                valueBoxOutput("vb_total_ingredientes", width = 3),
                valueBoxOutput("vb_costo_ingredientes_total", width = 3),
                valueBoxOutput("vb_num_platillos", width = 3),
                valueBoxOutput("vb_costo_promedio_ingr", width = 3)
              )
      ),
      
      # ========================================================================
      # TAB 4: RESUMEN POR PLATILLO
      # ========================================================================
      tabItem(tabName = "resumen",
              fluidRow(
                box(width = 12, title = "Análisis Detallado de Costos por Platillo", 
                    status = "primary", solidHeader = TRUE,
                    selectInput("platillo_select", "Seleccionar Platillo:",
                                choices = unique(costos_df$Platillo)))
              ),
              fluidRow(
                valueBoxOutput("vb_costo_mp_platillo", width = 3),
                valueBoxOutput("vb_costo_total_platillo", width = 3),
                valueBoxOutput("vb_precio_platillo", width = 3),
                valueBoxOutput("vb_margen_platillo", width = 3)
              ),
              fluidRow(
                box(width = 6, title = "Ingredientes del Platillo Seleccionado", status = "info",
                    DT::dataTableOutput("tabla_ingredientes_platillo")),
                box(width = 6, title = "Distribución de Costos", status = "success",
                    plotlyOutput("grafico_desglose_platillo", height = "400px"))
              ),
              fluidRow(
                box(width = 12, title = "Resumen Comparativo de Todos los Platillos", status = "warning",
                    DT::dataTableOutput("tabla_resumen_platillos"))
              ),
              fluidRow(
                box(width = 12, title = "Detalle de Cálculos del Platillo Seleccionado", status = "info",
                    uiOutput("detalle_calculos_platillo"))
              )
      ),
      
      # ========================================================================
      # TAB 5: RECETAS ESTANDARIZADAS
      # ========================================================================
      tabItem(tabName = "recetas",
              fluidRow(
                box(width = 12, title = "Recetas Estandarizadas con Escalado de Porciones", 
                    status = "primary", solidHeader = TRUE,
                    selectInput("receta_select", "Seleccionar Platillo:", 
                                choices = unique(costos_df$Platillo)),
                    numericInput("num_porciones", "Número de Porciones:", 
                                 value = 4, min = 1, max = 50, step = 1))
              ),
              fluidRow(
                box(width = 6, title = "Ingredientes Escalados", status = "info",
                    DT::dataTableOutput("tabla_receta_escalada")),
                box(width = 6, title = "Resumen de Costos", status = "success",
                    h3(textOutput("costo_receta_escalada"), 
                       style = "color: #7ec8e3; text-align: center; font-size: 36px;"),
                    p("Costo Total de Materia Prima", 
                      style = "text-align: center; font-size: 14px;"),
                    hr(),
                    uiOutput("info_receta_detalle"))
              ),
              fluidRow(
                box(width = 12, title = "Detalle de Cálculos de Escalado", status = "warning",
                    uiOutput("detalle_calculos_receta"))
              )
      ),
      
      # ========================================================================
      # TAB 6: ANÁLISIS DE RENTABILIDAD
      # ========================================================================
      tabItem(tabName = "rentabilidad",
              fluidRow(
                box(width = 12, title = "Análisis Financiero Completo del Menú", 
                    status = "primary", solidHeader = TRUE,
                    p("Análisis de costos, precios, márgenes y proyecciones financieras"))
              ),
              fluidRow(
                valueBoxOutput("vb_costo_menu_rent", width = 3),
                valueBoxOutput("vb_precio_menu_rent", width = 3),
                valueBoxOutput("vb_margen_menu_rent", width = 3),
                valueBoxOutput("vb_utilidad_menu", width = 3)
              ),
              fluidRow(
                box(width = 6, title = "Comparativo: Costo vs Precio de Venta", status = "info",
                    plotlyOutput("grafico_costo_precio", height = "400px")),
                box(width = 6, title = "Contribución al Margen Total", status = "success",
                    plotlyOutput("grafico_margenes", height = "400px"))
              ),
              fluidRow(
                box(width = 4, title = "Punto de Equilibrio", status = "warning",
                    h3(textOutput("punto_equilibrio"), 
                       style = "color: #7ec8e3; text-align: center; font-size: 48px;"),
                    p("Comensales por mes para cubrir gastos fijos", 
                      style = "text-align: center; font-size: 12px;"),
                    hr(),
                    p(strong("Gastos Fijos Mensuales:"), " $", format(COSTOS_FIJOS_TOTALES, big.mark = ",")),
                    p(strong("Margen por Menú:"), textOutput("margen_unitario_text", inline = TRUE))),
                box(width = 4, title = paste0("Proyección: ", COMENSALES_ESTIMADOS_MES, " Comensales/Mes"), status = "info",
                    h3(textOutput("utilidad_proyectada"), 
                       style = "color: #7ec8e3; text-align: center; font-size: 48px;"),
                    p("Utilidad Mensual Proyectada", 
                      style = "text-align: center; font-size: 12px;"),
                    hr(),
                    p(strong("Ingresos Totales:"), textOutput("ingresos_proyectados", inline = TRUE)),
                    p(strong("ROI:"), textOutput("roi_proyectado", inline = TRUE))),
                box(width = 4, title = "Food Cost por Platillo", status = "success",
                    plotlyOutput("grafico_food_cost", height = "250px"))
              ),
              fluidRow(
                box(width = 12, title = "Tabla de Análisis Financiero Detallado", status = "primary",
                    DT::dataTableOutput("tabla_analisis_financiero"))
              )
      ),
      
      # ========================================================================
      # TAB 7: CONTROL HACCP
      # ========================================================================
      tabItem(tabName = "haccp",
              fluidRow(
                box(width = 12, title = "Sistema HACCP - Análisis de Peligros y Puntos Críticos", 
                    status = "primary", solidHeader = TRUE,
                    p("Sistema de control para garantizar la inocuidad alimentaria en todas las etapas"))
              ),
              fluidRow(
                box(width = 12, title = "Temperaturas Críticas de Cocción", status = "warning",
                    DT::dataTableOutput("tabla_haccp"))
              ),
              fluidRow(
                box(width = 6, title = "Medidas Preventivas", status = "info",
                    h5("Control de Temperaturas", style = "color: #7ec8e3;"),
                    p("• Zona de Peligro: 4°C - 60°C"),
                    p("• Refrigeración: 0°C - 4°C"),
                    p("• Congelación: -18°C o menos"),
                    p("• Servicio Caliente: >60°C"),
                    hr(),
                    h5("Prevención de Contaminación Cruzada", style = "color: #7ec8e3;"),
                    p("• Usar tablas de corte por colores"),
                    p("• Separar alimentos crudos de cocidos"),
                    p("• Lavado de manos frecuente"),
                    p("• Desinfección de superficies")),
                box(width = 6, title = "Código de Colores para Tablas", status = "success",
                    p(strong("AMARILLO:"), " Aves (74°C)"),
                    p(strong("AZUL:"), " Pescados y Mariscos (63°C)"),
                    p(strong("ROJO:"), " Carnes rojas"),
                    p(strong("VERDE:"), " Frutas y Verduras"),
                    p(strong("BLANCO:"), " Lácteos y Panadería"),
                    p(strong("CAFÉ:"), " Alimentos Cocidos"))
              ),
              fluidRow(
                box(width = 12, title = "Aplicación HACCP en el Menú", status = "info",
                    div(class = "calculo-box",
                        h5("Puntos Críticos de Control por Platillo"),
                        p(strong("Dumplings de Camarones:"), " Cocción al vapor - Camarones deben alcanzar 63°C internamente"),
                        p(strong("Pollo al Tandoori:"), " Cocción en horno - Pollo debe alcanzar 74°C internamente"),
                        p(strong("Pescado al Wok:"), " Salteado rápido - Pescado debe alcanzar 63°C internamente"),
                        p(strong("Falafel:"), " Fritura profunda - Temperatura de aceite: 180°C, tiempo: 3-4 min"),
                        hr(),
                        p(strong("Verificación:"), " Usar termómetro digital calibrado"),
                        p(strong("Registro:"), " Documentar temperaturas en bitácora diaria"),
                        p(strong("Acción Correctiva:"), " Si temperatura insuficiente, continuar cocción hasta alcanzar temperatura segura")
                    ))
              )
      ),
      
      # ========================================================================
      # TAB 8: PLANEACIÓN ESTRATÉGICA
      # ========================================================================
      tabItem(tabName = "planeacion",
              fluidRow(
                box(width = 4, title = "Misión", status = "info",
                    p("Ofrecer experiencias gastronómicas auténticas e innovadoras que celebren el patrimonio culinario de la Ruta de la Seda, garantizando calidad, seguridad alimentaria y excelencia en el servicio.")),
                box(width = 4, title = "Visión", status = "success",
                    p("Ser el restaurante referente en cocina internacional de México, reconocido por autenticidad, innovación y compromiso con la excelencia operativa.")),
                box(width = 4, title = "Valores", status = "warning",
                    p("• Calidad en ingredientes y preparación"),
                    p("• Seguridad alimentaria (HACCP)"),
                    p("• Autenticidad cultural"),
                    p("• Innovación continua"),
                    p("• Excelencia en servicio"))
              ),
              fluidRow(
                box(width = 12, title = "Objetivos SMART", status = "primary",
                    DT::dataTableOutput("tabla_objetivos"))
              ),
              fluidRow(
                box(width = 12, title = "Estrategias Clave", status = "info",
                    div(class = "calculo-box",
                        h5("4 Pilares Estratégicos"),
                        p(strong("1. Diferenciación por Calidad:")),
                        p("• Implementación completa HACCP"),
                        p("• Certificaciones de calidad"),
                        p("• Capacitación continua"),
                        hr(),
                        p(strong("2. Excelencia en Servicio:")),
                        p("• Experiencia gastronómica memorable"),
                        p("• Programa de fidelización"),
                        p("• Retroalimentación continua"),
                        hr(),
                        p(strong("3. Optimización Operativa:")),
                        p("• Estandarización de recetas"),
                        p("• Control riguroso de costos"),
                        p("• Reducción de merma al 10%"),
                        hr(),
                        p(strong("4. Sostenibilidad:")),
                        p("• Proveedores locales"),
                        p("• Reducción de huella ambiental"),
                        p("• Responsabilidad social")
                    ))
              )
      ),
      
      # ========================================================================
      # TAB 9: CONTROL DE DESVIACIONES
      # ========================================================================
      tabItem(tabName = "control",
              fluidRow(
                box(width = 12, title = "Sistema de Control de Desviaciones", 
                    status = "primary", solidHeader = TRUE,
                    p("Loop de Control: MEDIR → COMPARAR → ANALIZAR → CORREGIR"))
              ),
              fluidRow(
                box(width = 6, title = "Checklist de Recepción", status = "info",
                    checkboxInput("c1", "Verificar temperatura del producto", FALSE),
                    checkboxInput("c2", "Revisar integridad del empaque", FALSE),
                    checkboxInput("c3", "Verificar etiqueta y caducidad", FALSE),
                    checkboxInput("c4", "Confirmar proveedor autorizado", FALSE),
                    checkboxInput("c5", "Inspección visual de calidad", FALSE),
                    hr(),
                    actionButton("guardar_check", "Guardar Registro", class = "btn-success")),
                box(width = 6, title = "Acciones Correctivas", status = "warning",
                    h5("Temperatura Incorrecta en Recepción", style = "color: #7ec8e3;"),
                    p(strong("Acción:"), " Rechazar producto"),
                    p(strong("Registro:"), " Documentar en bitácora"),
                    p(strong("Seguimiento:"), " Contactar proveedor"),
                    hr(),
                    h5("Merma Excesiva", style = "color: #7ec8e3;"),
                    p(strong("Acción:"), " Analizar causa raíz"),
                    p(strong("Registro:"), " Cuantificar pérdida"),
                    p(strong("Prevención:"), " Capacitación en aprovechamiento"))
              )
      ),
      
      # ========================================================================
      # TAB 10: MEJORA CONTINUA
      # ========================================================================
      tabItem(tabName = "mejora",
              fluidRow(
                box(width = 12, title = "Ciclo PDCA de Deming", status = "primary",
                    p("Ciclo de Mejora Continua: Plan → Do → Check → Act"))
              ),
              fluidRow(
                box(width = 3, title = "Plan (Planificar)", status = "info",
                    p("• Identificar oportunidades"),
                    p("• Analizar datos"),
                    p("• Definir objetivos SMART"),
                    p("• Establecer plan de acción")),
                box(width = 3, title = "Do (Hacer)", status = "success",
                    p("• Implementar cambios"),
                    p("• Capacitar personal"),
                    p("• Proveer recursos"),
                    p("• Comunicar claramente")),
                box(width = 3, title = "Check (Verificar)", status = "warning",
                    p("• Medir KPIs"),
                    p("• Documentar resultados"),
                    p("• Comparar con objetivos"),
                    p("• Identificar desviaciones")),
                box(width = 3, title = "Act (Actuar)", status = "primary",
                    p("• Estandarizar mejoras"),
                    p("• Actualizar procedimientos"),
                    p("• Extender a todo el equipo"),
                    p("• Reiniciar ciclo"))
              ),
              fluidRow(
                box(width = 12, title = "Ejemplo Práctico de Mejora Continua", status = "info",
                    div(class = "calculo-box",
                        h5("Proyecto: Reducción de Merma en 15%"),
                        p(strong("PLAN:"), " Objetivo SMART - Reducir merma de ingredientes del 12% al 10% en 3 meses mediante control de porciones"),
                        p(strong("DO:"), " Implementar pesaje preciso, capacitación en técnicas de corte, aprovechamiento de restos en caldos"),
                        p(strong("CHECK:"), " Después de 1 mes: merma redujo a 11%. Después de 2 meses: 10.5%. Meta: 10%"),
                        p(strong("ACT:"), " Al alcanzar 10%, estandarizar procedimientos, actualizar recetas, capacitar a nuevo personal. Nuevo objetivo: 8%"),
                        hr(),
                        p(strong("Impacto Financiero:")),
                        p("Reducción de 2% en merma sobre $", round(costo_materia_prima_menu, 2), 
                          " = Ahorro mensual de $", round(costo_materia_prima_menu * 0.02 * COMENSALES_ESTIMADOS_MES / 8, 2), 
                          " (asumiendo ", COMENSALES_ESTIMADOS_MES, " comensales/mes)")
                    ))
              )
      ),
      
      # ========================================================================
      # TAB 11: BITÁCORAS
      # ========================================================================
      tabItem(tabName = "bitacoras",
              fluidRow(
                box(width = 12, title = "Sistema de Bitácoras y Trazabilidad", 
                    status = "primary", solidHeader = TRUE,
                    p("Registro sistemático para garantizar control de calidad y trazabilidad"))
              ),
              fluidRow(
                box(width = 12, title = "Bitácora de Recepción de Productos", status = "info",
                    fluidRow(
                      column(3, dateInput("fecha_bit", "Fecha:", value = Sys.Date())),
                      column(3, selectInput("producto_bit", "Producto:", 
                                            choices = c("Pollo", "Pescado", "Camarones", "Verduras", "Lácteos"))),
                      column(3, textInput("proveedor_bit", "Proveedor:")),
                      column(3, numericInput("temp_bit", "Temperatura °C:", value = 4))
                    ),
                    fluidRow(
                      column(6, selectInput("cumple_bit", "¿Cumple estándares?", 
                                            choices = c("Sí", "No"))),
                      column(6, actionButton("guardar_bit", "Guardar Registro", 
                                             class = "btn-success", style = "margin-top: 25px; width: 100%;"))
                    ),
                    hr(),
                    h5("Registros Recientes", style = "color: #7ec8e3;"),
                    DT::dataTableOutput("tabla_bitacora"))
              ),
              fluidRow(
                box(width = 12, title = "Importancia de las Bitácoras", status = "warning",
                    div(class = "calculo-box",
                        h5("Propósito de los Registros"),
                        p(strong("Trazabilidad:"), " Rastrear origen de ingredientes en caso de incidente"),
                        p(strong("Cumplimiento:"), " Demostrar cumplimiento de normativas de seguridad"),
                        p(strong("Mejora:"), " Analizar tendencias y identificar proveedores problemáticos"),
                        p(strong("Legal:"), " Protección legal en caso de auditorías o reclamos"),
                        hr(),
                        p(strong("Frecuencia de Registro:"), " Cada recepción de productos"),
                        p(strong("Retención:"), " Mínimo 6 meses, recomendado 2 años"),
                        p(strong("Responsable:"), " Encargado de almacén / Chef de cocina")
                    ))
              )
      )
    )
  )
)

# ============================================================================
# SERVER
# ============================================================================

server <- function(input, output, session) {
  
  # ========================================================================
  # TAB: ESTRUCTURA DE COSTOS
  # ========================================================================
  
  output$vb_costos_fijos_totales <- renderValueBox({
    valueBox(paste0("$", format(COSTOS_FIJOS_TOTALES, big.mark = ",")), 
             "Costos Fijos Mensuales", icon = icon("building"), color = "red")
  })
  
  output$vb_comensales_mes <- renderValueBox({
    valueBox(format(COMENSALES_ESTIMADOS_MES, big.mark = ","), 
             "Comensales/Mes", icon = icon("users"), color = "blue")
  })
  
  output$vb_costo_fijo_comensal <- renderValueBox({
    valueBox(paste0("$", round(COSTO_FIJO_POR_COMENSAL, 2)), 
             "Costo Fijo/Comensal", icon = icon("user"), color = "purple")
  })
  
  output$vb_margen_ganancia <- renderValueBox({
    valueBox(paste0(MARGEN_GANANCIA * 100, "%"), 
             "Margen de Ganancia", icon = icon("percent"), color = "green")
  })
  
  output$grafico_costos_fijos <- renderPlotly({
    df <- data.frame(
      Concepto = c("Renta", "Salarios", "Energía y Agua"),
      Monto = c(RENTA_MENSUAL, SALARIOS_MENSUAL, ENERGIA_AGUA_MENSUAL)
    )
    
    plot_ly(df, labels = ~Concepto, values = ~Monto, type = 'pie',
            marker = list(colors = c('#e74c3c', '#f39c12', '#3498db')),
            textinfo = 'label+value+percent',
            textposition = 'inside') %>%
      layout(paper_bgcolor = '#1a2f5a', 
             plot_bgcolor = '#1a2f5a',
             font = list(color = '#ffffff'),
             showlegend = TRUE)
  })
  
  output$grafico_comparativo_costos <- renderPlotly({
    df <- costos_por_platillo %>%
      select(Platillo, Costo_Materia_Prima, Costo_Fijo_Asignado, Precio_Venta) %>%
      pivot_longer(cols = c(Costo_Materia_Prima, Costo_Fijo_Asignado, Precio_Venta), 
                   names_to = "Tipo", values_to = "Valor")
    
    df$Tipo <- factor(df$Tipo, 
                      levels = c("Costo_Materia_Prima", "Costo_Fijo_Asignado", "Precio_Venta"),
                      labels = c("Materia Prima", "Costos Fijos", "Precio Venta"))
    
    plot_ly(df, x = ~Platillo, y = ~Valor, color = ~Tipo, type = 'bar',
            colors = c('#3498db', '#e74c3c', '#2ecc71')) %>%
      layout(xaxis = list(title = "", tickangle = -45),
             yaxis = list(title = "Monto (MXN)"),
             barmode = 'group',
             paper_bgcolor = '#1a2f5a',
             plot_bgcolor = '#1a2f5a',
             font = list(color = '#ffffff'),
             legend = list(title = list(text = '')))
  })
  
  # ========================================================================
  # TAB: TABLA DE COSTOS COMPLETA
  # ========================================================================
  
  output$tabla_costos_completa <- DT::renderDataTable({
    tabla <- costos_df %>%
      mutate(
        Costo_Porcion = paste0("$", format(round(Costo_Porcion, 2), nsmall = 2))
      ) %>%
      select(Platillo, Ingrediente, Cantidad_1_Porcion, Unidad, Costo_Porcion)
    
    DT::datatable(tabla, 
                  options = list(pageLength = 20, scrollX = TRUE, scrollY = "500px"),
                  rownames = FALSE,
                  colnames = c("Platillo", "Ingrediente", "Cantidad", "Unidad", "Costo/Porción"))
  })
  
  output$vb_total_ingredientes <- renderValueBox({
    valueBox(nrow(costos_df), "Total Ingredientes", icon = icon("leaf"), color = "green")
  })
  
  output$vb_costo_ingredientes_total <- renderValueBox({
    valueBox(paste0("$", round(costo_materia_prima_menu, 2)), 
             "Costo Materia Prima", icon = icon("shopping-cart"), color = "blue")
  })
  
  output$vb_num_platillos <- renderValueBox({
    valueBox(nrow(costos_por_platillo), "Platillos", icon = icon("utensils"), color = "purple")
  })
  
  output$vb_costo_promedio_ingr <- renderValueBox({
    promedio <- mean(costos_df$Costo_Porcion)
    valueBox(paste0("$", round(promedio, 2)), 
             "Costo Promedio/Ingrediente", icon = icon("calculator"), color = "orange")
  })
  
  # ========================================================================
  # TAB: RESUMEN POR PLATILLO
  # ========================================================================
  
  platillo_data <- reactive({
    costos_por_platillo %>% filter(Platillo == input$platillo_select)
  })
  
  output$vb_costo_mp_platillo <- renderValueBox({
    valueBox(paste0("$", platillo_data()$Costo_Materia_Prima), 
             "Materia Prima", icon = icon("carrot"), color = "green")
  })
  
  output$vb_costo_total_platillo <- renderValueBox({
    valueBox(paste0("$", platillo_data()$Costo_Total_Platillo), 
             "Costo Total", icon = icon("calculator"), color = "red")
  })
  
  output$vb_precio_platillo <- renderValueBox({
    valueBox(paste0("$", platillo_data()$Precio_Venta), 
             "Precio Venta", icon = icon("tag"), color = "blue")
  })
  
  output$vb_margen_platillo <- renderValueBox({
    valueBox(paste0(platillo_data()$Margen_Porcentaje, "%"), 
             "Margen", icon = icon("chart-line"), color = "purple")
  })
  
  output$tabla_ingredientes_platillo <- DT::renderDataTable({
    tabla <- costos_df %>%
      filter(Platillo == input$platillo_select) %>%
      mutate(Costo_Porcion = paste0("$", round(Costo_Porcion, 2))) %>%
      select(Ingrediente, Cantidad_1_Porcion, Unidad, Costo_Porcion)
    
    DT::datatable(tabla, 
                  options = list(pageLength = 15, dom = 't'),
                  rownames = FALSE,
                  colnames = c("Ingrediente", "Cantidad", "Unidad", "Costo"))
  })
  
  output$grafico_desglose_platillo <- renderPlotly({
    datos <- platillo_data()
    df <- data.frame(
      Categoria = c("Materia Prima", "Costos Fijos", "Margen Ganancia"),
      Monto = c(datos$Costo_Materia_Prima, 
                datos$Costo_Fijo_Asignado, 
                datos$Margen_Pesos)
    )
    
    plot_ly(df, labels = ~Categoria, values = ~Monto, type = 'pie',
            marker = list(colors = c('#3498db', '#e74c3c', '#2ecc71')),
            textinfo = 'label+value+percent',
            textposition = 'inside') %>%
      layout(paper_bgcolor = '#1a2f5a', 
             plot_bgcolor = '#1a2f5a',
             font = list(color = '#ffffff'),
             showlegend = TRUE)
  })
  
  output$tabla_resumen_platillos <- DT::renderDataTable({
    tabla <- costos_por_platillo %>%
      mutate(
        Costo_Materia_Prima = paste0("$", round(Costo_Materia_Prima, 2)),
        Costo_Total_Platillo = paste0("$", round(Costo_Total_Platillo, 2)),
        Precio_Venta = paste0("$", round(Precio_Venta, 2)),
        Margen_Pesos = paste0("$", round(Margen_Pesos, 2))
      ) %>%
      select(Platillo, Costo_Materia_Prima, Costo_Total_Platillo, Precio_Venta, 
             Margen_Porcentaje, Food_Cost_Pct)
    
    DT::datatable(tabla, 
                  options = list(pageLength = 10),
                  rownames = FALSE,
                  colnames = c("Platillo", "MP", "Costo Total", 
                               "Precio", "Margen %", "Food Cost %"))
  })
  
  output$detalle_calculos_platillo <- renderUI({
    datos <- platillo_data()
    
    food_cost_status <- if(datos$Food_Cost_Pct <= 35) {
      "✓ ÓPTIMO"
    } else {
      "⚠ REVISAR"
    }
    
    div(class = "calculo-box",
        h5("Cálculos Detallados del Platillo: ", input$platillo_select),
        p(strong("Paso 1: Costo de Materia Prima")),
        p("Suma de todos los costos de ingredientes = $", round(datos$Costo_Materia_Prima, 2)),
        hr(),
        p(strong("Paso 2: Asignación de Costos Fijos")),
        div(class = "formula",
            paste0("Costo Fijo = $", round(COSTO_FIJO_POR_COMENSAL, 2), " por comensal")
        ),
        hr(),
        p(strong("Paso 3: Costo Total")),
        div(class = "formula",
            paste0("$", round(datos$Costo_Materia_Prima, 2), " + $", 
                   round(datos$Costo_Fijo_Asignado, 2), " = $", 
                   round(datos$Costo_Total_Platillo, 2))
        ),
        hr(),
        p(strong("Paso 4: Precio de Venta (Margen 15%)")),
        div(class = "formula",
            paste0("$", round(datos$Costo_Total_Platillo, 2), " × 1.15 = $", 
                   round(datos$Precio_Venta, 2))
        ),
        hr(),
        p(strong("Paso 5: Análisis")),
        p("• Margen en pesos: $", round(datos$Margen_Pesos, 2)),
        p("• Margen %: ", round(datos$Margen_Porcentaje, 1), "%"),
        p("• Food Cost: ", round(datos$Food_Cost_Pct, 1), "% ", food_cost_status)
    )
  })
  
  # ========================================================================
  # TAB: RECETAS ESTANDARIZADAS
  # ========================================================================
  
  output$tabla_receta_escalada <- DT::renderDataTable({
    factor <- input$num_porciones / 1
    
    tabla <- costos_df %>%
      filter(Platillo == input$receta_select) %>%
      mutate(
        Cantidad_Escalada = round(Cantidad_1_Porcion * factor, 2),
        Costo_Escalado = round(Costo_Porcion * factor, 2)
      ) %>%
      mutate(Costo_Escalado = paste0("$", format(Costo_Escalado, nsmall = 2))) %>%
      select(Ingrediente, Cantidad_Escalada, Unidad, Costo_Escalado)
    
    DT::datatable(tabla, 
                  options = list(pageLength = 15, dom = 't'),
                  rownames = FALSE,
                  colnames = c("Ingrediente", "Cantidad", "Unidad", "Costo"))
  })
  
  output$costo_receta_escalada <- renderText({
    factor <- input$num_porciones / 1
    costo_base <- costos_df %>%
      filter(Platillo == input$receta_select) %>%
      summarise(total = sum(Costo_Porcion))
    
    costo_escalado <- costo_base$total * factor
    paste0("$", format(round(costo_escalado, 2), nsmall = 2, big.mark = ","))
  })
  
  output$info_receta_detalle <- renderUI({
    factor <- input$num_porciones / 1
    costo_base <- costos_df %>%
      filter(Platillo == input$receta_select) %>%
      summarise(total = sum(Costo_Porcion))
    
    costo_por_porcion <- costo_base$total
    costo_escalado <- costo_por_porcion * factor
    
    div(
      p(strong("Porciones solicitadas:"), " ", input$num_porciones),
      p(strong("Costo MP por porción base:"), " $", round(costo_por_porcion, 2)),
      p(strong("Factor de escalado:"), " ", factor, "x"),
      p(strong("Costo MP total escalado:"), " $", round(costo_escalado, 2)),
      hr(),
      p(strong("Nota:"), " No incluye costos fijos")
    )
  })
  
  output$detalle_calculos_receta <- renderUI({
    factor <- input$num_porciones / 1
    costo_base <- costos_df %>%
      filter(Platillo == input$receta_select) %>%
      summarise(total = sum(Costo_Porcion))
    
    div(class = "calculo-box",
        h5("Metodología de Escalado de Recetas"),
        p(strong("Fórmula de Escalado:")),
        div(class = "formula",
            "Cantidad Escalada = Cantidad Base × Factor",
            br(),
            "Costo Escalado = Costo Base × Factor"
        ),
        hr(),
        p(strong("Aplicación:")),
        p("Factor = ", input$num_porciones, " porciones ÷ 1 porción base = ", factor),
        p("Costo Base MP = $", round(costo_base$total, 2)),
        p("Costo Escalado = $", round(costo_base$total, 2), " × ", factor, 
          " = $", round(costo_base$total * factor, 2))
    )
  })
  
  # ========================================================================
  # TAB: ANÁLISIS DE RENTABILIDAD
  # ========================================================================
  
  output$vb_costo_menu_rent <- renderValueBox({
    valueBox(paste0("$", round(costo_total_menu, 2)), 
             "Costo Total Menú", icon = icon("dollar-sign"), color = "red")
  })
  
  output$vb_precio_menu_rent <- renderValueBox({
    valueBox(paste0("$", round(precio_total_menu, 2)), 
             "Precio de Venta", icon = icon("tag"), color = "green")
  })
  
  output$vb_margen_menu_rent <- renderValueBox({
    valueBox(paste0(round(margen_total_menu_pct, 1), "%"), 
             "Margen %", icon = icon("chart-line"), color = "purple")
  })
  
  output$vb_utilidad_menu <- renderValueBox({
    valueBox(paste0("$", round(margen_total_menu_pesos, 2)), 
             "Utilidad por Menú", icon = icon("coins"), color = "blue")
  })
  
  output$grafico_costo_precio <- renderPlotly({
    df <- costos_por_platillo %>%
      select(Platillo, Costo_Total_Platillo, Precio_Venta) %>%
      pivot_longer(cols = c(Costo_Total_Platillo, Precio_Venta), 
                   names_to = "Tipo", values_to = "Valor")
    
    df$Tipo <- factor(df$Tipo,
                      levels = c("Costo_Total_Platillo", "Precio_Venta"),
                      labels = c("Costo Total", "Precio Venta"))
    
    plot_ly(df, x = ~Platillo, y = ~Valor, color = ~Tipo, type = 'bar',
            colors = c('#e74c3c', '#2ecc71')) %>%
      layout(xaxis = list(title = "", tickangle = -45),
             yaxis = list(title = "Monto (MXN)"),
             barmode = 'group',
             paper_bgcolor = '#1a2f5a',
             plot_bgcolor = '#1a2f5a',
             font = list(color = '#ffffff'),
             legend = list(title = list(text = '')))
  })
  
  output$grafico_margenes <- renderPlotly({
    plot_ly(costos_por_platillo, 
            labels = ~Platillo, 
            values = ~Margen_Pesos, 
            type = 'pie',
            textinfo = 'label+percent',
            textposition = 'inside') %>%
      layout(paper_bgcolor = '#1a2f5a',
             font = list(color = '#ffffff'))
  })
  
  output$punto_equilibrio <- renderText({
    margen_unitario <- margen_total_menu_pesos
    pe <- ceiling(COSTOS_FIJOS_TOTALES / margen_unitario)
    paste0(pe)
  })
  
  output$margen_unitario_text <- renderText({
    paste0("$", round(margen_total_menu_pesos, 2))
  })
  
  output$utilidad_proyectada <- renderText({
    utilidad <- (margen_total_menu_pesos * COMENSALES_ESTIMADOS_MES) - COSTOS_FIJOS_TOTALES
    paste0("$", format(round(utilidad, 2), big.mark = ","))
  })
  
  output$ingresos_proyectados <- renderText({
    ingresos <- precio_total_menu * COMENSALES_ESTIMADOS_MES
    paste0("$", format(round(ingresos, 2), big.mark = ","))
  })
  
  output$roi_proyectado <- renderText({
    ingresos <- precio_total_menu * COMENSALES_ESTIMADOS_MES
    costos_totales <- (costo_total_menu * COMENSALES_ESTIMADOS_MES)
    roi <- ((ingresos - costos_totales) / costos_totales) * 100
    paste0(round(roi, 1), "%")
  })
  
  output$grafico_food_cost <- renderPlotly({
    plot_ly(costos_por_platillo, 
            x = ~reorder(Platillo, Food_Cost_Pct), 
            y = ~Food_Cost_Pct, 
            type = 'bar',
            marker = list(color = '#667eea')) %>%
      layout(xaxis = list(title = "", tickangle = -45),
             yaxis = list(title = "Food Cost %", range = c(0, 50)),
             paper_bgcolor = '#1a2f5a',
             plot_bgcolor = '#1a2f5a',
             font = list(color = '#ffffff'),
             shapes = list(
               list(type = "line", y0 = 35, y1 = 35, x0 = 0, x1 = 1,
                    xref = "paper", line = list(color = "red", dash = "dash"))
             ))
  })
  
  output$tabla_analisis_financiero <- DT::renderDataTable({
    tabla <- costos_por_platillo %>%
      mutate(
        Costo_Materia_Prima = paste0("$", round(Costo_Materia_Prima, 2)),
        Costo_Total_Platillo = paste0("$", round(Costo_Total_Platillo, 2)),
        Precio_Venta = paste0("$", round(Precio_Venta, 2)),
        Margen_Pesos = paste0("$", round(Margen_Pesos, 2))
      ) %>%
      select(Platillo, Costo_Materia_Prima, Costo_Total_Platillo, Precio_Venta, 
             Margen_Pesos, Margen_Porcentaje, Food_Cost_Pct)
    
    DT::datatable(tabla, 
                  options = list(pageLength = 10),
                  rownames = FALSE,
                  colnames = c("Platillo", "MP", "Costo Total", "Precio", 
                               "Margen $", "Margen %", "Food Cost %"))
  })
  
  # ========================================================================
  # TAB: HACCP
  # ========================================================================
  
  output$tabla_haccp <- DT::renderDataTable({
    df <- data.frame(
      Producto = c("Pollo", "Pescado", "Camarones", "Huevo", "Lácteos"),
      Temp_Coccion = c("74°C", "63°C", "63°C", "71°C", "Recepción: 4°C"),
      Tiempo_Min = c("25-30 min", "Variable", "5-7 min", "Variable", "N/A"),
      PCC = c("Cocción", "Cocción", "Cocción", "Cocción", "Recepción/Almacén"),
      Justificacion = c(
        "Elimina Salmonella y Campylobacter",
        "Destruye parásitos y bacterias",
        "Elimina Vibrio parahaemolyticus",
        "Elimina Salmonella",
        "Previene proliferación bacteriana"
      ),
      stringsAsFactors = FALSE
    )
    
    DT::datatable(df, 
                  options = list(pageLength = 10, scrollX = TRUE),
                  rownames = FALSE,
                  colnames = c("Producto", "Temp. Crítica", "Tiempo", "PCC", "Justificación"))
  })
  
  # ========================================================================
  # TAB: OBJETIVOS
  # ========================================================================
  
  output$tabla_objetivos <- DT::renderDataTable({
    df <- data.frame(
      Objetivo = c(
        "Reducir merma de ingredientes en 15%",
        "Alcanzar 95% de satisfacción del cliente",
        "Obtener certificación HACCP",
        "Reducir tiempo de servicio a 2.5 min/platillo",
        "Capacitar 100% del personal trimestralmente"
      ),
      Especifico = c("Sí - De 12% a 10%", "Sí - Encuestas", "Sí - Cert. oficial", 
                     "Sí - Cronometraje", "Sí - Todos los empleados"),
      Medible = c("Sí - Pesaje diario", "Sí - Escala 1-10", "Sí - Documento", 
                  "Sí - Tiempo promedio", "Sí - Asistencia"),
      Alcanzable = c("Sí", "Sí", "Sí", "Sí", "Sí"),
      Tiempo = c("3 meses", "6 meses", "6 meses", "2 meses", "3 meses"),
      Responsable = c("Chef Ejecutivo", "Gerente", "Dir. Calidad", 
                      "Capitán de Meseros", "RH"),
      stringsAsFactors = FALSE
    )
    
    DT::datatable(df, 
                  options = list(pageLength = 10, scrollX = TRUE),
                  rownames = FALSE)
  })
  
  # ========================================================================
  # TAB: BITÁCORAS
  # ========================================================================
  
  bitacora_rv <- reactiveValues(
    data = data.frame(
      Fecha = as.Date(character()),
      Producto = character(),
      Proveedor = character(),
      Temperatura = numeric(),
      Cumple = character(),
      stringsAsFactors = FALSE
    )
  )
  
  observeEvent(input$guardar_bit, {
    nuevo_registro <- data.frame(
      Fecha = input$fecha_bit,
      Producto = input$producto_bit,
      Proveedor = input$proveedor_bit,
      Temperatura = input$temp_bit,
      Cumple = input$cumple_bit,
      stringsAsFactors = FALSE
    )
    
    bitacora_rv$data <- rbind(bitacora_rv$data, nuevo_registro)
    showNotification("Registro guardado exitosamente", type = "message")
  })
  
  output$tabla_bitacora <- DT::renderDataTable({
    if(nrow(bitacora_rv$data) == 0) {
      return(DT::datatable(data.frame(Mensaje = "No hay registros aún"), 
                           options = list(dom = 't'), rownames = FALSE))
    }
    
    DT::datatable(bitacora_rv$data, 
                  options = list(pageLength = 10, order = list(list(0, 'desc'))),
                  rownames = FALSE)
  })
}

# ============================================================================
# EJECUTAR APLICACIÓN
# ============================================================================

shinyApp(ui = ui, server = server)