# tools/trello_check.R - Gantt to Tickets > Submit to Boards against a stand-in Trello (tools/fake_trello.py on :8931):
# first submit creates cards, resubmit UPDATES them (no duplicates), a card left by CollaborationPlanning is never touched,
# and "Read status back" takes the list a card was moved to.
suppressMessages({ library(shiny); library(R6); library(jsonlite); library(httr) })
for (f in c("R/utils_timezone.R", "R/api_manager.R", "R/utils_ics.R")) source(f)
source("modules/Gantt to Tickets/review_edit.R"); source("modules/Gantt to Tickets/submit_boards.R")
options(bos.trello_base = "http://127.0.0.1:8931/1")
pass <- 0; fail <- 0
check <- function(n, ok, d = NULL) { ok <- isTRUE(ok); cat(if (ok) "PASS " else "FAIL ", n, if (!ok && !is.null(d)) paste(" ->", paste(format(d), collapse = " ")), "\n", sep = ""); if (ok) pass <<- pass + 1 else fail <<- fail + 1 }
state <- function() fromJSON(content(GET("http://127.0.0.1:8931/1/_state"), as = "text"), simplifyVector = FALSE)
am <- APIManager$new(); am$trello_key <- "k"; am$trello_token <- "t"; am$trello_board_id <- "B"
am$gantt_data <- data.frame(Task_Name = c("Design", "Build"), Description = c("UI", "API"), Start_Date = c("2026-12-01", "2026-12-05"),
                            End_Date = c("2026-12-03", "2026-12-09"), Assignee = c("Ana", "Ben"), Priority = c("High", "Low"), Status = "", stringsAsFactors = FALSE)
testServer(submit_boards_server, args = list(api_manager = am), {
  session$setInputs(trello_list = "L1", submit_trello = 1)
  st <- state(); mine <- Filter(function(c) grepl("Business Operations Suite", c$desc), st)
  check("first submit: one card per task, with our mark and due date", length(mine) == 2 && all(c("Design", "Build") %in% vapply(mine, `[[`, "", "name")) &&
        any(vapply(mine, function(c) identical(c$due, "2026-12-09"), TRUE)))
  check("CollaborationPlanning's own 'Design' card untouched (not taken as ours)", grepl("Collaboration Planning task", st$CP1$desc) && st$CP1$name == "Design")
  check("card ids kept with the tasks", all(nzchar(am$gantt_data$Trello_Card_ID)) && !"CP1" %in% am$gantt_data$Trello_Card_ID)
  am$gantt_data$Description[1] <- "UI v2"
  session$setInputs(submit_trello = 2)
  st2 <- state()
  check("resubmit updates (still 3 cards on the board, new text on ours)", length(st2) == 3 &&
        grepl("UI v2", st2[[am$gantt_data$Trello_Card_ID[1]]]$desc))
  ids <- am$gantt_data$Trello_Card_ID; am$gantt_data$Trello_Card_ID <- ""      # a new session: ids not known, found by name
  session$setInputs(submit_trello = 3)
  check("a new session finds its cards by name (no duplicates)", length(state()) == 3 && identical(am$gantt_data$Trello_Card_ID, ids))
  POST(paste0("http://127.0.0.1:8931/1/_move/", ids[2], "/L3"))
  session$setInputs(pull_trello = 1)
  check("status read back from the board (moved to Done)", am$gantt_data$Status[2] == "Done" && am$gantt_data$Status[1] == "", am$gantt_data$Status)
})
cat(sprintf("%d passed, %d failed\n", pass, fail))
