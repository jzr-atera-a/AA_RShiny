# modules/chapter09.R
# Chapter 9: Building More Features -- Caching and Rate Limiting

CH09_FILES <- list(

  list(
    name = "flask_caching_setup.py",
    description = "<strong>flask_caching_setup.py</strong> — Exercise 56: Flask-Caching setup with SimpleCache, the <code>@cache.cached()</code> decorator, and why <code>query_string=True</code> is essential for endpoints with query parameters.",
    code = 'print("=== Flask-Caching: Setup and Configuration ===\n")

setup_code = """
# extensions.py
from flask_caching import Cache
cache = Cache()

# config.py
class Config:
    CACHE_TYPE            = "SimpleCache"  # in-memory; use Redis in production
    CACHE_DEFAULT_TIMEOUT = 60             # seconds

# app.py  register_extensions()
cache.init_app(app)
"""
print(setup_code)

print("=== @cache.cached() Decorator ===\n")
decorator_code = """
class RecipeListResource(Resource):

    @use_kwargs({...})
    @cache.cached(timeout=60, query_string=True)
    def get(self, q, page, per_page, sort, order):
        print("Querying database...")   # printed only on cache MISS

        paginated = Recipe.get_all_published(q, page, per_page, sort, order)
        return recipe_pagination_schema.dump(paginated).data, 200
"""
print(decorator_code)

print("=== Cache key behaviour ===\n")
print("  query_string=False (bad):")
print("    /recipes                    -> key: /recipes")
print("    /recipes?page=2&sort=name   -> key: /recipes  (SAME! stale data!)")
print()
print("  query_string=True (correct):")
print("    /recipes?page=1&sort=created_at&order=desc  -> unique key")
print("    /recipes?page=2&sort=created_at&order=desc  -> different key")
print()

# Simulate cache hits and misses
cache_store = {}

def get_with_cache(cache_key, db_query_fn):
    if cache_key in cache_store:
        print(f"  CACHE HIT  [{cache_key[:55]}]")
        return cache_store[cache_key]
    print(f"  CACHE MISS [{cache_key[:55]}] -> querying DB...")
    result = db_query_fn()
    cache_store[cache_key] = result
    return result

def fake_db():
    return {"data": ["recipe_1", "recipe_2"]}

print("=== Cache simulation ===\n")
k1 = "/recipes?page=1&per_page=20&sort=created_at&order=desc"
k2 = "/recipes?page=2&per_page=20&sort=created_at&order=desc"

get_with_cache(k1, fake_db)
get_with_cache(k1, fake_db)
get_with_cache(k1, fake_db)
get_with_cache(k2, fake_db)
get_with_cache(k2, fake_db)

print(f"\n  Cache holds {len(cache_store)} unique entries")',
    demo = NULL
  ),

  list(
    name = "cache_invalidation.py",
    description = "<strong>cache_invalidation.py</strong> — Exercises 58-59: clearing stale cache on write operations. <code>cache.clear()</code> is called inside <code>post()</code> and <code>publish()</code> so the listing endpoint always reflects current data.",
    code = 'from http import HTTPStatus

print("=== Cache Invalidation: Clear on Write ===\n")

print("  The Problem:")
print("    User POSTs a new recipe  -> DB updated")
print("    User GETs /recipes       -> cache returns OLD data!")
print("    Cache TTL expires (60s)  -> only NOW the new recipe appears")
print()
print("  The Solution: cache.clear() on every write\n")

cache_store = {}
recipes_db  = [
    {"id": 1, "name": "Egg Salad",    "is_publish": True},
    {"id": 2, "name": "Tomato Pasta", "is_publish": True},
]
next_id = [3]

def cache_clear():
    count = len(cache_store)
    cache_store.clear()
    print(f"    cache.clear() -> removed {count} cached entries")

def get_recipes_cached():
    key = "/recipes"
    if key in cache_store:
        print("  CACHE HIT  -> returning cached list")
        return cache_store[key]
    print("  CACHE MISS -> querying DB")
    result = [r for r in recipes_db if r["is_publish"]]
    cache_store[key] = result
    return result

def post_recipe(name):
    """RecipeListResource.post() -- mirrors Exercise 58"""
    recipe = {"id": next_id[0], "name": name, "is_publish": False}
    next_id[0] += 1
    recipes_db.append(recipe)
    cache_clear()
    return recipe, HTTPStatus.CREATED

def publish_recipe(recipe_id):
    """RecipePublishResource.put() -- mirrors Exercise 58"""
    recipe = next((r for r in recipes_db if r["id"] == recipe_id), None)
    if not recipe:
        return {"message": "not found"}, HTTPStatus.NOT_FOUND
    recipe["is_publish"] = True
    cache_clear()
    return {}, HTTPStatus.NO_CONTENT

print("Step 1: First GET (cache MISS, populates cache)")
get_recipes_cached()
print(f"  Cache size: {len(cache_store)}\n")

print("Step 2: Second GET (cache HIT)")
get_recipes_cached()
print()

print("Step 3: POST new recipe (clears cache)")
post_recipe("Caesar Salad")
print()

print("Step 4: GET after POST (fresh from DB)")
result = get_recipes_cached()
print(f"  {len(result)} published recipes\n")

print("Step 5: Publish Caesar Salad (clears cache)")
publish_recipe(3)
print()

print("Step 6: GET after publish (Caesar now visible)")
result2 = get_recipes_cached()
names = [r["name"] for r in result2]
print(f"  {len(result2)} published: {names}")',
    demo = NULL
  ),

  list(
    name = "rate_limiting.py",
    description = "<strong>rate_limiting.py</strong> — Exercise 60: Flask-Limiter setup, applying <code>@limiter.limit()</code> to endpoints, and HTTP 429 responses. Shows a full simulation of rate limiting the login endpoint to 3 attempts per minute.",
    code = 'import time
from http import HTTPStatus

print("=== Flask-Limiter: Rate Limiting ===\n")

setup_code = """
# extensions.py
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

# app.py
limiter.init_app(app)

# Apply to login (Exercise 60):
class TokenResource(Resource):
    decorators = [limiter.limit("3/minute")]

    def post(self):   # max 3 login attempts per minute per IP
        ...
"""
print(setup_code)

print("=== Rate limit string syntax ===\n")
limits = [
    ("\"200 per day\"",        "200 requests per day per IP"),
    ("\"50 per hour\"",        "50 per hour per IP"),
    ("\"3/minute\"",           "3 per minute per IP"),
    ("\"1/second\"",           "1 per second (strict burst)"),
    ("\"10/min;200/day\"",     "Multiple limits simultaneously"),
]
for expr, desc in limits:
    print(f"  {expr:<28} -> {desc}")

print()
print("=== HTTP 429 Too Many Requests ===\n")
print("  Status : 429 Too Many Requests")
print("  Headers: Retry-After: 57   (seconds until window resets)")
print("  Body   : {\"message\": \"3 per 1 minute\"}\n")

class RateLimiter:
    def __init__(self, max_calls, window_seconds):
        self.max_calls = max_calls
        self.window    = window_seconds
        self.calls     = {}

    def check(self, ip):
        now     = time.time()
        history = [t for t in self.calls.get(ip, []) if now - t < self.window]
        if len(history) >= self.max_calls:
            return False, HTTPStatus.TOO_MANY_REQUESTS
        history.append(now)
        self.calls[ip] = history
        return True, HTTPStatus.OK

limiter = RateLimiter(max_calls=3, window_seconds=60)

print("=== Simulation: 3/minute on POST /token ===\n")
for i in range(5):
    ok, status = limiter.check("192.168.1.1")
    icon = "\u2705" if ok else "\u274c"
    print(f"  Request {i+1}: {icon}  {status.value} {status.phrase}")',
    demo = NULL
  ),

  list(
    name = "whitelist.py",
    description = "<strong>whitelist.py</strong> — Exercise 62: the <code>@limiter.request_filter</code> decorator exempting localhost from all rate limits. Useful for development, CI, and trusted internal services.",
    code = 'from http import HTTPStatus

print("=== IP Whitelist with @limiter.request_filter ===\n")

whitelist_code = """
# app.py  register_extensions()  (Exercise 62)

@limiter.request_filter
def ip_whitelist():
    return request.remote_addr == "127.0.0.1"
    # True  -> request is EXEMPT from all rate limits
    # False -> normal limits apply
"""
print(whitelist_code)

print("=== When to whitelist ===\n")
use_cases = [
    ("127.0.0.1",           "Local development machine"),
    ("10.0.0.0/8",          "Internal microservices"),
    ("CI/CD runner IP",     "Automated test pipelines"),
    ("Admin dashboard",     "Internal monitoring tools"),
]
for ip, desc in use_cases:
    print(f"  {ip:<28} -> {desc}")

print()
print("=== Activity 17: Multiple limits on one endpoint ===\n")

multi_code = """
class TokenResource(Resource):
    decorators = [
        limiter.limit("1/second"),    # burst protection
        limiter.limit("30/minute"),   # sustained limit
        limiter.limit("200/day"),     # daily quota
    ]
# ALL three must pass -- the most restrictive one governs
"""
print(multi_code)

WHITELIST = {"127.0.0.1"}

class SmartLimiter:
    def __init__(self, max_calls):
        self.max_calls = max_calls
        self.counts    = {}

    def check(self, ip):
        if ip in WHITELIST:
            return True, "EXEMPT (whitelisted)"
        count = self.counts.get(ip, 0) + 1
        self.counts[ip] = count
        if count > self.max_calls:
            return False, "429 Too Many Requests"
        return True, f"OK ({count}/{self.max_calls} used)"

lim = SmartLimiter(max_calls=3)

print("=== Whitelist simulation (3 req limit) ===\n")
for ip, attempts in [("127.0.0.1", 5), ("10.0.0.5", 5)]:
    print(f"  IP: {ip}")
    for i in range(attempts):
        ok, msg = lim.check(ip)
        icon = "\u2705" if ok else "\u274c"
        print(f"    Request {i+1}: {icon}  {msg}")
    print()',
    demo = NULL
  )
)

# ── Chapter 9 UI ──────────────────────────────────────────────
chapter9_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(9, "\u26a1", "Building More Features",
      "Add production-grade performance and security: in-memory response caching with Flask-Caching, automatic cache invalidation on writes, request rate limiting with Flask-Limiter, and IP whitelisting for trusted clients.",
      c("Flask-Caching", "cache.cached()", "cache.clear()", "Flask-Limiter", "429", "Whitelist", "SimpleCache", "Redis")),

    stats_row(
      list("60s",   "Cache TTL"),
      list("3/min", "Login rate limit"),
      list("429",   "Rate limit code"),
      list("Redis", "Prod cache backend")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),

        tabPanel(title = tagList(icon("book"), " Theory"),

          fluidRow(
            box(title = "\u26a1 Flask-Caching", status = "info", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                tags$h5("Why caching?"),
                tags$p("The recipe listing endpoint hits the DB, runs SQLAlchemy deserialisation, and marshmallow serialisation on every request. Caching stores the finished JSON in memory and returns it instantly without touching the DB."),
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(tags$th("Backend"), tags$th("Use case"))),
                  tags$tbody(
                    tags$tr(tags$td(tags$code("SimpleCache")), tags$td("Single-process dev/testing")),
                    tags$tr(tags$td(tags$code("Redis")),       tags$td("Production -- shared across workers")),
                    tags$tr(tags$td(tags$code("Memcached")),   tags$td("High-throughput alternative"))
                  )
                )
              ),
              div(class = "framework-card",
                tags$h5("@cache.cached() decorator"),
                tags$pre(class = "code-inline",
"@cache.cached(timeout=60, query_string=True)
def get(self, q, page, per_page, sort, order):
    # timeout=60        -> expire after 60 seconds
    # query_string=True -> include ?page=...&sort=... in key
    print(\"Querying database...\")  # only on cache MISS")
              )
            ),

            box(title = "\U0001f504 Cache Invalidation", status = "warning", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                tags$h5("Stale data problem + solution"),
                tags$pre(class = "code-inline",
"class RecipeListResource(Resource):
    @jwt_required
    def post(self):
        recipe.save()
        cache.clear()        # invalidate on CREATE
        return ..., 201

class RecipePublishResource(Resource):
    @jwt_required
    def put(self, recipe_id):
        recipe.is_publish = True
        recipe.save()
        cache.clear()        # invalidate on PUBLISH
        return {}, 204")
              ),
              div(class = "tip-box",
                HTML("<strong>\U0001f4a1 cache.clear() vs cache.delete():</strong> <code>clear()</code> wipes all entries; <code>delete(key)</code> removes one. For Smilecook, <code>clear()</code> is safe -- a short cache miss after a write is acceptable."))
            )
          ),

          fluidRow(
            box(title = "\U0001f6a7 Flask-Limiter", status = "danger", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                tags$h5("Rate limiting login"),
                tags$pre(class = "code-inline",
"from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

class TokenResource(Resource):
    decorators = [limiter.limit(\"3/minute\")]

    def post(self):   # max 3 attempts/minute/IP")
              ),
              div(class = "framework-card",
                tags$h5("HTTP 429 response"),
                tags$pre(class = "code-inline",
"HTTP/1.1 429 Too Many Requests
Retry-After: 57

{\"message\": \"3 per 1 minute\"}")
              )
            ),

            box(title = "\u2705 IP Whitelist + Multiple Limits", status = "success", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                tags$h5("Exempt trusted IPs"),
                tags$pre(class = "code-inline",
"@limiter.request_filter
def ip_whitelist():
    return request.remote_addr == \"127.0.0.1\"")
              ),
              div(class = "framework-card",
                tags$h5("Multiple rate limits (Activity 17)"),
                tags$pre(class = "code-inline",
"decorators = [
    limiter.limit(\"1/second\"),   # burst
    limiter.limit(\"30/minute\"),  # sustained
    limiter.limit(\"200/day\"),    # daily quota
]
# All three must pass")
              ),
              div(class = "success-box",
                HTML("<strong>\u2705 Chapter 9 outcome:</strong> Smilecook caches list queries, invalidates on writes, limits login to 3/minute, and exempts localhost for development."))
            )
          )
        ),


          # ── VOLVO API CONTEXT ──────────────────────────────────────

          # -- VOLVO API CONTEXT -----------------------------------------------------
          fluidRow(
            box(title = "\U0001f69a Volvo API Connection: Caching Telemetry + Respecting Rate Limits",
                status = "primary", solidHeader = TRUE, width = 12,
              div(class = "volvo-context-banner",
                span(class = "volvo-badge", "\U0001f69a Volvo Group Vehicle API v1.0.6"),
                span(class = "volvo-relevance", "Direct relevance: call frequency limits + 429 responses")
              ),
              div(class = "volvo-card",
                tags$h5("The Volvo API enforces strict call frequency limits"),
                tags$p("The Volvo API documentation specifies exact recommended polling intervals per endpoint. Exceeding them results in HTTP 429. Flask-Caching and Flask-Limiter form the correct response:"),
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(tags$th("Endpoint"), tags$th("Service"), tags$th("Recommended frequency"), tags$th("What to cache"))),
                  tags$tbody(
                    tags$tr(tags$td(tags$code("/vehicles")),         tags$td("Any"),   tags$td("Once per day"),     tags$td("Fleet list")),
                    tags$tr(tags$td(tags$code("/vehiclepositions")), tags$td("MAP"),   tags$td("Once per minute"),  tags$td("Latest position per VIN")),
                    tags$tr(tags$td(tags$code("/vehiclestatuses")),  tags$td("MAP"),   tags$td("Once per minute"),  tags$td("Latest snapshot")),
                    tags$tr(tags$td(tags$code("/vehiclestatuses")),  tags$td("CHECK"), tags$td("Every 15 minutes"), tags$td("Accumulated totals"))
                  )
                )
              ),
              fluidRow(
                column(6,
                  div(class = "volvo-card",
                    tags$h5("Flask-Caching strategy for Volvo data"),
                    tags$pre(class = "code-inline",
'# Cache fleet list for 24 hours (rarely changes)
@cache.cached(timeout=86400, key_prefix="vehicles")
def get_fleet():
    return volvo_api.get_vehicles()

# Cache positions for 60 seconds (MAP updates per minute)
@cache.cached(
    timeout=60,
    key_prefix=lambda: "pos_" + request.args.get("vin","all")
)
def get_positions():
    return volvo_api.get_vehiclepositions(latestOnly=True)

# Cache accumulated status for 15 minutes
@cache.cached(timeout=900, key_prefix="accumulated")
def get_accumulated():
    return volvo_api.get_vehiclestatuses(
        contentFilter="ACCUMULATED",
        latestOnly=True
    )'),
                    div(class = "success-box",
                      HTML("<strong>\u2705 Caching benefit:</strong> Multiple dashboards querying your fleet layer all get served from cache -- you only hit the Volvo API at the documented frequency."))
                  )
                ),
                column(6,
                  div(class = "volvo-card",
                    tags$h5("Handling HTTP 429 from the Volvo API"),
                    tags$p("Reason from docs:", tags$em("Request sent too often / Max concurrent calls"), ". Handle it with exponential back-off:"),
                    tags$pre(class = "code-inline",
'import http.client, time

def volvo_request(url, headers, max_retries=3):
    conn = http.client.HTTPSConnection(
        "api.renault-trucks.com"
    )
    for attempt in range(max_retries):
        conn.request("GET", url, headers=headers)
        res = conn.getresponse()

        if res.status == 429:
            wait = int(res.getheader("Retry-After", 60))
            print(f"Rate limited. Waiting {wait}s...")
            time.sleep(wait)
            continue

        if res.status == 200:
            return res.read()

        raise Exception(f"API error {res.status}")

    raise Exception("Max retries exceeded")'),
                    div(class = "tip-box",
                      HTML("<strong>\U0001f4a1 Flask-Limiter in YOUR app:</strong> If you expose a Flask endpoint that proxies Volvo data, rate-limit it too -- use <code>limiter.limit(\"1/minute\")</code> to match the Volvo API frequency and prevent clients burning through your quota."))
                  )
                )
              )
            )
          ),

        tabPanel(title = tagList(icon("code"), " Code Lab"),

          code_lab_header(
            "Chapter 9 \u2014 Building More Features",
            "Flask-Caching setup, cache keys, cache invalidation on writes, Flask-Limiter rate limiting, and IP whitelist."
          ),
          file_pills_ui(ns, CH09_FILES),
          py_code_display(ns),
          terminal_ui(ns)
        ),

        tabPanel(title = tagList(icon("truck"), " Volvo: Status + Caching"),
          fluidRow(
            box(title = "\U0001f4da How to Use This Tab", status = "primary",
                solidHeader = TRUE, width = 12, collapsible = TRUE,
              div(class = "volvo-card",
                tags$p(tags$strong("Purpose:"), " Query", tags$code("GET /vehicle/vehiclestatuses"), "with a focus on choosing the right", tags$strong("contentFilter and cache TTL"), "pair, as discussed in the Theory tab."),
                tags$p(tags$strong("Cache TTL guidance:"), " The recommended call frequency in the Volvo docs should be your cache TTL:"),
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(tags$th("contentFilter"), tags$th("Volvo frequency"), tags$th("Recommended cache TTL"))),
                  tags$tbody(
                    tags$tr(tags$td(tags$code("SNAPSHOT")),    tags$td("1 min (MAP)"),     tags$td(tags$strong("60 seconds"))),
                    tags$tr(tags$td(tags$code("ACCUMULATED")), tags$td("15 min (CHECK)"),  tags$td(tags$strong("900 seconds"))),
                    tags$tr(tags$td(tags$code("UPTIME")),      tags$td("On telltale only"),tags$td(tags$strong("300 seconds"))),
                    tags$tr(tags$td("(all sections)"),         tags$td("15 min"),          tags$td(tags$strong("900 seconds")))
                  )
                ),
                tags$p(tags$strong("latestOnly = true"), " is the recommended mode for caching -- you cache one response per vehicle, not a time-series."),
                tags$p(tags$strong("EV-specific triggers"), ": Use", tags$code("triggerFilter=BATTERY_PACK_CHARGING_STATUS_CHANGE"), "to retrieve only EV charging events -- highly efficient if you only need battery/charging data for your autonomous vehicle feasibility model."),
                tags$p(tags$strong("additionalContent"), ": Add", tags$code("VOLVOGROUPSNAPSHOT"), "to get charging power (kW), trailer weights, battery preconditioning status, and parking climate -- all critical for EV route planning.")
              )
            )
          ),
          fluidRow(
            box(title = "\U0001f6f9 /vehiclestatuses Parameters", status = "warning",
                solidHeader = TRUE, width = 5,
              textInput(ns("v9_vin"), "VIN (blank = all vehicles):",
                        placeholder = "ABC12345678901234"),
              checkboxInput(ns("v9_latest"),
                "latestOnly = true (recommended for caching)", TRUE),
              hr(),
              tags$strong("contentFilter:"),
              radioButtons(ns("v9_content"), NULL,
                choices = c(
                  "SNAPSHOT (60s cache, MAP service)"        = "SNAPSHOT",
                  "ACCUMULATED (900s cache, CHECK service)"  = "ACCUMULATED",
                  "UPTIME (telltales, HEALTH service)"       = "UPTIME",
                  "All sections (no filter)"                 = ""),
                selected = "SNAPSHOT"),
              hr(),
              tags$strong("additionalContent:"),
              checkboxGroupInput(ns("v9_addcontent"), NULL,
                choices = c("VOLVOGROUPSNAPSHOT (EV + trailer fields)" = "VOLVOGROUPSNAPSHOT",
                            "VOLVOGROUPACCUMULATED (energy breakdowns)"= "VOLVOGROUPACCUMULATED"),
                inline = FALSE),
              hr(),
              selectInput(ns("v9_trigger"), "triggerFilter (optional):",
                choices = c("(All triggers)", "TIMER",
                  "BATTERY_PACK_CHARGING_STATUS_CHANGE",
                  "BATTERY_PACK_CHARGING_CONNECTION_STATUS_CHANGE",
                  "BATTERY_PACK_HIGH_DISCHARGE","BATTERY_PACK_ENERGY_USAGE",
                  "VEHICLE_COUPLER_UNLOCK_ALLOWED","CLIMATE_STATUS",
                  "BATTERY_PRECONDITIONING","VEHICLE_MODE",
                  "IGNITION_ON","IGNITION_OFF","ENGINE_ON","ENGINE_OFF",
                  "FUELLEVEL_CHANGED_WHILE_OFF","TIRE_WARNING","TELL_TALE"),
                selected = "(All triggers)"),
              textInput(ns("v9_start"), "starttime (ISO 8601):",
                        placeholder = "2024-01-15T08:00:00Z"),
              textInput(ns("v9_stop"),  "stoptime (ISO 8601):",
                        placeholder = "2024-01-15T09:00:00Z"),
              br(),
              div(class = "info-box-plain",
                uiOutput(ns("v9_cache_hint"))),
              br(),
              actionButton(ns("v9_run"), "\u25b6  Call API  --  GET /vehiclestatuses",
                           class = "btn-run")
            ),
            box(title = "\U0001f4cb EV & Charging Fields (VOLVOGROUPSNAPSHOT)", status = "info",
                solidHeader = TRUE, width = 7,
              div(class = "volvo-card",
                tags$h5("Key EV snapshot fields for route planning"),
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(tags$th("Field"), tags$th("Unit"), tags$th("Relevance"))),
                  tags$tbody(
                    tags$tr(tags$td(tags$code("hybridBatteryPackRemainingCharge")), tags$td("% (0-100)"), tags$td("Current battery state of charge")),
                    tags$tr(tags$td(tags$code("batteryPackChargingStatus")),         tags$td("Enum"),     tags$td("NOT_CHARGING / CHARGING / CHARGING_AC / CHARGING_DC / ERROR")),
                    tags$tr(tags$td(tags$code("batteryPackChargingConnectionStatus")),tags$td("Enum"),    tags$td("CONNECTED / DISCONNECTED / CONNECTING / ERROR")),
                    tags$tr(tags$td(tags$code("batteryPackChargingPower")),           tags$td("kW"),      tags$td("Current charging power draw")),
                    tags$tr(tags$td(tags$code("batteryPackChargeTarget")),            tags$td("% (0-100)"),tags$td("Target charge level set by driver")),
                    tags$tr(tags$td(tags$code("estimatedTimeBatteryPackChargingCompleted")), tags$td("DateTime"), tags$td("ETA to reach charge target")),
                    tags$tr(tags$td(tags$code("batteryPackChargingPowerLimit")),      tags$td("kW"),      tags$td("Maximum power draw limit active")),
                    tags$tr(tags$td(tags$code("estimatedDistanceToEmpty")),           tags$td("m"),       tags$td("Predicted range remaining")),
                    tags$tr(tags$td(tags$code("parkingClimateStatus")),               tags$td("Enum"),    tags$td("ACTIVE / NOT_ACTIVE / ERROR")),
                    tags$tr(tags$td(tags$code("batteryVoltage")),                     tags$td("V"),       tags$td("Low-voltage battery level"))
                  )
                )
              ),
              div(class = "volvo-card",
                tags$h5("Accumulated EV energy (VOLVOGROUPACCUMULATED)"),
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(tags$th("Field"), tags$th("Unit"), tags$th("Description"))),
                  tags$tbody(
                    tags$tr(tags$td(tags$code("electricEnergyPropulsion")),    tags$td("Wh"), tags$td("Total energy used for driving")),
                    tags$tr(tags$td(tags$code("totalElectricEnergyUsed")),     tags$td("Wh"), tags$td("Total consumed (excl. plug-in)")),
                    tags$tr(tags$td(tags$code("electricEnergyRecuperation")),  tags$td("Wh"), tags$td("Energy recovered via regenerative braking")),
                    tags$tr(tags$td(tags$code("electricEnergyBatterypackHeating")),tags$td("Wh"),tags$td("Energy used for battery thermal management")),
                    tags$tr(tags$td(tags$code("totalElectricMotorHours")),     tags$td("h"),  tags$td("Hours motor was ready for propulsion"))
                  )
                )
              )
            )
          ),
          fluidRow(
            box(title = "\U0001f5a5\ufe0f Response", status = "primary",
                solidHeader = TRUE, width = 12,
              div(class = "terminal-wrap",
                div(class = "terminal-header",
                  div(class = "term-dots",
                    span(class = "td-red"), span(class = "td-yellow"), span(class = "td-green")),
                  span(class = "term-label", "GET /vehicle/vehiclestatuses")),
                div(class = "terminal-body", verbatimTextOutput(ns("v9_out"))))
            )
          )
        )

      )
    )
  )
}

chapter9_server <- function(id, creds = NULL) {
  moduleServer(id, function(input, output, session) {
    code_lab_server(input, output, session, CH09_FILES)

    output$v9_cache_hint <- renderUI({
      cf <- input$v9_content
      ttl <- switch(cf,
        "SNAPSHOT"    = "Recommended cache TTL: 60 seconds",
        "ACCUMULATED" = "Recommended cache TTL: 900 seconds (15 min)",
        "UPTIME"      = "Recommended cache TTL: 300 seconds",
        "All sections -- cache TTL: 900 seconds"
      )
      HTML(paste0("<strong>⏱ ", ttl, "</strong>"))
    })
    v9_result <- eventReactive(input$v9_run, {
      un      <- creds$username; pw <- creds$password
      vin     <- trimws(input$v9_vin)
      latest  <- isTRUE(input$v9_latest)
      content <- input$v9_content
      addcont <- paste(input$v9_addcontent, collapse = ",")
      trigger <- input$v9_trigger
      start   <- trimws(input$v9_start)
      stop    <- trimws(input$v9_stop)
      code <- paste0('import http.client, json, base64
from urllib.parse import urlencode

def _call(endpoint, params, un, pw):
    if not un or not pw:
        print("No credentials set. Go to Chapter 1 > Volvo API tab to enter credentials.")
        return
    b64 = base64.b64encode((un + ":" + pw).encode()).decode()
    ctype_map = {
        "vehicles":         "application/x.volvogroup.com.vehicles.v1.0+json; UTF-8",
        "vehiclepositions": "application/x.volvogroup.com.vehiclepositions.v1.0+json; UTF-8",
        "vehiclestatuses":  "application/x.volvogroup.com.vehiclestatuses.v1.0+json; UTF-8",
    }
    hdrs = {
        "authorization": "Basic " + b64,
        "content-type":  ctype_map.get(endpoint, "application/json")
    }
    clean = {k: v for k, v in params.items() if v and v != "(All triggers)"}
    url = "/vehicle/" + endpoint
    if clean:
        url += "?" + urlencode(clean, doseq=True)
    print("Request : GET https://api.renault-trucks.com" + url)
    print("Auth    : Basic ****  (credentials masked)")
    print()
    try:
        conn = http.client.HTTPSConnection("api.renault-trucks.com", timeout=15)
        conn.request("GET", url, headers=hdrs)
        res  = conn.getresponse()
        body = res.read().decode("utf-8")
        print("Status  : " + str(res.status) + " " + res.reason)
        if res.status == 200:
            data = json.loads(body)
            txt  = json.dumps(data, indent=2)
            print(txt[:5000])
            if len(txt) > 5000:
                print("\n... (truncated - full response is " + str(len(txt)) + " chars)")
            more = data.get("moreDataAvailable", False)
            if more:
                print("\nmoreDataAvailable = True  ->  use lastVin / advance starttime to get next page")
        else:
            print("Error body: " + body[:800])
        conn.close()
    except Exception as e:
        print("Connection error: " + str(type(e).__name__) + ": " + str(e))
', '
un = "', un, '"
pw = "', pw, '"
params = {}
if "', vin, '":       params["vin"]              = "', vin, '"
if "', content, '":   params["contentFilter"]    = "', content, '"
if "', addcont, '":   params["additionalContent"]= "', addcont, '"
if "', trigger, '" != "(All triggers)":
    params["triggerFilter"] = "', trigger, '"
if "', start, '":     params["starttime"]        = "', start, '"
if "', stop, '":      params["stoptime"]         = "', stop, '"
if ', if(isTRUE(latest)) 'True' else 'False', ':
    params["latestOnly"] = "true"
_call("vehiclestatuses", params, un, pw)
')
      run_python_safe(code)
    })
    output$v9_out <- renderText({
      if (input$v9_run == 0)
        return("$ Ready -- configure filters and click Call API")
      v9_result()
    })

  })
}
