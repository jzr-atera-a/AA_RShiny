# modules/overview.R
# Overview landing page

overview_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "overview-hero",
      div(class = "overview-book-chip", "PYTHON API DEVELOPMENT FUNDAMENTALS"),
      tags$h1(class = "overview-title", "\U0001f40d Python API Dev Lab"),
      tags$p(class = "overview-subtitle",
        "An interactive learning companion to Python API Development Fundamentals by Jack Chan, Ray Chung & Jack Huang (Packt, 2019)."),
      div(class = "badge-row",
        span(class = "hero-badge", "REST APIs"),
        span(class = "hero-badge", "Flask"),
        span(class = "hero-badge", "Flask-RESTful"),
        span(class = "hero-badge", "SQLAlchemy"),
        span(class = "hero-badge", "JWT Auth"),
        span(class = "hero-badge", "Marshmallow")
      )
    ),

    stats_row(
      list("10",   "All Chapters"),
      list("40+",  "Python Examples"),
      list("40+",  "Exercises"),
      list("372",  "Pages in Book")
    ),

    fluidRow(
      box(title = "\U0001f4da What You'll Build — Smilecook", status = "info", solidHeader = TRUE, width = 8,
        div(class = "framework-card",
          tags$h5("The Smilecook Recipe-Sharing Platform"),
          tags$p("Throughout this book you progressively build Smilecook — a fully-featured recipe sharing REST API, starting from a simple Flask hello-world and growing to a production-deployed application."),
          tags$table(class = "algo-table",
            tags$thead(tags$tr(tags$th("Chapter"), tags$th("Topic"), tags$th("What you build"))),
            tags$tbody(
              tags$tr(tags$td("1"), tags$td("Your First Step"),         tags$td("Flask hello-world, CRUD recipe API, HTTP concepts")),
              tags$tr(tags$td("2"), tags$td("Building Our Project"),    tags$td("Flask-RESTful resources, Recipe model, publish workflow")),
              tags$tr(tags$td("3"), tags$td("Database + SQLAlchemy"),   tags$td("ORM models, migrations, password hashing, app factory")),
              tags$tr(tags$td("4"), tags$td("JWT Authentication"),      tags$td("Login, protected routes with @jwt_required, refresh tokens, logout + blacklist")),
              tags$tr(tags$td("5"), tags$td("Marshmallow"),             tags$td("Schemas, dump/load, field validation, nested schemas, PATCH, webargs")),
              tags$tr(tags$td("6"), tags$td("Email Confirmation"),      tags$td("Mailgun API, itsdangerous tokens, activation workflow, env variables")),
              tags$tr(tags$td("7"), tags$td("Working with Images"),     tags$td("Flask-Uploads, UUID filenames, Pillow compression, avatar + cover upload")),
              tags$tr(tags$td("8"), tags$td("Pagination + Search"),     tags$td("SQLAlchemy paginate(), ILIKE search, dynamic sort, PaginationSchema")),
              tags$tr(tags$td("9"), tags$td("Caching + Rate Limiting"), tags$td("Flask-Caching, cache invalidation on write, Flask-Limiter, IP whitelist")),
              tags$tr(tags$td("10"), tags$td("Deployment"),              tags$td("Heroku, Gunicorn, Procfile, config classes, env vars, flask db upgrade")),
              tags$tr(tags$td("7"), tags$td("Working with Images"),     tags$td("Avatar upload, image compression with Pillow")),
              tags$tr(tags$td("8"), tags$td("Pagination & Search"),     tags$td("Paginated endpoints, search, sort/order")),
              tags$tr(tags$td("9"), tags$td("Caching & Rate Limiting"), tags$td("Flask-Caching, Flask-Limiter, whitelisting")),
              tags$tr(tags$td("10"), tags$td("Deployment"),             tags$td("Heroku, Gunicorn, environment variables, Postgres"))
            )
          )
        )
      ),

      box(title = "\U0001f6e0\ufe0f Tech Stack", status = "warning", solidHeader = TRUE, width = 4,
        div(class = "framework-card",
          tags$h5("Core Libraries"),
          tags$ul(
            tags$li(tags$strong("Flask"), " — Micro web framework"),
            tags$li(tags$strong("Flask-RESTful"), " — Resource-based routing"),
            tags$li(tags$strong("Flask-SQLAlchemy"), " — ORM integration"),
            tags$li(tags$strong("Flask-Migrate"), " — DB schema migrations"),
            tags$li(tags$strong("Flask-JWT-Extended"), " — JWT authentication"),
            tags$li(tags$strong("marshmallow"), " — Serialisation & validation"),
            tags$li(tags$strong("Passlib/bcrypt"), " — Password hashing"),
            tags$li(tags$strong("Pillow"), " — Image processing")
          )
        ),
        div(class = "tip-box",
          HTML("<strong>\U0001f4a1 How to use this lab:</strong> Select a chapter from the sidebar. Each chapter has a <strong>Theory</strong> tab with definitions and concepts, and a <strong>Code Lab</strong> tab where you can select and run each exercise's Python code directly."))
      )
    )
  )
}

overview_server <- function(id) {
  moduleServer(id, function(input, output, session) {})
}
