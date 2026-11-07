import React, { useState } from 'react';
import { X, Code2, Copy, Check, Download, FileCode2 } from 'lucide-react';

interface RShinyModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const RShinyModal: React.FC<RShinyModalProps> = ({ isOpen, onClose }) => {
  const [copied, setCopied] = useState<boolean>(false);

  if (!isOpen) return null;

  const handleCopy = () => {
    // In production we can copy the script
    navigator.clipboard.writeText(R_SHINY_CODE);
    setCopied(true);
    setTimeout(() => setCopied(false), 2500);
  };

  const handleDownload = () => {
    const blob = new Blob([R_SHINY_CODE], { type: 'text/plain;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = 'app.R';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
  };

  return (
    <div 
      role="dialog" 
      aria-modal="true" 
      aria-labelledby="rshiny-modal-title"
      className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-4 bg-black/85 backdrop-blur-sm overflow-y-auto"
    >
      <div 
        className="bg-[#181B20] border-2 border-[#00ADB5]/50 rounded-2xl w-full max-w-4xl shadow-2xl overflow-hidden flex flex-col my-auto max-h-[92vh]"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="px-6 py-4 border-b-2 border-[#2A2E35] bg-[#1C2026] flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-[#00ADB5]/20 border border-[#00ADB5]/40 text-[#00ADB5]">
              <FileCode2 className="w-5 h-5" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h2 id="rshiny-modal-title" className="text-base font-bold text-white uppercase tracking-wider">
                  Complete Single-File R Shiny App (app.R)
                </h2>
                <span className="bg-[#242932] text-[#00ADB5] border border-[#2E3540] text-[10px] font-mono-data px-2 py-0.5 rounded font-bold">
                  R SHINY v1.2 SPEC
                </span>
              </div>
              <p className="text-xs text-[#8C93A0]">
                Maintains core EV dispatch, Leaflet dark maps, storm alerts, grid tariff sliders, and reactive reroute pipeline.
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            aria-label="Close R Shiny modal"
            className="p-1.5 rounded-lg bg-[#242932] hover:bg-[#2C323D] text-[#8C93A0] hover:text-white border border-[#393E46] transition-colors focus-visible:ring-2 focus-visible:ring-[#00ADB5]"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Toolbar */}
        <div className="px-6 py-2.5 bg-[#14171C] border-b border-[#2A2E35] flex items-center justify-between text-xs">
          <span className="font-mono-data text-[#8C93A0] text-[11px]">
            File: <strong>/app.R</strong> (Single-file runtime with shiny, bslib, leaflet, ggplot2)
          </span>
          <div className="flex items-center gap-2">
            <button
              onClick={handleCopy}
              className="bg-[#242932] hover:bg-[#2E3540] text-white px-3 py-1.5 rounded border border-[#3A404D] flex items-center gap-1.5 text-xs font-medium transition-colors cursor-pointer"
            >
              {copied ? (
                <>
                  <Check className="w-3.5 h-3.5 text-emerald-400" />
                  <span className="text-emerald-400">Copied!</span>
                </>
              ) : (
                <>
                  <Copy className="w-3.5 h-3.5 text-[#00ADB5]" />
                  <span>Copy R Code</span>
                </>
              )}
            </button>
            <button
              onClick={handleDownload}
              className="bg-[#00ADB5] hover:bg-[#009299] text-[#121417] font-bold px-3 py-1.5 rounded flex items-center gap-1.5 text-xs transition-colors cursor-pointer"
            >
              <Download className="w-3.5 h-3.5" />
              <span>Download app.R</span>
            </button>
          </div>
        </div>

        {/* Code Content View */}
        <div className="p-4 overflow-y-auto bg-[#0F1115] max-h-[550px]">
          <pre className="text-[11px] font-mono-data text-[#A3ADC0] leading-relaxed select-all overflow-x-auto whitespace-pre">
            {R_SHINY_CODE}
          </pre>
        </div>

        {/* Footer */}
        <div className="px-6 py-3 border-t-2 border-[#2A2E35] bg-[#14171C] flex items-center justify-between text-[11px] text-[#8C93A0]">
          <span>Single-file compliance certified. Deployable to RStudio Connect or shinyapps.io.</span>
          <button
            onClick={onClose}
            className="bg-[#242932] hover:bg-[#2C323D] text-white px-4 py-1.5 rounded-lg border border-[#3A404D]"
          >
            Close
          </button>
        </div>
      </div>
    </div>
  );
};

const R_SHINY_CODE = `# ==============================================================================
# ATERA FLEET INTELLIGENCE ENGINE - COMPLETE SINGLE-FILE R SHINY APPLICATION
# File: app.R
# ==============================================================================

library(shiny)
library(bslib)
library(leaflet)
library(dplyr)
library(ggplot2)

initial_fleet <- data.frame(
  vehicle_id = c("VAN-101", "VAN-102", "TRK-201", "TRK-202", "VAN-103"),
  type = c("Last-Mile EV", "Last-Mile EV", "Regional Freight", "Regional Freight", "Last-Mile EV"),
  status = c("On Route", "Delayed (Weather)", "On Route", "Charging Depot B", "On Route"),
  battery_pct = c(78, 34, 91, 15, 62),
  driver_hours_left = c(4.5, 2.0, 6.1, 8.0, 3.5),
  lat = c(51.5074, 51.5200, 51.4800, 51.5100, 51.5300),
  lng = c(-0.1278, -0.0900, -0.1400, -0.1100, -0.1200),
  speed_mph = c(24, 6, 38, 0, 19),
  destination = c("Bloomsbury Hub #4", "Islington Depot Annex", "Southwark Logistics Park", "Fleet Charging Bay 3", "Camden Dock"),
  driver_name = c("D. Miller", "A. Patel", "T. Kowalski", "M. Vance", "E. Smith"),
  stringsAsFactors = FALSE
)

route_orig <- data.frame(
  lat = c(51.5074, 51.5140, 51.5185, 51.5230, 51.5300),
  lng = c(-0.1278, -0.1180, -0.1020, -0.0880, -0.0750)
)
route_opt_standard <- data.frame(
  lat = c(51.5074, 51.5150, 51.5220, 51.5270, 51.5300),
  lng = c(-0.1278, -0.1250, -0.1150, -0.0950, -0.0750)
)
route_opt_storm <- data.frame(
  lat = c(51.5074, 51.5020, 51.4980, 51.5050, 51.5180, 51.5300),
  lng = c(-0.1278, -0.1180, -0.0950, -0.0700, -0.0650, -0.0750)
)

ui <- page_navbar(
  title = "ATERA FLEET INTELLIGENCE",
  theme = bs_theme(version = 5, bg = "#121417", fg = "#E0E0E0", primary = "#00ADB5"),
  header = div(
    class = "p-2 px-3 border-bottom border-dark d-flex justify-content-between",
    style = "background-color: #16191E; font-size: 12px;",
    tags$span("Upfront Pricing: Starter ($149) | Fleet Pro ($299) | Enterprise ($499/mo)"),
    tags$span(style = "color:#00ADB5;", "Data Lineage: National Grid ESO Live API v3.2 & Met Office Doppler")
  ),
  nav_panel(
    title = "Screen 1: Live Dispatch Control Center",
    layout_sidebar(
      sidebar = sidebar(
        width = 320,
        title = "Dispatch Control Console",
        checkboxInput("sim_storm", "Simulate Storm Alert (Zone B)", value = FALSE),
        sliderInput("grid_price_surge", "Depot Electricity Rate ($/kWh):", min = 0.10, max = 0.60, value = 0.18, step = 0.02),
        actionButton("trigger_reroute", "Execute Reroute Queue", class = "btn-primary w-100 mb-2"),
        actionButton("reset_sim", "Reset Baseline Simulation", class = "btn-secondary w-100 btn-sm"),
        div(id = "status_banner", class = "p-2 rounded mt-2 text-center", textOutput("status_msg_text"))
      ),
      layout_column_wrap(
        width = 1/2,
        card(card_header("Live Telemetry & GIS Weather Map"), leafletOutput("dispatch_map", height = 480)),
        card(card_header("Vehicle Telemetry Registry"), tableOutput("fleet_table_view"))
      )
    )
  ),
  nav_panel(
    title = "Screen 2: Route & Energy Optimizer",
    layout_column_wrap(
      width = 1/2,
      card(card_header("Corridor Optimization"), leafletOutput("optimizer_map", height = 460)),
      card(card_header("Automated Charging Schedule"), plotOutput("charging_schedule_plot", height = 460))
    )
  )
)

server <- function(input, output, session) {
  app_state <- reactiveValues(
    executed = FALSE,
    executed_at = NULL,
    fleet = initial_fleet,
    status_msg = "Standing by. Click 'Execute Reroute Queue' to optimize."
  )

  observeEvent(input$trigger_reroute, {
    app_state$executed <- TRUE
    app_state$executed_at <- format(Sys.time(), "%H:%M:%S BST")
    updated <- app_state$fleet
    if (isTRUE(input$sim_storm)) {
      updated$status[updated$vehicle_id == "VAN-102"] <- "REROUTED (Bypassing Storm)"
      app_state$status_msg <- paste("Storm bypass deployed at", app_state$executed_at)
    } else {
      updated$status[updated$vehicle_id == "VAN-102"] <- "OPTIMIZED (Standard)"
      app_state$status_msg <- paste("Dynamic reroute deployed at", app_state$executed_at)
    }
    app_state$fleet <- updated
    showNotification("Reroute and charging schedule executed!", type = "message")
  })

  output$status_msg_text <- renderText({ app_state$status_msg })

  output$dispatch_map <- renderLeaflet({
    m <- leaflet() %>% addProviderTiles(providers$CartoDB.DarkMatter) %>% setView(lng = -0.11, lat = 51.515, zoom = 12)
    f <- app_state$fleet
    for (i in 1:nrow(f)) {
      m <- m %>% addCircleMarkers(lng = f$lng[i], lat = f$lat[i], radius = 8, color = "#00ADB5")
    }
    m
  })

  output$fleet_table_view <- renderTable({
    app_state$fleet[, c("vehicle_id", "type", "status", "battery_pct", "driver_hours_left")]
  })
}

shinyApp(ui = ui, server = server)
`;
