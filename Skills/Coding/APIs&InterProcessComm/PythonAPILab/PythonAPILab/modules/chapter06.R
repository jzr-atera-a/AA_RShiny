# modules/chapter06.R
# Chapter 6: Email Confirmation

CH06_FILES <- list(

  list(
    name = "mailgun_api.py",
    description = "<strong>mailgun_api.py</strong> — Exercises 40-41: the <code>MailgunApi</code> class that wraps the Mailgun HTTP API to send transactional emails. Shows the POST request structure, auth, and how to build the from/to/subject/text payload.",
    code = '# Exercises 40-41: MailgunApi class
# Source: Lesson06/Exercise41/smilecook/mailgun.py
import json

# ── MailgunApi class (mirrors the book exactly) ───────────────
class MailgunApi:
    """Wraps the Mailgun /messages endpoint."""

    API_URL = "https://api.mailgun.net/v3/{}/messages"

    def __init__(self, domain, api_key):
        self.domain   = domain
        self.key      = api_key
        self.base_url = self.API_URL.format(self.domain)

    def send_email(self, to, subject, text, html=None):
        if not isinstance(to, (list, tuple)):
            to = [to]

        data = {
            "from":    f"SmileCook <no-reply@{self.domain}>",
            "to":      to,
            "subject": subject,
            "text":    text,
            "html":    html,
        }

        # Real code uses:
        # response = requests.post(url=self.base_url,
        #                          auth=("api", self.key),
        #                          data=data)
        # return response
        return data   # return the payload dict for demonstration

# ── Demonstration ─────────────────────────────────────────────
print("=== MailgunApi — Transactional Email ===\n")
print("  Mailgun is a cloud email service for developers.")
print("  It exposes a simple REST API to send transactional emails.\n")

mailgun = MailgunApi(
    domain  = "sandbox.mailgun.org",
    api_key = "key-xxxxxxxxxxxxxxxxxxxx"
)

# Simulate sending an account activation email
payload = mailgun.send_email(
    to      = "alice@example.com",
    subject = "Please confirm your registration.",
    text    = "Hi Alice! Please confirm by clicking: https://smilecook.com/activate/TOKEN_HERE",
    html    = "<p>Hi Alice!</p><p><a href=\'https://smilecook.com/activate/TOKEN_HERE\'>Click here to activate</a></p>"
)

print("  Email payload that would be sent to Mailgun API:\n")
payload_display = {k: v for k, v in payload.items() if v is not None}
print(json.dumps(payload_display, indent=4))

print()
print("  Mailgun API request:")
print(f"    POST {mailgun.base_url}")
print(f"    auth: (\"api\", \"<your_api_key>\")")
print(f"    data: {{see payload above}}")
print()
print("  Setup steps:")
steps = [
    "1. Create a free Mailgun account at mailgun.com",
    "2. Add and verify your domain (or use the sandbox domain)",
    "3. Copy your API key from the Mailgun dashboard",
    "4. Set MAILGUN_API_KEY and MAILGUN_DOMAIN as environment variables",
    "5. Instantiate MailgunApi(domain, api_key) and call send_email()",
]
for s in steps: print(f"  {s}")',
    demo = NULL
  ),

  list(
    name = "token_generation.py",
    description = "<strong>token_generation.py</strong> — Exercise 42: <code>generate_token()</code> and <code>verify_token()</code> using <code>itsdangerous.URLSafeTimedSerializer</code>. Creates a time-limited, cryptographically signed activation token from a user's email address.",
    code = '# Exercise 42: Generate and Verify Account Activation Tokens
# Source: Lesson06/Exercise42/utils.py
import json, base64, hmac, hashlib, time, struct

SECRET_KEY = "dev-secret-key-change-in-production"

# ── Simplified URLSafeTimedSerializer simulation ──────────────
# (mirrors itsdangerous behaviour without the library)

def _sign(payload_b64: str, salt: str) -> str:
    key = (SECRET_KEY + salt).encode()
    sig = hmac.new(key, payload_b64.encode(), hashlib.sha256).hexdigest()[:16]
    return sig

def generate_token(email: str, salt: str = None) -> str:
    """
    Mirrors: serializer.dumps(email, salt=salt)
    Produces a URL-safe token containing:
      base64(email) + "." + timestamp + "." + hmac_signature
    """
    salt = salt or ""
    ts   = int(time.time())
    payload = base64.urlsafe_b64encode(
        json.dumps({"email": email, "ts": ts}).encode()
    ).decode().rstrip("=")
    sig = _sign(payload, salt)
    return f"{payload}.{ts}.{sig}"

def verify_token(token: str, max_age: int = 1800, salt: str = None) -> str | bool:
    """
    Mirrors: serializer.loads(token, max_age=max_age, salt=salt)
    Returns email if valid and not expired, False otherwise.
    """
    salt = salt or ""
    try:
        parts = token.split(".")
        if len(parts) < 3:
            return False
        payload_b64 = parts[0]
        ts          = int(parts[1])
        provided_sig = parts[2]

        # Check expiry
        if time.time() - ts > max_age:
            return False

        # Verify signature
        expected_sig = _sign(payload_b64, salt)
        if not hmac.compare_digest(provided_sig, expected_sig):
            return False

        # Decode payload
        padding = 4 - len(payload_b64) % 4
        data = json.loads(base64.urlsafe_b64decode(payload_b64 + "=" * padding))
        return data["email"]

    except Exception:
        return False',
    demo = 'print("=== Account Activation Token Demo ===\n")

# Generate token
email = "alice@example.com"
token = generate_token(email, salt="activate")
print(f"  Email : {email}")
print(f"  Token : {token[:60]}...")
print(f"  Length: {len(token)} characters\n")

# Verify valid token
result = verify_token(token, max_age=1800, salt="activate")
print(f"  verify_token (correct salt) -> {result!r}  \u2705\n")

# Wrong salt
result_wrong_salt = verify_token(token, salt="wrong-salt")
print(f"  verify_token (wrong salt)   -> {result_wrong_salt}  \u274c\n")

# Tampered token
tampered = token[:-5] + "XXXXX"
result_tampered = verify_token(tampered, salt="activate")
print(f"  verify_token (tampered)     -> {result_tampered}  \u274c\n")

# Expired token (max_age=0)
result_expired = verify_token(token, max_age=0, salt="activate")
print(f"  verify_token (max_age=0)    -> {result_expired}  \u274c\n")

print("  itsdangerous real usage:")
print(\'  from itsdangerous import URLSafeTimedSerializer\')
print(\'  s = URLSafeTimedSerializer(app.config["SECRET_KEY"])\')
print(\'  token = s.dumps(email, salt="activate")\')
print(\'  email = s.loads(token, max_age=1800, salt="activate")  # raises on fail\')'
  ),

  list(
    name = "activation_workflow.py",
    description = "<strong>activation_workflow.py</strong> — Exercise 43: the complete user registration + email activation workflow. Shows how <code>UserListResource.post()</code> generates a token, sends the activation email, and how <code>UserActivateResource.get()</code> verifies it and sets <code>is_active=True</code>.",
    code = '# Exercise 43: Full Registration + Activation Workflow
# Source: Lesson06/Exercise43/resources/user.py
import json, base64, hmac, hashlib, time
from http import HTTPStatus

SECRET_KEY = "dev-secret-key"

# ── Token helpers (same as token_generation.py) ───────────────
def generate_token(email, salt=""):
    ts = int(time.time())
    payload = base64.urlsafe_b64encode(
        json.dumps({"email": email, "ts": ts}).encode()
    ).decode().rstrip("=")
    key = (SECRET_KEY + salt).encode()
    sig = hmac.new(key, payload.encode(), hashlib.sha256).hexdigest()[:16]
    return f"{payload}.{ts}.{sig}"

def verify_token(token, max_age=1800, salt=""):
    try:
        parts = token.split(".")
        if len(parts) < 3: return False
        payload_b64, ts_str, provided_sig = parts[0], parts[1], parts[2]
        if time.time() - int(ts_str) > max_age: return False
        key = (SECRET_KEY + salt).encode()
        expected = hmac.new(key, payload_b64.encode(), hashlib.sha256).hexdigest()[:16]
        if not hmac.compare_digest(provided_sig, expected): return False
        padding = 4 - len(payload_b64) % 4
        data = json.loads(base64.urlsafe_b64decode(payload_b64 + "=" * padding))
        return data["email"]
    except: return False

# ── Simulated user store ──────────────────────────────────────
users_db = {}   # email -> user dict
email_log = []  # simulated outbox

def fake_send_email(to, subject, text):
    email_log.append({"to": to, "subject": subject, "text": text[:80] + "..."})
    print(f"  [MAILGUN] Sending to {to}: {subject[:50]}")

# ── UserListResource.post() — registration + send activation ─
def register_user(username, email, password):
    if email in users_db:
        return {"message": "email already used"}, HTTPStatus.BAD_REQUEST
    user = {"id": len(users_db)+1, "username": username, "email": email,
            "password": password, "is_active": False}
    users_db[email] = user
    token = generate_token(email, salt="activate")
    link  = f"https://smilecook.com/users/activate/{token}"
    fake_send_email(
        to      = email,
        subject = "Please confirm your registration.",
        text    = f"Hi {username}! Confirm by clicking: {link}"
    )
    return {"id": user["id"], "username": username, "email": email,
            "is_active": False, "activation_link": link}, HTTPStatus.CREATED

# ── UserActivateResource.get() — verify token + activate ─────
def activate_user(token):
    email = verify_token(token, max_age=1800, salt="activate")
    if email is False:
        return {"message": "Invalid token or token expired"}, HTTPStatus.BAD_REQUEST
    user = users_db.get(email)
    if not user:
        return {"message": "User not found"}, HTTPStatus.NOT_FOUND
    if user["is_active"]:
        return {"message": "The user account is already activated"}, HTTPStatus.BAD_REQUEST
    user["is_active"] = True
    return {}, HTTPStatus.NO_CONTENT

def show(label, result):
    body, status = result
    print(f"  {label}")
    print(f"    Status : {status.value} {status.phrase}")
    if body: print(f"    Body   : {json.dumps({k:v for k,v in body.items() if k!=\'activation_link\'}, indent=6)}")
    print()',
    demo = 'print("=== Registration + Email Activation Workflow ===\n")

# 1. Register
print("Step 1: POST /users (register)\n")
result, _ = register_user("alice", "alice@example.com", "hashed_pw_1")
token = result.get("activation_link","").split("/")[-1]
show("POST /users", (result, _))

# 2. Try to log in before activation (would be rejected in Ch4)
user = users_db.get("alice@example.com")
print(f"  is_active before activation: {user[\'is_active\']}  \u274c\n")

# 3. Activate with valid token
print("Step 2: GET /users/activate/<token> (click the link)\n")
show("GET /users/activate/<valid_token>", activate_user(token))
print(f"  is_active after activation: {users_db[\'alice@example.com\'][\'is_active\']}  \u2705\n")

# 4. Already activated
print("Step 3: Click link again (already activated)\n")
show("GET /users/activate/<token> (second time)", activate_user(token))

# 5. Bad token
print("Step 4: Tampered token\n")
show("GET /users/activate/<tampered_token>", activate_user("invalid.token.here"))

print("  Email outbox:")
for mail in email_log:
    print(f"    To: {mail[\'to\']}  Subject: {mail[\'subject\']}")'
  ),

  list(
    name = "env_variables.py",
    description = "<strong>env_variables.py</strong> — Exercise 44: managing environment variables for secrets (MAILGUN_API_KEY, SECRET_KEY) in development vs production. Shows <code>os.environ</code>, <code>os.getenv()</code>, <code>python-dotenv</code>, and how Flask config classes load from the environment.",
    code = '# Exercise 44: Setting Up Environment Variables
# Source: Lesson06/Exercise44 config pattern
import os, json

print("=== Environment Variables for Secrets ===\n")

# ── Why environment variables? ────────────────────────────────
print("  Rule: NEVER hard-code secrets in source code.")
print("  Reason: Source code gets committed to Git; secrets must stay out.\n")

print("  What to put in environment variables:")
secrets = [
    "SECRET_KEY",
    "JWT_SECRET_KEY",
    "MAILGUN_API_KEY",
    "MAILGUN_DOMAIN",
    "DATABASE_URL",
    "DEBUG",
]
for s in secrets:
    print(f"    {s}")

print()
print("=== How Flask Config Uses Environment Variables ===\n")

config_code = """
# config.py

import os

class Config:
    DEBUG            = False
    SECRET_KEY       = os.environ.get("SECRET_KEY", "fallback-dev-key")
    SQLALCHEMY_DATABASE_URI = os.environ.get(
        "DATABASE_URL",
        "sqlite:///smilecook.db"
    )
    MAILGUN_DOMAIN   = os.environ.get("MAILGUN_DOMAIN")
    MAILGUN_API_KEY  = os.environ.get("MAILGUN_API_KEY")
    JWT_SECRET_KEY   = os.environ.get("JWT_SECRET_KEY", "jwt-dev-key")


class DevelopmentConfig(Config):
    DEBUG = True
    SQLALCHEMY_TRACK_MODIFICATIONS = True


class ProductionConfig(Config):
    SQLALCHEMY_TRACK_MODIFICATIONS = False
"""
print(config_code)

# ── Demonstrate os.environ ─────────────────────────────────────
print("=== Reading Environment Variables in Python ===\n")

# Simulate setting env vars
os.environ["SECRET_KEY"]    = "my-super-secret-production-key"
os.environ["MAILGUN_DOMAIN"] = "sandboxXXXX.mailgun.org"

print(f"  os.environ.get(\'SECRET_KEY\')    = {os.environ.get(\'SECRET_KEY\')!r}")
print(f"  os.environ.get(\'MAILGUN_DOMAIN\') = {os.environ.get(\'MAILGUN_DOMAIN\')!r}")
print(f"  os.environ.get(\'MISSING_KEY\', \'default\') = {os.environ.get(\'MISSING_KEY\', \'default\')!r}")

print()
print("=== .env File + python-dotenv ===\n")
print("  # .env file (never commit to Git!)")
dotenv_example = """
  SECRET_KEY=my-super-secret-key
  DATABASE_URL=postgresql://user:pass@localhost/smilecook
  MAILGUN_API_KEY=key-xxxxxxxxxxxxxxxx
  MAILGUN_DOMAIN=sandboxXXXX.mailgun.org
  JWT_SECRET_KEY=jwt-secret-key
"""
print(dotenv_example)
print("  # In app.py or config.py:")
print("  from dotenv import load_dotenv")
print("  load_dotenv()  # loads .env into os.environ")
print()
print("  # .gitignore must include:")
print("  .env")',
    demo = NULL
  )
)

# ── Chapter 6 UI ──────────────────────────────────────────────
chapter6_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(6, "\U0001f4e7", "Email Confirmation",
      "Add account activation via email: integrate the Mailgun API to send transactional emails, generate time-limited cryptographic activation tokens with itsdangerous, and build the full registration-to-activation workflow.",
      c("Mailgun", "Email API", "itsdangerous", "URLSafeTimedSerializer", "Token Activation", "Environment Variables", "is_active")),

    stats_row(
      list("Mailgun",  "Email Service"),
      list("30 min",   "Token Expiry"),
      list("HMAC",     "Token Signing"),
      list(".env",     "Secret Storage")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),

        tabPanel(title = tagList(icon("book"), " Theory"),

          fluidRow(
            box(title = "\U0001f4e7 Mailgun — Transactional Email API", status = "info", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                tags$h5("What is Mailgun?"),
                tags$p("Mailgun is a cloud email service designed for developers. It provides a simple REST API to send, receive, and track transactional emails — no email server setup needed."),
                tags$ul(
                  tags$li(tags$strong("Transactional email"), " — emails triggered by user actions (signup, reset password)"),
                  tags$li(tags$strong("REST API"), " — simple POST request with auth and email data"),
                  tags$li(tags$strong("Free tier"), " — 5,000 emails/month free for 3 months"),
                  tags$li(tags$strong("Sandbox domain"), " — available immediately for testing")
                )
              ),
              div(class = "framework-card",
                tags$h5("MailgunApi class"),
                tags$pre(class = "code-inline",
"import requests

class MailgunApi:
    API_URL = 'https://api.mailgun.net/v3/{}/messages'

    def send_email(self, to, subject, text, html=None):
        return requests.post(
            url  = self.base_url,
            auth = ('api', self.key),
            data = {
                'from':    f'SmileCook <no-reply@{self.domain}>',
                'to':      to,
                'subject': subject,
                'text':    text,
                'html':    html
            }
        )")
              )
            ),

            box(title = "\U0001f510 itsdangerous — Activation Tokens", status = "warning", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                tags$h5("What is itsdangerous?"),
                tags$p("itsdangerous is a Python library for cryptographically signing data. ", tags$code("URLSafeTimedSerializer"), " creates URL-safe tokens that:"),
                tags$ul(
                  tags$li("Contain the user's email address"),
                  tags$li("Are signed with the app's SECRET_KEY"),
                  tags$li("Expire after a configurable time (e.g. 30 minutes)"),
                  tags$li("Cannot be forged without knowing the SECRET_KEY")
                )
              ),
              div(class = "framework-card",
                tags$h5("generate_token + verify_token"),
                tags$pre(class = "code-inline",
"from itsdangerous import URLSafeTimedSerializer

def generate_token(email, salt=None):
    s = URLSafeTimedSerializer(app.config['SECRET_KEY'])
    return s.dumps(email, salt=salt)

def verify_token(token, max_age=1800, salt=None):
    s = URLSafeTimedSerializer(app.config['SECRET_KEY'])
    try:
        email = s.loads(token, max_age=max_age, salt=salt)
    except:
        return False  # expired or tampered
    return email")
              ),
              div(class = "tip-box",
                HTML("<strong>\U0001f4a1 salt=</strong> adds an extra layer of safety — a token generated with <code>salt='activate'</code> cannot be reused with <code>salt='reset-password'</code>."))
            )
          ),

          fluidRow(
            box(title = "\U0001f504 Full Activation Workflow", status = "success", solidHeader = TRUE, width = 7,
              div(class = "framework-card",
                tags$h5("Registration + Activation Sequence"),
                tags$ol(
                  tags$li(tags$strong("POST /users"), " — user submits {username, email, password}"),
                  tags$li("Server validates data via marshmallow UserSchema"),
                  tags$li("User saved with ", tags$code("is_active=False")),
                  tags$li("Server calls ", tags$code("generate_token(user.email, salt='activate')")),
                  tags$li("Token embedded in activation URL: ", tags$code("url_for('UserActivateResource', token=token)")),
                  tags$li("MailgunApi sends email with activation link"),
                  tags$li("User clicks link → ", tags$code("GET /users/activate/<token>")),
                  tags$li("Server calls ", tags$code("verify_token(token, salt='activate')")),
                  tags$li("On success: ", tags$code("user.is_active = True"), " + save"),
                  tags$li("User can now log in via ", tags$code("POST /tokens"))
                )
              ),
              div(class = "success-box",
                HTML("<strong>\u2705 Why verify email?</strong> Prevents spam accounts, ensures users own the email they register with, and provides a contact for password resets."))
            ),

            box(title = "\U0001f511 Environment Variables", status = "danger", solidHeader = TRUE, width = 5,
              div(class = "framework-card",
                tags$h5("Secrets must never be in code"),
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(tags$th("Variable"), tags$th("Purpose"))),
                  tags$tbody(
                    tags$tr(tags$td(tags$code("SECRET_KEY")),      tags$td("itsdangerous token signing")),
                    tags$tr(tags$td(tags$code("JWT_SECRET_KEY")),  tags$td("JWT token signing")),
                    tags$tr(tags$td(tags$code("MAILGUN_API_KEY")), tags$td("Mailgun authentication")),
                    tags$tr(tags$td(tags$code("MAILGUN_DOMAIN")),  tags$td("Mailgun sending domain")),
                    tags$tr(tags$td(tags$code("DATABASE_URL")),    tags$td("PostgreSQL connection string"))
                  )
                )
              ),
              div(class = "framework-card",
                tags$h5(".env workflow"),
                tags$pre(class = "code-inline",
"# .env  (git-ignored)
SECRET_KEY=my-secret

# config.py
import os
SECRET_KEY = os.environ.get('SECRET_KEY')

# app.py
from dotenv import load_dotenv
load_dotenv()")
              )
            )
          )
        ),

        tabPanel(title = tagList(icon("code"), " Code Lab"),
          code_lab_header(
            "Chapter 6 \u2014 Email Confirmation",
            "MailgunApi class, activation token generation/verification, full registration+activation workflow, and environment variable management."
          ),
          file_pills_ui(ns, CH06_FILES),
          py_code_display(ns),
          terminal_ui(ns)
        )
      )
    )
  )
}

chapter6_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    code_lab_server(input, output, session, CH06_FILES)
  })
}
