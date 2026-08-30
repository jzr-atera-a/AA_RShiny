# modules/feedback_tab.R

feedback_tab_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        width = 12, solidHeader = TRUE, status = "primary", title = NULL,
        div(
          style = paste0(
            "background:linear-gradient(135deg,#002C3C 0%,#005f5a 60%,#00A39A 100%);",
            "border-radius:10px; padding:32px 36px; color:#ffffff; text-align:center;"
          ),
          icon("envelope-open-text", style = "font-size:52px; color:#7fffd4; margin-bottom:16px;"),
          tags$h2("We Would Love to Hear from You", style = "font-size:26px; font-weight:700; color:#ffffff; margin:0 0 10px 0;"),
          tags$p(HTML(paste0(
            "Your feedback is invaluable in helping us improve the Atera Analytics platform. Whether you have ",
            "suggestions for new features, additional asset classes or instruments, improvements to existing ",
            "analytics, or you are interested in a bespoke version of this application tailored to your ",
            "organisation, we want to hear from you."
          )), style = "font-size:15px; color:#d0f0ec; line-height:1.7; max-width:700px; margin:0 auto 24px auto;"),
          tags$a(
            href = "mailto:admin@atera-analytics.co.uk",
            HTML("<span style='font-size:20px; font-weight:700; color:#7fffd4;'>admin@atera-analytics.co.uk</span>"),
            style = paste0(
              "display:inline-block; background:rgba(255,255,255,0.12); border:2px solid #7fffd4; ",
              "border-radius:8px; padding:14px 32px; text-decoration:none;"
            )
          )
        )
      )
    ),
    
    fluidRow(
      box(
        width = 4, solidHeader = TRUE, status = "primary",
        title = tagList(icon("lightbulb"), " Feature Suggestions"),
        tags$p(paste0(
          "Tell us which additional asset classes, instruments, or analytical modules you would find most ",
          "valuable. We are actively developing extensions to this platform including live streaming quotes, ",
          "chart pattern (not just candlestick) recognition, and further live macro data integrations."
        ), style = "font-size:13px; color:#444; line-height:1.6;"),
        tags$p(HTML(paste0("Write to: <a href='mailto:admin@atera-analytics.co.uk' style='color:#008A82; font-weight:600;'>admin@atera-analytics.co.uk</a>")),
               style = "font-size:13px; margin-top:12px;")
      ),
      box(
        width = 4, solidHeader = TRUE, status = "primary",
        title = tagList(icon("robot"), " AI and Algorithmic Trading"),
        tags$p(paste0(
          "Atera Analytics has the full capability to extend this platform into automated algorithmic trading ",
          "systems, AI-driven signal generation, and bespoke quantitative tools. If your organisation is ",
          "exploring these capabilities, we would be delighted to discuss how we can help."
        ), style = "font-size:13px; color:#444; line-height:1.6;"),
        tags$p(HTML(paste0("Write to: <a href='mailto:admin@atera-analytics.co.uk' style='color:#008A82; font-weight:600;'>admin@atera-analytics.co.uk</a>")),
               style = "font-size:13px; margin-top:12px;")
      ),
      box(
        width = 4, solidHeader = TRUE, status = "primary",
        title = tagList(icon("bug"), " Bug Reports and Improvements"),
        tags$p(paste0(
          "If you encounter any unexpected behaviour, errors, or charts that do not display as expected, please ",
          "let us know. Include the asset class and specific instrument you were analysing and a brief ",
          "description of what you observed. We aim to respond promptly."
        ), style = "font-size:13px; color:#444; line-height:1.6;"),
        tags$p(HTML(paste0("Write to: <a href='mailto:admin@atera-analytics.co.uk' style='color:#008A82; font-weight:600;'>admin@atera-analytics.co.uk</a>")),
               style = "font-size:13px; margin-top:12px;")
      )
    ),
    
    fluidRow(
      box(
        width = 12, solidHeader = TRUE, status = "info", title = "About Atera Analytics",
        fluidRow(
          column(8,
            tags$p(HTML(paste0(
              "Atera Analytics is an entrepreneurial platform founded by <strong>Joseph Francisco Zubizarreta</strong>, ",
              "MBA Alumni of the <strong>Judge Business School, University of Cambridge</strong>, who currently ",
              "serves as its <strong>Technical &amp; Commercial Director</strong>. The platform is dedicated to ",
              "making complex, production-grade analytical applications accessible to domain experts across ",
              "finance, investment management, and quantitative research. This multi-asset trading and technical ",
              "analysis suite is one of several applications developed under the Atera Analytics umbrella, with a ",
              "growing portfolio of tools spanning financial markets, autonomous vehicle analytics, and AI-powered ",
              "enterprise applications."
            )), style = "font-size:14px; color:#444; line-height:1.7; margin:0;")
          ),
          column(4,
            div(style = "background:linear-gradient(135deg,#002C3C,#008A82); border-radius:8px; padding:20px; text-align:center; color:#fff;",
                icon("envelope", style = "font-size:28px; color:#7fffd4; margin-bottom:10px;"),
                tags$h5("Get in Touch", style = "color:#fff; font-weight:700; margin:0 0 8px 0;"),
                tags$a("admin@atera-analytics.co.uk", href = "mailto:admin@atera-analytics.co.uk",
                       style = "color:#7fffd4; font-size:13px; font-weight:600; text-decoration:none;")
            )
          )
        )
      )
    )
  )
}

feedback_tab_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    # Fully static content — no server-side outputs needed.
    session$onSessionEnded(function() {})
  })
}
