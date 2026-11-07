# modules/negotiation.R: Negotiation Tactics

negotiation_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(9, "\U0001f91d", "Negotiation Tactics",
      "Negotiation is not confrontation: it is the process by which two parties with different interests reach an agreement they can both live with. For DeepTech founders, the single most powerful tactic is competitive term sheets from multiple investors.",
      c("BATNA", "LEVERAGE", "MARKET NORMS", "DEEPTECH TACTICS")),

    # ── How to use this tab ───────────────────────────────────
    fluidRow(
      box(title = "\U0001f4a1 How to Use This Tab", status = "warning",
          solidHeader = TRUE, width = 12,
        tags$p(style = "color:#8fb0d8;font-size:13px;line-height:1.7;margin:0;",
          tags$b(style = "color:#00e5ff;", "\U0001f4cc Two sub-tabs to work through: "),
          tags$br(),
          tags$b(style = "color:#cdd9f5;", "Negotiation Principles"),
          " covers BATNA (Best Alternative to a Negotiated Agreement): the single most
          powerful negotiating tool. The table shows which terms to fight hard on vs accept,
          and the framework cards explain how to read and counter the three most common VC tactics
          (exploding offers, market norm bluffing, good cop/bad cop).",
          tags$br(), tags$br(),
          tags$b(style = "color:#cdd9f5;", "QuantumLeap AI Playbook"),
          " translates the principles into a step-by-step Series A negotiation strategy
          including a timeline strip, valuation anchoring arguments using IP replacement cost,
          and specific red flags to watch for when a corporate strategic co-invests.",
          tags$br(), tags$br(),
          tags$b(style = "color:#00e5ff;", "The term-by-term table: "),
          "study the Fight Hard? column: this is the prioritised list of where to spend
          your negotiating capital. Liquidation preference and board composition are worth
          fighting hard for. Dividends and information rights are not.",
          tags$br(), tags$br(),
          tags$b(style = "color:#00e5ff;", "\U0001f4cc Before your next investor meeting: "),
          "read the Exploding Offer, Market Norm, and Good Cop/Bad Cop sections.
          These are the three tactics you will encounter most often, and knowing them
          in advance removes their power entirely."
        )
      )
    ),

      

    fluidRow(
      box(title = NULL, status = "primary", solidHeader = FALSE, width = 12,
        tabsetPanel(id = ns("tabs"),
          tabPanel("\U0001f4da Negotiation Principles",
            br(),
            fluidRow(
              column(6,
                sh("BATNA: Your Most Powerful Tool"),
                fw("What BATNA Is",
                  "Best Alternative to a Negotiated Agreement: the best outcome you can achieve if the current deal falls through. For a founder, BATNA = best competing term sheet (or bootstrapping if pre-term sheet). The stronger your BATNA, the more freely you can walk away from any single deal: and investors know it."),
                div(class = "mc-panel",
                  tags$h5(style = "color:#00e5ff;", "BATNA Formula"),
                  tags$code("BATNA Value = max(Alternative₁, Alternative₂, ..., Alternativeₙ)"),
                  br(), br(),
                  tags$p(style = "color:#8fb0d8;font-size:11px;", "Practical BATNA for DeepTech Series A:"),
                  tags$ul(style = "color:#8fb0d8;font-size:11px;",
                    tags$li("Competing term sheet from a second VC at similar terms"),
                    tags$li("EIC Accelerator grant extension + 6-month bridge from angels"),
                    tags$li("Corporate strategic investment at higher valuation"),
                    tags$li("SBRI contract or NDA-protected IP licensing deal to tide you over")
                  )
                ),
                pull_quote("The only thing that creates leverage in a term sheet negotiation is a competing offer. Everything else is theatre.", "Brad Feld"),
                sh("What To Fight For vs What To Let Go"),
                algo_table(
                  c("Term", "Fight Hard?", "Why"),
                  list(
                    list("Liquidation pref (1x non-part)", "YES", "Major economic impact at exit"),
                    list("Board composition", "YES", "Governance determines control"),
                    list("Option pool size", "YES", "Directly dilutes founders"),
                    list("Anti-dilution (full ratchet)", "YES", "Punitive in down rounds"),
                    list("Information rights", "NO", "Standard, reasonable"),
                    list("Pro-rata rights", "MEDIUM", "Can complicate future rounds"),
                    list("Dividends (non-cumulative)", "NO", "Rarely material"),
                    list("ROFR on shares", "MEDIUM", "Can restrict founder liquidity")
                  )
                )
              ),
              column(6,
                sh("Reading VC Negotiating Tactics"),
                fw("The Exploding Offer",
                  "'We need an answer by Friday or we're moving on.' This is almost always a pressure tactic, not a real constraint. A professional VC will not walk from a good deal because you took an extra week. Responding: 'We're very interested and want to move quickly: can we align on a 10-day exclusivity?' resets the timeline professionally."),
                fw("The Overstated Market Norm",
                  "'This is completely standard, we've never deviated from this.' Translation: 'We prefer this term and hope you don't know the market.' Counter: 'Could you share two or three recent term sheets where this exact structure appeared?' Knowledgeable founders who know market norms win this negotiation."),
                fw("The Good Cop / Bad Cop Partnership",
                  "One GP is warm and entrepreneurial; the other (often the 'managing partner') is demanding on terms. The warm GP then says 'I agree with you but my partner insists.' Counter: always negotiate with the decision-maker in the room, and get confirmation in writing from the authority who can actually approve changes."),
                sh("DeepTech-Specific Negotiating Points"),
                fw("IP Licensing Protective Provisions",
                  "Corporate strategic co-investors may insert provisions requiring their consent for IP licensing decisions. This is a red line. Push back on any protective provision that covers ordinary business decisions: including who you license IP to and at what rate."),
                success_box(tags$strong("\u2713 Golden Rule: "), "Know the market before you enter the room. Read 15:20 recent term sheets from comparable UK DeepTech rounds. Gunderson Dettmer, Orrick, and BVCA all publish market data. Walk in knowing what 'market' means on every term.")
              )
            )
          ),
          tabPanel("\U0001f916 QuantumLeap AI Playbook",
            br(),
            fluidRow(
              column(6,
                sh("Series A Negotiation Strategy"),
                timeline_strip(
                  list("Build BATNA", "Get 2+ term sheets before discussing terms with any one VC"),
                  list("Anchor High", "Start with clean founder-friendly structure; negotiate down from there"),
                  list("Bundle Issues", "Trade valuation for board seat; don't negotiate each term in isolation"),
                  list("Use Silence", "After each counter, stay quiet. Discomfort drives concessions."),
                  list("Close With Relationship", "End by affirming the partnership: this person joins your board")
                ),
                br(),
                fw("Valuation Anchoring for DeepTech",
                  "Don't anchor on revenue multiples (you have little revenue). Anchor on: (1) comparable rounds for similar TRL/sector, (2) cost of replication (how much would it cost a competitor to rebuild your IP?), (3) strategic premium from corporate investors who value the optionality of your technology."),
                fw("The IP Valuation Argument",
                  "For QuantumLeap AI: 'Our neuromorphic architecture has 3 granted patents covering the core inference pipeline. An independent IP valuation places this at £8:12M in licensing value alone. We view the Series A as capitalising the commercialisation pathway of already-valuable IP: not just funding R&D risk.'")
              ),
              column(6,
                sh("Investor Due Diligence on Investors"),
                fw("Reference Former Founders",
                  "Ask every investor for 5 references: then ask those founders: 'Did this VC support you during a difficult board meeting?' and 'Did they lead or follow when things got hard?' A VC who performs well in good times but is aggressive in adversity is a liability in DeepTech."),
                warn_box(tags$strong("\u26a0 Corporate Strategic Red Flags: "),
                  tags$ul(
                    tags$li("ROFR on acquisition offers from competitors"),
                    tags$li("Protective provisions on IP licensing"),
                    tags$li("Information rights that include access to technical roadmap"),
                    tags$li("Right to name a board observer (who then attends all meetings)")
                  )
                ),
                fw("Timing the Market",
                  "In 2024:2025, UK DeepTech raising conditions are tighter than 2021. The best time to raise is when you have a de-risking event (tapeout, first silicon, pilot customer LOI) rather than a pure milestone date. A tapeout for QuantumLeap AI is a +40% valuation event; raise 4:6 weeks after, while momentum is high.")
              )
            )
          )
        )
      )
    )
  )
}

negotiation_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {})
}
