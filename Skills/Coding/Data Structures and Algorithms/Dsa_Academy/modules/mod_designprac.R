# modules/mod_designprac.R — System / product design interview practice: step-by-step walkthroughs with
# architecture diagrams, and a timed practice mode with a coverage checklist.

DESIGN_PHASES <- c(req = "1 · Requirements", est = "2 · Estimates", api = "3 · API", data = "4 · Data model",
                   hld = "5 · High-level design", deep = "6 · Deep dives", wrap = "7 · Bottlenecks & wrap-up")

# Architecture diagram: boxes + arrows. nodes: id, label, x, y [, kind]; edges: from, to [, label]
arch_plot <- function(nodes, edges, show = nodes$id, new = character(0), focus = character(0), height = 400) {
  kind_col <- c(client = "#e0f2fe", edge = "#ede9fe", service = "#e0e7ff", store = "#dcfce7", cache = "#fef3c7", queue = "#fce7f3", worker = "#f1f5f9")
  kind_bd  <- c(client = "#0284c7", edge = "#7c3aed", service = COL$pri, store = "#059669", cache = "#d97706", queue = "#db2777", worker = "#64748b")
  nodes$kind[is.na(nodes$kind)] <- "service"
  vis <- nodes$id %in% show
  shapes <- list(); anns <- list(); w <- 0.9; h <- 0.42
  for (i in which(vis)) {
    n <- nodes[i, ]; hl <- n$id %in% c(new, focus)
    shapes[[length(shapes) + 1]] <- list(type = "rect", x0 = n$x - w / 2, x1 = n$x + w / 2, y0 = n$y - h / 2, y1 = n$y + h / 2,
      fillcolor = kind_col[[n$kind]], line = list(color = if (hl) COL$err else kind_bd[[n$kind]], width = if (hl) 3.5 else 1.6), layer = "above")
    anns[[length(anns) + 1]] <- list(x = n$x, y = n$y, text = paste0(if (n$id %in% new) "★ " else "", n$label), showarrow = FALSE,
      font = list(size = 11.5, color = "#0f172a"), xanchor = "center", yanchor = "middle")
  }
  for (j in seq_len(nrow(edges))) {
    e <- edges[j, ]; if (!(e$from %in% show && e$to %in% show)) next
    a <- nodes[nodes$id == e$from, ]; b <- nodes[nodes$id == e$to, ]
    # shorten to the box borders
    dx <- b$x - a$x; dy <- b$y - a$y; L <- sqrt(dx^2 + dy^2); if (L == 0) next
    tx <- min(if (dx != 0) (w / 2) / abs(dx) else Inf, if (dy != 0) (h / 2) / abs(dy) else Inf)
    x0 <- a$x + dx * tx; y0 <- a$y + dy * tx; x1 <- b$x - dx * tx; y1 <- b$y - dy * tx
    hot <- e$from %in% c(new, focus) || e$to %in% c(new, focus)
    anns[[length(anns) + 1]] <- list(x = x1, y = y1, ax = x0, ay = y0, xref = "x", yref = "y", axref = "x", ayref = "y", text = "",
      showarrow = TRUE, arrowhead = 2, arrowsize = 1, arrowwidth = if (hot) 2.4 else 1.5, arrowcolor = if (hot) COL$err else "#94a3b8")
    if (!is.na(e$label) && nzchar(e$label))
      anns[[length(anns) + 1]] <- list(x = (x0 + x1) / 2, y = (y0 + y1) / 2, text = e$label, showarrow = FALSE, font = list(size = 9.5, color = "#475569"),
                                       bgcolor = "rgba(255,255,255,.85)")
  }
  xr <- range(nodes$x) + c(-0.7, 0.7); yr <- range(nodes$y) + c(-0.5, 0.5)
  plot_ly(x = nodes$x[vis], y = nodes$y[vis], type = "scatter", mode = "markers", marker = list(size = 1, opacity = 0),
          hoverinfo = "text", hovertext = nodes$label[vis], height = height) %>%
    layout(shapes = shapes, annotations = anns, showlegend = FALSE,
           xaxis = list(visible = FALSE, range = xr, fixedrange = TRUE), yaxis = list(visible = FALSE, range = yr, fixedrange = TRUE),
           margin = list(l = 5, r = 5, t = 5, b = 5), plot_bgcolor = "#f8fafc", paper_bgcolor = "#f8fafc") %>%
    config(displayModeBar = FALSE)
}

nd <- function(...) { x <- rbind(...); x$kind <- as.character(x$kind); x }
N <- function(id, label, x, y, kind = "service") data.frame(id = id, label = label, x = x, y = y, kind = kind, stringsAsFactors = FALSE)
E <- function(from, to, label = "") data.frame(from = from, to = to, label = label, stringsAsFactors = FALSE)

DESIGN_CASES <- list(
  shortener = list(
    title = "URL shortener (TinyURL / bit.ly)", co = "Google · Meta", minutes = 40,
    nodes = nd(N("cl", "Client", 0, 2, "client"), N("lb", "Load balancer", 1.4, 2, "edge"), N("api", "API servers", 2.8, 2),
               N("kgs", "Key generator<br>(ID ranges)", 2.8, 0.6, "worker"), N("cache", "Redis cache<br>code → URL", 4.3, 3, "cache"),
               N("db", "KV store<br>(sharded by code)", 4.3, 2, "store"), N("q", "Click events<br>(Kafka)", 4.3, 0.9, "queue"),
               N("an", "Analytics<br>aggregator", 5.8, 0.9, "worker"), N("cdn", "CDN / edge<br>redirect cache", 1.4, 3.2, "edge")),
    edges = rbind(E("cl", "cdn", "GET /abc"), E("cl", "lb"), E("lb", "api"), E("api", "kgs", "lease range"), E("api", "cache", "read"),
                  E("api", "db", "write / miss"), E("api", "q", "click"), E("q", "an")),
    steps = list(
      list(phase = "req", show = c("cl"), new = "cl", title = "Clarify the scope",
           text = "<b>Functional:</b> create a short code for a long URL (optional custom alias, optional expiry); redirect code → URL; basic click counts.<br><b>Non-functional:</b> redirects must be fast (p99 &lt; 50 ms) and highly available; read-heavy (≈ 100 : 1); codes unguessable enough; links never break.<br><b>Out of scope (say it):</b> user accounts, spam detection, editing links."),
      list(phase = "est", show = c("cl"), title = "Back-of-the-envelope",
           text = "100 M new links / month ≈ <b>40 writes/s</b> (peak ×5 = 200/s). Reads at 100 : 1 ≈ <b>4 000/s</b>, peak 20 000/s.<br>Storage: 100 M × 12 months × 5 years × ~500 B ≈ <b>3 TB</b> — fits a modest sharded KV store.<br>Code length: 62⁷ ≈ 3.5 × 10¹² ≫ 6 × 10⁹ links → <b>7 base-62 characters</b>."),
      list(phase = "api", show = c("cl", "lb", "api"), new = c("lb", "api"), title = "API",
           text = "<code>POST /v1/links {url, alias?, ttl?} → 201 {code}</code><br><code>GET /{code} → 301/302 Location: url</code> (302 if you need every click counted; 301 lets browsers cache).<br><code>GET /v1/links/{code}/stats</code>. Rate-limit creation per API key."),
      list(phase = "data", show = c("cl", "lb", "api", "db"), new = "db", title = "Data model",
           text = "<code>links(code PK, long_url, owner_id, created_at, expires_at)</code> — a pure key-value access pattern, so a KV / wide-column store (DynamoDB, Bigtable, Cassandra) sharded by <code>code</code>. Optional index long_url → code if you want de-duplication."),
      list(phase = "hld", show = c("cl", "lb", "api", "db", "kgs"), new = "kgs", title = "Generating codes",
           text = "Options: <b>hash</b> the URL (collisions, need retries), <b>random</b> 7 chars (check-and-set), or a <b>counter → base 62</b>. A key-generation service hands each API server a <b>range of IDs</b> (e.g. 1 000 at a time from a coordinated counter), so creation needs no cross-server coordination. Shuffle / encrypt the ID if codes must not be sequential."),
      list(phase = "hld", show = c("cl", "lb", "api", "db", "kgs", "cache", "cdn"), new = c("cache", "cdn"), title = "Make reads fast",
           text = "Redirects dominate. Put a <b>read-through cache</b> (Redis, LRU) in front of the store — a small fraction of links gets most clicks, so a high hit rate is cheap. Edge / CDN caching of 301s takes load off entirely, at the cost of losing click counts."),
      list(phase = "deep", show = c("cl", "lb", "api", "db", "kgs", "cache", "cdn", "q", "an"), new = c("q", "an"), title = "Deep dive: analytics without slowing redirects",
           text = "Redirect path writes a click event to a <b>log / queue</b> asynchronously and returns immediately. A stream aggregator rolls counts up per code / minute into an analytics store. Duplicate or lost events only affect stats, not redirects."),
      list(phase = "wrap", show = c("cl", "lb", "api", "db", "kgs", "cache", "cdn", "q", "an"), focus = c("db", "kgs"), title = "Bottlenecks & trade-offs",
           text = "• Hot keys → replicate in cache, consistent hashing.<br>• KGS is a SPOF → run several, each with its own range; losing an un-used range only wastes IDs.<br>• Expiry → TTL in the store + lazy check on read.<br>• Custom aliases → conditional put (fail if exists).<br>• Multi-region: reads served locally, writes to a home region per code prefix.")),
    checklist = c("Read : write ratio stated", "QPS and storage estimated", "Code length justified (base 62)", "Create + redirect APIs",
                  "301 vs 302 trade-off", "ID generation without collisions", "Cache in front of the store", "Sharding key chosen",
                  "Async analytics", "Expiry / custom alias", "Failure of a component discussed"),
    keywords = c("base62|base 62", "cache|redis", "shard|partition", "301|302", "range|counter|snowflake", "kafka|queue|async", "ttl|expir", "replica|replication")
  ),
  feed = list(
    title = "News feed (Facebook / Instagram home feed)", co = "Meta", minutes = 45,
    nodes = nd(N("cl", "Mobile / web", 0, 2, "client"), N("gw", "API gateway", 1.3, 2, "edge"), N("post", "Post service", 2.7, 3.2),
               N("feed", "Feed service", 2.7, 2), N("fan", "Fan-out workers", 4.1, 3.2, "worker"), N("q", "Post events<br>queue", 4.1, 4.2, "queue"),
               N("fc", "Feed cache<br>(user → post ids)", 4.1, 2, "cache"), N("pdb", "Posts DB", 5.5, 3.2, "store"),
               N("graph", "Social graph", 5.5, 1.2, "store"), N("rank", "Ranking service", 2.7, 0.8), N("media", "Media blob<br>store + CDN", 1.3, 3.4, "store")),
    edges = rbind(E("cl", "gw"), E("gw", "post", "create"), E("gw", "feed", "read"), E("post", "pdb"), E("post", "q"), E("q", "fan"),
                  E("fan", "graph", "followers"), E("fan", "fc", "push ids"), E("feed", "fc"), E("feed", "rank"), E("feed", "pdb", "hydrate"), E("cl", "media", "upload / view")),
    steps = list(
      list(phase = "req", show = "cl", new = "cl", title = "Clarify the scope",
           text = "<b>Functional:</b> publish a post (text, image), view a home feed of posts from people you follow, ranked, with pagination.<br><b>Non-functional:</b> feed loads in &lt; 500 ms, eventual consistency is fine (a few seconds), very high read volume, celebrities with millions of followers."),
      list(phase = "est", show = "cl", title = "Back-of-the-envelope",
           text = "500 M DAU × 10 feed loads = <b>5 B reads/day ≈ 60 k/s</b> (peak 150 k/s). 1 post / user / day ≈ <b>6 k writes/s</b>. Average 300 followers → 1.8 M feed inserts/s if we fan out on write. Store ~500 post ids per user feed: 500 M × 500 × 8 B = <b>2 TB</b> of cache."),
      list(phase = "api", show = c("cl", "gw"), new = "gw", title = "API",
           text = "<code>POST /v1/posts {text, media_ids}</code><br><code>GET /v1/feed?cursor=&limit=20 → {items, next_cursor}</code> — cursor-based pagination (by rank score or time), not offsets, because the feed changes while you scroll."),
      list(phase = "data", show = c("cl", "gw", "post", "pdb", "graph", "media"), new = c("post", "pdb", "graph", "media"), title = "Data model",
           text = "<code>posts(post_id, author_id, created_at, text, media)</code> sharded by post_id; <code>follows(follower, followee)</code> in a graph store (TAO at Meta); media in blob storage behind a CDN. IDs are time-sortable (Snowflake) so 'newer than' is cheap."),
      list(phase = "hld", show = c("cl", "gw", "post", "pdb", "graph", "media", "q", "fan", "fc", "feed"), new = c("q", "fan", "fc", "feed"), title = "Fan-out on write",
           text = "When a post is created, a queue triggers workers that look up the author's followers and <b>push the post id into each follower's cached feed</b>. Reading a feed is then a single cache read + hydration of post bodies. Fast reads, expensive writes."),
      list(phase = "deep", show = c("cl", "gw", "post", "pdb", "graph", "media", "q", "fan", "fc", "feed"), focus = c("fan", "graph"), title = "Deep dive: celebrities (hybrid fan-out)",
           text = "A user with 50 M followers would cause 50 M writes per post. <b>Hybrid:</b> fan out on write for normal users; for high-follower accounts, <b>pull on read</b> — at read time merge the cached feed with recent posts of the celebrities you follow. Skip fan-out to inactive users too."),
      list(phase = "deep", show = c("cl", "gw", "post", "pdb", "graph", "media", "q", "fan", "fc", "feed", "rank"), new = "rank", title = "Deep dive: ranking",
           text = "Candidate generation (a few hundred ids from the feed cache + pulled sources) → lightweight filtering → <b>ML ranking</b> on features (affinity, recency, engagement predictions) → diversity rules. Cache the ranked page briefly; re-rank on refresh."),
      list(phase = "wrap", show = c("cl", "gw", "post", "pdb", "graph", "media", "q", "fan", "fc", "feed", "rank"), focus = c("fc", "pdb"), title = "Bottlenecks & trade-offs",
           text = "• Feed cache misses (cold users) → rebuild by pulling.<br>• Hot posts → replicate post objects in cache.<br>• Deletes / privacy changes → filter at hydration time, not just at fan-out.<br>• Consistency: your own post should appear immediately (read-your-writes by merging locally).<br>• Monitoring: feed latency p99, fan-out lag.")),
    checklist = c("Read and write QPS estimated", "Feed API with cursor pagination", "Posts / follows data model", "Fan-out on write explained",
                  "Celebrity problem + hybrid approach", "Feed cache sizing", "Ranking pipeline outline", "Media via blob store + CDN",
                  "Read-your-own-writes", "Deletes / privacy at read time", "Metrics & monitoring"),
    keywords = c("fan.?out", "celebrit|hybrid|pull", "cursor", "cache", "rank", "cdn|blob", "snowflake|time.?sortable", "queue|kafka")
  ),
  ratelimiter = list(
    title = "Distributed rate limiter", co = "Google · Meta", minutes = 35,
    nodes = nd(N("cl", "Clients", 0, 2, "client"), N("gw", "API gateway<br>+ limiter middleware", 1.6, 2, "edge"), N("redis", "Redis cluster<br>counters / buckets", 3.3, 2.9, "cache"),
               N("rules", "Rules service<br>(config)", 3.3, 1.0, "store"), N("svc", "Backend services", 3.3, 2), N("lc", "Local<br>token cache", 1.6, 0.8, "cache")),
    edges = rbind(E("cl", "gw"), E("gw", "redis", "INCR / Lua"), E("gw", "svc", "allowed"), E("rules", "gw", "push rules"), E("gw", "lc")),
    steps = list(
      list(phase = "req", show = "cl", new = "cl", title = "Clarify the scope",
           text = "Limit requests per <b>key</b> (user id, API key, IP) per <b>rule</b> (e.g. 100 / minute per user per endpoint). Return 429 with <code>Retry-After</code>. Low added latency (&lt; 2 ms), works across many gateway instances, fails <b>open</b> if the limiter is down (usually)."),
      list(phase = "est", show = "cl", title = "Estimates",
           text = "1 M requests/s across 200 gateways; 50 M active keys × ~32 B of state ≈ <b>1.6 GB</b> — fits in a Redis cluster. Each request needs one round-trip to the counter store, so it must be in-region."),
      list(phase = "hld", show = c("cl", "gw", "svc"), new = c("gw", "svc"), title = "Where does it live?",
           text = "In the <b>API gateway / middleware</b>, before requests reach services — one place to enforce, easy to configure. Client-side limits are advisory only."),
      list(phase = "data", show = c("cl", "gw", "svc", "redis"), new = "redis", title = "Algorithm & state",
           text = "<b>Token bucket</b> (burst-friendly: capacity + refill rate; store tokens + last refill time) or <b>sliding-window counter</b> (two fixed windows weighted by overlap — accurate, O(1) memory). Fixed windows allow 2× bursts at the boundary; sliding <i>log</i> is exact but O(requests) memory. Do the read-modify-write <b>atomically</b> with a Lua script or INCR + EXPIRE."),
      list(phase = "deep", show = c("cl", "gw", "svc", "redis", "rules"), new = "rules", title = "Rules",
           text = "Rules live in a config service (YAML / DB), are pushed to gateways and cached in memory: <code>{domain: api, key: user_id, endpoint: /upload, limit: 10, per: 60s}</code>. Hot reload without restarts."),
      list(phase = "deep", show = c("cl", "gw", "svc", "redis", "rules", "lc"), new = "lc", title = "Deep dive: latency & scale",
           text = "To avoid a network hop on every request, gateways can <b>lease batches of tokens</b> locally (e.g. 10 at a time) and sync periodically — trading a little accuracy for speed. Shard counters by key; keep them in the same region as traffic."),
      list(phase = "wrap", show = c("cl", "gw", "svc", "redis", "rules", "lc"), focus = c("redis"), title = "Bottlenecks & trade-offs",
           text = "• Redis down → fail open (protect availability) or fail closed (protect backend) — a product decision.<br>• Race conditions → atomic scripts.<br>• Multi-region → per-region limits or async global sync (approximate).<br>• Return headers: <code>X-RateLimit-Remaining</code>, <code>Retry-After</code>.")),
    checklist = c("Keys and rules defined", "429 + Retry-After", "Where the limiter sits", "Algorithm compared (bucket / windows / log)",
                  "Atomic updates (Lua / INCR)", "State size estimated", "Fail open vs closed", "Rules config & hot reload",
                  "Local batching for latency", "Multi-region behaviour"),
    keywords = c("token bucket|leaky", "sliding", "fixed window", "lua|atomic|incr", "429", "fail.?open|fail.?closed", "redis", "header|retry-after")
  ),
  chat = list(
    title = "Chat / messenger (1:1 and small groups)", co = "Meta", minutes = 45,
    nodes = nd(N("a", "Sender app", 0, 3, "client"), N("b", "Recipient app", 0, 1, "client"), N("ws", "WebSocket<br>gateways", 1.5, 2, "edge"),
               N("chat", "Chat service", 3, 2), N("pres", "Presence<br>service", 3, 3.3, "cache"), N("sess", "Session map<br>user → gateway", 3, 0.7, "cache"),
               N("mq", "Per-user<br>inbox queue", 4.5, 2, "queue"), N("store", "Message store<br>(by conversation)", 6, 2, "store"), N("push", "Push<br>notifications", 4.5, 0.7, "worker")),
    edges = rbind(E("a", "ws", "send"), E("ws", "chat"), E("chat", "store", "append"), E("chat", "mq"), E("chat", "sess", "lookup"),
                  E("chat", "ws", "deliver"), E("ws", "b"), E("chat", "push", "offline"), E("ws", "pres", "heartbeat")),
    steps = list(
      list(phase = "req", show = c("a", "b"), new = c("a", "b"), title = "Clarify the scope",
           text = "1:1 and group chats (≤ 100 members), text first, delivery + read receipts, online presence, history on multiple devices, push when offline.<br><b>Non-functional:</b> low latency (&lt; 200 ms), <b>no message loss</b>, per-conversation ordering."),
      list(phase = "est", show = c("a", "b"), title = "Estimates",
           text = "500 M DAU × 40 messages = 20 B/day ≈ <b>230 k msg/s</b>, peak 1 M/s. 100 B per message → 2 TB/day of storage. ~100 M concurrent connections → at 100 k connections per gateway, <b>~1 000 gateways</b>."),
      list(phase = "api", show = c("a", "b", "ws"), new = "ws", title = "Connections & API",
           text = "Persistent <b>WebSocket</b> per device (long-polling fallback). Frames: <code>send{conv_id, client_msg_id, body}</code>, <code>ack{msg_id}</code>, <code>deliver{...}</code>, <code>read{conv_id, up_to}</code>. REST for history: <code>GET /conversations/{id}/messages?before=</code>."),
      list(phase = "data", show = c("a", "b", "ws", "chat", "store"), new = c("chat", "store"), title = "Data model & ordering",
           text = "<code>messages(conv_id, seq, sender, ts, body)</code> partitioned by <code>conv_id</code>, clustered by <code>seq</code> (Cassandra / HBase style). The chat service assigns a monotonically increasing <b>seq per conversation</b>; <code>client_msg_id</code> makes retries idempotent."),
      list(phase = "hld", show = c("a", "b", "ws", "chat", "store", "sess", "mq"), new = c("sess", "mq"), title = "Routing a message",
           text = "Sender's gateway → chat service: persist first (durability), then look up which gateway each recipient device is connected to (session map in Redis) and push. Per-user inbox queues hold undelivered messages until the device acks."),
      list(phase = "deep", show = c("a", "b", "ws", "chat", "store", "sess", "mq", "push", "pres"), new = c("push", "pres"), title = "Offline, presence, receipts",
           text = "Offline → push notification service (APNs / FCM) and the message waits in the inbox. Presence = heartbeats with TTL; fan presence out only to friends currently viewing, and debounce flapping. Delivery / read receipts are just small messages flowing back."),
      list(phase = "wrap", show = c("a", "b", "ws", "chat", "store", "sess", "mq", "push", "pres"), focus = c("ws", "store"), title = "Bottlenecks & trade-offs",
           text = "• Gateway failure → clients reconnect, resync from last acked seq.<br>• Large groups → fan out via queue, not inline.<br>• Multi-device → each device tracks its own cursor.<br>• End-to-end encryption changes what the server can store / index.<br>• Hot conversations → partition by conv_id spreads load.")),
    checklist = c("Message QPS and connections estimated", "WebSocket choice justified", "Idempotent send (client id)", "Per-conversation ordering (seq)",
                  "Persist before deliver", "Session map / routing", "Offline delivery + push", "Receipts", "Presence with TTL heartbeats",
                  "Multi-device sync", "Gateway failure handling"),
    keywords = c("websocket", "idempot|client_msg|dedup", "seq|order", "presence|heartbeat", "push|apns|fcm", "partition|shard", "ack|receipt", "cassandra|hbase|wide.?column")
  )
)
rm(nd, N, E)

DESIGN_PROMPTS <- c(
  setNames(names(DESIGN_CASES), vapply(DESIGN_CASES, function(d) paste0(d$title, " — with walkthrough"), "")),
  "Web crawler (Google)" = "crawler", "Top-K trending hashtags" = "topk", "Collaborative document editor (Google Docs)" = "docs",
  "Proximity / nearby places (Yelp, Meta Places)" = "nearby")
EXTRA_CHECKS <- list(
  crawler = list(minutes = 40, checklist = c("Scale: pages/day and bandwidth", "URL frontier with priorities", "Politeness per host (robots.txt, delays)", "De-duplication (URL + content hash)", "DNS caching", "Distributed workers by host hash", "Recrawl / freshness policy", "Traps and spam handling", "Storage of pages"),
                 keywords = c("frontier", "robots|polite", "dedup|hash|simhash", "dns", "bloom", "recrawl|fresh")),
  topk = list(minutes = 35, checklist = c("Window definition (last 5 min / 1 h)", "Event ingestion via queue", "Count-min sketch or exact counts trade-off", "Per-shard top-K then merge", "Heap of size K", "Sliding window by time buckets", "Latency vs accuracy", "Serving layer cache"),
              keywords = c("count.?min|sketch", "heap", "window|bucket", "kafka|stream|queue", "merge", "approximate")),
  docs = list(minutes = 45, checklist = c("Real-time collaboration requirement", "OT vs CRDT discussed", "Central server ordering of ops", "WebSocket sessions per doc", "Operation log + snapshots", "Cursor / presence", "Offline edits and merge", "Permissions", "Version history"),
              keywords = c("operational transform|\\bot\\b", "crdt", "snapshot", "websocket", "version", "conflict")),
  nearby = list(minutes = 40, checklist = c("Read-heavy, location queries", "Geohash / quadtree / S2 index", "Radius search over neighbouring cells", "Business data store separate from index", "Caching popular areas", "Index rebuild / updates", "Ranking by distance + rating", "Sharding by region"),
                keywords = c("geohash", "quadtree", "s2|h3", "radius|neighbo", "cache", "shard|region"))
)

designprac_ui <- function(id) {
  ns <- NS(id)
  tagList(
    topic_hero("🏗️", "Design Interview Practice",
      "System design (Google, Meta 'System Design') and product architecture (Meta 'Product Architecture') rounds reward a structured walk from requirements to trade-offs. Step through worked designs, then run a timed mock with a coverage checklist.",
      c("Requirements", "Estimates", "API", "Data model", "High-level design", "Deep dives", "Trade-offs")),
    tags$div(class = "topic-tabs",
      tabsetPanel(id = ns("tabs"), type = "pills",
        tabPanel("🎬 Walkthroughs",
          fluidRow(
            box(title = "Worked design — step by step", status = "primary", solidHeader = TRUE, width = 8,
              fluidRow(column(6, selectInput(ns("case"), NULL, setNames(names(DESIGN_CASES), vapply(DESIGN_CASES, function(d) d$title, "")))),
                       column(6, stepper_ui(ns, "dw"))),
              uiOutput(ns("dw_phase")),
              plotlyOutput(ns("dw_plot"), height = "400px"),
              legend_row(c("client" = "#0284c7", "edge / gateway" = "#7c3aed", "service" = COL$pri, "storage" = "#059669", "cache" = "#d97706", "queue" = "#db2777", "worker" = "#64748b"))),
            box(title = "What to say at this step", status = "info", solidHeader = TRUE, width = 4, uiOutput(ns("dw_text"))))
        ),
        tabPanel("⏱ Timed practice",
          fluidRow(
            box(title = "Mock design interview", status = "primary", solidHeader = TRUE, width = 8,
              fluidRow(column(6, selectInput(ns("tp_prompt"), "Prompt", DESIGN_PROMPTS, width = "100%")),
                       column(3, uiOutput(ns("tp_clock"))),
                       column(3, tags$div(style = "margin-top:25px; display:flex; gap:6px;", actionButton(ns("tp_start"), "Start", class = "btn btn-dsa btn-sm"),
                                          actionButton(ns("tp_save"), "Save", class = "btn btn-dsa-outline btn-sm")))),
              callout("Spend roughly: requirements 5 min · estimates 3 · API & data 7 · high-level design 10 · deep dives 15 · wrap-up 5. Type the notes you would say out loud.", "tip"),
              lapply(names(DESIGN_PHASES), function(k) textAreaInput(ns(paste0("tp_", k)), DESIGN_PHASES[[k]], "", rows = if (k %in% c("hld", "deep")) 5 else 3, width = "100%"))),
            box(title = "Coverage checklist", status = "warning", solidHeader = TRUE, width = 4,
              uiOutput(ns("tp_checks")), uiOutput(ns("tp_cov")),
              sliderInput(ns("tp_self"), "Overall self-score (1–4)", 1, 4, 2, step = 1, ticks = FALSE, width = "100%"),
              uiOutput(ns("tp_saved"))))
        ),
        tabPanel("📈 History",
          fluidRow(box(title = "Design practice attempts", status = "info", solidHeader = TRUE, width = 12, DT::DTOutput(ns("tp_hist")))))
      )
    )
  )
}

designprac_server <- function(id, progress = NULL, bus = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    st <- reactiveValues(end = NULL, started = NULL, saved = NULL, tick = 0)

    D <- reactive(DESIGN_CASES[[input$case %||% names(DESIGN_CASES)[1]]])
    dw_steps <- reactive(D()$steps)
    dw <- stepper_server(input, output, session, "dw", dw_steps, speed = 2500)
    output$dw_phase <- renderUI({
      s <- dw$cur()
      tags$div(style = "display:flex; gap:4px; flex-wrap:wrap; margin-bottom:6px;",
        lapply(names(DESIGN_PHASES), function(k) tags$span(class = "kind-pill",
          style = if (k == s$phase) "background:#4f46e5;color:#fff;" else "", DESIGN_PHASES[[k]])))
    })
    output$dw_plot <- renderPlotly({
      d <- D(); s <- dw$cur()
      arch_plot(d$nodes, d$edges, show = s$show, new = s$new %||% character(0), focus = s$focus %||% character(0))
    })
    output$dw_text <- renderUI({
      s <- dw$cur(); d <- D()
      tagList(tags$h4(style = "margin-top:0;", s$title), tags$div(style = "font-size:13.5px; line-height:1.55;", HTML(s$text)),
              tags$hr(), hint(sprintf("Asked at: %s · suggested %d minutes. ★ marks components introduced at this step.", d$co, d$minutes)))
    })

    # ── Timed practice ───────────────────────────────────────────────────────
    spec <- reactive({
      p <- input$tp_prompt
      if (p %in% names(DESIGN_CASES)) { d <- DESIGN_CASES[[p]]; list(minutes = d$minutes, checklist = d$checklist, keywords = d$keywords) }
      else EXTRA_CHECKS[[p]]
    })
    observeEvent(input$tp_prompt, { st$end <- NULL; st$saved <- NULL; for (k in names(DESIGN_PHASES)) updateTextAreaInput(session, paste0("tp_", k), value = "") })
    observeEvent(input$tp_start, { st$started <- Sys.time(); st$end <- as.numeric(Sys.time()) * 1000 + spec()$minutes * 60000 })
    output$tp_clock <- renderUI({
      if (is.null(st$end)) return(tags$div(class = "hint", style = "margin-top:28px;", sprintf("%d minutes", spec()$minutes)))
      tags$div(class = "dsa-countdown", style = "font-size:22px; margin-top:20px;", `data-end` = sprintf("%.0f", st$end), `data-total` = spec()$minutes * 60, "--:--")
    })
    notes <- reactive(paste(vapply(names(DESIGN_PHASES), function(k) input[[paste0("tp_", k)]] %||% "", ""), collapse = "\n"))
    output$tp_checks <- renderUI(checkboxGroupInput(ns("tp_check"), "Tick what you covered:", spec()$checklist, width = "100%"))
    output$tp_cov <- renderUI({
      sp <- spec(); txt <- tolower(notes())
      hit <- vapply(sp$keywords, function(k) grepl(k, txt, perl = TRUE), TRUE)
      filled <- vapply(names(DESIGN_PHASES), function(k) nchar(trimws(input[[paste0("tp_", k)]] %||% "")) > 15, TRUE)
      tagList(
        kpi_row(kpi(sprintf("%d / %d", length(input$tp_check), length(sp$checklist)), "checklist", COL$pri),
                kpi(sprintf("%d / %d", sum(filled), length(filled)), "phases with notes", COL$sec)),
        tags$div(class = "code-title", "Key terms detected in your notes"),
        tags$div(lapply(seq_along(hit), function(i) tags$span(class = "kind-pill", style = paste0("margin:2px;", if (hit[i]) "background:#dcfce7;color:#065f46;" else "background:#f1f5f9;color:#94a3b8;"),
                                                            gsub("\\\\b|\\?|\\.", "", strsplit(sp$keywords[i], "|", fixed = TRUE)[[1]][1])))))
    })
    observeEvent(input$tp_save, {
      sp <- spec(); cov <- length(input$tp_check) / length(sp$checklist)
      db_insert("design_attempts", list(ts = now_ts(), day = today(), prompt_id = input$tp_prompt,
        seconds = if (is.null(st$started)) NA else as.numeric(difftime(Sys.time(), st$started, units = "secs")),
        notes = as.character(jsonlite::toJSON(setNames(lapply(names(DESIGN_PHASES), function(k) input[[paste0("tp_", k)]] %||% ""), names(DESIGN_PHASES)), auto_unbox = TRUE)),
        checklist = paste(input$tp_check, collapse = " | "), coverage = round(100 * cov), self_score = as.numeric(input$tp_self)))
      st$saved <- round(100 * cov); st$tick <- st$tick + 1; if (!is.null(bus)) bus$db_tick <- (isolate(bus$db_tick) %||% 0) + 1
    })
    output$tp_saved <- renderUI(if (!is.null(st$saved)) callout(sprintf("Saved — %d%% of the checklist covered.", st$saved), "success"))
    output$tp_hist <- DT::renderDT({
      st$tick
      h <- db_table("design_attempts")
      if (!nrow(h)) return(DT::datatable(data.frame(Message = "No attempts yet."), rownames = FALSE, options = list(dom = "t")))
      lab <- setNames(names(DESIGN_PROMPTS), DESIGN_PROMPTS)
      DT::datatable(data.frame(When = h$ts, Prompt = lab[h$prompt_id], Coverage = paste0(h$coverage, "%"), Self = h$self_score,
                               Minutes = round(h$seconds / 60, 1), stringsAsFactors = FALSE), rownames = FALSE, options = list(pageLength = 10, dom = "tp"))
    })
  })
}
