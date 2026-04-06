# modules/chapter03.R
# Chapter 3: Manipulating a Database with SQLAlchemy

CH03_FILES <- list(

  list(
    name = "orm_concepts.py",
    description = "<strong>orm_concepts.py</strong> — Demonstrates ORM concepts using Python's <code>sqlite3</code> (raw SQL) vs a minimal ORM simulation, illustrating exactly what SQLAlchemy does under the hood. Covers tables, columns, relationships, and queries.",
    code = '# Chapter 3: ORM Concepts — What SQLAlchemy does for you
import sqlite3
import json

# ── Part 1: Raw SQL (what you have to do without ORM) ─────────
print("=== Part 1: Raw SQL (sqlite3) ===\n")
conn = sqlite3.connect(":memory:")
cur  = conn.cursor()

# DDL — create tables
cur.executescript("""
    CREATE TABLE user (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        username   TEXT NOT NULL UNIQUE,
        email      TEXT NOT NULL UNIQUE,
        is_active  INTEGER DEFAULT 0,
        created_at TEXT DEFAULT (datetime(\'now\'))
    );
    CREATE TABLE recipe (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        name             TEXT NOT NULL,
        description      TEXT,
        num_of_servings  INTEGER,
        cook_time        INTEGER,
        is_publish       INTEGER DEFAULT 0,
        user_id          INTEGER REFERENCES user(id)
    );
""")

# DML — insert
cur.execute("INSERT INTO user (username, email) VALUES (?, ?)", ("alice", "alice@example.com"))
cur.execute("INSERT INTO user (username, email) VALUES (?, ?)", ("bob",   "bob@example.com"))
cur.execute("INSERT INTO recipe (name, num_of_servings, cook_time, user_id) VALUES (?,?,?,?)",
            ("Egg Salad", 2, 10, 1))
cur.execute("INSERT INTO recipe (name, num_of_servings, cook_time, user_id) VALUES (?,?,?,?)",
            ("Tomato Pasta", 4, 20, 1))
conn.commit()

# Query with JOIN
cur.execute("""
    SELECT r.id, r.name, u.username
    FROM recipe r JOIN user u ON r.user_id = u.id
""")
rows = cur.fetchall()
print("  Recipes with authors (raw SQL JOIN):")
for row in rows:
    print(f"    id={row[0]}, name={row[1]!r}, author={row[2]!r}")

# ── Part 2: ORM simulation — what SQLAlchemy gives you ────────
print()
print("=== Part 2: ORM Pattern (what Flask-SQLAlchemy looks like) ===\n")

orm_code = """
# With Flask-SQLAlchemy you write PYTHON CLASSES, not SQL:

class User(db.Model):
    __tablename__ = "user"
    id       = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), nullable=False, unique=True)
    email    = db.Column(db.String(200), nullable=False, unique=True)
    recipes  = db.relationship("Recipe", backref="user")

class Recipe(db.Model):
    __tablename__ = "recipe"
    id      = db.Column(db.Integer, primary_key=True)
    name    = db.Column(db.String(100), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey("user.id"))

# CRUD becomes Python method calls:
user = User(username="alice", email="alice@example.com")
db.session.add(user)
db.session.commit()

recipe = Recipe.query.filter_by(name="Egg Salad").first()
user.recipes  # -> Python list of Recipe objects (ORM handles the JOIN)
"""
print(orm_code)

print("=== ORM Benefits Summary ===")
benefits = [
    ("Abstraction",    "Write Python, not SQL — same code works on SQLite, PostgreSQL, MySQL"),
    ("Safety",         "Parameterised queries by default — prevents SQL injection"),
    ("Relationships",  "Navigate FK relationships as Python attributes (user.recipes)"),
    ("Migrations",     "Flask-Migrate tracks schema changes like Git tracks code"),
    ("Portability",    "Switch databases by changing one config line"),
]
for name, desc in benefits:
    print(f"  \u2705 {name:<15} — {desc}")',
    demo = NULL
  ),

  list(
    name = "sqlalchemy_models.py",
    description = "<strong>sqlalchemy_models.py</strong> — The full SQLAlchemy models from Exercise 19. Shows the <code>User</code> and <code>Recipe</code> model classes with column definitions, relationships, <code>server_default</code> timestamps, and class methods for querying. Simulated with SQLite in-memory.",
    code = '# Exercise 19: Installing Packages and Defining SQLAlchemy Models
# Source: Lesson03/Exercise19/models/user.py + recipe.py
# Simulated with sqlite3 to demonstrate the ORM concepts without Flask context

import sqlite3, json
from datetime import datetime

# ── Simulated db.Model behaviour with sqlite3 ─────────────────
conn = sqlite3.connect(":memory:")
conn.row_factory = sqlite3.Row
cur = conn.cursor()

cur.executescript("""
    CREATE TABLE user (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        username   TEXT NOT NULL UNIQUE,
        email      TEXT NOT NULL UNIQUE,
        password   TEXT,
        is_active  INTEGER DEFAULT 0,
        created_at TEXT DEFAULT (datetime(\'now\')),
        updated_at TEXT DEFAULT (datetime(\'now\'))
    );
    CREATE TABLE recipe (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        name             TEXT NOT NULL,
        description      TEXT,
        num_of_servings  INTEGER,
        cook_time        INTEGER,
        directions       TEXT,
        is_publish       INTEGER DEFAULT 0,
        created_at       TEXT DEFAULT (datetime(\'now\')),
        updated_at       TEXT DEFAULT (datetime(\'now\')),
        user_id          INTEGER REFERENCES user(id)
    );
""")

# ── ORM-style class wrappers ──────────────────────────────────
class User:
    """Mirrors Exercise 19 User(db.Model)"""

    def __init__(self, username, email, password=None):
        self.username = username
        self.email    = email
        self.password = password

    def save(self):
        cur.execute(
            "INSERT INTO user (username, email, password) VALUES (?,?,?)",
            (self.username, self.email, self.password)
        )
        conn.commit()
        self.id = cur.lastrowid

    @classmethod
    def get_by_username(cls, username):
        row = cur.execute("SELECT * FROM user WHERE username=?", (username,)).fetchone()
        return dict(row) if row else None

    @classmethod
    def get_by_email(cls, email):
        row = cur.execute("SELECT * FROM user WHERE email=?", (email,)).fetchone()
        return dict(row) if row else None


class Recipe:
    """Mirrors Exercise 19 Recipe(db.Model)"""

    def __init__(self, name, description, num_of_servings, cook_time, directions, user_id):
        self.name            = name
        self.description     = description
        self.num_of_servings = num_of_servings
        self.cook_time       = cook_time
        self.directions      = directions
        self.user_id         = user_id
        self.is_publish      = False

    def save(self):
        cur.execute(
            """INSERT INTO recipe
               (name, description, num_of_servings, cook_time, directions, is_publish, user_id)
               VALUES (?,?,?,?,?,?,?)""",
            (self.name, self.description, self.num_of_servings,
             self.cook_time, self.directions, int(self.is_publish), self.user_id)
        )
        conn.commit()
        self.id = cur.lastrowid',
    demo = '# Demo the models
print("=== SQLAlchemy Model Demo (Exercise 19) ===\n")

# Create users
alice = User("alice", "alice@example.com", "hashed_pw_1")
alice.save()
bob   = User("bob",   "bob@example.com",   "hashed_pw_2")
bob.save()

print(f"  Created users: alice.id={alice.id}, bob.id={bob.id}")

# Create recipes belonging to alice
r1 = Recipe("Egg Salad",    "Lovely salad.",  2, 10, "Boil eggs, mix.",  alice.id)
r1.save()
r2 = Recipe("Tomato Pasta", "Lovely pasta.",  4, 20, "Cook pasta, add.", alice.id)
r2.save()
r3 = Recipe("Burger",       "Juicy burger.",  1, 15, "Grill, assemble.", bob.id)
r3.save()

# Query methods
found_user = User.get_by_username("alice")
print(f"\n  User.get_by_username(\'alice\') -> id={found_user[\'id\']}, email={found_user[\'email\']!r}")

found_by_email = User.get_by_email("bob@example.com")
print(f"  User.get_by_email(\'bob@example.com\') -> username={found_by_email[\'username\']!r}")

# Show recipes with user FK
rows = cur.execute("""
    SELECT r.id, r.name, r.is_publish, u.username
    FROM recipe r JOIN user u ON r.user_id = u.id
    ORDER BY r.id
""").fetchall()
print("\n  Recipes in database:")
for row in rows:
    print(f"    id={row[0]}, name={row[1]!r}, is_publish={bool(row[2])}, author={row[3]!r}")

print(f"\n  Total users  : {cur.execute(\'SELECT COUNT(*) FROM user\').fetchone()[0]}")
print(f"  Total recipes: {cur.execute(\'SELECT COUNT(*) FROM recipe\').fetchone()[0]}")'
  ),

  list(
    name = "flask_migrate.py",
    description = "<strong>flask_migrate.py</strong> — Exercise 20: demonstrates Flask-Migrate (Alembic) migration workflow. Explains how migrations work as version-controlled schema changes, shows the migration script structure, and simulates the upgrade/downgrade process.",
    code = '# Exercise 20: Flask-Migrate — Database Migration Workflow
# Source: Lesson03/Exercise20 concepts

print("=== Flask-Migrate (Alembic) Workflow ===\n")

# The 4 essential commands
commands = [
    ("flask db init",    "Initialise migrations/ folder in your project (run once)"),
    ("flask db migrate", "Auto-generate a new migration script by comparing models to DB"),
    ("flask db upgrade", "Apply pending migrations to the database"),
    ("flask db downgrade","Roll back the most recent migration"),
]
print("  Commands:")
for cmd, desc in commands:
    print(f"    $ {cmd:<25} # {desc}")

print()
print("=== What a Migration Script Looks Like ===\n")
migration_script = """
# migrations/versions/6089a861042f_.py  (auto-generated by flask db migrate)

def upgrade():
    op.create_table(
        "user",
        sa.Column("id",         sa.Integer(),     nullable=False),
        sa.Column("username",   sa.String(80),    nullable=False),
        sa.Column("email",      sa.String(200),   nullable=False),
        sa.Column("password",   sa.String(200),   nullable=True),
        sa.Column("is_active",  sa.Boolean(),     nullable=True),
        sa.Column("created_at", sa.DateTime(),    nullable=False,
                  server_default=sa.text("now()")),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("email"),
        sa.UniqueConstraint("username"),
    )

def downgrade():
    op.drop_table("user")
"""
print(migration_script)

print("=== Key Concepts ===")
concepts = [
    ("Version control",  "Each migration file has a unique revision ID, forming a chain"),
    ("Auto-generation",  "Alembic compares your SQLAlchemy models to the current DB schema"),
    ("Upgrade chain",    "upgrade() applies changes; downgrade() reverses them"),
    ("server_default",   "Sets the default at DB level (not Python level) for reliability"),
    ("Production safe",  "Never drop data without a carefully reviewed downgrade() function"),
]
for name, desc in concepts:
    print(f"  \u2705 {name:<18} — {desc}")',
    demo = NULL
  ),

  list(
    name = "password_hashing.py",
    description = "<strong>password_hashing.py</strong> — Exercise 22: implements user registration with password hashing using <code>passlib</code>. Demonstrates why plain-text passwords are dangerous, how bcrypt works, and the check workflow during login.",
    code = '# Exercise 22: Password Hashing with passlib / bcrypt
# Source: Lesson03/Exercise22/models/user.py
import hashlib, secrets, hmac

# ── Why we NEVER store plain-text passwords ───────────────────
print("=== The Problem: Plain-Text Passwords ===\n")
print("  If someone steals your database:")
print("  plain_text_db = {")
print("      \"alice\": \"password123\",   <- EXPOSED immediately")
print("      \"bob\":   \"mySecret!\",     <- All users compromised")
print("  }")

# ── Hashing demonstration with SHA-256 + salt (simplified) ───
print()
print("=== Hashing Concepts (simplified with hashlib) ===\n")

def hash_password(plain_password: str) -> tuple:
    """Simulate what passlib/bcrypt does: salt + hash."""
    salt = secrets.token_hex(16)          # random 32-char salt
    salted = (salt + plain_password).encode()
    hashed = hashlib.sha256(salted).hexdigest()
    return salt, hashed

def verify_password(plain_password: str, salt: str, stored_hash: str) -> bool:
    salted = (salt + plain_password).encode()
    computed = hashlib.sha256(salted).hexdigest()
    return hmac.compare_digest(computed, stored_hash)

# Registration
password = "mySecret123"
salt, hashed = hash_password(password)
print(f"  Registration:")
print(f"    plain text : {password!r}")
print(f"    salt       : {salt!r}")
print(f"    stored hash: {hashed!r}")
print(f"    -> We store ONLY (salt, hash), never the plain text")

# Login verification
print()
print(f"  Login (correct password {password!r}):")
result = verify_password(password, salt, hashed)
print(f"    verify_password() -> {result}  \u2705")

print(f"  Login (wrong password \'wrongpass\'):")
result_wrong = verify_password("wrongpass", salt, hashed)
print(f"    verify_password() -> {result_wrong}  \u274c")

# ── Flask-Bcrypt pattern (as used in the book) ────────────────
print()
print("=== Flask-Bcrypt Pattern (book code) ===\n")
bcrypt_code = """
# In models/user.py (Exercise 22):
from flask_bcrypt import generate_password_hash, check_password_hash

class User(db.Model):
    password = db.Column(db.String(200))

    def save(self):
        # Hash the password BEFORE saving to DB
        self.password = generate_password_hash(self.password).decode("utf8")
        db.session.add(self)
        db.session.commit()

# In resources/user.py (login):
if not check_password_hash(user.password, data["password"]):
    return {"message": "email or password is incorrect"}, HTTPStatus.UNAUTHORIZED
"""
print(bcrypt_code)',
    demo = NULL
  ),

  list(
    name = "app_factory.py",
    description = "<strong>app_factory.py</strong> — Exercise 19: the Application Factory pattern used in Chapter 3. Shows how <code>create_app()</code>, <code>register_extensions()</code>, and <code>register_resources()</code> create a clean, testable Flask app structure that scales to production.",
    code = '# Exercise 19: Application Factory Pattern
# Source: Lesson03/Exercise19/app.py

print("=== Application Factory Pattern ===\n")

app_code = """
# app.py — Chapter 3 version with SQLAlchemy + Migrate

from flask import Flask
from flask_migrate import Migrate
from flask_restful import Api

from config import Config
from extensions import db

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)      # Load config from class

    register_extensions(app)            # Init db, migrate, etc.
    register_resources(app)             # Register all API routes

    return app

def register_extensions(app):
    db.init_app(app)                    # Bind SQLAlchemy to this app
    migrate = Migrate(app, db)          # Set up Alembic migrations

def register_resources(app):
    api = Api(app)
    api.add_resource(RecipeListResource,    "/recipes")
    api.add_resource(RecipeResource,        "/recipes/<int:recipe_id>")
    api.add_resource(RecipePublishResource, "/recipes/<int:recipe_id>/publish")

if __name__ == "__main__":
    app = create_app()
    app.run()
"""
print(app_code)

config_code = """
# config.py
class Config:
    DEBUG = True
    SQLALCHEMY_DATABASE_URI = "sqlite:///smilecook.db"
    SQLALCHEMY_TRACK_MODIFICATIONS = False

# extensions.py
from flask_sqlalchemy import SQLAlchemy
db = SQLAlchemy()         # Created here, bound to app later
"""
print("=== config.py + extensions.py ===\n")
print(config_code)

print("=== Why Application Factory? ===\n")
benefits = [
    ("Testing",    "Create multiple app instances with different configs in tests"),
    ("Config",     "Inject config at runtime: create_app(\'testing\'), create_app(\'production\')"),
    ("Extensions", "Extensions initialised with db.init_app() avoid circular imports"),
    ("Scalability","Easy to add Blueprints, more extensions as the project grows"),
]
for name, desc in benefits:
    print(f"  \u2705 {name:<14} — {desc}")',
    demo = NULL
  )
)

# ── Chapter 3 UI ──────────────────────────────────────────────
chapter3_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(3, "\U0001f5c4\ufe0f", "Manipulating a Database with SQLAlchemy",
      "Replace in-memory storage with a real relational database using Flask-SQLAlchemy ORM. Master model definitions, database migrations with Flask-Migrate, and secure password hashing.",
      c("SQLAlchemy", "ORM", "Flask-Migrate", "Alembic", "Password Hashing", "App Factory", "bcrypt")),

    stats_row(
      list("ORM",     "Pattern"),
      list("2",       "Models: User + Recipe"),
      list("bcrypt",  "Password Hash"),
      list("Alembic", "Migrations")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),

        # ── THEORY TAB ─────────────────────────────────────────
        tabPanel(title = tagList(icon("book"), " Theory"),

          fluidRow(
            box(title = "\U0001f5c4\ufe0f Databases & ORM", status = "info", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                tags$h5("What is a Database?"),
                tags$p("A database is an organised collection of structured information stored electronically. In web APIs, a relational database (RDBMS) stores data in tables with rows and columns."),
                tags$ul(
                  tags$li(tags$strong("SQL"), " — Structured Query Language; used to create, read, update, delete data"),
                  tags$li(tags$strong("RDBMS"), " — Relational Database Management System (PostgreSQL, SQLite, MySQL)"),
                  tags$li(tags$strong("Table"), " — Stores one type of entity (e.g. users, recipes)"),
                  tags$li(tags$strong("Foreign Key"), " — Links a row in one table to a row in another")
                )
              ),
              div(class = "framework-card",
                tags$h5("What is ORM?"),
                tags$p("Object-Relational Mapping (ORM) lets you interact with a relational database using Python classes and objects instead of writing raw SQL."),
                tags$pre(class = "code-inline",
"# Without ORM (raw SQL):
cursor.execute(\"SELECT * FROM user WHERE username=?\", (\"alice\",))

# With ORM (SQLAlchemy):
User.query.filter_by(username=\"alice\").first()")
              )
            ),

            box(title = "\U0001f4ca SQLAlchemy Model Anatomy", status = "warning", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                tags$h5("Column Type Reference"),
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(tags$th("SQLAlchemy type"), tags$th("Python type"), tags$th("DB type"))),
                  tags$tbody(
                    tags$tr(tags$td(tags$code("db.Integer")),     tags$td("int"),      tags$td("INTEGER")),
                    tags$tr(tags$td(tags$code("db.String(n)")),   tags$td("str"),      tags$td("VARCHAR(n)")),
                    tags$tr(tags$td(tags$code("db.Boolean()")),   tags$td("bool"),     tags$td("BOOLEAN")),
                    tags$tr(tags$td(tags$code("db.DateTime()")),  tags$td("datetime"), tags$td("DATETIME")),
                    tags$tr(tags$td(tags$code("db.Text()")),      tags$td("str"),      tags$td("TEXT"))
                  )
                )
              ),
              div(class = "framework-card",
                tags$h5("Column Constraints"),
                tags$pre(class = "code-inline",
"id       = db.Column(db.Integer, primary_key=True)
username = db.Column(db.String(80),
                     nullable=False,    # NOT NULL
                     unique=True)       # UNIQUE
created  = db.Column(db.DateTime(),
                     server_default=db.func.now())")
              )
            )
          ),

          fluidRow(
            box(title = "\U0001f517 Relationships: User \u2192 Recipes", status = "success", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                tags$h5("One-to-Many Relationship"),
                tags$p("One User can have many Recipes. In SQLAlchemy, this is modelled with a ForeignKey in the child table and a relationship() in the parent:"),
                tags$pre(class = "code-inline",
"# In User model:
recipes = db.relationship('Recipe', backref='user')

# In Recipe model:
user_id = db.Column(db.Integer, db.ForeignKey('user.id'))

# Usage in Python:
alice = User.query.first()
alice.recipes    # list of Recipe objects
recipe.user      # the User who owns this recipe (backref)")
              ),
              div(class = "tip-box",
                HTML("<strong>\U0001f4a1 backref:</strong> The <code>backref='user'</code> argument automatically adds a <code>.user</code> attribute to the Recipe model, so you can navigate the relationship in both directions."))
            ),

            box(title = "\U0001f504 Flask-Migrate Workflow", status = "danger", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                tags$h5("Migration Lifecycle"),
                tags$ol(
                  tags$li("Change your SQLAlchemy model class"),
                  tags$li(tags$code("flask db migrate -m 'add user table'"), " — Auto-generate script"),
                  tags$li("Review the generated migration file in ", tags$code("migrations/versions/")),
                  tags$li(tags$code("flask db upgrade"), " — Apply to database"),
                  tags$li(tags$code("flask db downgrade"), " — Roll back if needed")
                )
              ),
              div(class = "framework-card",
                tags$h5("Why migrations matter"),
                tags$ul(
                  tags$li("Track schema changes over time, like Git for your database"),
                  tags$li("Share schema changes with your team safely"),
                  tags$li("Deploy schema changes to production without data loss"),
                  tags$li("Roll back bad changes in seconds")
                )
              )
            )
          ),

          fluidRow(
            box(title = "\U0001f512 Password Hashing — Security Essential", status = "primary", solidHeader = TRUE, width = 12,
              fluidRow(
                column(6,
                  div(class = "framework-card",
                    tags$h5("The Golden Rule"),
                    tags$p(tags$strong("NEVER store plain-text passwords."), " Always hash passwords before storing. A hash function is one-way — given the hash, you cannot recover the original password."),
                    tags$pre(class = "code-inline",
"# What to store in the DB:
generate_password_hash('mypassword')
# -> '$2b$12$KIx9...' (bcrypt hash, 60 chars)

# How to verify at login:
check_password_hash(stored_hash, 'mypassword')
# -> True if match, False otherwise")
                  ),
                  div(class = "info-box-plain",
                    HTML("<strong>\u2139 Why bcrypt?</strong> bcrypt is deliberately slow to compute, making brute-force attacks impractical. It also includes a random salt automatically, so identical passwords produce different hashes."))
                ),
                column(6,
                  div(class = "framework-card",
                    tags$h5("Registration + Login Flow"),
                    tags$ol(
                      tags$li(tags$strong("Registration:"), " User sends {email, password}"),
                      tags$li("Server calls ", tags$code("generate_password_hash(password)"), " → bcrypt hash"),
                      tags$li("Store email + hash in DB; never the plain-text password"),
                      tags$li(tags$strong("Login:"), " User sends {email, password}"),
                      tags$li("Look up user by email; call ", tags$code("check_password_hash(stored, input)")),
                      tags$li("Returns 401 if no match; issues JWT token if match (Chapter 4)")
                    )
                  ),
                  div(class = "success-box",
                    HTML("<strong>\u2705 Chapter 3 outcome:</strong> Smilecook now has a real PostgreSQL/SQLite database, User + Recipe models with proper relationships, schema migrations, and secure password storage — ready for JWT authentication in Chapter 4."))
                )
              )
            )
          )
        ),

        # ── CODE LAB TAB ───────────────────────────────────────

          # ── VOLVO API CONTEXT ──────────────────────────────────────

          # -- VOLVO API CONTEXT -----------------------------------------------------
          fluidRow(
            box(title = "\U0001f69a Volvo API Connection: Storing Vehicle Telemetry with SQLAlchemy",
                status = "primary", solidHeader = TRUE, width = 12,
              div(class = "volvo-context-banner",
                span(class = "volvo-badge", "\U0001f69a Volvo Group Vehicle API v1.0.6"),
                span(class = "volvo-relevance", "Direct relevance: persistent storage of telemetry data")
              ),
              div(class = "volvo-card",
                tags$h5("Why you need a database"),
                tags$p("The Volvo API docs state explicitly: the client needs to regularly retrieve data and store it in its own database. The API only retains 14 days of history. If you need longer retention, trend analysis, or your own query logic, you must persist the data yourself using SQLAlchemy models.")
              ),
              fluidRow(
                column(6,
                  div(class = "volvo-card",
                    tags$h5("Suggested SQLAlchemy Models"),
                    tags$p("Each Volvo API endpoint maps naturally to an ORM model:"),
                    tags$pre(class = "code-inline",
'class Vehicle(db.Model):
    __tablename__    = "vehicle"
    vin              = db.Column(db.String(17), primary_key=True)
    brand            = db.Column(db.String(50))
    emission_level   = db.Column(db.String(20))
    transport_cycle  = db.Column(db.String(30))
    connected_services = db.Column(db.Text)   # JSON list
    last_synced      = db.Column(db.DateTime)

class VehiclePosition(db.Model):
    __tablename__ = "vehicle_position"
    id            = db.Column(db.Integer, primary_key=True)
    vin           = db.Column(db.String(17),
                              db.ForeignKey("vehicle.vin"))
    latitude      = db.Column(db.Float)
    longitude     = db.Column(db.Float)
    speed_kmh     = db.Column(db.Float)   # wheelBasedSpeed
    heading       = db.Column(db.Integer)
    received_at   = db.Column(db.DateTime)
    trigger_type  = db.Column(db.String(50))')
                  )
                ),
                column(6,
                  div(class = "volvo-card",
                    tags$h5("VehicleStatus Model (EV fields)"),
                    tags$pre(class = "code-inline",
'class VehicleStatus(db.Model):
    __tablename__            = "vehicle_status"
    id                       = db.Column(db.Integer,
                                         primary_key=True)
    vin                      = db.Column(db.String(17),
                               db.ForeignKey("vehicle.vin"))
    received_at              = db.Column(db.DateTime)
    trigger_type             = db.Column(db.String(50))

    # Snapshot (MAP service)
    latitude                 = db.Column(db.Float)
    longitude                = db.Column(db.Float)
    wheel_based_speed        = db.Column(db.Float)
    fuel_level_pct           = db.Column(db.Float)
    battery_remaining_pct    = db.Column(db.Float)
    charging_status          = db.Column(db.String(30))
    ambient_temp_celsius     = db.Column(db.Float)

    # Accumulated (CHECK service)
    total_distance_m         = db.Column(db.BigInteger)
    total_fuel_used_ml       = db.Column(db.BigInteger)
    total_electric_energy_wh = db.Column(db.BigInteger)'),
                    div(class = "tip-box",
                      HTML("<strong>\U0001f4a1 Migration tip:</strong> Use <code>flask db migrate</code> whenever the Volvo API evolves. EV-specific fields like <code>charging_status</code> and <code>battery_remaining_pct</code> only became mandatory in v1.0.6."))
                  )
                )
              )
            )
          ),

        tabPanel(title = tagList(icon("code"), " Code Lab"),

          code_lab_header(
            "Chapter 3 \u2014 Manipulating a Database with SQLAlchemy",
            "ORM vs raw SQL, SQLAlchemy model definitions, Flask-Migrate workflow, application factory pattern, and password hashing."
          ),
          file_pills_ui(ns, CH03_FILES),
          py_code_display(ns),
          terminal_ui(ns)
        ),

        tabPanel(title = tagList(icon("truck"), " Volvo: Fleet Data"),
          fluidRow(
            box(title = "\U0001f4da How to Use This Tab", status = "primary",
                solidHeader = TRUE, width = 12, collapsible = TRUE,
              div(class = "volvo-card",
                tags$p(tags$strong("Purpose:"), " Query", tags$code("GET /vehicle/vehicles"), "to retrieve your full fleet list -- the foundation of any SQLAlchemy schema as shown in the Theory tab."),
                tags$p(tags$strong("Credentials:"), " Must be saved in the", tags$strong("Chapter 1 > Volvo Credentials & API"), "tab first."),
                tags$p(tags$strong("additionalContent = VOLVOGROUPVEHICLE"), " unlocks proprietary Volvo fields: ",
                  tags$code("connectedServices"), ", ", tags$code("transportCycle"), ", ",
                  tags$code("deliveryDate"), ", ", tags$code("registrationNumber"), ", ",
                  tags$code("roadCondition"), ", ", tags$code("vehicleReportSettings"), "."),
                tags$p(tags$strong("Pagination:"), " Max 100 vehicles per response. When ", tags$code("moreDataAvailable=true"),
                  ", copy the last VIN into the ", tags$strong("lastVin"), " field and call again."),
                tags$p(tags$strong("Recommended frequency:"), " Once per day -- vehicle metadata changes rarely.")
              )
            )
          ),
          fluidRow(
            box(title = "\U0001f6f9 /vehicles Parameters", status = "warning",
                solidHeader = TRUE, width = 5,
              checkboxInput(ns("v3_additional"),
                "additionalContent = VOLVOGROUPVEHICLE (unlock proprietary fields)", TRUE),
              hr(),
              textInput(ns("v3_lastvin"), "lastVin (pagination cursor):",
                        placeholder = "Leave blank for first page"),
              textInput(ns("v3_reqid"), "requestId (optional trace ID):",
                        placeholder = "e.g. atera-001"),
              br(),
              actionButton(ns("v3_run"), "\u25b6  Call API  --  GET /vehicles", class = "btn-run")
            ),
            box(title = "\U0001f4cb What Each Field Maps To", status = "info",
                solidHeader = TRUE, width = 7,
              tags$table(class = "algo-table",
                tags$thead(tags$tr(tags$th("API Field"), tags$th("SQLAlchemy Column"), tags$th("Notes"))),
                tags$tbody(
                  tags$tr(tags$td(tags$code("vin")),             tags$td(tags$code("String(17) PK")),  tags$td("Vehicle Identification Number")),
                  tags$tr(tags$td(tags$code("brand")),           tags$td(tags$code("String(50)")),     tags$td("RENAULT TRUCKS, VOLVO TRUCKS...")),
                  tags$tr(tags$td(tags$code("model")),           tags$td(tags$code("String(50)")),     tags$td("FH, FM, T-range...")),
                  tags$tr(tags$td(tags$code("possibleFuelType")),tags$td(tags$code("Text")),           tags$td("ELECTRIC, DIESEL, GAS -- JSON list")),
                  tags$tr(tags$td(tags$code("emissionLevel")),   tags$td(tags$code("String(20)")),     tags$td("EURO_VI, EURO_V...")),
                  tags$tr(tags$td(tags$code("productionDate")),  tags$td(tags$code("Date")),           tags$td("day/month/year object")),
                  tags$tr(tags$td(tags$code("transportCycle*")), tags$td(tags$code("String(30)")),     tags$td("LONG_DISTANCE, DISTRIBUTION...")),
                  tags$tr(tags$td(tags$code("connectedServices*")),tags$td(tags$code("Text")),         tags$td("MAP, CHECK, HEALTH -- JSON list")),
                  tags$tr(tags$td(tags$code("deliveryDate*")),   tags$td(tags$code("Date")),           tags$td("Delivered to end customer")),
                  tags$tr(tags$td(tags$code("registrationNumber*")),tags$td(tags$code("String(20)")), tags$td("Licence plate"))
                )
              ),
              div(class = "tip-box",
                HTML("* <strong>Requires additionalContent=VOLVOGROUPVEHICLE</strong>"))
            )
          ),
          fluidRow(
            box(title = "\U0001f5a5\ufe0f Response", status = "primary",
                solidHeader = TRUE, width = 12,
              div(class = "terminal-wrap",
                div(class = "terminal-header",
                  div(class = "term-dots",
                    span(class = "td-red"), span(class = "td-yellow"), span(class = "td-green")),
                  span(class = "term-label", "GET /vehicle/vehicles")),
                div(class = "terminal-body", verbatimTextOutput(ns("v3_out"))))
            )
          )
        )

      )
    )
  )
}

chapter3_server <- function(id, creds = NULL) {
  moduleServer(id, function(input, output, session) {
    code_lab_server(input, output, session, CH03_FILES)

    v3_result <- eventReactive(input$v3_run, {
      un  <- creds$username; pw <- creds$password
      add <- if (isTRUE(input$v3_additional)) "VOLVOGROUPVEHICLE" else ""
      lv  <- trimws(input$v3_lastvin)
      rid <- trimws(input$v3_reqid)
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
if "', add, '":
    params["additionalContent"] = "', add, '"
if "', lv, '":
    params["lastVin"] = "', lv, '"
if "', rid, '":
    params["requestId"] = "', rid, '"
_call("vehicles", params, un, pw)
')
      run_python_safe(code)
    })
    output$v3_out <- renderText({
      if (input$v3_run == 0)
        return("$ Ready -- credentials must be saved in Chapter 1 first")
      v3_result()
    })

  })
}
