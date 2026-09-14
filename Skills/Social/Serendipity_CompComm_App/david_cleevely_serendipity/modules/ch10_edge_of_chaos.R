# modules/ch10_edge_of_chaos.R
# Chapter 10: The Edge Of Chaos

ch10_edge_of_chaos_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "aa-hero",
        tags$h1("Chapter 10"),
        tags$h2("The Edge Of Chaos"),
        div(
          span(class = "hero-badge", icon("atom"),          " Order vs. Disorder"),
          span(class = "hero-badge", icon("wand-magic-sparkles"), " Fertile Systems"),
          span(class = "hero-badge", icon("scale-balanced"),  " The Book's Synthesis")
        )
    ),

    fluidRow(
      box(title = "Chapter 10 - Overview", status = "primary", solidHeader = TRUE, width = 12,
          p("The book's final chapter draws every earlier idea - networks, place, mindset, organisational design, ",
            "institutional bureaucracy - into a single unifying image, borrowed from complexity science: the most ",
            "productive systems operate at the ", tags$b("edge of chaos"),
            " - close enough to order to let structure and connections form, close enough to disorder to let ",
            "genuinely unexpected things keep happening."),
          fluidRow(
            column(3, metric_card("\u2744\ufe0f", "Complete Order = Frozen")),
            column(3, metric_card("\U0001f300", "Complete Chaos = No Structure")),
            column(3, metric_card("\u2696\ufe0f", "The Fertile Middle")),
            column(3, metric_card("\U0001f9ed", "The Book's Synthesis"))
          )
      )
    ),

    fluidRow(
      box(title = NULL, status = "primary", solidHeader = FALSE, width = 12,
        tabsetPanel(
          id = ns("tabs"),

          tabPanel("\U0001f4da General Concepts",
            br(),
            fluidRow(
              column(6,
                sh("Two Failure Modes"),
                concept_card("Complete Order: Efficient but Frozen",
                  "A perfectly ordered system - every relationship fixed, every process optimised, every outcome predictable - is exactly the failure mode Chapters 7 and 8 warned about. It's efficient at what it already does and structurally incapable of producing anything it wasn't built to produce."),
                concept_card("Complete Chaos: Nothing to Build On",
                  "The opposite extreme is just as unproductive, if less discussed. A system with no structure at all - no repeated relationships, no accumulated trust, no shared reference points - can't turn a chance encounter into anything, because there's nothing stable enough to connect it to. Pure randomness doesn't compound; structure is what lets a lucky break become a lasting outcome."),
                sh("The Fertile Middle"),
                concept_card("Why the Edge, Specifically, Is Where Value Concentrates",
                  "Complexity scientists have long observed that systems near this boundary - neither frozen nor random - produce the richest, most varied behaviour: enough order for information to travel and combine, enough disorder for genuinely new combinations to keep appearing. Cleevely applies the same logic to innovation systems directly.")
              ),
              column(6,
                sh("The Book's Synthesis"),
                concept_card("Every Earlier Chapter Was Describing One Side of This Balance",
                  "Read back through the book with this lens: Chapter 3's weak ties are structure loose enough to carry novelty; Chapter 4's Cambridge cluster is dense enough to build trust but small enough to stay informal; Chapter 7's slack is deliberately preserved disorder inside an otherwise ordered organisation. The edge of chaos isn't a new idea in Chapter 10 - it's the pattern that was underneath every earlier chapter all along."),
                concept_card("A Dial to Be Tuned, Not a Point to Be Found Once",
                  "Cleevely's closing argument treats the edge of chaos as a dial that needs continuous, deliberate attention - as circumstances change, an organisation that was well-balanced can drift toward either failure mode without anyone deciding it should."),
                div(class = "success-box",
                    tags$strong("\u2705 Chapter 10 takeaway: "),
                    "Don't aim for maximum order or maximum freedom - aim for the deliberately maintained edge between ",
                    "them, and keep checking which way you've drifted.")
              )
            )
          ),

          tabPanel("\u269b\ufe0f Interactive",
            br(),
            fluidRow(
              column(12,
                shg("Live Demonstration: Order \u2194 Chaos"),
                p(style = "font-size:12.5px;color:#546e7a;",
                  "Drag the slider from rigid order to full chaos and watch the same network respond. Near 0 the ",
                  "structure locks rigid; near 100 it flies apart with no stable connections; the fertile middle is ",
                  "where you'll see it hold a loose, constantly-recombining shape."),
                viz_box(ns("chaos-net"), height = 460,
                        controls = viz_slider(ns("chaos-slider"), "Order \u2190\u2192 Chaos", 0, 100, 45,
                          sprintf("SerendipityViz.updateChaos('%s', this.value); document.getElementById('%s').textContent = this.value;",
                                  ns("chaos-net"), paste0(ns("chaos-slider"), "-val"))),
                        caption = "Force-directed graph \u00b7 the slider live-tunes link and repulsion strength"),
                div(class = "gauge-readout",
                    span(class = "gr-label", "Current regime"),
                    tags$p(id = paste0(ns("chaos-net"), "-readout"),
                           "The edge of chaos \u2014 structured enough to connect, loose enough to surprise")),
                d3_init(sprintf("
                  var nodes = [
                    {id:'1', label:'A', r:13, color:'#E8A020'}, {id:'2', label:'B', r:13, color:'#E8A020'},
                    {id:'3', label:'C', r:13, color:'#1e5a5a'}, {id:'4', label:'D', r:13, color:'#1e5a5a'},
                    {id:'5', label:'E', r:13, color:'#3498db'}, {id:'6', label:'F', r:13, color:'#3498db'},
                    {id:'7', label:'G', r:13, color:'#E8A020'}, {id:'8', label:'H', r:13, color:'#1e5a5a'},
                    {id:'9', label:'I', r:13, color:'#3498db'}, {id:'10', label:'J', r:13, color:'#F5C842'},
                    {id:'11', label:'K', r:13, color:'#E8A020'}, {id:'12', label:'L', r:13, color:'#1e5a5a'}
                  ];
                  var links = [
                    {source:'1',target:'2'}, {source:'2',target:'3',weak:true}, {source:'3',target:'4'},
                    {source:'4',target:'5',weak:true}, {source:'5',target:'6'}, {source:'6',target:'7',weak:true},
                    {source:'7',target:'8'}, {source:'8',target:'9',weak:true}, {source:'9',target:'10'},
                    {source:'10',target:'11',weak:true}, {source:'11',target:'12'}, {source:'12',target:'1',weak:true},
                    {source:'1',target:'7'}, {source:'4',target:'10',weak:true}, {source:'2',target:'8',weak:true}
                  ];
                  SerendipityViz.forceNetwork('%s', nodes, links, {height:460, registerAs:'%s', charge:-200});
                  SerendipityViz.updateChaos('%s', 45);
                ", ns("chaos-net"), ns("chaos-net"), ns("chaos-net")))
              )
            )
          ),

          tabPanel("\U0001f3e2 Applicability on Atera Analytics",
            br(),
            fluidRow(
              column(6,
                shg("Where Atera Sits on the Dial Today"),
                app_card("Reading Across the Nine Earlier Chapters",
                  "Pulled together, Atera's honest self-assessment across this book looks like a company sitting close to - but not perfectly on - the fertile edge: real structural holes (Chapter 3), a genuine local cluster advantage (Chapter 4), and early signs of milestone-driven rigidity creeping in (Chapters 7 and 8). The risk isn't any single failure - it's steady, unnoticed drift toward the ordered end as the company scales and reporting formalises."),
                app_card("A Single Standing Question for Leadership",
                  "Chapter 10 suggests a simple, recurring leadership question, worth asking every quarter: 'where has Atera drifted since we last checked - toward rigid predictability, or toward unstructured chaos - and what's the smallest deliberate correction?'")
              ),
              column(6,
                shg("Keeping Atera Tuned to the Edge"),
                app_card("Concrete Levers, Pulled Together From Every Chapter",
                  "Protect a handful of weak-tie relationships deliberately (Ch.3). Keep investing in physical presence in Cambridge (Ch.4). Preserve a small pool of genuinely unstructured engineering time (Ch.7). Report pivots honestly to Innovate UK instead of hiding them (Ch.8). Keep sending someone outside the usual circuit (Ch.9). None of these alone is decisive - together, they're what keeps Atera near the fertile middle rather than drifting to either extreme."),
                app_card("A Company-Wide Synthesis, Not Just a Communications Exercise",
                  "Where the earlier Compelling Communication app asked how Atera talks about its work, this app asks a prior question: whether Atera is actually organised in a way that keeps producing something worth talking about. Serendipity, on Cleevely's account, is the deliberately maintained condition - not the accident everyone assumes it is."),
                div(class = "success-box",
                    tags$strong("\u2705 Chapter 10 action point: "),
                    "Add 'edge-of-chaos check-in' as a standing five-minute item at Atera's quarterly leadership ",
                    "review - a deliberate moment to ask which way the company has drifted.")
              )
            )
          )
        )
      )
    )
  )
}

ch10_edge_of_chaos_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {})
}
