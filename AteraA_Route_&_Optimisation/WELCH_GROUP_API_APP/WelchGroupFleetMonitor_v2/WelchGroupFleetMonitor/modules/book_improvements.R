# modules/book_improvements.R — Welch Group Fleet Monitor
# Final Tab: How Chapters 1, 3, 5, 8 & 9 improve the cloned API tabs

book_improvements_ui <- function(id) {
  ns <- NS(id)

  # ── Shared card helpers ───────────────────────────────────────────────────
  bi_card <- function(chapter, colour, icon_class, title, body_content) {
    div(style = paste0(
          "background:#1e2a3a;border-left:5px solid ", colour, ";",
          "border-radius:8px;padding:18px 20px;margin-bottom:18px;"
        ),
      div(style = "display:flex;align-items:center;gap:12px;margin-bottom:14px;",
        tags$i(class = paste0("fa ", icon_class),
               style = paste0("color:", colour, ";font-size:22px;")),
        tags$h4(style = paste0("color:", colour, ";margin:0;font-size:16px;font-weight:800;"),
                chapter),
        tags$span(style = "color:#8fa0b5;font-size:13px;", title)
      ),
      body_content
    )
  }

  improvement_row <- function(label, orig, improved, colour = "#1a9b9b") {
    div(style = "display:grid;grid-template-columns:200px 1fr 1fr;gap:10px;padding:8px 0;border-bottom:1px solid #253a52;",
      tags$b(style = paste0("color:", colour, ";font-size:12px;align-self:center;"), label),
      div(style = "background:#0d1921;border-radius:4px;padding:8px 10px;",
        tags$small(style = "color:#dc3545;display:block;margin-bottom:4px;", "\u2717 Original"),
        tags$code(style = "color:#8fa0b5;font-size:11px;white-space:pre-wrap;", orig)
      ),
      div(style = "background:#0d1921;border-radius:4px;padding:8px 10px;",
        tags$small(style = "color:#28a745;display:block;margin-bottom:4px;", "\u2713 v2 Fixed"),
        tags$code(style = "color:#7ec8e3;font-size:11px;white-space:pre-wrap;", improved)
      )
    )
  }

  tagList(
    # ── Page header ───────────────────────────────────────────────────────────
    div(class = "wg-page-header",
      div(class = "wg-page-title",
        tags$i(class = "fa fa-book", style = "margin-right:10px;"),
        "Book \u2192 App Improvements: Chapters 1, 3, 5, 8 & 9"
      ),
      div(class = "wg-page-subtitle",
        "This tab documents exactly how each chapter of ",
        tags$em("Python API Development Fundamentals"),
        " (Chan, Chung, Huang \u2014 Packt, 2019) was applied to diagnose bugs in the",
        " original WelchGroupFleetMonitor and drive the improvements in the v2 cloned tabs."
      )
    ),

    # ── Overview summary row ──────────────────────────────────────────────────
    fluidRow(
      column(12,
        div(style = "display:flex;flex-wrap:wrap;gap:10px;margin-bottom:24px;",
          lapply(list(
            list("8", "Bugs Fixed",      "#dc3545"),
            list("3", "Tabs Cloned",     "#1a9b9b"),
            list("5", "Book Chapters",   "#fd7e14"),
            list("6", "New Charts",      "#28a745"),
            list("1", "Pagination Loop", "#6f42c1")
          ), function(m) {
            HTML(sprintf(
              '<div style="flex:1;min-width:130px;background:#1e2a3a;border-left:4px solid %s;
               padding:12px 16px;border-radius:6px;">
               <div style="font-size:28px;font-weight:800;color:#e0eaf5;">%s</div>
               <div style="font-size:11px;color:#8fa0b5;text-transform:uppercase;letter-spacing:.5px;">%s</div>
             </div>', m[[3]], m[[1]], m[[2]])
          ))
        )
      )
    ),

    # ── Chapter 1 ─────────────────────────────────────────────────────────────
    fluidRow(
      column(12,
        bi_card(
          chapter    = "Chapter 1 \u2014 REST, HTTP & JSON",
          colour     = "#1a9b9b",
          icon_class = "fa-globe",
          title      = "Applied in: api_connection_v2.R",
          body_content = tagList(

            tags$p(style = "color:#8fa0b5;margin-bottom:14px;",
              "Chapter 1 establishes REST constraints, HTTP methods, status codes, and the JSON data format.",
              " Every element maps directly to the Volvo API's design."
            ),

            # REST constraints applied
            div(style = "margin-bottom:14px;",
              tags$h5(style = "color:#1a9b9b;", "REST Constraints \u2192 Volvo API"),
              div(style = "display:grid;grid-template-columns:1fr 1fr;gap:8px;",
                lapply(list(
                  list("Stateless", "Every request carries Basic Auth. No session cookies. The API rejects requests with missing credentials with 401."),
                  list("Uniform Interface", "Three fixed resource URIs: /vehicles, /vehiclepositions, /vehiclestatuses. All GET \u2014 read-only."),
                  list("Client-Server", "The app (client) stores data; the Volvo API (server) serves it. Separation of concerns."),
                  list("Cacheable", "Ch9 maps each endpoint to a cache TTL: /vehicles=86400s, /vehiclestatuses SNAPSHOT=60s.")
                ), function(r) {
                  div(style = "background:#0d1921;border-left:2px solid #1a9b9b;padding:8px 12px;border-radius:3px;",
                    tags$b(style = "color:#7ec8e3;font-size:12px;", r[[1]]),
                    tags$p(style = "color:#8fa0b5;font-size:11px;margin:4px 0 0;", r[[2]])
                  )
                })
              )
            ),

            # HTTP status codes
            div(style = "margin-bottom:14px;",
              tags$h5(style = "color:#1a9b9b;", "HTTP Status Codes \u2192 App Improvement"),
              tags$p(style = "color:#8fa0b5;font-size:13px;",
                "The original connection tab shows a generic error message for all failures.",
                " v2 maps each code to a specific user hint:"
              ),
              div(style = "display:flex;flex-wrap:wrap;gap:6px;",
                lapply(list(
                  list("200","#28a745","OK \u2014 data returned"),
                  list("401","#dc3545","Wrong credentials \u2014 check username/password"),
                  list("403","#dc3545","No rights on this vehicle \u2014 contact Renault Trucks"),
                  list("406","#6f42c1","Accept header rejected \u2014 auto-retry fires"),
                  list("429","#fd7e14","Rate limited \u2014 wait 60s, Ch9 retry handler")
                ), function(r) {
                  HTML(sprintf(
                    '<span style="background:#1a2d45;border:1px solid %s;padding:4px 10px;border-radius:4px;font-size:11px;font-family:monospace;">
                     <b style="color:%s;">%s</b> <span style="color:#8fa0b5;">%s</span></span>',
                    r[[2]], r[[2]], r[[1]], r[[3]]
                  ))
                })
              )
            ),

            # JSON format
            div(
              tags$h5(style = "color:#1a9b9b;", "JSON Format \u2192 Raw JSON Inspector"),
              tags$p(style = "color:#8fa0b5;font-size:13px;",
                "Chapter 1's JSON type mappings (dict={}, list=[], string, number, bool, null)",
                " are demonstrated live in v2's Raw JSON Response Inspector panel.",
                " R's jsonlite::fromJSON() = Python's json.loads()."
              ),
              div(style = "background:#0d1921;border-radius:4px;padding:10px 14px;font-family:monospace;font-size:11px;",
                tags$pre(style = "color:#7ec8e3;margin:0;",
'# Volvo API JSON \u2192 R type mapping (Ch1 concepts):
{                                # R: named list
  "vehicleResponse": {           # R: named list
    "vehicles": [                # R: list of lists
      {
        "vin":    "ABC123",      # R: character (string)
        "productionDate": {
          "year": 2024           # R: integer (number)
        },
        "possibleFuelType": ["08"] # R: character vector (array)
      }
    ]
  },
  "moreDataAvailable": false     # R: logical (bool)
}')
              )
            )
          )
        )
      )
    ),

    # ── Chapter 3 ─────────────────────────────────────────────────────────────
    fluidRow(
      column(12,
        bi_card(
          chapter    = "Chapter 3 \u2014 SQLAlchemy, ORM & Data Models",
          colour     = "#fd7e14",
          icon_class = "fa-database",
          title      = "Applied in: vehicle_data_v2.R \u2014 Field mapping, units, bug fixes",
          body_content = tagList(

            tags$p(style = "color:#8fa0b5;margin-bottom:14px;",
              "Chapter 3 covers SQLAlchemy column types, units, relationships, and the importance of",
              " correctly mapping raw API values to storage types.",
              " Three bugs in the original statuses_as_df() were diagnosed using the Ch3 field-mapping framework."
            ),

            # Bug fixes table
            div(style = "margin-bottom:14px;",
              tags$h5(style = "color:#fd7e14;", "Bug Fixes Diagnosed via Ch3 Field Mapping"),
              improvement_row(
                label   = "BUGFIX-5\nGrossWeight_kg",
                orig    = "snap$grossCombinationVehicleWeight\n# Wrong: inside snapshotData\n# Result: always NA",
                improved = "s$grossCombinationVehicleWeight\n# Correct: TOP-LEVEL field per spec\n# Ch3: column type = BigInteger",
                colour  = "#fd7e14"
              ),
              improvement_row(
                label   = "BUGFIX-2\nEV Accumulated",
                orig    = "s$volvoGroupAccumulatedData\n# Wrong top-level key\n# Spec path: acc$volvoGroupAccumulated",
                improved = "acc <- s$accumulatedData\nvga <- acc$volvoGroupAccumulated\n# Ch3: nested relationship (FK)",
                colour  = "#fd7e14"
              ),
              improvement_row(
                label   = "BUGFIX-3\nElecEnergyRegen",
                orig    = "vga$electricEnergyRecuperated\n# Wrong field name + scalar\n# Always returns NA",
                improved = "regen <- vga$electricEnergyRecuperation\nregen_wh <- regen$energy\n# Ch3: nested object, not scalar",
                colour  = "#fd7e14"
              )
            ),

            # Column type reference
            div(
              tags$h5(style = "color:#fd7e14;", "API Field \u2192 SQLAlchemy Column Type \u2192 Unit"),
              div(style = "overflow-x:auto;",
                tags$table(style = "width:100%;font-size:12px;border-collapse:collapse;",
                  tags$thead(
                    tags$tr(
                      lapply(c("API Field","Type in .flatten_status()","SQLAlchemy Column","Unit/Note"), function(h)
                        tags$th(style = "color:#fd7e14;padding:6px 10px;text-align:left;border-bottom:1px solid #253a52;", h))
                    )
                  ),
                  tags$tbody(
                    lapply(list(
                      list("hrTotalVehicleDistance", "numeric \u00f7 1000", "Float",     "metres \u2192 km"),
                      list("totalEngineHours",       "numeric \u00f7 1000", "Float",     "1/1000 hr \u2192 hours"),
                      list("fuelLevel1",             "numeric",            "Float",     "SOC% for BEV (rFMS)"),
                      list("batteryPackChargingStatus","character",        "String(30)","NOT_CHARGING/CHARGING/..."),
                      list("electricEnergyRecuperation.energy","numeric",  "BigInteger","Wh (nested object)"),
                      list("estimatedDistanceToEmpty.electric","numeric",  "Float",     "km (nested object)"),
                      list("grossCombinationVehicleWeight","numeric",      "BigInteger","kg, top-level field")
                    ), function(r) {
                      tags$tr(
                        tags$td(style="padding:5px 10px;color:#7ec8e3;font-family:monospace;font-size:11px;border-bottom:1px solid #1a2d45;", r[[1]]),
                        tags$td(style="padding:5px 10px;color:#c8d8e4;border-bottom:1px solid #1a2d45;", r[[2]]),
                        tags$td(style="padding:5px 10px;color:#1a9b9b;font-family:monospace;border-bottom:1px solid #1a2d45;", r[[3]]),
                        tags$td(style="padding:5px 10px;color:#8fa0b5;font-size:11px;border-bottom:1px solid #1a2d45;", r[[4]])
                      )
                    })
                  )
                )
              )
            )
          )
        )
      )
    ),

    # ── Chapter 5 ─────────────────────────────────────────────────────────────
    fluidRow(
      column(12,
        bi_card(
          chapter    = "Chapter 5 \u2014 marshmallow Serialisation",
          colour     = "#6f42c1",
          icon_class = "fa-exchange-alt",
          title      = "Applied in: vehicle_data_v2.R \u2014 Nested extraction, Field Explorer tab",
          body_content = tagList(

            tags$p(style = "color:#8fa0b5;margin-bottom:14px;",
              "Chapter 5 introduces marshmallow nested schemas, dump_only fields, and partial loading.",
              " The /vehiclestatuses response has exactly the same nested structure that Ch5's",
              " RecipeSchema > UserSchema example demonstrates.",
              " The Field Explorer tab in v2 visualises which fields came from which section."
            ),

            fluidRow(
              column(6,
                div(style = "margin-bottom:14px;",
                  tags$h5(style = "color:#6f42c1;", "Nested Schema Mapping (Ch5 \u2192 API)"),
                  div(style = "background:#0d1921;border-radius:4px;padding:10px 14px;font-family:monospace;font-size:11px;",
                    tags$pre(style = "color:#7ec8e3;margin:0;",
'# Ch5: nested schemas in marshmallow
class VehicleStatusSchema(Schema):
    vin          = fields.Str(required=True)
    receivedAt   = fields.DateTime(dump_only=True)
    triggerType  = fields.Nested(TriggerTypeSchema)

    # Section schemas \u2014 None when section absent
    snapshotData    = fields.Nested(SnapshotSchema)
    accumulatedData = fields.Nested(AccumulatedSchema)
    uptimeData      = fields.Nested(UptimeSchema)

class SnapshotSchema(Schema):
    gnssPosition = fields.Nested(GNSSSchema)  # 2 levels deep
    fuelLevel1   = fields.Float()   # SOC% for BEV
    batteryPackChargingStatus = fields.Str()

    # VOLVOGROUPSNAPSHOT (additionalContent):
    volvoGroupSnapshot = fields.Nested(VGSnapshotSchema)')
                  )
                )
              ),
              column(6,
                div(style = "margin-bottom:14px;",
                  tags$h5(style = "color:#6f42c1;", "dump_only + partial= in Context"),
                  lapply(list(
                    list("dump_only", "receivedDateTime, requestServerDateTime",
                         "Set by Volvo server \u2014 never in request params"),
                    list("required", "vin",
                         "Every response must have a VIN"),
                    list("partial=", "accumulatedData, uptimeData",
                         "Not present when contentFilter=SNAPSHOT only. Use partial= in load()"),
                    list("load_only", "(not applicable \u2014 Volvo is read-only)",
                         "No write operations; all fields are dump_only perspective")
                  ), function(r) {
                    div(style = "padding:6px 10px;margin-bottom:6px;background:#1a2d45;border-left:2px solid #6f42c1;border-radius:3px;",
                      tags$b(style = "color:#a78bfa;font-family:monospace;font-size:11px;", r[[1]]),
                      tags$span(style = "color:#7ec8e3;font-size:11px;margin-left:8px;", r[[2]]),
                      tags$br(),
                      tags$small(style = "color:#8fa0b5;", r[[3]])
                    )
                  })
                )
              )
            ),

            div(
              tags$h5(style = "color:#6f42c1;", "Field Explorer Tab \u2014 Section Presence Visualisation"),
              tags$p(style = "color:#8fa0b5;font-size:13px;",
                "The v2 Field Explorer tab shows which fields from each section (Base/Snapshot/Accumulated/Uptime/Volvo EV)",
                " are present in the response with a fill-rate percentage.",
                " This directly implements Ch5's concept that contentFilter controls which nested schemas are populated.",
                " Original tab: no section breakdown visible. v2: full section-by-section field audit."
              )
            )
          )
        )
      )
    ),

    # ── Chapter 8 ─────────────────────────────────────────────────────────────
    fluidRow(
      column(12,
        bi_card(
          chapter    = "Chapter 8 \u2014 Pagination, Search & Ordering",
          colour     = "#17a2b8",
          icon_class = "fa-list",
          title      = "Applied in: vehicle_data_v2.R \u2014 moreDataAvailable cursor loop",
          body_content = tagList(

            tags$p(style = "color:#8fa0b5;margin-bottom:14px;",
              "Chapter 8's paginate() pattern \u2014 advance a cursor until has_next is False \u2014",
              " is the exact mechanism the Volvo API uses for time-window queries.",
              " The original app silently returns only the first page of results."
            ),

            # Side-by-side comparison
            div(style = "margin-bottom:14px;",
              tags$h5(style = "color:#17a2b8;", "Pagination Pattern: SQLAlchemy Ch8 vs Volvo API"),
              div(style = "display:grid;grid-template-columns:1fr 1fr;gap:12px;",
                div(style = "background:#0d1921;border-radius:4px;padding:10px 14px;",
                  tags$small(style = "color:#fd7e14;display:block;margin-bottom:6px;", "\u2717 Ch8 SQLAlchemy paginate()"),
                  tags$pre(style = "color:#7ec8e3;font-size:11px;margin:0;",
'# Ch8 book pattern:
pag = Recipe.query.paginate(
    page=page, per_page=20
)
while pag.has_next:
    data += pag.items
    page = pag.next_num
    pag = Recipe.query.paginate(
        page=page, per_page=20
    )')
                ),
                div(style = "background:#0d1921;border-radius:4px;padding:10px 14px;",
                  tags$small(style = "color:#28a745;display:block;margin-bottom:6px;", "\u2713 Volvo API (v2 .paginated_fetch_v2)"),
                  tags$pre(style = "color:#7ec8e3;font-size:11px;margin:0;",
'# Equivalent Volvo API pattern:
# moreDataAvailable = pag.has_next
# receivedDateTime cursor = pag.next_num

while True:
    result = call_api(starttime=cursor)
    records += result["vehicleStatuses"]
    if not result["moreDataAvailable"]:
        break
    # Advance cursor (= pag.next_num)
    last = records[-1]["receivedDateTime"]
    cursor = last + timedelta(seconds=1)')
                )
              )
            ),

            # BUGFIX-6
            div(style = "margin-bottom:14px;",
              tags$h5(style = "color:#17a2b8;", "BUGFIX-6: Missing Pagination in Original"),
              div(style = "background:#2a1a1a;border-left:3px solid #dc3545;border-radius:4px;padding:10px 14px;",
                tags$b(style = "color:#dc3545;", "\u2717 Original vehicle_data.R:"),
                tags$p(style = "color:#8fa0b5;font-size:12px;margin:6px 0 0;",
                  "get_vehicle_positions() and get_vehicle_statuses() call the API once and return whatever fits in one response.",
                  " If moreDataAvailable=true, all subsequent pages are silently lost.",
                  " For a fleet with 14 days of history, this can mean losing >95% of the data."
                )
              ),
              div(style = "background:#0d2a1a;border-left:3px solid #28a745;border-radius:4px;padding:10px 14px;margin-top:8px;",
                tags$b(style = "color:#28a745;", "\u2713 v2 .paginated_fetch_v2():"),
                tags$p(style = "color:#8fa0b5;font-size:12px;margin:6px 0 0;",
                  "Loops until moreDataAvailable=false, advancing the receivedDateTime cursor by +1 second each page.",
                  " Respects 1.2s inter-call sleep (Ch9 rate limit). Logs each page to the Pagination [Ch8] diagnostic tab."
                )
              )
            ),

            # Pagination Diagnostics tab
            div(
              tags$h5(style = "color:#17a2b8;", "Pagination [Ch8] Diagnostic Tab"),
              tags$p(style = "color:#8fa0b5;font-size:13px;",
                "v2 adds a dedicated 'Pagination [Ch8]' subtab that logs every page fetch,",
                " showing cursor values, record counts per page, and whether moreDataAvailable was true.",
                " This makes the Ch8 paginate() concept live and inspectable in production."
              )
            )
          )
        )
      )
    ),

    # ── Chapter 9 ─────────────────────────────────────────────────────────────
    fluidRow(
      column(12,
        bi_card(
          chapter    = "Chapter 9 \u2014 Caching & Rate Limiting",
          colour     = "#e83e8c",
          icon_class = "fa-bolt",
          title      = "Applied in: vehicle_data_v2.R \u2014 TTL hints, 429 handling, datetype fix",
          body_content = tagList(

            tags$p(style = "color:#8fa0b5;margin-bottom:14px;",
              "Chapter 9 covers cache TTL selection, cache invalidation on writes, and HTTP 429 handling.",
              " The Volvo API enforces strict call frequency limits \u2014 exceeding them returns 429.",
              " Three improvements apply Ch9 directly."
            ),

            # Cache TTL mapping
            div(style = "margin-bottom:14px;",
              tags$h5(style = "color:#e83e8c;", "Cache TTL Mapping: contentFilter \u2192 TTL"),
              tags$p(style = "color:#8fa0b5;font-size:13px;",
                "The v2 query panel shows a dynamic cache TTL hint based on the selected contentFilter,",
                " exactly mirroring the Chapter 9 cache.cached(timeout=N) pattern:"
              ),
              div(style = "overflow-x:auto;",
                tags$table(style = "width:100%;font-size:12px;border-collapse:collapse;",
                  tags$thead(
                    tags$tr(lapply(c("Endpoint / contentFilter","Volvo cadence","Ch9 cache TTL","v2 hint shown"),
                      function(h) tags$th(style="color:#e83e8c;padding:6px 10px;text-align:left;border-bottom:1px solid #253a52;",h)))
                  ),
                  tags$tbody(
                    lapply(list(
                      list("/vehicles",              "Once/day",    "86400s (24h)", "Fleet metadata changes rarely"),
                      list("/vehiclepositions",       "1/minute",    "60s",          "MAP service 1-min updates"),
                      list("SNAPSHOT (MAP)",          "1/minute",    "60s",          "Event-triggered live data"),
                      list("ACCUMULATED (CHECK)",     "Hourly",      "900s (15min)", "Lifetime totals, slow change"),
                      list("UPTIME (HEALTH)",         "On telltale", "300s",         "Health alerts, semi-realtime"),
                      list("Everything (all)",        "Slowest",     "900s",         "Use slowest endpoint cadence")
                    ), function(r) {
                      tags$tr(
                        tags$td(style="padding:5px 10px;color:#7ec8e3;font-family:monospace;font-size:11px;border-bottom:1px solid #1a2d45;", r[[1]]),
                        tags$td(style="padding:5px 10px;color:#c8d8e4;border-bottom:1px solid #1a2d45;", r[[2]]),
                        tags$td(style="padding:5px 10px;color:#e83e8c;font-weight:700;border-bottom:1px solid #1a2d45;", r[[3]]),
                        tags$td(style="padding:5px 10px;color:#8fa0b5;font-size:11px;border-bottom:1px solid #1a2d45;", r[[4]])
                      )
                    })
                  )
                )
              )
            ),

            # 429 handling
            div(style = "margin-bottom:14px;",
              tags$h5(style = "color:#e83e8c;", "HTTP 429 Handling"),
              improvement_row(
                label    = "Rate limit\n429 retry",
                orig     = "# utils_api_manager.R already\n# handles 429 with Retry-After.\n# But inter-call sleep is 1.2s\n# even though positions cadence\n# is 1/minute (not 1/second).",
                improved = "# v2 comments clarify correct\n# cadence per endpoint.\n# Pagination loop also respects\n# Sys.sleep(1.2) between pages.\n# [Ch9] limiter.limit('1/minute')",
                colour   = "#e83e8c"
              )
            ),

            # BUGFIX-7 and BUGFIX-8
            div(
              tags$h5(style = "color:#e83e8c;", "BUGFIX-7 & 8: Accept Header + datetype"),
              div(style = "display:grid;grid-template-columns:1fr 1fr;gap:10px;",
                div(style = "background:#2a1a1a;border-left:3px solid #dc3545;border-radius:4px;padding:10px 14px;",
                  tags$b(style = "color:#dc3545;", "\u2717 BUGFIX-7: Wrong Accept header"),
                  tags$pre(style = "color:#8fa0b5;font-size:11px;margin:6px 0 0;",
'# Original hardcodes v3.0:
accept_type = "application/x.volvogroup
  .com.vehiclestatuses.v3.0+json"
# Triggers 406 on every call!
# Auto-retry works but wastes
# one round-trip per request.')
                ),
                div(style = "background:#0d2a1a;border-left:3px solid #28a745;border-radius:4px;padding:10px 14px;",
                  tags$b(style = "color:#28a745;", "\u2713 BUGFIX-8: datetype=received explicit"),
                  tags$pre(style = "color:#7ec8e3;font-size:11px;margin:6px 0 0;",
'# [Ch9] v2 always sends:
q$datetype <- "received"
# API docs recommend "received"
# not "created" for pagination
# cursor reliability.
# Original never sent this param.')
                )
              )
            )
          )
        )
      )
    ),

    # ── BUGFIX-1 summary (module naming) ─────────────────────────────────────
    fluidRow(
      column(12,
        div(style = "background:#2a1a2a;border-left:5px solid #dc3545;border-radius:8px;padding:18px 20px;margin-bottom:18px;",
          tags$h4(style = "color:#dc3545;margin-bottom:14px;",
            tags$i(class = "fa fa-exclamation-triangle", style = "margin-right:10px;"),
            "Critical Bug: Duplicate Function Names (BUGFIX-1)"
          ),
          tags$p(style = "color:#8fa0b5;",
            "The original app ships with BOTH ", tags$code("vehicle_data.R"), " and ",
            tags$code("vehicle_data_p.R"), " in the modules/ directory.",
            " Both files define ", tags$b(style = "color:#dc3545;", "identical R function names"),
            ": ", tags$code("vehicle_data_ui()"), " and ", tags$code("vehicle_data_server()"), ".",
            " When module_loader.R sources all .R files alphabetically, the second file",
            " (vehicle_data_p.R) silently overwrites the first. The user never sees vehicle_data.R at all."
          ),
          div(style = "display:grid;grid-template-columns:1fr 1fr;gap:12px;margin-top:12px;",
            div(style = "background:#0d1921;border-left:2px solid #dc3545;padding:8px 12px;border-radius:3px;",
              tags$b(style = "color:#dc3545;font-size:12px;", "\u2717 vehicle_data_p.R (last sourced)"),
              tags$pre(style = "color:#8fa0b5;font-size:11px;margin:6px 0 0;",
'# SAME function names as vehicle_data.R:
vehicle_data_ui <- function(id) { ... }
vehicle_data_server <- function(id, ...) { ... }
# Overwrites vehicle_data.R silently!')
            ),
            div(style = "background:#0d1921;border-left:2px solid #28a745;padding:8px 12px;border-radius:3px;",
              tags$b(style = "color:#28a745;font-size:12px;", "\u2713 v2: unique names"),
              tags$pre(style = "color:#7ec8e3;font-size:11px;margin:6px 0 0;",
'# v2 uses unique, non-conflicting names:
vehicle_data_v2_ui <- function(id) { ... }
vehicle_data_v2_server <- function(id, ...) { ... }
# Registered as vehicle_data_v2 in YAML.')
            )
          )
        )
      )
    ),

    # ── Summary matrix ────────────────────────────────────────────────────────
    fluidRow(
      column(12,
        div(style = "background:#1e2a3a;border-radius:8px;padding:18px 20px;margin-bottom:18px;",
          tags$h4(style = "color:#7ec8e3;margin-bottom:16px;",
            tags$i(class = "fa fa-check-square", style = "margin-right:10px;"),
            "Complete Improvement Matrix"
          ),
          div(style = "overflow-x:auto;",
            tags$table(style = "width:100%;font-size:12px;border-collapse:collapse;",
              tags$thead(
                tags$tr(
                  lapply(c("Bug / Improvement","Chapter Reference","Original Behaviour","v2 Behaviour","Tab Affected"),
                    function(h) tags$th(style="color:#7ec8e3;padding:8px 10px;text-align:left;border-bottom:2px solid #253a52;background:#131e2b;",h))
                )
              ),
              tags$tbody(
                lapply(list(
                  list("BUGFIX-1","(Architecture)","vehicle_data.R + vehicle_data_p.R share function names","Unique names: vehicle_data_v2_ui/server","vehicle_data_v2"),
                  list("BUGFIX-2","Ch3: ORM field paths","s$volvoGroupAccumulatedData (wrong top-level)","acc$volvoGroupAccumulated (correct nesting)","vehicle_data_v2"),
                  list("BUGFIX-3","Ch3: field types","electricEnergyRecuperated (wrong name + scalar)","electricEnergyRecuperation$energy (nested object)","vehicle_data_v2"),
                  list("BUGFIX-4","Ch5: nested schema","estimatedDistanceToEmpty as scalar","estimatedDistanceToEmpty$electric (object field)","vehicle_data_v2"),
                  list("BUGFIX-5","Ch3: ORM location","snap$grossCombinationVehicleWeight","s$grossCombinationVehicleWeight (top-level)","vehicle_data_v2"),
                  list("BUGFIX-6","Ch8: pagination","Single-page result, moreDataAvailable ignored","Full cursor loop until moreDataAvailable=false","vehicle_data_v2"),
                  list("BUGFIX-7","Ch1: HTTP headers","Accept: v3.0 (wrong) triggers 406+retry every call","Correct v1.0 type; no wasted round-trip","utils_api_manager (noted)"),
                  list("BUGFIX-8","Ch9: request params","datetype never sent","datetype=received explicit on all time-window queries","vehicle_data_v2"),
                  list("New: Cache TTL hints","Ch9: caching","No guidance on polling frequency","Dynamic TTL hint per contentFilter selection","vehicle_data_v2"),
                  list("New: Field Explorer","Ch5: marshmallow","No section breakdown visible","Section-by-section fill-rate audit","vehicle_data_v2"),
                  list("New: EV Analytics","Ch3/Ch5: EV fields","No EV-specific charts","SoC timeline, charging events, energy donut, range scatter","vehicle_data_v2"),
                  list("New: Pagination log","Ch8: paginate()","No visibility into pagination","Per-page log with cursor values","vehicle_data_v2"),
                  list("New: Endpoint tester","Ch1: REST/HTTP","Only tests /vehicles","Tests all 3 endpoints, shows per-endpoint HTTP status","api_connection_v2"),
                  list("New: JSON inspector","Ch1: JSON format","No raw response view in connection tab","Full JSON inspector with type annotations","api_connection_v2"),
                  list("New: Status code map","Ch1: HTTP codes","Generic error messages","Per-status-code hints matching API spec","api_connection_v2")
                ), function(r) {
                  is_bugfix <- startsWith(r[[1]], "BUGFIX")
                  bg  <- if (is_bugfix) "#2a1a1a" else "#1a2a1a"
                  col <- if (is_bugfix) "#dc3545" else "#28a745"
                  tags$tr(
                    tags$td(style=paste0("padding:5px 10px;font-weight:700;color:",col,";font-family:monospace;font-size:11px;border-bottom:1px solid #1a2d45;background:",bg,";"), r[[1]]),
                    tags$td(style="padding:5px 10px;color:#6f42c1;font-size:11px;border-bottom:1px solid #1a2d45;", r[[2]]),
                    tags$td(style="padding:5px 10px;color:#8fa0b5;font-size:11px;border-bottom:1px solid #1a2d45;", r[[3]]),
                    tags$td(style="padding:5px 10px;color:#7ec8e3;font-size:11px;border-bottom:1px solid #1a2d45;", r[[4]]),
                    tags$td(style="padding:5px 10px;color:#fd7e14;font-family:monospace;font-size:11px;border-bottom:1px solid #1a2d45;", r[[5]])
                  )
                })
              )
            )
          )
        )
      )
    )
  )
}

book_improvements_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    # Static content only — no server-side logic needed
  })
}
