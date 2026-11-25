# modules/mod_systemdesign.R — System Design Fundamentals

sd_frac <- function(x) { v <- sin(x) * 43758.5453; v - floor(v) }   # deterministic pseudo-hash in [0, 1)

systemdesign_ui <- function(id) {
  ns <- NS(id)
  tagList(
    topic_hero("🏗️", "System Design Fundamentals",
      "Design interviews reward structure and trade-off reasoning, not memorised architectures. Estimate the load, sketch the data flow, find the bottleneck, and say what you are giving up to fix it.",
      c("Capacity Estimation", "Caching", "Consistent Hashing", "Rate Limiting", "CAP Theorem", "Sharding")),

    topic_tabs(ns,
      visual = tagList(
        fluidRow(
          box(title = "Back-of-Envelope Capacity Estimator", status = "primary", solidHeader = TRUE, width = 5,
            fluidRow(
              column(6, numericInput(ns("dau"), "Daily active users:", 5e6, min = 1, step = 1e5)),
              column(6, numericInput(ns("rpu"), "Requests / user / day:", 20, min = 1))
            ),
            fluidRow(
              column(6, numericInput(ns("wr_pct"), "Writes (% of requests):", 10, min = 0, max = 100)),
              column(6, numericInput(ns("obj_kb"), "Stored size per write (KB):", 2, min = 0.01, step = 0.5))
            ),
            fluidRow(
              column(6, sliderInput(ns("peak"), "Peak ÷ average:", min = 1, max = 10, value = 3, step = 0.5)),
              column(6, sliderInput(ns("years"), "Retention (years):", min = 1, max = 10, value = 5, step = 1))
            ),
            fluidRow(
              column(6, sliderInput(ns("repl"), "Replication factor:", min = 1, max = 5, value = 3, step = 1)),
              column(6, numericInput(ns("srv_qps"), "QPS one server handles:", 1000, min = 1))
            )
          ),
          box(title = "What the numbers imply", status = "info", solidHeader = TRUE, width = 7,
            uiOutput(ns("cap_kpi")),
            plotlyOutput(ns("cap_plot"), height = "220px"),
            uiOutput(ns("cap_explain"))
          )
        ),
        fluidRow(
          box(title = "Consistent Hashing — adding a server without reshuffling everything", status = "primary", solidHeader = TRUE, width = 8,
            fluidRow(
              column(4, sliderInput(ns("ch_s"), "Servers:", min = 2, max = 8, value = 4, step = 1)),
              column(4, sliderInput(ns("ch_v"), "Virtual nodes per server:", min = 1, max = 40, value = 1, step = 1)),
              column(4, checkboxInput(ns("ch_add"), "Add one more server", FALSE))
            ),
            fluidRow(
              column(7, plotlyOutput(ns("ch_ring"), height = "340px")),
              column(5, plotlyOutput(ns("ch_load"), height = "340px"))
            )
          ),
          box(title = "Why it matters", status = "info", solidHeader = TRUE, width = 4,
            uiOutput(ns("ch_kpi")),
            callout("Servers and keys are hashed onto the same ring; a key belongs to the first server clockwise from it. A new server only takes over the arc just behind it — about <b>1 / N</b> of the keys.", "info"),
            callout("With one point per server the arcs are very uneven. Raise <b>virtual nodes</b> and watch the load bars level out: each server is scattered around the ring many times.", "tip")
          )
        ),
        fluidRow(
          box(title = "LRU Cache Simulator", status = "primary", solidHeader = TRUE, width = 6,
            fluidRow(
              column(8, textInput(ns("lru_seq"), "Access sequence:", "A,B,C,A,D,B,E,A,C,F,A")),
              column(4, sliderInput(ns("lru_cap"), "Capacity:", min = 1, max = 6, value = 3, step = 1))
            ),
            stepper_ui(ns, "lru"),
            uiOutput(ns("lru_viz"))
          ),
          box(title = "Token Bucket Rate Limiter", status = "primary", solidHeader = TRUE, width = 6,
            fluidRow(
              column(4, sliderInput(ns("tb_rate"), "Refill (tokens/s):", min = 1, max = 20, value = 5, step = 1)),
              column(4, sliderInput(ns("tb_cap"), "Bucket size (burst):", min = 1, max = 50, value = 15, step = 1)),
              column(4, selectInput(ns("tb_traffic"), "Traffic:", c("Steady 4/s" = "steady", "Bursty" = "bursty", "Spike at t = 15" = "spike")))
            ),
            plotlyOutput(ns("tb_plot"), height = "250px"),
            uiOutput(ns("tb_explain"))
          )
        ),
        fluidRow(
          box(title = "Latency Numbers — the scale behind every design decision", status = "info", solidHeader = TRUE, width = 12,
            fluidRow(
              column(8, plotlyOutput(ns("lat_plot"), height = "380px")),
              column(4,
                callout("The axis is logarithmic: each gridline is 10× slower. Memory is ~100,000× faster than a disk seek, and a cross-continent round trip costs about as much as 1.5 million RAM reads.", "info"),
                callout("<b>Design consequences:</b> cache in memory, batch network calls, keep chatty services in the same data centre, read sequentially rather than randomly, and put a CDN close to users.", "tip"),
                hint("Classic figures popularised by Jeff Dean and Peter Norvig. Modern hardware has improved several of them (notably SSDs); the <i>ratios</i> are what you should remember."))
            )
          )
        )
      ),

      learn = tagList(
        insight_cards(
          when = c("Reads dominate and data tolerates being slightly stale → cache and replicate.",
                   "Writes or data volume exceed one machine → partition (shard) by a well-chosen key.",
                   "Work is slow or spiky and need not finish inside the request → queue it and process asynchronously.",
                   "A dependency can fail or be flooded → timeouts, retries with back-off, rate limits, circuit breakers."),
          pitfalls = c("Drawing boxes before asking about scale, read / write ratio and consistency needs.",
                       "A single point of failure hiding in plain sight (one load balancer, one primary DB, one cache node).",
                       "Choosing a shard key that creates hot partitions (e.g. celebrity user IDs, timestamps).",
                       "Adding a cache without a story for invalidation and for a cold or stampeding cache."),
          tips = c("Spend the first five minutes on requirements and numbers; state assumptions aloud.",
                   "Every component you add should answer a named bottleneck. Say the trade-off: 'this buys X at the cost of Y'.",
                   "Go deep on one or two parts rather than shallow on ten — and finish with failure modes and monitoring.")
        ),
        fluidRow(
          box(title = "A framework for the 45 minutes", status = "primary", solidHeader = TRUE, width = 6,
            cplx_table(data.frame(
              Step = c("1. Requirements", "2. Estimates", "3. API & data model", "4. High-level design", "5. Deep dive", "6. Wrap-up"),
              Minutes = c("5", "5", "5", "10", "15", "5"),
              Output = c("Functional scope; scale, latency, availability, consistency targets", "QPS, storage, bandwidth, read / write ratio",
                         "Endpoints, main entities, access patterns → SQL or NoSQL", "Clients → LB → services → cache / DB / queue, with the data flow",
                         "The hardest one or two parts: sharding, fan-out, ranking, consistency", "Bottlenecks, failure modes, monitoring, what you would do next"),
              stringsAsFactors = FALSE))
          ),
          box(title = "CAP theorem, practically", status = "info", solidHeader = TRUE, width = 6,
            callout("When the network <b>partitions</b>, a distributed store must choose: refuse some requests to stay <b>consistent</b> (CP), or keep answering and risk stale data (<b>available</b>, AP). Partitions are a fact of life, so the real choice is C versus A <i>during</i> a partition.", "info"),
            cplx_table(data.frame(
              Choice = c("CP", "AP", "Tunable"),
              Behaviour.during.partition = c("Minority side rejects writes", "Both sides accept; reconcile later", "Per-request quorum (R + W &gt; N for strong reads)"),
              Typical.systems = c("ZooKeeper, etcd, HBase, most relational primaries", "Cassandra, DynamoDB, CouchDB, DNS", "Cassandra, DynamoDB, Riak"),
              Good.for = c("Balances, inventory, locks, leader election", "Feeds, carts, likes, presence", "Mixed workloads"),
              stringsAsFactors = FALSE)),
            hint("PACELC extends CAP: <b>E</b>lse (no partition) you still trade <b>L</b>atency against <b>C</b>onsistency.")
          )
        ),
        fluidRow(
          box(title = "Building blocks", status = "info", solidHeader = TRUE, width = 6,
            cplx_table(data.frame(
              Component = c("Load balancer", "CDN", "Cache", "Read replicas", "Sharding", "Message queue", "Rate limiter", "Object storage", "Search index"),
              Solves = c("Spreads traffic, removes dead servers", "Static content near the user", "Repeated expensive reads", "Read-heavy load", "Write / data volume beyond one node",
                         "Decouples and smooths spiky work", "Abuse and overload", "Large blobs: images, video, backups", "Full-text and faceted queries"),
              Costs = c("Another hop; must itself be redundant", "Invalidation, cost", "Staleness, invalidation", "Replication lag", "Cross-shard queries and transactions", "Eventual consistency, ordering, duplicates",
                        "Legitimate users can be throttled", "Not for small transactional records", "Extra pipeline to keep in sync"),
              Examples = c("Nginx, HAProxy, ALB", "CloudFront, Fastly", "Redis, Memcached", "MySQL / Postgres replicas", "Vitess, Citus, DynamoDB", "Kafka, SQS, RabbitMQ", "Token bucket at the gateway", "S3, GCS", "Elasticsearch"),
              stringsAsFactors = FALSE))
          ),
          box(title = "Caching strategies", status = "info", solidHeader = TRUE, width = 6,
            cplx_table(data.frame(
              Strategy = c("Cache-aside", "Read-through", "Write-through", "Write-behind"),
              How = c("App checks cache; on miss reads DB and fills cache", "Cache library loads from DB on miss", "Write to cache and DB together", "Write to cache; flush to DB asynchronously"),
              Trade.off = c("Simple and resilient; first read is slow, stale until TTL", "Same as cache-aside, less app code", "Always fresh; slower writes", "Fast writes; data loss if the cache dies"),
              stringsAsFactors = FALSE)),
            cplx_table(data.frame(
              Eviction = c("LRU", "LFU", "TTL", "FIFO"),
              Evicts = c("Least recently used", "Least frequently used", "Anything older than its time-to-live", "Oldest inserted"),
              Best.when = c("Recent items are likely to be reused (default)", "Stable popularity, long-lived hot set", "Data has a natural freshness window", "Simplicity matters more than hit rate"),
              stringsAsFactors = FALSE))
          )
        ),
        fluidRow(
          box(title = "Classic questions and their core idea", status = "success", solidHeader = TRUE, width = 6,
            cplx_table(data.frame(
              Design = c("URL shortener", "Rate limiter", "News feed / timeline", "Chat / messaging", "Typeahead search", "Web crawler", "Video streaming", "Distributed cache"),
              The.crux = c("ID generation + base-62 encoding; heavy read caching", "Token bucket in Redis, keyed per user / IP", "Fan-out on write vs on read; hybrid for celebrities", "WebSockets, per-user queues, delivery receipts",
                           "Trie or prefix index of top queries, precomputed", "URL frontier, politeness, de-duplication (Bloom filter)", "Chunking, adaptive bitrate, CDN", "Consistent hashing, replication, eviction"),
              stringsAsFactors = FALSE))
          ),
          box(title = "Data-structure-level designs (Python)", status = "primary", solidHeader = TRUE, width = 6,
            fluidRow(
              column(6, dsa_code(
'class LRUCache:
    def __init__(self, capacity):
        self.cap = capacity
        self.d = OrderedDict()

    def get(self, key):
        if key not in self.d:
            return -1
        self.d.move_to_end(key)     # most recent
        return self.d[key]

    def put(self, key, value):
        self.d[key] = value
        self.d.move_to_end(key)
        if len(self.d) > self.cap:
            self.d.popitem(last=False)  # evict LRU', "LRU cache — O(1) get / put")),
              column(6, dsa_code(
'class TokenBucket:
    def __init__(self, rate, capacity):
        self.rate, self.cap = rate, capacity
        self.tokens = capacity
        self.last = time.monotonic()

    def allow(self):
        now = time.monotonic()
        self.tokens = min(self.cap,
            self.tokens + (now - self.last) * self.rate)
        self.last = now
        if self.tokens >= 1:
            self.tokens -= 1
            return True
        return False', "Token bucket"))
            )
          )
        )
      ),

      practice = practice_tab(ns, "systemdesign",
        "Kleppmann, M. (2017). Designing Data-Intensive Applications. O'Reilly.",
        "Karger et al. (1997). Consistent hashing and random trees. STOC '97.",
        "Gilbert & Lynch (2002). Brewer's conjecture and the feasibility of consistent, available, partition-tolerant web services. SIGACT News 33(2).",
        "Xu, A. (2020). System Design Interview: An Insider's Guide.")
    )
  )
}

systemdesign_server <- function(id, progress = NULL) {
  moduleServer(id, function(input, output, session) {

    num <- function(x, d) { x <- suppressWarnings(as.numeric(x)); if (length(x) != 1 || is.na(x)) d else x }
    human <- function(x, units = c("", "K", "M", "B", "T")) {
      i <- 1; while (abs(x) >= 1000 && i < length(units)) { x <- x / 1000; i <- i + 1 }
      paste0(formatC(x, format = "f", digits = if (x >= 100 || x == round(x)) 0 else 1), units[i])
    }
    bytes <- function(kb) human(kb, c(" KB", " MB", " GB", " TB", " PB"))

    # ── Capacity ─────────────────────────────────────────────────────────────
    cap <- reactive({
      dau <- num(input$dau, 1e6); rpu <- num(input$rpu, 10); wr <- min(100, max(0, num(input$wr_pct, 10))) / 100
      kb <- num(input$obj_kb, 1); peak <- input$peak %||% 3; years <- input$years %||% 5; repl <- input$repl %||% 3
      per_day <- dau * rpu; qps <- per_day / 86400
      list(per_day = per_day, qps = qps, peak = qps * peak, wqps = qps * wr, rqps = qps * (1 - wr),
           day_kb = per_day * wr * kb, total_kb = per_day * wr * kb * 365 * years * repl, years = years, repl = repl,
           servers = ceiling(qps * peak / max(1, num(input$srv_qps, 1000))), ratio = if (wr > 0) (1 - wr) / wr else Inf, kb = kb)
    })
    output$cap_kpi <- renderUI({
      c <- cap()
      tagList(
        kpi_row(kpi(human(c$qps), "average QPS", COL$pri), kpi(human(c$peak), "peak QPS", COL$err), kpi(human(c$wqps), "write QPS", COL$warn), kpi(c$servers, "app servers at peak", COL$sec)),
        kpi_row(kpi(bytes(c$day_kb), "new data / day", COL$acc), kpi(bytes(c$total_kb), sprintf("%d yr × %d replicas", c$years, c$repl), COL$ok),
                kpi(if (is.finite(c$ratio)) sprintf("%.0f : 1", c$ratio) else "∞", "read : write", COL$pri)))
    })
    output$cap_plot <- renderPlotly({
      c <- cap(); yr <- 0:c$years; gb <- c$day_kb * 365 * yr * c$repl / 1e6
      plot_ly(x = yr, y = gb, type = "scatter", mode = "lines+markers", fill = "tozeroy", height = 220,
              line = list(color = COL$pri, width = 3), marker = list(color = COL$pri), fillcolor = "rgba(79,70,229,.15)") %>%
        dsa_layout(xt = "years in production", yt = "storage (GB, replicated)")
    })
    output$cap_explain <- renderUI({
      c <- cap()
      explain(sprintf("%s requests/day ÷ 86,400 s ≈ <b>%s QPS</b> (handy shortcut: 1 M/day ≈ 12 QPS). %s %s",
        human(c$per_day), human(c$qps),
        if (c$ratio >= 5) "The workload is <b>read-heavy</b> → caching and read replicas pay off first." else "Writes are a large share → think early about partitioning and write throughput.",
        if (c$total_kb > 5e9) "Total storage is beyond a single node → plan for <b>sharding</b> or a distributed store." else "Total storage still fits on one well-provisioned node (plus replicas)."))
    })

    # ── Consistent hashing ───────────────────────────────────────────────────
    ch_owner <- function(S, V, kp) {
      pts <- do.call(rbind, lapply(seq_len(S), function(s) data.frame(server = s, pos = sd_frac(s * 127.1 + seq_len(V) * 311.7))))
      pts <- pts[order(pts$pos), ]
      idx <- findInterval(kp, pts$pos) + 1; idx[idx > nrow(pts)] <- 1
      list(owner = pts$server[idx], pts = pts)
    }
    ch <- reactive({
      S <- input$ch_s; V <- input$ch_v; req(S, V)
      K <- 400; kp <- sd_frac(seq_len(K) * 12.9898 + 4.1)
      base <- ch_owner(S, V, kp); plus <- ch_owner(S + 1, V, kp)
      cur <- if (isTRUE(input$ch_add)) plus else base
      list(S = S, V = V, K = K, kp = kp, cur = cur, nS = if (isTRUE(input$ch_add)) S + 1 else S,
           moved_ch = mean(base$owner != plus$owner), moved_mod = mean((seq_len(K) %% S) != (seq_len(K) %% (S + 1))),
           changed = base$owner != plus$owner)
    })
    ch_pal <- c("#4f46e5", "#f59e0b", "#10b981", "#ec4899", "#06b6d4", "#7c3aed", "#ef4444", "#84cc16", "#0f172a")
    output$ch_ring <- renderPlotly({
      r <- ch(); th <- function(p) pi / 2 - 2 * pi * p
      circ <- seq(0, 2 * pi, length.out = 200)
      p <- plot_ly(height = 340) %>%
        add_trace(x = cos(circ), y = sin(circ), type = "scatter", mode = "lines", line = list(color = "#e2e8f0", width = 2), hoverinfo = "none", showlegend = FALSE) %>%
        add_trace(x = 0.9 * cos(th(r$kp)), y = 0.9 * sin(th(r$kp)), type = "scatter", mode = "markers", showlegend = FALSE,
                  marker = list(size = if (isTRUE(input$ch_add)) ifelse(r$changed, 8, 4) else 5, color = ch_pal[r$cur$owner], opacity = 0.75), hoverinfo = "none")
      pts <- r$cur$pts
      p %>% add_trace(x = cos(th(pts$pos)), y = sin(th(pts$pos)), type = "scatter", mode = "markers", showlegend = FALSE,
                      marker = list(size = if (r$V > 10) 9 else 16, color = ch_pal[pts$server], symbol = "diamond", line = list(color = "#fff", width = 1.5)),
                      hovertext = paste("server", pts$server), hoverinfo = "text") %>%
        layout(xaxis = list(visible = FALSE, range = c(-1.15, 1.15), fixedrange = TRUE), yaxis = list(visible = FALSE, range = c(-1.15, 1.15), scaleanchor = "x", fixedrange = TRUE),
               margin = list(l = 5, r = 5, t = 28, b = 5), plot_bgcolor = "#f8fafc", paper_bgcolor = "#f8fafc",
               title = list(text = "Hash ring: ◆ servers, • keys (coloured by owner)", font = list(size = 12), x = 0.02)) %>% config(displayModeBar = FALSE)
    })
    output$ch_load <- renderPlotly({
      r <- ch(); load <- tabulate(r$cur$owner, r$nS); ideal <- r$K / r$nS
      plot_ly(x = paste("S", seq_len(r$nS)), y = load, type = "bar", height = 340, marker = list(color = ch_pal[seq_len(r$nS)]), text = load, textposition = "outside") %>%
        dsa_layout(title = "Keys per server", yt = "keys") %>%
        layout(xaxis = list(categoryorder = "array", categoryarray = paste("S", seq_len(r$nS))),
               shapes = list(list(type = "line", x0 = -0.5, x1 = r$nS - 0.5, y0 = ideal, y1 = ideal, line = list(color = COL$mute, dash = "dash", width = 2))),
               yaxis = list(range = c(0, max(load) * 1.2)))
    })
    output$ch_kpi <- renderUI({
      r <- ch(); load <- tabulate(r$cur$owner, r$nS)
      tagList(
        tags$div(class = "code-title", sprintf("Keys that move when server %d joins", r$S + 1)),
        kpi_row(kpi(sprintf("%.0f%%", 100 * r$moved_ch), "consistent hashing", COL$ok), kpi(sprintf("%.0f%%", 100 * r$moved_mod), "hash mod N", COL$err)),
        kpi_row(kpi(sprintf("%.0f%%", 100 / (r$S + 1)), "ideal (1 / N)", COL$pri), kpi(sprintf("%.1f×", max(load) / (r$K / r$nS)), "busiest vs ideal load", if (max(load) / (r$K / r$nS) > 1.5) COL$warn else COL$ok)))
    })

    # ── LRU ──────────────────────────────────────────────────────────────────
    lru_seq <- reactive({
      s <- trimws(strsplit(input$lru_seq %||% "", ",")[[1]]); s <- head(s[nzchar(s)], 20)
      validate(need(length(s) >= 1, "Enter an access sequence like A,B,C,A."))
      s
    })
    lru_steps <- reactive({
      s <- lru_seq(); cap <- input$lru_cap; req(cap)
      cache <- character(0); hits <- 0
      steps <- list(list(i = 0, cache = cache, hits = 0, kind = "", msg = sprintf("An empty cache with room for %d item(s). The left end is the most recently used; the right end is next to be evicted.", cap)))
      for (i in seq_along(s)) {
        k <- s[i]
        if (k %in% cache) { cache <- c(k, setdiff(cache, k)); hits <- hits + 1; kind <- "hit"; msg <- sprintf("<b>%s</b> is cached → <b>hit</b>. Move it to the front (most recent).", k) }
        else if (length(cache) >= cap) { ev <- cache[length(cache)]; cache <- c(k, cache[-length(cache)]); kind <- "evict"; msg <- sprintf("<b>%s</b> is not cached → <b>miss</b>, and the cache is full. Evict the least recently used (<b>%s</b>) and insert %s at the front.", k, ev, k) }
        else { cache <- c(k, cache); kind <- "miss"; msg <- sprintf("<b>%s</b> is not cached → <b>miss</b>. There is room, so insert it at the front.", k) }
        steps[[length(steps) + 1]] <- list(i = i, cache = cache, hits = hits, kind = kind, msg = msg)
      }
      steps
    })
    lru <- stepper_server(input, output, session, "lru", lru_steps)
    output$lru_viz <- renderUI({
      s <- lru_seq(); st <- lru$cur()
      cls <- ifelse(seq_along(s) < st$i, "dim", ""); if (st$i >= 1) cls[st$i] <- switch(st$kind, hit = "found", evict = "bad", "active")
      ccls <- rep("visited", length(st$cache)); if (length(st$cache) && st$i >= 1) ccls[1] <- if (st$kind == "hit") "found" else "active"
      tagList(
        vrow(s, cls, idx = FALSE),
        tags$div(class = "code-title", style = "margin-top:10px;", "Cache contents"),
        vrow(st$cache, ccls, ptr = if (length(st$cache) > 1) setNames(list(1, length(st$cache)), c("MRU", "LRU")) else if (length(st$cache) == 1) list(MRU = 1) else NULL, idx = FALSE, arrows = TRUE),
        kpi_row(kpi(st$hits, "hits", COL$ok), kpi(st$i - st$hits, "misses", COL$err), kpi(if (st$i) sprintf("%.0f%%", 100 * st$hits / st$i) else "—", "hit rate", COL$pri)),
        explain(st$msg))
    })

    # ── Token bucket ─────────────────────────────────────────────────────────
    tbk <- reactive({
      rate <- input$tb_rate; cap <- input$tb_cap; req(rate, cap)
      t <- 0:39
      arr <- switch(input$tb_traffic,
        steady = rep(4, 40),
        bursty = ifelse((t %/% 4) %% 2 == 0, 1, 12),
        spike  = ifelse(t >= 15 & t < 20, 30, 3))
      tok <- cap; ok <- numeric(40); level <- numeric(40)
      for (i in seq_along(t)) {
        tok <- min(cap, tok + rate); ok[i] <- min(arr[i], floor(tok)); tok <- tok - ok[i]; level[i] <- tok
      }
      list(t = t, arr = arr, ok = ok, rej = arr - ok, level = level, rate = rate, cap = cap)
    })
    output$tb_plot <- renderPlotly({
      r <- tbk()
      plot_ly(x = r$t, height = 250) %>%
        add_bars(y = r$ok, name = "allowed", marker = list(color = COL$ok)) %>%
        add_bars(y = r$rej, name = "rejected (HTTP 429)", marker = list(color = COL$err)) %>%
        add_trace(y = r$level, type = "scatter", mode = "lines", name = "tokens left", line = list(color = COL$pri, width = 2.5)) %>%
        dsa_layout(xt = "time (s)", yt = "requests / tokens", legend = TRUE) %>% layout(barmode = "stack")
    })
    output$tb_explain <- renderUI({
      r <- tbk(); tot <- sum(r$arr)
      explain(sprintf("%d of %d requests allowed (<b>%.0f%%</b>). The bucket refills at %d tokens/s — the <b>sustained</b> rate — and holds at most %d, which is the largest <b>burst</b> it will absorb. A full bucket lets a short spike through; once drained, traffic is clipped to the refill rate.",
                      sum(r$ok), tot, 100 * sum(r$ok) / tot, r$rate, r$cap))
    })

    # ── Latency numbers ──────────────────────────────────────────────────────
    output$lat_plot <- renderPlotly({
      d <- data.frame(
        op = c("L1 cache reference", "Branch mispredict", "L2 cache reference", "Mutex lock / unlock", "Main memory reference",
               "Compress 1 KB (Snappy)", "Send 1 KB over 1 Gbps", "SSD random read", "Read 1 MB sequentially from RAM",
               "Round trip within a data centre", "Read 1 MB sequentially from SSD", "Disk seek", "Read 1 MB sequentially from disk", "Packet California → Netherlands → California"),
        ns = c(0.5, 5, 7, 25, 100, 3e3, 1e4, 1.5e5, 2.5e5, 5e5, 1e6, 1e7, 2e7, 1.5e8),
        kind = c("CPU", "CPU", "CPU", "CPU", "Memory", "CPU", "Network", "Storage", "Memory", "Network", "Storage", "Storage", "Storage", "Network"),
        stringsAsFactors = FALSE)
      nice <- function(ns) ifelse(ns < 1e3, paste0(ns, " ns"), ifelse(ns < 1e6, paste0(ns / 1e3, " µs"), paste0(ns / 1e6, " ms")))
      colr <- c(CPU = COL$pri, Memory = COL$ok, Network = COL$warn, Storage = COL$err)
      d$op <- factor(d$op, levels = rev(d$op))
      p <- plot_ly(height = 380)
      for (k in names(colr)) { dd <- d[d$kind == k, ]
        p <- add_trace(p, x = dd$ns, y = dd$op, type = "bar", orientation = "h", name = k, marker = list(color = colr[[k]]),
                       text = nice(dd$ns), textposition = "outside", hoverinfo = "text", hovertext = paste0(dd$op, ": ", nice(dd$ns))) }
      p %>% dsa_layout(xt = "nanoseconds (log scale)", legend = TRUE) %>%
        layout(xaxis = list(type = "log", range = c(-0.6, 9.3)), yaxis = list(title = "", categoryorder = "array", categoryarray = levels(d$op)), margin = list(l = 290))
    })

    quiz_server(input, output, session, topic = "systemdesign", progress = progress, questions = list(
      list(q = "A service gets 86.4 million requests per day. Its average load is about…",
           opts = c("100 QPS", "1,000 QPS", "10,000 QPS", "86,400 QPS"), ans = 2,
           why = "A day has 86,400 seconds: 86.4 M ÷ 86,400 = 1,000 QPS. Then multiply by a peak factor."),
      list(q = "Going from 4 to 5 cache servers with <code>hash(key) % N</code> remaps roughly what share of keys?",
           opts = c("20%", "25%", "50%", "80%"), ans = 4,
           why = "A key keeps its server only if its hash gives the same remainder mod 4 and mod 5 — about 1 in 5. Consistent hashing moves only ~1/5."),
      list(q = "During a network partition, a CP system will…",
           opts = c("Serve possibly stale data from every node", "Reject some requests rather than return inconsistent data", "Lose all data", "Automatically merge conflicts"), ans = 2,
           why = "CP sacrifices availability on the minority side to guarantee that every successful read reflects the latest write."),
      list(q = "In a token bucket, the bucket <b>size</b> controls…",
           opts = c("The long-run average rate", "The largest burst that can pass at once", "The number of users", "The retry delay"), ans = 2,
           why = "Refill rate sets the sustained throughput; capacity sets how many requests can go through back-to-back after a quiet period."),
      list(q = "The workload is 100 reads per write and data may be a few seconds stale. First scaling move?",
           opts = c("Shard the database", "Add a cache and read replicas", "Switch to a message queue", "Use stronger consistency"), ans = 2,
           why = "Read-heavy and staleness-tolerant is the ideal case for caching and replication. Sharding addresses write or storage limits.")
    ))
  })
}
