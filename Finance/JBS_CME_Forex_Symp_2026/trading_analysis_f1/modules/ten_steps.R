# modules/ten_steps.R

ten_steps_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        width = 12, solidHeader = TRUE, status = "primary",
        title = "Ten Steps to Becoming a Successful Trader",
        tags$p("A widely-taught framework: Ten Steps to Becoming a Successful Trader.",
               style = "font-size:12px; color:#888; font-style:italic; margin-bottom:16px;"),
        uiOutput(ns("tenStepsUI"))
      )
    )
  )
}

ten_steps_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    
    output$tenStepsUI <- renderUI({
      steps <- list(
        list(n = 1,  title = "Hard Work!", icon = "dumbbell",
             text = "As with any skill, the harder you work, the better you get at it. Learn the skills, practise applying them, and only start trading with real money once you're really ready."),
        list(n = 2,  title = "Self-Confidence", icon = "hand-fist",
             text = "Believe in yourself and your ability. If you've taken time to learn about trading, don't be afraid of taking controlled risk or trying new approaches."),
        list(n = 3,  title = "Education", icon = "graduation-cap",
             text = "It's possible to get lucky without really knowing what you're doing — but nobody becomes a successful trader over a weekend. Commit time and effort to a proper education."),
        list(n = 4,  title = "Get a Mentor", icon = "user-tie",
             text = "Get feedback on your trading as you apply new knowledge and skills. Find a role model whose advice you trust and learn from their process."),
        list(n = 5,  title = "Honesty & Responsibility", icon = "scale-balanced",
             text = "All traders lose money from time to time — it doesn't make you a bad trader. Be honest with yourself about your decisions, or you'll keep repeating the same mistakes."),
        list(n = 6,  title = "Don't Just Copy Other Traders", icon = "user-slash",
             text = "Copying gives you no control over your trading decisions. If you want to be a trader, learn how to be a trader."),
        list(n = 7,  title = "Learn From Your Mistakes", icon = "rotate-left",
             text = "Go back and review each losing trade. Did you follow your process? Could you have avoided or reduced the loss? Would you do things differently next time?"),
        list(n = 8,  title = "Set 'Process' Goals, Not Monetary Goals", icon = "bullseye",
             text = "Monetary goals build emotional pressure after early losses. Process goals — always follow your rules, never exceed your risk limit, always use stop losses — bring discipline, and profits follow."),
        list(n = 9,  title = "Be Organised and Disciplined", icon = "list-check",
             text = "Work out a set of trading rules that suits your character and fits around your other life commitments — then stick to them."),
        list(n = 10, title = "Patience", icon = "hourglass-half",
             text = "By deciding not to take a trade, you are still making a decision. Don't enter trades just to feel like you're trading — wait for the right opportunity.")
      )
      
      card_color <- "#008A82"
      cards <- lapply(steps, function(s) {
        column(6,
          div(style = paste0(
                "background:#f7fbfb; border-left:4px solid ", card_color, "; border-radius:8px; ",
                "padding:14px 16px; margin-bottom:14px; display:flex; gap:12px; align-items:flex-start;"
              ),
              div(style = paste0(
                    "background:", card_color, "; color:#fff; border-radius:50%; width:34px; height:34px; ",
                    "min-width:34px; display:flex; align-items:center; justify-content:center; font-weight:700;"
                  ),
                  s$n
              ),
              div(
                tags$h5(HTML(paste0(as.character(icon(s$icon)), " ", s$title)),
                        style = "margin:0 0 4px 0; color:#002C3C; font-weight:700;"),
                tags$p(s$text, style = "margin:0; font-size:12.5px; color:#444; line-height:1.6;")
              )
          )
        )
      })
      
      fluidRow(cards)
    })
    
    session$onSessionEnded(function() {})
  })
}
