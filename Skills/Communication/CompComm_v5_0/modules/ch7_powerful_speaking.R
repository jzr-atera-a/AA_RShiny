# modules/ch7_powerful_speaking.R

ch7_powerful_speaking_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero("7", "Powerful Public Speaking and Presentations",
      "Interact deliberately. Signpost clearly. Create one magic moment. Let your body language signal confidence. The golden secret: prepare until you know it six different ways.",
      c("Interactions", "Signposting", "Magic Moments", "Body Language", "Q&A Mastery", "Online Presenting")),

    fluidRow(
      column(2, stat_card("Interact", "Engage Your Audience")),
      column(2, stat_card("Sign",     "Guide the Journey")),
      column(2, stat_card("\u2728",        "Create Magic Moments")),
      column(2, stat_card("Body",     "Non-Verbal Impact")),
      column(2, stat_card("Q&A",      "Prepare Every Answer")),
      column(2, stat_card("Online",   "New Rules Apply"))
    ),

    fluidRow(
      tabBox(id = ns("tabs"), width = 12,
        tabPanel("\U0001f4da General Concepts", br(),
          fluidRow(
            column(6,
              sh("Interactions"),
              framework_card("Presentations Are Conversations, Not Broadcasts",
                "The most powerful presentations are structured conversations. Interactions \u2014 questions to the audience, pauses for reflection, moments of genuine engagement \u2014 transform a passive audience into active participants. Active participants are more engaged, more persuaded and more likely to act."),
              framework_card("Types of Audience Interaction",
                "<b>Rhetorical questions:</b> \u2018How many of you have ever had to make a major decision without enough data?\u2019 No answer required \u2014 but the audience answers mentally.<br>
                 <b>Show of hands:</b> A physical interaction that creates commitment and engagement.<br>
                 <b>Pause for reflection:</b> \u2018Take a moment to consider what that means for your organisation.\u2019 Creates ownership of the idea in the audience\u2019s mind."),
              sh("Signposting"),
              framework_card("Tell Them Where You Are and Where You\u2019re Going",
                "Signposting is the practice of explicitly guiding the audience through the structure of the presentation: \u2018I\u2019m going to cover three things today\u2019; \u2018That brings me to my second point\u2019; \u2018Before I move on, let me summarise\u2019. Signposting reduces cognitive load \u2014 when the audience knows where they are, they can focus on understanding the content."),
              framework_card("Opening and Closing Signposts",
                "<b>Opening:</b> State your agenda, your duration and your purpose in the first 90 seconds. This gives the audience permission to relax and listen.<br><br>
                 <b>Closing:</b> Signal the end before it arrives: \u2018I want to leave you with one final thought\u2019 or \u2018In summary, there are three things I hope you\u2019ll take from today.\u2019"),
              sh("Magic Moments"),
              framework_card("Create at Least One Moment They Will Remember",
                "A magic moment is a planned peak of emotional or intellectual impact \u2014 a surprising demonstration, an unexpected visual, a counterintuitive statement, a moment of genuine humour, or an emotionally resonant story. Every presentation of any length should contain at least one magic moment, deliberately placed where the audience\u2019s attention is highest.")
            ),
            column(6,
              sh("Body Language"),
              framework_card("Your Body Communicates Before You Speak",
                "Audiences form their initial impression of a presenter within seconds, primarily from non-verbal signals: posture, eye contact, movement and facial expression. A presenter who stands straight, makes genuine eye contact, moves with purpose and uses natural hand gestures projects confidence and authority before saying a word."),
              framework_card("The Four Body Language Essentials",
                "<b>1. Posture:</b> Stand straight with feet shoulder-width apart. Stillness signals confidence.<br>
                 <b>2. Eye contact:</b> Hold eye contact with individual audience members for 3\u20135 seconds. This creates connection and reads as confidence.<br>
                 <b>3. Gesture:</b> Use open, natural hand gestures. Avoid pointing or crossing arms.<br>
                 <b>4. Movement:</b> Move with purpose \u2014 step forward to emphasise, step back to signal transition."),
              sh("Nerves & Verbal Redundancies"),
              framework_card("Managing Performance Anxiety",
                "Nerves are physiologically identical to excitement \u2014 the body\u2019s response (adrenaline, raised heart rate) is the same. Reframing nervousness as readiness is one of the most evidence-backed performance anxiety techniques available. Verbal redundancies \u2014 \u2018um\u2019, \u2018er\u2019, \u2018you know\u2019, \u2018basically\u2019 \u2014 undermine authority. A silent pause communicates thought and confidence."),
              sh("The Q&A Session"),
              framework_card("The Q&A Bridging Formula",
                "<b>Step 1 \u2014 Acknowledge:</b> \u2018That\u2019s an important question.\u2019 Never dismiss.<br>
                 <b>Step 2 \u2014 Answer briefly:</b> Address the question in one or two sentences.<br>
                 <b>Step 3 \u2014 Bridge:</b> \u2018What that really points to is...\u2019 \u2014 return to your Golden Thread."),
              sh("Online Presenting"),
              framework_card("The Online Environment Changes Everything",
                "Looking at the camera (not the screen) is the equivalent of eye contact in a live presentation and must be practised deliberately. Energy levels must also be higher online \u2014 the screen compresses and dampens personality, requiring approximately 20% more energy than feels comfortable."),
              pull_quote("The golden secret of success in presentations is preparation. Know the material well enough to deliver it six different ways.", "Simon Hall \u2014 Chapter 7"),
              success_box(tags$strong("Chapter 7 Summary: "), "Interact. Signpost. Create one magic moment. Project confident body language. Prepare every Q&A answer. On video: look at the camera.")
            )
          )
        ),
        tabPanel("\U0001f3e2 Applicability on Atera Analytics", br(),
          fluidRow(
            column(6,
              shg("Interactions \u2014 Making Atera Presentations Two-Way"),
              insight_box("Building Engagement Into Atera\u2019s Pitch Structure",
                "<b>For council presentations, open with a rhetorical question:</b><br>
                 \u2018How many of you have been asked whether your roads are ready for autonomous vehicles?\u2019 (Pause. Let the question land.)<br><br>
                 <b>For investor meetings, use a directed question early:</b><br>
                 \u2018What would you estimate it costs to manually assess 100km of road for AV readiness?\u2019 (Let them answer. Then reveal the actual figure and the Atera comparison.)<br><br>
                 <b>For Innovate UK reviews, use a pause for reflection after the demo:</b><br>
                 \u2018Take a moment to consider what this means for the 100+ councils we\u2019re targeting.\u2019"),
              shg("Magic Moments for Atera"),
              insight_box("Atera\u2019s Planned Magic Moments",
                "<b>The live dashboard demonstration:</b> Showing the EV Route Optimizer score a real Cambridge route in real time is Atera\u2019s most powerful magic moment. It should be the centrepiece of every stakeholder presentation, carefully set up with context, delivered slowly, and followed by a pause.<br><br>
                 <b>The before-and-after comparison:</b> Showing a road segment before and after the AV readiness scoring overlay \u2014 from an unmarked map to a colour-coded green/amber/red risk assessment.<br><br>
                 <b>The killer fact pause:</b> After stating the number of unassessed UK roads or uncommitted government investment, a full 3-second silence creates a genuine magic moment.")
            ),
            column(6,
              shg("Q&A Preparation for Atera\u2019s Key Presentations"),
              insight_box("Atera\u2019s 5 Most Anticipated Questions \u2014 With Bridged Answers",
                "<b>Q: How is this different from existing road assessment tools?</b><br>
                 A: Existing tools require manual surveys. Ours operates in real time. Assessment in minutes rather than weeks.<br><br>
                 <b>Q: Is the platform production-ready or still a prototype?</b><br>
                 A: 5 of 7 milestones complete. Dashboard operational. Commercial deployment confirmed Q2 2026.<br><br>
                 <b>Q: What happens when Innovate UK funding ends?</b><br>
                 A: Four commercial revenue streams already identified \u2014 SaaS licensing, API access, consultancy, Data-as-a-Service.<br><br>
                 <b>Q: Who owns the IP?</b><br>
                 A: Active IP protection roadmap with Marks & Clerk. Ownership clearly defined.<br><br>
                 <b>Q: Who are your competitors?</b><br>
                 A: Most focus on vehicles. We focus on infrastructure \u2014 the gap nobody else has addressed at national scale."),
              shg("Online Presenting Standards for Atera"),
              insight_box("Video Communication Standards for All Team Members",
                "<b>Camera:</b> Eye level or slightly above. Look at the lens when making key points.<br>
                 <b>Lighting:</b> Natural light or ring light from the front. Never a window behind you.<br>
                 <b>Background:</b> Clean, uncluttered, professional. Atera logo or neutral background preferred.<br>
                 <b>Energy:</b> Increase your natural energy level by approximately 20% on video. What feels slightly too enthusiastic on camera reads as engaged and confident."),
              success_box(tags$strong("Action Points: "),
                tags$ol(
                  tags$li("Script an opening agenda signpost for every presentation type"),
                  tags$li("Design the live dashboard demo as the centrepiece magic moment"),
                  tags$li("Prepare answers to the 10 most likely Q&A questions with bridging phrases"),
                  tags$li("Establish video presentation standards for all team members"),
                  tags$li("Record one practice run and review for verbal redundancies")
                ))
            )
          )
        )
      )
    )
  )
}

ch7_powerful_speaking_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {})
}
