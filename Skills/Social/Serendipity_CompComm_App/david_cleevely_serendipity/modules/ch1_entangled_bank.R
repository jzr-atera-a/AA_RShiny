# modules/ch1_entangled_bank.R
# Chapter 1: The Entangled Bank

ch1_entangled_bank_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "aa-hero",
        tags$h1("Chapter 1"),
        tags$h2("The Entangled Bank"),
        div(
          span(class = "hero-badge", icon("project-diagram"), " Complexity"),
          span(class = "hero-badge", icon("share-nodes"),     " Interconnection"),
          span(class = "hero-badge", icon("users"),           " Systems, Not Lone Geniuses")
        )
    ),

    fluidRow(
      box(title = "Chapter 1 - Overview", status = "primary", solidHeader = TRUE, width = 12,
          p("Cleevely opens by borrowing Darwin's image of the ", tags$em("entangled bank"),
            " - a tangled riverside thicket of plants, insects, birds and worms, each dependent on the others ",
            "in ways too complex to fully trace. His claim: innovation looks the same way. A breakthrough is ",
            "never really the product of one isolated genius - it's the visible tip of a much larger, mostly ",
            "invisible web of people, ideas, funding, timing and prior work."),
          fluidRow(
            column(3, metric_card("\U0001f331", "The Entangled Bank Metaphor")),
            column(3, metric_card("\U0001f465", "Systems, Not Individuals")),
            column(3, metric_card("\U0001f517", "Hidden Dependencies")),
            column(3, metric_card("\U0001f9e9", "Complexity as a Feature"))
          )
      )
    ),

    fluidRow(
      box(title = NULL, status = "primary", solidHeader = FALSE, width = 12,
        tabsetPanel(
          id = ns("tabs"),

          # ── GENERAL CONCEPTS ──────────────────────────────────
          tabPanel("\U0001f4da General Concepts",
            br(),
            fluidRow(
              column(6,
                sh("Darwin's Entangled Bank"),
                concept_card("An Image Borrowed from The Origin of Species",
                  "Darwin closed <em>On the Origin of Species</em> picturing a bank clothed with plants, birds singing, insects flitting, worms turning the soil - all of it \u2018dependent on each other in so complex a manner\u2019. Cleevely uses the same image for innovation: a thriving ecosystem is not a collection of independent parts, it's a web where removing any single strand changes everything downstream of it."),

                sh("Innovation as a Systems Property"),
                concept_card("Nobody Invents Alone",
                  "Every celebrated \u2018lone genius\u2019 story dissolves under scrutiny into a web of mentors, rivals, funders, prior failures and lucky timing. Cleevely argues that treating innovation as an individual trait - something certain gifted people simply have - misses where it actually comes from: the density and shape of the network around a person, not the person alone."),

                concept_card("Why This Matters for Policy and Strategy",
                  "If innovation is systemic, then the practical question changes. Instead of asking \u2018how do we find more brilliant individuals?\u2019, the better question is \u2018how do we build the entangled bank - the dense, varied web of connections - that makes brilliance more likely to occur and more likely to be noticed when it does?\u2019"),

                quote_block(
                  "It is interesting to contemplate an entangled bank, and to reflect that elaborately constructed forms have all been produced by laws acting around us.",
                  "Adapted from the closing image of On the Origin of Species, echoed by Cleevely"
                )
              ),

              column(6,
                sh("Hidden Dependencies"),
                concept_card("Most of the Web Is Invisible",
                  "In a real entangled bank, most of the causal links - which insect pollinates which plant, which fungus feeds which root - are invisible to a casual observer. Innovation networks work the same way: the conversation that mattered, the introduction that mattered, is rarely the one that gets written into the official history afterwards."),

                concept_card("Complexity Is a Feature, Not Noise to Be Removed",
                  "A natural instinct in organisations is to simplify: fewer stakeholders, cleaner reporting lines, tidier processes. Cleevely's warning is that this same tidying instinct, applied to an innovation system, can quietly cut the very strands that were producing unplanned value."),

                div(class = "tip-box",
                    tags$strong("\U0001f4a1 Key test: "),
                    "Before simplifying any team, partnership list or process, ask what unplanned value might be ",
                    "travelling along the connection you're about to remove."),

                sh("Setting Up the Rest of the Book"),
                concept_card("From Metaphor to Mechanism",
                  "Chapter 1 deliberately stays at the level of metaphor - it establishes the entangled-bank picture of innovation before the book gets specific. Chapters 2 and 3 then start unpacking the mechanism: how historical breakthroughs actually happened, and how network structure specifically shapes the flow of information and opportunity."),

                div(class = "success-box",
                    tags$strong("\u2705 Chapter 1 takeaway: "),
                    "Treat any innovation effort as an ecosystem to be cultivated, not a machine to be optimised - ",
                    "the tangle is doing more work than it looks like it's doing.")
              )
            )
          ),

          # ── INTERACTIVE ────────────────────────────────────────
          tabPanel("\U0001f333 Interactive",
            br(),
            fluidRow(
              column(12,
                shg("Drag the Bank - Explore an Entangled Innovation System"),
                p(style = "font-size:12.5px;color:#546e7a;",
                  "Every node below is something that plausibly contributed to a single breakthrough: people, ",
                  "ideas, prior technologies, funding sources and chance events. Drag any node to feel how tightly ",
                  "coupled the system is - moving one point pulls its neighbours with it. Hover a node for detail."),
                viz_box(ns("entangled-net"), height = 440,
                        caption = "Force-directed graph \u00b7 drag nodes \u00b7 hover for detail"),
                viz_legend(c("Person" = "#E8A020", "Idea / Prior work" = "#1e5a5a",
                             "Institution / Funding" = "#3498db", "Chance event" = "#e74c3c")),
                d3_init(sprintf("
                  var nodes = [
                    {id:'A', label:'Researcher', r:20, color:'#E8A020', tooltip:'Publishes an obscure paper nobody cites for 3 years.'},
                    {id:'B', label:'Rival Lab',  r:16, color:'#E8A020', tooltip:'Working on an unrelated problem next door.'},
                    {id:'C', label:'Old Patent', r:15, color:'#1e5a5a', tooltip:'A 1970s idea shelved for lack of materials.'},
                    {id:'D', label:'Funding Body',r:18, color:'#3498db', tooltip:'Redirects a small grant after a programme cancellation.'},
                    {id:'E', label:'Conference Talk', r:15, color:'#e74c3c', tooltip:'A chance seat-neighbour asks an odd question.'},
                    {id:'F', label:'PhD Student', r:16, color:'#E8A020', tooltip:'Connects two unrelated literatures for a lit review.'},
                    {id:'G', label:'New Material', r:15, color:'#1e5a5a', tooltip:'Becomes cheap enough to use, years after being invented.'},
                    {id:'H', label:'Journal Editor', r:14, color:'#E8A020', tooltip:'Pairs two reviewers who later co-author.'},
                    {id:'I', label:'Failed Startup', r:15, color:'#e74c3c', tooltip:'Its engineers scatter into new companies.'},
                    {id:'J', label:'University Dept', r:17, color:'#3498db', tooltip:'Hosts a seminar series that mixes disciplines.'},
                    {id:'K', label:'Breakthrough', r:22, color:'#F5C842', tooltip:'The visible result everyone later credits to one genius.'}
                  ];
                  var links = [
                    {source:'A', target:'K'}, {source:'B', target:'A', weak:true},
                    {source:'C', target:'K', weak:true}, {source:'D', target:'A'},
                    {source:'E', target:'F', weak:true}, {source:'F', target:'K'},
                    {source:'G', target:'C'}, {source:'H', target:'A', weak:true},
                    {source:'I', target:'F', weak:true}, {source:'J', target:'E'},
                    {source:'J', target:'F'}, {source:'D', target:'J', weak:true},
                    {source:'B', target:'C', weak:true}
                  ];
                  SerendipityViz.forceNetwork('%s', nodes, links, {height:440});
                ", ns("entangled-net")))
              )
            )
          ),

          # ── ATERA ANALYTICS APPLICATION ──────────────────────
          tabPanel("\U0001f3e2 Applicability on Atera Analytics",
            br(),
            fluidRow(
              column(6,
                shg("Atera's Own Entangled Bank"),
                app_card("The Platform Is the Visible Tip",
                  "Atera's CAM Infrastructure Assessment Platform looks, from the outside, like the product of a single company's engineering. In reality it sits on an entangled bank of prior work: OpenStreetMap data built by volunteers, YOLOv8 research published openly, an Innovate UK funding line that could have gone to a different sector, and Cambridge academic contacts made at events unrelated to CAV technology at all."),
                app_card("Mapping the Invisible Dependencies",
                  "A useful exercise for Atera's leadership: list every partnership, dataset and piece of funding the platform depends on, then trace how each relationship actually started. Most will not trace back to a formal business-development process - they will trace back to an introduction, a conference hallway conversation, or a shared academic supervisor."),
                div(class = "tip-box",
                    tags$strong("\U0001f4a1 Practical step: "),
                    "Before Atera's next reporting cycle, ask each team lead to name one relationship the company ",
                    "depends on that didn't come from a formal sales or recruitment process.")
              ),
              column(6,
                shg("Resisting the Urge to Simplify Too Early"),
                app_card("The Risk of Tidying the Stakeholder List",
                  "As Atera scales and reporting to Innovate UK becomes more structured, there's a natural pull toward a clean, minimal stakeholder map: a handful of \u2018key accounts\u2019, a fixed set of council contacts. Chapter 1's warning applies directly - some of the loosest, least official connections (a curious council data officer, an AV startup founder met at a Zenzic mixer) may be exactly where the next pilot or partnership originates."),
                app_card("Designing for the Tangle, Not Against It",
                  "Concretely, this means keeping some deliberately unstructured time and budget for events, cross-sector conversations and speculative introductions - even as the core delivery process becomes more disciplined to meet milestone reporting."),
                div(class = "success-box",
                    tags$strong("\u2705 Chapter 1 action point: "),
                    "Keep an explicit \u2018unplanned connections\u2019 line in Atera's quarterly review - not to justify ",
                    "spend, but to make visible how much of the pipeline actually starts outside the formal process.")
              )
            )
          )
        )
      )
    )
  )
}

ch1_entangled_bank_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {})
}
