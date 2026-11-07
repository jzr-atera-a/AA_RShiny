# modules/chapter02.R
# Chapter 2: Starting to Build Our Project — Flask-RESTful, Models, Resources

CH02_FILES <- list(

  list(
    name = "recipe_model.py",
    description = "<strong>recipe_model.py</strong> — The Recipe domain model from Exercise 6. Defines the <code>Recipe</code> class with auto-incrementing IDs, a <code>data</code> property returning a dict, and an <code>is_publish</code> flag. This is the in-memory model before any database is introduced.",
    code = '# Exercise 6: Creating the Recipe Model
# Source: Lesson02/Exercise06/models/recipe.py

recipe_list = []


def get_last_id():
    if recipe_list:
        last_recipe = recipe_list[-1]
    else:
        return 1
    return last_recipe.id + 1


class Recipe:

    def __init__(self, name, description, num_of_servings, cook_time, directions):
        self.id = get_last_id()
        self.name = name
        self.description = description
        self.num_of_servings = num_of_servings
        self.cook_time = cook_time
        self.directions = directions
        self.is_publish = False

    @property
    def data(self):
        return {
            "id":               self.id,
            "name":             self.name,
            "description":      self.description,
            "num_of_servings":  self.num_of_servings,
            "cook_time":        self.cook_time,
            "directions":       self.directions,
        }',
    demo = 'import json

# Create some recipes
r1 = Recipe("Egg Salad",    "Lovely egg salad.",        2, 10, "Boil eggs, mix with mayo.")
r2 = Recipe("Tomato Pasta", "Classic tomato pasta.",    4, 20, "Cook pasta, add sauce.")
r3 = Recipe("Caesar Salad", "Fresh Caesar with croutons.", 2, 5, "Toss romaine with dressing.")

recipe_list.extend([r1, r2, r3])

print("=== Recipe Model Demo ===\n")
for r in recipe_list:
    print(f"  Recipe #{r.id}: {r.name}")
    print(f"    is_publish : {r.is_publish}")
    print(f"    data       : {json.dumps(r.data, indent=6)}")
    print()

# Publish one
r2.is_publish = True
print(f"After publishing r2: r2.is_publish = {r2.is_publish}")
print(f"Auto-increment IDs: {[r.id for r in recipe_list]}")'
  ),

  list(
    name = "resourceful_routing.py",
    description = "<strong>resourceful_routing.py</strong> — Demonstrates Flask-RESTful's <code>Resource</code> class pattern (Exercises 7-10). Shows how HTTP methods map to class methods (<code>get</code>, <code>post</code>, <code>put</code>, <code>delete</code>) and how the <code>RecipeListResource</code> and <code>RecipeResource</code> differ in purpose.",
    code = '# Exercise 7-10: Resourceful Routing with Flask-RESTful
# Demonstrates the Resource class pattern (simulated, no HTTP server)
import json
from http import HTTPStatus

# ── In-memory store ───────────────────────────────────────────
recipe_list = []

def get_last_id():
    return (recipe_list[-1].id + 1) if recipe_list else 1

class Recipe:
    def __init__(self, name, description, num_of_servings, cook_time, directions):
        self.id = get_last_id()
        self.name = name
        self.description = description
        self.num_of_servings = num_of_servings
        self.cook_time = cook_time
        self.directions = directions
        self.is_publish = False

    @property
    def data(self):
        return {"id": self.id, "name": self.name,
                "description": self.description,
                "num_of_servings": self.num_of_servings,
                "cook_time": self.cook_time,
                "directions": self.directions}


# ── Flask-RESTful Resource classes (pure Python simulation) ───

class RecipeListResource:
    """Maps to /recipes  (GET all published, POST create)"""

    def get(self):
        data = [r.data for r in recipe_list if r.is_publish]
        return {"data": data}, HTTPStatus.OK

    def post(self, request_data):
        recipe = Recipe(**request_data)
        recipe_list.append(recipe)
        return recipe.data, HTTPStatus.CREATED


class RecipeResource:
    """Maps to /recipes/<id>  (GET one, PUT update, DELETE remove)"""

    def get(self, recipe_id):
        recipe = next((r for r in recipe_list if r.id == recipe_id and r.is_publish), None)
        if recipe is None:
            return {"message": "recipe not found"}, HTTPStatus.NOT_FOUND
        return recipe.data, HTTPStatus.OK

    def put(self, recipe_id, request_data):
        recipe = next((r for r in recipe_list if r.id == recipe_id), None)
        if recipe is None:
            return {"message": "recipe not found"}, HTTPStatus.NOT_FOUND
        recipe.name             = request_data["name"]
        recipe.description      = request_data["description"]
        recipe.num_of_servings  = request_data["num_of_servings"]
        recipe.cook_time        = request_data["cook_time"]
        recipe.directions       = request_data["directions"]
        return recipe.data, HTTPStatus.OK


class RecipePublishResource:
    """Maps to /recipes/<id>/publish  (PUT publish, DELETE unpublish)"""

    def put(self, recipe_id):
        recipe = next((r for r in recipe_list if r.id == recipe_id), None)
        if recipe is None:
            return {"message": "recipe not found"}, HTTPStatus.NOT_FOUND
        recipe.is_publish = True
        return {}, HTTPStatus.NO_CONTENT

    def delete(self, recipe_id):
        recipe = next((r for r in recipe_list if r.id == recipe_id), None)
        if recipe is None:
            return {"message": "recipe not found"}, HTTPStatus.NOT_FOUND
        recipe.is_publish = False
        return {}, HTTPStatus.NO_CONTENT',
    demo = 'def show(label, result):
    body, status = result
    print(f"  {label}")
    print(f"    {status.value} {status.phrase}")
    if body:
        print(f"    {json.dumps(body, indent=4)}")
    print()

list_res    = RecipeListResource()
recipe_res  = RecipeResource()
publish_res = RecipePublishResource()

print("=== Flask-RESTful Resource Demo ===\n")

# POST: create recipes
show("POST /recipes (Egg Salad)",
    list_res.post({"name":"Egg Salad","description":"Lovely.","num_of_servings":2,"cook_time":10,"directions":"Boil, mix."}))
show("POST /recipes (Tomato Pasta)",
    list_res.post({"name":"Tomato Pasta","description":"Yum.","num_of_servings":4,"cook_time":20,"directions":"Cook, sauce."}))

# GET all (none published yet)
show("GET /recipes (before publish)", list_res.get())

# Publish recipe #1
show("PUT /recipes/1/publish",   publish_res.put(1))
show("GET /recipes (after publish)", list_res.get())

# GET one
show("GET /recipes/1",           recipe_res.get(1))
show("GET /recipes/99 (missing)", recipe_res.get(99))'
  ),

  list(
    name = "flask_restful_app.py",
    description = "<strong>flask_restful_app.py</strong> — Exercise 10: the main <code>app.py</code> factory showing how <code>Flask-RESTful</code>'s <code>Api</code> object wires Resources to URLs. Demonstrates the clean separation between <code>app.py</code>, <code>models/</code>, and <code>resources/</code>.",
    code = '# Exercise 10: Creating the Main Application File
# Source: Lesson02/Exercise10/app.py
# Shows Flask-RESTful Api registration pattern

# Real Flask-RESTful app.py would be:
#
# from flask import Flask
# from flask_restful import Api
# from resources.recipe import RecipeListResource, RecipeResource, RecipePublishResource
#
# app = Flask(__name__)
# api = Api(app)
#
# api.add_resource(RecipeListResource,    "/recipes")
# api.add_resource(RecipeResource,        "/recipes/<int:recipe_id>")
# api.add_resource(RecipePublishResource, "/recipes/<int:recipe_id>/publish")
#
# if __name__ == "__main__":
#     app.run(port=5000, debug=True)

# ── Simulate URL routing table ────────────────────────────────

routes = [
    ("RecipeListResource",    "/recipes",                         ["GET", "POST"]),
    ("RecipeResource",        "/recipes/<int:recipe_id>",         ["GET", "PUT", "DELETE"]),
    ("RecipePublishResource", "/recipes/<int:recipe_id>/publish", ["PUT", "DELETE"]),
]

print("=== Flask-RESTful Route Table ===\n")
print("  %-30s %-40s %s" % ("Resource", "URL", "Methods"))
print("  " + "-" * 85)
for resource, url, methods in routes:
    print(f"  {resource:<30} {url:<40} {', '.join(methods)}")

print()
print("=== Project Structure ===")
structure = """
  smilecook/
  \u251c\u2500\u2500 app.py                  <- Flask app + Api registration
  \u251c\u2500\u2500 models/
  \u2502   \u251c\u2500\u2500 __init__.py
  \u2502   \u2514\u2500\u2500 recipe.py           <- Recipe class + in-memory store
  \u2514\u2500\u2500 resources/
      \u251c\u2500\u2500 __init__.py
      \u2514\u2500\u2500 recipe.py           <- RecipeListResource, RecipeResource, RecipePublishResource
"""
print(structure)

print("=== Flask-RESTful: Method -> Handler Mapping ===")
mapping = {
    "GET    /recipes":                  "RecipeListResource.get()",
    "POST   /recipes":                  "RecipeListResource.post()",
    "GET    /recipes/<id>":             "RecipeResource.get(recipe_id)",
    "PUT    /recipes/<id>":             "RecipeResource.put(recipe_id)",
    "DELETE /recipes/<id>":             "RecipeResource.delete(recipe_id)",
    "PUT    /recipes/<id>/publish":     "RecipePublishResource.put(recipe_id)",
    "DELETE /recipes/<id>/publish":     "RecipePublishResource.delete(recipe_id)",
}
for request, handler in mapping.items():
    print(f"  {request:<35} -> {handler}")',
    demo = NULL
  ),

  list(
    name = "publish_unpublish.py",
    description = "<strong>publish_unpublish.py</strong> — Exercise 9: Implements the publish/unpublish workflow. Demonstrates how a sub-resource (<code>/publish</code>) models a state transition, why PUT is used for publishing (idempotent state change), and how 204 No Content is the correct response.",
    code = '# Exercise 9: Publishing and Unpublishing Recipes
# Source: Lesson02/Exercise09/resources/recipe.py (publish section)
import json
from http import HTTPStatus

recipe_store = {}
next_id = [1]

def create_recipe(name, description):
    rid = next_id[0]; next_id[0] += 1
    recipe_store[rid] = {
        "id": rid, "name": name,
        "description": description, "is_publish": False
    }
    return recipe_store[rid], HTTPStatus.CREATED

def publish_recipe(recipe_id):
    if recipe_id not in recipe_store:
        return {"message": "recipe not found"}, HTTPStatus.NOT_FOUND
    recipe_store[recipe_id]["is_publish"] = True
    return {}, HTTPStatus.NO_CONTENT   # 204 — success, nothing to return

def unpublish_recipe(recipe_id):
    if recipe_id not in recipe_store:
        return {"message": "recipe not found"}, HTTPStatus.NOT_FOUND
    recipe_store[recipe_id]["is_publish"] = False
    return {}, HTTPStatus.NO_CONTENT

def get_published():
    data = [r for r in recipe_store.values() if r["is_publish"]]
    return {"data": data}, HTTPStatus.OK

def show(label, result):
    body, status = result
    print(f"  {label}")
    print(f"    Status : {status.value} {status.phrase}")
    if body:
        print(f"    Body   : {json.dumps(body, indent=4)}")
    print()

print("=== Publish / Unpublish Workflow Demo ===\n")
show("POST /recipes (Egg Salad)",    create_recipe("Egg Salad",    "Lovely salad."))
show("POST /recipes (Tomato Pasta)", create_recipe("Tomato Pasta", "Lovely pasta."))
show("GET  /recipes (none published)", get_published())
show("PUT  /recipes/1/publish",  publish_recipe(1))
show("GET  /recipes (one published)", get_published())
show("PUT  /recipes/1/publish (idempotent: same result)", publish_recipe(1))
show("DELETE /recipes/1/publish (unpublish)", unpublish_recipe(1))
show("GET  /recipes (back to zero)", get_published())
show("PUT  /recipes/99/publish (not found)", publish_recipe(99))',
    demo = NULL
  )
)

# ── Chapter 2 UI ──────────────────────────────────────────────
chapter2_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(2, "\U0001f527", "Starting to Build Our Project",
      "Build the Smilecook recipe-sharing platform using Flask-RESTful. Learn domain modelling, resourceful routing, the Resource class pattern, and how to separate models from resources in a real project structure.",
      c("Flask-RESTful", "Resource Class", "Route Registration", "Recipe Model", "Publish Workflow", "Project Structure")),

    stats_row(
      list("3",         "Resources"),
      list("7",         "Endpoints"),
      list("Resource",  "Base Class"),
      list("204",       "No Content")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),

        # ── THEORY TAB ─────────────────────────────────────────
        tabPanel(title = tagList(icon("book"), " Theory"),

          fluidRow(
            box(title = "\U0001f527 What is Flask-RESTful?", status = "info", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                tags$h5("Flask-RESTful Extension"),
                tags$p("Flask-RESTful is a Flask extension that adds support for quickly building REST APIs. It provides the ", tags$code("Resource"), " base class, which maps HTTP methods directly to Python methods."),
                tags$ul(
                  tags$li(tags$strong("Resource class"), " — Inherit from it; define ", tags$code("get()"), ", ", tags$code("post()"), ", ", tags$code("put()"), ", ", tags$code("delete()")),
                  tags$li(tags$strong("Api object"), " — Registers resources to URL routes with ", tags$code("add_resource()")),
                  tags$li(tags$strong("Automatic JSON"), " — Returning a dict from a method automatically serialises it to JSON"),
                  tags$li(tags$strong("Status codes"), " — Return a tuple ", tags$code("(data, status_code)"), " from any method")
                )
              ),
              div(class = "framework-card",
                tags$h5("Installation"),
                tags$pre(class = "code-inline",
"pip install flask-restful

# In app.py:
from flask_restful import Api, Resource
api = Api(app)
api.add_resource(MyResource, '/path')")
              )
            ),

            box(title = "\U0001f4e6 The Resource Class Pattern", status = "warning", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                tags$h5("HTTP Method -> Class Method"),
                tags$p("In Flask-RESTful, each HTTP method maps to a Python method of the same name on the Resource subclass:"),
                tags$pre(class = "code-inline",
"class RecipeListResource(Resource):
    def get(self):            # GET /recipes
        ...
    def post(self):           # POST /recipes
        ...

class RecipeResource(Resource):
    def get(self, recipe_id): # GET /recipes/<id>
        ...
    def put(self, recipe_id): # PUT /recipes/<id>
        ...
    def delete(self, recipe_id): # DELETE /recipes/<id>
        ...")
              ),
              div(class = "tip-box",
                HTML("<strong>\U0001f4a1 Design pattern:</strong> <em>Collection resource</em> (<code>/recipes</code>) handles list + create. <em>Item resource</em> (<code>/recipes/&lt;id&gt;</code>) handles get-one, update, delete."))
            )
          ),

          fluidRow(
            box(title = "\U0001f3d7\ufe0f Project Architecture: Smilecook", status = "success", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                tags$h5("Separation of Concerns"),
                tags$pre(class = "code-inline",
"smilecook/
\u251c\u2500\u2500 app.py          <- App factory + API registration
\u251c\u2500\u2500 models/
\u2502   \u2514\u2500\u2500 recipe.py   <- Domain model + in-memory store
\u2514\u2500\u2500 resources/
    \u2514\u2500\u2500 recipe.py   <- HTTP handler classes"),
                tags$ul(
                  tags$li(tags$strong("Models"), " — Pure business logic; no HTTP concerns"),
                  tags$li(tags$strong("Resources"), " — HTTP handling only; delegate logic to models"),
                  tags$li(tags$strong("app.py"), " — Wires everything together")
                )
              ),
              div(class = "success-box",
                HTML("<strong>\u2705 Single Responsibility:</strong> Models know nothing about HTTP. Resources know nothing about data storage. This makes each layer independently testable."))
            ),

            box(title = "\U0001f4cb Smilecook Recipe API Endpoints", status = "danger", solidHeader = TRUE, width = 6,
              tags$table(class = "algo-table",
                tags$thead(tags$tr(tags$th("Method"), tags$th("URL"), tags$th("Resource"), tags$th("Action"))),
                tags$tbody(
                  tags$tr(tags$td(tags$code("GET")),    tags$td("/recipes"),                   tags$td("RecipeListResource"),    tags$td("Get all published")),
                  tags$tr(tags$td(tags$code("POST")),   tags$td("/recipes"),                   tags$td("RecipeListResource"),    tags$td("Create recipe")),
                  tags$tr(tags$td(tags$code("GET")),    tags$td("/recipes/{id}"),               tags$td("RecipeResource"),        tags$td("Get one recipe")),
                  tags$tr(tags$td(tags$code("PUT")),    tags$td("/recipes/{id}"),               tags$td("RecipeResource"),        tags$td("Update recipe")),
                  tags$tr(tags$td(tags$code("DELETE")), tags$td("/recipes/{id}"),               tags$td("RecipeResource"),        tags$td("Delete recipe")),
                  tags$tr(tags$td(tags$code("PUT")),    tags$td("/recipes/{id}/publish"),       tags$td("RecipePublishResource"), tags$td("Publish recipe")),
                  tags$tr(tags$td(tags$code("DELETE")), tags$td("/recipes/{id}/publish"),       tags$td("RecipePublishResource"), tags$td("Unpublish recipe"))
                )
              ),
              div(class = "tip-box",
                HTML("<strong>\U0001f4a1 Sub-resource pattern:</strong> <code>/publish</code> models a <em>state transition</em> on the recipe — a clean RESTful way to avoid verb-based URLs like <code>POST /recipes/1/do-publish</code>."))
            )
          ),

          fluidRow(
            box(title = "\U0001f501 The Recipe Model Deep Dive", status = "primary", solidHeader = TRUE, width = 12,
              fluidRow(
                column(6,
                  div(class = "framework-card",
                    tags$h5("Auto-incrementing IDs"),
                    tags$p("The in-memory store uses a global list and a ", tags$code("get_last_id()"), " helper to simulate database auto-increment:"),
                    tags$pre(class = "code-inline",
"recipe_list = []

def get_last_id():
    if recipe_list:
        return recipe_list[-1].id + 1
    return 1")
                  ),
                  div(class = "framework-card",
                    tags$h5("The data property"),
                    tags$p("The ", tags$code("@property"), " decorator exposes recipe fields as a dict, which Flask-RESTful can automatically serialise to JSON:"),
                    tags$pre(class = "code-inline",
"@property
def data(self):
    return {
        'id':              self.id,
        'name':            self.name,
        'num_of_servings': self.num_of_servings,
        'cook_time':       self.cook_time,
    }")
                  )
                ),
                column(6,
                  div(class = "framework-card",
                    tags$h5("is_publish flag"),
                    tags$p("Recipes are created unpublished by default. Only published recipes are returned in the public listing endpoint. This models a draft/published workflow."),
                    tags$pre(class = "code-inline",
"class RecipeListResource(Resource):
    def get(self):
        data = [r.data for r in recipe_list
                if r.is_publish is True]
        return {'data': data}, 200")
                  ),
                  div(class = "info-box-plain",
                    HTML("<strong>\u2139 Why 204 No Content?</strong><br>When publishing or unpublishing, there is no meaningful body to return — the action is a state change. HTTP 204 communicates success without a response body, which is correct RESTful design."))
                )
              )
            )
          )
        ),

        # ── CODE LAB TAB ───────────────────────────────────────
        tabPanel(title = tagList(icon("code"), " Code Lab"),
          code_lab_header(
            "Chapter 2 \u2014 Starting to Build Our Project",
            "Recipe domain model, Flask-RESTful Resource pattern, URL registration, publish/unpublish workflow."
          ),
          file_pills_ui(ns, CH02_FILES),
          py_code_display(ns),
          terminal_ui(ns)
        )
      )
    )
  )
}

chapter2_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    code_lab_server(input, output, session, CH02_FILES)
  })
}
