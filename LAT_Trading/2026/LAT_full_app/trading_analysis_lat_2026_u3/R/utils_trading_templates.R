# =============================================================================
# Fill the real LAT Word templates (Individual Trade Sheet, Morning Sheet)
# =============================================================================
# The two LAT templates are kept in www/templates/. A template is a .docx (a zip of XML); the
# functions below open it, write the recorded values into its own tables, put screenshots where the
# template says "[Insert chart picture here]", and save a new .docx. Header, logo, footer and styles
# are the template's own. Nothing is written for the student: text fields are exactly what was typed.
# Needs the xml2 and zip packages; if a template or package is missing the caller falls back to the
# plain officer layout.

tr_tpl_ns <- c(w = "http://schemas.openxmlformats.org/wordprocessingml/2006/main")
`%||%` <- function(a, b) if (is.null(a)) b else a
tr_tpl_find <- function(name) {
  for (d in c(getOption("trading.template_dir", ""), file.path("www", "templates"), "templates"))
    if (nzchar(d) && file.exists(file.path(d, name))) return(file.path(d, name))
  NA_character_
}
tr_tpl_available <- function(name) !is.na(tr_tpl_find(name)) && requireNamespace("xml2", quietly = TRUE) && requireNamespace("zip", quietly = TRUE)

tr_tpl_open <- function(path) {
  tr_need("xml2"); tr_need("zip")
  tp <- new.env()
  tp$dir <- tempfile("lat_tpl_"); dir.create(tp$dir)
  utils::unzip(path, exdir = tp$dir)
  tp$doc <- xml2::read_xml(file.path(tp$dir, "word", "document.xml"))
  tp$rels <- xml2::read_xml(file.path(tp$dir, "word", "_rels", "document.xml.rels"))
  tp$ct <- xml2::read_xml(file.path(tp$dir, "[Content_Types].xml"))
  tp$img <- 0L
  dir.create(file.path(tp$dir, "word", "media"), showWarnings = FALSE)
  tp
}
tr_tpl_save <- function(tp, file) {
  xml2::write_xml(tp$doc, file.path(tp$dir, "word", "document.xml"))
  xml2::write_xml(tp$rels, file.path(tp$dir, "word", "_rels", "document.xml.rels"))
  xml2::write_xml(tp$ct, file.path(tp$dir, "[Content_Types].xml"))
  files <- list.files(tp$dir, recursive = TRUE, all.files = TRUE, include.dirs = FALSE)
  files <- c("[Content_Types].xml", setdiff(files, "[Content_Types].xml"))
  if (file.exists(file)) unlink(file)
  zip::zip(zipfile = normalizePath(file, mustWork = FALSE), files = files, root = tp$dir, mode = "mirror")
  unlink(tp$dir, recursive = TRUE)
  invisible(file)
}

tr_tpl_esc <- function(x) { x <- gsub("&", "&amp;", x, fixed = TRUE); x <- gsub("<", "&lt;", x, fixed = TRUE); gsub(">", "&gt;", x, fixed = TRUE) }
tr_tpl_run <- function(text, rpr = NULL) {
  parts <- strsplit(as.character(text), "\r?\n")[[1]]; if (!length(parts)) parts <- ""
  body <- paste0(vapply(seq_along(parts), function(i) paste0(if (i > 1) "<w:br/>" else "", '<w:t xml:space="preserve">', tr_tpl_esc(parts[i]), "</w:t>"), ""), collapse = "")
  rp <- if (is.null(rpr)) "" else as.character(rpr)
  xml2::read_xml(paste0('<w:r xmlns:w="', tr_tpl_ns[["w"]], '">', rp, body, "</w:r>"))
}
tr_tpl_body <- function(tp) xml2::xml_find_first(tp$doc, "/w:document/w:body", tr_tpl_ns)
tr_tpl_tables <- function(tp) xml2::xml_find_all(tr_tpl_body(tp), "./w:tbl", tr_tpl_ns)
tr_tpl_rows <- function(tbl) xml2::xml_find_all(tbl, "./w:tr", tr_tpl_ns)
tr_tpl_cells <- function(row) xml2::xml_find_all(row, "./w:tc", tr_tpl_ns)
tr_tpl_cell <- function(tbl, r, c) { rows <- tr_tpl_rows(tbl); if (r > length(rows)) return(NULL); cs <- tr_tpl_cells(rows[[r]]); if (c > length(cs)) NULL else cs[[c]] }

# write text into a table cell (keeps the cell's own paragraph and run formatting)
tr_tpl_set <- function(tc, text, size = NULL) {
  if (is.null(tc)) return(invisible())
  text <- as.character(text); if (length(text) != 1 || is.na(text)) text <- ""
  p <- xml2::xml_find_first(tc, ".//w:p", tr_tpl_ns)
  rpr <- xml2::xml_find_first(p, "./w:pPr/w:rPr", tr_tpl_ns)
  if (inherits(rpr, "xml_missing")) rpr <- xml2::xml_find_first(p, "./w:r/w:rPr", tr_tpl_ns)
  if (inherits(rpr, "xml_missing")) rpr <- NULL
  for (r in xml2::xml_find_all(p, "./w:r", tr_tpl_ns)) xml2::xml_remove(r)
  rp <- if (is.null(rpr)) NULL else as.character(rpr)
  if (!is.null(size)) {   # font size in points, added at the end of the run properties (valid position in the schema)
    sz <- sprintf('<w:sz w:val="%d"/><w:szCs w:val="%d"/>', as.integer(size * 2), as.integer(size * 2))
    rp <- if (is.null(rp)) paste0("<w:rPr>", sz, "</w:rPr>") else sub("</w:rPr>", paste0(sz, "</w:rPr>"), rp, fixed = TRUE)
  }
  if (grepl("\\n", text)) { jc <- xml2::xml_find_first(p, "./w:pPr/w:jc", tr_tpl_ns); if (!inherits(jc, "xml_missing")) xml2::xml_set_attr(jc, "w:val", "left") }
  if (nzchar(text)) xml2::xml_add_child(p, tr_tpl_run(text, rp))
  invisible()
}
# make sure a table has at least `n` rows from row `first` on, cloning the last row
tr_tpl_need_rows <- function(tbl, first, n) {
  rows <- tr_tpl_rows(tbl)
  while (length(rows) < first + n - 1) {
    xml2::xml_add_sibling(rows[[length(rows)]], rows[[length(rows)]], .where = "after", .copy = TRUE)
    rows <- tr_tpl_rows(tbl)
    for (tc in tr_tpl_cells(rows[[length(rows)]])) tr_tpl_set(tc, "")
  }
  invisible(rows)
}
# fill a data frame into a table starting at row `first`, column `col0` (all cells as text)
tr_tpl_fill_df <- function(tbl, df, first = 2, col0 = 1) {
  if (!nrow(df)) return(invisible())
  tr_tpl_need_rows(tbl, first, nrow(df)); rows <- tr_tpl_rows(tbl)
  for (i in seq_len(nrow(df))) { cs <- tr_tpl_cells(rows[[first + i - 1]])
    for (j in seq_len(ncol(df))) if (col0 + j - 1 <= length(cs)) tr_tpl_set(cs[[col0 + j - 1]], as.character(df[i, j])) }
  invisible()
}

# ---- paragraphs and pictures -------------------------------------------------------------
tr_tpl_par_text <- function(p) paste(xml2::xml_text(xml2::xml_find_all(p, ".//w:t", tr_tpl_ns)), collapse = "")
tr_tpl_find_par <- function(tp, pattern, nth = 1) {
  ps <- xml2::xml_find_all(tr_tpl_body(tp), "./w:p", tr_tpl_ns)
  hit <- Filter(function(p) grepl(pattern, tr_tpl_par_text(p), fixed = TRUE), as.list(ps))
  if (length(hit) >= nth) hit[[nth]] else NULL
}
tr_tpl_clear_par <- function(p) { for (r in xml2::xml_find_all(p, "./w:r", tr_tpl_ns)) xml2::xml_remove(r); invisible(p) }
tr_tpl_centre <- function(p) {
  jc <- xml2::xml_find_first(p, "./w:pPr/w:jc", tr_tpl_ns)
  if (!inherits(jc, "xml_missing")) xml2::xml_set_attr(jc, "w:val", "center")
  else { ppr <- xml2::xml_find_first(p, "./w:pPr", tr_tpl_ns)
         if (inherits(ppr, "xml_missing")) { xml2::xml_add_child(p, xml2::read_xml(paste0('<w:pPr xmlns:w="', tr_tpl_ns[["w"]], '"><w:jc w:val="center"/></w:pPr>')), .where = 0) }
         else xml2::xml_add_child(ppr, xml2::read_xml(paste0('<w:jc xmlns:w="', tr_tpl_ns[["w"]], '" w:val="center"/>'))) }
  invisible(p)
}
tr_tpl_image_part <- function(tp, path) {   # copy the picture into the package; returns relationship id
  ext <- tolower(tools::file_ext(path)); if (ext == "jpg") ext <- "jpeg"; if (!ext %in% c("png", "jpeg")) stop("Pictures must be PNG or JPEG: ", basename(path))
  tp$img <- tp$img + 1L; nm <- sprintf("lat_img%d.%s", tp$img, ext); file.copy(path, file.path(tp$dir, "word", "media", nm), overwrite = TRUE)
  rid <- sprintf("rIdLatImg%d", tp$img)
  xml2::xml_add_child(tp$rels, xml2::read_xml(sprintf('<Relationship xmlns="http://schemas.openxmlformats.org/package/2006/relationships" Id="%s" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/%s"/>', rid, nm)))
  ctn <- xml2::xml_ns(tp$ct); have <- tolower(xml2::xml_attr(xml2::xml_find_all(tp$ct, "//d1:Default", ctn), "Extension"))
  if (!ext %in% have) xml2::xml_add_child(tp$ct, xml2::read_xml(sprintf('<Default xmlns="http://schemas.openxmlformats.org/package/2006/content-types" Extension="%s" ContentType="image/%s"/>', ext, ext)), .where = 0)
  list(rid = rid, name = nm)
}
tr_tpl_picture_run <- function(tp, path, width_in = 6.2, max_h_in = 5.6) {
  d <- tr_img_dim(path, width_in); w <- d[1]; h <- d[2]
  if (h > max_h_in) { w <- w * max_h_in / h; h <- max_h_in }
  cx <- as.integer(round(w * 914400)); cy <- as.integer(round(h * 914400)); part <- tr_tpl_image_part(tp, path); id <- 1000L + tp$img
  xml2::read_xml(sprintf(paste0(
    '<w:r xmlns:w="%s" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" ',
    'xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><w:drawing>',
    '<wp:inline distT="0" distB="0" distL="0" distR="0"><wp:extent cx="%d" cy="%d"/><wp:docPr id="%d" name="Picture %d"/>',
    '<wp:cNvGraphicFramePr><a:graphicFrameLocks noChangeAspect="1"/></wp:cNvGraphicFramePr><a:graphic><a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">',
    '<pic:pic><pic:nvPicPr><pic:cNvPr id="%d" name="%s"/><pic:cNvPicPr/></pic:nvPicPr><pic:blipFill><a:blip r:embed="%s"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill>',
    '<pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="%d" cy="%d"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr></pic:pic></a:graphicData></a:graphic></wp:inline></w:drawing></w:r>'),
    tr_tpl_ns[["w"]], cx, cy, id, tp$img, id, part$name, part$rid, cx, cy))
}
# Replace a placeholder paragraph by a sequence of items, each on its own paragraph and in the given order:
# list(type = "text" | "caption" | "pic", value = text or file path). Captions are bold; pictures are centred.
tr_tpl_fill_items <- function(tp, p, items, width_in = 6.2) {
  if (is.null(p)) return(FALSE)
  items <- Filter(function(it) !is.null(it$value) && length(it$value) == 1 && !is.na(it$value) && nzchar(it$value) && (it$type != "pic" || file.exists(it$value)), items)
  if (!length(items)) return(FALSE)
  tr_tpl_clear_par(p)
  paras <- list(p); cur <- p
  for (k in seq_len(max(0, length(items) - 1))) { xml2::xml_add_sibling(cur, p, .where = "after", .copy = TRUE); cur <- xml2::xml_find_first(cur, "following-sibling::w:p[1]", tr_tpl_ns); paras[[length(paras) + 1]] <- cur }
  for (k in seq_along(items)) { it <- items[[k]]
    if (it$type == "pic") { xml2::xml_add_child(paras[[k]], tr_tpl_picture_run(tp, it$value, width_in)); tr_tpl_centre(paras[[k]]) }
    else { xml2::xml_add_child(paras[[k]], tr_tpl_run(it$value, if (it$type == "caption") "<w:rPr><w:b/></w:rPr>" else NULL))
           if (it$type == "caption") tr_tpl_keep_next(paras[[k]]) } }
  TRUE
}
# keep a caption on the same page as the picture under it
tr_tpl_keep_next <- function(p) {
  ppr <- xml2::xml_find_first(p, "./w:pPr", tr_tpl_ns)
  if (inherits(ppr, "xml_missing")) { xml2::xml_add_child(p, xml2::read_xml(paste0('<w:pPr xmlns:w="', tr_tpl_ns[["w"]], '"/>')), .where = 0); ppr <- xml2::xml_find_first(p, "./w:pPr", tr_tpl_ns) }
  if (!inherits(xml2::xml_find_first(ppr, "./w:keepNext", tr_tpl_ns), "xml_missing")) return(invisible(p))
  kn <- xml2::read_xml(paste0('<w:keepNext xmlns:w="', tr_tpl_ns[["w"]], '"/>'))
  st <- xml2::xml_find_first(ppr, "./w:pStyle", tr_tpl_ns)
  if (inherits(st, "xml_missing")) xml2::xml_add_child(ppr, kn, .where = 0) else xml2::xml_add_sibling(st, kn, .where = "after")
  invisible(p)
}
# Replace a placeholder paragraph by text lines and/or pictures (each on its own paragraph, centred pictures).
# `lines` are plain text paragraphs; `pics` file paths. Returns TRUE if something was written.
tr_tpl_fill_par <- function(tp, p, lines = character(0), pics = character(0), width_in = 6.2, empty_text = NULL) {
  if (is.null(p)) return(FALSE)
  lines <- lines[!is.na(lines) & nzchar(lines)]; pics <- pics[!is.na(pics) & file.exists(pics)]
  if (!length(lines) && !length(pics)) { if (is.null(empty_text)) return(FALSE); lines <- empty_text }
  tr_tpl_fill_items(tp, p, c(lapply(lines, function(l) list(type = "text", value = l)), lapply(pics, function(f) list(type = "pic", value = f))), width_in)
}
# Pictures (data.frame slot / event_id / caption / path) -> items: caption line (when there is one) then the picture
tr_tpl_pic_items <- function(pics) {
  if (is.null(pics) || !nrow(pics)) return(list())
  unlist(lapply(seq_len(nrow(pics)), function(i) { cap <- pics$caption[i]
    c(if (!is.na(cap) && nzchar(cap)) list(list(type = "caption", value = cap)), list(list(type = "pic", value = pics$path[i]))) }), recursive = FALSE)
}
tr_tpl_drop_par <- function(p) if (!is.null(p)) xml2::xml_remove(p)

# ---- Individual Trade Sheet --------------------------------------------------------------
# charts: list(entry = paths, trade = paths, exit = paths) (character vectors)
# pics: data.frame(slot, event_id, caption, path) with slot entry / entry_platform / intrade / exit / post_exit
# (tr_chart_frame() turns the older list(entry =, trade =, exit =) into this form).
tr_trade_sheet_template <- function(trade, legs, events, name, charts = list(), file) {
  pics <- tr_chart_frame(charts)
  sl <- function(...) pics[pics$slot %in% c(...), , drop = FALSE]
  path <- tr_tpl_find("Trade_Sheet_Template.docx"); tp <- tr_tpl_open(path); tb <- tr_tpl_tables(tp)
  tr_tpl_set(tr_tpl_cell(tb[[1]], 1, 2), name)
  vals <- c(tr_txt(trade$chart_period), tr_duration_text(trade$expected_duration_hours), tr_pips_text(trade$initial_risk_pips, trade$initial_risk_gbp), tr_pips_text(trade$initial_reward_pips, trade$initial_reward_pips * trade$stake_per_pip_gbp), tr_numtxt(trade$initial_rrr, 2))
  for (i in 1:5) tr_tpl_set(tr_tpl_cell(tb[[2]], i, 2), vals[i])
  ent <- c(tr_ddmmyyyy(trade$entry_ts), tr_hhmm(trade$entry_ts), trade$direction, tr_asset_label(trade$asset), tr_ntrim(trade$stake_per_pip_gbp, 2), tr_ntrim(trade$entry_price), tr_ntrim(trade$stop1), tr_ntrim(trade$target))
  for (j in seq_along(ent)) tr_tpl_set(tr_tpl_cell(tb[[3]], 2, j), ent[j], size = if (j == 1) 9 else NULL)
  txt <- c(trade$setup_fundamental, trade$setup_technical, trade$trigger_text, trade$execution_text, trade$stop_reason, trade$target_reason)
  for (i in 1:6) tr_tpl_set(tr_tpl_cell(tb[[4]], i, 2), tr_txt(txt[i]))
  # pictures and in-trade management
  p_entry <- tr_tpl_find_par(tp, "[Insert chart picture here]", 1); p_exit <- tr_tpl_find_par(tp, "[Insert chart picture here]", 2)
  tr_tpl_fill_items(tp, p_entry, tr_tpl_pic_items(rbind(sl("entry"), sl("entry_platform"))))
  # each stop move / partial exit is followed by its own chart (as in the LAT sample); other in-trade pictures after the list
  it_pics <- sl("intrade"); evs <- if (is.null(events)) NULL else events[order(events$event_ts), , drop = FALSE]
  lines <- tr_event_lines(trade, evs); items <- list(); used <- rep(FALSE, nrow(it_pics))
  for (k in seq_along(lines)) {
    items[[length(items) + 1]] <- list(type = "text", value = lines[k])
    hit <- !is.na(it_pics$event_id) & it_pics$event_id == evs$event_id[k]; used <- used | hit
    items <- c(items, tr_tpl_pic_items(it_pics[hit, , drop = FALSE]))
  }
  items <- c(items, tr_tpl_pic_items(it_pics[!used, , drop = FALSE]))
  if (!length(items)) items <- list(list(type = "text", value = "Not applicable: the stop and the limit were not changed and there was no partial exit."))
  tr_tpl_fill_items(tp, tr_tpl_find_par(tp, "if applicable", 1), items)
  # exit table
  dur <- if (nrow(legs) && any(is.finite(legs$duration_hours))) max(legs$duration_hours, na.rm = TRUE) else NA_real_
  tr_tpl_set(tr_tpl_cell(tb[[5]], 1, 2), if (is.finite(dur)) tr_duration_text(dur) else "")
  if (nrow(legs)) {
    opp <- ifelse(legs$direction == "B", "S", "B")
    ex <- data.frame(tr_ddmmyyyy(legs$exit_ts), tr_hhmm(legs$exit_ts), opp, tr_asset_label(legs$asset[1]), tr_ntrim(legs$stake_per_pip_gbp, 2), tr_ntrim(legs$entry_price), tr_ntrim(legs$exit_price),
                     tr_numtxt(legs$pips_result, 1), tr_numtxt(legs$net_pnl_gbp, 2), stringsAsFactors = FALSE)
    tr_tpl_fill_df(tb[[5]], ex, first = 4)
    for (i in seq_len(nrow(ex))) tr_tpl_set(tr_tpl_cell(tb[[5]], 3 + i, 1), ex[i, 1], size = 9)
  }
  last <- if (nrow(legs)) legs[which.max(legs$exit_ts), ] else trade
  code <- tr_exit_code_text(last$exit_code, last$exit_price, last$exit_ts)
  why <- tr_txt(last$reason_for_exit)
  tr_tpl_set(tr_tpl_cell(tb[[6]], 1, 2), trimws(paste(code, why)))
  tr_tpl_set(tr_tpl_cell(tb[[6]], 2, 2), tr_txt(last$lessons_learned))
  post <- sl("post_exit")
  tr_tpl_fill_items(tp, p_exit, c(tr_tpl_pic_items(sl("exit")), if (nrow(post)) c(list(list(type = "caption", value = "Post Exit")), tr_tpl_pic_items(transform(post, caption = ifelse(is.na(caption), NA, caption)))) else list()))
  # any placeholder that is still unused stays as the template's own prompt
  tr_tpl_save(tp, file)
}
tr_duration_text <- function(h) { if (!is.finite(h)) return(""); m <- round(h * 60); if (m >= 60) sprintf("%dHr %d Mins", m %/% 60, m %% 60) else sprintf("%d Mins", m) }
tr_pips_text <- function(p, gbp) { if (!is.finite(p)) return(""); paste0(tr_trim0(tr_numtxt(p, 1)), " pips", if (is.finite(gbp)) sprintf(" (\u00a3%s)", tr_numtxt(gbp, 2)) else "") }
# Factual part of "Reason for Exit" (the student's own explanation follows it), e.g. "S1 hit: stop loss 10649.5 reached at 12:55."
tr_exit_code_text <- function(code, price = NA, ts = NA) {
  code <- tr_txt(code); if (!nzchar(code)) return("")
  px <- if (length(price) && is.finite(suppressWarnings(as.numeric(price)))) tr_ntrim(as.numeric(price)) else ""
  at <- if (length(ts) && !is.na(ts[1])) paste(" at", format(ts[1], "%H:%M", tz = "Europe/London")) else ""
  if (!nzchar(px)) return(switch(code, S1 = "S1 hit.", `S2+` = "S2+ hit.", ME = "ME (manual exit).", T = "T hit.", paste0(code, ".")))
  switch(code, S1 = sprintf("S1 hit: stop loss %s reached%s.", px, at), `S2+` = sprintf("S2+ hit: trailing stop %s reached%s.", px, at),
         ME = sprintf("ME (manual exit) at %s%s.", px, at), T = sprintf("T hit: target %s reached%s.", px, at), sprintf("%s at %s%s.", code, px, at))
}
tr_event_lines <- function(trade, events) {
  if (is.null(events) || !nrow(events)) return(character(0))
  events <- events[order(events$event_ts), , drop = FALSE]
  vapply(seq_len(nrow(events)), function(i) { ev <- events[i, ]
    if (identical(ev$event_type, "STOP_MOVE")) {
      pr <- tr_pips_at(trade$entry_price, ev$new_stop, trade$direction, trade$pip_size)
      sprintf("%s %s: stop moved from %s to %s (%s)%s", tr_ddmmyyyy(ev$event_ts), tr_hhmm(ev$event_ts), tr_ntrim(ev$old_stop), tr_ntrim(ev$new_stop),
              if (is.finite(pr)) (if (pr > 0) sprintf("%.1f pips of risk", pr) else sprintf("%.1f pips of profit locked", -pr)) else "",
              if (!is.na(ev$reason) && nzchar(ev$reason)) paste0(". Your reason: ", ev$reason) else "")
    } else sprintf("%s %s: part of the position closed (%s per pip) at %s%s", tr_ddmmyyyy(ev$event_ts), tr_hhmm(ev$event_ts), tr_ntrim(ev$size_closed_per_pip, 2), tr_ntrim(ev$price),
                   if (!is.na(ev$reason) && nzchar(ev$reason)) paste0(". Your reason: ", ev$reason) else "") }, "")
}

# ---- Morning Sheet -----------------------------------------------------------------------
tr_morning_template <- function(sheet, levels, name, file, cal_o = character(0), cal_t = character(0)) {
  path <- tr_tpl_find("Morning_Sheet_Template.docx"); tp <- tr_tpl_open(path); tb <- tr_tpl_tables(tp)
  tr_tpl_set(tr_tpl_cell(tb[[1]], 1, 2), name); tr_tpl_set(tr_tpl_cell(tb[[1]], 3, 2), format(sheet$sheet_date, "%d/%m/%Y"))
  chg <- function(p, pts) { if (is.finite(pts) && is.finite(p)) sprintf("%+.2f (%+.2f%%)", pts, p) else if (is.finite(p)) sprintf("%+.2f%%", p) else if (is.finite(pts)) sprintf("%+.2f", pts) else "" }
  big <- function(x) ifelse(is.finite(x), formatC(x, format = "f", digits = 2, big.mark = ","), "")
  tr_tpl_fill_df(tb[[2]], data.frame(Price = c(big(sheet$dow_price), big(sheet$nikkei_price)),
                                      Change = c(chg(sheet$dow_change_pct, sheet$dow_change_pts), chg(sheet$nikkei_change_pct, sheet$nikkei_change_pts)), stringsAsFactors = FALSE), first = 2, col0 = 2)
  rows <- tr_morning_rows(levels)
  tr_tpl_fill_df(tb[[3]], rows$fx, first = 2, col0 = 1); tr_tpl_fill_df(tb[[4]], rows$cm, first = 2, col0 = 1)
  news <- tr_txt(sheet$overnight_news)
  txt_o <- tr_txt(sheet$overnight_calendar); txt_t <- c(tr_txt(sheet$todays_releases), tr_txt(sheet$releases_in_window))
  split <- function(x) unlist(strsplit(x[nzchar(x)], "\r?\n"))
  p_o <- tr_tpl_find_par(tp, "Economic Calendar from overnight"); p_t <- tr_tpl_find_par(tp, "Economic Calendar for today")
  # today's paragraph first (it comes later in the body), so the earlier one is not disturbed
  keep <- function(txt, pics) if (length(pics) && tr_calendar_is_table(paste(txt, collapse = "\n"))) character(0) else split(txt)   # pictures replace the typed calendar table
  tr_tpl_fill_par(tp, p_t, lines = keep(txt_t, cal_t), pics = cal_t, width_in = 6.2)
  tr_tpl_fill_par(tp, p_o, lines = c(split(news), keep(txt_o, cal_o)), pics = cal_o, width_in = 6.2)   # the news always prints; only a typed calendar table gives way to the picture
  tr_tpl_save(tp, file)
}
