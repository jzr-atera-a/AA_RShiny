# global.R
# Practical Recommender Systems Code Lab — Shared Utilities & Sample Data

library(shiny)
library(shinydashboard)
library(plotly)
library(ggplot2)
library(DT)
library(dplyr)
library(tidyr)

# ── Python / reticulate setup (graceful fallback) ──────────────
python_available_flag <- tryCatch({
  library(reticulate)
  py_available(initialize = TRUE)
}, error = function(e) FALSE)

# ── Reproducible sample data ───────────────────────────────────
set.seed(42)
N_USERS  <- 50
N_MOVIES <- 30

sample_movies <- data.frame(
  movie_id = 1:N_MOVIES,
  title = c(
    "The Matrix","Inception","Interstellar","The Dark Knight","Pulp Fiction",
    "Forrest Gump","The Shawshank Redemption","Goodfellas","Fight Club",
    "The Silence of the Lambs","Schindler's List","The Godfather",
    "Casablanca","Citizen Kane","2001: A Space Odyssey","Blade Runner",
    "Alien","The Terminator","Die Hard","Jurassic Park",
    "Titanic","Avatar","Star Wars","Raiders of the Lost Ark",
    "Back to the Future","E.T.","Home Alone","The Lion King",
    "Toy Story","Finding Nemo"
  ),
  genre = c(
    "Sci-Fi","Sci-Fi","Sci-Fi","Action","Drama",
    "Drama","Drama","Crime","Drama","Thriller",
    "Drama","Crime","Romance","Drama","Sci-Fi",
    "Sci-Fi","Horror","Action","Action","Adventure",
    "Romance","Sci-Fi","Sci-Fi","Adventure","Sci-Fi",
    "Family","Comedy","Family","Family","Family"
  ),
  year = c(
    1999,2010,2014,2008,1994,1994,1994,1990,1999,1991,
    1993,1972,1942,1941,1968,1982,1979,1984,1988,1993,
    1997,2009,1977,1981,1985,1982,1990,1994,1995,2003
  ),
  stringsAsFactors = FALSE
)

# Sparse ratings (~30% fill)
all_pairs  <- expand.grid(user_id = 1:N_USERS, movie_id = 1:N_MOVIES)
keep_idx   <- sample(nrow(all_pairs), round(nrow(all_pairs) * 0.30))
sample_ratings <- all_pairs[keep_idx, ]
sample_ratings$rating    <- sample(1:5, nrow(sample_ratings), replace = TRUE,
                                   prob = c(0.05, 0.10, 0.20, 0.35, 0.30))
sample_ratings$timestamp <- as.integer(Sys.time()) -
  sample(1:31536000, nrow(sample_ratings), replace = TRUE)
sample_ratings <- sample_ratings[order(sample_ratings$user_id), ]
rownames(sample_ratings) <- NULL

# Event log (implicit feedback) ── mirrors MovieGEEK collector.Log
EVENT_TYPES   <- c("view","search","details","addtocart","buy")
EVENT_WEIGHTS <- c(view = 1, search = 0.5, details = 2, addtocart = 3, buy = 5)

n_events <- 600
sample_events <- data.frame(
  session_id  = paste0("S", sample(1:120, n_events, replace = TRUE)),
  user_id     = sample(1:N_USERS, n_events, replace = TRUE),
  content_id  = sample(1:N_MOVIES, n_events, replace = TRUE),
  event       = sample(EVENT_TYPES, n_events, replace = TRUE,
                       prob = c(0.40, 0.20, 0.20, 0.12, 0.08)),
  timestamp   = as.integer(Sys.time()) -
    sample(1:2592000, n_events, replace = TRUE),
  stringsAsFactors = FALSE
)

# ── Existing KB helpers (unchanged) ───────────────────────────
chapter_card <- function(num, title, desc, topics) {
  tags$div(class = "chapter-card",
           tags$div(
             tags$span(class = "chapter-num",   num),
             tags$span(class = "chapter-title", title)
           ),
           tags$div(class = "chapter-desc",   desc),
           tags$div(class = "chapter-topics",
                    lapply(topics, function(t) tags$span(class = "topic-tag", t)))
  )
}

timeline_entry <- function(badge, title, desc) {
  tags$div(class = "timeline-item",
           tags$div(class = "timeline-badge", badge),
           tags$div(class = "timeline-content",
                    tags$h6(title),
                    tags$p(desc))
  )
}

algo_table <- function(data) {
  tagList(
    tags$table(class = "algo-table",
               tags$thead(tags$tr(lapply(names(data), function(n) tags$th(n)))),
               tags$tbody(
                 lapply(1:nrow(data), function(i) {
                   tags$tr(lapply(data[i, ], function(val) tags$td(val)))
                 })
               )
    )
  )
}

plotly_dark_theme <- function(p) {
  p %>% layout(
    paper_bgcolor = "rgba(0,0,0,0)",
    plot_bgcolor  = "rgba(0,0,0,0)",
    font   = list(color = "#8a9bb0", family = "Inter, sans-serif", size = 11),
    xaxis  = list(gridcolor = "rgba(255,255,255,0.08)",
                  zerolinecolor = "rgba(255,255,255,0.1)", color = "#8a9bb0"),
    yaxis  = list(gridcolor = "rgba(255,255,255,0.08)",
                  zerolinecolor = "rgba(255,255,255,0.1)", color = "#8a9bb0")
  )
}

# ── NEW: Code Lab helpers ──────────────────────────────────────

# Header banner for each Code Lab tab
code_lab_header <- function(title, subtitle, badges = NULL) {
  tags$div(class = "codelab-header",
           tags$div(class = "codelab-badge-row",
                    tags$span(class = "codelab-badge", "CODE LAB"),
                    if (!is.null(badges))
                      lapply(badges, function(b) tags$span(class = "codelab-lang-badge", b))
           ),
           tags$h3(class = "codelab-title", title),
           tags$p(class  = "codelab-subtitle", subtitle)
  )
}

# Styled R code block (pre-formatted, dark background)
r_code_block <- function(code_text) {
  tags$pre(class = "code-block", code_text)
}

# Run button with standard styling
run_button <- function(id, label = "▶  Run") {
  actionButton(id, label, class = "btn-meta", style = "margin-bottom:12px;")
}

# "Coming Soon" placeholder for unimplemented Code Labs
coming_soon_lab <- function(chapter_num, topic, bullets = NULL) {
  tagList(
    div(class = "codelab-header",
        div(class = "codelab-badge-row",
            span(class = "codelab-badge", "CODE LAB"),
            span(class = "codelab-lang-badge", "COMING SOON")),
        tags$h3(class = "codelab-title",
                paste0("Chapter ", chapter_num, " · ", topic)),
        tags$p(class = "codelab-subtitle",
               "This Code Lab will be implemented in the next release.")
    ),
    fluidRow(
      column(12,
             div(class = "info-box-plain",
                 tags$strong("🚧 Planned implementations:"),
                 if (!is.null(bullets))
                   tags$ul(lapply(bullets, tags$li))
                 else
                   tags$p("Full interactive R implementation coming soon.")
             )
      )
    )
  )
}

# Standard DT options matching the app theme
dt_options <- list(
  pageLength  = 10,
  scrollX     = TRUE,
  dom         = "Bfrtip",
  buttons     = c("copy", "csv"),
  initComplete = JS(
    "function(settings, json) {",
    "  $(this.api().table().header()).css({'background-color':'#e0f4f2','color':'#002C3C','font-size':'11px'});",
    "}"
  )
)

# ── Movie descriptions for Ch 10 Content-Based ────────────
sample_descriptions <- data.frame(
  movie_id    = 1:30,
  description = c(
    "A computer hacker discovers reality is a simulated world controlled by machines. Action-packed science fiction with philosophical themes about reality and freedom.",
    "A skilled thief plants ideas in dreams through a layered heist inside the subconscious mind. Complex science fiction thriller with stunning visuals and time manipulation.",
    "A crew travels through a wormhole near Saturn to find habitable planets for humanity. Epic space science fiction exploring gravity relativity time dilation and love.",
    "A masked vigilante fights crime in Gotham City confronting a chaotic criminal mastermind. Dark superhero action thriller exploring chaos order and sacrifice.",
    "Interconnected crime stories in Los Angeles featuring hitmen, thieves and gangsters. Non-linear crime drama with sharp dialogue and dark humor.",
    "A man with low intelligence but big heart experiences historic American events over decades. Heartwarming drama about love destiny family and the kindness of strangers.",
    "A banker wrongly convicted of murder befriends a fellow prisoner over two decades. Inspiring prison drama about hope friendship and the human spirit.",
    "A former mobster reflects on his career in the New York criminal underworld. Gritty realistic crime drama about loyalty betrayal and the consequences of violence.",
    "A young man and his therapist explore toxic masculinity through an underground fighting club. Psychological thriller drama examining identity consumerism and rebellion.",
    "An FBI agent tracks a cannibal serial killer terrorizing the American Southeast. Tense psychological horror thriller about manipulation and survival.",
    "A German industrialist saves Jewish workers from the Holocaust during World War Two. Powerful historical drama about moral courage humanity and redemption.",
    "A mafia patriarch navigates power family loyalty and succession in postwar New York. Epic crime drama exploring honor family power and the corrupting nature of violence.",
    "A cynical American expatriate runs a nightclub in Vichy Morocco during World War Two. Romantic drama classic with timeless themes of love sacrifice and political intrigue.",
    "A newspaper reporter investigates the mysterious life of a recently deceased publishing tycoon. Groundbreaking drama about power wealth ambition and the meaning of a life.",
    "An astronaut travels through space encountering an alien monolith that triggers human evolution. Visionary science fiction exploring consciousness technology and the future of humanity.",
    "A police detective hunts a murderous android in a dystopian futuristic Los Angeles. Neo-noir science fiction about identity humanity empathy and artificial life.",
    "Astronauts on a commercial ship encounter a deadly alien organism on a desolate planet. Claustrophobic horror science fiction thriller about survival and the unknown.",
    "A soldier from the future is sent back to prevent a nuclear apocalypse by killing a key figure. Relentless action science fiction about time travel fate and machine intelligence.",
    "A New York City cop battles terrorists who have seized a Los Angeles skyscraper. Fast-paced action thriller with wit humor and incredible stunts.",
    "Scientists create living dinosaurs on a remote island amusement park that falls into chaos. Thrilling adventure science fiction about genetic engineering and unintended consequences.",
    "A young couple fall in love aboard a doomed luxury ocean liner in 1912. Epic romantic drama depicting the tragic sinking of the Titanic.",
    "A soldier uses alien technology to create a revolutionary military resource on Pandora. Visually spectacular science fiction adventure about colonialism nature and identity.",
    "A young farm boy joins a rebellion against an evil galactic empire with the help of a wizard. Epic space fantasy adventure about good versus evil heroism and the Force.",
    "An archaeologist races against Nazis to find the Ark of the Covenant before they weaponize it. Classic action adventure with exotic locations booby traps and historical mysteries.",
    "A teenager accidentally travels back in time thirty years and must ensure his parents meet. Comedy science fiction adventure about time paradoxes family and rock and roll.",
    "A stranded alien befriends a young boy and tries to phone home while hunted by authorities. Heartwarming family science fiction adventure about friendship and belonging.",
    "A young boy defends his house alone against bumbling burglars during Christmas holidays. Slapstick family comedy about resourcefulness courage and the meaning of home.",
    "A young lion prince flees after his father is murdered and must reclaim his rightful kingdom. Animated musical adventure drama about responsibility loss and coming of age.",
    "Cowboy toy feels threatened by a new space ranger action figure and they learn to be friends. Pioneering animated film about friendship jealousy change and growing up.",
    "A forgetful clownfish searches the ocean with a shark-phobic blue fish for his lost son. Animated adventure comedy about parental love overcoming fear and family."
  ),
  stringsAsFactors = FALSE
)

# ── Shared normalise function (used in Ch 7/8/10/11/12) ───
normalize_user_ratings <- function(x) {
  valid <- !is.na(x)
  if (sum(valid) <= 1) return(rep(0, length(x)))
  xm <- mean(x[valid]); xr <- max(x[valid]) - min(x[valid])
  if (xr == 0) return(rep(0, length(x)))
  res <- (x - xm) / xr; res[!valid] <- 0; res
}

cosine_sim_rows <- function(mat) {
  norms <- sqrt(rowSums(mat^2))
  norms[norms < 1e-10] <- 1e-10
  tcrossprod(mat / norms)
}
