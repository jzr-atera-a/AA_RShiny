# modules/chapter01.R
# Chapter 1: Your First Step — REST, HTTP, JSON, Flask Basics

CH01_FILES <- list(

  list(
    name = "http_concepts.py",
    description = "<strong>http_concepts.py</strong> — Demonstrates core HTTP concepts: status codes, methods, and JSON structure using Python's built-in <code>http</code> and <code>json</code> libraries. No Flask needed — pure stdlib exploration.",
    code = 'import json
from http import HTTPStatus

# HTTP Methods and their CRUD mapping
http_methods = {
    "GET":    "Read   — Retrieve a resource",
    "POST":   "Create — Create a new resource",
    "PUT":    "Update — Replace a resource",
    "PATCH":  "Update — Partially update a resource",
    "DELETE": "Delete — Remove a resource",
}

print("=== HTTP Methods & CRUD Mapping ===")
for method, description in http_methods.items():
    print(f"  {method:<8} -> {description}")

# Common HTTP Status Codes
status_codes = [
    (HTTPStatus.OK,                  "Standard success response"),
    (HTTPStatus.CREATED,             "Resource created successfully"),
    (HTTPStatus.NO_CONTENT,          "Success, no body returned"),
    (HTTPStatus.BAD_REQUEST,         "Invalid request syntax"),
    (HTTPStatus.UNAUTHORIZED,        "Authentication required"),
    (HTTPStatus.FORBIDDEN,           "Authenticated but no permission"),
    (HTTPStatus.NOT_FOUND,           "Resource does not exist"),
    (HTTPStatus.UNPROCESSABLE_ENTITY,"Validation failed"),
    (HTTPStatus.INTERNAL_SERVER_ERROR, "Server-side error"),
]

print()
print("=== Common HTTP Status Codes ===")
for status, meaning in status_codes:
    print(f"  {status.value} {status.phrase:<32} — {meaning}")

# JSON structure example
recipe = {
    "id": 1,
    "name": "Egg Salad",
    "description": "A lovely egg salad recipe.",
    "num_of_servings": 2,
    "cook_time": 10,
    "is_publish": True
}

print()
print("=== JSON Representation of a Recipe ===")
print(json.dumps(recipe, indent=2))',
    demo = NULL
  ),

  list(
    name = "rest_principles.py",
    description = "<strong>rest_principles.py</strong> — Illustrates the 6 REST architectural constraints and RESTful URL design with a recipe resource. Explains statelessness, client-server separation, and uniform interface.",
    code = '# REST Constraints — Roy Fielding (2000)

constraints = [
    ("1. Client-Server",      "UI and data storage are separated. Client handles UI; server handles data."),
    ("2. Stateless",          "Each request contains ALL info needed. Server holds no client session state."),
    ("3. Cacheable",          "Responses must define themselves as cacheable or non-cacheable."),
    ("4. Uniform Interface",  "Resources identified by URIs. Manipulation through representations."),
    ("5. Layered System",     "Client cannot tell whether it is connected directly to end server."),
    ("6. Code on Demand",     "Optional: servers can extend client functionality by transferring code."),
]

print("=== The 6 REST Architectural Constraints ===")
for name, desc in constraints:
    print(f"\n  {name}")
    print(f"    {desc}")

# RESTful URL design for the Smilecook recipe API
print()
print("=== RESTful URL Design: Smilecook Recipe API ===")
endpoints = [
    ("GET",    "/recipes",                  "List all published recipes"),
    ("POST",   "/recipes",                  "Create a new recipe"),
    ("GET",    "/recipes/{id}",             "Get a specific recipe"),
    ("PUT",    "/recipes/{id}",             "Update a recipe"),
    ("DELETE", "/recipes/{id}",             "Delete a recipe"),
    ("PUT",    "/recipes/{id}/publish",     "Publish a recipe"),
    ("DELETE", "/recipes/{id}/publish",     "Unpublish a recipe"),
]

print("  %-8s %-30s %s" % ("Method", "URL", "Description"))
print("  " + "-" * 65)
for method, url, desc in endpoints:
    print(f"  {method:<8} {url:<30} {desc}")',
    demo = NULL
  ),

  list(
    name = "exercise01_hello_flask.py",
    description = "<strong>exercise01_hello_flask.py</strong> — The book's first Flask application (Exercise 1). Demonstrates the minimal Flask app structure: importing Flask, creating the app instance, defining a route, and running the dev server. Runs in simulation mode here.",
    code = '# Exercise 1: Building Our First Flask Application
# Source: Lesson01/Exercise01/app.py

# In a real environment you would run this as:
#   flask run  OR  python app.py
# Here we simulate the Flask routing logic without a live server.

# ── Simulated Flask-style routing ─────────────────────────────
class SimulatedFlask:
    """Minimal Flask-like router for demonstration purposes."""

    def __init__(self, name):
        self.name = name
        self._routes = {}

    def route(self, path, methods=None):
        def decorator(f):
            self._routes[path] = f
            return f
        return decorator

    def simulate_request(self, path, method="GET"):
        handler = self._routes.get(path)
        if handler:
            return f"200 OK  ->  {handler()}"
        return "404 Not Found"


app = SimulatedFlask(__name__)


@app.route("/")
def hello():
    return "Hello World!"


# ── Demo ──────────────────────────────────────────────────────
print("=== Exercise 1: Hello World Flask App ===")
print()
print("App routes registered:", list(app._routes.keys()))
print()
print("Simulating GET /")
print(" ", app.simulate_request("/"))
print()
print("Simulating GET /unknown")
print(" ", app.simulate_request("/unknown"))
print()
print("Real Flask code (what runs with `flask run`):")
print("""
  from flask import Flask
  app = Flask(__name__)

  @app.route("/")
  def hello():
      return "Hello World!"

  if __name__ == "__main__":
      app.run()
""")',
    demo = NULL
  ),

  list(
    name = "exercise02_recipe_api.py",
    description = "<strong>exercise02_recipe_api.py</strong> — Full recipe API from Exercise 2. Implements GET all recipes, GET by ID, POST create, and PUT update using Flask's <code>jsonify</code> and <code>request</code>. Simulated here to show the logic and JSON responses without a live server.",
    code = '# Exercise 2: Managing Recipes with Flask
# Source: Lesson01/Exercise02/app.py
import json
from http import HTTPStatus

# ── In-memory recipe store ─────────────────────────────────────
recipes = [
    {"id": 1, "name": "Egg Salad",    "description": "This is a lovely egg salad recipe."},
    {"id": 2, "name": "Tomato Pasta", "description": "This is a lovely tomato pasta recipe."},
]

# ── Simulated route handlers (pure Python, no Flask server) ───

def get_recipes():
    return {"data": recipes}, HTTPStatus.OK

def get_recipe(recipe_id):
    recipe = next((r for r in recipes if r["id"] == recipe_id), None)
    if recipe:
        return recipe, HTTPStatus.OK
    return {"message": "recipe not found"}, HTTPStatus.NOT_FOUND

def create_recipe(data):
    recipe = {
        "id": len(recipes) + 1,
        "name": data.get("name"),
        "description": data.get("description"),
    }
    recipes.append(recipe)
    return recipe, HTTPStatus.CREATED

def update_recipe(recipe_id, data):
    recipe = next((r for r in recipes if r["id"] == recipe_id), None)
    if not recipe:
        return {"message": "recipe not found"}, HTTPStatus.NOT_FOUND
    recipe.update({"name": data.get("name"), "description": data.get("description")})
    return recipe, HTTPStatus.OK

# ── Demo ──────────────────────────────────────────────────────
def show(label, result):
    body, status = result
    print(f"  {label}")
    print(f"    Status : {status.value} {status.phrase}")
    print(f"    Body   : {json.dumps(body, indent=4)}")
    print()

print("=== Exercise 2: Flask Recipe API — Simulated Requests ===\n")

show("GET /recipes", get_recipes())
show("GET /recipes/1", get_recipe(1))
show("GET /recipes/99 (not found)", get_recipe(99))
show("POST /recipes", create_recipe({"name": "Caesar Salad", "description": "Classic Caesar with croutons."}))
show("GET /recipes (after POST)", get_recipes())
show("PUT /recipes/3", update_recipe(3, {"name": "Caesar Salad Updated", "description": "With extra anchovies."}))',
    demo = NULL
  ),

  list(
    name = "json_format.py",
    description = "<strong>json_format.py</strong> — Deep dive into JSON as used in REST APIs. Shows serialisation, deserialisation, nested structures, and the direct mapping between Python dicts/lists and JSON objects/arrays.",
    code = '# The JSON Format — Chapter 1 concept
import json

# Python dict -> JSON string (serialisation)
recipe = {
    "id": 1,
    "name": "Egg Salad",
    "description": "A lovely egg salad recipe.",
    "num_of_servings": 2,
    "cook_time": 10,
    "directions": "Step 1: Boil eggs. Step 2: Mix.",
    "is_publish": True,
    "tags": ["healthy", "quick", "vegetarian"],
    "nutrition": {
        "calories": 250,
        "protein_g": 12,
        "fat_g": 18
    }
}

print("=== Serialisation: Python dict -> JSON string ===")
json_string = json.dumps(recipe, indent=2)
print(json_string)

print()
print("=== Type mapping: Python -> JSON ===")
type_map = [
    ("dict",  "object  {}"),
    ("list",  "array   []"),
    ("str",   "string  \"\""),
    ("int",   "number  integer"),
    ("float", "number  float"),
    ("bool",  "boolean true/false"),
    ("None",  "null"),
]
for py_type, json_type in type_map:
    print(f"  Python {py_type:<8} ->  JSON {json_type}")

print()
print("=== Deserialisation: JSON string -> Python dict ===")
incoming_json = \'{"name": "Tomato Soup", "cook_time": 25, "is_publish": false}\'
parsed = json.loads(incoming_json)
print(f"  Raw string : {incoming_json}")
print(f"  Parsed type: {type(parsed).__name__}")
print(f"  name       : {parsed[\'name\']!r}  (type: {type(parsed[\'name\']).__name__})")
print(f"  cook_time  : {parsed[\'cook_time\']!r}  (type: {type(parsed[\'cook_time\']).__name__})")
print(f"  is_publish : {parsed[\'is_publish\']!r}  (type: {type(parsed[\'is_publish\']).__name__})")',
    demo = NULL
  )
)

# ── Chapter 1 UI ──────────────────────────────────────────────
chapter1_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(1, "\U0001f310", "Your First Step",
      "Understand the foundations of REST APIs: HTTP protocol, methods, status codes, JSON format, and how to build your first Flask web application from scratch.",
      c("REST", "HTTP Methods", "CRUD", "JSON", "HTTP Status Codes", "Flask", "Open API")),

    stats_row(
      list("6",      "REST Constraints"),
      list("5",      "HTTP Methods"),
      list("~50",    "HTTP Status Codes"),
      list("Flask",  "Web Framework")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),

        # ── THEORY TAB ─────────────────────────────────────────
        tabPanel(title = tagList(icon("book"), " Theory"),

          fluidRow(
            box(title = "\U0001f310 What Is an API?", status = "info", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                tags$h5("Application Programming Interface"),
                tags$p("An API is a set of definitions and protocols that allow two software applications to communicate with each other. It defines the rules for how requests and responses should be formatted."),
                tags$ul(
                  tags$li(tags$strong("REST API"), " — Representational State Transfer; uses HTTP protocol"),
                  tags$li(tags$strong("Client"), " — The application making the request (browser, mobile app, Postman)"),
                  tags$li(tags$strong("Server"), " — The application receiving and responding to requests"),
                  tags$li(tags$strong("Resource"), " — Any piece of data the API manages (e.g. a recipe, a user)")
                )
              ),
              div(class = "tip-box",
                HTML("<strong>\U0001f4a1 Key insight:</strong> REST is not a protocol or a standard — it is an <em>architectural style</em> described by Roy Fielding in his 2000 doctoral dissertation."))
            ),

            box(title = "\U0001f4cb The 6 REST Constraints", status = "warning", solidHeader = TRUE, width = 6,
              tags$table(class = "algo-table",
                tags$thead(tags$tr(tags$th("Constraint"), tags$th("What it means"))),
                tags$tbody(
                  tags$tr(tags$td("Client-Server"),     tags$td("UI and data storage are separated; each evolves independently")),
                  tags$tr(tags$td("Stateless"),         tags$td("Each request is self-contained; server stores no session state")),
                  tags$tr(tags$td("Cacheable"),         tags$td("Responses label themselves cacheable or non-cacheable")),
                  tags$tr(tags$td("Uniform Interface"), tags$td("Resources identified by URIs; manipulation via representations")),
                  tags$tr(tags$td("Layered System"),    tags$td("Client cannot tell if it is talking to the end server or a proxy")),
                  tags$tr(tags$td("Code on Demand"),    tags$td("Optional: server can send executable code to client"))
                )
              ),
              div(class = "success-box",
                HTML("<strong>\u2705 An API is RESTful</strong> if it satisfies the first 5 constraints. Code on Demand is optional."))
            )
          ),

          fluidRow(
            box(title = "\U0001f4e1 HTTP Methods & CRUD", status = "success", solidHeader = TRUE, width = 6,
              tags$table(class = "algo-table",
                tags$thead(tags$tr(tags$th("HTTP Method"), tags$th("CRUD"), tags$th("Description"), tags$th("Idempotent?"))),
                tags$tbody(
                  tags$tr(tags$td(tags$code("GET")),    tags$td("Read"),   tags$td("Retrieve a resource"),              tags$td("\u2705 Yes")),
                  tags$tr(tags$td(tags$code("POST")),   tags$td("Create"), tags$td("Create a new resource"),            tags$td("\u274c No")),
                  tags$tr(tags$td(tags$code("PUT")),    tags$td("Update"), tags$td("Replace an entire resource"),       tags$td("\u2705 Yes")),
                  tags$tr(tags$td(tags$code("PATCH")),  tags$td("Update"), tags$td("Partially update a resource"),      tags$td("\u2705 Yes")),
                  tags$tr(tags$td(tags$code("DELETE")), tags$td("Delete"), tags$td("Remove a resource"),                tags$td("\u2705 Yes"))
                )
              ),
              div(class = "info-box-plain",
                HTML("<strong>\u2139 Idempotent</strong> means calling the method multiple times produces the same result as calling it once. <code>GET /recipes/1</code> is idempotent; <code>POST /recipes</code> creates a new recipe each time."))
            ),

            box(title = "\U0001f7e1 HTTP Status Codes", status = "danger", solidHeader = TRUE, width = 6,
              tags$table(class = "algo-table",
                tags$thead(tags$tr(tags$th("Range"), tags$th("Category"), tags$th("Common Codes"))),
                tags$tbody(
                  tags$tr(tags$td("1xx"), tags$td("Informational"), tags$td("100 Continue")),
                  tags$tr(tags$td("2xx"), tags$td("Success"),       tags$td("200 OK, 201 Created, 204 No Content")),
                  tags$tr(tags$td("3xx"), tags$td("Redirection"),   tags$td("301 Moved, 304 Not Modified")),
                  tags$tr(tags$td("4xx"), tags$td("Client Error"),  tags$td("400 Bad Request, 401 Unauthorized, 403 Forbidden, 404 Not Found, 422 Unprocessable")),
                  tags$tr(tags$td("5xx"), tags$td("Server Error"),  tags$td("500 Internal Server Error, 503 Service Unavailable"))
                )
              ),
              div(class = "tip-box",
                HTML("<strong>\U0001f4a1 Rule of thumb:</strong> <em>2xx</em> = success, <em>4xx</em> = your fault (client), <em>5xx</em> = our fault (server)."))
            )
          ),

          fluidRow(
            box(title = "\U0001f40d The Flask Web Framework", status = "primary", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                tags$h5("What is Flask?"),
                tags$p("Flask is a lightweight Python web framework (micro-framework) built on Werkzeug and Jinja2. It provides the minimal tools needed to build web applications and APIs without imposing a rigid project structure."),
                tags$ul(
                  tags$li(tags$strong("Micro-framework"), " — Minimal core; you add only what you need"),
                  tags$li(tags$strong("WSGI"), " — Runs on any WSGI-compatible server (Gunicorn, uWSGI)"),
                  tags$li(tags$strong("Routing"), " — Decorator-based: ", tags$code("@app.route('/path')"))
                )
              ),
              div(class = "framework-card",
                tags$h5("Minimal Flask App Pattern"),
                tags$pre(class = "code-inline",
"from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return 'Hello World!'

if __name__ == '__main__':
    app.run()")
              )
            ),

            box(title = "\U0001f4c4 JSON — The API Data Format", status = "info", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                tags$h5("JSON (JavaScript Object Notation)"),
                tags$p("JSON is a lightweight, human-readable data format that has become the de facto standard for REST APIs. Python's ", tags$code("json"), " module handles serialisation and deserialisation."),
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(tags$th("Python type"), tags$th("JSON type"))),
                  tags$tbody(
                    tags$tr(tags$td(tags$code("dict")),  tags$td("object { }")),
                    tags$tr(tags$td(tags$code("list")),  tags$td("array [ ]")),
                    tags$tr(tags$td(tags$code("str")),   tags$td("string")),
                    tags$tr(tags$td(tags$code("int/float")), tags$td("number")),
                    tags$tr(tags$td(tags$code("bool")),  tags$td("true / false")),
                    tags$tr(tags$td(tags$code("None")),  tags$td("null"))
                  )
                )
              ),
              div(class = "tip-box",
                HTML("<strong>\U0001f4a1 Flask tip:</strong> Use <code>jsonify(data)</code> to return JSON from a route. It sets <code>Content-Type: application/json</code> automatically."))
            )
          )
        ),

        # ── CODE LAB TAB ───────────────────────────────────────

          # ── VOLVO API CONTEXT ──────────────────────────────────────

          # -- VOLVO API CONTEXT -----------------------------------------------------
          fluidRow(
            box(title = "\U0001f69a Volvo API Connection: REST, HTTP & JSON",
                status = "primary", solidHeader = TRUE, width = 12,
              div(class = "volvo-context-banner",
                span(class = "volvo-badge", "\U0001f69a Volvo Group Vehicle API v1.0.6"),
                span(class = "volvo-relevance", "Direct relevance: foundation concepts")
              ),
              fluidRow(
                column(4,
                  div(class = "volvo-card",
                    tags$h5("REST API"),
                    tags$p("The Volvo API is a pure HTTPS REST API hosted at:"),
                    tags$pre(class = "code-inline",
'https://api.renault-trucks.com/vehicle'),
                    tags$p("It follows REST constraints exactly as Chapter 1 defines them: stateless, client-server, uniform interface, cacheable responses.")
                  )
                ),
                column(4,
                  div(class = "volvo-card",
                    tags$h5("HTTP Methods"),
                    tags$p("The Volvo API is", tags$strong("read-only"), " -- every endpoint uses", tags$code("GET"), " only. There are no POST, PUT, PATCH, or DELETE operations."),
                    tags$table(class = "algo-table",
                      tags$thead(tags$tr(tags$th("Endpoint"), tags$th("Method"))),
                      tags$tbody(
                        tags$tr(tags$td(tags$code("/vehicles")),         tags$td(tags$code("GET"))),
                        tags$tr(tags$td(tags$code("/vehiclepositions")), tags$td(tags$code("GET"))),
                        tags$tr(tags$td(tags$code("/vehiclestatuses")),  tags$td(tags$code("GET")))
                      )
                    )
                  )
                ),
                column(4,
                  div(class = "volvo-card",
                    tags$h5("HTTP Status Codes in the Wild"),
                    tags$p("The Volvo API returns exactly the status codes Chapter 1 covers:"),
                    tags$table(class = "algo-table",
                      tags$thead(tags$tr(tags$th("Code"), tags$th("Meaning in Volvo API"))),
                      tags$tbody(
                        tags$tr(tags$td("200"), tags$td("Data returned successfully")),
                        tags$tr(tags$td("400"), tags$td("Missing auth header")),
                        tags$tr(tags$td("401"), tags$td("Wrong credentials / expired")),
                        tags$tr(tags$td("403"), tags$td("No rights on this vehicle")),
                        tags$tr(tags$td("404"), tags$td("VIN unknown")),
                        tags$tr(tags$td("429"), tags$td("Rate limit exceeded"))
                      )
                    )
                  )
                )
              ),
              fluidRow(
                column(6,
                  div(class = "volvo-card",
                    tags$h5("JSON Response: /vehicles"),
                    tags$p("Every Volvo API response is JSON. The", tags$code("/vehicles"), "endpoint returns nested JSON objects identical to what Chapter 1 covers in", tags$code("json_format.py"), ":"),
                    tags$pre(class = "code-inline",
'{
  "vehicleResponse": {
    "vehicles": [
      {
        "vin":              "ABC12345678901234",
        "brand":            "RENAULT TRUCKS",
        "type":             "TRUCK",
        "possibleFuelType": ["ELECTRIC"],
        "emissionLevel":    "EURO_VI",
        "productionDate":   {"day": 1, "month": 4, "year": 2022}
      }
    ]
  },
  "moreDataAvailable": false
}')
                  )
                ),
                column(6,
                  div(class = "volvo-card",
                    tags$h5("Authentication Header (Basic Auth)"),
                    tags$p("The Volvo API uses", tags$strong("HTTP Basic Auth"), " not JWT. Credentials are passed on every request:"),
                    tags$pre(class = "code-inline",
'import http.client

conn = http.client.HTTPSConnection(
    "api.renault-trucks.com"
)

headers = {
    "content-type":  "application/x.volvogroup.com"
                     ".vehicles.v1.0+json",
    "authorization": "Basic <USERNAME:PASSWORD>"
}

conn.request("GET", "/vehicle/vehicles",
             headers=headers)
res  = conn.getresponse()
data = res.read().decode("utf-8")'),
                    div(class = "tip-box",
                      HTML("<strong>\U0001f4a1 Key difference from Chapter 4:</strong> The Volvo API authenticates the <em>consumer application</em>, not end-users. Basic Auth sends a fixed credential per request -- no login flow, no token expiry."))
                  )
                )
              )
            )
          ),

        tabPanel(title = tagList(icon("code"), " Code Lab"),

          code_lab_header(
            "Chapter 1 \u2014 Your First Step",
            "HTTP concepts, REST principles, your first Flask hello-world, the full recipe CRUD API, and JSON serialisation deep-dive."
          ),
          file_pills_ui(ns, CH01_FILES),
          py_code_display(ns),
          terminal_ui(ns)
        ),

        tabPanel(title = tagList(icon("key"), " Volvo Credentials & API"),
          fluidRow(
            box(title = "\U0001f511 How to Use This Tab", status = "primary",
                solidHeader = TRUE, width = 12, collapsible = TRUE,
              div(class = "volvo-card",
                tags$p(tags$strong("Step 1:"), " Enter your Renault Trucks Developer Portal credentials below and click", tags$strong("Save Credentials"), "."),
                tags$p(tags$strong("Step 2:"), " Optionally tick ", tags$strong("Include Volvo Group vehicle data"), " to request proprietary fields (transport cycle, connected services, delivery date, etc.)."),
                tags$p(tags$strong("Step 3:"), " Click ", tags$strong("Call API"), " to call ", tags$code("GET /vehicle/vehicles"), ". The response shows all vehicles your account has access to."),
                tags$p(tags$strong("Credentials persist"), " across Chapters 3, 5, 8, and 9 for this session -- you only need to enter them once here."),
                tags$hr(),
                tags$p(tags$strong("What /vehicles returns:"), " A paginated list of all fleet vehicles, with VIN, brand, model, fuel type, emission level, and production date. Max 100 per response. Set ", tags$code("additionalContent=VOLVOGROUPVEHICLE"), " for proprietary Volvo fields.")
              )
            )
          ),
          fluidRow(
            box(title = "\U0001f510 API Credentials", status = "warning",
                solidHeader = TRUE, width = 4,
              textInput(ns("volvo_username"), "Username (Developer Portal):",
                        placeholder = "your@email.com"),
              passwordInput(ns("volvo_password"), "Password:"),
              actionButton(ns("volvo_save"), "Save Credentials",
                           class = "btn-copy", icon = icon("save")),
              br(), br(),
              uiOutput(ns("creds_status"))
            ),
            box(title = "\U0001f6f9 /vehicles Parameters", status = "info",
                solidHeader = TRUE, width = 4,
              checkboxInput(ns("v_additional"),
                "Include Volvo Group data (additionalContent=VOLVOGROUPVEHICLE)", FALSE),
              tags$hr(),
              tags$p(tags$strong("lastVin"), " -- for pagination (leave blank for first page):"),
              textInput(ns("v_lastvin"), NULL, placeholder = "ABC12345678901234"),
              tags$p(tags$small(tags$em(
                "When moreDataAvailable=true, paste the last VIN from the response here and call again."))),
              br(),
              actionButton(ns("volvo_run1"), "\u25b6  Call API  --  GET /vehicles",
                           class = "btn-run")
            ),
            box(title = "\U0001f4cb Endpoint Reference", status = "success",
                solidHeader = TRUE, width = 4,
              div(class = "volvo-card",
                tags$p(tags$strong("Base URL:")),
                tags$pre(class = "code-inline",
'https://api.renault-trucks.com/vehicle'),
                tags$p(tags$strong("Auth: HTTP Basic Auth")),
                tags$pre(class = "code-inline",
'Authorization: Basic <base64(user:pass)>'),
                tags$p(tags$strong("Recommended call frequency:")),
                tags$p(tags$code("/vehicles"), " -- once per day (static data)"),
                tags$p(tags$strong("Max records per page:"), " 100")
              )
            )
          ),
          fluidRow(
            box(title = "\U0001f5a5\ufe0f API Response", status = "primary",
                solidHeader = TRUE, width = 12,
              div(class = "terminal-wrap",
                div(class = "terminal-header",
                  div(class = "term-dots",
                    span(class = "td-red"), span(class = "td-yellow"), span(class = "td-green")),
                  span(class = "term-label", "GET /vehicle/vehicles")),
                div(class = "terminal-body",
                    verbatimTextOutput(ns("volvo_out1"))))
            )
          )
        )

      )
    )
  )
}

chapter1_server <- function(id, creds = NULL) {
  moduleServer(id, function(input, output, session) {
    code_lab_server(input, output, session, CH01_FILES)

    observeEvent(input$volvo_save, {
      creds$username <- trimws(input$volvo_username)
      creds$password <- trimws(input$volvo_password)
    })
    output$creds_status <- renderUI({
      if (nzchar(creds$username))
        div(style="color:#27ae60;font-weight:700;",
            "✅ Credentials saved for this session")
      else
        div(style="color:#e74c3c;",
            "⚠️ No credentials saved yet")
    })
    v_result1 <- eventReactive(input$volvo_run1, {
      un  <- creds$username; pw <- creds$password
      add <- if (isTRUE(input$v_additional)) "VOLVOGROUPVEHICLE" else ""
      lv  <- trimws(input$v_lastvin)
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
un  = "', un, '"
pw  = "', pw, '"
params = {}
if "', add, '":
    params["additionalContent"] = "', add, '"
if "', lv, '":
    params["lastVin"] = "', lv, '"
_call("vehicles", params, un, pw)
')
      run_python_safe(code)
    })
    output$volvo_out1 <- renderText({
      if (input$volvo_run1 == 0)
        return("$ Ready -- save credentials then click Call API")
      v_result1()
    })

  })
}
