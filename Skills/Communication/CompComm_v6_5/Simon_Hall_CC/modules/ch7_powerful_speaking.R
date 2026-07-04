# modules/ch7_powerful_speaking.R
# Chapter 7: Powerful Public Speaking and Presentations

ch7_powerful_speaking_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "aa-hero",
        tags$h1("Chapter 7"),
        tags$h2("Powerful Public Speaking and Presentations"),
        div(
          span(class = "hero-badge", icon("comments"),      " Interactions"),
          span(class = "hero-badge", icon("map-signs"),     " Signposting"),
          span(class = "hero-badge", icon("magic"),         " Magic Moments"),
          span(class = "hero-badge", icon("walking"),       " Body Language"),
          span(class = "hero-badge", icon("question-circle"), " Q&A Mastery"),
          span(class = "hero-badge", icon("video"),         " Online Presenting")
        )
    ),

    fluidRow(
      box(title = "Chapter 7 \u2014 Overview", status = "primary",
          solidHeader = TRUE, width = 12,
          p("Chapter 7 moves from preparation to performance \u2014 the advanced techniques that ",
            "separate competent presenters from truly powerful ones. Interaction, signposting, ",
            "body language, managing nerves, handling the Q&A, and mastering the online environment: ",
            "these are the skills that make the difference between a presentation that informs ",
            "and one that genuinely changes minds."),
          fluidRow(
            column(2, metric_card("Interact",  "Audience Engagement")),
            column(2, metric_card("Sign",      "Guide the Journey")),
            column(2, metric_card("\u2728",          "Create Magic Moments")),
            column(2, metric_card("Body",      "93% Non-Verbal Impact")),
            column(2, metric_card("Q&A",       "Prepare Every Answer")),
            column(2, metric_card("Online",    "New Rules Apply"))
          )
      )
    ),

    fluidRow(
      box(title = NULL, status = "primary", solidHeader = FALSE, width = 12,
        tabsetPanel(
          id = ns("tabs"),

          # ── GENERAL CONCEPTS ──────────────────────────
          tabPanel("\U0001f4da General Concepts",
            br(),
            fluidRow(
              column(6,
                sh("Interactions"),
                concept_card("Presentations Are Conversations, Not Broadcasts",
                  "The most powerful presentations are not monologues \u2014 they are structured 
                  conversations in which the presenter takes the audience on a journey 
                  while remaining responsive to their reactions. 
                  Interactions \u2014 questions to the audience, pauses for reflection, 
                  moments of genuine engagement \u2014 transform a passive audience 
                  into active participants. Active participants are more engaged, 
                  more persuaded and more likely to act."),

                concept_card("Types of Audience Interaction",
                  "<b>Rhetorical questions:</b> \u2018How many of you have ever had to make a major decision 
                  without enough data?\u2019 \u2014 no answer required, but the audience answers mentally.<br><br>
                  <b>Show of hands:</b> A physical interaction that creates commitment and engagement.<br><br>
                  <b>Directed questions:</b> Asking a specific individual or group for their view 
                  \u2014 creates energy but requires skill to manage.<br><br>
                  <b>Pause for reflection:</b> \u2018Take a moment to consider what that means for your organisation.\u2019 
                  Creates ownership of the idea in the audience\u2019s mind."),

                sh("Signposting"),
                concept_card("Tell Them Where You Are and Where You\u2019re Going",
                  "Signposting is the practice of explicitly guiding the audience through 
                  the structure of the presentation: 
                  \u2018I\u2019m going to cover three things today\u2019; \u2018That brings me to my second point\u2019; 
                  \u2018We\u2019re now halfway through\u2019; \u2018Before I move on, let me summarise\u2019. 
                  Signposting reduces cognitive load \u2014 when the audience knows where they are, 
                  they can focus on understanding the content rather than tracking the structure. 
                  It also signals a prepared, confident presenter."),

                concept_card("Opening and Closing Signposts",
                  "<b>Opening signpost:</b> State your agenda, your duration and your purpose 
                  in the first 90 seconds. This gives the audience permission to relax and listen 
                  rather than spending the first five minutes wondering what the presentation is about.<br><br>
                  <b>Closing signpost:</b> Signal the end before it arrives: 
                  \u2018I want to leave you with one final thought\u2019 or \u2018In summary, there are three things 
                  I hope you\u2019ll take from today\u2019. This prepares the audience to receive and 
                  retain your most important message."),

                sh("Magic Moments"),
                concept_card("Create at Least One Moment They Will Remember",
                  "A magic moment is a planned peak of emotional or intellectual impact 
                  \u2014 a moment designed to be memorable. It might be a surprising demonstration, 
                  an unexpected visual, a counterintuitive statement, a moment of genuine humour, 
                  or an emotionally resonant story. 
                  Every presentation of any length should contain at least one magic moment, 
                  deliberately placed at a point where the audience\u2019s attention is highest. 
                  The magic moment is what the audience talks about afterwards.")
              ),

              column(6,
                sh("Body Language"),
                concept_card("Your Body Communicates Before You Speak",
                  "Research suggests that audiences form their initial impression of a presenter 
                  within seconds, primarily from non-verbal signals: posture, eye contact, 
                  movement and facial expression. A presenter who stands straight, 
                  makes genuine eye contact, moves with purpose and uses natural hand gestures 
                  projects confidence and authority before saying a word. 
                  Conversely, a presenter who hunches, avoids eye contact or fidgets 
                  signals nervousness and undermines credibility regardless of the quality 
                  of their content."),

                concept_card("The Four Body Language Essentials",
                  "<b>1. Posture:</b> Stand straight with feet shoulder-width apart. 
                  Avoid rocking, swaying or crossing legs. Stillness signals confidence.<br><br>
                  <b>2. Eye contact:</b> Hold eye contact with individual audience members 
                  for 3\u20135 seconds before moving on. This creates connection and reads as confidence.<br><br>
                  <b>3. Gesture:</b> Use open, natural hand gestures to emphasise key points. 
                  Avoid pointing, crossing arms or hands in pockets.<br><br>
                  <b>4. Movement:</b> Move with purpose \u2014 step forward to emphasise a key point, 
                  step back to signal a transition. Random movement is distracting."),

                sh("Nerves, Redundancies and Authority"),
                concept_card("Managing Performance Anxiety",
                  "Nerves are physiologically identical to excitement \u2014 the body\u2019s response 
                  (adrenaline, raised heart rate, heightened awareness) is the same. 
                  The difference is in interpretation. Reframing nervousness as readiness 
                  \u2014 \u2018my body is preparing me to perform\u2019 \u2014 is one of the most evidence-backed 
                  performance anxiety techniques available. 
                  Combined with thorough preparation, slow breathing and a physical warm-up, 
                  nerves become an asset rather than a liability."),

                concept_card("Removing Verbal Redundancies",
                  "Verbal redundancies \u2014 \u2018um\u2019, \u2018er\u2019, \u2018you know\u2019, \u2018basically\u2019, \u2018sort of\u2019, \u2018kind of\u2019, 
                  \u2018to be honest\u2019 \u2014 undermine authority and signal uncertainty. 
                  They are habits that can be eliminated through recording and reviewing 
                  your own presentations, slowing down your delivery rate, 
                  and replacing filled pauses with silent pauses. 
                  A silent pause communicates thought and confidence. 
                  A filled pause communicates uncertainty.")
              )
            ),

            hr(class = "divider"),
            fluidRow(
              column(6,
                sh("Timings"),
                concept_card("Respect the Clock \u2014 It Is a Measure of Respect",
                  "Running over time is one of the most disrespectful things a presenter can do. 
                  It signals poor preparation, poor editing and disregard for the audience\u2019s schedule. 
                  The rule: always finish slightly under time. 
                  A 20-minute slot should receive an 18-minute presentation. 
                  The additional 2 minutes creates goodwill, allows for questions, 
                  and leaves the audience with a positive impression of the presenter\u2019s discipline."),

                sh("Online Presenting"),
                concept_card("The Online Environment Changes Everything",
                  "Online presenting is a fundamentally different medium from in-person presenting. 
                  The camera creates a new primary relationship \u2014 between the presenter and the lens, 
                  not between the presenter and the room. Looking at the camera (not the screen) 
                  is the equivalent of eye contact in a live presentation and must be practised deliberately. 
                  Energy levels must also be higher online \u2014 the screen compresses and dampens personality, 
                  requiring the presenter to project with approximately 20% more energy 
                  than feels comfortable.")
              ),

              column(6,
                sh("The Question and Answer Session"),
                concept_card("The Q&A Is Part of the Presentation",
                  "Most presenters treat the Q&A as an uncontrollable postscript to their presentation. 
                  The best presenters treat it as a prepared and managed extension. 
                  This means: anticipating the 10 most likely questions in advance and preparing answers; 
                  having a response strategy for hostile or off-topic questions; 
                  and knowing how to use bridging to return to your key messages 
                  even when the question takes you elsewhere."),

                concept_card("The Q&A Bridging Formula",
                  "When a question threatens to take you off-message, use the three-step bridge:<br><br>
                  <b>Step 1 \u2014 Acknowledge:</b> \u2018That\u2019s an important question.\u2019 (Never dismiss.)<br><br>
                  <b>Step 2 \u2014 Answer briefly:</b> Address the question in one or two sentences, 
                  without being evasive.<br><br>
                  <b>Step 3 \u2014 Bridge:</b> \u2018What that really points to is...\u2019 or \u2018The wider context for that is...\u2019 
                  \u2014 and return to your Golden Thread."),

                sh("The Golden Secret of Success in Presentations"),
                concept_card("Preparation Is the Only Secret",
                  "There is no shortcut to powerful presenting. The single differentiator 
                  between an average presenter and a great one is the degree of preparation. 
                  Great presenters know their material so thoroughly that they can respond 
                  to any situation \u2014 technology failure, hostile question, unexpected development \u2014 
                  without losing their composure or their message. 
                  Preparation is not memorisation; it is internalisation. 
                  Know the material well enough to deliver it six different ways."),

                div(class = "success-box",
                    tags$strong("\u2705 Chapter 7 Summary: "),
                    "Interact deliberately. Signpost clearly. Create one magic moment. 
                    Let your body language signal confidence. Remove verbal redundancies. 
                    Finish under time. Prepare every Q&A answer. And on video: look at the camera. 
                    The golden secret: prepare until you know it six different ways.")
              )
            )
          ), # end General Concepts

          # ── ATERA ANALYTICS APPLICATION ──────────────
          tabPanel("\U0001f3e2 Applicability on Atera Analytics",
            br(),
            fluidRow(
              column(6,
                shg("Interactions \u2014 Making Atera Presentations Two-Way"),
                app_card("Building Audience Engagement Into Atera\u2019s Pitch Structure",
                  "Atera\u2019s current presentations are primarily one-directional \u2014 presenting findings 
                  and capabilities to a passive audience. Introducing deliberate interaction points 
                  transforms the dynamic:<br><br>
                  <b>For council presentations, open with a rhetorical question:</b><br>
                  \u2018How many of you have been asked whether your roads are ready for autonomous vehicles?\u2019 
                  (Pause. Let the question land.)<br><br>
                  <b>For investor meetings, use a directed question early:</b><br>
                  \u2018What would you estimate it costs to manually assess 100km of road for AV readiness?\u2019 
                  (Let them answer. Then reveal the actual figure and the comparison with Atera\u2019s platform cost.)<br><br>
                  <b>For Innovate UK reviews, use a pause for reflection after the dashboard demo:</b><br>
                  \u2018Take a moment to consider what this means for the 100+ councils we\u2019re targeting.\u2019"),

                app_card("Signposting in Atera\u2019s Presentations",
                  "Every Atera presentation should open with an explicit three-part agenda stated in 
                  the first 60 seconds:<br><br>
                  Example: \u2018Today I\u2019m going to cover three things: where we are with the platform, 
                  what it means commercially, and what we need from you. This will take 20 minutes, 
                  and I\u2019d like to leave 10 minutes for questions.\u2019<br><br>
                  And close with a deliberate final signpost:<br>
                  \u2018Before I hand over to questions, let me leave you with the three things 
                  I hope you\u2019ll take from today: the platform works, it\u2019s commercially ready, 
                  and we need three pilot partners by Q2.\u2019"),

                shg("Magic Moments for Atera Presentations"),
                app_card("Atera\u2019s Planned Magic Moments",
                  "Every Atera presentation should contain at least one planned magic moment. 
                  The strongest candidates:<br><br>
                  <b>The live dashboard demonstration:</b> Showing the EV Route Optimizer score 
                  a real Cambridge route in real time is Atera\u2019s most powerful magic moment. 
                  It should be the centrepiece of every stakeholder presentation, 
                  carefully set up with context, delivered slowly, and followed by a pause.<br><br>
                  <b>The before-and-after comparison:</b> Showing a road segment before and after 
                  the AV readiness scoring overlay \u2014 from an unmarked map to a colour-coded 
                  green/amber/red risk assessment \u2014 is a visually compelling transformation.<br><br>
                  <b>The killer fact pause:</b> After stating the number of unassessed UK roads 
                  or the volume of uncommitted government investment, a full 3-second silence 
                  creates a genuine magic moment of realisation in the room.")
              ),

              column(6,
                shg("Q&A Preparation for Atera\u2019s Key Presentations"),
                app_card("Atera\u2019s 10 Most Anticipated Questions \u2014 With Bridged Answers",
                  "<b>Q: How is this different from existing road assessment tools?</b><br>
                  A: Existing tools require manual surveys. Ours operates in real time using live data. 
                  What that means in practice is assessment in minutes rather than weeks.<br><br>
                  <b>Q: Is the platform production-ready or still a prototype?</b><br>
                  A: The core platform is production-ready. We have completed 5 of 7 milestones 
                  and are in final validation. Commercial deployment is confirmed for Q2 2026.<br><br>
                  <b>Q: What happens when Innovate UK funding ends?</b><br>
                  A: We have four commercial revenue streams already identified \u2014 SaaS licensing, 
                  API access, consultancy and Data-as-a-Service. We\u2019re not dependent on grant funding 
                  for the commercial phase.<br><br>
                  <b>Q: Who owns the IP?</b><br>
                  A: We have an active IP protection roadmap with Marks & Clerk. 
                  Ownership is clearly defined across consortium partners."),

                app_card("Online Presenting \u2014 Atera\u2019s Video Communication Standards",
                  "With international partners, Horizon Europe collaborators and remote Innovate UK 
                  reviews, a significant proportion of Atera\u2019s presentations now take place online. 
                  Recommended standards for all Atera video presentations:<br><br>
                  <b>Camera:</b> Eye level or slightly above. Look at the lens, not the screen, 
                  when making key points. This creates the equivalent of eye contact.<br><br>
                  <b>Lighting:</b> Natural light or a ring light from the front. 
                  Never a window behind you \u2014 it creates a silhouette and undermines presence.<br><br>
                  <b>Background:</b> Clean, uncluttered, professional. The Atera logo or a neutral 
                  background with good depth is preferable to a bedroom or kitchen.<br><br>
                  <b>Energy:</b> Increase your natural energy level by approximately 20% on video. 
                  What feels slightly too enthusiastic on camera reads as engaged and confident."),

                app_card("Body Language for Atera\u2019s Presenting Team",
                  "Atera presents to sophisticated audiences \u2014 government funders, council officers, 
                  investors \u2014 who will form judgements of the organisation partly from the 
                  non-verbal signals of its representatives. Pre-presentation preparation checklist:<br><br>
                  Stand (do not sit) for all key pitches and demonstrations where possible.<br>
                  Make individual eye contact with each decision-maker in the room before starting.<br>
                  Remove verbal redundancies (\u2018basically\u2019, \u2018sort of\u2019, \u2018you know\u2019) \u2014 
                  record and review one practice run before each major presentation.<br>
                  Finish every response in a Q&A with a direct, declarative sentence. 
                  Never trail off or end with a question mark in your voice."),

                div(class = "success-box",
                    tags$strong("\u2705 Chapter 7 Action Points for Atera: "),
                    tags$ol(
                      tags$li("Script an opening agenda signpost for every presentation type"),
                      tags$li("Design the live dashboard demo as the centrepiece magic moment"),
                      tags$li("Prepare answers to the 10 most likely Q&A questions with bridging phrases"),
                      tags$li("Establish video presentation standards for all team members"),
                      tags$li("Record one practice run of the next major pitch and review for redundancies"),
                      tags$li("Finish every presentation under time \u2014 plan for 80% of the allocated slot")
                    ))
              )
            )
          ) # end Atera tab
        ) # end tabsetPanel
      ) # end box
    ) # end fluidRow
  )
}

ch7_powerful_speaking_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {
  })
}
