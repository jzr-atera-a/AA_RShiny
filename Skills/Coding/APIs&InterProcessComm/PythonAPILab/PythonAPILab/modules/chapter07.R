# modules/chapter07.R
# Chapter 7: Working with Images

CH07_FILES <- list(

  list(
    name = "flask_uploads_setup.py",
    description = "<strong>flask_uploads_setup.py</strong> — Exercise 46: Flask-Uploads with <code>UploadSet</code>, <code>IMAGES</code>, and <code>configure_uploads()</code>. Shows the extensions pattern and how <code>patch_request_class()</code> caps upload size at 10 MB.",
    code = 'import os

print("=== Flask-Uploads Configuration ===\n")

setup_code = """
# extensions.py
from flask_uploads import UploadSet, IMAGES
from flask_sqlalchemy import SQLAlchemy
from flask_jwt_extended import JWTManager

db        = SQLAlchemy()
jwt       = JWTManager()
image_set = UploadSet("images", IMAGES)
# IMAGES = allowed extensions: jpg jpeg png gif tiff bmp webp

# app.py  register_extensions()
from flask_uploads import configure_uploads, patch_request_class

configure_uploads(app, image_set)
patch_request_class(app, 10 * 1024 * 1024)  # 10 MB max
"""
print(setup_code)

print("=== User Model: avatar_image field (Exercise 45) ===\n")
model_code = """
class User(db.Model):
    # ... existing fields ...
    avatar_image = db.Column(db.String(100), default=None)
    # stores the filename: "550e8400-e29b-41d4-a716-446655440000.jpg"
"""
print(model_code)

print("=== Allowed IMAGES extensions ===\n")
IMAGES = ("jpg", "jpeg", "png", "gif", "tiff", "bmp", "webp")
print("  Allowed:", IMAGES)
print()
max_bytes = 10 * 1024 * 1024
print(f"=== Upload size guard ===")
print(f"  patch_request_class(app, {max_bytes:,} bytes = {max_bytes // (1024*1024)} MB)")
print("  Oversized request -> 413 Request Entity Too Large")',
    demo = NULL
  ),

  list(
    name = "avatar_upload_resource.py",
    description = "<strong>avatar_upload_resource.py</strong> — Exercise 46: <code>UserAvatarUploadResource.put()</code>. Validates the file, removes the old avatar if present, saves the new one with <code>save_image()</code>, and returns the new avatar URL.",
    code = 'import os, uuid
from http import HTTPStatus

UPLOAD_FOLDER = "/tmp/smilecook_avatars"
ALLOWED_EXTENSIONS = {"jpg", "jpeg", "png", "gif", "webp"}

os.makedirs(UPLOAD_FOLDER, exist_ok=True)

def allowed_file(filename):
    ext = filename.rsplit(".", 1)[-1].lower() if "." in filename else ""
    return ext in ALLOWED_EXTENSIONS

def save_image(filename, folder):
    ext = filename.rsplit(".", 1)[-1].lower()
    new_filename = f"{uuid.uuid4()}.{ext}"
    save_path = os.path.join(folder, new_filename)
    open(save_path, "w").write("fake image bytes")
    return new_filename

users = {1: {"id": 1, "username": "alice", "avatar_image": None}}

def put_avatar(user_id, filename):
    """UserAvatarUploadResource.put() -- mirrors Exercise 46"""
    if not filename:
        return {"message": "Not a valid image"}, HTTPStatus.BAD_REQUEST
    if not allowed_file(filename):
        return {"message": "File type not allowed"}, HTTPStatus.BAD_REQUEST
    user = users.get(user_id)
    if not user:
        return {"message": "User not found"}, HTTPStatus.NOT_FOUND
    if user["avatar_image"]:
        old_path = os.path.join(UPLOAD_FOLDER, user["avatar_image"])
        if os.path.exists(old_path):
            os.remove(old_path)
            print(f"  Removed old avatar: {user[\"avatar_image\"]}")
    new_filename = save_image(filename, UPLOAD_FOLDER)
    user["avatar_image"] = new_filename
    return {"avatar_url": f"https://smilecook.com/images/avatars/{new_filename}"}, HTTPStatus.OK

def show(label, result):
    body, status = result
    print(f"  {label}")
    print(f"    {status.value} {status.phrase}  ->  {body}")
    print()',
    demo = 'print("=== UserAvatarUploadResource Demo ===\n")

show("PUT /users/avatar (valid jpg)",       put_avatar(1, "photo.jpg"))
show("PUT /users/avatar (update: new png)", put_avatar(1, "selfie.png"))
show("PUT /users/avatar (invalid exe)",     put_avatar(1, "virus.exe"))
show("PUT /users/avatar (no file)",         put_avatar(1, ""))
show("PUT /users/avatar (unknown user)",    put_avatar(99, "photo.jpg"))

print(f"  Final user state: {users[1]}")'
  ),

  list(
    name = "image_compression.py",
    description = "<strong>image_compression.py</strong> — Exercise 48: <code>compress_image()</code> using Pillow. Converts to RGB, resizes if over 1600px, saves as JPEG at quality=85, reports size reduction. Demonstrated with a synthetic in-memory image.",
    code = 'print("=== Image Compression with Pillow ===\n")

try:
    from PIL import Image
    import io

    def compress_image_demo(width, height, mode="RGB"):
        img = Image.new(mode, (width, height), color=(180, 100, 60))
        if img.mode != "RGB":
            img = img.convert("RGB")
            print(f"  Converted {mode} -> RGB")
        original_bytes = io.BytesIO()
        img.save(original_bytes, format="PNG")
        original_size = len(original_bytes.getvalue())
        if max(img.width, img.height) > 1600:
            maxsize = (1600, 1600)
            img.thumbnail(maxsize)
            print(f"  Resized: {width}x{height} -> {img.width}x{img.height}")
        compressed_bytes = io.BytesIO()
        img.save(compressed_bytes, format="JPEG", optimize=True, quality=85)
        compressed_size = len(compressed_bytes.getvalue())
        reduction = round((original_size - compressed_size) / original_size * 100) if original_size > 0 else 0
        return {
            "original_size":   original_size,
            "compressed_size": compressed_size,
            "reduction_pct":   reduction,
            "final_dims":      f"{img.width}x{img.height}",
        }

    print("  Case 1: Normal 800x600 RGB image")
    r = compress_image_demo(800, 600)
    print(f"    Original  : {r[\"original_size\"]:,} bytes")
    print(f"    Compressed: {r[\"compressed_size\"]:,} bytes  ({r[\"reduction_pct\"]}% smaller)")
    print(f"    Dimensions: {r[\"final_dims\"]}\n")

    print("  Case 2: Oversized 3000x2000 image (needs resize)")
    r2 = compress_image_demo(3000, 2000)
    print(f"    Original  : {r2[\"original_size\"]:,} bytes")
    print(f"    Compressed: {r2[\"compressed_size\"]:,} bytes  ({r2[\"reduction_pct\"]}% smaller)")
    print(f"    Dimensions: {r2[\"final_dims\"]}\n")

    print("  Case 3: RGBA image (needs RGB conversion)")
    r3 = compress_image_demo(400, 300, mode="RGBA")
    print(f"    Original  : {r3[\"original_size\"]:,} bytes")
    print(f"    Compressed: {r3[\"compressed_size\"]:,} bytes  ({r3[\"reduction_pct\"]}% smaller)")
    print(f"    Dimensions: {r3[\"final_dims\"]}")

except ImportError:
    print("  Pillow not installed in this environment.")
    print()
    print("  compress_image() logic from the book (utils.py):")
    steps = [
        "1. Open uploaded file with Image.open(file_path)",
        "2. If mode != RGB: convert to RGB (handles PNG with alpha channel)",
        "3. If max(width, height) > 1600: thumbnail((1600, 1600))",
        "4. Save as .jpg with optimize=True, quality=85",
        "5. Compute size reduction % and print it",
        "6. Delete the original file; return compressed UUID filename",
    ]
    for s in steps:
        print(f"     {s}")',
    demo = NULL
  ),

  list(
    name = "save_image_util.py",
    description = "<strong>save_image_util.py</strong> — Activity 11: the complete <code>save_image()</code> utility. Combines UUID filename generation, Flask-Uploads save, and <code>compress_image()</code> into one pipeline call.",
    code = 'import os, uuid

print("=== save_image() Full Pipeline ===\n")

save_image_code = """
# utils.py -- Activity 11 complete version

import uuid
from PIL import Image
from flask_uploads import extension
from extensions import image_set

def save_image(image, folder):
    # 1. UUID filename prevents path traversal + collisions
    filename = "{}.{}".format(uuid.uuid4(), extension(image.filename))

    # 2. Save via Flask-Uploads (uses configured UPLOADED_IMAGES_DEST)
    image_set.save(image, folder=folder, name=filename)

    # 3. Compress in-place and return new compressed filename
    filename = compress_image(filename=filename, folder=folder)
    return filename

def compress_image(filename, folder):
    file_path = image_set.path(filename=filename, folder=folder)
    image     = Image.open(file_path)

    if image.mode != "RGB":
        image = image.convert("RGB")

    if max(image.width, image.height) > 1600:
        image.thumbnail((1600, 1600))

    compressed_filename = "{}.jpg".format(uuid.uuid4())
    compressed_path     = image_set.path(filename=compressed_filename, folder=folder)

    image.save(compressed_path, optimize=True, quality=85)

    original_size   = os.stat(file_path).st_size
    compressed_size = os.stat(compressed_path).st_size
    percentage      = round((original_size - compressed_size) / original_size * 100)

    print("The file size is reduced by {}%, from {} to {}.".format(
        percentage, original_size, compressed_size))

    os.remove(file_path)       # delete original; keep compressed only
    return compressed_filename
"""
print(save_image_code)

print("=== Chapter 7 new endpoints ===\n")
endpoints = [
    ("PUT", "/users/avatar",          "Upload or replace user avatar"),
    ("PUT", "/recipes/<id>/cover",    "Upload or replace recipe cover image"),
]
print("  %-8s %-32s %s" % ("Method", "URL", "Description"))
print("  " + "-" * 60)
for m, u, d in endpoints:
    print(f"  {m:<8} {u:<32} {d}")',
    demo = NULL
  )
)

# ── Chapter 7 UI ──────────────────────────────────────────────
chapter7_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(7, "\U0001f5bc\ufe0f", "Working with Images",
      "Add avatar and recipe cover image upload to Smilecook. Use Flask-Uploads for multipart handling, Pillow to resize and compress, UUID filenames for security, and serve images via static URLs.",
      c("Flask-Uploads", "Pillow", "UploadSet", "UUID filenames", "compress_image", "avatar_image", "cover_image")),

    stats_row(
      list("10 MB",  "Max Upload"),
      list("1600px", "Max Dimension"),
      list("85",     "JPEG Quality"),
      list("UUID",   "Filename Strategy")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),

        tabPanel(title = tagList(icon("book"), " Theory"),

          fluidRow(
            box(title = "\U0001f4e4 Flask-Uploads", status = "info", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                tags$h5("What is Flask-Uploads?"),
                tags$p("Flask-Uploads manages file uploads, validates allowed extensions, and handles save destinations. It wraps Werkzeug file handling into a clean API."),
                tags$ul(
                  tags$li(tags$strong("UploadSet"), " — groups file types (e.g. IMAGES)"),
                  tags$li(tags$strong("configure_uploads()"), " — binds the UploadSet to the app"),
                  tags$li(tags$strong("patch_request_class()"), " — enforces 10 MB max"),
                  tags$li(tags$strong("image_set.save()"), " — saves with configured folder"),
                  tags$li(tags$strong("image_set.path()"), " — returns full filesystem path"),
                  tags$li(tags$strong("image_set.url()"), " — returns public URL")
                )
              ),
              div(class = "framework-card",
                tags$h5("Setup"),
                tags$pre(class = "code-inline",
"# extensions.py
from flask_uploads import UploadSet, IMAGES
image_set = UploadSet(\"images\", IMAGES)

# app.py
configure_uploads(app, image_set)
patch_request_class(app, 10 * 1024 * 1024)")
              )
            ),

            box(title = "\U0001f5bc\ufe0f Pillow: Image Compression", status = "warning", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                tags$h5("compress_image() Pipeline"),
                tags$ol(
                  tags$li("Open with ", tags$code("Image.open()")),
                  tags$li("Convert to RGB if needed (handles PNG alpha)"),
                  tags$li("If max dimension > 1600px: ", tags$code("thumbnail((1600,1600))")),
                  tags$li("Save as JPEG: ", tags$code("optimize=True, quality=85")),
                  tags$li("Delete original; return compressed UUID filename")
                )
              ),
              div(class = "tip-box",
                HTML("<strong>\U0001f4a1 thumbnail() vs resize():</strong> <code>thumbnail()</code> preserves aspect ratio and only scales <em>down</em> — never enlarges the image."))
            )
          ),

          fluidRow(
            box(title = "\U0001f510 Security: UUID Filenames", status = "success", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                tags$h5("Why UUID filenames?"),
                tags$p("Never trust user-supplied filenames. Attackers can upload:"),
                tags$ul(
                  tags$li(tags$code("../../etc/passwd"), " -- path traversal"),
                  tags$li(tags$code("script.php.jpg"), " -- double extension bypass"),
                  tags$li(tags$code("shell.py"), " -- code execution if served")
                ),
                tags$pre(class = "code-inline",
"import uuid
from flask_uploads import extension

filename = \"{}.{}\".format(
    uuid.uuid4(),              # unguessable
    extension(image.filename)  # only the extension
)")
              ),
              div(class = "success-box",
                HTML("<strong>\u2705 UUID filenames</strong> prevent path traversal, collisions, and enumeration. The original filename is never stored."))
            ),

            box(title = "\U0001f504 Avatar Upload Workflow", status = "danger", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                tags$h5("PUT /users/avatar"),
                tags$ol(
                  tags$li("Client sends ", tags$code("multipart/form-data"), " field ", tags$code("avatar")),
                  tags$li("Check file exists: 400 if missing"),
                  tags$li("Validate extension against IMAGES: 400 if disallowed"),
                  tags$li("Load user via JWT identity"),
                  tags$li("If user has old avatar: delete from disk"),
                  tags$li(tags$code("save_image(file, folder=\"avatars\")")),
                  tags$li("Save new filename to DB"),
                  tags$li("Return ", tags$code("{\"avatar_url\": \"...\"}"), " 200 OK")
                )
              ),
              div(class = "tip-box",
                HTML("<strong>\U0001f4a1 Content-Type:</strong> Image uploads use <code>multipart/form-data</code> not JSON. Use Postman's <strong>form-data</strong> tab."))
            )
          )
        ),

        tabPanel(title = tagList(icon("code"), " Code Lab"),
          code_lab_header(
            "Chapter 7 \u2014 Working with Images",
            "Flask-Uploads setup, avatar upload resource, Pillow image compression, and the full save_image() pipeline."
          ),
          file_pills_ui(ns, CH07_FILES),
          py_code_display(ns),
          terminal_ui(ns)
        )
      )
    )
  )
}

chapter7_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    code_lab_server(input, output, session, CH07_FILES)
  })
}
