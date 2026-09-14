# modules/ch5_prepared_mind.R
# Chapter 5: The Prepared Mind

ch5_prepared_mind_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "aa-hero",
        tags$h1("Chapter 5"),
        tags$h2("The Prepared Mind"),
        div(
          span(class = "hero-badge", icon("brain"),      " Curiosity"),
          span(class = "hero-badge", icon("eye"),        " Attentiveness"),
          span(class = "hero-badge", icon("bolt-lightning")," Recognising Opportunity")
        )
    ),

    fluidRow(
      box(title = "Chapter 5 - Overview", status = "primary", solidHeader = TRUE, width = 12,
          p("Having spent four chapters on systems, history and networks, Cleevely turns to the individual. Borrowing ",
            "Louis Pasteur's famous line - \u2018chance favours only the prepared mind\u2019 - Chapter 5 asks what, ",
            "specifically, prepares a mind to notice and act on an unexpected opportunity that a thousand other ",
            "people would walk straight past."),
          fluidRow(
            column(3, metric_card("\U0001f9e0", "Pasteur's Principle")),
            column(3, metric_card("\U0001f440", "Noticing the Anomaly")),
            column(3, metric_card("\U0001f4da", "Breadth of Exposure")),
            column(3, metric_card("\u26a1", "Willingness to Act"))
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
                sh("Pasteur's Principle"),
                concept_card("Chance Favours Only the Prepared Mind",
                  "Pasteur's line is often quoted and rarely unpacked. Cleevely takes it apart: \u2018prepared\u2019 doesn't mean psychic or lucky - it means having enough background knowledge, in enough different areas, to recognise when something unexpected is actually significant rather than simply strange or wrong."),
                concept_card("Noticing the Anomaly",
                  "Most people who encounter an anomaly - a result that doesn't fit, a comment that seems out of place - either don't notice it, or notice it and dismiss it as noise. The prepared mind pauses on the anomaly instead of filtering it out, precisely because it has enough context to ask \u2018wait, why did that happen?\u2019"),
                sh("Breadth Over Depth (Sometimes)"),
                concept_card("Why Generalists Spot More Serendipity Than Specialists",
                  "Deep specialists are often better at solving known problems within their field, but Cleevely argues that people with broader, more varied exposure - across disciplines, industries or roles - are structurally more likely to notice when an idea from one world would solve a problem in another. Breadth creates more surface area for connections to happen.")
              ),
              column(6,
                sh("Willingness to Act on a Hunch"),
                concept_card("Recognition Without Action Is Wasted",
                  "Noticing an anomaly is necessary but not sufficient. Many people who spot something odd never act on it - the cost of investigating feels higher than the uncertain payoff. Cleevely notes that the people credited with serendipitous discoveries usually shared a tolerance for chasing a hunch that might well turn out to be nothing."),
                concept_card("Preparation Can Be Built, Not Just Inherited",
                  "Because a prepared mind is largely a function of accumulated knowledge, curiosity habits and a tolerance for following anomalies, Cleevely treats it as trainable - not a fixed trait some people simply have. Deliberately reading outside your field, asking \u2018why\u2019 more often, and giving yourself explicit permission to chase small curiosities all measurably increase preparedness."),
                div(class = "success-box",
                    tags$strong("\u2705 Chapter 5 takeaway: "),
                    "A prepared mind is built from three ingredients you can deliberately cultivate: broad exposure, ",
                    "attentiveness to anomalies, and a habit of acting on hunches before you're certain they matter.")
              )
            )
          ),

          tabPanel("\U0001f9ed Interactive",
            br(),
            fluidRow(
              column(6,
                shg("Self-Assessment: How Prepared Is Your Mind?"),
                p(style = "font-size:12.5px;color:#546e7a;",
                  "Rate yourself honestly from 0 (rarely) to 10 (constantly) on each dimension. The radar chart and ",
                  "score update live as you move each slider - this is a reflective tool, not a scientific instrument."),
                div(class = "quiz-item",
                    tags$label("Curiosity - I explore topics outside my job or field for their own sake"),
                    tags$input(type = "range", id = ns("q1"), min = 0, max = 10, value = 5,
                               oninput = sprintf("SerendipityQuiz.update('%s');", ns(""))),
                    div(class = "quiz-scale", span("Rarely"), span("Constantly"))),
                div(class = "quiz-item",
                    tags$label("Attentiveness - I notice when something doesn't fit my expectations"),
                    tags$input(type = "range", id = ns("q2"), min = 0, max = 10, value = 5,
                               oninput = sprintf("SerendipityQuiz.update('%s');", ns(""))),
                    div(class = "quiz-scale", span("Rarely"), span("Constantly"))),
                div(class = "quiz-item",
                    tags$label("Breadth - I regularly talk to people well outside my usual field"),
                    tags$input(type = "range", id = ns("q3"), min = 0, max = 10, value = 5,
                               oninput = sprintf("SerendipityQuiz.update('%s');", ns(""))),
                    div(class = "quiz-scale", span("Rarely"), span("Constantly"))),
                div(class = "quiz-item",
                    tags$label("Follow-through - I act on a hunch even when I can't yet justify it"),
                    tags$input(type = "range", id = ns("q4"), min = 0, max = 10, value = 5,
                               oninput = sprintf("SerendipityQuiz.update('%s');", ns(""))),
                    div(class = "quiz-scale", span("Rarely"), span("Constantly"))),
                div(class = "quiz-item",
                    tags$label("Foundation - I have enough depth in my own field to recognise what's unusual"),
                    tags$input(type = "range", id = ns("q5"), min = 0, max = 10, value = 5,
                               oninput = sprintf("SerendipityQuiz.update('%s');", ns(""))),
                    div(class = "quiz-scale", span("Rarely"), span("Constantly")))
              ),
              column(6,
                shg("Your Prepared-Mind Profile"),
                viz_box(ns("mind-radar"), height = 380),
                div(class = "quiz-score-box",
                    span(class = "quiz-score-label", "Prepared-Mind Score"),
                    div(id = ns("score-value"), class = "quiz-score-value", "25/50"),
                    p(id = ns("score-desc"), class = "quiz-score-desc",
                      "Move the sliders to see your profile - there's no failing score, only a map of where to invest attention.")
                ),
                d3_init(sprintf("
                  var axes = ['Curiosity','Attentive','Breadth','Follow-through','Foundation'];
                  var radar = SerendipityViz.radarChart('%s', axes, [5,5,5,5,5], {height:380});
                  window.SerendipityQuiz = {
                    radar: radar,
                    update: function(nsPrefix) {
                      var ids = ['q1','q2','q3','q4','q5'];
                      var vals = ids.map(function(k){ return +document.getElementById(nsPrefix + k).value; });
                      radar.render(vals);
                      var total = vals.reduce(function(a,b){return a+b;},0);
                      document.getElementById('%s').textContent = total + '/50';
                      var desc = document.getElementById('%s');
                      if (total < 20) desc.textContent = 'Plenty of room to build preparedness - start with broader reading and one new conversation a week.';
                      else if (total < 35) desc.textContent = 'A solid, workable level of preparedness - look for the weakest single dimension and invest there first.';
                      else desc.textContent = 'A well-prepared mind on paper - the real test is still whether you act on the hunches you notice.';
                    }
                  };
                ", ns("mind-radar"), ns("score-value"), ns("score-desc")))
              )
            )
          ),

          tabPanel("\U0001f3e2 Applicability on Atera Analytics",
            br(),
            fluidRow(
              column(6,
                shg("Hiring and Building Prepared Minds at Atera"),
                app_card("Looking Beyond the CV for Breadth",
                  "Atera's technical hiring naturally screens for depth - machine learning, GIS, robotics. Chapter 5 suggests deliberately valuing breadth too: candidates who've worked across unrelated sectors, or who show genuine curiosity outside their specialism, are structurally more likely to spot unexpected applications of the platform."),
                app_card("Protecting Time to Notice Anomalies",
                  "Engineers under constant sprint pressure rarely have the slack to pause on an odd result and ask why it happened - the prepared mind needs unstructured time as much as it needs knowledge. A small, protected block of exploration time each month costs little and directly targets this.")
              ),
              column(6,
                shg("A Prepared-Mind Culture Around Milestone Reporting"),
                app_card("Anomalies in the Data Are Opportunities, Not Just Errors",
                  "When Atera's road-readiness scoring throws up an unexpected pattern - a road segment scoring oddly, a council's data behaving differently to others - the reflex is often to treat it as a bug to be fixed quietly. Chapter 5's lens suggests treating a genuine anomaly as a possible signal first, and a bug second."),
                app_card("Encouraging Hunches Without Waiting for Certainty",
                  "Atera can build a lightweight internal habit - a shared channel or five-minute standing agenda item - for flagging 'something odd I noticed' before anyone has proven it matters. Most flags will be nothing; the occasional one won't be."),
                div(class = "success-box",
                    tags$strong("\u2705 Chapter 5 action point: "),
                    "Add a standing 'anomaly of the week' slot to Atera's team meeting - a no-judgement space to ",
                    "flag something unexpected before it's been explained.")
              )
            )
          )
        )
      )
    )
  )
}

ch5_prepared_mind_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {})
}
