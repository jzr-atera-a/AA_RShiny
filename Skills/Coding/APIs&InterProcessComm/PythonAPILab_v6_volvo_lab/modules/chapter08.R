# modules/chapter08.R
# Chapter 8: Pagination, Searching, and Ordering

CH08_FILES <- list(

  list(
    name = "pagination_model.py",
    description = "<strong>pagination_model.py</strong> — Exercise 50: SQLAlchemy <code>paginate()</code> and the <code>get_all_published(page, per_page)</code> query. Walks through all Pagination attributes: <code>items</code>, <code>total</code>, <code>pages</code>, <code>has_next</code>, <code>has_prev</code>.",
    code = 'from http import HTTPStatus

print("=== SQLAlchemy Pagination ===\n")

class FakePagination:
    """Mirrors the SQLAlchemy Pagination object returned by .paginate()"""
    def __init__(self, items, page, per_page, total):
        self.items    = items
        self.page     = page
        self.per_page = per_page
        self.total    = total
        self.pages    = (total + per_page - 1) // per_page
        self.has_prev = page > 1
        self.has_next = page < self.pages
        self.prev_num = page - 1 if self.has_prev else None
        self.next_num = page + 1 if self.has_next else None

ALL_RECIPES = [{"id": i, "name": f"Recipe {i}", "is_publish": True} for i in range(1, 48)]

def get_all_published(page=1, per_page=20):
    """mirrors Recipe.get_all_published(page, per_page)"""
    start = (page - 1) * per_page
    items = ALL_RECIPES[start:start + per_page]
    return FakePagination(items, page, per_page, len(ALL_RECIPES))

def show_page(page, per_page=20):
    pag = get_all_published(page, per_page)
    first_id = pag.items[0]["id"]  if pag.items else "n/a"
    last_id  = pag.items[-1]["id"] if pag.items else "n/a"
    print(f"  GET /recipes?page={page}&per_page={per_page}")
    print(f"    total    : {pag.total} recipes across {pag.pages} pages")
    print(f"    this page: {len(pag.items)} items  (ids {first_id}..{last_id})")
    print(f"    has_prev : {pag.has_prev}  prev_num={pag.prev_num}")
    print(f"    has_next : {pag.has_next}  next_num={pag.next_num}")
    print()

show_page(1)
show_page(2)
show_page(3)

print("=== SQLAlchemy .paginate() syntax ===\n")
print("""
  Recipe.query
        .filter(Recipe.is_publish.is_(True))
        .order_by(desc(Recipe.created_at))
        .paginate(page=page, per_page=per_page)
  # Returns a Pagination object:
  #   .items     -> ORM objects for this page
  #   .total     -> total matching records
  #   .pages     -> total page count
  #   .has_next  -> bool
  #   .has_prev  -> bool
  #   .next_num  -> int or None
  #   .prev_num  -> int or None
""")',
    demo = NULL
  ),

  list(
    name = "pagination_schema.py",
    description = "<strong>pagination_schema.py</strong> — Exercise 50: the <code>PaginationSchema</code> that wraps paginated results with first/last/prev/next navigation links. Built from the book's <code>schemas/pagination.py</code>.",
    code = 'import json
from urllib.parse import urlencode

class FakePagination:
    def __init__(self, items, page, per_page, total):
        self.items    = items
        self.page     = page
        self.per_page = per_page
        self.total    = total
        self.pages    = (total + per_page - 1) // per_page
        self.has_prev = page > 1
        self.has_next = page < self.pages
        self.prev_num = page - 1 if self.has_prev else None
        self.next_num = page + 1 if self.has_next else None

BASE_URL = "https://api.smilecook.com/recipes"

def get_url(page, q="", sort="created_at", order="desc"):
    args = {"page": page, "per_page": 20, "sort": sort, "order": order}
    if q:
        args["q"] = q
    return f"{BASE_URL}?{urlencode(args)}"

def get_pagination_links(pag, q=""):
    links = {
        "first": get_url(1, q),
        "last":  get_url(pag.pages, q),
    }
    if pag.has_prev:
        links["prev"] = get_url(pag.prev_num, q)
    if pag.has_next:
        links["next"] = get_url(pag.next_num, q)
    return links

def dump_pagination(pag, q=""):
    return {
        "links":    get_pagination_links(pag, q),
        "page":     pag.page,
        "pages":    pag.pages,
        "per_page": pag.per_page,
        "total":    pag.total,
        "data":     pag.items,
    }

ALL = [{"id": i, "name": f"Recipe {i}"} for i in range(1, 48)]

def paginate(page, per_page=20):
    s = (page - 1) * per_page
    return FakePagination(ALL[s:s + per_page], page, per_page, len(ALL))

print("=== PaginationSchema output (page 2 of 3) ===\n")
result = dump_pagination(paginate(2))
result_display = dict(result)
result_display["data"] = f"[{len(result[\"data\"])} recipe objects]"
print(json.dumps(result_display, indent=2))

print()
print("=== With search query q=salad ===\n")
salad_results = [r for r in ALL if "Recipe" in r["name"]][:5]
fake_pag = FakePagination(salad_results, 1, 20, 5)
result2 = dump_pagination(fake_pag, q="salad")
result2["data"] = f"[{len(result2[\"data\"])} matched recipes]"
print(json.dumps(result2, indent=2))',
    demo = NULL
  ),

  list(
    name = "search_and_sort.py",
    description = "<strong>search_and_sort.py</strong> — Exercises 52-54: full-text search with <code>ilike()</code>, dynamic sort column via <code>getattr(cls, sort)</code>, and <code>asc()</code>/<code>desc()</code> ordering. The complete <code>get_all_published(q, page, per_page, sort, order)</code> query.",
    code = 'print("=== Recipe Search + Sort Demo ===\n")

RECIPES = [
    {"id": 1, "name": "Egg Salad",       "description": "Lovely cold salad",        "cook_time": 10, "num_of_servings": 2, "is_publish": True},
    {"id": 2, "name": "Tomato Pasta",    "description": "Rich tomato sauce pasta",   "cook_time": 20, "num_of_servings": 4, "is_publish": True},
    {"id": 3, "name": "Caesar Salad",    "description": "Classic Caesar dressing",   "cook_time":  5, "num_of_servings": 2, "is_publish": True},
    {"id": 4, "name": "Chicken Soup",    "description": "Hearty tomato chicken",     "cook_time": 45, "num_of_servings": 6, "is_publish": True},
    {"id": 5, "name": "Avocado Toast",   "description": "Healthy breakfast toast",   "cook_time":  8, "num_of_servings": 1, "is_publish": True},
    {"id": 6, "name": "Pasta Carbonara", "description": "Creamy Italian classic",    "cook_time": 25, "num_of_servings": 2, "is_publish": True},
    {"id": 7, "name": "Draft Recipe",    "description": "Not published yet",         "cook_time": 30, "num_of_servings": 4, "is_publish": False},
]

class FakePagination:
    def __init__(self, items, page, per_page, total):
        self.items    = items
        self.page     = page
        self.per_page = per_page
        self.total    = total
        self.pages    = max(1, (total + per_page - 1) // per_page)
        self.has_prev = page > 1
        self.has_next = page < self.pages

VALID_SORTS = {"cook_time", "num_of_servings", "name"}

def get_all_published(q="", page=1, per_page=20, sort="cook_time", order="asc"):
    """mirrors Recipe.get_all_published() from Exercise 54"""
    keyword = q.lower()
    results = [
        r for r in RECIPES
        if r["is_publish"] and (
            not keyword
            or keyword in r["name"].lower()
            or keyword in r["description"].lower()
        )
    ]
    if sort not in VALID_SORTS:
        sort = "cook_time"
    reverse = (order == "desc")
    results.sort(key=lambda r: r[sort], reverse=reverse)
    start = (page - 1) * per_page
    return FakePagination(results[start:start + per_page], page, per_page, len(results))

def show_search(q="", sort="cook_time", order="asc", label=None):
    label = label or f"q={q!r}  sort={sort}  order={order}"
    pag = get_all_published(q=q, sort=sort, order=order)
    names = [r["name"] for r in pag.items]
    print(f"  {label}")
    print(f"    total={pag.total}  results={names}")
    print()

show_search(sort="cook_time", order="asc",
            label="All published, cook_time ASC (quickest first)")
show_search(q="tomato", label="Search: tomato")
show_search(q="salad",  label="Search: salad")
show_search(sort="num_of_servings", order="desc",
            label="Sort by num_of_servings DESC")
show_search(q="unicorn", label="No match")

print("=== SQLAlchemy equivalent ===\n")
print("""
  keyword = "%{}%".format(q)

  Recipe.query.filter(
      or_(cls.name.ilike(keyword),
          cls.description.ilike(keyword)),
      cls.is_publish.is_(True)
  )
  .order_by(asc(getattr(cls, sort)))   # dynamic column
  .paginate(page=page, per_page=per_page)
""")',
    demo = NULL
  ),

  list(
    name = "webargs_query_params.py",
    description = "<strong>webargs_query_params.py</strong> — Exercise 54: the complete <code>RecipeListResource.get()</code> with all five webargs query parameters: <code>q</code>, <code>page</code>, <code>per_page</code>, <code>sort</code>, and <code>order</code> — plus the cache decorator.",
    code = 'from http import HTTPStatus

print("=== RecipeListResource.get() -- all five query params ===\n")

webargs_code = """
from webargs import fields
from webargs.flaskparser import use_kwargs

class RecipeListResource(Resource):

    @use_kwargs({
        "q":        fields.Str(missing=""),           # search keyword
        "page":     fields.Int(missing=1),            # page number
        "per_page": fields.Int(missing=20),           # page size
        "sort":     fields.Str(missing="created_at"), # sort column
        "order":    fields.Str(missing="desc"),       # asc or desc
    })
    @cache.cached(timeout=60, query_string=True)
    def get(self, q, page, per_page, sort, order):
        print("Querying database...")   # only on cache MISS

        if sort not in ["created_at", "cook_time", "num_of_servings"]:
            sort = "created_at"         # safe whitelist fallback

        if order not in ["asc", "desc"]:
            order = "desc"

        paginated = Recipe.get_all_published(q, page, per_page, sort, order)
        return recipe_pagination_schema.dump(paginated).data, HTTPStatus.OK
"""
print(webargs_code)

print("=== Example URL patterns ===\n")
examples = [
    ("GET /recipes",                                   "page 1, 20/page, newest first"),
    ("GET /recipes?page=2",                            "second page"),
    ("GET /recipes?q=pasta",                           "search for pasta"),
    ("GET /recipes?sort=cook_time&order=asc",          "quickest recipes first"),
    ("GET /recipes?q=salad&sort=num_of_servings&order=desc", "salads, most servings first"),
    ("GET /recipes?per_page=5&page=3",                 "custom page size"),
]
print("  %-52s %s" % ("URL", "Description"))
print("  " + "-" * 72)
for url, desc in examples:
    print(f"  {url:<52} {desc}")',
    demo = NULL
  )
)

# ── Chapter 8 UI ──────────────────────────────────────────────
chapter8_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(8, "\U0001f4c4", "Pagination, Searching, and Ordering",
      "Scale the Smilecook API for large datasets. Implement cursor-based pagination with SQLAlchemy paginate(), full-text ILIKE search across name and description, dynamic sort columns, and HAL-style navigation links.",
      c("Pagination", "paginate()", "PaginationSchema", "ILIKE Search", "sort + order", "webargs", "navigation links")),

    stats_row(
      list("20",    "Default per_page"),
      list("5",     "Query params"),
      list("ilike", "Search method"),
      list("4",     "Nav links")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),

        tabPanel(title = tagList(icon("book"), " Theory"),

          fluidRow(
            box(title = "\U0001f4c4 SQLAlchemy Pagination", status = "info", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                tags$h5("paginate() method"),
                tags$p("Instead of fetching all records, chain ", tags$code(".paginate(page, per_page)"), " to get a Pagination object:"),
                tags$pre(class = "code-inline",
"pag = Recipe.query
          .filter(Recipe.is_publish.is_(True))
          .order_by(desc(Recipe.created_at))
          .paginate(page=page, per_page=per_page)

pag.items    # ORM objects for this page
pag.total    # total matching records
pag.pages    # total pages
pag.has_next # bool
pag.has_prev # bool
pag.next_num # int or None
pag.prev_num # int or None")
              ),
              div(class = "tip-box",
                HTML("<strong>\U0001f4a1 Why paginate?</strong> Returning 10,000 recipes in one response is slow and unusable. Pagination keeps responses fast and predictable in size."))
            ),

            box(title = "\U0001f517 PaginationSchema + Nav Links", status = "warning", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                tags$h5("Response envelope"),
                tags$pre(class = "code-inline",
"{
  \"links\": {
    \"first\": \"https://api.smilecook.com/recipes?page=1\",
    \"last\":  \"https://api.smilecook.com/recipes?page=5\",
    \"prev\":  \"https://api.smilecook.com/recipes?page=1\",
    \"next\":  \"https://api.smilecook.com/recipes?page=3\"
  },
  \"page\":     2,
  \"pages\":    5,
  \"per_page\": 20,
  \"total\":    94,
  \"data\":     [...]
}")
              ),
              div(class = "success-box",
                HTML("<strong>\u2705 HAL-style links</strong> let API clients navigate without constructing URLs. Just follow <code>links.next</code>."))
            )
          ),

          fluidRow(
            box(title = "\U0001f50d ILIKE Search", status = "success", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                tags$h5("Case-insensitive full-text search"),
                tags$pre(class = "code-inline",
"keyword = \"%{}%\".format(q)   # SQL wildcard

Recipe.query.filter(
    or_(
        cls.name.ilike(keyword),         # case-insensitive
        cls.description.ilike(keyword)   # match either field
    ),
    cls.is_publish.is_(True)
)")
              ),
              div(class = "framework-card",
                tags$h5("webargs q parameter"),
                tags$pre(class = "code-inline",
"@use_kwargs({\"q\": fields.Str(missing=\"\")})
def get(self, q, ...):
    # q=\"\" = return all (no filter applied)
    # GET /recipes?q=pasta -> filters for pasta")
              )
            ),

            box(title = "\U0001f504 Dynamic Sort + Order", status = "danger", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                tags$h5("getattr() for dynamic columns"),
                tags$pre(class = "code-inline",
"VALID = [\"created_at\", \"cook_time\", \"num_of_servings\"]

if sort not in VALID:
    sort = \"created_at\"   # safe default

if order == \"asc\":
    sort_logic = asc(getattr(Recipe, sort))
else:
    sort_logic = desc(getattr(Recipe, sort))

query.order_by(sort_logic)")
              ),
              div(class = "info-box-plain",
                HTML("<strong>\u2139 Always whitelist</strong> the <code>sort</code> parameter. Allowing arbitrary column names exposes DB internals and risks injection attacks."))
            )
          )
        ),


          # ── VOLVO API CONTEXT ──────────────────────────────────────

          # -- VOLVO API CONTEXT -----------------------------------------------------
          fluidRow(
            box(title = "\U0001f69a Volvo API Connection: Pagination with moreDataAvailable + lastVin",
                status = "primary", solidHeader = TRUE, width = 12,
              div(class = "volvo-context-banner",
                span(class = "volvo-badge", "\U0001f69a Volvo Group Vehicle API v1.0.6"),
                span(class = "volvo-relevance", "Direct relevance: pagination is a core API mechanic")
              ),
              div(class = "volvo-card",
                tags$h5("Two pagination patterns in the Volvo API"),
                tags$p("The Volvo API uses two complementary pagination strategies that directly mirror what Chapter 8 covers with SQLAlchemy:")
              ),
              fluidRow(
                column(6,
                  div(class = "volvo-card",
                    tags$h5("Pattern 1: Cursor-based (lastVin)"),
                    tags$p("Used for", tags$code("/vehicles"), "and", tags$code("latestOnly=true"), "positions. The last VIN from each response becomes the cursor for the next call -- equivalent to SQLAlchemy", tags$code("paginate()"), "but keyed by VIN instead of page number:"),
                    tags$pre(class = "code-inline",
'# Step 1: First call (max 100 vehicles per response)
GET /vehicle/vehicles

# Response:
# { "vehicleResponse": {...}, "moreDataAvailable": true }

# Step 2: Pass last VIN from response as cursor
GET /vehicle/vehicles?lastVin=ABC12345678901234

# Repeat until moreDataAvailable = false'),
                    div(class = "tip-box",
                      HTML("<strong>\U0001f4a1 Equivalent to Chapter 8:</strong> <code>moreDataAvailable=true</code> maps to SQLAlchemy <code>pag.has_next</code>. <code>lastVin</code> is the cursor equivalent of a page number."))
                  )
                ),
                column(6,
                  div(class = "volvo-card",
                    tags$h5("Pattern 2: Time-window (starttime + stoptime)"),
                    tags$p("Used for", tags$code("/vehiclepositions"), "and", tags$code("/vehiclestatuses"), ". Advance the time window using", tags$code("receivedDateTime + 1 second"), "from the last record:"),
                    tags$pre(class = "code-inline",
'# Initial request (up to 14 days retention):
GET /vehiclestatuses
    ?starttime=2024-01-01T00:00:00Z
    &stoptime=2024-01-15T00:00:00Z

# If moreDataAvailable=true, advance cursor:
# last_received = response["vehicleStatuses"][-1]["receivedDateTime"]
# next_start = last_received + 1 second

GET /vehiclestatuses
    ?starttime=2024-01-01T06:34:05Z
    &stoptime=2024-01-15T00:00:00Z

# Repeat until moreDataAvailable = false'),
                    div(class = "tip-box",
                      HTML("<strong>\U0001f4a1 Always use</strong> <code>datetype=received</code> (the default). Vehicles may delay sending events due to connectivity, so <code>receivedDateTime</code> is more reliable than <code>createdDateTime</code> for pagination."))
                  )
                )
              ),
              fluidRow(
                column(12,
                  div(class = "volvo-card",
                    tags$h5("Recommended polling loop (Python)"),
                    tags$pre(class = "code-inline",
'import http.client, json
from datetime import datetime, timedelta

def poll_vehicle_statuses(last_sync_dt):
    conn = http.client.HTTPSConnection(
        "api.renault-trucks.com"
    )
    headers = {
        "authorization": "Basic <CREDENTIALS>",
        "content-type":  "application/x.volvogroup.com"
                         ".vehiclestatuses.v1.0+json"
    }
    starttime    = last_sync_dt.strftime("%Y-%m-%dT%H:%M:%SZ")
    stoptime     = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")
    all_statuses = []

    while True:
        url = (f"/vehicle/vehiclestatuses"
               f"?starttime={starttime}&stoptime={stoptime}"
               f"&datetype=received")
        conn.request("GET", url, headers=headers)
        data = json.loads(conn.getresponse().read())
        statuses = (data["vehicleStatusResponse"]
                        ["vehicleStatuses"])
        all_statuses.extend(statuses)

        if not data["moreDataAvailable"]:
            break

        # Advance cursor: last receivedDateTime + 1 second
        last_dt   = statuses[-1]["receivedDateTime"]
        next_dt   = (datetime.fromisoformat(
                         last_dt.replace("Z", "+00:00"))
                     + timedelta(seconds=1))
        starttime = next_dt.strftime("%Y-%m-%dT%H:%M:%SZ")

    return all_statuses')
                  )
                )
              )
            )
          ),

        tabPanel(title = tagList(icon("code"), " Code Lab"),

          code_lab_header(
            "Chapter 8 \u2014 Pagination, Searching, and Ordering",
            "Pagination model, PaginationSchema with nav links, ILIKE search + dynamic sort, full five-param query interface."
          ),
          file_pills_ui(ns, CH08_FILES),
          py_code_display(ns),
          terminal_ui(ns)
        ),

        tabPanel(title = tagList(icon("truck"), " Volvo: Positions"),
          fluidRow(
            box(title = "\U0001f4da How to Use This Tab", status = "primary",
                solidHeader = TRUE, width = 12, collapsible = TRUE,
              div(class = "volvo-card",
                tags$p(tags$strong("Purpose:"), " Query", tags$code("GET /vehicle/vehiclepositions"), "-- GPS positions for your fleet. Demonstrates the pagination patterns covered in the Theory tab."),
                tags$p(tags$strong("latestOnly = true"), ": Returns only the most recent position per vehicle. Use for live map dashboards. Pair with", tags$code("lastVin"), "for fleets > 100 vehicles."),
                tags$p(tags$strong("Time window"), ": Provide both", tags$code("starttime"), "and", tags$code("stoptime"), "in ISO 8601 format to retrieve historical positions. When", tags$code("moreDataAvailable=true"), ", advance", tags$code("starttime"), "to the last", tags$code("receivedDateTime + 1 second"), "and call again."),
                tags$p(tags$strong("triggerFilter"), ": Limit to specific event types. Use", tags$code("TIMER"), "for regular position pings, or EV triggers like", tags$code("BATTERY_PACK_CHARGING_STATUS_CHANGE"), "to see only charging events."),
                tags$p(tags$strong("datetype"), ": Always use", tags$code("received"), "(default) -- vehicles may delay sending due to connectivity, making", tags$code("receivedDateTime"), "more reliable for pagination cursors."),
                tags$p(tags$strong("Update frequency"), ": The MAP service sends positions every", tags$strong("1 minute while moving"), ", every", tags$strong("10 minutes while stationary"), ". Call this endpoint no more than once per minute."),
                tags$p(tags$strong("Retention"), ": 14 days from receivedDateTime.")
              )
            )
          ),
          fluidRow(
            box(title = "\U0001f6f9 /vehiclepositions Parameters", status = "warning",
                solidHeader = TRUE, width = 5,
              textInput(ns("v8_vin"), "VIN (blank = all vehicles):",
                        placeholder = "ABC12345678901234"),
              checkboxInput(ns("v8_latest"),
                "latestOnly = true (recommended for live map)", TRUE),
              radioButtons(ns("v8_datetype"), "datetype:",
                           choices = c("received (recommended)" = "received",
                                       "created" = "created"),
                           selected = "received", inline = TRUE),
              hr(),
              textInput(ns("v8_start"), "starttime (ISO 8601):",
                        placeholder = "2024-01-15T08:00:00Z"),
              textInput(ns("v8_stop"),  "stoptime (ISO 8601):",
                        placeholder = "2024-01-15T09:00:00Z"),
              tags$small(tags$em("Required when latestOnly = false. Use starttime+stoptime for historical data.")),
              hr(),
              selectInput(ns("v8_trigger"), "triggerFilter (optional):",
                          choices = c("(All triggers)","TIMER","IGNITION_ON","IGNITION_OFF",
                            "ENGINE_ON","ENGINE_OFF","DRIVER_LOGIN","DRIVER_LOGOUT",
                            "GEOFENCE","MOVEMENT","NO_MOVEMENT","IDLING",
                            "BATTERY_PACK_CHARGING_STATUS_CHANGE",
                            "BATTERY_PACK_CHARGING_CONNECTION_STATUS_CHANGE",
                            "BATTERY_PACK_HIGH_DISCHARGE","VEHICLE_MODE"),
                          selected = "(All triggers)"),
              textInput(ns("v8_lastvin"), "lastVin (pagination cursor):",
                        placeholder = "paste last VIN when moreDataAvailable=true"),
              br(),
              actionButton(ns("v8_run"), "\u25b6  Call API  --  GET /vehiclepositions",
                           class = "btn-run")
            ),
            box(title = "\U0001f4cd Position Response Fields", status = "info",
                solidHeader = TRUE, width = 7,
              div(class = "volvo-card",
                tags$h5("VehiclePosition object"),
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(tags$th("Field"), tags$th("Type"), tags$th("Description"))),
                  tags$tbody(
                    tags$tr(tags$td(tags$code("vin")),                tags$td("String"),   tags$td("Vehicle Identification Number")),
                    tags$tr(tags$td(tags$code("createdDateTime")),    tags$td("DateTime"), tags$td("When data was captured in vehicle")),
                    tags$tr(tags$td(tags$code("receivedDateTime")),   tags$td("DateTime"), tags$td("When server received it -- use for pagination cursor")),
                    tags$tr(tags$td(tags$code("gnssPosition.latitude")), tags$td("Float"), tags$td("WGS84 latitude")),
                    tags$tr(tags$td(tags$code("gnssPosition.longitude")),tags$td("Float"), tags$td("WGS84 longitude")),
                    tags$tr(tags$td(tags$code("gnssPosition.heading")),  tags$td("Int"),   tags$td("Direction 0-359 degrees")),
                    tags$tr(tags$td(tags$code("gnssPosition.altitude")), tags$td("Int"),   tags$td("Meters above sea level")),
                    tags$tr(tags$td(tags$code("gnssPosition.speed")),    tags$td("Float"), tags$td("GNSS speed in km/h")),
                    tags$tr(tags$td(tags$code("wheelBasedSpeed")),    tags$td("Float"),    tags$td("Wheel-based speed km/h (mandatory)")),
                    tags$tr(tags$td(tags$code("tachographSpeed")),    tags$td("Float"),    tags$td("Tachograph speed km/h")),
                    tags$tr(tags$td(tags$code("triggerType")),        tags$td("Object"),   tags$td("What caused this position event"))
                  )
                )
              ),
              div(class = "volvo-card",
                tags$h5("Pagination response fields"),
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(tags$th("Field"), tags$th("Action when true"))),
                  tags$tbody(
                    tags$tr(tags$td(tags$code("moreDataAvailable")),   tags$td("Advance starttime to last receivedDateTime + 1s")),
                    tags$tr(tags$td(tags$code("requestServerDateTime")),tags$td("Use as starttime for next incremental poll"))
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
                  span(class = "term-label", "GET /vehicle/vehiclepositions")),
                div(class = "terminal-body", verbatimTextOutput(ns("v8_out"))))
            )
          )
        )

      )
    )
  )
}

chapter8_server <- function(id, creds = NULL) {
  moduleServer(id, function(input, output, session) {
    code_lab_server(input, output, session, CH08_FILES)

    v8_result <- eventReactive(input$v8_run, {
      un      <- creds$username; pw <- creds$password
      vin     <- trimws(input$v8_vin)
      latest  <- isTRUE(input$v8_latest)
      dtype   <- input$v8_datetype
      trigger <- input$v8_trigger
      start   <- trimws(input$v8_start)
      stop    <- trimws(input$v8_stop)
      lv      <- trimws(input$v8_lastvin)
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
if "', vin, '":      params["vin"]         = "', vin, '"
if "', dtype, '":    params["datetype"]    = "', dtype, '"
if "', trigger, '" != "(All triggers)":
    params["triggerFilter"] = "', trigger, '"
if "', start, '":    params["starttime"]   = "', start, '"
if "', stop, '":     params["stoptime"]    = "', stop, '"
if "', lv, '":       params["lastVin"]     = "', lv, '"
if ', if(isTRUE(latest)) 'True' else 'False', ':
    params["latestOnly"] = "true"
_call("vehiclepositions", params, un, pw)
')
      run_python_safe(code)
    })
    output$v8_out <- renderText({
      if (input$v8_run == 0)
        return("$ Ready -- configure filters and click Call API")
      v8_result()
    })

  })
}
