# modules/chapter04.R
# Chapter 4: Authentication Services and Security with JWT

CH04_FILES <- list(

  list(
    name = "jwt_concepts.py",
    description = "<strong>jwt_concepts.py</strong> — Deep dive into JWT structure: decodes a real token to show the three Base64Url-encoded parts (header, payload, signature). Demonstrates claims, expiry, and why JWTs are self-contained.",
    code = 'import base64, json, hashlib, hmac, time

# ── What a JWT looks like ─────────────────────────────────────
print("=== JWT Structure ===\n")
print("A JWT is three Base64Url-encoded parts joined by dots:\n")
print("  eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9")
print("  .eyJzdWIiOiIxMjM0NTYiLCJ1c2VybmFtZSI6ImFsaWNlIiwiZXhwIjoxNzAwMDAwMDAwfQ")
print("  .SomeSignatureHere\n")

# ── Build a minimal JWT from scratch ─────────────────────────
def b64url_encode(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()

def b64url_decode(s: str) -> bytes:
    padding = 4 - len(s) % 4
    return base64.urlsafe_b64decode(s + "=" * padding)

SECRET = "super-secret-key"

header  = {"alg": "HS256", "typ": "JWT"}
payload = {
    "sub":      "42",
    "username": "alice",
    "iat":      int(time.time()),
    "exp":      int(time.time()) + 3600,   # expires in 1 hour
    "fresh":    True,
}

h = b64url_encode(json.dumps(header,  separators=(",",":")).encode())
p = b64url_encode(json.dumps(payload, separators=(",",":")).encode())

sig_input = f"{h}.{p}".encode()
sig = hmac.new(SECRET.encode(), sig_input, hashlib.sha256).digest()
s   = b64url_encode(sig)

token = f"{h}.{p}.{s}"
print("=== Hand-crafted JWT ===\n")
print(f"  Header  : {json.dumps(header)}")
print(f"  Payload : {json.dumps(payload, indent=10)}")
print(f"\n  Token   : {token[:50]}...\n")

# ── Decode and verify ─────────────────────────────────────────
print("=== Verification ===\n")
parts = token.split(".")
decoded_header  = json.loads(b64url_decode(parts[0]))
decoded_payload = json.loads(b64url_decode(parts[1]))

print(f"  Decoded header  : {decoded_header}")
print(f"  Decoded payload : {decoded_payload}")
print(f"  sub (user id)   : {decoded_payload[\'sub\']}")
print(f"  fresh           : {decoded_payload[\'fresh\']}")
print(f"  expires in      : {decoded_payload[\'exp\'] - int(time.time())} seconds")

# Re-compute signature to verify
check_input = f"{parts[0]}.{parts[1]}".encode()
check_sig   = hmac.new(SECRET.encode(), check_input, hashlib.sha256).digest()
valid = hmac.compare_digest(b64url_decode(parts[2]), check_sig)
print(f"\n  Signature valid : {valid}  \u2705")

print()
print("=== JWT Claims Reference ===")
claims = [
    ("sub",  "Subject — who the token refers to (user id)"),
    ("iat",  "Issued At — when the token was created"),
    ("exp",  "Expiry — when the token stops being valid"),
    ("jti",  "JWT ID — unique identifier (used for revocation)"),
    ("fresh","Custom — whether token was issued at login vs refresh"),
]
for k, v in claims:
    print(f"  {k:<8} — {v}")',
    demo = NULL
  ),

  list(
    name = "token_resource.py",
    description = "<strong>token_resource.py</strong> — Exercise 24: the <code>TokenResource</code> login endpoint. Validates credentials, creates an access token and refresh token with <code>create_access_token()</code>. Simulated here without Flask.",
    code = '# Exercise 24 + 29: TokenResource — Login, Access Token, Refresh Token
# Source: Lesson04/Exercise29/resources/token.py
import json, time, base64, hashlib, hmac
from http import HTTPStatus

SECRET_KEY = "dev-secret-key"

# ── Minimal token helper (mirrors flask_jwt_extended) ────────
def b64url(data):
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()

def make_token(user_id, fresh=False, token_type="access", expires_in=900):
    header  = {"alg": "HS256", "typ": "JWT"}
    payload = {
        "sub":   str(user_id),
        "type":  token_type,
        "fresh": fresh,
        "iat":   int(time.time()),
        "exp":   int(time.time()) + expires_in,
        "jti":   hex(abs(hash((user_id, time.time()))))[2:18],
    }
    h = b64url(json.dumps(header,  separators=(",",":")).encode())
    p = b64url(json.dumps(payload, separators=(",",":")).encode())
    sig = hmac.new(SECRET_KEY.encode(), f"{h}.{p}".encode(), hashlib.sha256).digest()
    return f"{h}.{p}.{b64url(sig)}", payload

# ── User store ────────────────────────────────────────────────
import hashlib as _hl
def _hash(pw): return _hl.sha256(pw.encode()).hexdigest()

users = {
    "alice@example.com": {"id": 1, "username": "alice", "password": _hash("password123")},
    "bob@example.com":   {"id": 2, "username": "bob",   "password": _hash("secret456")},
}

black_list = set()   # revoked JTIs

# ── TokenResource.post() — Exercise 24 ───────────────────────
def login(email, password):
    user = users.get(email)
    if not user or user["password"] != _hash(password):
        return {"message": "username or password is incorrect"}, HTTPStatus.UNAUTHORIZED

    access_token,  at_payload = make_token(user["id"], fresh=True,  token_type="access",  expires_in=900)
    refresh_token, rt_payload = make_token(user["id"], fresh=False, token_type="refresh", expires_in=86400)
    return {
        "access_token":  access_token,
        "refresh_token": refresh_token,
        "_debug_access_payload":  at_payload,
        "_debug_refresh_payload": rt_payload,
    }, HTTPStatus.OK

# ── RefreshResource.post() — Exercise 29 ─────────────────────
def refresh(refresh_token_str):
    parts   = refresh_token_str.split(".")
    payload = json.loads(base64.urlsafe_b64decode(parts[1] + "=="))
    if payload.get("type") != "refresh":
        return {"message": "not a refresh token"}, HTTPStatus.UNPROCESSABLE_ENTITY
    new_token, new_payload = make_token(int(payload["sub"]), fresh=False, token_type="access")
    return {"access_token": new_token, "_debug": new_payload}, HTTPStatus.OK

# ── RevokeResource.post() — Exercise 31 ──────────────────────
def revoke(access_token_str):
    parts   = access_token_str.split(".")
    payload = json.loads(base64.urlsafe_b64decode(parts[1] + "=="))
    black_list.add(payload["jti"])
    return {"message": "Successfully logged out"}, HTTPStatus.OK',
    demo = 'def show(label, result):
    body, status = result
    print(f"  {label}")
    print(f"    Status : {status.value} {status.phrase}")
    for k, v in body.items():
        if k.startswith("_debug"):
            print(f"    {k} : {v}")
        elif "token" in k:
            print(f"    {k} : {str(v)[:45]}...")
        else:
            print(f"    {k} : {v}")
    print()

print("=== JWT Authentication Flow Demo ===\n")

# 1. Login with correct credentials
result = login("alice@example.com", "password123")
show("POST /tokens (correct credentials)", result)
access_tok  = result[0]["access_token"]
refresh_tok = result[0]["refresh_token"]

# 2. Wrong password
show("POST /tokens (wrong password)", login("alice@example.com", "wrongpassword"))

# 3. Refresh
show("POST /tokens/refresh", refresh(refresh_tok))

# 4. Revoke / logout
show("POST /tokens/revoke (logout)", revoke(access_tok))
print(f"  Black list (revoked JTIs): {black_list}")'
  ),

  list(
    name = "protected_routes.py",
    description = "<strong>protected_routes.py</strong> — Exercises 26-27: demonstrates <code>@jwt_required</code>, <code>@jwt_optional</code>, and the ownership check pattern from <code>RecipeResource</code>. Shows how <code>get_jwt_identity()</code> extracts user_id and how 403 Forbidden is returned when a user tries to modify another user's recipe.",
    code = '# Exercises 26-27: Protected Routes & Ownership Checks
# Source: Lesson04/Exercise27/resources/recipe.py + user.py
import json
from http import HTTPStatus

# ── Simulated JWT context ─────────────────────────────────────
_current_user_id = None   # set by the decorator simulation

def jwt_required(fn):
    def wrapper(*args, **kwargs):
        if _current_user_id is None:
            return {"message": "Missing Authorization Header"}, HTTPStatus.UNAUTHORIZED
        return fn(*args, **kwargs)
    return wrapper

def jwt_optional(fn):
    def wrapper(*args, **kwargs):
        return fn(*args, **kwargs)   # user might be None — that is OK
    return wrapper

def get_jwt_identity():
    return _current_user_id

# ── Simulated database ────────────────────────────────────────
recipes_db = {
    1: {"id": 1, "name": "Egg Salad",    "user_id": 1, "is_publish": True},
    2: {"id": 2, "name": "Tomato Pasta", "user_id": 1, "is_publish": False},
    3: {"id": 3, "name": "Burger",       "user_id": 2, "is_publish": True},
}
users_db = {1: "alice", 2: "bob"}

# ── RecipeResource handlers (mirrors Exercise 27) ─────────────
@jwt_optional
def get_recipe(recipe_id):
    recipe = recipes_db.get(recipe_id)
    if recipe is None:
        return {"message": "Recipe not found"}, HTTPStatus.NOT_FOUND
    current = get_jwt_identity()
    if not recipe["is_publish"] and recipe["user_id"] != current:
        return {"message": "Access is not allowed"}, HTTPStatus.FORBIDDEN
    return recipe, HTTPStatus.OK

@jwt_required
def delete_recipe(recipe_id):
    recipe = recipes_db.get(recipe_id)
    if recipe is None:
        return {"message": "Recipe not found"}, HTTPStatus.NOT_FOUND
    if get_jwt_identity() != recipe["user_id"]:
        return {"message": "Access is not allowed"}, HTTPStatus.FORBIDDEN
    del recipes_db[recipe_id]
    return {}, HTTPStatus.NO_CONTENT

# ── MeResource.get() — Exercise 26 ───────────────────────────
@jwt_required
def get_me():
    uid = get_jwt_identity()
    return {"id": uid, "username": users_db[uid]}, HTTPStatus.OK',
    demo = 'global _current_user_id

def show(label, result):
    body, status = result
    print(f"  {label}")
    print(f"    Status: {status.value} {status.phrase}  Body: {json.dumps(body) if body else \"(empty)\"}")
    print()

print("=== Protected Routes Demo ===\n")

# -- Unauthenticated --
_current_user_id = None
print("[ No authentication ]\n")
show("GET /recipes/1 (published)",         get_recipe(1))
show("GET /recipes/2 (unpublished, hidden)",get_recipe(2))
show("GET /me (requires auth)",            get_me())

# -- Logged in as alice (id=1) --
_current_user_id = 1
print("[ Authenticated as alice (id=1) ]\n")
show("GET /recipes/2 (unpublished, owner sees it)", get_recipe(2))
show("GET /me",                                     get_me())
show("DELETE /recipes/1 (own recipe)",              delete_recipe(1))
show("DELETE /recipes/3 (bob\'s recipe => 403)",    delete_recipe(3))

# -- Logged in as bob (id=2) --
_current_user_id = 2
print("[ Authenticated as bob (id=2) ]\n")
show("GET /recipes/2 (alice\'s draft => 403)", get_recipe(2))
show("DELETE /recipes/3 (own recipe)",         delete_recipe(3))'
  ),

  list(
    name = "refresh_revoke.py",
    description = "<strong>refresh_revoke.py</strong> — Exercises 29-31: complete token lifecycle — access token (short-lived), refresh token (long-lived), token refreshing, and blacklist-based logout. Demonstrates the <code>fresh</code> flag, JTI blacklist, and <code>@jwt_refresh_token_required</code>.",
    code = '# Exercises 29-31: Refresh Tokens + Logout / Revocation
# Source: Lesson04/Activity07/smilecook/resources/token.py
import json, time, base64

# ── Simplified token store ─────────────────────────────────────
black_list = set()    # revoked JTIs — in production use Redis

def decode_payload(token_str):
    parts = token_str.split(".")
    return json.loads(base64.urlsafe_b64decode(parts[1] + "=="))

def is_revoked(jti):
    return jti in black_list

# ── Demonstrate the token lifecycle ──────────────────────────
print("=== Token Lifecycle: Access vs Refresh ===\n")

lifecycle = [
    ("Access Token",  "15 min",  "Short-lived; sent on every API request in Authorization header"),
    ("Refresh Token", "30 days", "Long-lived; used ONLY to obtain a new access token"),
]
print("  %-16s %-12s %s" % ("Token Type", "Lifetime", "Purpose"))
print("  " + "-" * 70)
for name, lifetime, purpose in lifecycle:
    print(f"  {name:<16} {lifetime:<12} {purpose}")

print()
print("=== fresh vs non-fresh access tokens ===\n")
print("  fresh=True  — issued directly at login (password verified just now)")
print("  fresh=False — issued via refresh token (password not re-verified)")
print()
print("  Usage: protect sensitive operations (e.g. change password) with")
print("  @fresh_jwt_required so they demand a brand-new login, not a refresh.")

print()
print("=== Logout via JTI Blacklist ===\n")
print("  1. Client sends POST /tokens/revoke with Authorization: Bearer <token>")
print("  2. Server extracts JTI from token: get_raw_jwt()[\'jti\']")
print("  3. Server adds JTI to black_list set (in-memory or Redis)")
print("  4. @jwt_required callback checks is_revoked(jti) before allowing requests")
print()

# Simulate revocation
fake_jti = "abc123def456"
print(f"  Before revoke: is_revoked(\'{fake_jti}\') = {is_revoked(fake_jti)}")
black_list.add(fake_jti)
print(f"  After  revoke: is_revoked(\'{fake_jti}\') = {is_revoked(fake_jti)}")

print()
print("=== Flask-JWT-Extended Configuration ===\n")
config = [
    ("JWT_SECRET_KEY",                  "Secret key for signing tokens"),
    ("JWT_ACCESS_TOKEN_EXPIRES",        "timedelta(minutes=15) -- default 15 min"),
    ("JWT_REFRESH_TOKEN_EXPIRES",       "timedelta(days=30) -- default 30 days"),
    ("JWT_BLACKLIST_ENABLED",           "True -- enables revocation checking"),
    ("JWT_BLACKLIST_TOKEN_CHECKS",      "[access, refresh] -- which types to check"),
]
for key, desc in config:
    print(f"  {key:<40} # {desc}")',
    demo = NULL
  )
)

# ── Chapter 4 UI ──────────────────────────────────────────────
chapter4_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(4, "\U0001f511", "Authentication Services and Security with JWT",
      "Secure the Smilecook API with JSON Web Tokens. Implement login, protected routes with ownership checks, refresh tokens for seamless sessions, and blacklist-based logout.",
      c("JWT", "Flask-JWT-Extended", "Access Token", "Refresh Token", "Blacklist", "fresh flag", "@jwt_required")),

    stats_row(
      list("3",    "Token Types"),
      list("15m",  "Access Token Life"),
      list("30d",  "Refresh Token Life"),
      list("JTI",  "Revocation Key")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),

        tabPanel(title = tagList(icon("book"), " Theory"),

          fluidRow(
            box(title = "\U0001f511 What is JWT?", status = "info", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                tags$h5("JSON Web Token"),
                tags$p("A JWT is a compact, URL-safe token that encodes claims as a JSON object, signed with a secret key. It is self-contained — the server does not need to store session state."),
                tags$pre(class = "code-inline",
"<Header>.<Payload>.<Signature>

Header  : {\"alg\": \"HS256\", \"typ\": \"JWT\"}
Payload : {\"sub\": \"42\", \"exp\": 1700000000, \"fresh\": true}
Signature: HMAC-SHA256(base64(header) + \".\" + base64(payload), secret)")
              ),
              div(class = "tip-box",
                HTML("<strong>\U0001f4a1 Stateless auth:</strong> The token carries all the info the server needs. No session table, no DB lookup per request — just verify the signature."))
            ),

            box(title = "\U0001f4cb JWT Claims Reference", status = "warning", solidHeader = TRUE, width = 6,
              tags$table(class = "algo-table",
                tags$thead(tags$tr(tags$th("Claim"), tags$th("Name"), tags$th("Description"))),
                tags$tbody(
                  tags$tr(tags$td(tags$code("sub")),   tags$td("Subject"),   tags$td("User identifier (user.id)")),
                  tags$tr(tags$td(tags$code("iat")),   tags$td("Issued At"), tags$td("Unix timestamp when token was created")),
                  tags$tr(tags$td(tags$code("exp")),   tags$td("Expiry"),    tags$td("Unix timestamp after which token is invalid")),
                  tags$tr(tags$td(tags$code("jti")),   tags$td("JWT ID"),    tags$td("Unique ID per token — used for revocation")),
                  tags$tr(tags$td(tags$code("fresh")), tags$td("Fresh"),     tags$td("True = issued at login, False = via refresh"))
                )
              ),
              div(class = "framework-card",
                tags$h5("Flask-JWT-Extended Setup"),
                tags$pre(class = "code-inline",
"from flask_jwt_extended import JWTManager

app.config['JWT_SECRET_KEY'] = 'your-secret'
jwt = JWTManager(app)")
              )
            )
          ),

          fluidRow(
            box(title = "\U0001f504 Token Lifecycle: Access + Refresh", status = "success", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                tags$h5("Why two tokens?"),
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(tags$th("Token"), tags$th("Lifetime"), tags$th("Sent with"))),
                  tags$tbody(
                    tags$tr(tags$td("Access"),  tags$td("15 minutes"), tags$td("Every API request")),
                    tags$tr(tags$td("Refresh"), tags$td("30 days"),    tags$td("Only to /tokens/refresh"))
                  )
                )
              ),
              div(class = "framework-card",
                tags$h5("Flow"),
                tags$ol(
                  tags$li("Login ", tags$code("POST /tokens"), " → receive access + refresh tokens"),
                  tags$li("Include ", tags$code("Authorization: Bearer <access_token>"), " on every request"),
                  tags$li("When access token expires (401), call ", tags$code("POST /tokens/refresh")),
                  tags$li("Get fresh access token; no need to re-enter password"),
                  tags$li("Logout: ", tags$code("POST /tokens/revoke"), " — JTI added to blacklist")
                )
              ),
              div(class = "tip-box",
                HTML("<strong>\U0001f4a1 fresh flag:</strong> Sensitive endpoints (e.g. change password) use <code>@fresh_jwt_required</code> so the user must have logged in recently, not just refreshed."))
            ),

            box(title = "\U0001f6e1\ufe0f Protected Route Patterns", status = "danger", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                tags$h5("Decorator Reference"),
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(tags$th("Decorator"), tags$th("Behaviour"))),
                  tags$tbody(
                    tags$tr(tags$td(tags$code("@jwt_required")),             tags$td("Must have valid access token or 401")),
                    tags$tr(tags$td(tags$code("@jwt_optional")),             tags$td("Token optional; identity = None if absent")),
                    tags$tr(tags$td(tags$code("@fresh_jwt_required")),       tags$td("Must have fresh=True token")),
                    tags$tr(tags$td(tags$code("@jwt_refresh_token_required")),tags$td("Must have refresh token"))
                  )
                )
              ),
              div(class = "framework-card",
                tags$h5("Ownership Check Pattern"),
                tags$pre(class = "code-inline",
"@jwt_required
def delete(self, recipe_id):
    recipe = Recipe.get_by_id(recipe_id)
    if recipe is None:
        return {'message': 'Not found'}, 404

    current_user = get_jwt_identity()   # user_id from token

    if current_user != recipe.user_id:  # ownership check
        return {'message': 'Forbidden'}, 403

    recipe.delete()
    return {}, 204")
              )
            )
          ),

          fluidRow(
            box(title = "\U0001f6aa Logout via JTI Blacklist", status = "primary", solidHeader = TRUE, width = 12,
              fluidRow(
                column(6,
                  div(class = "framework-card",
                    tags$h5("Why JWTs are hard to invalidate"),
                    tags$p("JWTs are stateless — the server cannot invalidate a token once issued. The solution is a blacklist: store revoked JTI values in memory (dev) or Redis (production), and check on every request."),
                    tags$pre(class = "code-inline",
"black_list = set()

@jwt.token_in_blacklist_loader
def check_if_token_in_blacklist(decrypted_token):
    return decrypted_token['jti'] in black_list

class RevokeResource(Resource):
    @jwt_required
    def post(self):
        jti = get_raw_jwt()['jti']
        black_list.add(jti)
        return {'message': 'Successfully logged out'}, 200")
                  )
                ),
                column(6,
                  div(class = "framework-card",
                    tags$h5("New Routes Added in Chapter 4"),
                    tags$table(class = "algo-table",
                      tags$thead(tags$tr(tags$th("Method"), tags$th("URL"), tags$th("Action"))),
                      tags$tbody(
                        tags$tr(tags$td(tags$code("POST")), tags$td("/tokens"),         tags$td("Login — get access + refresh tokens")),
                        tags$tr(tags$td(tags$code("POST")), tags$td("/tokens/refresh"), tags$td("Exchange refresh token for new access token")),
                        tags$tr(tags$td(tags$code("POST")), tags$td("/tokens/revoke"),  tags$td("Logout — add JTI to blacklist")),
                        tags$tr(tags$td(tags$code("GET")),  tags$td("/me"),             tags$td("Get own profile (requires JWT)")),
                        tags$tr(tags$td(tags$code("GET")),  tags$td("/users/{name}"),   tags$td("Public profile (email hidden unless own)"))
                      )
                    )
                  ),
                  div(class = "success-box",
                    HTML("<strong>\u2705 Chapter 4 outcome:</strong> Smilecook is now fully authenticated. Only logged-in users can create recipes. Only the owner can edit or delete. Unauthenticated users see only published content."))
                )
              )
            )
          )
        ),

        tabPanel(title = tagList(icon("code"), " Code Lab"),
          code_lab_header(
            "Chapter 4 \u2014 Authentication Services and Security with JWT",
            "JWT anatomy, login endpoint, protected routes with ownership checks, refresh tokens, and blacklist-based logout."
          ),
          file_pills_ui(ns, CH04_FILES),
          py_code_display(ns),
          terminal_ui(ns)
        )
      )
    )
  )
}

chapter4_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    code_lab_server(input, output, session, CH04_FILES)
  })
}
