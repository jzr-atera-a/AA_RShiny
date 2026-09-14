# modules/ch8_online_world.R
# Chapter 8: The Online World

ch8_online_world_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "aa-hero",
        tags$h1("Chapter 8"),
        tags$h2("The Online World"),
        div(
          span(class = "hero-badge", icon("star"),        " The Golden Rule"),
          span(class = "hero-badge", icon("id-card"),     " Your Bio"),
          span(class = "hero-badge", icon("share-alt"),   " Platform Strategy"),
          span(class = "hero-badge", icon("hashtag"),     " Tags & Hashtags"),
          span(class = "hero-badge", icon("camera"),      " Photography & Video"),
          span(class = "hero-badge", icon("robot"),       " AI & Trolls"),
          span(class = "hero-badge", icon("pen-square"),  " Think Before You Post")
        )
    ),

    fluidRow(
      box(title = "Chapter 8 - Overview", status = "primary",
          solidHeader = TRUE, width = 12,
          p("The online world has fundamentally changed the rules of professional communication. ",
            "Your digital presence is now your first impression - seen before you enter a room, ",
            "before a meeting is arranged, before a contract is signed. ",
            "Chapter 8 covers everything from the golden rule of online communication to ",
            "photography, videography, AI, and the perennial danger of the ill-considered post."),
          fluidRow(
            column(2, metric_card("24/7",   "Your Online Profile Works Constantly")),
            column(2, metric_card("Give",   "Value Before You Ask")),
            column(2, metric_card("Bio",    "Your Most-Read Document")),
            column(2, metric_card("Visual", "Images Outperform Text 3\u00d7")),
            column(2, metric_card("AI",     "Use It Wisely")),
            column(2, metric_card("Think",  "Before Every Post"))
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
                sh("The Golden Rule"),
                concept_card("Give Value Before You Ask for Anything",
                  "The single most important principle of professional online communication is generosity. 
                  The communicators who build the largest, most engaged and most commercially valuable 
                  audiences online are those who consistently give - insight, knowledge, perspective, 
                  entertainment - without immediately asking for something in return. 
                  Trust is built through consistent, valuable giving. 
                  The ask - the sale, the partnership, the referral - follows trust, never precedes it."),

                sh("Interactive Posting"),
                concept_card("Conversations, Not Broadcasts",
                  "Online communication is a dialogue, not a monologue. 
                  Posting content and never responding to comments, questions or engagement 
                  signals that you are using your audience as a billboard rather than a community. 
                  Responding to every comment (especially early in building an audience) 
                  signals respect, builds loyalty, and dramatically increases algorithmic reach. 
                  The platforms reward engagement because engagement keeps people on the platform."),

                concept_card("Turning Comments Into Relationships",
                  "Do not stop at a one-word reply. Ask the commenter a genuine follow-up question, 
                  reference their point in a future post, or move a promising exchange into a direct 
                  message. The professionals who build real communities treat every comment as the 
                  start of a conversation, not a box to tick. Tagging a relevant person or organisation 
                  in a reply - when genuinely relevant - can also pull a whole new audience into the thread."),

                sh("Your Bio"),
                concept_card("The Most-Read Document You Will Ever Write",
                  "Your professional bio - on LinkedIn, on your website, in event programmes - 
                  is read by more people more often than almost any other piece of writing you produce. 
                  Yet most professionals treat it as an afterthought. A powerful bio: 
                  opens with a hook (not your job title), communicates your value in the first two lines, 
                  uses first person (I, not \u2018Joseph is...\u2019), includes one surprising or humanising detail, 
                  and ends with a clear statement of what you are looking for or offering."),

                concept_card("Three Bio Lengths - Always Have All Three Ready",
                  "<b>One line (for introductions and headers):</b> 
                  Your role + your distinctive value in 15 words or fewer.<br><br>
                  <b>Three lines (for event programmes and email signatures):</b> 
                  Hook + what you do + one credential or proof point.<br><br>
                  <b>One paragraph (for LinkedIn About and proposals):</b> 
                  Full story arc: the problem you solve, how you solve it, 
                  what makes you credible, and what you are seeking."),

                sh("Picking Your Platforms"),
                concept_card("Not Every Platform Deserves Your Time",
                  "Attempting to maintain an active presence on every social platform 
                  simultaneously is a route to mediocrity across all of them. 
                  The most effective professional communicators choose one or two platforms 
                  where their target audience is most concentrated, and invest their energy there. 
                  For most B2B professionals, LinkedIn is the non-negotiable primary platform. 
                  Secondary choices should be made based on audience location, not personal preference.")
              ),

              column(6,
                sh("Creating Your Social Media Strategy"),
                concept_card("A Strategy Has Four Components",
                  "<b>1. Purpose:</b> Why are you posting? Brand awareness, lead generation, 
                  thought leadership, recruitment, partnership development? 
                  Different purposes require different content types and different metrics.<br><br>
                  <b>2. Audience:</b> Who exactly are you trying to reach? 
                  The more precisely you define them, the more effective your content will be.<br><br>
                  <b>3. Content mix:</b> What proportion of posts will be insights, 
                  case studies, personal stories, industry commentary, questions? 
                  A sustainable content strategy has variety.<br><br>
                  <b>4. Cadence:</b> How often will you post, and when? 
                  Consistency beats frequency. Posting three times a week reliably 
                  outperforms posting daily for two weeks then going silent for a month."),

                sh("Tags, Hash Tags and Links"),
                concept_card("Tags and Mentions: Borrowing Someone Else\u2019s Audience",
                  "Tagging or @mentioning a relevant person, partner or organisation in a post pulls 
                  that account\u2019s network into your reach - but only when the mention is genuinely 
                  relevant to them. A tag that exists purely to farm attention (mentioning a big name 
                  with no real connection to the content) reads as spam and is often deleted or ignored. 
                  Used well, a tag is a form of credit: thank a partner, cite a source, or loop in a 
                  collaborator who will want to see - and likely share - the post."),

                concept_card("Hashtags: Fewer, Sharper, More Relevant",
                  "The era of stuffing a post with thirty generic hashtags is over on every major 
                  professional platform. Three to five hashtags, mixing one broad industry term with 
                  two or three specific, niche ones, consistently outperforms a long generic list. 
                  A hashtag should describe what the post is actually about - not what audience the 
                  poster wishes they had."),

                concept_card("Links: The Quiet Killer of Reach",
                  "Most professional platforms, including LinkedIn, algorithmically suppress the reach 
                  of posts that contain an outbound link, because the platform\u2019s goal is to keep 
                  readers on-platform. The practical workaround: post the core content and insight 
                  directly in the post itself, then add the link as the first comment rather than in 
                  the post body. This preserves reach while still giving interested readers a way through."),

                sh("Photography"),
                concept_card("Your Photograph Is Your Handshake",
                  "Before a single word of your bio is read, your profile photograph has already 
                  made a judgement on your behalf: competent or careless, current or outdated, 
                  approachable or closed-off. Photography deserves the same deliberate craft attention 
                  as your writing - it is not a box-ticking exercise but one of the highest-leverage 
                  elements of an online professional presence."),

                sh("Error Number One"),
                concept_card("Bad Profile Photography Is the Most Damaging Error Online",
                  "The single most common and most damaging error in online professional communication 
                  is a poor profile photograph. Studies consistently show that profile photographs 
                  influence first impressions, credibility assessments and click-through rates 
                  more than any other single element of an online profile. A blurry holiday crop, an 
                  outdated photo from a decade ago, or a group shot with the subject unclear all send 
                  the same signal: this profile was not taken seriously, so why should the content be?"),

                sh("Making the Picture Pretty"),
                concept_card("The Fundamentals That Separate Amateur From Professional",
                  "A professional headshot does not require a studio. It requires: sharp focus, even 
                  lighting with no harsh shadows, a simple and uncluttered background, and a natural, 
                  approachable expression rather than a forced smile or overly formal pose. A shallow 
                  depth of field - a slightly blurred background - instantly separates the subject and 
                  adds a professional quality even when shot on a smartphone."),

                sh("Focus and Exposure"),
                concept_card("Getting the Technical Basics Right",
                  "The subject must be in sharp focus - tap to focus on the eyes if shooting on a 
                  phone, since a soft-focus face undermines every other quality in the shot. Exposure 
                  should be even across the face: no blown-out highlights from a window behind the 
                  subject, and no dark shadows cast by overhead lighting. Shooting facing a window, 
                  rather than with the window behind you, solves most amateur exposure problems 
                  instantly and for free."),

                sh("Angles"),
                concept_card("A Few Degrees Make All the Difference",
                  "Shoot slightly above eye level for portraits - it is universally the most flattering 
                  angle and is standard practice for professional headshots. Never shoot upwards at a 
                  professional subject; it distorts proportions and reads as unintentionally unflattering. 
                  For event or behind-the-scenes photography, vary the angle deliberately to create 
                  visual interest across a set of images, rather than repeating the same straight-on shot."),

                sh("Videography"),
                concept_card("Video Is the Dominant Online Content Format",
                  "Video consistently achieves higher reach, engagement and retention 
                  than any other content format across all major professional platforms. 
                  Short-form video (under 90 seconds) performs best for awareness and reach. 
                  Longer-form video (3\u20135 minutes) works for thought leadership and demonstration. 
                  The fundamentals of good professional video: stable shot, good lighting, 
                  clear audio (a microphone is more important than a high-end camera), 
                  and content that delivers value within the first 5 seconds.")
              )
            ),

            hr(class = "divider"),
            fluidRow(
              column(6,
                sh("Blogs"),
                concept_card("Long-Form Content Builds Deep Authority",
                  "While short-form social posts build reach and visibility, 
                  long-form blog content (800\u20131,500 words) builds the deeper authority 
                  that converts awareness into trust. A well-written blog post that genuinely 
                  advances the thinking in your field - sharing original insight, analysis 
                  or perspective rather than summarising what others have said - 
                  positions the writer as a genuine expert and creates durable, searchable content 
                  that continues to work long after it is published."),

                sh("Artificial Intelligence"),
                concept_card("Using AI in Content Creation - The Principles",
                  "AI tools can accelerate content creation, assist with research 
                  and help overcome blank-page paralysis. But AI-generated content 
                  that is published without genuine human editing, perspective and voice 
                  is immediately recognisable and immediately trust-destroying. 
                  The audiences that professional communicators are trying to reach 
                  are sophisticated enough to detect generic, unedited AI output. 
                  The rule: use AI to draft and research; always edit to add your genuine voice, 
                  specific insight and original perspective before publishing.")
              ),

              column(6,
                sh("Trolls"),
                concept_card("How to Handle Online Hostility",
                  "Anyone with a meaningful online presence will eventually encounter hostile, 
                  bad-faith or abusive responses to their content. The evidence-based guidance 
                  is clear: do not engage with bad-faith actors. Responding to trolls 
                  rewards the behaviour, extends the reach of the hostile content 
                  and draws more attention to it. The correct response to a genuine troll 
                  is silence, blocking or - where appropriate - reporting. 
                  Reserve your energy for genuine critics who deserve a thoughtful response."),

                sh("Think Before You Post!"),
                concept_card("The 24-Hour Rule for Anything Sensitive",
                  "Before posting anything that touches on politics, controversy, personal criticism, 
                  competitor commentary or strong opinion - wait 24 hours. 
                  Read it again. Ask: does this serve my audience, or does it serve my ego? 
                  Does it advance my purpose, or does it risk relationships I have spent years building? 
                  The posts that feel most urgent to publish in the moment 
                  are almost always the ones that cause the most damage."),

                div(class = "success-box",
                    tags$strong("\u2705 Chapter 8 Summary: "),
                    "Give before you ask, and reply to every comment. Write your bio in three lengths. 
                    Choose one or two platforms and invest in them properly. Use a focused set of 
                    hashtags and put links in the comments, not the post. Invest in a professional 
                    photograph, get the focus, exposure and angle right, and use video where you can. 
                    Use AI as a tool, not a ghostwriter. And always think before you post.")
              )
            )
          ), # end General Concepts

          tabPanel("\U0001f3e2 Applicability on Atera Analytics",
            br(),
            fluidRow(
              column(6,
                shg("Atera\u2019s Online Golden Rule - Becoming a Generous Expert"),
                app_card("What Atera Should Give Its Online Audience",
                  "Atera\u2019s online communications currently focus primarily on project milestones 
                  and company achievements. Applying the Golden Rule means shifting the balance 
                  toward giving genuine value to the CAV and transport technology community:<br><br>
                  <b>Insights:</b> What has Atera learned about UK road infrastructure from its data 
                  that the wider industry does not yet know?<br><br>
                  <b>Analysis:</b> Commentary on UK government CAV policy, Innovate UK programme developments, 
                  or AV deployment news - from the perspective of an organisation with 
                  direct infrastructure data experience.<br><br>
                  <b>Behind-the-scenes:</b> The human dimension of building a deep-tech platform 
                  - the technical challenges, the unexpected discoveries, the team\u2019s expertise 
                  - builds trust and personality simultaneously.<br><br>
                  <b>Practical tools:</b> Frameworks, checklists or short guides that help councils 
                  or AV operators think about infrastructure readiness - even before they use Atera\u2019s platform."),

                app_card("Atera\u2019s LinkedIn Content Strategy",
                  "Recommended content mix for Atera\u2019s LinkedIn presence:<br><br>
                  <b>40% Insight posts:</b> Short analysis of CAV industry developments, 
                  infrastructure data findings, government investment trends.<br>
                  <b>25% Project stories:</b> Human-centred stories from the project 
                  - team achievements, milestone moments, partner collaboration highlights.<br>
                  <b>20% Platform demonstrations:</b> Short video or screenshot posts showing 
                  the dashboard in action, route assessments, digital twin visualisations.<br>
                  <b>15% Engagement posts:</b> Questions for the community, polls, 
                  responses to others\u2019 content in the CAV space.<br><br>
                  Posting cadence: 3 times per week, Tuesday to Thursday 
                  (highest professional engagement days on LinkedIn)."),

                shg("Interactive Posting - Atera\u2019s Engagement Standard"),
                app_card("Every Comment Gets a Real Reply Within 24 Hours",
                  "Council officers, Innovate UK contacts and prospective AV partners who comment on 
                  an Atera post should receive a substantive reply, not a thumbs-up emoji. A monitoring 
                  officer who asks a technical question in the comments and gets a genuine, thoughtful 
                  answer is far more likely to trust the milestone report that follows. Atera should 
                  treat every comment as a shortlist candidate for a follow-up conversation, not a 
                  metric to clear."),

                shg("Tags, Hashtags and Links for Atera"),
                app_card("Tagging Partners, Not Chasing Attention",
                  "Atera should tag Innovate UK, Zenzic, and named academic or council partners only 
                  when a post genuinely concerns joint work - a milestone achieved together, an event 
                  attended, a joint publication. This borrows credibility from the partner\u2019s network 
                  and signals a real working relationship, rather than reading as name-dropping."),
                app_card("A Focused Hashtag Set and Links in the Comments",
                  "Atera\u2019s LinkedIn posts should use a consistent core set of 3-5 hashtags - 
                  <code>#AutonomousVehicles</code>, <code>#SmartMobility</code>, <code>#CAV</code>, plus 
                  one specific to the post (<code>#InnovateUK</code>, <code>#UKRoads</code>) - rather than 
                  a long generic list. Any link to a report, case study or external article should go in 
                  the first comment, not the post body, to avoid the algorithmic reach penalty LinkedIn 
                  applies to outbound links."),

                shg("Atera\u2019s Bio - Three Versions"),
                app_card("Joseph Zubizarreta - Bio Template",
                  "<b>One line:</b><br>
                  \u2018Building the UK\u2019s AI-powered infrastructure assessment layer for autonomous vehicles - 
                  Innovate UK funded, Cambridge ecosystem.\u2019<br><br>
                  <b>Three lines:</b><br>
                  \u2018The UK is deploying autonomous vehicles onto roads it has never properly assessed. 
                  I lead Atera Analytics - the team building the AI platform that changes that. 
                  Government-validated, commercially deploying Q2 2026.\u2019<br><br>
                  <b>One paragraph (LinkedIn About):</b><br>
                  Open with the problem. Describe the solution in plain language. 
                  Reference Innovate UK validation, Zenzic programme, Cambridge ecosystem. 
                  State clearly what partnerships or conversations Atera is seeking. 
                  End with a direct call to connect.")
              ),

              column(6,
                shg("Atera\u2019s Visual Content Standards"),
                app_card("Error Number One - Atera\u2019s Team Profile Audit",
                  "A quick audit of the Atera team\u2019s LinkedIn profile photos is the single 
                  highest-ROI action in this section: any outdated, low-resolution, cropped-from-a-group-photo, 
                  or missing headshot should be replaced before the next round of investor or council 
                  outreach. A monitoring officer forming a first impression of the team will look at 
                  these photos before they read a single milestone report."),
                app_card("Making the Picture Pretty and Getting the Angle Right",
                  "All team members representing Atera externally should have a consistent, professional 
                  headshot - similar background tone, similar lighting, similar framing, shot slightly 
                  above eye level. Inconsistency across team profiles signals an organisation that has 
                  not yet considered its brand. A single afternoon with a decent smartphone camera, a 
                  window for natural light, and a plain wall is enough to bring every profile up to the 
                  same professional standard."),
                app_card("Dashboard Screenshots: Focus and Exposure Matter Here Too",
                  "The EV Route Optimizer and digital twin platform screenshots are Atera\u2019s most 
                  powerful visual assets - but only when captured in sharp focus at full resolution, 
                  never as a compressed screenshot of a screenshot. Every online post about the platform 
                  should include one, and the colour-coded route map is immediately distinctive and 
                  shareable when captured cleanly."),
                app_card("Short Video for Atera\u2019s Highest-Performing Post",
                  "A 60\u201390 second screen-recorded demo of the dashboard scoring a live route would 
                  be Atera\u2019s highest-performing LinkedIn post. It requires no budget - only a clean 
                  recording, stable framing, and clear audio narration."),

                app_card("AI in Atera\u2019s Content Creation",
                  "Atera legitimately uses AI tools (Vertex AI, GCP, generative AI pipelines) 
                  as core technical infrastructure. This creates an authentic opportunity 
                  to demonstrate AI expertise through content - not by hiding AI use 
                  but by being transparent and thoughtful about it.<br><br>
                  Recommended approach: use AI to draft initial content for LinkedIn posts 
                  and blog articles, then edit to add Atera\u2019s specific data, voice and perspective. 
                  Never publish unedited AI output. The editing step is where Atera\u2019s 
                  genuine expertise becomes visible and distinguishable from generic content."),

                app_card("Think Before You Post - Atera\u2019s Posting Standards",
                  "As a company in receipt of public funding and engaged with government stakeholders, 
                  Atera must apply particularly careful judgement to online content:<br><br>
                  <b>Never post:</b> Criticism of competitors by name; commentary on 
                  Innovate UK programme decisions; unverified claims about platform capabilities; 
                  content that could breach the confidentiality of commercial conversations.<br><br>
                  <b>Always check:</b> Would this post be appropriate if a monitoring officer, 
                  council procurement team or potential investor read it? 
                  If the answer is \u2018probably not\u2019, do not post it.<br><br>
                  <b>Trolls and criticism:</b> If Atera receives negative or hostile online responses, 
                  do not engage publicly. Respond privately if warranted; ignore if bad-faith."),

                div(class = "success-box",
                    tags$strong("\u2705 Chapter 8 Action Points for Atera: "),
                    tags$ol(
                      tags$li("Write three versions of the company bio and Joseph\u2019s personal bio"),
                      tags$li("Build a 12-week LinkedIn content calendar with the recommended content mix"),
                      tags$li("Produce a 60-90 second dashboard demo video for LinkedIn"),
                      tags$li("Ensure all team member profiles have consistent professional photography"),
                      tags$li("Establish a posting approval process for all external content")
                    ))
              )
            )
          ) # end Atera tab
        ) # end tabsetPanel
      ) # end box
    ) # end fluidRow
  )
}

ch8_online_world_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {
  })
}
