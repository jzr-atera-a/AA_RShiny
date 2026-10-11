# modules/mod_systemdesign.R — System Design Fundamentals

systemdesign_ui <- function(id) {
  ns <- NS(id)
  tagList(
    topic_hero("🏗️", "System Design Fundamentals",
      "Design scalable distributed systems. Key concepts tested in senior-level interviews: caching, sharding, CAP theorem, and load balancing.",
      c("Scalability", "CAP Theorem", "Caching", "Sharding", "Load Balancing")),

    fluidRow(
      box(title = "Back-of-Envelope Calculator", status = "primary", solidHeader = TRUE, width = 5,
        tags$p("Estimate system capacity quickly — a core system design interview skill.",
               style = "font-size:12px; color:#555;"),
        numericInput(ns("dau"),      "Daily Active Users (DAU):", value = 1e6,  step = 1e5, min = 1),
        numericInput(ns("req_day"),  "Requests per user per day:", value = 10,   step = 1,   min = 1),
        numericInput(ns("req_size"), "Avg request size (KB):",     value = 50,   step = 1,   min = 1),
        numericInput(ns("storage_y"),"Retention (years):",         value = 5,    step = 1,   min = 1),
        actionButton(ns("btn_calc"), "Calculate", class = "btn btn-dsa")
      ),
      box(title = "Capacity Estimates", status = "info", solidHeader = TRUE, width = 7,
        uiOutput(ns("capacity_result"))
      )
    ),

    fluidRow(
      box(title = "CAP Theorem", status = "primary", solidHeader = TRUE, width = 6,
        callout("<strong>CAP Theorem:</strong> A distributed system can guarantee at most 2 of the 3 properties simultaneously.", "info"),
        tags$br(),
        fluidRow(
          column(4,
            tags$div(class="callout callout-tip",
              tags$h6("⚡ Consistency"),
              tags$p("Every read receives the most recent write or an error.", style="font-size:11px;")
            )
          ),
          column(4,
            tags$div(class="callout callout-info",
              tags$h6("📡 Availability"),
              tags$p("Every request receives a response (not necessarily the latest data).", style="font-size:11px;")
            )
          ),
          column(4,
            tags$div(class="callout callout-warn",
              tags$h6("🌐 Partition Tolerance"),
              tags$p("System operates despite network partitions. Required in practice.", style="font-size:11px;")
            )
          )
        ),
        tags$br(),
        callout("In practice, <strong>network partitions are unavoidable</strong>, so you choose between CP (consistent, may be unavailable) and AP (available, may be stale).", "warn")
      ),
      box(title = "Key Components", status = "info", solidHeader = TRUE, width = 6,
        cplx_table(data.frame(
          Component       = c("Load Balancer", "CDN", "Cache", "DB Sharding", "Message Queue", "Rate Limiter"),
          Purpose         = c("Distribute traffic", "Edge delivery", "Reduce latency", "Scale writes", "Async/decouple", "Protect APIs"),
          Example         = c("Nginx, ALB", "CloudFront", "Redis, Memcached", "Consistent hash", "Kafka, RabbitMQ", "Token bucket"),
          stringsAsFactors = FALSE
        ))
      )
    ),

    fluidRow(
      box(title = "Caching Strategies", status = "primary", solidHeader = TRUE, width = 6,
        callout("<strong>Cache-Aside (Lazy Loading):</strong> App reads cache; on miss, loads from DB and populates cache. Simple, but cold-start misses.", "info"),
        callout("<strong>Write-Through:</strong> Write to cache and DB simultaneously. Always consistent, but adds write latency.", "tip"),
        callout("<strong>Write-Back (Write-Behind):</strong> Write to cache only; flush to DB asynchronously. Fast writes but risk of data loss.", "warn"),
        callout("<strong>Read-Through:</strong> Cache sits in front of DB, auto-populates on miss. Transparent to the app.", "info"),
        tags$br(),
        tags$p(tags$strong("LRU Cache (Python)"), style="font-size:12px;"),
        dsa_code(
'from collections import OrderedDict
class LRUCache:
    def __init__(self, cap):
        self.cap  = cap
        self.cache = OrderedDict()
    def get(self, key):
        if key not in self.cache: return -1
        self.cache.move_to_end(key)
        return self.cache[key]
    def put(self, key, val):
        if key in self.cache:
            self.cache.move_to_end(key)
        self.cache[key] = val
        if len(self.cache) > self.cap:
            self.cache.popitem(last=False)')
      ),
      box(title = "Consistent Hashing", status = "primary", solidHeader = TRUE, width = 6,
        callout("<strong>Problem:</strong> When you add/remove a server, naive hashing (key % n) remaps almost all keys.", "warn"),
        callout("<strong>Solution:</strong> Place both servers and keys on a virtual ring. A key is served by the next server clockwise. Adding a server only moves ~k/n keys.", "success"),
        tags$br(),
        tags$p(tags$strong("Design Framework (5-step)"), style="font-size:12px; font-weight:700;"),
        tags$ol(style="font-size:12px; color:#475569;",
          tags$li(tags$strong("Clarify requirements:"), " functional + non-functional (scale, latency, availability)"),
          tags$li(tags$strong("Capacity estimate:"), " QPS, storage, bandwidth"),
          tags$li(tags$strong("High-level design:"), " components, data flow, APIs"),
          tags$li(tags$strong("Deep-dive:"), " bottlenecks, DB schema, caching, sharding"),
          tags$li(tags$strong("Wrap-up:"), " failure modes, monitoring, future scale")
        ),
        callout("Always state assumptions out loud in an interview. Interviewers reward structured thinking over perfect answers.", "tip")
      )
    ),

    fluidRow(
      box(title = "Classic System Design Questions", status = "success", solidHeader = TRUE, width = 6,
        fluidRow(
          column(6,
            tags$div(class="prob-row", tags$span(class="lc-badge badge-medium","Medium"), tags$span(class="prob-title","Design URL Shortener (TinyURL)")),
            tags$div(class="prob-row", tags$span(class="lc-badge badge-medium","Medium"), tags$span(class="prob-title","Design Rate Limiter")),
            tags$div(class="prob-row", tags$span(class="lc-badge badge-medium","Medium"), tags$span(class="prob-title","Design Notification Service")),
            tags$div(class="prob-row", tags$span(class="lc-badge badge-hard","Hard"), tags$span(class="prob-title","Design Twitter/News Feed"))
          ),
          column(6,
            tags$div(class="prob-row", tags$span(class="lc-badge badge-hard","Hard"), tags$span(class="prob-title","Design Distributed Cache")),
            tags$div(class="prob-row", tags$span(class="lc-badge badge-hard","Hard"), tags$span(class="prob-title","Design Google Drive")),
            tags$div(class="prob-row", tags$span(class="lc-badge badge-hard","Hard"), tags$span(class="prob-title","Design YouTube")),
            tags$div(class="prob-row", tags$span(class="lc-badge badge-hard","Hard"), tags$span(class="prob-title","Design Web Crawler"))
          )
        )
      ),
      box(title = "Quick Quiz", status = "warning", solidHeader = TRUE, width = 3,
        uiOutput(ns("quiz_ui"))
      ),
      box(title = "Numbers Every Engineer Should Know", status = "info", solidHeader = TRUE, width = 3,
        cplx_table(data.frame(
          Operation   = c("L1 cache ref", "RAM access", "SSD read", "Network (DC)", "HDD seek"),
          Latency     = c("~1 ns", "~100 ns", "~100 μs", "~500 μs", "~10 ms"),
          stringsAsFactors = FALSE
        ))
      )
    ),

    ref_block(
      "Xu, A. (2020). System Design Interview: An Insider's Guide. Byte Code LLC.",
      "Martin, R.C. (2017). Clean Architecture. Prentice Hall.",
      "Kleppmann, M. (2017). Designing Data-Intensive Applications. O'Reilly."
    )
  )
}

systemdesign_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    output$capacity_result <- renderUI({
      input$btn_calc
      dau     <- isolate(input$dau)
      rpd     <- isolate(input$req_day)
      rs_kb   <- isolate(input$req_size)
      years   <- isolate(input$storage_y)

      total_req_day  <- dau * rpd
      qps_avg        <- total_req_day / 86400
      qps_peak       <- qps_avg * 5  # assume 5× peak
      bw_mbps        <- (qps_peak * rs_kb * 8) / 1e6
      storage_gb_day <- (total_req_day * rs_kb) / (1024 * 1024)
      storage_tb     <- storage_gb_day * 365 * years / 1000

      fmt_num <- function(x) formatC(x, format="f", big.mark=",", digits=0)
      fmt_dec <- function(x) formatC(x, format="f", big.mark=",", digits=1)

      rows <- list(
        list(label="Total requests/day",  val=paste0(fmt_num(total_req_day), " req")),
        list(label="Avg QPS",             val=paste0(fmt_dec(qps_avg), " req/s")),
        list(label="Peak QPS (5×)",       val=paste0(fmt_dec(qps_peak), " req/s")),
        list(label="Peak bandwidth",      val=paste0(fmt_dec(bw_mbps), " Mbps")),
        list(label="Storage/day",         val=paste0(fmt_dec(storage_gb_day), " GB/day")),
        list(label=paste0("Storage (",years,"yr)"), val=paste0(fmt_dec(storage_tb), " TB"))
      )

      tags$div(
        lapply(rows, function(r)
          tags$div(style="display:flex; justify-content:space-between; padding:6px 0; border-bottom:1px solid #e2e8f0; font-size:13px;",
            tags$span(style="color:#64748b;", r$label),
            tags$span(class="vnode visited", style="padding:3px 10px; font-size:12px;", r$val)
          )
        )
      )
    })

    # ── Quiz ─────────────────────────────────────────────────────────────────
    q_ans <- reactiveVal(NULL)
    output$quiz_ui <- renderUI({
      ans <- q_ans()
      tagList(
        tags$p(class="quiz-q","In CAP theorem, what must every real distributed system tolerate?"),
        tags$button(class=paste("qopt",if(!is.null(ans)&&ans=="a")"wrong" else ""),
          "Consistency", onclick=sprintf("Shiny.setInputValue('%s','a',{priority:'event'})",ns("qa"))),
        tags$button(class=paste("qopt",if(!is.null(ans)&&ans=="b")"wrong" else ""),
          "Availability", onclick=sprintf("Shiny.setInputValue('%s','b',{priority:'event'})",ns("qa"))),
        tags$button(class=paste("qopt",if(!is.null(ans)&&ans=="c")"right" else ""),
          "Partition Tolerance", onclick=sprintf("Shiny.setInputValue('%s','c',{priority:'event'})",ns("qa"))),
        if (!is.null(ans)) {
          if (ans=="c") tags$div(class="qfeedback right","✅ Correct! Network partitions are unavoidable in distributed systems. So you're always choosing between CP and AP.")
          else tags$div(class="qfeedback wrong","❌ Partition tolerance is non-negotiable in practice. The real choice is CP (sacrifice availability) vs AP (sacrifice consistency).")
        }
      )
    })
    observeEvent(input$qa, q_ans(input$qa))
  })
}
