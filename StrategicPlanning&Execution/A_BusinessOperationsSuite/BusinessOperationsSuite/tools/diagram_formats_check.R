# tools/diagram_formats_check.R - every format from one picture; files read back with magick / pdftools.
suppressMessages({ library(shiny); library(plotly) })
source("R/utils_gdrive.R"); source("R/utils_diagram_export.R")
pass <- 0; fail <- 0
check <- function(n, ok, d = NULL) { ok <- isTRUE(ok); cat(if (ok) "PASS " else "FAIL ", n, if (!ok && !is.null(d)) paste(" ->", paste(format(d), collapse = " ")), "\n", sep = ""); if (ok) pass <<- pass + 1 else fail <<- fail + 1 }
img <- magick::image_blank(900, 500, "#3366cc")
img <- magick::image_annotate(img, "Test diagram", size = 60, color = "white", gravity = "center")
png <- magick::image_write(img, format = "png")
df <- data.frame(category = c("Grants", "Loans, soft"), programmes = c(3, 2))
p <- plot_ly(df, x = ~category, y = ~programmes, type = "bar")
spec <- list(title = "Programmes by Category", subtitle = "All", plot = p, data = df)
files <- diagram_build_files(spec, c("html", "pdf", "png", "jpg", "gif", "tiff", "svg", "csv"), png)
fm <- vapply(files, `[[`, "", "format"); by <- setNames(lapply(files, `[[`, "bytes"), fm)
check("8 files in order", identical(fm, c("html", "pdf", "png", "jpg", "gif", "tiff", "svg", "csv")), fm)
h <- rawToChar(by$html)
check("plotly HTML: interactive page with the data", grepl("cdn.plot.ly", h) && grepl("Plotly.newPlot", h) && grepl("Loans, soft", h))
for (f in c("jpg", "gif", "tiff", "png")) {
  i <- magick::image_info(magick::image_read(by[[f]]))
  check(sprintf("%s readable, 900x500", f), i$width == 900 && i$height == 500 && tolower(i$format) %in% c(f, if (f == "jpg") "jpeg", if (f == "tiff") "tiff"), i)
}
tf <- tempfile(fileext = ".pdf"); writeBin(by$pdf, tf)
pi <- pdftools::pdf_info(tf)
check("PDF: one A4 landscape page", pi$pages == 1 && round(pdftools::pdf_pagesize(tf)$width) %in% c(841, 842) && round(pdftools::pdf_pagesize(tf)$height) %in% c(595, 596), pdftools::pdf_pagesize(tf))
r <- pdftools::pdf_render_page(tf, dpi = 30)
check("PDF page shows the picture (blue in the middle)", { px <- r[, dim(r)[2] %/% 2, dim(r)[3] %/% 2]; as.integer(px[3]) > 150 && as.integer(px[1]) < 120 }, r[, dim(r)[2] %/% 2, dim(r)[3] %/% 2])
check("SVG wraps the PNG", grepl("^<svg", rawToChar(by$svg)) && grepl("data:image/png;base64,", rawToChar(by$svg)))
check("CSV quotes", grepl('"Loans, soft"', rawToChar(by$csv)) && startsWith(rawToChar(by$csv), '"category","programmes"'))
# image page when there is no interactive HTML
f2 <- diagram_build_files(list(title = "BM <Canvas>", subtitle = "a / b", data = data.frame(box = "Key Partners", content = "x & y")), c("html"), png)
h2 <- rawToChar(f2[[1]]$bytes)
check("image page: embedded PNG + escaped table", grepl("data:image/png;base64,", h2) && grepl("BM &lt;Canvas&gt;", h2) && grepl("x &amp; y", h2))
# generated diagrams
sv <- '<p>Here:</p><svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"><rect width="10" height="10"/></svg>'
s3 <- diagram_code_spec(sv, "svg", "Flowchart", "show the order process from cart to delivery", "Claude")
check("svg: title from type + instructions", s3$title == "Flowchart - show the order process from cart")
check("svg: vector SVG extracted", startsWith(s3$vector_svg, "<svg") && endsWith(s3$vector_svg, "</svg>"))
f3 <- diagram_build_files(s3, c("svg"), NULL)
check("svg format uses the real vector SVG (no picture needed)", startsWith(rawToChar(f3[[1]]$bytes), "<svg"))
s4 <- diagram_code_spec("graph TD; A-->B", "mermaid", "Flowchart", "", "ChatGPT")
f4 <- diagram_build_files(s4, c("html", "source"), NULL)
check("mermaid: page + .mmd source", grepl("mermaid.initialize", rawToChar(f4[[1]]$bytes)) && f4[[2]]$ext == "mmd" && rawToChar(f4[[2]]$bytes) == "graph TD; A-->B")
check("no code -> not ready", isFALSE(diagram_code_spec(NULL, "svg", "x", "", "x")$ready))
check("available formats", identical(diagram_available(list(data = df)), c("html", DIAGRAM_IMAGE_FORMATS, "csv")) &&
      identical(diagram_available(s4), c("html", DIAGRAM_IMAGE_FORMATS, "source")))
check("plain text from canvas HTML", diagram_plain("<p><strong>Who</strong> are&nbsp;our partners?</p><p>B &amp; C</p>") == "Who are our partners?\nB & C")
cat(sprintf("\n%d passed, %d failed\n", pass, fail)); quit(status = if (fail) 1 else 0)
