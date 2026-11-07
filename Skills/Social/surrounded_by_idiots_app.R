library(shiny)
library(shinydashboard)

ui <- dashboardPage(
  skin = "blue",
  
  dashboardHeader(
    title = tags$span(
      tags$img(src = "https://img.icons8.com/fluency/48/group.png", height = "30px", style = "margin-right:8px;"),
      "Surrounded by Idiots"
    ),
    titleWidth = 320
  ),
  
  dashboardSidebar(
    width = 260,
    tags$div(
      style = "padding:15px; background:linear-gradient(135deg,#0a1128 0%,#1a2744 100%); color:#7ec8e3; font-size:12px; letter-spacing:1px; text-transform:uppercase; border-bottom:1px solid #4a90e2;",
      "Thomas Erikson · DISC Framework"
    ),
    sidebarMenu(
      menuItem("📘 Book Overview",        tabName = "overview",    icon = icon("book-open")),
      menuItem("🔴 Red — Dominant",       tabName = "red",         icon = icon("fire")),
      menuItem("🟡 Yellow — Inspiring",   tabName = "yellow",      icon = icon("sun")),
      menuItem("🟢 Green — Stable",       tabName = "green",       icon = icon("leaf")),
      menuItem("🔵 Blue — Analytical",    tabName = "blue",        icon = icon("chart-bar")),
      menuItem("🤝 Communication Guide",  tabName = "commguide",   icon = icon("comments")),
      menuItem("⚡ Conflict & Stress",    tabName = "conflict",    icon = icon("bolt")),
      menuItem("👥 Team Dynamics",        tabName = "teamdyn",     icon = icon("users")),
      menuItem("🧠 Self-Assessment",      tabName = "selfassess",  icon = icon("brain")),
      menuItem("🏆 Key Takeaways",        tabName = "takeaways",   icon = icon("trophy"))
    ),
    tags$div(
      style = "padding:20px 15px; color:#4a90e2; font-size:11px; border-top:1px solid #1a3a6e; margin-top:20px;",
      tags$p(style="color:#7ec8e3; font-weight:600; margin-bottom:6px;", "About the Book"),
      tags$p(style="color:#8899bb; line-height:1.5;", 
             "Published 2014 · Thomas Erikson · Based on William Moulton Marston's DISC model · 20M+ copies sold worldwide")
    )
  ),
  
  dashboardBody(
    tags$head(tags$style(HTML("
      body, .content-wrapper, .right-side {
        background: linear-gradient(135deg, #0a1128 0%, #1a2744 100%) !important;
        min-height: 100vh;
      }
      .main-header .logo, .main-header .navbar {
        background: linear-gradient(135deg, #0d1b3e 0%, #1a2f6e 100%) !important;
        border-bottom: 2px solid #4a90e2 !important;
      }
      .main-sidebar { background: linear-gradient(180deg, #071020 0%, #0f1e3d 100%) !important; }
      .sidebar-menu > li > a { color: #b0c4de !important; transition: all 0.3s; }
      .sidebar-menu > li > a:hover, .sidebar-menu > li.active > a {
        color: #ffffff !important;
        background: linear-gradient(90deg, #1a3a6e, #2a5298) !important;
        border-left: 3px solid #7ec8e3 !important;
      }
      .box {
        background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%) !important;
        border: 2px solid #4a90e2 !important;
        border-radius: 12px !important;
        box-shadow: 0 8px 25px rgba(74,144,226,0.3) !important;
        transition: all 0.3s ease;
        margin-bottom: 20px !important;
      }
      .box:hover { box-shadow: 0 12px 35px rgba(74,144,226,0.5) !important; transform: translateY(-2px); }
      .box-primary .box-header  { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; color:#fff !important; border-radius:10px 10px 0 0 !important; padding:15px; font-weight:600; }
      .box-info .box-header     { background: linear-gradient(135deg, #2a5298 0%, #4a90e2 100%) !important; color:#fff !important; border-radius:10px 10px 0 0 !important; padding:15px; font-weight:600; }
      .box-success .box-header  { background: linear-gradient(135deg, #2ecc71 0%, #27ae60 100%) !important; color:#fff !important; border-radius:10px 10px 0 0 !important; padding:15px; font-weight:600; }
      .box-warning .box-header  { background: linear-gradient(135deg, #f39c12 0%, #e67e22 100%) !important; color:#fff !important; border-radius:10px 10px 0 0 !important; padding:15px; font-weight:600; }
      .box-danger .box-header   { background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%) !important; color:#fff !important; border-radius:10px 10px 0 0 !important; padding:15px; font-weight:600; }
      .box-body { background: linear-gradient(135deg, #0f1f3f 0%, #1a2f5a 100%) !important; color:#e0e7ff !important; padding:20px !important; border-radius:0 0 10px 10px; }
      p { color: #c7d2fe !important; line-height:1.75 !important; }
      h4 { color: #7ec8e3 !important; margin-top:16px; }
      h3 { color: #ffffff !important; }
      li { color: #c7d2fe !important; line-height:1.8; }
      strong { color: #7ec8e3 !important; }
      .page-header { color:#fff !important; border-color:#4a90e2 !important; }
      .section-hero {
        background: linear-gradient(135deg,#1a3a6e,#2a5298);
        border-radius:14px; padding:30px; margin-bottom:24px;
        border:2px solid #4a90e2; box-shadow:0 8px 30px rgba(74,144,226,0.4);
      }
      .color-badge {
        display:inline-block; padding:6px 18px; border-radius:20px;
        font-weight:700; font-size:14px; margin:4px;
      }
      .badge-red    { background:#e74c3c; color:#fff; }
      .badge-yellow { background:#f1c40f; color:#333; }
      .badge-green  { background:#27ae60; color:#fff; }
      .badge-blue   { background:#2980b9; color:#fff; }
      .trait-grid { display:grid; grid-template-columns:1fr 1fr; gap:14px; margin-top:12px; }
      .trait-card { background:rgba(74,144,226,0.15); border:1px solid #4a90e2; border-radius:10px; padding:14px; }
      .trait-card h5 { color:#7ec8e3 !important; margin:0 0 8px 0; font-size:13px; text-transform:uppercase; letter-spacing:1px; }
      .progress-row { margin:8px 0; }
      .progress-label { color:#b0c4de !important; font-size:13px; margin-bottom:3px; }
      .progress { height:10px; border-radius:5px; background:rgba(255,255,255,0.1); }
      .quiz-option { 
        background:rgba(74,144,226,0.12); border:1px solid #4a90e2; border-radius:8px;
        padding:10px 16px; margin:6px 0; cursor:pointer; transition:all 0.2s;
        color:#c7d2fe !important;
      }
      .quiz-option:hover { background:rgba(74,144,226,0.3); border-color:#7ec8e3; }
      .result-box { 
        border-radius:12px; padding:20px; margin-top:16px; text-align:center;
        border:2px solid; font-size:16px; font-weight:600;
      }
      .selectInput select, .shiny-input-container select { 
        background:#1e3c72 !important; color:#e0e7ff !important; border:1px solid #4a90e2 !important; 
      }
      .btn-primary { background:linear-gradient(135deg,#667eea,#764ba2) !important; border:none !important; border-radius:8px !important; padding:10px 28px !important; font-weight:600 !important; }
      .btn-primary:hover { box-shadow:0 4px 15px rgba(102,126,234,0.6) !important; transform:translateY(-1px); }
      .info-icon { font-size:28px; margin-bottom:8px; display:block; }
      table { width:100%; border-collapse:collapse; }
      th { background:rgba(74,144,226,0.3) !important; color:#7ec8e3 !important; padding:10px 14px; text-align:left; border-bottom:2px solid #4a90e2; }
      td { color:#c7d2fe !important; padding:9px 14px; border-bottom:1px solid rgba(74,144,226,0.2); }
      tr:hover td { background:rgba(74,144,226,0.1); }
    "))),
    
    tabItems(
      
      # ── 1. OVERVIEW ──────────────────────────────────────────────────────────
      tabItem("overview",
        div(class="section-hero",
          h2(style="color:#fff;margin:0 0 10px;", "📘 Surrounded by Idiots"),
          p(style="color:#7ec8e3;font-size:16px;margin:0;",
            "Thomas Erikson's global bestseller on human behaviour and the four personality types that shape every interaction.")
        ),
        fluidRow(
          box(title="About the Book", status="primary", solidHeader=TRUE, width=6,
            p("Published in Sweden in 2014 as ", strong("Omgiven av Idioter"), ", the book became a worldwide phenomenon, selling over 20 million copies across 60 countries."),
            p("Thomas Erikson, a Swedish behavioural expert and author, presents a highly accessible adaptation of the ", strong("DISC model"), " — originally developed by American psychologist ", strong("William Moulton Marston"), " in 1928."),
            p("The central premise: most interpersonal frustrations and communication failures arise not from malice or stupidity, but from ", strong("fundamental differences in how people perceive and process the world"), ". Understanding these differences is the key to reducing conflict and building stronger relationships."),
            h4("Core Message"),
            p("No one is an 'idiot' — they are simply wired differently. When you understand why someone behaves the way they do, you can adapt your communication, build empathy, and get far better results with far less friction.")
          ),
          box(title="The DISC Model at a Glance", status="info", solidHeader=TRUE, width=6,
            p("The book maps human behaviour to four colour-coded personality types, each representing a cluster of traits, communication preferences, and behavioural tendencies."),
            tags$table(
              tags$thead(tags$tr(tags$th("Colour"), tags$th("Label"), tags$th("Core Drive"), tags$th("% of Population*"))),
              tags$tbody(
                tags$tr(tags$td(span(class="color-badge badge-red", "RED")), tags$td("Dominant"), tags$td("Results & Control"), tags$td("~10–15%")),
                tags$tr(tags$td(span(class="color-badge badge-yellow", "YELLOW")), tags$td("Inspiring"), tags$td("Recognition & Fun"), tags$td("~25–30%")),
                tags$tr(tags$td(span(class="color-badge badge-green", "GREEN")), tags$td("Stable"), tags$td("Harmony & Security"), tags$td("~35–40%")),
                tags$tr(tags$td(span(class="color-badge badge-blue", "BLUE")), tags$td("Analytical"), tags$td("Accuracy & Logic"), tags$td("~10–15%"))
              )
            ),
            p(style="font-size:11px;margin-top:10px;color:#8899bb !important;", "*Erikson's own rough estimates; not clinically validated population statistics.")
          )
        ),
        fluidRow(
          box(title="About Thomas Erikson", status="success", solidHeader=TRUE, width=4,
            p(strong("Thomas Erikson"), " is a Swedish author, lecturer, and behavioural expert who has worked with thousands of executives, managers, and organisations across Europe."),
            p("He holds certifications in DISC analysis and has spent over two decades coaching leaders to improve communication and performance."),
            p("His other books include ", strong("Surrounded by Bad Bosses"), ", ", strong("Surrounded by Psychopaths"), ", and ", strong("Surrounded by Narcissists"), ".")
          ),
          box(title="How To Use This Dashboard", status="warning", solidHeader=TRUE, width=4,
            tags$ul(
              tags$li("Navigate the ", strong("four colour tabs"), " to explore each personality type in depth."),
              tags$li("Visit ", strong("Communication Guide"), " to learn how each type talks to others."),
              tags$li("Explore ", strong("Conflict & Stress"), " to understand how types react under pressure."),
              tags$li("Use ", strong("Team Dynamics"), " for workplace and leadership insights."),
              tags$li("Take the ", strong("Self-Assessment"), " quiz to discover your own colour profile.")
            )
          ),
          box(title="Key Thesis", status="danger", solidHeader=TRUE, width=4,
            p(strong("Most communication failures are not personal — they are structural.")),
            p("Erikson argues that when two people clash, it is rarely because one is bad. It is because their default styles are incompatible and neither person knows how to bridge the gap."),
            p("The solution is ", strong("behavioural flexibility"), " — learning to temporarily adopt another type's preferred communication style without losing your own identity.")
          )
        )
      ),
      
      # ── 2. RED ───────────────────────────────────────────────────────────────
      tabItem("red",
        div(class="section-hero", style="border-color:#e74c3c; background:linear-gradient(135deg,#4a0f0f,#8b1a1a);",
          h2(style="color:#ff8080;margin:0 0 8px;", "🔴 The Red Personality — Dominant"),
          p(style="color:#ffb3b3;font-size:15px;margin:0;", "Fast, decisive, results-driven, and utterly impatient with anything that slows them down.")
        ),
        fluidRow(
          box(title="Core Character", status="danger", solidHeader=TRUE, width=6,
            p("Reds are the doers of the world. They act first, ask questions later, and are entirely comfortable taking charge in any situation. They thrive on challenges, competition, and clear, measurable results."),
            p("They are energised by ", strong("power, control, and autonomy"), ". Being told what to do — especially without explanation — is their greatest irritant."),
            h4("Signature Traits"),
            div(class="trait-grid",
              div(class="trait-card", tags$h5("Strengths"), tags$ul(tags$li("Decisive & fast-acting"), tags$li("Natural leader"), tags$li("Highly ambitious"), tags$li("Confident under pressure"), tags$li("Gets things done"))),
              div(class="trait-card", tags$h5("Weaknesses"), tags$ul(tags$li("Impatient & blunt"), tags$li("Poor listener"), tags$li("Can bulldoze others"), tags$li("Overlooks feelings"), tags$li("Struggles to delegate")))
            )
          ),
          box(title="Behavioural Indicators", status="danger", solidHeader=TRUE, width=6,
            h4("How to Spot a Red"),
            tags$ul(
              tags$li("Speaks quickly, directly, and without pleasantries."),
              tags$li("Makes eye contact — often sustained and intense."),
              tags$li("Leans forward in conversations; physically assertive."),
              tags$li("Interrupts when they feel the point has already been made."),
              tags$li("Carries themselves with visible authority and confidence."),
              tags$li("Their workspace is functional, not decorative."),
              tags$li("Answers questions with questions: ", em("\"What's the bottom line?\"")),
            ),
            h4("Famous Red Examples (Erikson's Frame)"),
            p("Erikson suggests archetypes: the hard-charging CEO, the military commander, the sports coach who never accepts second place.")
          )
        ),
        fluidRow(
          box(title="Communication With Reds", status="danger", solidHeader=TRUE, width=6,
            h4("What Works"),
            tags$ul(
              tags$li(strong("Be brief and direct."), " Skip the preamble — state the purpose in the first sentence."),
              tags$li(strong("Focus on outcomes."), " They care about results, not processes."),
              tags$li(strong("Give them control."), " Offer choices; don't issue mandates."),
              tags$li(strong("Be confident."), " Hesitation signals weakness to Reds."),
              tags$li(strong("Challenge them respectfully."), " They respect directness but not aggression.")
            ),
            h4("What to Avoid"),
            tags$ul(
              tags$li("Small talk and long warm-up conversations."),
              tags$li("Excessive detail, statistics, or lengthy explanations."),
              tags$li("Emotional appeals or personal anecdotes."),
              tags$li("Vague answers — Reds hate ambiguity.")
            )
          ),
          box(title="Red Under Stress", status="danger", solidHeader=TRUE, width=6,
            h4("Stress Triggers"),
            tags$ul(tags$li("Loss of control or autonomy"), tags$li("Perceived incompetence around them"), tags$li("Too many rules or bureaucratic delays"), tags$li("Being micromanaged"), tags$li("Wasted time")),
            h4("Stress Behaviour"),
            p("Under pressure, Reds become ", strong("aggressive, domineering, and dismissive"), ". They may raise their voice, issue ultimatums, or make unilateral decisions that ignore the team."),
            p("Erikson notes this is a panic response — Reds instinctively regain control when they feel it slipping. The cure is giving them agency: ", strong('"What would you like to do about it?"')),
            h4("Reds at Their Best"),
            p("When properly channelled, Reds are extraordinary in crises, turnarounds, and high-stakes negotiations. Their drive is infectious and their courage is genuine.")
          )
        )
      ),
      
      # ── 3. YELLOW ────────────────────────────────────────────────────────────
      tabItem("yellow",
        div(class="section-hero", style="border-color:#f1c40f; background:linear-gradient(135deg,#3d2e00,#7a5c00);",
          h2(style="color:#ffe680;margin:0 0 8px;", "🟡 The Yellow Personality — Inspiring"),
          p(style="color:#ffe680;font-size:15px;margin:0;", "Enthusiastic, social, creative, and endlessly optimistic — the natural storyteller of the group.")
        ),
        fluidRow(
          box(title="Core Character", status="warning", solidHeader=TRUE, width=6,
            p("Yellows are the social glue of any group. They light up rooms, generate ideas at a remarkable rate, and possess an infectious enthusiasm that draws others in."),
            p("Their world revolves around ", strong("people, possibilities, and positive energy"), ". They are motivated by recognition, approval, and fun — and will wilt in environments that are overly formal or joyless."),
            h4("Signature Traits"),
            div(class="trait-grid",
              div(class="trait-card", tags$h5("Strengths"), tags$ul(tags$li("Charismatic & persuasive"), tags$li("Creative & imaginative"), tags$li("Excellent networker"), tags$li("Optimistic & energising"), tags$li("Embraces change"))),
              div(class="trait-card", tags$h5("Weaknesses"), tags$ul(tags$li("Unfocused & scattered"), tags$li("Starts more than finishes"), tags$li("Can exaggerate"), tags$li("Avoids difficult truths"), tags$li("Poor with details & admin")))
            )
          ),
          box(title="Behavioural Indicators", status="warning", solidHeader=TRUE, width=6,
            h4("How to Spot a Yellow"),
            tags$ul(
              tags$li("Talks fast, with expressive hand gestures and animated facial expressions."),
              tags$li("Knows everyone's name and personal story within minutes."),
              tags$li("Their workspace is colourful, personal, and slightly chaotic."),
              tags$li("Loves to share stories — often goes on tangents."),
              tags$li("Is the first to suggest a social plan or celebration."),
              tags$li("Laughs frequently and loudly."),
              tags$li("May have 10 browser tabs open and three unfinished projects.")
            ),
            h4("Yellow in Meetings"),
            p("Yellows are the most vocal participants. They pitch ideas rapidly, often without having thought them through. They are not trying to dominate — they are simply externalising their thought process.")
          )
        ),
        fluidRow(
          box(title="Communication With Yellows", status="warning", solidHeader=TRUE, width=6,
            h4("What Works"),
            tags$ul(
              tags$li(strong("Be warm and enthusiastic."), " Match their energy."),
              tags$li(strong("Let them talk."), " Yellows process out loud — give them space."),
              tags$li(strong("Appeal to the big picture."), " Spark their imagination with possibilities."),
              tags$li(strong("Provide recognition."), " Publicly acknowledge their contributions."),
              tags$li(strong("Be fun."), " A sense of humour goes a very long way.")
            ),
            h4("What to Avoid"),
            tags$ul(
              tags$li("Dry, data-heavy presentations with no narrative."),
              tags$li("Excessive criticism, especially in public."),
              tags$li("Rigid procedures that kill creativity."),
              tags$li("Ignoring or interrupting them repeatedly.")
            )
          ),
          box(title="Yellow Under Stress", status="warning", solidHeader=TRUE, width=6,
            h4("Stress Triggers"),
            tags$ul(tags$li("Social rejection or being ignored"), tags$li("Monotonous, repetitive tasks"), tags$li("Overly critical environments"), tags$li("Being excluded from the group"), tags$li("Strict, humourless rules")),
            h4("Stress Behaviour"),
            p("Under pressure, Yellows become ", strong("dramatic, erratic, and attention-seeking"), ". They may lash out emotionally, spread negativity, or simply shut down and withdraw — the opposite of their natural state."),
            p("Erikson notes that the key to a stressed Yellow is ", strong("reassurance and belonging"), ": remind them they are valued and heard."),
            h4("Yellows at Their Best"),
            p("In sales, marketing, creative work, PR, or any role that requires inspiring others, Yellows are peerless. Their ability to build instant rapport is a genuine superpower.")
          )
        )
      ),
      
      # ── 4. GREEN ─────────────────────────────────────────────────────────────
      tabItem("green",
        div(class="section-hero", style="border-color:#27ae60; background:linear-gradient(135deg,#0a2e1a,#145a32);",
          h2(style="color:#80ffb3;margin:0 0 8px;", "🟢 The Green Personality — Stable"),
          p(style="color:#80ffb3;font-size:15px;margin:0;", "Patient, loyal, empathetic, and deeply committed to peace, stability, and the people they love.")
        ),
        fluidRow(
          box(title="Core Character", status="success", solidHeader=TRUE, width=6,
            p("Greens are the most common personality type and the quiet backbone of most teams and families. They are deeply relational, consistently dependable, and almost universally liked."),
            p("Their world is built on ", strong("trust, stability, and human connection"), ". They will go to extraordinary lengths to preserve harmony and protect the people they care about."),
            h4("Signature Traits"),
            div(class="trait-grid",
              div(class="trait-card", tags$h5("Strengths"), tags$ul(tags$li("Calm & patient"), tags$li("Deeply loyal"), tags$li("Excellent listener"), tags$li("Team-oriented"), tags$li("Reliable & consistent"))),
              div(class="trait-card", tags$h5("Weaknesses"), tags$ul(tags$li("Resistant to change"), tags$li("Struggles to say no"), tags$li("Avoids conflict at all costs"), tags$li("Slow to act"), tags$li("Can harbour resentment silently")))
            )
          ),
          box(title="Behavioural Indicators", status="success", solidHeader=TRUE, width=6,
            h4("How to Spot a Green"),
            tags$ul(
              tags$li("Speaks calmly, with a warm and measured tone."),
              tags$li("Listens more than they speak — and actually absorbs what you say."),
              tags$li("Their workspace has personal photos and small sentimental objects."),
              tags$li("Checks in on colleagues' wellbeing — not just their output."),
              tags$li("Will say yes when they mean maybe, or maybe when they mean no."),
              tags$li("Dislikes sudden changes to routine or surprise decisions."),
              tags$li("Often the last to leave a party — they hate abrupt endings.")
            ),
            h4("The Green Paradox"),
            p("Erikson highlights a key contradiction: Greens are often the most emotionally sophisticated people in the room, yet they are least likely to ", strong("express their own needs"), ". This leads to quiet frustration and eventually burnout.")
          )
        ),
        fluidRow(
          box(title="Communication With Greens", status="success", solidHeader=TRUE, width=6,
            h4("What Works"),
            tags$ul(
              tags$li(strong("Be warm and personal."), " Ask about them genuinely — they will open up."),
              tags$li(strong("Give advance notice."), " Greens need time to process change."),
              tags$li(strong("Be patient."), " They may not respond immediately — they are thinking."),
              tags$li(strong("Create psychological safety."), " They will not share concerns unless they feel safe."),
              tags$li(strong("Show appreciation."), " Greens thrive on knowing their loyalty is seen.")
            ),
            h4("What to Avoid"),
            tags$ul(
              tags$li("Surprise announcements or sudden reorganisations."),
              tags$li("Aggressive or confrontational communication styles."),
              tags$li("Pressing them for an immediate decision."),
              tags$li("Making them feel their steadiness is weakness.")
            )
          ),
          box(title="Green Under Stress", status="success", solidHeader=TRUE, width=6,
            h4("Stress Triggers"),
            tags$ul(tags$li("Constant conflict or instability"), tags$li("Feeling taken for granted"), tags$li("Being forced to make rapid decisions"), tags$li("Personal betrayal or broken trust"), tags$li("Sudden, unexplained change")),
            h4("Stress Behaviour"),
            p("Under severe pressure, Greens become ", strong("passively resistant, withdrawn, and quietly obstructionist"), ". They will not explode — they will simply stop cooperating, go silent, and become emotionally inaccessible."),
            p("Erikson calls this their ", strong('"stubborn mode"'), " — the most determined state a Green can reach, and one of the hardest to break."),
            h4("Greens at Their Best"),
            p("In caregiving, education, HR, social work, and any role requiring consistent relationship-building, Greens are extraordinary. Their patience and loyalty are genuine, not performed.")
          )
        )
      ),
      
      # ── 5. BLUE ──────────────────────────────────────────────────────────────
      tabItem("blue",
        div(class="section-hero", style="border-color:#2980b9; background:linear-gradient(135deg,#071a2e,#0e3460);",
          h2(style="color:#80cfff;margin:0 0 8px;", "🔵 The Blue Personality — Analytical"),
          p(style="color:#80cfff;font-size:15px;margin:0;", "Precise, logical, methodical, and quietly relentless in the pursuit of correctness and quality.")
        ),
        fluidRow(
          box(title="Core Character", status="info", solidHeader=TRUE, width=6,
            p("Blues are the architects of accuracy. They believe that every problem has a correct solution and that it is their responsibility to find it — even if that means taking twice as long as everyone else."),
            p("Their world is structured around ", strong("logic, evidence, systems, and perfection"), ". Shortcuts, approximations, and 'good enough' are anathema to them."),
            h4("Signature Traits"),
            div(class="trait-grid",
              div(class="trait-card", tags$h5("Strengths"), tags$ul(tags$li("Highly analytical"), tags$li("Meticulous & detail-oriented"), tags$li("Principled & consistent"), tags$li("Excellent critical thinker"), tags$li("Produces high-quality work"))),
              div(class="trait-card", tags$h5("Weaknesses"), tags$ul(tags$li("Perfectionist paralysis"), tags$li("Overly critical of others"), tags$li("Emotionally guarded"), tags$li("Struggles with ambiguity"), tags$li("Can come across as cold")))
            )
          ),
          box(title="Behavioural Indicators", status="info", solidHeader=TRUE, width=6,
            h4("How to Spot a Blue"),
            tags$ul(
              tags$li("Speaks precisely — corrects imprecise language, even casually."),
              tags$li("Asks detailed, probing questions before committing to anything."),
              tags$li("Their workspace is immaculately organised with clear systems."),
              tags$li("Reads the manual. All of it."),
              tags$li("Will point out the one flaw in your 99% perfect presentation."),
              tags$li("Does not volunteer personal information in professional settings."),
              tags$li("Takes longer to respond — they are formulating the ", em("correct"), " answer.")
            ),
            h4("The Blue Standard"),
            p("Erikson observes that Blues hold themselves to the same exacting standards they apply to others — making them both the best quality-control resource in any team and, at times, the most exhausting.")
          )
        ),
        fluidRow(
          box(title="Communication With Blues", status="info", solidHeader=TRUE, width=6,
            h4("What Works"),
            tags$ul(
              tags$li(strong("Be precise and factual."), " Vague claims will be challenged."),
              tags$li(strong("Prepare thoroughly."), " Blues lose respect for underprepared people fast."),
              tags$li(strong("Give them time."), " Do not rush their analysis."),
              tags$li(strong("Welcome their questions."), " They are not attacking — they are verifying."),
              tags$li(strong("Provide data and evidence."), " Anecdotes alone will not persuade them.")
            ),
            h4("What to Avoid"),
            tags$ul(
              tags$li("Emotional appeals without substantive evidence."),
              tags$li("Asking for quick gut-feel decisions on complex matters."),
              tags$li("Dismissing their concerns as 'overthinking'."),
              tags$li("Inconsistency or changing the rules without explanation.")
            )
          ),
          box(title="Blue Under Stress", status="info", solidHeader=TRUE, width=6,
            h4("Stress Triggers"),
            tags$ul(tags$li("Being expected to work with incomplete information"), tags$li("Others' carelessness or sloppiness"), tags$li("Unexpected chaos or disorganisation"), tags$li("Being overruled without logical justification"), tags$li("Unresolved contradictions or gaps in data")),
            h4("Stress Behaviour"),
            p("Under pressure, Blues become ", strong("hyper-critical, withdrawing, and stubbornly inflexible"), ". They may refuse to move forward until every variable is resolved, creating bottlenecks."),
            p("They may also turn their analytical rigour into criticism — scrutinising every decision and person around them as a displacement activity."),
            h4("Blues at Their Best"),
            p("In engineering, finance, law, medicine, research, or any role demanding precision and rigour, Blues are peerless. Their commitment to quality protects organisations from costly mistakes.")
          )
        )
      ),
      
      # ── 6. COMMUNICATION GUIDE ───────────────────────────────────────────────
      tabItem("commguide",
        div(class="section-hero",
          h2(style="color:#fff;margin:0 0 8px;", "🤝 Cross-Colour Communication Guide"),
          p(style="color:#7ec8e3;font-size:15px;margin:0;", "How each personality type communicates — and how to bridge the gaps.")
        ),
        fluidRow(
          box(title="The Communication Matrix", status="primary", solidHeader=TRUE, width=12,
            p("Erikson's core argument is that ", strong("communication failure is usually a style mismatch, not a character flaw"), ". The table below summarises how each colour prefers to send and receive information."),
            tags$table(
              tags$thead(tags$tr(tags$th("Type"), tags$th("Preferred Style"), tags$th("Wants From Others"), tags$th("Hates From Others"), tags$th("Listening Mode"))),
              tags$tbody(
                tags$tr(tags$td(span(class="color-badge badge-red","RED")), tags$td("Direct, brief, results-first"), tags$td("Competence, speed, options"), tags$td("Ramblings, emotion, excuses"), tags$td("Selective — seeks key points")),
                tags$tr(tags$td(span(class="color-badge badge-yellow","YELLOW")), tags$td("Enthusiastic, story-driven, personal"), tags$td("Enthusiasm, attention, praise"), tags$td("Negativity, rigid formality"), tags$td("Emotionally engaged but easily distracted")),
                tags$tr(tags$td(span(class="color-badge badge-green","GREEN")), tags$td("Warm, steady, consensus-seeking"), tags$td("Patience, safety, inclusion"), tags$td("Aggression, sudden change"), tags$td("Deep and patient — rarely interrupts")),
                tags$tr(tags$td(span(class="color-badge badge-blue","BLUE")), tags$td("Precise, structured, evidence-based"), tags$td("Accuracy, logic, data"), tags$td("Exaggeration, vagueness"), tags$td("Critical and evaluative"))
              )
            )
          )
        ),
        fluidRow(
          box(title="Red ↔ Yellow", status="warning", solidHeader=TRUE, width=6,
            p(strong("Natural friction:"), " Reds find Yellows unfocused and inefficient. Yellows find Reds cold and dismissive."),
            h4("Bridge Strategies"),
            tags$ul(
              tags$li("Red adapts: Allow Yellow to share their idea briefly before redirecting to outcomes."),
              tags$li("Yellow adapts: Lead with the result first, keep enthusiasm contained in professional settings."),
              tags$li("Common ground: Both are action-oriented and dislike excessive deliberation.")
            )
          ),
          box(title="Red ↔ Green", status="warning", solidHeader=TRUE, width=6,
            p(strong("Natural friction:"), " Reds perceive Greens as slow and conflict-avoidant. Greens find Reds aggressive and inconsiderate."),
            h4("Bridge Strategies"),
            tags$ul(
              tags$li("Red adapts: Slow down the pace; acknowledge the human element."),
              tags$li("Green adapts: Practise stating needs directly rather than hinting."),
              tags$li("Common ground: Both are fiercely loyal to their commitments.")
            )
          )
        ),
        fluidRow(
          box(title="Red ↔ Blue", status="info", solidHeader=TRUE, width=6,
            p(strong("Natural friction:"), " Reds see Blues as paralysed by over-analysis. Blues see Reds as reckless and careless."),
            h4("Bridge Strategies"),
            tags$ul(
              tags$li("Red adapts: Frame the question as 'what are the top 3 risks?' to get focused analysis."),
              tags$li("Blue adapts: Provide a provisional answer early and signal you will refine it."),
              tags$li("Common ground: Both prioritise getting things right — just on different timescales.")
            )
          ),
          box(title="Yellow ↔ Blue", status="info", solidHeader=TRUE, width=6,
            p(strong("Natural friction:"), " Yellows find Blues dull and killjoy. Blues find Yellows superficial and unreliable."),
            h4("Bridge Strategies"),
            tags$ul(
              tags$li("Yellow adapts: Present ideas with supporting evidence, not just enthusiasm."),
              tags$li("Blue adapts: Acknowledge the creative merit of an idea before listing its flaws."),
              tags$li("Common ground: Both are fiercely independent thinkers who dislike being bossed around.")
            )
          )
        ),
        fluidRow(
          box(title="Yellow ↔ Green", status="success", solidHeader=TRUE, width=6,
            p(strong("Natural affinity:"), " Both are people-oriented and warm. The main tension is that Yellows can overwhelm Greens with energy and change."),
            h4("Bridge Strategies"),
            tags$ul(
              tags$li("Yellow adapts: Give Green time and space; don't push for immediate reactions."),
              tags$li("Green adapts: Express enthusiasm explicitly — don't let Yellow think you're disengaged.")
            )
          ),
          box(title="Green ↔ Blue", status="success", solidHeader=TRUE, width=6,
            p(strong("Natural affinity:"), " Both are thoughtful, non-confrontational, and tend to follow rather than lead. Tension arises from Blue's critical streak vs. Green's sensitivity."),
            h4("Bridge Strategies"),
            tags$ul(
              tags$li("Blue adapts: Soften the delivery of criticism; context matters to Greens."),
              tags$li("Green adapts: Don't interpret Blue's bluntness as personal hostility.")
            )
          )
        )
      ),
      
      # ── 7. CONFLICT & STRESS ─────────────────────────────────────────────────
      tabItem("conflict",
        div(class="section-hero",
          h2(style="color:#fff;margin:0 0 8px;", "⚡ Conflict, Pressure & Stress Responses"),
          p(style="color:#7ec8e3;font-size:15px;margin:0;", "How each colour behaves when the pressure rises — and how to de-escalate.")
        ),
        fluidRow(
          box(title="Why Colours Clash", status="primary", solidHeader=TRUE, width=12,
            p("Erikson dedicates several chapters to conflict dynamics, noting that ", strong("most interpersonal conflicts are style amplifications"), ": under stress, each type's natural traits become exaggerated and defensive."),
            p("Understanding this is transformative: you stop trying to fight the person and start trying to understand the ", strong("underlying need"), " their stressed behaviour is signalling.")
          )
        ),
        fluidRow(
          box(title="Conflict Escalation by Type", status="danger", solidHeader=TRUE, width=6,
            tags$table(
              tags$thead(tags$tr(tags$th("Type"), tags$th("Under Mild Stress"), tags$th("Under Severe Stress"), tags$th("De-escalation Key"))),
              tags$tbody(
                tags$tr(tags$td(span(class="color-badge badge-red","RED")), tags$td("Blunt, dismissive"), tags$td("Aggressive, authoritarian"), tags$td("Give back control")),
                tags$tr(tags$td(span(class="color-badge badge-yellow","YELLOW")), tags$td("Dramatic, over-talkative"), tags$td("Erratic, emotionally volatile"), tags$td("Validate & reassure")),
                tags$tr(tags$td(span(class="color-badge badge-green","GREEN")), tags$td("Evasive, non-committal"), tags$td("Silent, stubborn, resentful"), tags$td("Create safety & patience")),
                tags$tr(tags$td(span(class="color-badge badge-blue","BLUE")), tags$td("Critical, nitpicking"), tags$td("Withdrawn, inflexible, cold"), tags$td("Provide data & logic"))
              )
            )
          ),
          box(title="The Feedback Problem", status="warning", solidHeader=TRUE, width=6,
            p("One of Erikson's most practical observations is that ", strong("feedback must be style-matched"), " or it will backfire completely."),
            tags$ul(
              tags$li(strong("Red:"), " Deliver feedback directly and briefly. Lead with impact. Skip emotional framing."),
              tags$li(strong("Yellow:"), " Start positive. Deliver criticism privately. Focus on improvement, not failure."),
              tags$li(strong("Green:"), " Build trust first. Take extra time. Be gentle and patient. Never ambush them."),
              tags$li(strong("Blue:"), " Be factual and specific. Reference evidence. Allow time to respond in writing if needed.")
            ),
            p("Erikson warns that the biggest mistake managers make is giving the ", strong("same feedback style to all four types"), ". What liberates a Red will crush a Green.")
          )
        ),
        fluidRow(
          box(title="Cross-Colour Conflict Flashpoints", status="danger", solidHeader=TRUE, width=12,
            tags$table(
              tags$thead(tags$tr(tags$th("Pair"), tags$th("Core Tension"), tags$th("What Each Thinks"), tags$th("Resolution Path"))),
              tags$tbody(
                tags$tr(tags$td("Red + Green"), tags$td("Pace & approach"), tags$td("Red: 'Too slow.' Green: 'Too brutal.'"), tags$td("Red slows; Green asserts needs")),
                tags$tr(tags$td("Red + Blue"), tags$td("Speed vs. rigour"), tags$td("Red: 'Over-analysis.' Blue: 'Recklessness.'"), tags$td("Set clear decision timelines")),
                tags$tr(tags$td("Yellow + Blue"), tags$td("Energy vs. precision"), tags$td("Yellow: 'Killjoy.' Blue: 'Shallow.'"), tags$td("Separate ideation from evaluation")),
                tags$tr(tags$td("Green + Red"), tags$td("Harmony vs. results"), tags$td("Green: 'Uncaring.' Red: 'Sensitive.'"), tags$td("Name the behaviour, not the person")),
                tags$tr(tags$td("Blue + Yellow"), tags$td("Logic vs. emotion"), tags$td("Blue: 'Unreliable.' Yellow: 'Cold.'"), tags$td("Frame ideas as hypotheses not facts"))
              )
            )
          )
        )
      ),
      
      # ── 8. TEAM DYNAMICS ─────────────────────────────────────────────────────
      tabItem("teamdyn",
        div(class="section-hero",
          h2(style="color:#fff;margin:0 0 8px;", "👥 Team Dynamics & Leadership"),
          p(style="color:#7ec8e3;font-size:15px;margin:0;", "How the four types work together — and how great leaders manage each one.")
        ),
        fluidRow(
          box(title="The Ideal Team Mix", status="primary", solidHeader=TRUE, width=6,
            p("Erikson argues that the ", strong("highest-performing teams contain all four colours"), " — not because any one type is superior, but because each brings a critical function:"),
            tags$table(
              tags$thead(tags$tr(tags$th("Type"), tags$th("Team Role"), tags$th("Critical Contribution"))),
              tags$tbody(
                tags$tr(tags$td(span(class="color-badge badge-red","RED")), tags$td("Driver"), tags$td("Keeps the team moving; makes hard calls")),
                tags$tr(tags$td(span(class="color-badge badge-yellow","YELLOW")), tags$td("Creator"), tags$td("Generates ideas; energises the group")),
                tags$tr(tags$td(span(class="color-badge badge-green","GREEN")), tags$td("Stabiliser"), tags$td("Ensures cohesion; spots people problems early")),
                tags$tr(tags$td(span(class="color-badge badge-blue","BLUE")), tags$td("Controller"), tags$td("Catches errors; maintains standards"))
              )
            )
          ),
          box(title="Leading Each Colour", status="info", solidHeader=TRUE, width=6,
            h4("What Each Type Needs From a Leader"),
            tags$ul(
              tags$li(span(class="color-badge badge-red","RED"), " — Autonomy, clear authority, and the chance to win."),
              tags$li(span(class="color-badge badge-yellow","YELLOW"), " — Praise, visibility, creative freedom, and fun."),
              tags$li(span(class="color-badge badge-green","GREEN"), " — Stability, genuine appreciation, and no surprises."),
              tags$li(span(class="color-badge badge-blue","BLUE"), " — Logic, structure, high standards, and time to be thorough.")
            ),
            h4("The Leadership Trap"),
            p("Most leaders default to managing everyone ", strong("the way they themselves prefer to be led"), ". A Red leader gives autonomy to all — including Greens who need more guidance. A Blue leader requires evidence from all — including Yellows who communicate via intuition.")
          )
        ),
        fluidRow(
          box(title="Common Team Pathologies", status="danger", solidHeader=TRUE, width=6,
            h4("All-Red Team"),
            p("High output but constant power struggles. No one backs down; collaboration suffers. Strong in sprints, unsustainable long-term."),
            h4("All-Yellow Team"),
            p("Bursting with ideas but perpetually unfinished. Excellent creativity, poor follow-through. Needs Blue and Red to land anything."),
            h4("All-Green Team"),
            p("Warm, harmonious — but potentially stagnant. Conflict-averse, resistant to change. Excellent culture, potentially poor decisiveness."),
            h4("All-Blue Team"),
            p("Extraordinarily rigorous but potentially paralysed. Over-analysis, missed deadlines, low morale. Needs Yellow and Red energy to move.")
          ),
          box(title="Practical Team Applications", status="success", solidHeader=TRUE, width=6,
            h4("Hiring for Gaps"),
            p("Before hiring, map your existing team's colours. If you are all Red and Blue, your next hire may need to be Yellow-Green to balance pace with people."),
            h4("Project Phases by Colour"),
            tags$ul(
              tags$li(strong("Discovery phase:"), " Yellow — wild ideation, open exploration."),
              tags$li(strong("Planning phase:"), " Blue — structured requirements, risk analysis."),
              tags$li(strong("Execution phase:"), " Red — drive, accountability, pace."),
              tags$li(strong("Sustain phase:"), " Green — relationship maintenance, team wellbeing.")
            ),
            h4("Meeting Design"),
            p("Structure meetings to serve all types: brief agenda (Red), creative discussion time (Yellow), consensus-checking (Green), factual Q&A (Blue).")
          )
        )
      ),
      
      # ── 9. SELF-ASSESSMENT ───────────────────────────────────────────────────
      tabItem("selfassess",
        div(class="section-hero",
          h2(style="color:#fff;margin:0 0 8px;", "🧠 Discover Your Colour Profile"),
          p(style="color:#7ec8e3;font-size:15px;margin:0;", "Answer these eight situational questions to find your dominant and secondary colour.")
        ),
        fluidRow(
          box(title="Question 1: A project hits a crisis. What is your first instinct?", status="primary", solidHeader=TRUE, width=6,
            radioButtons("q1", label=NULL, choices=c(
              "A — Take charge immediately and direct everyone." = "R",
              "B — Rally the team, boost morale, generate creative solutions." = "Y",
              "C — Make sure everyone is okay and supported." = "G",
              "D — Analyse what went wrong before acting." = "B"
            ))
          ),
          box(title="Question 2: At a party, you are most likely to…", status="primary", solidHeader=TRUE, width=6,
            radioButtons("q2", label=NULL, choices=c(
              "A — Network strategically and speak to the most important people." = "R",
              "B — Become the social centre and meet absolutely everyone." = "Y",
              "C — Spend quality time with a few good friends." = "G",
              "D — Observe the room and hold back until you find interesting conversation." = "B"
            ))
          )
        ),
        fluidRow(
          box(title="Question 3: Your biggest frustration at work?", status="info", solidHeader=TRUE, width=6,
            radioButtons("q3", label=NULL, choices=c(
              "A — Slow people and unnecessary meetings." = "R",
              "B — Boring, repetitive, joyless environments." = "Y",
              "C — Constant change and interpersonal conflict." = "G",
              "D — Imprecision, carelessness, and corners being cut." = "B"
            ))
          ),
          box(title="Question 4: How do you prefer to receive feedback?", status="info", solidHeader=TRUE, width=6,
            radioButtons("q4", label=NULL, choices=c(
              "A — Directly and immediately — don't soften it." = "R",
              "B — Warmly, with a focus on what I can improve." = "Y",
              "C — Privately, gently, with time to process." = "G",
              "D — In writing, with specific evidence and data." = "B"
            ))
          )
        ),
        fluidRow(
          box(title="Question 5: Before making a big decision, you…", status="success", solidHeader=TRUE, width=6,
            radioButtons("q5", label=NULL, choices=c(
              "A — Trust your gut and act fast." = "R",
              "B — Talk it through with someone whose opinion you trust." = "Y",
              "C — Consider carefully how it will affect everyone involved." = "G",
              "D — Research thoroughly and model out the likely outcomes." = "B"
            ))
          ),
          box(title="Question 6: Others most often describe you as…", status="success", solidHeader=TRUE, width=6,
            radioButtons("q6", label=NULL, choices=c(
              "A — Determined and confident." = "R",
              "B — Fun and enthusiastic." = "Y",
              "C — Reliable and caring." = "G",
              "D — Precise and thoughtful." = "B"
            ))
          )
        ),
        fluidRow(
          box(title="Question 7: When someone is late or disorganised, you feel…", status="warning", solidHeader=TRUE, width=6,
            radioButtons("q7", label=NULL, choices=c(
              "A — Annoyed — time is a resource, not to be wasted." = "R",
              "B — Mildly irritated but able to brush it off." = "Y",
              "C — Concerned — wonder if something is wrong with them." = "G",
              "D — Quietly appalled — it signals a lack of respect and professionalism." = "B"
            ))
          ),
          box(title="Question 8: Your ideal work environment is…", status="warning", solidHeader=TRUE, width=6,
            radioButtons("q8", label=NULL, choices=c(
              "A — Fast-paced, high stakes, results-focused." = "R",
              "B — Collaborative, creative, and social." = "Y",
              "C — Stable, warm, predictable, and people-centred." = "G",
              "D — Structured, logical, precise, and high-quality." = "B"
            ))
          )
        ),
        fluidRow(
          box(title="Get My Result", status="primary", solidHeader=TRUE, width=12,
            actionButton("calc", "🎨 Calculate My Colour Profile", class="btn-primary"),
            tags$br(), tags$br(),
            uiOutput("quiz_result")
          )
        )
      ),
      
      # ── 10. TAKEAWAYS ────────────────────────────────────────────────────────
      tabItem("takeaways",
        div(class="section-hero",
          h2(style="color:#fff;margin:0 0 8px;", "🏆 Key Takeaways & Practical Wisdom"),
          p(style="color:#7ec8e3;font-size:15px;margin:0;", "The essential lessons from Surrounded by Idiots — distilled for daily application.")
        ),
        fluidRow(
          box(title="The 10 Core Lessons", status="primary", solidHeader=TRUE, width=6,
            tags$ol(
              tags$li(strong("No one is an idiot."), " Behavioural difference is not deficiency."),
              tags$li(strong("You have a default colour"), " — and it shapes everything from how you listen to how you argue."),
              tags$li(strong("Flexibility is the skill."), " The goal is not to change your type but to adapt your style situationally."),
              tags$li(strong("Match your message to your audience's colour"), " — not your own preference."),
              tags$li(strong("Stress amplifies your type."), " Know your stress triggers before they know you."),
              tags$li(strong("Great teams are colour-diverse."), " Monocultures of personality underperform."),
              tags$li(strong("Feedback must be style-matched"), " or it will miss its target entirely."),
              tags$li(strong("Conflict is usually a gap in translation,"), " not a gap in character."),
              tags$li(strong("Understanding is not the same as agreeing."), " You can adapt without becoming someone else."),
              tags$li(strong("The person who adapts first"), " is not the weak one — they are the wise one.")
            )
          ),
          box(title="Erikson's Most Quotable Insights", status="info", solidHeader=TRUE, width=6,
            h4("On Understanding Others"),
            p(em('"How can you expect someone to understand you if you have no interest in understanding them?"')),
            h4("On Behavioural Flexibility"),
            p(em('"The biggest handicap in communication is the mistaken assumption that it has taken place."')),
            h4("On Self-Awareness"),
            p(em('"Knowing your own colour is the first step to understanding why others find you difficult — and why you find them difficult in return."')),
            h4("On Team Building"),
            p(em('"A team of identical personalities is not a strength. It is a vulnerability masquerading as harmony."'))
          )
        ),
        fluidRow(
          box(title="Criticism & Limitations of the Model", status="warning", solidHeader=TRUE, width=6,
            p("No behavioural framework is without its critics. For intellectual completeness:"),
            tags$ul(
              tags$li(strong("Oversimplification:"), " Human personality is far more complex than four quadrants. Erikson himself acknowledges most people are blends."),
              tags$li(strong("Static framing:"), " Personality shifts with context, age, culture, and relationships — the model captures tendencies, not absolutes."),
              tags$li(strong("Scientific limitations:"), " DISC-type models have mixed empirical validation compared to the Big Five personality framework."),
              tags$li(strong("Self-report bias:"), " Self-assessments reflect how people see themselves, not necessarily how they behave.")
            ),
            p("Erikson recommends using the model as a ", strong("starting point for empathy"), ", not a label to fix on someone permanently.")
          ),
          box(title="How to Apply This Tomorrow", status="success", solidHeader=TRUE, width=6,
            h4("In the Next 24 Hours"),
            tags$ul(
              tags$li("Identify the colour of your most challenging relationship."),
              tags$li("List ", strong("one thing you currently do"), " that probably annoys that person."),
              tags$li("Commit to adapting it — just once — and observe what changes.")
            ),
            h4("This Week"),
            tags$ul(
              tags$li("Map your team's colours based on observation."),
              tags$li("Adjust how you give feedback to one person whose style differs from yours."),
              tags$li("Next time conflict arises, ask: ", em('"Is this a character problem or a style problem?"'))
            ),
            h4("Long Term"),
            tags$ul(
              tags$li("Build the habit of reading others before communicating."),
              tags$li("Seek out roles, partners, and teams that complement your colour."),
              tags$li("Return to the framework under stress — it is most powerful when you need it most.")
            )
          )
        ),
        fluidRow(
          box(title="Further Reading", status="danger", solidHeader=TRUE, width=12,
            p("To deepen your understanding of personality, communication, and behavioural frameworks:"),
            tags$ul(
              tags$li(strong("Surrounded by Psychopaths"), " — Thomas Erikson (manipulation and dark traits)"),
              tags$li(strong("Surrounded by Bad Bosses"), " — Thomas Erikson (workplace leadership)"),
              tags$li(strong("Never Split the Difference"), " — Chris Voss (negotiation and behavioural intelligence)"),
              tags$li(strong("Emotional Intelligence"), " — Daniel Goleman (the science of self-awareness)"),
              tags$li(strong("The Five Dysfunctions of a Team"), " — Patrick Lencioni (team dynamics in depth)"),
              tags$li(strong("Quiet: The Power of Introverts"), " — Susan Cain (introversion and the Green/Blue dynamic)"),
              tags$li(strong("Personality and Individual Differences"), " — H.J. Eysenck (academic underpinnings of type theory)")
            )
          )
        )
      )
    )
  )
)

server <- function(input, output, session) {
  
  observeEvent(input$calc, {
    answers <- c(input$q1, input$q2, input$q3, input$q4, 
                 input$q5, input$q6, input$q7, input$q8)
    
    counts <- table(factor(answers, levels = c("R","Y","G","B")))
    primary <- names(which.max(counts))
    
    remaining <- counts
    remaining[primary] <- 0
    secondary <- names(which.max(remaining))
    
    profile <- list(
      R = list(name="Red — Dominant",    emoji="🔴", col="#e74c3c", bg="#4a0f0f",
               desc="You are results-driven, decisive, and naturally authoritative. You act fast, think big, and expect others to keep up. Your superpower is making things happen; your growth edge is patience and emotional attunement."),
      Y = list(name="Yellow — Inspiring", emoji="🟡", col="#f1c40f", bg="#3d2e00",
               desc="You are charismatic, creative, and socially magnetic. People are energised by your presence and inspired by your enthusiasm. Your superpower is connecting and motivating; your growth edge is follow-through and consistency."),
      G = list(name="Green — Stable",     emoji="🟢", col="#27ae60", bg="#0a2e1a",
               desc="You are warm, patient, and deeply loyal. Others feel safe around you and trust you instinctively. Your superpower is human connection and reliability; your growth edge is asserting your needs and embracing necessary change."),
      B = list(name="Blue — Analytical",  emoji="🔵", col="#2980b9", bg="#071a2e",
               desc="You are precise, logical, and committed to quality. You think before you act and hold yourself to the highest standard. Your superpower is rigour and critical thinking; your growth edge is flexibility and emotional warmth.")
    )
    
    p_info <- profile[[primary]]
    s_info <- profile[[secondary]]
    
    output$quiz_result <- renderUI({
      tagList(
        div(class="result-box", 
            style=paste0("background:", p_info$bg, "; border-color:", p_info$col, "; color:", p_info$col, ";"),
          tags$span(class="info-icon", p_info$emoji),
          tags$strong(paste("Primary Colour:", p_info$name)),
          tags$br(), tags$br(),
          tags$p(style=paste0("color:", p_info$col, " !important; font-weight:normal;"), p_info$desc)
        ),
        div(class="result-box",
            style=paste0("background:", s_info$bg, "; border-color:", s_info$col, "; color:", s_info$col, "; opacity:0.85;"),
          tags$span(class="info-icon", s_info$emoji),
          tags$strong(paste("Secondary Colour:", s_info$name)),
          tags$br(), tags$br(),
          tags$p(style=paste0("color:", s_info$col, " !important; font-weight:normal;"), s_info$desc)
        ),
        p(style="text-align:center; color:#8899bb !important; font-size:12px; margin-top:12px;",
          "Note: This is a reflective tool based on Erikson's framework, not a clinical psychometric assessment.")
      )
    })
  })
}

shinyApp(ui = ui, server = server)
