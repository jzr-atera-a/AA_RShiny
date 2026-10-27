# R/utils_infographic_render.R
# ============================================================
# INFOGRAPHIC STUDIO - renderer
# ============================================================
# The Editing Tool only supplies a JSON spec (sections of a fixed set of block
# types, icon NAMES from a whitelist, numbers and text). ALL drawing happens
# here: one tall self-contained SVG (so PDF / HTML / JPEG / GIF / PNG exports
# all start from exactly the same picture). Everything is original geometry.

IG_W <- 900
IG_M <- 48
IG_CW <- IG_W - 2 * IG_M
IG_FONT <- "'Segoe UI','Helvetica Neue',Helvetica,Arial,sans-serif"

IG_THEMES <- list(
  midnight = list(label = "Midnight", hero_from = "#0B1220", hero_to = "#1E3A5F", hero_ink = "#F8FAFC",
                  bandA = "#1B2535", bandB = "#223048", ink = "#F1F5F9", muted = "#A9B8CC", panel = "#2B3B55", panel_line = "#3E5173",
                  track = "#3A4B66", line = "#6F93C4", accents = c("#FBBF24", "#38BDF8", "#A78BFA", "#34D399")),
  sky = list(label = "Sky", hero_from = "#0B2A4A", hero_to = "#1D6FB8", hero_ink = "#FFFFFF",
             bandA = "#E6F3FC", bandB = "#D3EAF9", ink = "#0F2A43", muted = "#4A6783", panel = "#FFFFFF", panel_line = "#B9D6EE",
             track = "#BFD9EE", line = "#FFFFFF", accents = c("#1D8FE1", "#F97316", "#0EA5A4", "#7C3AED")),
  sunrise = list(label = "Sunrise", hero_from = "#7C2D12", hero_to = "#EA580C", hero_ink = "#FFFFFF",
                 bandA = "#FFF6E5", bandB = "#FFEBC7", ink = "#3B2412", muted = "#7A5A3C", panel = "#FFFFFF", panel_line = "#F3D9A8",
                 track = "#F1DDB4", line = "#FFFFFF", accents = c("#F59E0B", "#E11D48", "#0284C7", "#16A34A")),
  forest = list(label = "Forest", hero_from = "#052E22", hero_to = "#0F766E", hero_ink = "#FFFFFF",
                bandA = "#EAF8F0", bandB = "#D9F0E3", ink = "#0F3D2E", muted = "#4B6F61", panel = "#FFFFFF", panel_line = "#B7E0C8",
                track = "#BFE3CE", line = "#FFFFFF", accents = c("#16A34A", "#F59E0B", "#0284C7", "#9333EA")),
  berry = list(label = "Berry", hero_from = "#3B0764", hero_to = "#BE185D", hero_ink = "#FFFFFF",
               bandA = "#FDF1F8", bandB = "#FBE3F1", ink = "#3B0A2A", muted = "#7F4A68", panel = "#FFFFFF", panel_line = "#F3C3DD",
               track = "#F2CCE1", line = "#FFFFFF", accents = c("#DB2777", "#7C3AED", "#0891B2", "#F59E0B")),
  paper = list(label = "Paper (print)", hero_from = "#111827", hero_to = "#374151", hero_ink = "#FFFFFF",
               bandA = "#FFFFFF", bandB = "#F3F4F6", ink = "#111827", muted = "#4B5563", panel = "#FFFFFF", panel_line = "#D1D5DB",
               track = "#E5E7EB", line = "#D1D5DB", accents = c("#111827", "#2563EB", "#DC2626", "#6B7280"))
)
IG_THEME_CHOICES <- c(setNames(names(IG_THEMES), vapply(IG_THEMES, function(t) t$label, "")), "Your brand colours (set below)" = "custom")

# ---- small helpers ---------------------------------------------------------
ig_n <- function(x) formatC(x, format = "f", digits = 1)
ig_e <- function(x) htmltools::htmlEscape(as.character(if (is.null(x) || length(x) == 0) "" else x[[1]]))
ig_num <- function(x, default = 0) {
  v <- suppressWarnings(as.numeric(gsub("[^0-9.\\-]", "", as.character(x %||% ""))))
  if (length(v) == 0 || is.na(v)) default else v
}
ig_rgb <- function(hex) as.numeric(grDevices::col2rgb(hex)) / 255
ig_lum <- function(hex) { v <- ig_rgb(hex); 0.2126 * v[1] + 0.7152 * v[2] + 0.0722 * v[3] }
ig_on <- function(hex) if (ig_lum(hex) > 0.6) "#0F172A" else "#FFFFFF"
ig_mix <- function(a, b, t) { x <- ig_rgb(a) * (1 - t) + ig_rgb(b) * t; grDevices::rgb(x[1], x[2], x[3]) }
ig_acc <- function(th, i) th$accents[((i - 1) %% length(th$accents)) + 1]

ig_wrap <- function(text, px, fs, bold = FALSE, max_lines = 6) {
  text <- trimws(as.character(if (is.null(text) || length(text) == 0) "" else text[[1]]))
  if (!nzchar(text)) return(character(0))
  w <- max(4, floor(px / (fs * if (bold) 0.585 else 0.545)))
  l <- strwrap(text, width = w)
  if (length(l) > max_lines) { l <- l[seq_len(max_lines)]; l[max_lines] <- paste0(sub("\\s+\\S*$", "", l[max_lines]), "...") }
  l
}
# text lines -> list(svg, h); y = TOP of the first line
ig_text <- function(x, y, lines, fs, fill, weight = 400, anchor = "start", lh = NULL, italic = FALSE, ls = 0, opacity = 1) {
  if (length(lines) == 0) return(list(svg = "", h = 0))
  lh <- lh %||% fs * 1.32
  svg <- vapply(seq_along(lines), function(i) sprintf(
    '<text x="%s" y="%s" font-size="%s" font-weight="%s" fill="%s" text-anchor="%s"%s%s%s>%s</text>',
    ig_n(x), ig_n(y + fs + (i - 1) * lh), ig_n(fs), weight, fill, anchor,
    if (italic) ' font-style="italic"' else "", if (ls != 0) sprintf(' letter-spacing="%s"', ig_n(ls)) else "",
    if (opacity < 1) sprintf(' fill-opacity="%s"', opacity) else "", ig_e(lines[i])), character(1))
  list(svg = paste(svg, collapse = ""), h = lh * (length(lines) - 1) + fs * 1.25)
}
ig_rect <- function(x, y, w, h, fill, rx = 0, stroke = NULL, sw = 1, extra = "") {
  sprintf('<rect x="%s" y="%s" width="%s" height="%s" rx="%s" fill="%s"%s%s/>', ig_n(x), ig_n(y), ig_n(w), ig_n(h), ig_n(rx), fill,
          if (!is.null(stroke)) sprintf(' stroke="%s" stroke-width="%s"', stroke, sw) else "", extra)
}
ig_circle <- function(cx, cy, r, fill = "none", stroke = NULL, sw = 1, extra = "") {
  sprintf('<circle cx="%s" cy="%s" r="%s" fill="%s"%s%s/>', ig_n(cx), ig_n(cy), ig_n(r), fill,
          if (!is.null(stroke)) sprintf(' stroke="%s" stroke-width="%s"', stroke, sw) else "", extra)
}
ig_line <- function(x1, y1, x2, y2, col, sw = 2, extra = "") {
  sprintf('<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s" stroke-linecap="round"%s/>', ig_n(x1), ig_n(y1), ig_n(x2), ig_n(y2), col, sw, extra)
}
ig_arc <- function(cx, cy, r0, r1, a0, a1) {
  pt <- function(r, a) c(cx + r * cos(a), cy + r * sin(a))
  p0 <- pt(r1, a0); p1 <- pt(r1, a1); q1 <- pt(r0, a1); q0 <- pt(r0, a0)
  large <- if (a1 - a0 > pi) 1 else 0
  sprintf("M%s %s A%s %s 0 %d 1 %s %s L%s %s A%s %s 0 %d 0 %s %s Z", ig_n(p0[1]), ig_n(p0[2]), ig_n(r1), ig_n(r1), large, ig_n(p1[1]), ig_n(p1[2]),
          ig_n(q1[1]), ig_n(q1[2]), ig_n(r0), ig_n(r0), large, ig_n(q0[1]), ig_n(q0[2]))
}

# ---- icon library (original geometry, 24 x 24 grid) -------------------------
ig_gear_teeth <- function() paste0(vapply(seq(0, 7), function(i) {
  a <- i * pi / 4; sprintf('<path d="M%s %sL%s %s"/>', ig_n(12 + 7 * cos(a)), ig_n(12 + 7 * sin(a)), ig_n(12 + 9.6 * cos(a)), ig_n(12 + 9.6 * sin(a)))
}, character(1)), collapse = "")
ig_sun_rays <- function() paste0(vapply(seq(0, 7), function(i) {
  a <- i * pi / 4; sprintf('<path d="M%s %sL%s %s"/>', ig_n(12 + 6.6 * cos(a)), ig_n(12 + 6.6 * sin(a)), ig_n(12 + 9.4 * cos(a)), ig_n(12 + 9.4 * sin(a)))
}, character(1)), collapse = "")
IG_ICONS <- list(
  user = '<circle cx="12" cy="8" r="4"/><path d="M4 21c0-4.4 3.6-7 8-7s8 2.6 8 7z"/>',
  users = '<circle cx="9" cy="8" r="3.2"/><path d="M3 20c0-3.5 2.7-5.6 6-5.6s6 2.1 6 5.6z"/><circle cx="17" cy="9" r="2.6"/><path d="M16 14.4c3 0 5.4 1.8 5.4 5"/>',
  globe = '<circle cx="12" cy="12" r="9"/><ellipse cx="12" cy="12" rx="4" ry="9"/><path d="M3 12h18M5 7.5h14M5 16.5h14"/>',
  chart_up = '<path d="M3 17l6-6 4 4 8-9"/><path d="M15 6h6v6"/>',
  chart_bar = '<rect x="4" y="12" width="4" height="8" rx="1"/><rect x="10" y="5" width="4" height="15" rx="1"/><rect x="16" y="9" width="4" height="11" rx="1"/>',
  chart_pie = '<path d="M12 3a9 9 0 1 0 9 9h-9z"/><path d="M15 3.4A9 9 0 0 1 20.6 9H15z"/>',
  dollar = '<circle cx="12" cy="12" r="9"/><path d="M14.5 9c-.4-1.1-1.4-1.7-2.6-1.7-1.5 0-2.6.8-2.6 2 0 3 5.4 1.5 5.4 4.5 0 1.2-1.2 2-2.8 2-1.3 0-2.4-.7-2.8-1.8M12 5.5v1.8M12 16.7v1.8"/>',
  coin = '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5.5"/>',
  bank = '<path d="M3 9l9-5 9 5zM5 9v9M9.5 9v9M14.5 9v9M19 9v9M3 21h18"/>',
  lightbulb = '<path d="M9 18h6M10 21h4M12 3a6 6 0 0 0-3.5 10.9c.6.5 1 1.2 1 2.1h5c0-.9.4-1.6 1-2.1A6 6 0 0 0 12 3z"/>',
  shield = '<path d="M12 3l8 3v6c0 5-3.4 8.2-8 9.5C7.4 20.2 4 17 4 12V6z"/><path d="M8.5 12l2.5 2.5 4.5-5"/>',
  lock = '<rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>',
  heart = '<path d="M12 20s-8-4.8-8-10.5A4.5 4.5 0 0 1 12 7a4.5 4.5 0 0 1 8 2.5C20 15.2 12 20 12 20z"/>',
  pulse = '<path d="M2 12h5l2-6 4 12 3-6h6"/>',
  medical = '<path d="M9 3h6v6h6v6h-6v6H9v-6H3V9h6z"/>',
  star = '<path d="M12 3l2.8 6 6.2.7-4.6 4.3 1.3 6.5-5.7-3.3-5.7 3.3 1.3-6.5L3 9.7 9.2 9z"/>',
  clock = '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l4 2"/>',
  hourglass = '<path d="M7 3h10M7 21h10M8 3c0 5 4 5 4 9s-4 4-4 9M16 3c0 5-4 5-4 9s4 4 4 9"/>',
  calendar = '<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 10h18M8 3v4M16 3v4"/>',
  cloud = '<path d="M7 18a4.5 4.5 0 0 1-.6-8.9A6 6 0 0 1 18 9.5 4 4 0 0 1 17.5 18z"/>',
  database = '<ellipse cx="12" cy="6" rx="7" ry="3"/><path d="M5 6v12c0 1.7 3.1 3 7 3s7-1.3 7-3V6M5 12c0 1.7 3.1 3 7 3s7-1.3 7-3"/>',
  server = '<rect x="3" y="4" width="18" height="6" rx="1.5"/><rect x="3" y="14" width="18" height="6" rx="1.5"/><circle cx="7" cy="7" r=".9" fill="currentColor" stroke="none"/><circle cx="7" cy="17" r=".9" fill="currentColor" stroke="none"/>',
  chip = '<rect x="7" y="7" width="10" height="10" rx="1.5"/><path d="M9 3v4M15 3v4M9 17v4M15 17v4M3 9h4M3 15h4M17 9h4M17 15h4"/>',
  phone = '<rect x="7" y="2" width="10" height="20" rx="2.5"/><path d="M11 18.5h2"/>',
  laptop = '<rect x="4" y="5" width="16" height="11" rx="1.5"/><path d="M2 20h20"/>',
  wifi = '<path d="M2 9a15 15 0 0 1 20 0M5 12.5a10.5 10.5 0 0 1 14 0M8.5 16a5.5 5.5 0 0 1 7 0"/><circle cx="12" cy="19.5" r="1" fill="currentColor" stroke="none"/>',
  network = '<circle cx="12" cy="5" r="2.5"/><circle cx="5" cy="19" r="2.5"/><circle cx="19" cy="19" r="2.5"/><path d="M11 7.3L6 16.7M13 7.3l5 9.4M7.5 19h9"/>',
  mail = '<rect x="3" y="5" width="18" height="14" rx="2"/><path d="M3 7l9 6 9-6"/>',
  building = '<rect x="5" y="3" width="10" height="18"/><path d="M15 9h5v12h-5M8 7h4M8 11h4M8 15h4"/>',
  factory = '<path d="M3 21V10l6 4v-4l6 4V6h4v15z"/>',
  home = '<path d="M3 11l9-8 9 8M5 10v10h14V10M10 20v-6h4v6"/>',
  briefcase = '<rect x="3" y="7" width="18" height="13" rx="2"/><path d="M9 7V5a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2M3 13h18"/>',
  graduation = '<path d="M12 4l10 5-10 5L2 9z"/><path d="M6 11.5V16c3 2.5 9 2.5 12 0v-4.5M22 9v6"/>',
  book = '<path d="M4 5c3-1 6-1 8 1 2-2 5-2 8-1v14c-3-1-6-1-8 1-2-2-5-2-8-1zM12 6v14"/>',
  leaf = '<path d="M5 19C5 10 10 5 20 4c0 10-5 15-14 15zM5 19c2-5 5-8 9-10"/>',
  droplet = '<path d="M12 3s6 6.5 6 11a6 6 0 0 1-12 0c0-4.5 6-11 6-11z"/>',
  bolt = '<path d="M13 2L4 14h7l-1 8 10-13h-7z"/>',
  sun = '<circle cx="12" cy="12" r="4"/>',
  gear = '<circle cx="12" cy="12" r="3"/><circle cx="12" cy="12" r="6.5"/>',
  search = '<circle cx="10.5" cy="10.5" r="6.5"/><path d="M15.5 15.5L21 21"/>',
  eye = '<path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>',
  target = '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1.5" fill="currentColor"/>',
  compass = '<circle cx="12" cy="12" r="9"/><path d="M15.5 8.5l-2 5-5 2 2-5z"/>',
  flag = '<path d="M5 21V4M5 4h12l-2 4 2 4H5"/>',
  pin = '<path d="M12 21s7-6.2 7-11.5A7 7 0 0 0 5 9.5C5 14.8 12 21 12 21z"/><circle cx="12" cy="9.5" r="2.5"/>',
  trophy = '<path d="M7 4h10v5a5 5 0 0 1-10 0zM7 6H4a3 3 0 0 0 3 4M17 6h3a3 3 0 0 1-3 4M12 14v4M8 21h8"/>',
  check = '<path d="M5 12.5l5 5L19 7"/>',
  cross = '<path d="M6 6l12 12M18 6L6 18"/>',
  plus = '<path d="M12 5v14M5 12h14"/>',
  minus = '<path d="M5 12h14"/>',
  warning = '<path d="M12 3l10 18H2z"/><path d="M12 10v5"/><circle cx="12" cy="18.2" r=".9" fill="currentColor" stroke="none"/>',
  scale = '<path d="M12 4v16M6 20h12M4 8h16M4 8l-3 7a3 3 0 0 0 6 0zM20 8l-3 7a3 3 0 0 0 6 0z"/>',
  cart = '<path d="M3 4h3l2.5 11h10l2-8H7"/><circle cx="10" cy="19.5" r="1.4"/><circle cx="17" cy="19.5" r="1.4"/>',
  car = '<path d="M4 15l2-6h12l2 6"/><rect x="3" y="15" width="18" height="4" rx="1.5"/><circle cx="7.5" cy="19" r="1.5"/><circle cx="16.5" cy="19" r="1.5"/>',
  truck = '<rect x="2" y="7" width="11" height="9"/><path d="M13 10h4l4 3v3h-8z"/><circle cx="7" cy="18" r="2"/><circle cx="17" cy="18" r="2"/>',
  plane = '<path d="M21 3L10 14M21 3l-7 18-4-7-7-4z"/>'
)
IG_ICONS$gear <- paste0(IG_ICONS$gear, ig_gear_teeth())
IG_ICONS$sun <- paste0(IG_ICONS$sun, ig_sun_rays())
IG_ICON_NAMES <- names(IG_ICONS)
IG_ICON_SYN <- c(money = "dollar", cash = "dollar", finance = "bank", price = "coin", cost = "coin", people = "users", person = "user", population = "users",
                 growth = "chart_up", trend = "chart_up", increase = "chart_up", chart = "chart_bar", stats = "chart_bar", data = "database", storage = "database",
                 security = "shield", privacy = "lock", safe = "shield", energy = "bolt", power = "bolt", electricity = "bolt", health = "pulse", hospital = "medical",
                 idea = "lightbulb", innovation = "lightbulb", time = "clock", mobile = "phone", smartphone = "phone", computer = "laptop", internet = "wifi",
                 web = "globe", world = "globe", earth = "globe", city = "building", office = "building", industry = "factory", education = "graduation",
                 school = "graduation", science = "search", research = "search", nature = "leaf", environment = "leaf", water = "droplet", climate = "sun",
                 goal = "target", win = "trophy", location = "pin", map = "pin", shopping = "cart", retail = "cart", transport = "truck", vehicle = "car",
                 travel = "plane", law = "scale", justice = "scale", ai = "chip", technology = "chip", cpu = "chip", software = "laptop", message = "mail",
                 email = "mail", yes = "check", no = "cross", good = "plus", bad = "minus", risk = "warning", alert = "warning", love = "heart", like = "heart")
ig_icon_name <- function(name) {
  n <- tolower(gsub("[^a-z_]", "", gsub("[- ]", "_", tolower(as.character(if (is.null(name) || length(name) == 0) "" else name[[1]])))))
  if (n %in% IG_ICON_NAMES) return(n)
  if (n %in% names(IG_ICON_SYN)) return(IG_ICON_SYN[[n]])
  "star"
}
ig_icon <- function(name, cx, cy, size, col, filled = FALSE, sw = 1.9) {
  g <- IG_ICONS[[ig_icon_name(name)]]
  sprintf('<g transform="translate(%s %s) scale(%s)" color="%s" fill="%s" stroke="currentColor" stroke-width="%s" stroke-linecap="round" stroke-linejoin="round">%s</g>',
          ig_n(cx - size / 2), ig_n(cy - size / 2), ig_n(size / 24), col, if (filled) "currentColor" else "none", sw, g)
}
ig_badge <- function(cx, cy, r, col, name, ring = TRUE, ring_col = NULL) {
  paste0(if (ring) ig_circle(cx, cy, r + 6, "none", ring_col %||% col, 2.4, ' stroke-opacity="0.4"') else "",
         ig_circle(cx, cy, r, col), ig_icon(name, cx, cy, r * 1.12, ig_on(col)))
}

# ---- evidence marker for statistics ----------------------------------------
ig_item_status <- function(it) {
  conf <- tolower(as.character(it$confidence %||% ""))
  if (!nzchar(conf)) return("")
  ver <- tolower(as.character(it$verified %||% "unchecked"))
  if (conf == "judgment") "judgment" else if (conf == "applicant") "applicant" else if (ver == "yes") "verified" else if (ver == "no") "contradicted" else "unverified"
}
IG_STATUS_COL <- c(verified = "#16A34A", unverified = "#F59E0B", contradicted = "#DC2626", judgment = "#94A3B8", applicant = "#2F4F9E")
# one status dot: hollow ring (judgment), diamond (supplied by the applicant) or filled dot
ig_status_dot <- function(st, x, y, r = 4.4) {
  if (st == "judgment") ig_circle(x, y, r - 0.4, "#FFFFFF", IG_STATUS_COL[["judgment"]], 1.4, ' fill-opacity="0.85"')
  else if (st == "applicant") sprintf('<rect x="%s" y="%s" width="%s" height="%s" fill="%s" stroke="#FFFFFF" stroke-width="1.1" transform="rotate(45 %s %s)"/>', ig_n(x - r * 0.85), ig_n(y - r * 0.85), ig_n(r * 1.7), ig_n(r * 1.7), IG_STATUS_COL[["applicant"]], ig_n(x), ig_n(y))
  else ig_circle(x, y, r, IG_STATUS_COL[[st]], "#FFFFFF", 1.2)
}
ig_marker <- function(it, x, y) {
  st <- ig_item_status(it); if (!nzchar(st)) return("")
  ig_status_dot(st, x, y)
}
ig_tip <- function(it, label = "") {
  src <- paste(unlist(it$source_ids), collapse = ", ")
  tip <- paste(Filter(nzchar, c(label, as.character(it$metric %||% ""), as.character(it$as_of %||% ""),
                                if (nzchar(as.character(it$quote %||% ""))) paste0("\"", it$quote, "\"") else "",
                                if (nzchar(src)) paste0("Source: ", src) else "", ig_item_status(it))), collapse = " | ")
  if (nzchar(tip)) sprintf("<title>%s</title>", ig_e(tip)) else ""
}
ig_items <- function(sec, max_n) { it <- sec$items %||% list(); if (length(it) > max_n) it <- it[seq_len(max_n)]; Filter(is.list, it) }
ig_fmt_value <- function(it) {
  v <- as.character(it$display %||% it$value %||% "")
  if (!nzchar(v)) "-" else v
}

# small label for items that are targets, placeholders to fill in, or self-assessed
IG_TAGS <- c(target = "TARGET", insert = "INSERT", estimate = "SELF-ASSESSED")
ig_tag_id <- function(x) { x <- tolower(trimws(as.character(if (is.null(x) || length(x) == 0) "" else x[[1]]))); x <- sub("^(placeholder|to_fill|todo)$", "insert", x); x <- sub("^(self_assessed|self-assessed|assumed|proposed)$", "estimate", x); if (x %in% names(IG_TAGS)) x else "" }
ig_tag_chip <- function(x, y, tag, th, anchor = "start") {
  tg <- ig_tag_id(tag); if (!nzchar(tg)) return(list(svg = "", w = 0, h = 0))
  lab <- IG_TAGS[[tg]]; w <- nchar(lab) * 6.6 + 14; col <- ig_acc(th, c(target = 1, insert = 3, estimate = 2)[[tg]]); x0 <- if (anchor == "end") x - w else if (anchor == "middle") x - w / 2 else x
  list(svg = paste0(ig_rect(x0, y, w, 17, "none", 8.5, col, 1.3, ' stroke-dasharray="3 2"'), ig_text(x0 + w / 2, y + 2.5, lab, 9.5, col, 800, "middle", ls = 0.8)$svg), w = w, h = 17)
}

# ============================================================
# BLOCKS: function(sec, th, y) -> list(svg, h)   (y = top of the body area)
# ============================================================

ig_block_stat_row <- function(sec, th, y) {
  its <- ig_items(sec, 4); n <- length(its); if (n == 0) return(list(svg = "", h = 0))
  colw <- IG_CW / n; out <- character(0); hmax <- 0
  for (i in seq_len(n)) {
    it <- its[[i]]; x <- IG_M + (i - 1) * colw; col <- ig_acc(th, i); yy <- y
    inner <- character(0)
    if (nzchar(as.character(it$icon %||% ""))) { inner <- c(inner, ig_badge(x + 26, yy + 26, 22, col, it$icon)); yy <- yy + 62 }
    vtxt <- ig_fmt_value(it); fsv <- min(if (n >= 4) 44 else 54, max(22, floor((colw - 22) / (0.6 * max(3, nchar(vtxt))))))
    vt <- ig_text(x, yy, vtxt, fsv, if (ig_tag_id(it$tag) == "insert") th$muted else col, 800, lh = fsv * 1.27)
    inner <- c(inner, vt$svg); yy <- yy + vt$h + 6
    tg <- ig_tag_chip(x, yy, it$tag, th); if (tg$h > 0) { inner <- c(inner, tg$svg); yy <- yy + tg$h + 8 }
    bar <- ig_num(it$bar, NA)
    if (!is.na(bar)) {
      bw <- colw - 36
      inner <- c(inner, ig_rect(x, yy, bw, 11, th$track, 5.5), ig_rect(x, yy, max(8, bw * min(100, max(0, bar)) / 100), 11, col, 5.5)); yy <- yy + 24
    }
    lt <- ig_text(x, yy, ig_wrap(it$label, colw - 30, 15.5, TRUE, 3), 15.5, th$ink, 700); inner <- c(inner, lt$svg); yy <- yy + lt$h + 4
    nt <- ig_text(x, yy, ig_wrap(it$note, colw - 30, 12.5, FALSE, 5), 12.5, th$muted, 400); inner <- c(inner, nt$svg); yy <- yy + nt$h
    src <- paste(unlist(it$source_ids), collapse = ",")
    if (nzchar(src)) { inner <- c(inner, ig_text(x + 12, yy + 4, paste0("Source ", src), 10.5, th$muted, 400)$svg, ig_marker(it, x + 3, yy + 12)); yy <- yy + 20 }
    out <- c(out, sprintf("<g>%s%s</g>", ig_tip(it, as.character(it$label %||% "")), paste(inner, collapse = "")))
    hmax <- max(hmax, yy - y)
  }
  list(svg = paste(out, collapse = ""), h = hmax)
}

ig_block_donut <- function(sec, th, y) {
  its <- ig_items(sec, 6); vals <- vapply(its, function(it) max(0, ig_num(it$value)), 0)
  if (length(its) == 0 || sum(vals) <= 0) return(list(svg = "", h = 0))
  r1 <- min(112, max(50, IG_CW * 0.155)); r0 <- r1 * 0.59; cx <- IG_M + r1 + 22; cy <- y + r1 + 18; tot <- sum(vals); a <- -pi / 2; out <- character(0)
  for (i in seq_along(its)) {
    a1 <- a + 2 * pi * vals[i] / tot
    if (vals[i] / tot > 0.9999) out <- c(out, sprintf('<path d="%s" fill="%s" fill-rule="evenodd"/>', paste0(ig_arc(cx, cy, r0, r1, 0, pi), ig_arc(cx, cy, r0, r1, pi, 2 * pi)), ig_acc(th, i)))
    else if (vals[i] > 0) out <- c(out, sprintf('<path d="%s" fill="%s" stroke="%s" stroke-width="3">%s</path>', ig_arc(cx, cy, r0, r1, a, a1), ig_acc(th, i), th$bandA, ig_tip(its[[i]], as.character(its[[i]]$label %||% ""))))
    a <- a1
  }
  cv <- as.character(sec$center_value %||% ""); cl <- as.character(sec$center_label %||% ""); k <- r1 / 112
  if (nzchar(cv)) out <- c(out, ig_text(cx, cy - 22 * k, cv, max(20, 34 * k), th$ink, 800, "middle")$svg, ig_text(cx, cy + 14 * k, ig_wrap(cl, 2 * r0 - 16, max(10, 12 * k), FALSE, 2), max(10, 12 * k), th$muted, 400, "middle")$svg)
  lx <- cx + r1 + 36; ly <- y + 22; lw <- max(80, IG_W - IG_M - lx - 30 - 62); two <- lw < 200; rowh <- if (two) 44 else 40
  for (i in seq_along(its)) {
    it <- its[[i]]; yy <- ly + (i - 1) * rowh
    pct <- sprintf("%d%%", round(100 * vals[i] / tot))
    out <- c(out, ig_rect(lx, yy, 16, 16, ig_acc(th, i), 5),
             ig_text(lx + 26, yy - 1, ig_wrap(it$label, lw, 14.5, TRUE, if (two) 2 else 1), 14.5, th$ink, 700, lh = 17)$svg,
             ig_text(IG_W - IG_M, yy - 1, if (nzchar(as.character(it$display %||% ""))) as.character(it$display) else pct, 15, ig_acc(th, i), 800, "end")$svg,
             ig_marker(it, lx - 12, yy + 9))
  }
  list(svg = paste(out, collapse = ""), h = max(2 * r1 + 40, 30 + length(its) * rowh + 10))
}

ig_block_bar_chart <- function(sec, th, y) {
  its <- ig_items(sec, 8); n <- length(its); if (n == 0) return(list(svg = "", h = 0))
  vals <- vapply(its, function(it) max(0, ig_num(it$value)), 0); vmax <- max(vals, 1e-9)
  style <- tolower(as.character(sec$style %||% "bars")); out <- character(0)
  slot <- IG_CW / n; ch <- 210; base <- y + 40 + ch
  if (style == "pencils" && n <= 6) {
    pw <- min(52, slot * 0.5)
    for (i in seq_len(n)) {
      col <- ig_acc(th, i); cx <- IG_M + slot * (i - 0.5); hh <- max(60, ch * vals[i] / vmax); top <- base - hh
      tipc <- "#F2D7A6"
      out <- c(out,
        sprintf('<g>%s<polygon points="%s,%s %s,%s %s,%s" fill="%s"/><polygon points="%s,%s %s,%s %s,%s" fill="%s"/><rect x="%s" y="%s" width="%s" height="%s" fill="%s"/><rect x="%s" y="%s" width="%s" height="%s" fill="%s" fill-opacity="0.35"/><rect x="%s" y="%s" width="%s" height="%s" rx="3" fill="%s"/></g>',
                ig_tip(its[[i]], as.character(its[[i]]$label %||% "")),
                ig_n(cx - pw / 2), ig_n(top + 30), ig_n(cx), ig_n(top), ig_n(cx + pw / 2), ig_n(top + 30), tipc,
                ig_n(cx - 7), ig_n(top + 12), ig_n(cx), ig_n(top), ig_n(cx + 7), ig_n(top + 12), ig_mix(col, "#000000", 0.35),
                ig_n(cx - pw / 2), ig_n(top + 30), ig_n(pw), ig_n(hh - 30 - 16), col,
                ig_n(cx - pw / 2), ig_n(top + 30), ig_n(pw * 0.32), ig_n(hh - 30 - 16), "#FFFFFF",
                ig_n(cx - pw / 2), ig_n(base - 16), ig_n(pw), 16, ig_mix(col, "#FFFFFF", 0.55)),
        ig_text(cx, top - 28, as.character(its[[i]]$display %||% its[[i]]$value %||% ""), 20, col, 800, "middle")$svg,
        ig_text(cx, base + 10, ig_wrap(its[[i]]$label, slot - 14, 13, TRUE, 2), 13, th$ink, 700, "middle")$svg)
    }
    return(list(svg = paste(out, collapse = ""), h = 40 + ch + 62))
  }
  out <- c(out, ig_line(IG_M, base, IG_W - IG_M, base, th$track, 2))
  bw <- min(74, slot * 0.62); imax <- which.max(vals)
  for (i in seq_len(n)) {
    col <- if (n <= 4) ig_acc(th, i) else if (i == imax) ig_acc(th, 2) else ig_acc(th, 1)
    cx <- IG_M + slot * (i - 0.5); hh <- max(6, ch * vals[i] / vmax)
    out <- c(out, sprintf('<g>%s<path d="M%s %s v-%s a8 8 0 0 1 8 -8 h%s a8 8 0 0 1 8 8 v%s z" fill="%s"/></g>', ig_tip(its[[i]], as.character(its[[i]]$label %||% "")),
                          ig_n(cx - bw / 2), ig_n(base), ig_n(hh - 8), ig_n(bw - 16), ig_n(hh - 8), col),
             ig_text(cx, base - hh - 26, as.character(its[[i]]$display %||% its[[i]]$value %||% ""), 17, th$ink, 800, "middle")$svg,
             ig_text(cx, base + 10, ig_wrap(its[[i]]$label, slot - 12, 12.5, TRUE, 2), 12.5, th$ink, 600, "middle")$svg,
             ig_marker(its[[i]], cx, base - hh - 34))
  }
  list(svg = paste(out, collapse = ""), h = 40 + ch + 56)
}

ig_block_ranking <- function(sec, th, y) {
  its <- ig_items(sec, 8); n <- length(its); if (n == 0) return(list(svg = "", h = 0))
  vals <- vapply(its, function(it) max(0, ig_num(it$value)), 0); vmax <- max(vals, 1e-9)
  lw <- min(220, IG_CW * 0.38); tw <- max(60, IG_CW - lw - 90); out <- character(0)
  for (i in seq_len(n)) {
    yy <- y + (i - 1) * 40; col <- ig_acc(th, if (i == 1) 1 else 2)
    out <- c(out, sprintf("<g>%s", ig_tip(its[[i]], as.character(its[[i]]$label %||% ""))),
             ig_text(IG_M, yy + 2, ig_wrap(its[[i]]$label, lw - 10, 14.5, TRUE, 1), 14.5, th$ink, 700)$svg,
             ig_rect(IG_M + lw, yy + 5, tw, 18, th$track, 9),
             ig_rect(IG_M + lw, yy + 5, max(14, tw * vals[i] / vmax), 18, col, 9),
             ig_text(IG_M + lw + tw + 14, yy + 2, as.character(its[[i]]$display %||% its[[i]]$value %||% ""), 15, col, 800)$svg,
             ig_marker(its[[i]], IG_W - IG_M - 6, yy + 14), "</g>")
  }
  list(svg = paste(out, collapse = ""), h = n * 40)
}

ig_block_pictogram <- function(sec, th, y) {
  its <- ig_items(sec, 4); n <- length(its); if (n == 0) return(list(svg = "", h = 0))
  out <- character(0); rowh <- 64; lw <- min(215, IG_CW * 0.34); x0 <- IG_M + lw; per <- (IG_W - IG_M - x0 - 74) / 10; gap <- max(3, round(per * 0.17)); sz <- max(12, min(30, per - gap)); pf <- if (IG_CW < 600) 20 else 26
  for (i in seq_len(n)) {
    it <- its[[i]]; yy <- y + (i - 1) * rowh; col <- ig_acc(th, i); v <- min(100, max(0, ig_num(it$value))); k <- round(v / 10)
    out <- c(out, sprintf("<g>%s", ig_tip(it, as.character(it$label %||% ""))),
             ig_text(IG_M, yy + 6, ig_wrap(it$label, lw - 20, 15, TRUE, 2), 15, th$ink, 700)$svg)
    for (j in 1:10) out <- c(out, ig_icon(it$icon %||% "user", x0 + (j - 1) * (sz + gap) + sz / 2, yy + 22, sz, if (j <= k) col else th$track, filled = TRUE, sw = 1.2))
    out <- c(out, ig_text(IG_W - IG_M, yy + 2, as.character(it$display %||% sprintf("%d%%", round(v))), pf, col, 800, "end")$svg, ig_marker(it, x0 + 10 * (sz + gap) + 6, yy + 22), "</g>")
  }
  list(svg = paste(out, collapse = ""), h = n * rowh)
}

ig_block_icon_row <- function(sec, th, y) {
  its <- ig_items(sec, 6); n <- length(its); if (n == 0) return(list(svg = "", h = 0))
  per <- min(max(2, floor(IG_CW / 170)), if (n <= 4) n else 3); rows <- ceiling(n / per); colw <- IG_CW / per; out <- character(0); hrow <- 0; cells <- list()
  for (i in seq_len(n)) {
    it <- its[[i]]; cx <- IG_M + ((i - 1) %% per + 0.5) * colw
    lt <- ig_wrap(it$label, colw - 28, 14.5, TRUE, 2); tt <- ig_wrap(it$text, colw - 30, 12.5, FALSE, 5)
    cells[[i]] <- list(cx = cx, lt = lt, tt = tt, it = it, h = 96 + length(lt) * 19 + length(tt) * 16.5 + 14)
  }
  hrow <- max(vapply(cells, function(z) z$h, 0)); hh <- rows * (hrow + 12)
  out <- c(out, ig_rect(IG_M - 12, y - 8, IG_CW + 24, hh + 4, th$panel, 18, th$panel_line, 1.5))
  for (i in seq_len(n)) {
    z <- cells[[i]]; yy <- y + floor((i - 1) / per) * (hrow + 12)
    out <- c(out, "<g>", ig_tip(z$it, as.character(z$it$label %||% "")), ig_badge(z$cx, yy + 38, 30, ig_acc(th, i), z$it$icon),
             ig_text(z$cx, yy + 88, z$lt, 14.5, th$ink, 700, "middle", lh = 19)$svg,
             ig_text(z$cx, yy + 92 + length(z$lt) * 19, z$tt, 12.5, th$muted, 400, "middle", lh = 16.5)$svg, "</g>")
  }
  list(svg = paste(out, collapse = ""), h = hh)
}

ig_block_quote_cards <- function(sec, th, y) {
  its <- ig_items(sec, 4); n <- length(its); if (n == 0) return(list(svg = "", h = 0))
  per <- if (n == 1 || IG_CW < 600) 1 else 2; cw <- (IG_CW - (per - 1) * 20) / per; out <- character(0); rows <- ceiling(n / per); ys <- y; tot <- 0
  for (r in seq_len(rows)) {
    idx <- ((r - 1) * per + 1):min(n, r * per)
    lines <- lapply(idx, function(i) ig_wrap(its[[i]]$quote, cw - 86, 14, FALSE, 7))
    hrow <- max(vapply(lines, function(l) 66 + length(l) * 18.5, 0)) + 10
    for (k in seq_along(idx)) {
      i <- idx[k]; it <- its[[i]]; x <- IG_M + (k - 1) * (cw + 20); col <- ig_acc(th, i)
      out <- c(out, "<g>", ig_tip(it, ""), ig_rect(x, ys, cw, hrow, th$panel, 14, th$panel_line, 1.5), ig_rect(x, ys + 14, 5, hrow - 28, col, 2.5),
               sprintf('<text x="%s" y="%s" font-size="54" font-weight="800" fill="%s" fill-opacity="0.9">&#8220;</text>', ig_n(x + 20), ig_n(ys + 50), col),
               ig_text(x + 62, ys + 18, lines[[k]], 14, th$ink, 400, italic = TRUE, lh = 18.5)$svg,
               ig_text(x + 62, ys + 34 + length(lines[[k]]) * 18.5, ig_wrap(it$attribution, cw - 100, 12, TRUE, 2), 12, col, 700)$svg,
               ig_marker(it, x + cw - 16, ys + 16), "</g>")
    }
    ys <- ys + hrow + 16; tot <- tot + hrow + 16
  }
  list(svg = paste(out, collapse = ""), h = tot - 8)
}

ig_block_steps <- function(sec, th, y) {
  its <- ig_items(sec, 6); n <- length(its); if (n == 0) return(list(svg = "", h = 0))
  out <- character(0)
  if (n <= 4 && IG_CW / n >= 130) {
    colw <- IG_CW / n; hmax <- 0
    out <- c(out, ig_line(IG_M + colw / 2, y + 28, IG_M + colw * (n - 0.5), y + 28, th$track, 6))
    for (i in seq_len(n)) {
      it <- its[[i]]; cx <- IG_M + colw * (i - 0.5); col <- ig_acc(th, i)
      lt <- ig_wrap(it$label, colw - 24, 15, TRUE, 2); tt <- ig_wrap(it$text, colw - 26, 12.5, FALSE, 6)
      out <- c(out, ig_circle(cx, y + 28, 28, col), ig_text(cx, y + 28 - 14, as.character(i), 26, ig_on(col), 800, "middle")$svg,
               ig_text(cx, y + 74, lt, 15, th$ink, 700, "middle")$svg, ig_text(cx, y + 78 + length(lt) * 20, tt, 12.5, th$muted, 400, "middle", lh = 16.5)$svg)
      hmax <- max(hmax, 78 + length(lt) * 20 + length(tt) * 16.5 + 8)
    }
    return(list(svg = paste(out, collapse = ""), h = hmax))
  }
  yy <- y; out <- c(out, ig_line(IG_M + 26, y + 26, IG_M + 26, y + 26 + 1, th$track, 6))
  for (i in seq_len(n)) {
    it <- its[[i]]; col <- ig_acc(th, i)
    lt <- ig_wrap(it$label, IG_CW - 80, 15, TRUE, 1); tt <- ig_wrap(it$text, IG_CW - 80, 12.5, FALSE, 3)
    hh <- max(60, 24 + length(lt) * 20 + length(tt) * 16.5 + 12)
    if (i < n) out <- c(out, ig_line(IG_M + 26, yy + 26, IG_M + 26, yy + hh + 26, th$track, 5))
    out <- c(out, ig_circle(IG_M + 26, yy + 26, 24, col), ig_text(IG_M + 26, yy + 26 - 12, as.character(i), 22, ig_on(col), 800, "middle")$svg,
             ig_text(IG_M + 68, yy + 4, lt, 15, th$ink, 700)$svg, ig_text(IG_M + 68, yy + 8 + length(lt) * 20, tt, 12.5, th$muted, 400, lh = 16.5)$svg)
    yy <- yy + hh
  }
  list(svg = paste(out, collapse = ""), h = yy - y - 6)
}

ig_block_branch_tree_wide <- function(sec, th, y) {
  L <- sec$left %||% list(); R <- sec$right %||% list()
  items_of <- function(s) Filter(is.list, (s$items %||% list())[seq_len(min(4, length(s$items %||% list())))])
  li <- items_of(L); ri <- items_of(R)
  if (length(li) + length(ri) == 0) return(list(svg = "", h = 0))
  out <- character(0); mid <- IG_W / 2; xl <- IG_M + 34; xr <- IG_W - IG_M - 34; lc <- th$line
  root <- ig_wrap(sec$root %||% sec$heading, 300, 17, TRUE, 3)
  rh <- max(64, length(root) * 22 + 28)
  rw <- 400; rc <- ig_acc(th, 2)
  out <- c(out, ig_rect(mid - rw / 2 - 8, y - 6, rw + 16, rh + 20, "none", rh / 2 + 10, rc, 3, ' stroke-opacity="0.35"'), ig_rect(mid - rw / 2, y, rw, rh + 8, rc, (rh + 8) / 2),
           ig_text(mid, y + 4 + (rh - length(root) * 22) / 2 + 2, root, 17, ig_on(rc), 800, "middle", lh = 22)$svg)
  ysplit <- y + rh + 52; ybadge <- ysplit + 46
  rr <- function(x0, y0, x1, y1) sprintf('<path d="M%s %s V%s Q%s %s %s %s H%s" fill="none" stroke="%s" stroke-width="5" stroke-linecap="round"/>', ig_n(x0), ig_n(y0), ig_n(ysplit - 10), ig_n(x0), ig_n(ysplit), ig_n(x0 + sign(x1 - x0) * 10), ig_n(ysplit), ig_n(x1 - sign(x1 - x0) * 0), lc)
  out <- c(out, ig_line(mid, y + rh + 12, mid, ysplit, lc, 5), ig_line(xl, ysplit, xr, ysplit, lc, 5),
           ig_line(xl, ysplit, xl, ybadge - 30, lc, 5), ig_line(xr, ysplit, xr, ybadge - 30, lc, 5))
  side <- function(s, its, x, col, default_icon, toward) {
    o <- ig_badge(x, ybadge, 28, col, s$icon %||% default_icon)
    o <- c(o, ig_text(x + toward * 46, ybadge - 14, ig_wrap(s$label, 200, 20, TRUE, 1), 20, col, 800, if (toward > 0) "start" else "end")$svg)
    yy <- ybadge + 56; hs <- 0
    for (k in seq_along(its)) {
      it <- its[[k]]; tl <- ig_wrap(it$text, 330, 13.5, FALSE, 5); hh <- max(60, length(tl) * 17.5 + 22)
      o <- c(o, ig_line(x, yy - 28, x, yy + hh - 28 + (if (k < length(its)) 0 else -10), lc, 5), ig_circle(x, yy + 6, 20, th$panel, col, 3), ig_icon(it$icon %||% default_icon, x, yy + 6, 22, col),
             ig_text(x + toward * 38, yy - 8 + 0, tl, 13.5, th$ink, 400, if (toward > 0) "start" else "end", lh = 17.5)$svg)
      yy <- yy + hh
    }
    list(svg = paste(o, collapse = ""), bottom = yy)
  }
  a <- side(L, li, xl, ig_acc(th, 3), "plus", 1); b <- side(R, ri, xr, ig_acc(th, 2) , "minus", -1)
  list(svg = paste(c(out, a$svg, b$svg), collapse = ""), h = max(a$bottom, b$bottom) - y)
}

ig_block_branch_tree_narrow <- function(sec, th, y) {
  items_of <- function(s) Filter(is.list, (s$items %||% list())[seq_len(min(4, length(s$items %||% list())))])
  sides <- list(list(s = sec$left %||% list(), col = ig_acc(th, 3), di = "plus"), list(s = sec$right %||% list(), col = ig_acc(th, 2), di = "minus"))
  root <- ig_wrap(sec$root %||% sec$heading, IG_CW - 36, 15, TRUE, 3); rh <- max(40, length(root) * 20 + 18); rc <- ig_acc(th, 2)
  out <- c(ig_rect(IG_M, y, IG_CW, rh, rc, rh / 2), ig_text(IG_M + IG_CW / 2, y + (rh - length(root) * 20) / 2 + 1, root, 15, ig_on(rc), 800, "middle", lh = 20)$svg)
  yy <- y + rh + 16
  for (sd in sides) {
    its <- items_of(sd$s); if (length(its) == 0) next
    out <- c(out, ig_badge(IG_M + 18, yy + 18, 16, sd$col, sd$s$icon %||% sd$di, ring = FALSE), ig_text(IG_M + 46, yy + 6, ig_wrap(sd$s$label, IG_CW - 60, 17, TRUE, 1), 17, sd$col, 800)$svg)
    yy <- yy + 42
    for (k in seq_along(its)) {
      it <- its[[k]]; tl <- ig_wrap(it$text, IG_CW - 58, 12.5, FALSE, 4); hh <- max(36, length(tl) * 16.5 + 12)
      out <- c(out, ig_line(IG_M + 18, yy - 6, IG_M + 18, yy + hh - 6, th$line, 3), ig_circle(IG_M + 18, yy + 10, 13, th$panel, sd$col, 2.5), ig_icon(it$icon %||% sd$di, IG_M + 18, yy + 10, 15, sd$col),
               ig_text(IG_M + 42, yy + 1, tl, 12.5, th$ink, 400, lh = 16.5)$svg)
      yy <- yy + hh
    }
    yy <- yy + 8
  }
  list(svg = paste(out, collapse = ""), h = yy - y)
}
ig_block_branch_tree <- function(sec, th, y) if (IG_CW < 640) ig_block_branch_tree_narrow(sec, th, y) else ig_block_branch_tree_wide(sec, th, y)

IG_REGION_TILES <- list(
  north_america = c(0, 0, 2, 2, "North America"), south_america = c(1, 2, 2, 2, "South America"), europe = c(3, 0, 2, 1, "Europe"),
  africa = c(3, 1, 2, 3, "Africa"), middle_east = c(5, 2, 1, 1, "Middle East"), asia = c(5, 0, 2, 2, "Asia"), oceania = c(5, 3, 2, 1, "Oceania"))
IG_REGION_IDS <- names(IG_REGION_TILES)
ig_region_id <- function(x) {
  k <- gsub("[^a-z]+", "_", tolower(as.character(x %||% ""))); k <- gsub("^_|_$", "", k)
  if (k %in% IG_REGION_IDS) return(k)
  syn <- c(usa = "north_america", us = "north_america", canada = "north_america", latin_america = "south_america", america = "north_america", eu = "europe",
           mena = "middle_east", asia_pacific = "asia", apac = "asia", australia = "oceania", pacific = "oceania", sub_saharan_africa = "africa")
  if (k %in% names(syn)) syn[[k]] else NA_character_
}
ig_block_region_map <- function(sec, th, y) {
  its <- ig_items(sec, 8); if (length(its) == 0) return(list(svg = "", h = 0))
  if (IG_CW < 560) {   # too narrow for the tile map: show the same data as ranking bars
    rk <- sec; rk$items <- lapply(its, function(it) { id <- ig_region_id(it$region %||% it$label); it$label <- if (is.na(id)) as.character(it$region %||% it$label) else IG_REGION_TILES[[id]][5]; it })
    return(ig_block_ranking(rk, th, y))
  }
  cell <- min(112, IG_CW / 7); ch <- cell * 0.66; gx <- (IG_CW - 7 * cell) / 2 + IG_M; vals <- list(); disp <- list(); srcs <- list()
  for (it in its) { id <- ig_region_id(it$region %||% it$label); if (!is.na(id)) { vals[[id]] <- ig_num(it$value); disp[[id]] <- as.character(it$display %||% it$value %||% ""); srcs[[id]] <- it } }
  vmax <- max(unlist(vals), 1e-9); out <- character(0)
  for (id in IG_REGION_IDS) {
    t <- IG_REGION_TILES[[id]]; x <- gx + as.numeric(t[1]) * cell + 3; yy <- y + as.numeric(t[2]) * ch + 3; w <- as.numeric(t[3]) * cell - 6; h <- as.numeric(t[4]) * ch - 6
    has <- !is.null(vals[[id]]); col <- if (has) ig_mix(th$track, ig_acc(th, 1), 0.25 + 0.75 * vals[[id]] / vmax) else th$track
    fg <- if (has) ig_on(col) else th$muted
    lab <- if (as.numeric(t[3]) == 1) { switch(id, middle_east = "Mid. East", t[5]) } else t[5]
    out <- c(out, "<g>", if (has) ig_tip(srcs[[id]], t[5]) else "", ig_rect(x, yy, w, h, col, 16, if (has) NULL else th$panel_line, 1.4, if (has) "" else ' fill-opacity="0.5"'),
             ig_text(x + w / 2, if (h < 100) yy + 8 else yy + h / 2 - (if (has) 22 else 9), lab, if (h < 100) 12 else 13, fg, 700, "middle")$svg,
             if (has) ig_text(x + w / 2, if (h < 100) yy + 27 else yy + h / 2 - 2, disp[[id]], if (h < 100) 19 else 22, fg, 800, "middle")$svg else "",
             if (has) ig_marker(srcs[[id]], x + w - 12, yy + 12) else "", "</g>")
  }
  list(svg = paste(out, collapse = ""), h = 4 * ch + 4)
}

ig_block_callout <- function(sec, th, y) {
  cfs <- if (IG_CW < 600) 20 else 25; tl <- ig_wrap(sec$text %||% sec$statement, IG_CW - 170, cfs, TRUE, 5); hh <- max(110, length(tl) * cfs * 1.28 + 50)
  col <- ig_acc(th, 1)
  svg <- paste0(ig_rect(IG_M - 8, y, IG_CW + 16, hh, th$panel, 22, th$panel_line, 1.5), ig_rect(IG_M - 8, y, 14, hh, col, 7),
                ig_badge(IG_M + 62, y + hh / 2, 34, col, sec$icon %||% "lightbulb"),
                ig_text(IG_M + 128, y + (hh - (length(tl) * cfs * 1.28 - 6)) / 2 - 4, tl, cfs, th$ink, 800, lh = cfs * 1.28)$svg)
  list(svg = svg, h = hh)
}

IG_BLOCKS <- list(stat_row = ig_block_stat_row, donut = ig_block_donut, bar_chart = ig_block_bar_chart, ranking = ig_block_ranking,
                  pictogram = ig_block_pictogram, icon_row = ig_block_icon_row, quote_cards = ig_block_quote_cards, steps = ig_block_steps,
                  branch_tree = ig_block_branch_tree, region_map = ig_block_region_map, callout = ig_block_callout)

# ---- hero + footer -----------------------------------------------------------
ig_hero <- function(m, th, fill_h = NULL, slant = 28) {
  tl <- ig_wrap(m$title, IG_CW - 250, 46, TRUE, 4); st <- ig_wrap(m$subtitle, IG_CW - 250, 17, FALSE, 4)
  kick <- toupper(as.character(m$kicker %||% ""))
  hh <- max(300, 120 + length(tl) * 56 + length(st) * 23 + 70)
  sh <- 0   # vertical shift when the hero is stretched to fill a whole page (cover slide)
  if (!is.null(fill_h) && fill_h > hh) { sh <- (fill_h - hh) / 2; hh <- fill_h }
  col1 <- ig_acc(th, 1); col2 <- ig_acc(th, 2)
  deco <- paste0(ig_circle(IG_W - 110, 120 + sh, 150, "none", col1, 28, ' stroke-opacity="0.16"'), ig_circle(IG_W - 110, 120 + sh, 96, "none", col2, 10, ' stroke-opacity="0.22"'),
                 ig_circle(60, hh - 40, 80, col2, NULL, 1, ' fill-opacity="0.12"'),
                 sprintf('<rect x="%s" y="%s" width="120" height="120" rx="26" fill="%s" fill-opacity="0.12" transform="rotate(18 %s %s)"/>', IG_W - 330, hh - 170, col1, IG_W - 270, hh - 110))
  icons <- unlist(m$hero_icons %||% list()); icons <- icons[seq_len(min(3, length(icons)))]
  ic <- character(0)
  pos <- list(c(IG_W - 150, 110 + sh), c(IG_W - 255, 190 + sh), c(IG_W - 90, 215 + sh))
  for (i in seq_along(icons)) ic <- c(ic, ig_badge(pos[[i]][1], pos[[i]][2], c(46, 32, 28)[i], ig_acc(th, i), icons[i]))
  y <- 70 + sh
  k <- if (nzchar(kick)) { r <- ig_text(IG_M, y, kick, 14, col1, 800, ls = 2.5); y <- y + 32; r$svg } else ""
  t <- ig_text(IG_M, y, tl, 46, th$hero_ink, 800, lh = 54); y <- y + t$h + 14
  s <- ig_text(IG_M, y, st, 17, th$hero_ink, 400, lh = 23, opacity = 0.85)
  list(h = hh, svg = paste0(sprintf('<polygon points="0,0 %s,0 %s,%s 0,%s" fill="url(#igHero)"/>', ig_n(IG_W), ig_n(IG_W), ig_n(hh - slant), ig_n(hh)), deco, paste(ic, collapse = ""), k, t$svg, s$svg))
}

ig_footer <- function(d, th, y) {
  src <- d$sources; out <- character(0); yy <- y + 46
  out <- c(out, ig_text(IG_M, y + 6, "SOURCES AND EVIDENCE", 14, ig_acc(th, 1), 800, ls = 2)$svg)
  cnt <- ig_evidence_counts(d)
  if (sum(cnt) > 0) {
    xx <- IG_M
    for (s in names(cnt)[cnt > 0]) {
      lab <- sprintf("%d %s", cnt[[s]], s)
      out <- c(out, ig_status_dot(s, xx + 5, yy + 8, 4.6), ig_text(xx + 16, yy, lab, 12, th$hero_ink, 400, opacity = 0.9)$svg)
      xx <- xx + 24 + nchar(lab) * 6.6
    }
    yy <- yy + 28
  }
  if (nrow(src) > 0) {
    for (i in seq_len(nrow(src))) {
      s <- src[i, ]
      host <- sub("^https?://(www\\.)?([^/]+).*$", "\\2", s$url)
      flag <- paste(c(if (identical(s$in_search_results, "no")) "not in search results", if (identical(s$reachable, "no")) "page not fetched"), collapse = ", ")
      line1 <- paste0(s$id, "  ", s$title)
      t1 <- ig_text(IG_M, yy, ig_wrap(line1, IG_CW, 12.5, TRUE, 2), 12.5, th$hero_ink, 700, lh = 16)
      lnk <- if (grepl("^https?://", s$url)) sprintf('<a href="%s" target="_blank" rel="noopener">%s</a>', ig_e(s$url),
                                                      ig_text(IG_M, yy + t1$h + 2, paste0(host, if (nzchar(s$publisher)) paste0("  -  ", s$publisher) else "", if (nzchar(flag)) paste0("  [", flag, "]") else ""), 11.5, ig_mix(ig_acc(th, 2), "#FFFFFF", 0.6), 400)$svg) else ""
      out <- c(out, t1$svg, lnk); yy <- yy + t1$h + 24
    }
  } else out <- c(out, ig_text(IG_M, yy, "No external sources: figures marked as judgment are illustrative, not measured.", 12.5, th$hero_ink, 400, opacity = 0.85)$svg); yy <- yy + 26
  list(svg = paste(out, collapse = ""), h = yy - y + 10)
}
ig_evidence_counts <- function(d) {
  st <- character(0)
  for (sec in d$sections) for (it in (sec$items %||% list())) if (is.list(it)) { s <- ig_item_status(it); if (nzchar(s)) st <- c(st, s) }
  vapply(c("verified", "unverified", "contradicted", "applicant", "judgment"), function(s) sum(st == s), integer(1))
}

# ---- assemble -------------------------------------------------------------------
ig_custom_theme <- function(p) {
  navy <- p$navy; teal <- p$teal; mag <- p$magenta; och <- p$ochre; W <- "#FFFFFF"
  list(label = "Brand colours", hero_from = ig_mix(navy, "#000000", 0.25), hero_to = ig_mix(navy, teal, 0.5), hero_ink = "#FFFFFF",
       bandA = ig_mix(teal, W, 0.93), bandB = ig_mix(teal, W, 0.85), ink = ig_mix(navy, "#000000", 0.2), muted = ig_mix(navy, W, 0.35), panel = W, panel_line = ig_mix(teal, W, 0.7),
       track = ig_mix(navy, W, 0.86), line = W, accents = c(teal, mag, och, navy))
}
ig_theme <- function(d) {
  nm <- tolower(as.character(d$meta$theme %||% "sky")); pal <- d$meta$palette
  if (identical(nm, "custom") && is.list(pal) && length(pal) == 4 && all(nzchar(unlist(pal)))) return(ig_custom_theme(pal))
  IG_THEMES[[nm]] %||% IG_THEMES$sky
}

# ---- page formats (poster or fixed-size slides/pages) -------------------------------
# lw = layout width in drawing units (the page is lw x lw/ar); per = sections per page;
# cover = the first page is a title-only cover when 2+ pages are requested.
IG_FORMATS <- list(
  poster = list(label = "Long poster (one tall page)", lw = 900, ar = NA, per = NA, cover = FALSE, short = "Poster"),
  `16x9` = list(label = "Presentation 16:9 landscape", lw = 1000, ar = 16 / 9, per = 1, cover = TRUE, short = "16:9"),
  a4l    = list(label = "A4 landscape (print, one slide per sheet)", lw = 1000, ar = sqrt(2), per = 1, cover = TRUE, short = "A4 landscape"),
  a5l    = list(label = "A5 landscape (print, 2 slides per A4 sheet)", lw = 1000, ar = sqrt(2), per = 1, cover = TRUE, short = "A5 landscape"),
  `4x3`  = list(label = "Presentation 4:3 landscape", lw = 900, ar = 4 / 3, per = 1, cover = TRUE, short = "4:3"),
  `1x1`  = list(label = "Square 1:1 (LinkedIn / Instagram post)", lw = 900, ar = 1, per = 1, cover = TRUE, short = "1:1"),
  `4x5`  = list(label = "Portrait 4:5 (LinkedIn carousel)", lw = 900, ar = 0.8, per = 1, cover = FALSE, short = "4:5"),
  `9x16` = list(label = "Portrait 9:16 (LinkedIn / stories)", lw = 900, ar = 9 / 16, per = 2, cover = FALSE, short = "9:16"),
  a4     = list(label = "A4 portrait (print)", lw = 900, ar = 1 / sqrt(2), per = 2, cover = FALSE, short = "A4")
)
IG_FORMAT_CHOICES <- setNames(names(IG_FORMATS), vapply(IG_FORMATS, function(f) f$label, ""))
ig_format_id <- function(x) { x <- tolower(trimws(as.character(if (is.null(x) || length(x) == 0) "" else x[[1]]))); if (x %in% names(IG_FORMATS)) x else "poster" }
ig_slides_n <- function(x, default = 4L) { v <- suppressWarnings(as.integer(round(as.numeric(if (is.null(x) || length(x) == 0) NA else x[[1]])))); if (is.na(v)) default else as.integer(min(8L, max(1L, v))) }
# how many sections a deck of n pages needs
ig_cover_on <- function(fmt, n, cover = "auto") {
  f <- IG_FORMATS[[ig_format_id(fmt)]]; n <- ig_slides_n(n); cover <- tolower(as.character(cover %||% "auto"))
  if (is.na(f$per)) return(FALSE)
  n >= 2 && (cover == "yes" || (cover == "auto" && isTRUE(f$cover)))
}
ig_sections_for <- function(fmt, n, layout = "stacked", panels = 3L, cover = "auto") {
  f <- IG_FORMATS[[ig_format_id(fmt)]]; if (is.na(f$per)) return(NA_integer_)
  n <- ig_slides_n(n)
  if (layout %in% c("dashboard", "flow")) { cv <- n >= 2 && identical(tolower(as.character(cover)), "yes"); return(as.integer(max(1L, (n - as.integer(cv)) * min(6L, max(1L, as.integer(panels)))))) }
  as.integer(max(1L, (n - as.integer(ig_cover_on(fmt, n, cover))) * f$per))
}

# the layout constants live where the blocks look them up
ig_set_width <- function(w, m = NULL) {
  e <- environment(ig_text); if (!is.null(m)) assign("IG_M", m, envir = e)
  assign("IG_W", w, envir = e); assign("IG_CW", w - 2 * get("IG_M", envir = e), envir = e)
}
ig_geom <- function() { e <- environment(ig_text); c(w = get("IG_W", envir = e), m = get("IG_M", envir = e)) }

# one section (ribbon heading + intro + block), drawn from y = 0; h includes the padding
ig_section_parts <- function(sec, th, pad_top = 58, pad_bot = 44) {
  fn <- IG_BLOCKS[[sec$type %||% ""]]; if (is.null(fn)) return(NULL)
  yy <- pad_top; head <- character(0)
  if (nzchar(as.character(sec$heading %||% ""))) {
    ht <- toupper(as.character(sec$heading)); tw <- min(IG_CW, nchar(ht) * 16.5 + 56); col <- ig_acc(th, 1)
    head <- c(head, sprintf('<polygon points="%s,%s %s,%s %s,%s %s,%s %s,%s" fill="%s"/>', ig_n(IG_M - 12), ig_n(yy), ig_n(IG_M + tw), ig_n(yy), ig_n(IG_M + tw + 16), ig_n(yy + 21), ig_n(IG_M + tw), ig_n(yy + 42), ig_n(IG_M - 12), ig_n(yy + 42), col),
              sprintf('<polygon points="%s,%s %s,%s %s,%s" fill="%s" fill-opacity="0.55"/>', ig_n(IG_M - 12), ig_n(yy + 42), ig_n(IG_M + 4), ig_n(yy + 42), ig_n(IG_M - 12), ig_n(yy + 54), col),
              ig_text(IG_M + 8, yy + 8, ig_wrap(ht, IG_CW - 40, 22, TRUE, 1), 22, ig_on(col), 800, ls = 0.5)$svg)
    yy <- yy + 62
  }
  intro <- ig_text(IG_M, yy, ig_wrap(sec$intro %||% sec$text_intro, IG_CW * 0.86, 14.5, FALSE, 3), 14.5, th$muted, 400, lh = 20)
  if (intro$h > 0) yy <- yy + intro$h + 22
  blk <- fn(sec, th, yy)
  list(svg = paste(c(head, intro$svg, blk$svg), collapse = ""), h = yy + blk$h + pad_bot)
}

ig_defs_css <- function(th) {
  sprintf('<style>text{font-family:%s}</style><defs><linearGradient id="igHero" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient></defs>', IG_FONT, th$hero_from, th$hero_to)
}

# ---- the long poster ---------------------------------------------------------------
ig_build_svg <- function(d) {
  old <- ig_geom(); on.exit(ig_set_width(old[["w"]], old[["m"]]), add = TRUE); ig_set_width(900, 48); th <- ig_theme(d); m <- d$meta; hero <- ig_hero(m, th)
  y <- hero$h; body <- character(0); bands <- list(); slant <- 26
  for (i in seq_along(d$sections)) {
    parts <- ig_section_parts(d$sections[[i]], th); if (is.null(parts)) next
    top <- y
    body <- c(body, sprintf('<g transform="translate(0,%s)">%s</g>', ig_n(top), parts$svg))
    bands[[length(bands) + 1]] <- list(y = top, up = (i %% 2 == 0), fill = if (i %% 2 == 1) th$bandA else th$bandB)
    y <- top + parts$h
  }
  foot <- ig_footer(d, th, y + 50); Htot <- y + 50 + foot$h + 40
  bg <- ig_rect(0, 0, IG_W, Htot, th$bandB)
  bsv <- vapply(bands, function(b) sprintf('<polygon points="0,%s %d,%s %d,%s 0,%s" fill="%s"/>', ig_n(b$y + if (b$up) slant else 0), IG_W, ig_n(b$y + if (b$up) 0 else slant), IG_W, ig_n(Htot), ig_n(Htot), b$fill), character(1))
  fpoly <- sprintf('<polygon points="0,%s %d,%s %d,%s 0,%s" fill="%s"/>', ig_n(y + 30), IG_W, ig_n(y), IG_W, ig_n(Htot), ig_n(Htot), th$hero_from)
  svg <- sprintf('<svg xmlns="http://www.w3.org/2000/svg" class="ig-svg" viewBox="0 0 %d %s" width="%d" height="%s" style="max-width:100%%;height:auto;display:block;margin:0 auto"><title>%s</title>%s%s%s%s%s%s%s</svg>',
                 IG_W, ig_n(Htot), IG_W, ig_n(Htot), ig_e(m$title), ig_defs_css(th), bg, paste(bsv, collapse = ""), hero$svg, paste(body, collapse = ""), fpoly, foot$svg)
  list(svg = svg, w = IG_W, h = Htot, pages = list(svg), n = 1L, notes = character(0), fmt = "poster")
}

# ---- fixed-size pages / slides --------------------------------------------------------
# contiguous split of heights into k groups minimising the tallest group
ig_partition <- function(h, k) {
  n <- length(h); k <- min(k, n); if (k <= 1) return(list(seq_len(n)))
  cs <- c(0, cumsum(h)); best <- matrix(Inf, k, n); cut <- matrix(0L, k, n)
  for (j in seq_len(n)) best[1, j] <- cs[j + 1]
  for (g in 2:k) for (j in g:n) for (c0 in (g - 1):(j - 1)) {
    v <- max(best[g - 1, c0], cs[j + 1] - cs[c0 + 1]); if (v < best[g, j]) { best[g, j] <- v; cut[g, j] <- c0 }
  }
  out <- list(); j <- n
  for (g in k:2) { c0 <- cut[g, j]; out[[g]] <- (c0 + 1):j; j <- c0 }
  out[[1]] <- seq_len(j); out
}

ig_footer_compact <- function(d, th, W, H, max_src) {
  src <- d$sources; n <- nrow(src); show <- min(n, max_src); rows <- ceiling(show / 2); cnt <- ig_evidence_counts(d)
  has_cnt <- sum(cnt) > 0
  fh <- 18 + 22 + (if (has_cnt) 24 else 0) + (if (n > 0) rows * 17 + (if (n > show) 17 else 0) else 20) + 40
  y0 <- H - fh; out <- character(0); yy <- y0 + 16
  out <- c(out, ig_rect(0, y0, W, fh, th$hero_from), ig_text(IG_M, yy, "SOURCES AND EVIDENCE", 12, ig_acc(th, 1), 800, ls = 2)$svg); yy <- yy + 22
  if (has_cnt) {
    xx <- IG_M
    for (s in names(cnt)[cnt > 0]) {
      lab <- sprintf("%d %s", cnt[[s]], s)
      out <- c(out, ig_status_dot(s, xx + 5, yy + 7, 4.4), ig_text(xx + 16, yy, lab, 11.5, th$hero_ink, 400, opacity = 0.9)$svg)
      xx <- xx + 24 + nchar(lab) * 6.4
    }
    yy <- yy + 24
  }
  if (n > 0) {
    colw <- (W - 2 * IG_M - 20) / 2; maxch <- max(20, floor((colw - 8) / 5.9))
    for (i in seq_len(show)) {
      s <- src[i, ]; col <- (i - 1) %/% rows; row <- (i - 1) %% rows
      host <- sub("^https?://(www\\.)?([^/]+).*$", "\\2", s$url)
      lab <- paste0(s$id, "  ", host, if (nzchar(s$title)) paste0("  -  ", s$title) else "")
      if (nchar(lab) > maxch) lab <- paste0(substr(lab, 1, maxch - 3), "...")
      t <- ig_text(IG_M + col * (colw + 20), yy + row * 17, lab, 11, ig_mix(ig_acc(th, 2), "#FFFFFF", 0.6), 400)$svg
      out <- c(out, if (grepl("^https?://", s$url)) sprintf('<a href="%s" target="_blank" rel="noopener">%s</a>', ig_e(s$url), t) else t)
    }
    if (n > show) out <- c(out, ig_text(IG_M, yy + rows * 17, sprintf("+ %d more source(s): see the Facts and Evidence table or the JSON", n - show), 11, th$hero_ink, 400, opacity = 0.75)$svg)
  } else out <- c(out, ig_text(IG_M, yy, "No external sources: figures marked as judgment are illustrative, not measured.", 11.5, th$hero_ink, 400, opacity = 0.85)$svg)
  list(svg = paste(out, collapse = ""), h = fh)
}

ig_page_chrome <- function(th, W, H, k, n, title, dark) {
  col <- if (dark) th$hero_ink else th$muted
  t <- ig_text(IG_M, H - 26, if (nchar(title) > 60) paste0(substr(title, 1, 57), "...") else title, 11, col, 600, opacity = 0.6)$svg
  p <- ig_text(W - IG_M, H - 26, sprintf("%d / %d", k, n), 11, col, 700, anchor = "end", opacity = 0.75)$svg
  paste0(t, p)
}

ig_build_pages <- function(d, fmt, n) {
  f <- IG_FORMATS[[fmt]]; n <- ig_slides_n(n); LW <- f$lw; W <- LW; H <- round(LW / f$ar)
  old <- ig_geom(); ig_set_width(LW, 48); on.exit(ig_set_width(old[["w"]], old[["m"]]), add = TRUE)
  th <- ig_theme(d); m <- d$meta; notes <- character(0)
  parts <- Filter(Negate(is.null), lapply(d$sections, ig_section_parts, th = th, pad_top = 18, pad_bot = 14))
  K <- length(parts); if (K == 0) stop("Nothing to draw.")
  cover <- ig_cover_on(fmt, n, d$meta$cover %||% "auto")
  Pc <- min(n - as.integer(cover), K)
  if (Pc < n - as.integer(cover)) notes <- c(notes, sprintf("There are only %d section(s), so the deck has %d page(s) instead of %d. Generate again with more sections, or lower the page count.", K, Pc + as.integer(cover), n))
  groups <- ig_partition(vapply(parts, function(p) p$h, numeric(1)), Pc)
  total <- Pc + as.integer(cover); pages <- character(0); chrome_h <- 34; max_src <- if (W > H) 8 else 14
  secidx <- seq_along(d$sections)[vapply(d$sections, function(s) !is.null(IG_BLOCKS[[s$type %||% ""]]), logical(1))]
  if (cover) {
    pages <- c(pages, ig_cover_page(d, th, W, H, total, LW)); ig_set_width(LW, 48)
  }
  for (g in seq_along(groups)) {
    k <- g + as.integer(cover); idx <- groups[[g]]; first <- (g == 1 && !cover); last <- (g == length(groups))
    hero <- if (first) ig_hero(m, th, slant = 0) else list(svg = "", h = 0)
    foot <- if (last) ig_footer_compact(d, th, W, H, max_src) else list(svg = "", h = chrome_h)
    avail <- H - hero$h - (if (last) foot$h else chrome_h) - 6
    bh <- sum(vapply(parts[idx], function(p) p$h, numeric(1)))
    s <- min(1, avail / bh)
    if (s < 0.55) notes <- c(notes, sprintf("Page %d holds %d section(s) and had to be shrunk to %d%%; it will be hard to read. Use more pages or fewer sections.", k, length(idx), round(s * 100)))
    ox <- (W - W * s) / 2; oy <- hero$h + (avail - bh * s) / 2; yy <- 0; bodies <- character(0); bandsv <- character(0)
    for (j in seq_along(idx)) {
      p <- parts[[idx[j]]]; gi <- secidx[idx[j]]
      bodies <- c(bodies, sprintf('<g transform="translate(0,%s)">%s</g>', ig_n(yy), p$svg))
      if (j > 1) bandsv <- c(bandsv, ig_rect(0, oy + yy * s - 4, W, H, if (gi %% 2 == 1) th$bandA else th$bandB))
      yy <- yy + p$h
    }
    gi1 <- secidx[idx[1]]; bgcol <- if (gi1 %% 2 == 1) th$bandA else th$bandB
    pages <- c(pages, sprintf('<svg xmlns="http://www.w3.org/2000/svg" class="ig-svg ig-page" data-ig-page="%d" viewBox="0 0 %d %d" width="%d" height="%d" style="max-width:100%%;height:auto;display:block"><title>%s</title>%s%s%s%s<g transform="translate(%s,%s) scale(%s)">%s</g>%s%s%s</svg>',
                              k, W, H, W, H, ig_e(m$title), ig_defs_css(th), ig_rect(0, 0, W, H, bgcol), paste(bandsv, collapse = ""), hero$svg, ig_n(ox), ig_n(oy), formatC(s, format = "f", digits = 4),
                              paste(bodies, collapse = ""), if (last) foot$svg else "", ig_page_chrome(th, W, H, k, total, m$title, last), ""))
  }
  list(svg = paste(pages, collapse = ""), w = W, h = H, pages = as.list(pages), n = length(pages), notes = notes, fmt = fmt)
}

ig_layout <- function(d) {
  fmt <- ig_format_id(d$meta$format)
  ly <- d$meta$layout %||% "stacked"
  if (identical(ly, "flow")) ig_build_flow(d, fmt, ig_slides_n(d$meta$slides))
  else if (identical(fmt, "poster")) ig_build_svg(d)
  else if (identical(ly, "dashboard")) ig_build_dashboard(d, fmt, ig_slides_n(d$meta$slides))
  else ig_build_pages(d, fmt, ig_slides_n(d$meta$slides))
}

render_infographic <- function(d, lay = NULL) {
  wid <- paste0("ig", sample(10000:99999, 1), sample(10000:99999, 1))
  if (is.null(lay)) lay <- ig_layout(d)
  if (lay$n <= 1 && identical(lay$fmt, "poster")) {
    return(htmltools::tagList(htmltools::HTML(sprintf('<div class="ig-card" id="%s" data-ig-w="%d" data-ig-h="%s" data-ig-pages="1" style="background:#fff;border-radius:12px;box-shadow:0 4px 15px rgba(0,44,60,.15);padding:0;margin:8px 0;overflow:hidden">%s</div>', wid, lay$w, ig_n(lay$h), lay$pages[[1]]))))
  }
  # one page per row, centred, every page the same width (wide slides 1000 px, tall or square pages 810 px; never wider than the window)
  pw <- if (lay$w > lay$h * 1.15) 1000 else 810
  cards <- vapply(seq_along(lay$pages), function(i)
    sprintf('<div class="ig-pagewrap" style="background:#fff;border-radius:10px;box-shadow:0 4px 15px rgba(0,44,60,.15);overflow:hidden;width:100%%;max-width:%dpx"><div style="padding:5px 12px;font-size:12px;color:#5b6b7b;background:#f4f7fa;border-bottom:1px solid #e1e8ef">Page %d of %d</div>%s</div>', pw, i, lay$n, lay$pages[[i]]), character(1))
  htmltools::tagList(htmltools::HTML(sprintf('<div class="ig-card ig-deck" id="%s" data-ig-w="%d" data-ig-h="%d" data-ig-pages="%d" data-ig-paper="%s" style="display:flex;flex-direction:column;align-items:center;gap:24px;margin:8px 0">%s</div>',
                                             wid, lay$w, lay$h, lay$n, if (lay$fmt %in% c("a4l", "a5l", "a4")) lay$fmt else "", paste(cards, collapse = ""))))
}
