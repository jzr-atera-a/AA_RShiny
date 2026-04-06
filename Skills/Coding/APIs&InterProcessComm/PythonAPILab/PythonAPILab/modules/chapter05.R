# modules/chapter05.R
# Chapter 5: Object Serialization with marshmallow

CH05_FILES <- list(

  list(
    name = "marshmallow_basics.py",
    description = "<strong>marshmallow_basics.py</strong> — Introduces marshmallow's core concepts: Schema definition, dump (serialisation), load (deserialisation), and field-level validation. Mirrors the Chapter 5 theory section.",
    code = '# Chapter 5: marshmallow — Serialisation vs Deserialisation
# marshmallow is a library for converting complex objects to/from Python dicts

# We simulate marshmallow behaviour here with pure Python
# (marshmallow requires pip install marshmallow)

import json
from datetime import datetime

print("=== Serialisation vs Deserialisation ===\n")
print("  Serialisation   : Python object  ->  dict/JSON  (dump)")
print("  Deserialisation : dict/JSON      ->  Python object (load)\n")

# ── A simple schema simulation ────────────────────────────────
class FieldError(Exception): pass

class StringField:
    def __init__(self, required=False, max_len=None, dump_only=False, load_only=False):
        self.required = required; self.max_len = max_len
        self.dump_only = dump_only; self.load_only = load_only

    def validate(self, value):
        if value is None and self.required:
            raise FieldError("Field is required.")
        if value and self.max_len and len(value) > self.max_len:
            raise FieldError(f"Must be at most {self.max_len} characters.")
        return value

class IntField:
    def __init__(self, dump_only=False, min_val=None, max_val=None):
        self.dump_only = dump_only; self.min_val = min_val; self.max_val = max_val

    def validate(self, value):
        if value is not None:
            if self.min_val is not None and value < self.min_val:
                raise FieldError(f"Must be >= {self.min_val}.")
            if self.max_val is not None and value > self.max_val:
                raise FieldError(f"Must be <= {self.max_val}.")
        return value

class SimpleSchema:
    """Minimal marshmallow-like schema."""

    def dump(self, obj):
        """Serialise: object -> dict (skips load_only fields)."""
        result = {}
        for name, field in self._fields().items():
            if getattr(field, "load_only", False): continue
            val = getattr(obj, name, None)
            if isinstance(val, datetime): val = val.isoformat()
            result[name] = val
        return result

    def load(self, data):
        """Deserialise + validate: dict -> validated dict."""
        result = {}; errors = {}
        for name, field in self._fields().items():
            if getattr(field, "dump_only", False): continue
            val = data.get(name)
            try:
                result[name] = field.validate(val)
            except FieldError as e:
                errors[name] = [str(e)]
        return result, errors

    def _fields(self):
        return {k: v for k, v in self.__class__.__dict__.items()
                if isinstance(v, (StringField, IntField))}

# ── RecipeSchema ──────────────────────────────────────────────
class RecipeSchema(SimpleSchema):
    id          = IntField(dump_only=True)
    name        = StringField(required=True, max_len=100)
    description = StringField(max_len=200)
    num_of_servings = IntField(min_val=1, max_val=50)
    cook_time   = IntField(min_val=1, max_val=300)
    directions  = StringField(max_len=1000)

recipe_schema = RecipeSchema()

# ── Mock Recipe object ────────────────────────────────────────
class Recipe:
    def __init__(self, **kw):
        for k, v in kw.items(): setattr(self, k, v)

# DUMP — serialise a Recipe object
print("=== dump() — Serialisation ===\n")
r = Recipe(id=1, name="Egg Salad", description="Lovely salad.",
           num_of_servings=2, cook_time=10, directions="Boil, mix.", password="hidden")
dumped = recipe_schema.dump(r)
print(f"  recipe_schema.dump(recipe) ->")
print(json.dumps(dumped, indent=4))

# LOAD with validation pass
print("\n=== load() — Deserialisation + Validation (valid data) ===\n")
valid_data = {"name": "Tomato Pasta", "description": "Great pasta.", "num_of_servings": 4, "cook_time": 20}
result, errors = recipe_schema.load(valid_data)
print(f"  data   : {result}")
print(f"  errors : {errors}  <- empty means no errors \u2705")

# LOAD with validation fail
print("\n=== load() — Deserialisation + Validation (invalid data) ===\n")
bad_data = {"name": "", "num_of_servings": 999, "cook_time": 0}
result2, errors2 = recipe_schema.load(bad_data)
print(f"  data   : {result2}")
print(f"  errors : {errors2}  <- validation caught the problems \u274c")',
    demo = NULL
  ),

  list(
    name = "user_schema.py",
    description = "<strong>user_schema.py</strong> — Exercise 33: the <code>UserSchema</code> with <code>dump_only</code>, <code>load_only</code>, email validation, and a custom <code>load_password</code> method that hashes the password during deserialisation. Shows how marshmallow replaces manual validation.",
    code = '# Exercise 33: UserSchema with marshmallow
# Source: Lesson05/Exercise33/schemas/user.py
import json, re, hashlib

# ── Field types ───────────────────────────────────────────────
class ValidationError(Exception): pass

class Field:
    def __init__(self, required=False, dump_only=False, load_only=False):
        self.required = required; self.dump_only = dump_only; self.load_only = load_only
    def _validate(self, value): return value

class Int(Field):
    def _validate(self, v): return v

class Str(Field):
    def __init__(self, required=False, **kw):
        super().__init__(required=required, **kw)
    def _validate(self, v):
        if v is None and self.required: raise ValidationError("Field is required.")
        return v

class Email(Field):
    def __init__(self, required=False, **kw):
        super().__init__(required=required, **kw)
    def _validate(self, v):
        if v and not re.match("[^@]+@[^@]+[.][^@]+", v):
            raise ValidationError("Not a valid email address.")
        return v

class Method(Field):
    """Calls a method on the schema during load."""
    def __init__(self, required=False, deserialize=None, **kw):
        super().__init__(required=required, **kw)
        self.deserialize = deserialize

# ── Base Schema ───────────────────────────────────────────────
class Schema:
    class Meta:
        ordered = True

    def _fields(self):
        return {k: v for k, v in self.__class__.__dict__.items()
                if isinstance(v, Field)}

    def dump(self, obj):
        result = {}
        for name, field in self._fields().items():
            if field.load_only: continue
            result[name] = getattr(obj, name, None)
        return result

    def load(self, data):
        result = {}; errors = {}
        for name, field in self._fields().items():
            if field.dump_only: continue
            val = data.get(name)
            try:
                if isinstance(field, Method) and field.deserialize:
                    if val is None and field.required:
                        raise ValidationError("Field is required.")
                    if val is not None:
                        method = getattr(self, field.deserialize)
                        val = method(val)
                else:
                    val = field._validate(val)
                result[name] = val
            except ValidationError as e:
                errors[name] = [str(e)]
        return result, errors

# ── UserSchema (mirrors Exercise 33) ─────────────────────────
def hash_password(pw):
    return hashlib.sha256(pw.encode()).hexdigest()[:20] + "...(hashed)"

class UserSchema(Schema):
    id         = Int(dump_only=True)
    username   = Str(required=True)
    email      = Email(required=True)
    password   = Method(required=True, deserialize="load_password", load_only=True)
    created_at = Str(dump_only=True)
    updated_at = Str(dump_only=True)

    def load_password(self, value):
        return hash_password(value)

user_schema = UserSchema()

# ── Mock User ─────────────────────────────────────────────────
class User:
    def __init__(self, **kw):
        for k, v in kw.items(): setattr(self, k, v)',
    demo = 'print("=== UserSchema Demo (Exercise 33) ===\n")

# LOAD — registration request
print("  Registration payload (deserialise + validate):\n")
reg_data = {"username": "alice", "email": "alice@example.com", "password": "secret123"}
result, errors = user_schema.load(reg_data)
print(f"    Input  : {reg_data}")
print(f"    Result : {result}")
print(f"    Errors : {errors or \'none \\u2705\'}\n")

# DUMP — response
u = User(id=1, username="alice", email="alice@example.com",
         password="hashed...", created_at="2024-01-01", updated_at="2024-01-01")
dumped = user_schema.dump(u)
print(f"  dump(user) -> {json.dumps(dumped, indent=4)}")
print("    Note: password is NOT in the output (load_only=True) \u2705\n")

# LOAD — validation failures
bad = {"username": "", "email": "not-an-email", "password": "x"}
result2, errors2 = user_schema.load(bad)
print(f"  Invalid payload errors:")
for field, msgs in errors2.items():
    print(f"    {field}: {msgs}")'
  ),

  list(
    name = "recipe_schema.py",
    description = "<strong>recipe_schema.py</strong> — Exercise 35: <code>RecipeSchema</code> with nested <code>UserSchema</code> (author field), custom validators (<code>@validates</code>), <code>@post_dump</code> wrapping, and <code>dump_only</code>/<code>required</code> fields. The complete schema used in production Smilecook.",
    code = '# Exercise 35: RecipeSchema with nested schemas + custom validators
# Source: Lesson05/Exercise35/schemas/recipe.py
import json

class ValidationError(Exception): pass

# ── Simulated marshmallow field types ────────────────────────
class Field:
    def __init__(self, required=False, dump_only=False, **kw):
        self.required = required; self.dump_only = dump_only

class Integer(Field):
    def __init__(self, required=False, dump_only=False, validators=None):
        super().__init__(required, dump_only); self.validators = validators or []
    def validate(self, v):
        for fn in self.validators: fn(v)
        return v

class Str(Field):
    def __init__(self, required=False, dump_only=False, max_len=None):
        super().__init__(required, dump_only); self.max_len = max_len
    def validate(self, v):
        if v and self.max_len and len(v) > self.max_len:
            raise ValidationError(f"Longer than {self.max_len} chars.")
        return v

class Bool(Field): pass
class DateTime(Field): pass
class Nested(Field):
    def __init__(self, schema, attribute=None, dump_only=False, only=None):
        super().__init__(dump_only=dump_only)
        self.schema = schema; self.attribute = attribute; self.only = only

# ── Custom validator functions ────────────────────────────────
def validate_num_of_servings(n):
    if n is not None:
        if n < 1:  raise ValidationError("Number of servings must be greater than 0.")
        if n > 50: raise ValidationError("Number of servings must not be greater than 50.")

def validate_cook_time(n):
    if n is not None:
        if n < 1:   raise ValidationError("Cook time must be greater than 0.")
        if n > 300: raise ValidationError("Cook time must not be greater than 300.")

# ── UserSchema (simplified, for nesting) ─────────────────────
class UserSchema:
    def dump(self, obj, only=None):
        d = {"id": getattr(obj,"id",None), "username": getattr(obj,"username",None)}
        if only: d = {k: v for k, v in d.items() if k in only}
        return d

user_schema = UserSchema()

# ── RecipeSchema ──────────────────────────────────────────────
class RecipeSchema:
    def dump(self, obj, many=False):
        def _dump_one(r):
            out = {
                "id":              getattr(r, "id",              None),
                "name":            getattr(r, "name",            None),
                "description":     getattr(r, "description",     None),
                "num_of_servings": getattr(r, "num_of_servings", None),
                "cook_time":       getattr(r, "cook_time",       None),
                "directions":      getattr(r, "directions",      None),
                "is_publish":      getattr(r, "is_publish",      False),
                "author":          user_schema.dump(r.user, only=["id","username"]) if getattr(r,"user",None) else None,
                "created_at":      str(getattr(r, "created_at",  "")),
                "updated_at":      str(getattr(r, "updated_at",  "")),
            }
            return out  # @post_dump would wrap if many=True
        if many:
            return {"data": [_dump_one(r) for r in obj]}
        return _dump_one(obj)

    def load(self, data):
        errors = {}
        result = {}
        # name
        name = data.get("name")
        if not name: errors["name"] = ["Field is required."]
        elif len(name) > 100: errors["name"] = ["Longer than 100 chars."]
        else: result["name"] = name
        # description
        desc = data.get("description")
        if desc and len(desc) > 200: errors["description"] = ["Longer than 200 chars."]
        else: result["description"] = desc
        # num_of_servings
        nos = data.get("num_of_servings")
        try:
            if nos is not None: validate_num_of_servings(nos)
            result["num_of_servings"] = nos
        except ValidationError as e: errors["num_of_servings"] = [str(e)]
        # cook_time
        ct = data.get("cook_time")
        try:
            if ct is not None: validate_cook_time(ct)
            result["cook_time"] = ct
        except ValidationError as e: errors["cook_time"] = [str(e)]
        return result, errors

recipe_schema      = RecipeSchema()
recipe_list_schema = RecipeSchema()

# ── Mock objects ──────────────────────────────────────────────
class User:
    def __init__(self, id, username): self.id = id; self.username = username

class Recipe:
    def __init__(self, **kw):
        for k, v in kw.items(): setattr(self, k, v)',
    demo = 'print("=== RecipeSchema Demo (Exercise 35) ===\n")

alice = User(1, "alice")
r1 = Recipe(id=1, name="Egg Salad", description="Lovely.", num_of_servings=2,
            cook_time=10, directions="Boil, mix.", is_publish=True,
            user=alice, created_at="2024-01-01", updated_at="2024-01-01")
r2 = Recipe(id=2, name="Tomato Pasta", description="Great.", num_of_servings=4,
            cook_time=20, directions="Cook pasta.", is_publish=False,
            user=alice, created_at="2024-01-02", updated_at="2024-01-02")

# Single dump
print("  recipe_schema.dump(r1):")
print(json.dumps(recipe_schema.dump(r1), indent=4))

# Many dump with @post_dump wrapping
print("\n  recipe_list_schema.dump([r1, r2], many=True):")
print(json.dumps(recipe_list_schema.dump([r1, r2], many=True), indent=4))

# Validation success
print("\n  load() valid data:")
d, e = recipe_schema.load({"name":"Caesar","description":"Fresh.","num_of_servings":2,"cook_time":5})
print(f"    result: {d},  errors: {e or \"none \\u2705\"}")

# Validation failures
print("\n  load() invalid data:")
d2, e2 = recipe_schema.load({"name":"", "num_of_servings":99, "cook_time":400})
print(f"    errors: {e2}")'
  ),

  list(
    name = "patch_method.py",
    description = "<strong>patch_method.py</strong> — Exercise 37: the PATCH method for partial updates. Demonstrates how marshmallow's <code>partial=('name',)</code> argument allows optional fields, and how <code>data.get('field') or recipe.field</code> safely merges only provided values.",
    code = '# Exercise 37: PATCH — Partial Updates with marshmallow
# Source: Lesson05/Exercise37/smilecook/resources/recipe.py
import json
from http import HTTPStatus

# ── Simulated recipe store ────────────────────────────────────
class Recipe:
    def __init__(self, id, name, description, num_of_servings, cook_time, directions, user_id):
        self.id = id; self.name = name; self.description = description
        self.num_of_servings = num_of_servings; self.cook_time = cook_time
        self.directions = directions; self.user_id = user_id

    def data(self):
        return {k: v for k, v in self.__dict__.items()}

db = {
    1: Recipe(1, "Egg Salad", "Lovely.", 2, 10, "Boil, mix.", user_id=1),
    2: Recipe(2, "Pasta",     "Great.",  4, 20, "Cook.",      user_id=1),
}

# ── PATCH handler — mirrors Exercise 37 ──────────────────────
def patch_recipe(recipe_id, patch_data, current_user_id):
    """
    PATCH is partial update — only provided fields are changed.
    marshmallow schema.load(data, partial=(\'name\',)) allows name to be omitted.
    """
    recipe = db.get(recipe_id)
    if recipe is None:
        return {"message": "Recipe not found"}, HTTPStatus.NOT_FOUND
    if current_user_id != recipe.user_id:
        return {"message": "Access is not allowed"}, HTTPStatus.FORBIDDEN

    # Apply only provided fields (partial update)
    recipe.name            = patch_data.get("name")            or recipe.name
    recipe.description     = patch_data.get("description")     or recipe.description
    recipe.num_of_servings = patch_data.get("num_of_servings") or recipe.num_of_servings
    recipe.cook_time       = patch_data.get("cook_time")       or recipe.cook_time
    recipe.directions      = patch_data.get("directions")      or recipe.directions

    return recipe.data(), HTTPStatus.OK

def show(label, result):
    body, status = result
    print(f"  {label}")
    print(f"    {status.value} {status.phrase}")
    print(f"    {json.dumps(body, indent=6)}\n")

print("=== PUT vs PATCH ===\n")
print("  PUT   — replace the ENTIRE resource; all fields required")
print("  PATCH — partial update; only provided fields change\n")

print("  Recipe #1 before PATCH:")
print(f"    {json.dumps(db[1].data(), indent=6)}\n")

# PATCH only the description
show("PATCH /recipes/1 — change only description",
     patch_recipe(1, {"description": "Updated: now with extra mayo."}, current_user_id=1))

# PATCH only cook_time
show("PATCH /recipes/1 — change only cook_time",
     patch_recipe(1, {"cook_time": 15}, current_user_id=1))

# PATCH by wrong user
show("PATCH /recipes/1 — wrong user (403)",
     patch_recipe(1, {"name": "Hacked!"}, current_user_id=2))

print("  marshmallow partial= usage:")
print(\'  data, errors = recipe_schema.load(json_data, partial=("name",))\')
print("  # name is no longer required — all other validators still run")',
    demo = NULL
  ),

  list(
    name = "webargs_filtering.py",
    description = "<strong>webargs_filtering.py</strong> — Exercise 38-39: using <code>webargs</code> to parse query-string arguments for filtering recipes by author, and controlling visibility (public vs private vs all). Demonstrates <code>@use_kwargs</code> and <code>fields.Str(missing='public')</code>.",
    code = '# Exercises 38-39: webargs — Query String Argument Parsing
# Source: Lesson05/Activity08/smilecook/resources/user.py
import json
from http import HTTPStatus

# ── Simulated user + recipe data ──────────────────────────────
users = {
    "alice": {"id": 1, "username": "alice", "email": "alice@example.com"},
    "bob":   {"id": 2, "username": "bob",   "email": "bob@example.com"},
}
recipes = [
    {"id": 1, "name": "Egg Salad",    "user_id": 1, "is_publish": True},
    {"id": 2, "name": "Tomato Pasta", "user_id": 1, "is_publish": False},
    {"id": 3, "name": "Burger",       "user_id": 2, "is_publish": True},
    {"id": 4, "name": "Secret Soup",  "user_id": 2, "is_publish": False},
]

# ── UserRecipeListResource.get() — mirrors Exercise 39 ────────
def get_user_recipes(username, visibility="public", current_user_id=None):
    """
    GET /users/<username>/recipes?visibility=public|private|all

    visibility defaults to "public" via webargs:
        @use_kwargs({"visibility": fields.Str(missing="public")})
    """
    user = users.get(username)
    if user is None:
        return {"message": "User not found"}, HTTPStatus.NOT_FOUND

    # Enforce: only owner sees private/all
    if current_user_id == user["id"] and visibility in ["all", "private"]:
        pass
    else:
        visibility = "public"

    if visibility == "public":
        result = [r for r in recipes if r["user_id"] == user["id"] and r["is_publish"]]
    elif visibility == "private":
        result = [r for r in recipes if r["user_id"] == user["id"] and not r["is_publish"]]
    else:  # all
        result = [r for r in recipes if r["user_id"] == user["id"]]

    return {"data": result, "visibility_used": visibility}, HTTPStatus.OK

def show(label, result):
    body, status = result
    print(f"  {label}")
    print(f"    {status.value} — {json.dumps(body, indent=6)}\n")

print("=== webargs: Query String Filtering ===\n")
print("  Endpoint: GET /users/<username>/recipes?visibility=public|private|all\n")

print("  [ Unauthenticated visitor ]")
show("GET /users/alice/recipes (default public)", get_user_recipes("alice"))
show("GET /users/alice/recipes?visibility=private (overridden to public)",
     get_user_recipes("alice", visibility="private", current_user_id=None))

print("  [ Authenticated as alice (id=1) ]")
show("GET /users/alice/recipes?visibility=all",
     get_user_recipes("alice", visibility="all", current_user_id=1))
show("GET /users/alice/recipes?visibility=private",
     get_user_recipes("alice", visibility="private", current_user_id=1))

print("  [ alice trying to see bob\'s private recipes ]")
show("GET /users/bob/recipes?visibility=private (overridden to public)",
     get_user_recipes("bob", visibility="private", current_user_id=1))',
    demo = NULL
  )
)

# ── Chapter 5 UI ──────────────────────────────────────────────
chapter5_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(5, "\U0001f4cb", "Object Serialization with marshmallow",
      "Replace manual dict-building with marshmallow schemas. Handle serialisation, deserialisation, field-level validation, nested schemas, partial PATCH updates, and query string filtering with webargs.",
      c("marshmallow", "Schema", "dump", "load", "Validation", "Nested", "PATCH", "webargs", "@post_dump")),

    stats_row(
      list("dump()",  "Serialise"),
      list("load()",  "Deserialise + Validate"),
      list("PATCH",   "Partial Update"),
      list("@post_dump", "Transform Output")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),

        tabPanel(title = tagList(icon("book"), " Theory"),

          fluidRow(
            box(title = "\U0001f4cb marshmallow — What & Why", status = "info", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                tags$h5("What is marshmallow?"),
                tags$p("marshmallow is a Python library for object serialisation/deserialisation and validation. It replaces the manual dict-building and validation logic scattered throughout your resource handlers."),
                tags$ul(
                  tags$li(tags$strong("Schema"), " — defines the shape and rules of your data"),
                  tags$li(tags$strong("dump()"), " — object/model → dict/JSON (for API responses)"),
                  tags$li(tags$strong("load()"), " — dict/JSON → validated data dict (for incoming requests)")
                )
              ),
              div(class = "framework-card",
                tags$h5("Before marshmallow (Chapter 2 style)"),
                tags$pre(class = "code-inline",
"# Manual — repetitive, no validation
return {
    'id':   recipe.id,
    'name': recipe.name,
    ...
}, 200")
              ),
              div(class = "framework-card",
                tags$h5("After marshmallow (Chapter 5)"),
                tags$pre(class = "code-inline",
"# Schema handles everything
recipe_schema = RecipeSchema()
return recipe_schema.dump(recipe), 200")
              )
            ),

            box(title = "\U0001f9e9 Field Types & Modifiers", status = "warning", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                tags$h5("Common Field Types"),
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(tags$th("Field"), tags$th("Description"))),
                  tags$tbody(
                    tags$tr(tags$td(tags$code("fields.Integer()")), tags$td("Integer number")),
                    tags$tr(tags$td(tags$code("fields.String()")),  tags$td("String value")),
                    tags$tr(tags$td(tags$code("fields.Email()")),   tags$td("String that must be a valid email")),
                    tags$tr(tags$td(tags$code("fields.Boolean()")), tags$td("True/False")),
                    tags$tr(tags$td(tags$code("fields.DateTime()")),tags$td("ISO 8601 datetime")),
                    tags$tr(tags$td(tags$code("fields.Nested()")),  tags$td("Embed another schema (relationships)")),
                    tags$tr(tags$td(tags$code("fields.Method()")),  tags$td("Call a schema method on load/dump"))
                  )
                )
              ),
              div(class = "framework-card",
                tags$h5("Key Modifiers"),
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(tags$th("Modifier"), tags$th("Effect"))),
                  tags$tbody(
                    tags$tr(tags$td(tags$code("required=True")),   tags$td("ValidationError if missing on load")),
                    tags$tr(tags$td(tags$code("dump_only=True")),  tags$td("Ignored on load (e.g. id, created_at)")),
                    tags$tr(tags$td(tags$code("load_only=True")),  tags$td("Not included in dump output (e.g. password)")),
                    tags$tr(tags$td(tags$code("validate=[...]")),  tags$td("List of validator functions")),
                    tags$tr(tags$td(tags$code("attribute='user'")), tags$td("Use object attr name different from field name"))
                  )
                )
              )
            )
          ),

          fluidRow(
            box(title = "\U0001f517 Nested Schemas — The author Field", status = "success", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                tags$h5("Embedding a related object"),
                tags$p("Instead of returning just the user_id, marshmallow can embed the full (or partial) UserSchema inside RecipeSchema:"),
                tags$pre(class = "code-inline",
"class RecipeSchema(Schema):
    # ...
    author = fields.Nested(
        UserSchema,
        attribute='user',    # reads recipe.user (ORM backref)
        dump_only=True,
        only=['id', 'username']  # exclude email from nested
    )")
              ),
              div(class = "framework-card",
                tags$h5("@post_dump — Wrap the output"),
                tags$pre(class = "code-inline",
"@post_dump(pass_many=True)
def wrap(self, data, many, **kwargs):
    if many:
        return {'data': data}   # wrap list in {\"data\": [...]}
    return data                 # single object returned as-is")
              ),
              div(class = "tip-box",
                HTML("<strong>\U0001f4a1 only=</strong> lets you whitelist specific fields when nesting. Use it to avoid accidentally exposing sensitive data (like email) in nested contexts."))
            ),

            box(title = "\U00002702\ufe0f PUT vs PATCH + webargs", status = "danger", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                tags$h5("PUT vs PATCH"),
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(tags$th("Method"), tags$th("Behaviour"), tags$th("Fields required?"))),
                  tags$tbody(
                    tags$tr(tags$td(tags$code("PUT")),   tags$td("Replace entire resource"), tags$td("All fields")),
                    tags$tr(tags$td(tags$code("PATCH")), tags$td("Partial update"),          tags$td("Only changed fields"))
                  )
                ),
                tags$pre(class = "code-inline",
"# PATCH: marshmallow partial= makes name optional
data, errors = recipe_schema.load(
    json_data,
    partial=('name',)   # name not required for PATCH
)

# Only update provided fields:
recipe.name = data.get('name') or recipe.name")
              ),
              div(class = "framework-card",
                tags$h5("webargs — Query String Parsing"),
                tags$pre(class = "code-inline",
"from webargs import fields
from webargs.flaskparser import use_kwargs

class UserRecipeListResource(Resource):
    @jwt_optional
    @use_kwargs({'visibility': fields.Str(missing='public')})
    def get(self, username, visibility):
        # visibility is 'public' by default
        # ?visibility=private  or  ?visibility=all")
              )
            )
          )
        ),

        tabPanel(title = tagList(icon("code"), " Code Lab"),
          code_lab_header(
            "Chapter 5 \u2014 Object Serialization with marshmallow",
            "marshmallow basics, UserSchema, RecipeSchema with nested author, PATCH partial updates, and webargs query filtering."
          ),
          file_pills_ui(ns, CH05_FILES),
          py_code_display(ns),
          terminal_ui(ns)
        )
      )
    )
  )
}

chapter5_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    code_lab_server(input, output, session, CH05_FILES)
  })
}
