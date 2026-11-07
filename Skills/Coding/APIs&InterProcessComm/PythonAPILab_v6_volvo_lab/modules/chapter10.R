# modules/chapter10.R
# Chapter 10: Deployment

CH10_FILES <- list(

  list(
    name = "config_handling.py",
    description = "<strong>config_handling.py</strong> — Exercise 63-64: the three-environment config pattern: <code>DevelopmentConfig</code>, <code>StagingConfig</code>, and <code>ProductionConfig</code>. Shows how the app factory selects the right class via the <code>ENV</code> environment variable.",
    code = 'import os

print("=== Configuration Class Hierarchy ===\n")

# mirrors Lesson10/Exercise64/config.py exactly
config_code = """
import os

class Config:
    DEBUG                       = False
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    JWT_ERROR_MESSAGE_KEY       = "message"
    JWT_BLACKLIST_ENABLED       = True
    JWT_BLACKLIST_TOKEN_CHECKS  = ["access", "refresh"]
    UPLOADED_IMAGES_DEST        = "static/images"
    CACHE_TYPE                  = "simple"
    CACHE_DEFAULT_TIMEOUT       = 10 * 60
    RATELIMIT_HEADERS_ENABLED   = True


class DevelopmentConfig(Config):
    DEBUG                    = True
    SECRET_KEY               = "super-secret-key"
    SQLALCHEMY_DATABASE_URI  = "postgresql+psycopg2://user:pass@localhost:5432/smilecook"


class StagingConfig(Config):
    SECRET_KEY               = os.environ.get("SECRET_KEY")
    SQLALCHEMY_DATABASE_URI  = os.environ.get("DATABASE_URL")


class ProductionConfig(Config):
    SECRET_KEY               = os.environ.get("SECRET_KEY")
    SQLALCHEMY_DATABASE_URI  = os.environ.get("DATABASE_URL")
"""
print(config_code)

print("=== App factory: ENV-based config selection ===\n")
factory_code = """
# app.py (Exercise 68)
def create_app():
    env = os.environ.get("ENV", "Development")

    if env == "Production":
        config_str = "config.ProductionConfig"
    elif env == "Staging":
        config_str = "config.StagingConfig"
    else:
        config_str = "config.DevelopmentConfig"

    app = Flask(__name__)
    app.config.from_object(config_str)
    ...
"""
print(factory_code)

# Simulate the config selection
print("=== Config selection simulation ===\n")
for env_val in ["Development", "Staging", "Production", None]:
    env = env_val or "Development"
    if env == "Production":
        cfg = "config.ProductionConfig"
    elif env == "Staging":
        cfg = "config.StagingConfig"
    else:
        cfg = "config.DevelopmentConfig"
    label = f"ENV={env_val!r}" if env_val else "ENV not set (default)"
    print(f"  {label:<28} -> {cfg}")

print()
print("=== Key differences between environments ===\n")
rows = [
    ("DEBUG",           "True",           "False",          "False"),
    ("SECRET_KEY",      "hard-coded",      "from env var",   "from env var"),
    ("DATABASE_URL",    "local postgres",  "from env var",   "from env var"),
    ("CACHE_TYPE",      "simple",          "simple/Redis",   "Redis"),
]
print("  %-25s %-20s %-20s %s" % ("Setting", "Dev", "Staging", "Production"))
print("  " + "-" * 80)
for row in rows:
    print(f"  {row[0]:<25} {row[1]:<20} {row[2]:<20} {row[3]}")',
    demo = NULL
  ),

  list(
    name = "gunicorn_procfile.py",
    description = "<strong>gunicorn_procfile.py</strong> — Exercise 68: the <code>Procfile</code>, <code>main.py</code> entry point, and Gunicorn WSGI server. Explains why the Flask dev server cannot be used in production and how Heroku uses the Procfile to start the app.",
    code = 'print("=== Gunicorn: Production WSGI Server ===\n")

print("  Why not use Flask dev server in production?")
problems = [
    "Single-threaded -- can only handle 1 request at a time",
    "No process management -- crashes without restart",
    "Not hardened -- exposes debug info and reloader",
    "No load balancing -- cannot use multiple CPU cores",
]
for p in problems:
    print(f"    - {p}")

print()
print("  Gunicorn = Green Unicorn: production-grade WSGI server")
print("  - Multi-worker: runs N worker processes in parallel")
print("  - Process management: auto-restarts crashed workers")
print("  - Compatible with Heroku, AWS, GCP, and all PaaS platforms\n")

print("=== main.py -- Gunicorn entry point ===\n")
main_py = """
# main.py  (mirrors Exercise 68/smilecook/main.py)
from app import create_app

app = create_app()
# Gunicorn imports this module and calls app as the WSGI callable
"""
print(main_py)

print("=== Procfile ===\n")
print("  The Procfile tells Heroku how to start each process type.\n")
procfile = """
# Procfile  (no file extension -- lives in project root)
web: gunicorn main:app
"""
print(procfile)
print("  Breakdown:")
print("    web        -> Heroku process type (receives HTTP traffic)")
print("    gunicorn   -> the WSGI server command")
print("    main:app   -> module=main, variable=app (the Flask app)\n")

print("=== .gitignore essentials ===\n")
gitignore = """
# .gitignore
__pycache__/
*.pyc
.env               # NEVER commit secrets
venv/
instance/
static/images/     # uploaded user files
*.db               # local SQLite databases
"""
print(gitignore)

print("=== requirements.txt ===\n")
print("  Heroku reads requirements.txt to install dependencies.")
print("  Generate with:  pip freeze > requirements.txt\n")
reqs = [
    "Flask==1.1.2",
    "flask-restful==0.3.8",
    "flask-sqlalchemy==2.4.4",
    "flask-migrate==2.5.3",
    "flask-jwt-extended==3.24.1",
    "flask-uploads==0.2.1",
    "flask-caching==1.9.0",
    "flask-limiter==1.2.1",
    "marshmallow==2.21.0",
    "passlib==1.7.4",
    "itsdangerous==1.1.0",
    "gunicorn==20.0.4",
    "psycopg2-binary==2.8.6",
]
for r in reqs:
    print(f"  {r}")',
    demo = NULL
  ),

  list(
    name = "heroku_deployment.py",
    description = "<strong>heroku_deployment.py</strong> — Exercises 65-69: the complete Heroku deployment workflow. Covers app creation, Heroku Postgres add-on, setting config vars, Git setup, and the <code>git push heroku main</code> deploy command.",
    code = 'print("=== Heroku Deployment: Step-by-Step Workflow ===\n")

steps = [
    ("1", "Install Heroku CLI",
     "brew install heroku/brew/heroku  (macOS)\n"
     "        or: download from https://devcenter.heroku.com/articles/heroku-cli"),

    ("2", "Login to Heroku",
     "heroku login"),

    ("3", "Create Heroku app (Exercise 65)",
     "heroku create smilecook-api\n"
     "        # Creates: https://smilecook-api.herokuapp.com"),

    ("4", "Add Heroku Postgres (Exercise 66)",
     "heroku addons:create heroku-postgresql:hobby-dev\n"
     "        # Sets DATABASE_URL env var automatically"),

    ("5", "Set environment variables (Exercise 67)",
     "heroku config:set ENV=Production\n"
     "        heroku config:set SECRET_KEY=your-production-secret\n"
     "        heroku config:set JWT_SECRET_KEY=your-jwt-secret\n"
     "        heroku config:set MAILGUN_DOMAIN=your-domain.mailgun.org\n"
     "        heroku config:set MAILGUN_API_KEY=key-xxxxxxxxxxxx"),

    ("6", "Initialise Git (Exercise 68)",
     "git init\n"
     "        git add .\n"
     "        git commit -m \"Initial commit\""),

    ("7", "Set Heroku remote + deploy",
     "heroku git:remote -a smilecook-api\n"
     "        git push heroku main"),

    ("8", "Run database migrations on Heroku",
     "heroku run flask db upgrade"),

    ("9", "Open the deployed app",
     "heroku open"),

    ("10", "View logs",
     "heroku logs --tail"),
]

for num, title, cmd in steps:
    print(f"  Step {num}: {title}")
    print(f"    $ {cmd}")
    print()

print("=== Verify environment variables ===\n")
print("  $ heroku config")
print()
print("  Expected output:")
vars_example = [
    ("DATABASE_URL",    "postgres://xxxx:yyyy@host:5432/dbname"),
    ("ENV",             "Production"),
    ("JWT_SECRET_KEY",  "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"),
    ("MAILGUN_API_KEY", "key-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"),
    ("MAILGUN_DOMAIN",  "sandbox.mailgun.org"),
    ("SECRET_KEY",      "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"),
]
for k, v in vars_example:
    print(f"    {k:<20}: {v}")',
    demo = NULL
  ),

  list(
    name = "deployment_comparison.py",
    description = "<strong>deployment_comparison.py</strong> — Chapter 10 theory: SaaS vs PaaS vs IaaS. Compares Heroku (PaaS) with AWS EC2 (IaaS) and explains the trade-offs: control, cost, ops complexity, and scalability.",
    code = 'print("=== Cloud Deployment Models: SaaS vs PaaS vs IaaS ===\n")

models = {
    "SaaS (Software as a Service)": {
        "examples":    "Gmail, Salesforce, Slack, Mailgun",
        "you_manage":  "Nothing -- just use the software",
        "provider":    "Everything: infra, runtime, app, data",
        "use_case":    "End-user applications",
        "smilecook":   "Mailgun is SaaS we consume",
    },
    "PaaS (Platform as a Service)": {
        "examples":    "Heroku, Google App Engine, Render",
        "you_manage":  "Your application code and data",
        "provider":    "Infrastructure, OS, runtime, scaling",
        "use_case":    "Deploy apps without managing servers",
        "smilecook":   "We deploy Smilecook here",
    },
    "IaaS (Infrastructure as a Service)": {
        "examples":    "AWS EC2, Google Compute Engine, Azure VMs",
        "you_manage":  "OS, runtime, middleware, app, data",
        "provider":    "Physical servers, networking, storage",
        "use_case":    "Full control, complex architectures",
        "smilecook":   "Alternative with more ops work",
    },
}

for model, info in models.items():
    print(f"  {model}")
    for k, v in info.items():
        print(f"    {k:<15}: {v}")
    print()

print("=== Heroku Free Tier Notes ===\n")
notes = [
    "hobby-dev Postgres: 10,000 rows max, no backups",
    "Free dynos sleep after 30 min of inactivity",
    "First request after sleep takes ~5-10 seconds (cold start)",
    "Use hobby or standard dyno for always-on production apps",
    "Heroku Postgres backups available on paid plans",
]
for n in notes:
    print(f"  - {n}")

print()
print("=== Full project structure for deployment ===\n")
structure = """
  smilecook/
  +-- app.py           <- Application factory (ENV-aware)
  +-- main.py          <- Gunicorn entry point: app = create_app()
  +-- config.py        <- Dev / Staging / Production config classes
  +-- Procfile         <- web: gunicorn main:app
  +-- requirements.txt <- pip freeze output
  +-- .gitignore       <- excludes .env, __pycache__, static/images
  +-- extensions.py    <- db, jwt, image_set, cache, limiter
  +-- models/
  +-- resources/
  +-- schemas/
  +-- utils.py
  +-- migrations/      <- flask db upgrade runs on heroku
  +-- static/
      +-- images/      <- uploaded avatars + covers (git-ignored)
"""
print(structure)',
    demo = NULL
  ),

  list(
    name = "production_checklist.py",
    description = "<strong>production_checklist.py</strong> — A complete production readiness checklist synthesising all 10 chapters: security, performance, observability, and deployment best practices for the Smilecook API.",
    code = 'print("=== Smilecook Production Readiness Checklist ===\n")
print("  Synthesising all 10 chapters of the book\n")

checklist = {
    "Ch 1-2  Flask + REST": [
        "RESTful URL design (/recipes, /recipes/<id>)",
        "Correct HTTP verbs (GET/POST/PUT/PATCH/DELETE)",
        "Correct status codes (201 Created, 204 No Content, 404 Not Found)",
        "Flask-RESTful Resource classes separate HTTP logic from business logic",
    ],
    "Ch 3    Database": [
        "SQLAlchemy ORM models with proper column types and constraints",
        "All schema changes managed via Flask-Migrate (no manual SQL)",
        "Foreign key relationships defined (Recipe.user_id -> User.id)",
        "Passwords hashed with bcrypt/pbkdf2 -- never plain text",
    ],
    "Ch 4    Authentication": [
        "JWT access tokens (15 min) + refresh tokens (30 days)",
        "Ownership checks on all mutating endpoints",
        "@jwt_required on create/update/delete, @jwt_optional on read",
        "Token blacklist for logout (JTI stored in memory/Redis)",
    ],
    "Ch 5    Serialisation": [
        "marshmallow schemas for all input validation",
        "dump_only on id/created_at, load_only on password",
        "Nested UserSchema in RecipeSchema (author field)",
        "PATCH uses partial= to allow optional fields",
    ],
    "Ch 6    Email": [
        "Email activation required before login is permitted",
        "Tokens expire after 30 minutes (URLSafeTimedSerializer)",
        "Salted tokens prevent cross-purpose reuse",
        "Secrets (MAILGUN_API_KEY) in environment variables only",
    ],
    "Ch 7    Images": [
        "UUID filenames prevent path traversal and collisions",
        "File type validated against IMAGES whitelist",
        "Pillow compresses to JPEG quality=85, max 1600px",
        "Old avatar/cover deleted before saving new one",
    ],
    "Ch 8    Pagination": [
        "All list endpoints paginated (default 20 per page)",
        "PaginationSchema returns first/last/prev/next links",
        "Search uses ILIKE across name + description",
        "Sort column whitelisted against injection",
    ],
    "Ch 9    Performance + Security": [
        "GET /recipes cached 60 seconds (query_string=True)",
        "cache.clear() called on every write operation",
        "Login endpoint rate-limited to 3/minute per IP",
        "RATELIMIT_HEADERS_ENABLED for client retry logic",
    ],
    "Ch 10   Deployment": [
        "ENV variable selects Dev/Staging/Production config",
        "All secrets in Heroku config vars (never in code)",
        "Gunicorn WSGI server (not Flask dev server)",
        "flask db upgrade run after every deployment",
        ".gitignore excludes .env and uploaded images",
    ],
}

for chapter, items in checklist.items():
    print(f"  [{chapter}]")
    for item in items:
        print(f"    \u2705 {item}")
    print()

print("=== You built a production-grade REST API! ===\n")
print("  Smilecook endpoints (complete):")
endpoints = [
    ("POST",   "/users",                         "Register"),
    ("GET",    "/users/activate/<token>",         "Activate account"),
    ("GET",    "/users/<username>",               "Public profile"),
    ("PUT",    "/users/avatar",                   "Upload avatar"),
    ("GET",    "/users/<username>/recipes",       "User recipes"),
    ("GET",    "/me",                             "Own profile"),
    ("POST",   "/token",                          "Login"),
    ("POST",   "/refresh",                        "Refresh token"),
    ("POST",   "/revoke",                         "Logout"),
    ("GET",    "/recipes",                        "List + search"),
    ("POST",   "/recipes",                        "Create recipe"),
    ("GET",    "/recipes/<id>",                   "Get recipe"),
    ("PATCH",  "/recipes/<id>",                   "Update recipe"),
    ("DELETE", "/recipes/<id>",                   "Delete recipe"),
    ("PUT",    "/recipes/<id>/publish",           "Publish"),
    ("DELETE", "/recipes/<id>/publish",           "Unpublish"),
    ("PUT",    "/recipes/<id>/cover",             "Upload cover"),
]
print("  %-8s %-36s %s" % ("Method", "URL", "Action"))
print("  " + "-" * 60)
for m, u, a in endpoints:
    print(f"  {m:<8} {u:<36} {a}")',
    demo = NULL
  )
)

# ── Chapter 10 UI ──────────────────────────────────────────────
chapter10_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(10, "\U0001f680", "Deployment",
      "Ship Smilecook to production. Configure Dev/Staging/Production environments, package with Gunicorn and a Procfile, deploy to Heroku with Postgres, manage secrets via config vars, and run database migrations in the cloud.",
      c("Heroku", "Gunicorn", "Procfile", "Config Classes", "PaaS vs IaaS", "ENV vars", "Heroku Postgres", "flask db upgrade")),

    stats_row(
      list("3",       "Config Environments"),
      list("Gunicorn","WSGI Server"),
      list("Heroku",  "PaaS Platform"),
      list("17",      "API Endpoints")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),

        tabPanel(title = tagList(icon("book"), " Theory"),

          fluidRow(
            box(title = "\U0001f310 SaaS vs PaaS vs IaaS", status = "info", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                tags$h5("Cloud deployment models"),
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(tags$th("Model"), tags$th("Examples"), tags$th("You manage"))),
                  tags$tbody(
                    tags$tr(tags$td("SaaS"), tags$td("Gmail, Mailgun, Slack"),         tags$td("Nothing -- just use it")),
                    tags$tr(tags$td("PaaS"), tags$td("Heroku, Render, App Engine"),    tags$td("App code and data only")),
                    tags$tr(tags$td("IaaS"), tags$td("AWS EC2, GCP VMs, Azure"),       tags$td("OS, runtime, middleware, app"))
                  )
                )
              ),
              div(class = "tip-box",
                HTML("<strong>\U0001f4a1 For Smilecook:</strong> We use <strong>PaaS (Heroku)</strong> to focus on application code rather than server management. Heroku handles OS patches, scaling, and routing automatically."))
            ),

            box(title = "\u2699\ufe0f Config Classes", status = "warning", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                tags$h5("Three-environment pattern"),
                tags$pre(class = "code-inline",
"class Config:              # shared base
    DEBUG = False
    CACHE_TYPE = \"simple\"

class DevelopmentConfig(Config):
    DEBUG = True
    SECRET_KEY = \"dev-only-secret\"    # hard-coded is OK
    SQLALCHEMY_DATABASE_URI = \"sqlite:///dev.db\"

class ProductionConfig(Config):
    SECRET_KEY = os.environ.get(\"SECRET_KEY\")  # env var!
    SQLALCHEMY_DATABASE_URI = os.environ.get(\"DATABASE_URL\")")
              ),
              div(class = "framework-card",
                tags$h5("App factory selects config"),
                tags$pre(class = "code-inline",
"env = os.environ.get(\"ENV\", \"Development\")

if env == \"Production\":
    config_str = \"config.ProductionConfig\"
elif env == \"Staging\":
    config_str = \"config.StagingConfig\"
else:
    config_str = \"config.DevelopmentConfig\"

app.config.from_object(config_str)")
              )
            )
          ),

          fluidRow(
            box(title = "\U0001f680 Gunicorn + Procfile", status = "success", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                tags$h5("Why not the Flask dev server?"),
                tags$ul(
                  tags$li("Single-threaded -- 1 request at a time"),
                  tags$li("No process management -- crashes without restart"),
                  tags$li("Exposes debug info and reloader in production"),
                  tags$li("Not designed for concurrent real-world traffic")
                )
              ),
              div(class = "framework-card",
                tags$h5("main.py + Procfile"),
                tags$pre(class = "code-inline",
"# main.py
from app import create_app
app = create_app()

# Procfile  (no extension, in project root)
web: gunicorn main:app
#    ^         ^    ^
#    process   module variable")
              ),
              div(class = "success-box",
                HTML("<strong>\u2705 Gunicorn</strong> is a pre-fork WSGI server. Each worker is a separate process -- a crash in one worker does not affect others, and Heroku auto-restarts failed dynos."))
            ),

            box(title = "\U0001f4e6 Heroku Deployment Workflow", status = "danger", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                tags$h5("10-step deploy"),
                tags$ol(
                  tags$li(tags$code("heroku login")),
                  tags$li(tags$code("heroku create smilecook-api")),
                  tags$li(tags$code("heroku addons:create heroku-postgresql:hobby-dev")),
                  tags$li(tags$code("heroku config:set ENV=Production")),
                  tags$li(tags$code("heroku config:set SECRET_KEY=..."), " (and all secrets)"),
                  tags$li(tags$code("git init && git add . && git commit")),
                  tags$li(tags$code("heroku git:remote -a smilecook-api")),
                  tags$li(tags$code("git push heroku main")),
                  tags$li(tags$code("heroku run flask db upgrade")),
                  tags$li(tags$code("heroku open"))
                )
              ),
              div(class = "tip-box",
                HTML("<strong>\U0001f4a1 DATABASE_URL</strong> is set automatically when you add the Heroku Postgres add-on. Your <code>ProductionConfig</code> reads it with <code>os.environ.get(\"DATABASE_URL\")</code>."))
            )
          ),

          fluidRow(
            box(title = "\U0001f3c6 Full API + Production Checklist", status = "primary", solidHeader = TRUE, width = 12,
              fluidRow(
                column(6,
                  div(class = "framework-card",
                    tags$h5("All 17 Smilecook Endpoints"),
                    tags$table(class = "algo-table",
                      tags$thead(tags$tr(tags$th("Method"), tags$th("URL"), tags$th("Action"))),
                      tags$tbody(
                        tags$tr(tags$td(tags$code("POST")),   tags$td("/users"),                   tags$td("Register")),
                        tags$tr(tags$td(tags$code("GET")),    tags$td("/users/activate/<token>"),   tags$td("Activate")),
                        tags$tr(tags$td(tags$code("GET")),    tags$td("/users/<username>"),          tags$td("Profile")),
                        tags$tr(tags$td(tags$code("PUT")),    tags$td("/users/avatar"),              tags$td("Avatar upload")),
                        tags$tr(tags$td(tags$code("GET")),    tags$td("/me"),                        tags$td("Own profile")),
                        tags$tr(tags$td(tags$code("POST")),   tags$td("/token"),                     tags$td("Login")),
                        tags$tr(tags$td(tags$code("POST")),   tags$td("/refresh"),                   tags$td("Refresh token")),
                        tags$tr(tags$td(tags$code("POST")),   tags$td("/revoke"),                    tags$td("Logout")),
                        tags$tr(tags$td(tags$code("GET")),    tags$td("/recipes"),                   tags$td("List + search")),
                        tags$tr(tags$td(tags$code("POST")),   tags$td("/recipes"),                   tags$td("Create")),
                        tags$tr(tags$td(tags$code("GET")),    tags$td("/recipes/<id>"),              tags$td("Get one")),
                        tags$tr(tags$td(tags$code("PATCH")),  tags$td("/recipes/<id>"),              tags$td("Partial update")),
                        tags$tr(tags$td(tags$code("DELETE")), tags$td("/recipes/<id>"),              tags$td("Delete")),
                        tags$tr(tags$td(tags$code("PUT")),    tags$td("/recipes/<id>/publish"),      tags$td("Publish")),
                        tags$tr(tags$td(tags$code("DELETE")), tags$td("/recipes/<id>/publish"),      tags$td("Unpublish")),
                        tags$tr(tags$td(tags$code("PUT")),    tags$td("/recipes/<id>/cover"),        tags$td("Cover upload"))
                      )
                    )
                  )
                ),
                column(6,
                  div(class = "framework-card",
                    tags$h5("Production checklist summary"),
                    tags$ul(
                      tags$li(tags$strong("Security:"), " bcrypt passwords, JWT auth, ownership checks, email activation, rate limiting"),
                      tags$li(tags$strong("Data:"), " SQLAlchemy ORM, Flask-Migrate, proper FK relationships"),
                      tags$li(tags$strong("API design:"), " RESTful URLs, correct status codes, marshmallow validation, pagination"),
                      tags$li(tags$strong("Performance:"), " Response caching, cache invalidation on write"),
                      tags$li(tags$strong("Files:"), " UUID filenames, Pillow compression, extension whitelist"),
                      tags$li(tags$strong("Ops:"), " Gunicorn WSGI, Heroku config vars, ENV-based config classes"),
                      tags$li(tags$strong("Email:"), " Mailgun transactional, time-limited activation tokens")
                    )
                  ),
                  div(class = "success-box",
                    HTML("<strong>\U0001f3c6 You have completed all 10 chapters!</strong><br>Smilecook is a fully-featured, production-deployed REST API built from first principles with Flask, SQLAlchemy, JWT, marshmallow, Pillow, Mailgun, Flask-Caching, Flask-Limiter, and Heroku."))
                )
              )
            )
          )
        ),

        tabPanel(title = tagList(icon("code"), " Code Lab"),
          code_lab_header(
            "Chapter 10 \u2014 Deployment",
            "Config class hierarchy, Gunicorn and Procfile, Heroku deployment workflow, SaaS/PaaS/IaaS comparison, and full production checklist."
          ),
          file_pills_ui(ns, CH10_FILES),
          py_code_display(ns),
          terminal_ui(ns)
        )
      )
    )
  )
}

chapter10_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    code_lab_server(input, output, session, CH10_FILES)
  })
}
