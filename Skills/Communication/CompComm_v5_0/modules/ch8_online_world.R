# modules/ch8_online_world.R

ch8_online_world_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero("8", "The Online World",
      "Your digital presence is now your first impression \u2014 seen before you enter a room, before a meeting is arranged, before a contract is signed.",
      c("Golden Rule", "Your Bio", "Platform Strategy", "Photography", "AI & Trolls", "Think Before You Post")),

    fluidRow(
      column(2, stat_card("24/7",   "Your Profile Works Constantly")),
      column(2, stat_card("Give",   "Value Before You Ask")),
      column(2, stat_card("Bio",    "Most-Read Document You Write")),
      column(2, stat_card("Visual", "Images Outperform Text 3\u00d7")),
      column(2, stat_card("AI",     "Use It Wisely")),
      column(2, stat_card("Think",  "Before Every Post"))
    ),

    fluidRow(
      tabBox(id = ns("tabs"), width = 12,
        tabPanel("\U0001f4da General Concepts", br(),
          fluidRow(
            column(6,
              sh("The Golden Rule"),
              framework_card("Give Value Before You Ask for Anything",
                "The most important principle of professional online communication is generosity. The communicators who build the largest, most commercially valuable audiences online are those who consistently give \u2014 insight, knowledge, perspective \u2014 without immediately asking for something in return. Trust is built through consistent, valuable giving. The ask follows trust, never precedes it."),
              framework_card("Interactive Posting \u2014 Conversations Not Broadcasts",
                "Online communication is a dialogue, not a monologue. Posting content and never responding to comments signals that you are using your audience as a billboard rather than a community. Responding to every comment signals respect, builds loyalty, and dramatically increases algorithmic reach."),
              sh("Your Bio"),
              framework_card("The Most-Read Document You Will Ever Write",
                "Your professional bio is read by more people more often than almost any other piece of writing you produce. A powerful bio: opens with a hook (not your job title), communicates your value in the first two lines, uses first person, includes one surprising or humanising detail, and ends with a clear statement of what you are looking for or offering."),
              framework_card("Three Bio Lengths \u2014 Always Have All Three Ready",
                "<b>One line:</b> Your role + your distinctive value in 15 words or fewer.<br>
                 <b>Three lines:</b> Hook + what you do + one credential or proof point.<br>
                 <b>One paragraph:</b> Full story arc: the problem you solve, how you solve it, what makes you credible, and what you are seeking."),
              sh("Picking Your Platforms"),
              framework_card("Not Every Platform Deserves Your Time",
                "The most effective professional communicators choose one or two platforms where their target audience is most concentrated and invest their energy there. For most B2B professionals, LinkedIn is the non-negotiable primary platform. Secondary choices should be made based on audience location, not personal preference.")
            ),
            column(6,
              sh("Social Media Strategy"),
              framework_card("A Strategy Has Four Components",
                "<b>1. Purpose:</b> Why are you posting? Brand awareness, lead generation, thought leadership?<br>
                 <b>2. Audience:</b> Who exactly are you trying to reach?<br>
                 <b>3. Content mix:</b> What proportion of posts will be insights, case studies, personal stories, industry commentary?<br>
                 <b>4. Cadence:</b> Consistency beats frequency. Posting three times a week reliably outperforms daily posting followed by a month of silence."),
              sh("Photography & Videography"),
              framework_card("Error Number One \u2014 Bad Profile Photography",
                "Profile photographs influence first impressions, credibility assessments and click-through rates more than any other single element of an online profile. A professional headshot \u2014 well-lit, high-resolution, neutral background, natural expression \u2014 is one of the highest-ROI investments any professional can make."),
              framework_card("Video Is the Dominant Online Content Format",
                "Video consistently achieves higher reach, engagement and retention than any other content format. Short-form video (under 90 seconds) performs best for awareness. The fundamentals: stable shot, good lighting, clear audio (a microphone is more important than a high-end camera), and content that delivers value within the first 5 seconds."),
              sh("AI and Trolls"),
              framework_card("Using AI in Content Creation \u2014 The Principles",
                "Use AI to draft and research; always edit to add your genuine voice, specific insight and original perspective before publishing. AI-generated content published without human editing is immediately recognisable and immediately trust-destroying."),
              framework_card("Think Before You Post! \u2014 The 24-Hour Rule",
                "Before posting anything that touches on politics, controversy, personal criticism or strong opinion \u2014 wait 24 hours. Ask: does this serve my audience, or does it serve my ego? The posts that feel most urgent to publish are almost always the ones that cause the most damage."),
              success_box(tags$strong("Chapter 8 Summary: "), "Give before you ask. Write your bio in three lengths. Choose platforms strategically. Invest in a professional photograph. Use AI as a tool, not a ghostwriter. Think before every post.")
            )
          )
        ),
        tabPanel("\U0001f3e2 Applicability on Atera Analytics", br(),
          fluidRow(
            column(6,
              shg("Atera\u2019s Online Golden Rule"),
              insight_box("What Atera Should Give Its Online Audience",
                "<b>Insights:</b> What has Atera learned about UK road infrastructure from its data that the wider industry does not yet know?<br><br>
                 <b>Analysis:</b> Commentary on UK government CAV policy, Innovate UK programme developments, or AV deployment news \u2014 from the perspective of an organisation with direct infrastructure data experience.<br><br>
                 <b>Behind-the-scenes:</b> The human dimension of building a deep-tech platform \u2014 technical challenges, unexpected discoveries, team expertise.<br><br>
                 <b>Practical tools:</b> Frameworks, checklists or short guides that help councils or AV operators think about infrastructure readiness, even before they use Atera\u2019s platform."),
              insight_box("Atera\u2019s LinkedIn Content Strategy",
                "<b>40% Insight posts:</b> Short analysis of CAV industry developments, infrastructure data findings, government investment trends.<br>
                 <b>25% Project stories:</b> Human-centred stories from the project \u2014 team achievements, milestone moments, partner highlights.<br>
                 <b>20% Platform demonstrations:</b> Short video or screenshot posts showing the dashboard in action.<br>
                 <b>15% Engagement posts:</b> Questions for the community, polls, responses to others\u2019 content.<br><br>
                 Cadence: 3 times per week, Tuesday to Thursday (highest LinkedIn professional engagement days)."),
              shg("Atera\u2019s Bio \u2014 Three Versions"),
              insight_box("Joseph Zubizarreta \u2014 Bio Templates",
                "<b>One line:</b><br>\u2018Building the UK\u2019s AI-powered infrastructure assessment layer for autonomous vehicles \u2014 Innovate UK funded, Cambridge ecosystem.\u2019<br><br>
                 <b>Three lines:</b><br>\u2018The UK is deploying autonomous vehicles onto roads it has never properly assessed. I lead Atera Analytics \u2014 the team building the AI platform that changes that. Government-validated, commercially deploying Q2 2026.\u2019<br><br>
                 <b>LinkedIn About:</b><br>Open with the problem. Describe the solution in plain language. Reference Innovate UK validation, Zenzic programme, Cambridge ecosystem. State what partnerships Atera is seeking. End with a direct call to connect.")
            ),
            column(6,
              shg("Atera\u2019s Visual Content Standards"),
              insight_box("Photography and Video for Atera\u2019s Online Presence",
                "<b>Profile photographs:</b> All team members representing Atera externally should have a consistent, professional headshot \u2014 similar background tone, similar lighting, similar framing.<br><br>
                 <b>Dashboard screenshots:</b> The EV Route Optimizer and Omniverse AR simulation platform screenshots are Atera\u2019s most powerful visual assets. Every online post about the platform should include one.<br><br>
                 <b>Short video:</b> A 60\u201390 second screen-recorded demo of the dashboard scoring a live route would be Atera\u2019s highest-performing LinkedIn post. It requires no budget \u2014 only a clean recording with clear audio narration."),
              shg("Think Before You Post \u2014 Atera\u2019s Standards"),
              insight_box("Content Standards for a Publicly-Funded Organisation",
                "As a company in receipt of public funding and engaged with government stakeholders, Atera must apply particularly careful judgement to online content:<br><br>
                 <b>Never post:</b> Criticism of competitors by name; commentary on Innovate UK programme decisions; unverified claims about platform capabilities; content that could breach the confidentiality of commercial conversations.<br><br>
                 <b>Always check:</b> Would this post be appropriate if a monitoring officer, council procurement team or potential investor read it?<br><br>
                 <b>Trolls and criticism:</b> If Atera receives hostile online responses, do not engage publicly. Respond privately if warranted; ignore if bad-faith."),
              success_box(tags$strong("Action Points: "),
                tags$ol(
                  tags$li("Write three versions of the company bio and Joseph\u2019s personal bio"),
                  tags$li("Build a 12-week LinkedIn content calendar with the recommended content mix"),
                  tags$li("Produce a 60\u201390 second dashboard demo video for LinkedIn"),
                  tags$li("Ensure all team profiles have consistent professional photography"),
                  tags$li("Establish a posting approval process for all external content")
                ))
            )
          )
        )
      )
    )
  )
}

ch8_online_world_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {})
}
