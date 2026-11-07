# modules/ch3_how_networks_work.R
# Chapter 3: How Networks Work

ch3_how_networks_work_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "aa-hero",
        tags$h1("Chapter 3"),
        tags$h2("How Networks Work"),
        div(
          span(class = "hero-badge", icon("share-nodes"), " Network Theory"),
          span(class = "hero-badge", icon("link"),        " Weak Ties"),
          span(class = "hero-badge", icon("people-arrows")," Brokers & Bridges")
        )
    ),

    fluidRow(
      box(title = "Chapter 3 - Overview", status = "primary", solidHeader = TRUE, width = 12,
          p("This is the book's most technical chapter, and its engine room. Cleevely sets out the mechanics of ",
            "network theory - how information and opportunity actually flow between people - and lands on a ",
            "counterintuitive finding with a long research pedigree: your ", tags$b("weak ties"),
            " (acquaintances, not close friends) are disproportionately responsible for new opportunities, because ",
            "they connect you to worlds your close ties already share with you."),
          fluidRow(
            column(3, metric_card("\U0001f517", "The Strength of Weak Ties")),
            column(3, metric_card("\U0001f309", "Structural Holes")),
            column(3, metric_card("\U0001f9ed", "Brokers Between Clusters")),
            column(3, metric_card("\U0001f4e1", "Novel Information Flow"))
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
                sh("The Strength of Weak Ties"),
                concept_card("Why Acquaintances Matter More Than Friends",
                  "Your close friends tend to know the same people, hear the same news and move in the same circles you do - they're a rich source of support, but a poor source of <em>new</em> information. Weak ties - old colleagues, distant contacts, people you see twice a year - sit in different social worlds. A single weak tie can carry information your entire close network has never encountered."),
                concept_card("Structural Holes: The Gaps Worth Bridging",
                  "A structural hole is a gap between two clusters that aren't otherwise connected. The person who sits across that gap - who knows people in both clusters - occupies an extremely valuable position: they see combinations of information and opportunity that neither cluster sees on its own, and they can broker connections that create new value for both sides."),
                sh("Brokers and Bridges"),
                concept_card("The Broker's Advantage",
                  "Cleevely highlights that people who deliberately position themselves as bridges - rather than as deeply embedded members of a single tight cluster - tend to have disproportionate access to novel opportunities. It's a strategic choice as much as a personality trait: cultivating a handful of loosely connected outside relationships pays off precisely because most people don't bother.")
              ),
              column(6,
                sh("Density vs. Diversity"),
                concept_card("A Dense Network Feels Productive but Often Isn't",
                  "It's easy to mistake a busy, tightly-knit network for a productive one. But if everyone already knows everyone, the marginal new connection adds almost no new information. A more diverse, loosely connected network - even if it feels less cohesive - has far more capacity to surface genuinely new opportunities."),
                concept_card("Designing Your Own Network Structure",
                  "Because network position is at least partly a choice, Cleevely argues individuals and organisations can deliberately design their own connectivity: keeping a few structural-hole relationships alive on purpose, rather than letting a network narrow naturally toward the people who are easiest to see regularly."),
                div(class = "tip-box",
                    tags$strong("\U0001f4a1 Key test: "),
                    "List your last five useful professional opportunities. How many came from a close, frequent ",
                    "contact - and how many came from someone you rarely speak to?"),
                div(class = "success-box",
                    tags$strong("\u2705 Chapter 3 takeaway: "),
                    "Deliberately maintain a handful of weak, structurally-diverse ties - they carry far more new ",
                    "information per relationship than your close network ever will.")
              )
            )
          ),

          tabPanel("\U0001f578\ufe0f Interactive",
            br(),
            fluidRow(
              column(12,
                shg("Weak Ties and Broker Positions - A Live Network"),
                p(style = "font-size:12.5px;color:#546e7a;",
                  "This graph shows two dense clusters (gold = engineering, teal = policy world) joined only by a ",
                  "small number of bridge relationships. Drag nodes to explore, and use the toggle to see the ",
                  "structurally-thin bridges that carry almost all the ", tags$em("novel"), " information between ",
                  "the two worlds."),
                viz_box(ns("net-graph"), height = 460,
                        controls = tags$label(
                          tags$input(type = "checkbox", id = ns("weak-toggle"),
                                     onclick = sprintf("SerendipityViz.toggleWeakTies('%s', this.checked);", ns("net-graph"))),
                          " Emphasise weak ties (the bridges between clusters)"
                        ),
                        caption = "Force-directed graph \u00b7 drag nodes \u00b7 toggle above to spotlight structural holes"),
                viz_legend(c("Engineering cluster" = "#E8A020", "Policy / funding cluster" = "#1e5a5a",
                             "Bridge / broker" = "#F5C842")),
                d3_init(sprintf("
                  var nodes = [
                    {id:'E1', label:'Eng Lead', r:17, color:'#E8A020'},
                    {id:'E2', label:'Eng A',    r:14, color:'#E8A020'},
                    {id:'E3', label:'Eng B',    r:14, color:'#E8A020'},
                    {id:'E4', label:'Eng C',    r:14, color:'#E8A020'},
                    {id:'E5', label:'Eng D',    r:14, color:'#E8A020'},
                    {id:'P1', label:'Policy Lead', r:17, color:'#1e5a5a'},
                    {id:'P2', label:'Policy A', r:14, color:'#1e5a5a'},
                    {id:'P3', label:'Policy B', r:14, color:'#1e5a5a'},
                    {id:'P4', label:'Policy C', r:14, color:'#1e5a5a'},
                    {id:'B1', label:'Broker', r:19, color:'#F5C842', tooltip:'Knows both worlds - the structural-hole position.'}
                  ];
                  var links = [
                    {source:'E1', target:'E2'}, {source:'E1', target:'E3'}, {source:'E1', target:'E4'},
                    {source:'E2', target:'E3'}, {source:'E3', target:'E4'}, {source:'E4', target:'E5'},
                    {source:'E2', target:'E5'},
                    {source:'P1', target:'P2'}, {source:'P1', target:'P3'}, {source:'P1', target:'P4'},
                    {source:'P2', target:'P3'}, {source:'P3', target:'P4'},
                    {source:'B1', target:'E1', weak:true}, {source:'B1', target:'P1', weak:true},
                    {source:'B1', target:'E3', weak:true}, {source:'B1', target:'P3', weak:true}
                  ];
                  SerendipityViz.forceNetwork('%s', nodes, links, {height:460, registerAs:'%s', charge:-260});
                ", ns("net-graph"), ns("net-graph")))
              )
            )
          ),

          tabPanel("\U0001f3e2 Applicability on Atera Analytics",
            br(),
            fluidRow(
              column(6,
                shg("Atera's Structural Holes"),
                app_card("Where Atera Currently Sits as a Broker",
                  "Atera occupies an unusually valuable bridge position: it sits between a tightly-knit CAV/AV engineering world (sensor and mapping specialists) and a separate, tightly-knit UK public-sector world (council transport officers, Innovate UK monitors). Very few organisations have dense relationships in both - which is exactly why Atera's platform, and its introductions, carry unusual value to each side."),
                app_card("Protecting the Bridge Role as the Company Grows",
                  "As Atera hires more engineers and more business-development staff, there's a natural risk that each group becomes densely connected <em>within</em> itself but loses the deliberate cross-cluster relationships that made the company valuable in the first place. Leadership should explicitly protect time for a small number of people to keep working both sides of the bridge.")
              ),
              column(6,
                shg("Weak Ties in Atera's Actual Pipeline"),
                app_card("The Pilot That Came From an Old Contact",
                  "Atera's first council pilot did not come from the structured sales pipeline - it came from a former colleague, now working in local government, who Atera's founder had not spoken to in two years. This is the textbook weak-tie pattern: low-frequency, low-effort contact producing outsized opportunity."),
                app_card("Deliberately Cultivating More Weak Ties",
                  "Atera can systematise this by design: a standing practice of re-connecting with dormant contacts quarterly, attending at least one conference outside the core CAV/AV space each year (logistics, insurance, city planning), and tracking which pipeline opportunities originated from weak versus strong ties to see where the real value is coming from."),
                div(class = "success-box",
                    tags$strong("\u2705 Chapter 3 action point: "),
                    "Add a 'source of first contact' field to Atera's CRM and review it quarterly - if weak ties ",
                    "are outperforming the structured pipeline, invest deliberately in generating more of them.")
              )
            )
          )
        )
      )
    )
  )
}

ch3_how_networks_work_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {})
}
