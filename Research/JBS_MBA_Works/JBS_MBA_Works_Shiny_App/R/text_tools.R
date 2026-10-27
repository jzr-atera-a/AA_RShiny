# =============================================================================
# text_tools.R \u2014 Text database and analysis (no external services)
# data/works_text_v2.json holds every page: printed text (pdftotext) and any
# text read from images (OCR), plus section outlines and the front matter.
# =============================================================================

`%||%` <- function(a, b) if (is.null(a)) b else a

TEXT_DB <- jsonlite::fromJSON(file.path("data", "works_text_v2.json"), simplifyVector = FALSE)
WORK_BY_ID <- setNames(WORKS, vapply(WORKS, `[[`, character(1), "id"))

# ---- Page access -------------------------------------------------------------
page_nums   <- function(id) vapply(TEXT_DB[[id]]$pages, function(p) as.integer(p$n), integer(1))
page_titles <- function(id) vapply(TEXT_DB[[id]]$pages, function(p) p$title %||% "", character(1))
page_ocr    <- function(id) vapply(TEXT_DB[[id]]$pages, function(p) p$ocr %||% "", character(1))
page_texts  <- function(id) vapply(TEXT_DB[[id]]$pages, function(p) {
  o <- p$ocr %||% ""
  if (nzchar(o)) paste0(p$text, "\n\n[Text inside an image, read by OCR]\n", o) else p$text
}, character(1))

words_in <- function(text) {
  t <- trimws(text)
  if (!nzchar(t)) 0L else length(strsplit(t, "\\s+")[[1]])
}

# ---- Search ------------------------------------------------------------------
find_spans <- function(text, q, whole = FALSE) {
  q <- tolower(trimws(q))
  empty <- matrix(integer(0), ncol = 2)
  if (!nzchar(q) || !nzchar(text)) return(empty)
  st <- gregexpr(q, tolower(text), fixed = TRUE)[[1]]
  if (st[1] == -1) return(empty)
  m <- cbind(as.integer(st), as.integer(st) + nchar(q) - 1L)
  if (whole && nrow(m) > 0) {
    n <- nchar(text)
    keep <- vapply(seq_len(nrow(m)), function(k) {
      before <- if (m[k, 1] > 1) substr(text, m[k, 1] - 1L, m[k, 1] - 1L) else ""
      after  <- if (m[k, 2] < n) substr(text, m[k, 2] + 1L, m[k, 2] + 1L) else ""
      !grepl("[[:alpha:]]", before) && !grepl("[[:alpha:]]", after)
    }, logical(1))
    m <- m[keep, , drop = FALSE]
  }
  m
}

hl_html <- function(text, q, whole = FALSE) {
  sp <- find_spans(text, q, whole)
  if (nrow(sp) == 0) return(as.character(htmltools::htmlEscape(text)))
  n <- nchar(text)
  out <- character(0)
  pos <- 1L
  for (k in seq_len(nrow(sp))) {
    s <- sp[k, 1]; e <- sp[k, 2]
    out <- c(out,
             as.character(htmltools::htmlEscape(substr(text, pos, s - 1L))),
             "<mark>", as.character(htmltools::htmlEscape(substr(text, s, e))), "</mark>")
    pos <- e + 1L
  }
  out <- c(out, as.character(htmltools::htmlEscape(substr(text, pos, n))))
  paste(out, collapse = "")
}

snippets <- function(text, q, width = 110, max_n = 2, whole = FALSE) {
  sp <- find_spans(text, q, whole)
  if (nrow(sp) == 0) return(character(0))
  sp <- sp[seq_len(min(max_n, nrow(sp))), , drop = FALSE]
  n <- nchar(text)
  vapply(seq_len(nrow(sp)), function(k) {
    s <- max(1L, sp[k, 1] - width)
    e <- min(n, sp[k, 2] + width)
    if (s > 1) { while (s < sp[k, 1] && substr(text, s, s) != " ") s <- s + 1L }
    if (e < n) { while (e > sp[k, 2] && substr(text, e, e) != " ") e <- e - 1L }
    piece <- gsub("\\s+", " ", substr(text, s, e))
    paste0(if (s > 1) "\u2026 " else "", hl_html(piece, q, whole), if (e < n) " \u2026" else "")
  }, character(1))
}

full_text <- function(id) {
  if (id == "FRONT") {
    pgs <- TEXT_DB$FRONT$pages
    body <- vapply(seq_along(pgs), function(k) {
      paste0("[", pgs[[k]]$title, "]\n", page_texts("FRONT")[k])
    }, character(1))
    return(paste0("Cover, dedication, introductions and index\n", strrep("=", 70), "\n\n",
                  paste(body, collapse = "\n\n"), "\n"))
  }
  w <- WORK_BY_ID[[id]]
  nums <- page_nums(id); txs <- page_texts(id)
  body <- vapply(seq_along(nums), function(k) paste0("[Page ", nums[k], "]\n", txs[k]), character(1))
  paste0(w$code, " - ", w$title, "\n", w$type, " | Hand-in: ",
         if (is.na(w$hand_in)) "Undated" else format(w$hand_in, "%d %B %Y"),
         " | Printed pages ", w$pages_label, "\n", strrep("=", 70), "\n\n",
         paste(body, collapse = "\n\n"), "\n")
}

# ---- Language statistics -----------------------------------------------------
STOPWORDS <- c("this","january","february","march","april","june","july","august","september","october","november","december","prof","dr","individual","assignment","coursework","programme","handbook","student","cover","sheet","lecturer","course","hand","date","count","word","words","name","number","grade","numbers","blind","plagiarism","guidelines","judge","business","school","cambridge","confirm","violate","violates","work","piece","own","see","details","http","https","http","www","com","org","html","accessed","available","retrieved","meta","cambridge","figure","table","pages","page","also","such","more","less","used","using","based","well","much","many","each","other","which","these","those","into","over","under","about","between","after","before","within","without","through","during","while","where","when","what","then","than","them","they","your","ours","yours","been","being","does","doing","make","made","like","just","only","very","most","some","any","all","are","was","its","our","can","may","might","must","should","could","shall","not","nor","but","and","for","the","you","per","via","etc","et","al","thus","hence","therefore","however","although","whether","either","neither","both", "that","with","from","have","has","had","were","will","would","their","there","percent","cent","fig","pp",
               "which","what","when","where","these","those","into","over","under","about","also","can",
               "could","should","such","than","then","more","most","other","some","any","each","only",
               "same","both","few","its","our","out","off","how","all","too","very","just","may","might",
               "must","been","being","because","while","during","through","between","against","within",
               "without","upon","onto","they","them","your","yours","here","many","much","made","make",
               "like","well","however","therefore","thus","first","second","third","new","use","used",
               "using","based","including","include","one","two","three","four","five","per","via","etc",
               "are","was","not","but","for","and","the","you","who","whom","his","her","she","it's","across",
               "after","before","above","below","again","further","once","still","even","every","whilst",
               "whether","does","did","doing","done","get","got","way","ways","part","parts","often",
               "since","until","around","among","along","whose","whereas","though","although","isn't",
               "don't","doesn't","i'm","we're","they're","there's","that's","it's","let's","rather","yet")

content_tokens <- function(text) {
  toks <- strsplit(gsub("[^a-z]+", " ", tolower(text)), " ")[[1]]
  toks[nchar(toks) >= 4 & !(toks %in% STOPWORDS)]
}

text_stats <- function(id) {
  txs <- page_texts(id)
  all <- paste(txs, collapse = "\n")
  words <- sum(vapply(txs, words_in, integer(1)))
  sents <- sentence_lengths(id)
  cites <- citation_table(id)
  toks <- content_tokens(all)
  list(words = words, pages = length(txs), sentences = length(sents),
       citations = nrow(cites), unique_terms = length(unique(toks)),
       minutes = max(1, round(words / 230)),
       avg_sentence = if (length(sents)) round(mean(sents), 1) else 0,
       ocr_pages = sum(nzchar(page_ocr(id))))
}

keyword_table <- function(id, n = 15) {
  toks <- content_tokens(paste(page_texts(id), collapse = " "))
  tb <- sort(table(toks), decreasing = TRUE)
  tb <- head(tb, n)
  data.frame(term = names(tb), count = as.integer(tb), stringsAsFactors = FALSE)
}

sentence_lengths <- function(id) {
  all <- paste(page_texts(id), collapse = " ")
  s <- strsplit(all, "(?<=[.!?])\\s+(?=[A-Z])", perl = TRUE)[[1]]
  s <- s[nzchar(trimws(s))]
  as.integer(lengths(strsplit(trimws(s), "\\s+")))
}

# In-text citations such as (Fisher, Ury and Patton, 2011)
CITE_PAT <- "\\(([A-Z][A-Za-z'\\-]+)[^()]{0,80}?((?:19|20)[0-9]{2})[a-z]?[^()]{0,20}\\)"
CITE_STOP <- c("ABC","Advanced","Business","HR","The","Level","Step","Stage","Phase","Option","Box","Example","Accessed", "Available", "Retrieved", "See", "Also", "Figure", "Table", "Appendix", "Note", "Source", "Sources", "Data", "Exhibit", "Online", "Ibid", "Cf", "Chapter", "Page", "Pages", "Week", "Section", "Slide", "Slides", "Eg", "Ie")
citation_table <- function(id) {
  all <- paste(page_texts(id), collapse = "\n")
  hits <- regmatches(all, gregexpr(CITE_PAT, all, perl = TRUE))[[1]]
  if (length(hits) == 0) return(data.frame(author = character(), year = integer(), stringsAsFactors = FALSE))
  g <- regmatches(hits, regexec(CITE_PAT, hits, perl = TRUE))
  out <- data.frame(author = vapply(g, function(x) x[2], character(1)),
                    year = as.integer(vapply(g, function(x) x[3], character(1))),
                    stringsAsFactors = FALSE)
  out[!(out$author %in% CITE_STOP), , drop = FALSE]
}

section_table <- function(id) {
  o <- TEXT_DB[[id]]$outline
  empty <- data.frame(title = character(), page = integer(), words = integer(), stringsAsFactors = FALSE)
  if (length(o) == 0) return(empty)
  nums <- page_nums(id)
  wc <- vapply(page_texts(id), words_in, integer(1))
  pages <- vapply(o, function(s) as.integer(s$page), integer(1))
  titles <- vapply(o, function(s) s$title, character(1))
  ord <- order(pages)
  pages <- pages[ord]; titles <- titles[ord]
  keep <- !duplicated(pages)
  pages <- pages[keep]; titles <- titles[keep]
  nxt <- c(pages[-1], max(nums) + 1L)
  words <- vapply(seq_along(pages), function(k) sum(wc[nums >= pages[k] & nums < nxt[k]]), integer(1))
  data.frame(title = titles, page = pages, words = as.integer(words), stringsAsFactors = FALSE)
}

# Share of each work's content words per 1000 words (for comparisons)
token_profile <- function(id) {
  txs <- page_texts(id)
  total <- max(1, sum(vapply(txs, words_in, integer(1))))
  tb <- table(content_tokens(paste(txs, collapse = " ")))
  data.frame(term = names(tb), count = as.integer(tb), per1000 = as.numeric(tb) / total * 1000,
             stringsAsFactors = FALSE)
}

# Occurrences of a search term per work and per page (whole words)
term_by_work <- function(term, whole = TRUE) {
  rows <- lapply(WORKS, function(w) {
    txs <- page_texts(w$id); nums <- page_nums(w$id)
    cnt <- vapply(txs, function(t) nrow(find_spans(t, term, whole)), integer(1))
    total <- max(1, sum(vapply(txs, words_in, integer(1))))
    data.frame(code = w$code, term_name = w$term, count = sum(cnt),
               per1000 = sum(cnt) / total * 1000, stringsAsFactors = FALSE)
  })
  do.call(rbind, rows)
}

term_by_page <- function(id, term, whole = TRUE) {
  txs <- page_texts(id); nums <- page_nums(id)
  data.frame(page = nums, matches = vapply(txs, function(t) nrow(find_spans(t, term, whole)), integer(1)),
             stringsAsFactors = FALSE)
}

# Top content words across the collection, per 1000 words, for the heatmap
collection_matrix <- function(n = 25) {
  profs <- lapply(WORKS, function(w) token_profile(w$id))
  names(profs) <- vapply(WORKS, `[[`, character(1), "id")
  totals <- sort(tapply(unlist(lapply(profs, function(p) p$count)),
                        unlist(lapply(profs, function(p) p$term)), sum), decreasing = TRUE)
  top <- names(head(totals, n))
  m <- vapply(names(profs), function(id) {
    p <- profs[[id]]
    vapply(top, function(t) { v <- p$per1000[p$term == t]; if (length(v)) v else 0 }, numeric(1))
  }, numeric(length(top)))
  m <- matrix(m, nrow = length(top), dimnames = list(top, names(profs)))
  m
}

citation_collection <- function() {
  rows <- lapply(WORKS, function(w) {
    ct <- citation_table(w$id)
    if (nrow(ct) == 0) return(NULL)
    data.frame(term_name = w$term, year = ct$year, stringsAsFactors = FALSE)
  })
  do.call(rbind, rows)
}

# ---- Summaries and key passages built from the printed text ------------------
split_sentences <- function(txt) {
  s <- strsplit(gsub("\\s+", " ", txt), "(?<=[.!?])\\s+(?=[A-Z])", perl = TRUE)[[1]]
  s <- trimws(s)
  s[nzchar(s)]
}

printed_pages <- function(id) vapply(TEXT_DB[[id]]$pages, function(p) p$text, character(1))

# Each detected section with its full printed text, page range and word count
section_blocks <- function(id) {
  st <- section_table(id)
  if (nrow(st) == 0) return(list())
  nums <- page_nums(id); raws <- printed_pages(id)
  nxt <- c(st$page[-1], max(nums) + 1L)
  lapply(seq_len(nrow(st)), function(k) {
    idx <- which(nums >= st$page[k] & nums < nxt[k])
    list(title = st$title[k], page_from = st$page[k], page_to = max(st$page[k], nxt[k] - 1L),
         words = st$words[k], text = paste(raws[idx], collapse = " "))
  })
}

# Opening sentences of a passage, used as its summary
opening_sentences <- function(txt, n = 2) {
  s <- split_sentences(txt)
  w <- lengths(strsplit(s, "\\s+"))
  s <- s[nchar(s) > 40 & w >= 8 & w <= 45]
  if (length(s) == 0) {
    words <- strsplit(trimws(txt), "\\s+")[[1]]
    if (length(words) == 0) return(character())
    return(paste0(paste(head(words, 45), collapse = " "), if (length(words) > 45) " \u2026" else ""))
  }
  head(s, n)
}

# Units for section-level text: real sections where at least two exist, otherwise one unit per printed page
summary_units <- function(id) {
  secs <- section_blocks(id)
  if (length(secs) >= 2) {
    return(lapply(secs, function(s) list(
      kind = "Section", title = s$title, label = sprintf("pp. %d\u2013%d", s$page_from, s$page_to),
      words = s$words, text = s$text)))
  }
  nums <- page_nums(id); raws <- printed_pages(id); ttls <- page_titles(id)
  lapply(seq_along(raws), function(k) {
    opening <- strsplit(trimws(raws[k]), "\\s+")[[1]]
    fallback <- if (grepl("cover sheet", raws[k], ignore.case = TRUE)) "Assignment cover sheet" else
      paste0(paste(head(opening, 7), collapse = " "), if (length(opening) > 7) " \u2026" else "")
    list(kind = "Page", title = if (nzchar(ttls[k])) ttls[k] else fallback,
         label = paste("p.", nums[k]), words = words_in(raws[k]), text = raws[k])
  })
}

# Most frequent content words in a passage
top_terms <- function(txt, n = 6) {
  tk <- content_tokens(txt)
  if (length(tk) == 0) return(character())
  tb <- sort(table(tk), decreasing = TRUE)
  names(tb)[seq_len(min(n, length(tb)))]
}

# Sentences that best carry the work's main vocabulary, with their page numbers
key_quotes <- function(id, n = 3) {
  raws <- printed_pages(id); nums <- page_nums(id)
  all_tk <- content_tokens(paste(raws, collapse = " "))
  if (length(all_tk) == 0) return(list())
  tb <- sort(table(all_tk), decreasing = TRUE)
  top <- names(tb)[seq_len(min(15, length(tb)))]
  cand <- list()
  for (k in seq_along(raws)) for (s in split_sentences(raws[k])) {
    w <- length(strsplit(s, "\\s+")[[1]])
    if (w < 12 || w > 40) next
    sc <- sum(content_tokens(s) %in% top) / sqrt(w)
    if (sc > 0) cand[[length(cand) + 1]] <- list(text = s, page = nums[k], score = sc)
  }
  if (length(cand) == 0) return(list())
  picked <- list()
  for (i in order(-vapply(cand, `[[`, numeric(1), "score"))) {
    s <- cand[[i]]$text
    if (any(vapply(picked, function(p) substr(p$text, 1, 40) == substr(s, 1, 40), logical(1)))) next
    picked[[length(picked) + 1]] <- cand[[i]]
    if (length(picked) == n) break
  }
  picked[order(vapply(picked, `[[`, numeric(1), "page"))]
}

# Citations grouped by author and year, most frequent first
citation_summary <- function(id) {
  ct <- citation_table(id)
  if (nrow(ct) == 0) return(data.frame(author = character(), year = integer(), count = integer()))
  ag <- aggregate(list(count = ct$author), by = list(author = ct$author, year = ct$year), FUN = length)
  ag[order(-ag$count, ag$author, ag$year), , drop = FALSE]
}

# ---- Analysis of what the text is doing ---------------------------------------
# Each sentence is assigned one rhetorical role. The first matching role wins, in this order.
RHET_ORDER <- c("Recommendation", "Evidence", "Framework", "Reasoning", "Reflection", "Claim")
RHET_PAT <- list(
  Recommendation = "\\b(should|must|recommend\\w*|ought|need to|needs to|propos\\w*|advis\\w*|next steps?|we suggest)\\b",
  Evidence       = "(\\d+(\\.\\d+)?\\s?%|[$]\\s?\\d|\\b(USD|GBP|EUR)\\b|\\([A-Z][^()]{1,60}\\b(19|20)\\d{2}[a-z]?\\)|according to|survey|statistic\\w*|data (shows?|suggests?|indicates?)|research (shows?|found|suggests?))",
  Framework      = "\\b(framework|model|matrix|methodolog\\w*|approach|theor(y|ies)|tools?|DMADV|DMAIC|SWOT|PESTEL|Porter|Gage|RCA|canvas)\\b",
  Reasoning      = "\\b(because|therefore|thus|hence|as a result|which means|implies?|suggests?|consequently|leads? to|so that)\\b"
)
RHET_REFLECT <- "(?-i:\\bI\\b)|(?i)\\b(my|me|learn\\w*|reflect\\w*|realis\\w*|realiz\\w*|personally)\\b"

# Currency amounts are matched separately (plain regex) so the perl patterns stay ASCII
# Pound and euro signs become words first, so the ASCII patterns can match them
norm_cur <- function(s) {
  s <- gsub(intToUtf8(163), "GBP ", s, fixed = TRUE)
  gsub(intToUtf8(8364), "EUR ", s, fixed = TRUE)
}
classify_sentence <- function(s) {
  s <- norm_cur(s)
  for (r in names(RHET_PAT)) if (grepl(RHET_PAT[[r]], s, ignore.case = TRUE, perl = TRUE)) return(r)
  if (grepl(RHET_REFLECT, s, perl = TRUE)) return("Reflection")
  "Claim"
}

# Share of sentences in each rhetorical role, per printed page
argument_flow <- function(id) {
  nums <- page_nums(id); raws <- printed_pages(id)
  rows <- lapply(seq_along(raws), function(k) {
    s <- split_sentences(raws[k])
    cats <- if (length(s)) vapply(s, classify_sentence, character(1), USE.NAMES = FALSE) else character()
    n <- vapply(RHET_ORDER, function(r) sum(cats == r), integer(1))
    data.frame(page = nums[k], role = RHET_ORDER, n = as.integer(n), stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, rows)
  tot <- tapply(out$n, out$page, sum)
  out$share <- ifelse(out$page %in% names(tot)[tot > 0], out$n / as.numeric(tot[as.character(out$page)]) * 100, 0)
  out
}

# Count of sentences per role across the whole work
role_counts <- function(id) {
  af <- argument_flow(id)
  tb <- tapply(af$n, af$role, sum)
  setNames(as.integer(tb[RHET_ORDER]), RHET_ORDER)
}

# Concept vocabulary of every work, computed once
WORK_TOKENS <- lapply(WORKS, function(w) content_tokens(paste(printed_pages(w$id), collapse = " ")))
names(WORK_TOKENS) <- vapply(WORKS, `[[`, character(1), "id")
DOC_FREQ <- table(unlist(lapply(WORK_TOKENS, unique)))

# Words used far more in this work than in the other works (TF-IDF style)
distinctive_terms <- function(id, n = 10, min_count = 3) {
  tk <- WORK_TOKENS[[id]]
  if (length(tk) == 0) return(data.frame(term = character(), count = integer(), per1000 = numeric(), score = numeric()))
  tb <- table(tk)
  tb <- tb[tb >= min_count]
  authors <- tolower(citation_table(id)$author)
  people <- tolower(unlist(strsplit(named_actors(id, 50)$name, " ")))
  tb <- tb[!(names(tb) %in% c(authors, people))]
  if (length(tb) == 0) return(data.frame(term = character(), count = integer(), per1000 = numeric(), score = numeric()))
  df <- as.numeric(DOC_FREQ[names(tb)])
  idf <- log(length(WORKS) / df)
  score <- (as.numeric(tb) / length(tk)) * idf
  ord <- order(-score)[seq_len(min(n, length(tb)))]
  data.frame(term = names(tb)[ord], count = as.integer(tb)[ord],
             per1000 = round(as.numeric(tb)[ord] / length(tk) * 1000, 1),
             score = round(score[ord] * 1000, 2), stringsAsFactors = FALSE)
}

# Occurrences of the distinctive concepts on each printed page
concept_by_page <- function(id, terms) {
  nums <- page_nums(id); raws <- printed_pages(id)
  m <- vapply(raws, function(r) {
    tb <- table(content_tokens(r))
    vapply(terms, function(t) if (t %in% names(tb)) as.numeric(tb[[t]]) else 0, numeric(1))
  }, numeric(length(terms)))
  if (is.null(dim(m))) m <- matrix(m, nrow = length(terms))
  dimnames(m) <- list(terms, paste0("p", nums))
  m
}

ACTOR_STOP <- c("Accessed","USD","GBP","EUR","AUM","ESG","AI","ASRS","What","Why","How","Who","Where","Appendices","Appendix","The","This","That","These","Those","However","In","It","Its","For","From","Figure","Table","Appendix",
  "Section","Chapter","Introduction","Conclusion","Recommendations","Cambridge","MBA","JBS","Judge","Business","School",
  "Page","January","February","March","April","May","June","July","August","September","October","November","December",
  "Week","Slide","Key","Example","Also","Our","We","They","Their","There","When","While","Although","Overall","Finally",
  "First","Second","Third","Given","Because","Therefore","Thus","Hence","Moreover","Furthermore","Additionally","Summary",
  "Overview","Background","Problem","Analysis","Strategy","Market","Markets","Figure","Source","Sources","Dashboard",
  "Individual","Assignment","Student","Word","Count","Hand","Date","Name","Lecturer","Course","Question","Answer","Results",
  "Global","Data","Risk","Value","Growth","Financial","Business","Management","Leadership","Corporate","Group","Team")

ALL_WORDS <- gsub("[^A-Za-z\']", "", unlist(strsplit(paste(unlist(lapply(WORKS, function(w) printed_pages(w$id))), collapse = " "), "\\s+")))
ALL_WORDS <- ALL_WORDS[nzchar(ALL_WORDS)]
LOWER_COUNT <- as.list(table(tolower(ALL_WORDS)))
CAP_COUNT <- as.list(table(ALL_WORDS[grepl("^[A-Z]", ALL_WORDS)]))

# Named organisations and people (capitalised phrases not at the start of a sentence)
named_actors <- function(id, n = 10) {
  phrases <- character()
  for (t in printed_pages(id)) for (s in split_sentences(t)) {
    w <- strsplit(s, "\\s+")[[1]]
    if (length(w) < 2) next
    cap <- grepl("^[A-Z][A-Za-z&'-]{2,}[.,;:)]?$", w)
    cap[1] <- FALSE
    runs <- rle(cap); pos <- 1
    for (k in seq_along(runs$lengths)) {
      L <- runs$lengths[k]
      if (runs$values[k]) {
        idx <- pos:(pos + L - 1)
        for (chunk in split(idx, ceiling(seq_along(idx) / 3))) {
          ph <- gsub("[.,;:)]$", "", paste(w[chunk], collapse = " "))
          phrases <- c(phrases, ph)
        }
      }
      pos <- pos + L
    }
  }
  phrases <- sub("'s$", "", phrases)
  phrases <- phrases[!grepl("-", phrases)]
  phrases <- phrases[!vapply(phrases, function(p) all(strsplit(p, " ")[[1]] %in% ACTOR_STOP), logical(1))]
  phrases <- phrases[!vapply(phrases, function(p) any(vapply(strsplit(p, " ")[[1]], function(w) {
    w <- sub("'s$", "", w); lc <- LOWER_COUNT[[tolower(w)]] %||% 0; uc <- CAP_COUNT[[w]] %||% 0
    lc > uc
  }, logical(1))), logical(1))]
  if (length(phrases) == 0) return(data.frame(name = character(), count = integer()))
  tb <- sort(table(phrases), decreasing = TRUE)
  tb <- tb[tb >= 2]
  if (length(tb) == 0) return(data.frame(name = character(), count = integer()))
  head(data.frame(name = names(tb), count = as.integer(tb), stringsAsFactors = FALSE), n)
}

# Sentences that carry a figure: a percentage, a currency amount, or a number with million, billion and similar
FIGURE_PAT <- "((GBP|EUR|USD)\\s?\\d[\\d,.]*(\\s?(million|billion|bn|m|k))?|\\d[\\d,.]*\\s?(%|percent|per cent)|[$]\\s?\\d[\\d,.]*(\\s?(million|billion|bn|m|k))?|\\d[\\d,.]*\\s(million|billion|thousand))"
figure_table <- function(id, n = 10) {
  nums <- page_nums(id); raws <- printed_pages(id)
  rows <- list()
  for (k in seq_along(raws)) for (s in split_sentences(raws[k])) {
    m <- regmatches(norm_cur(s), gregexpr(FIGURE_PAT, norm_cur(s), perl = TRUE))[[1]]
    if (length(m) == 0) next
    ctx <- if (nchar(s) > 200) paste0(substr(s, 1, 197), "...") else s
    m <- head(unique(m), 3)
    m <- gsub("GBP ", intToUtf8(163), gsub("EUR ", intToUtf8(8364), m, fixed = TRUE), fixed = TRUE)
    rows[[length(rows) + 1]] <- data.frame(figure = paste(m, collapse = ", "), page = nums[k],
                                           context = ctx, stringsAsFactors = FALSE)
  }
  if (length(rows) == 0) return(data.frame(figure = character(), page = integer(), context = character()))
  out <- do.call(rbind, rows)
  out <- out[!duplicated(out$context), , drop = FALSE]
  head(out, n)
}

# Headline figures for the Insights tab
insight_figures <- function(id) {
  rc <- role_counts(id)
  list(recommendations = rc[["Recommendation"]], evidence = rc[["Evidence"]],
       frameworks = rc[["Framework"]], reasoning = rc[["Reasoning"]],
       actors = nrow(named_actors(id, 50)), concepts = length(WORK_TOKENS[[id]]) > 0,
       figures = nrow(figure_table(id, 500)))
}
