library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(shinycssloaders)
library(shinyWidgets)
library(visNetwork)
library(dplyr)
library(ggplot2)
library(wordcloud2)
library(htmlwidgets)

# Define colour palette for consistent styling
primary_colour <- "#667eea"
secondary_colour <- "#764ba2"
accent_colour <- "#f39c12"
success_colour <- "#27AE60"
warning_colour <- "#F39C12"
info_colour <- "#4f46e5"

# Custom CSS styling - maintaining original configuration
custom_css <- "
  .skin-blue .main-header .navbar { 
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; 
    border: none !important; 
    box-shadow: 0 2px 10px rgba(0,0,0,0.1) !important;
  }
  .skin-blue .main-header .logo { 
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
    color: white !important; 
    font-weight: 700 !important; 
    font-size: 18px !important;
    border-right: none !important;
  }
  .skin-blue .main-header .logo:hover {
    background: linear-gradient(135deg, #764ba2 0%, #667eea 100%) !important;
  }
  .skin-blue .main-sidebar { 
    background: linear-gradient(180deg, #2c3e50 0%, #34495e 100%) !important; 
  }
  .skin-blue .sidebar-menu > li > a { 
    color: #ecf0f1 !important; 
    border-left: 3px solid transparent !important; 
    transition: all 0.3s ease !important;
    font-weight: 500 !important;
  }
  .skin-blue .sidebar-menu > li.active > a,
  .skin-blue .sidebar-menu > li.menu-open > a { 
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; 
    border-left: 3px solid #f39c12 !important; 
    color: white !important; 
    box-shadow: inset 0 0 10px rgba(0,0,0,0.2) !important;
  }
  .skin-blue .sidebar-menu > li > a:hover { 
    background-colour: #3e5771 !important; 
    color: white !important; 
  }
  .content-wrapper,
  .right-side { 
    background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%) !important; 
  }
  .box { 
    border: none !important; 
    border-radius: 12px !important; 
    box-shadow: 0 4px 20px rgba(0,0,0,0.08) !important;
    background: white !important;
    margin-bottom: 20px !important;
  }
  .box-header { 
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; 
    color: white !important;
    border-radius: 12px 12px 0 0 !important; 
    font-weight: 600 !important;
    border-bottom: none !important;
  }
  .box.box-solid.box-primary > .box-header,
  .box.box-solid.box-info > .box-header,
  .box.box-solid.box-success > .box-header,
  .box.box-solid.box-warning > .box-header {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
    color: white !important;
  }
  .references {
    background: linear-gradient(135deg, #f8f9ff 0%, #ffffff 100%) !important;
    border: 1px solid #e3e8ff !important;
    border-left: 5px solid #4f46e5 !important;
    padding: 20px !important;
    margin-top: 25px !important;
    border-radius: 12px !important;
    box-shadow: 0 2px 10px rgba(79, 70, 229, 0.1) !important;
  }
  .references h5 {
    color: #4f46e5 !important;
    font-weight: 600 !important;
    margin-bottom: 15px !important;
    border-bottom: 2px solid #4f46e5 !important;
    padding-bottom: 5px !important;
  }
  .reference-item {
    margin-bottom: 12px !important;
    line-height: 1.5 !important;
    padding-left: 10px !important;
    border-left: 3px solid #e3e8ff !important;
  }
  .small-box { 
    border-radius: 12px !important; 
    box-shadow: 0 4px 15px rgba(0,0,0,0.1) !important;
  }
  .bg-blue,
  .bg-green,
  .bg-yellow,
  .bg-red {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
  }
  .small-box .icon { 
    opacity: 0.8 !important; 
  }
  .academic-content {
    background: white;
    padding: 20px;
    border-radius: 8px;
    line-height: 1.6;
    font-size: 14px;
    color: #2c3e50;
    margin-bottom: 15px;
  }
  .academic-content h5 {
    color: #4f46e5;
    font-weight: 600;
    margin-bottom: 10px;
  }
  .concept-highlight {
    background: linear-gradient(135deg, #f8f9ff 0%, #ffffff 100%);
    border-left: 4px solid #667eea;
    padding: 15px;
    margin: 10px 0;
    border-radius: 5px;
  }
  .btn-primary { 
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; 
    border: none !important; 
    border-radius: 8px !important;
    font-weight: 600 !important;
  }
  .btn-success {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; 
    border: none !important; 
    border-radius: 8px !important;
    font-weight: 600 !important;
  }
  .form-control {
    border-radius: 8px !important;
    border: 1px solid #e3e8ff !important;
  }
  h4 { 
    color: #2c3e50 !important; 
    font-weight: 600 !important; 
  }
  .dataTables_wrapper {
    overflow: visible !important;
  }
  .box-body {
    overflow: visible !important;
  }
  .progress-chart {
    height: 300px;
    display: flex;
    align-items: center;
    justify-content: center;
    background: #f8f9fa;
    border-radius: 8px;
    border: 1px solid #e9ecef;
  }
"

# UI
ui <- dashboardPage(
  dashboardHeader(title = "Strategic Networking & Influence Mastery"),
  dashboardSidebar(
    tags$head(tags$style(HTML(custom_css))),
    sidebarMenu(
      menuItem("Finding Relevant People", tabName = "finding", icon = icon("users")),
      menuItem("Reading Personalities", tabName = "personalities", icon = icon("brain")),
      menuItem("Memorable Introductions", tabName = "introductions", icon = icon("handshake")),
      menuItem("Appearing Resourceful", tabName = "resourceful", icon = icon("lightbulb")),
      menuItem("Connecting Through Value", tabName = "value", icon = icon("link")),
      menuItem("Inspiring Collaboration", tabName = "inspire", icon = icon("rocket")),
      menuItem("Creating Desire", tabName = "desire", icon = icon("magnet")),
      menuItem("Advanced Strategies", tabName = "advanced", icon = icon("chess"))
    )
  ),
  dashboardBody(
    tabItems(
      # Tab 1: Finding Relevant People
      tabItem(tabName = "finding",
              fluidRow(
                valueBoxOutput("network_size"),
                valueBoxOutput("industry_reach"),
                valueBoxOutput("influence_score")
              ),
              fluidRow(
                box(
                  title = "Strategic People Identification", status = "primary", solidHeader = TRUE,
                  width = 6, height = "auto",
                  div(class = "academic-content",
                      h5("Research-Based Approach to Finding Key Connections"),
                      p("Effective networking begins with strategic identification of relevant individuals who can provide mutual value. Research demonstrates that successful professionals focus on quality over quantity in their professional relationships."),
                      div(class = "concept-highlight",
                          HTML("<strong>Industry Mapping:</strong> Use LinkedIn Sales Navigator, industry databases, and professional associations to identify key players in your field. Look for patterns in career progression and influence indicators.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Thought Leadership Analysis:</strong> Identify individuals who consistently publish insightful content, speak at conferences, or are frequently quoted in industry publications.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Network Effect Leverage:</strong> Focus on connectors - people who sit at the intersection of multiple networks and can provide access to diverse opportunities.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Geographic and Virtual Presence:</strong> Modern networking transcends location. Identify relevant people globally through digital platforms and virtual events."))
                  )
                ),
                box(
                  title = "Digital Research Strategies", status = "info", solidHeader = TRUE,
                  width = 6, height = "auto",
                  div(class = "academic-content",
                      h5("Systematic Online Intelligence Gathering"),
                      div(class = "concept-highlight",
                          HTML("<strong>LinkedIn Advanced Search:</strong> Use boolean search operators, industry filters, and connection degree analysis to identify high-value prospects.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Twitter Lists and Engagement:</strong> Create lists of industry leaders and monitor their content engagement patterns to understand their interests and values.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Conference Speaker Analysis:</strong> Research speakers at major industry events - they often represent the most influential voices in their fields.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Publication and Citation Tracking:</strong> Use Google Scholar, ResearchGate, or industry publications to identify thought leaders through their published work.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Company Leadership Mapping:</strong> Research executive teams at target organizations using company websites, SEC filings, and business databases."))
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Network Visualization Tool", status = "success", solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("network_map")
                ),
                box(
                  title = "Influence Metrics Dashboard", status = "warning", solidHeader = TRUE,
                  width = 6,
                  div(class = "academic-content",
                      h5("Quantitative Assessment Framework"),
                      div(class = "concept-highlight",
                          HTML("<strong>Follower Quality Score:</strong> Analyze the influence level of someone's followers rather than just quantity")),
                      div(class = "concept-highlight",
                          HTML("<strong>Engagement Rate Analysis:</strong> Monitor likes, comments, and shares to gauge authentic influence versus vanity metrics")),
                      div(class = "concept-highlight",
                          HTML("<strong>Content Reach Measurement:</strong> Track how often their content is referenced, quoted, or reshared across platforms")),
                      div(class = "concept-highlight",
                          HTML("<strong>Professional Achievement Index:</strong> Awards, board positions, speaking engagements, and media mentions create a composite influence score"))
                  )
                )
              ),
              # References for Tab 1
              div(class = "references",
                  h5("Academic References"),
                  div(class = "reference-item",
                      "Granovetter, M. S. (1973). The strength of weak ties. American Journal of Sociology, 78(6), 1360-1380."),
                  div(class = "reference-item",
                      "Burt, R. S. (2005). Brokerage and closure: An introduction to social capital. Oxford University Press."),
                  div(class = "reference-item",
                      "Cross, R., & Thomas, R. J. (2009). Driving results through social networks: How top organizations leverage networks for performance and growth. Jossey-Bass."),
                  div(class = "reference-item",
                      "Uzzi, B., & Dunlap, S. (2005). How to build your network. Harvard Business Review, 83(12), 53-60."),
                  div(class = "reference-item",
                      "Ibarra, H., & Hunter, M. (2007). How leaders create and use networks. Harvard Business Review, 85(1), 40-47.")
              )
      ),
      
      # Tab 2: Reading Personalities
      tabItem(tabName = "personalities",
              fluidRow(
                box(
                  title = "Personality Assessment Framework", status = "primary", solidHeader = TRUE,
                  width = 12, height = "auto",
                  div(class = "academic-content",
                      h5("Evidence-Based Personality Recognition Systems"),
                      p("Understanding personality types enables more effective communication and relationship building. Research in social psychology provides robust frameworks for reading and adapting to different personality styles."),
                      fluidRow(
                        column(4,
                               h5("The Big Five Model (OCEAN)", style = "color: #4f46e5;"),
                               div(class = "concept-highlight",
                                   HTML("• <strong>Openness:</strong> Innovation vs. tradition preference<br>
                                   • <strong>Conscientiousness:</strong> Organization vs. flexibility<br>
                                   • <strong>Extraversion:</strong> Social energy and assertiveness<br>
                                   • <strong>Agreeableness:</strong> Cooperation vs. competition<br>
                                   • <strong>Neuroticism:</strong> Emotional stability patterns"))
                        ),
                        column(4,
                               h5("Erikson's Surrounded by Idiots", style = "color: #4f46e5;"),
                               div(class = "concept-highlight",
                                   HTML("• <strong>Red (Dominant):</strong> Direct, results-focused, impatient<br>
                                   • <strong>Yellow (Influencing):</strong> Enthusiastic, social, optimistic<br>
                                   • <strong>Green (Steady):</strong> Patient, reliable, team-oriented<br>
                                   • <strong>Blue (Compliant):</strong> Analytical, precise, quality-focused"))
                        ),
                        column(4,
                               h5("Robert Greene's Types", style = "color: #4f46e5;"),
                               div(class = "concept-highlight",
                                   HTML("• <strong>The Aggressor:</strong> Confrontational, power-seeking<br>
                                   • <strong>The Insecure Master:</strong> Competent but defensive<br>
                                   • <strong>The Drama Magnet:</strong> Emotionally volatile<br>
                                   • <strong>The Rigid Mind:</strong> Inflexible, rule-bound<br>
                                   • <strong>The Passive-Aggressive:</strong> Indirect resistance"))
                        )
                      )
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Behavioral Observation Techniques", status = "info", solidHeader = TRUE,
                  width = 6,
                  div(class = "academic-content",
                      h5("Micro-Expression and Body Language Analysis"),
                      div(class = "concept-highlight",
                          HTML("<strong>Facial Coding:</strong> Paul Ekman's research on micro-expressions reveals seven universal emotions that leak through facial expressions within 1/25th of a second.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Posture Patterns:</strong> Open vs. closed body language, personal space preferences, and gesture patterns indicate comfort levels and personality traits.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Voice Tonality:</strong> Pace, volume, pitch variations, and linguistic patterns provide insights into thinking styles and emotional states.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Eye Movement Patterns:</strong> NLP eye accessing cues and attention patterns can indicate cognitive processing preferences and truthfulness."))
                  )
                ),
                box(
                  title = "Communication Style Adaptation", status = "warning", solidHeader = TRUE,
                  width = 6,
                  div(class = "academic-content",
                      h5("Personality-Matched Communication Strategies"),
                      div(class = "concept-highlight",
                          HTML("<strong>For Analytical Types (Blue):</strong> Provide detailed data, logical arguments, and allow processing time. Avoid emotional appeals and high-pressure tactics.")),
                      div(class = "concept-highlight",
                          HTML("<strong>For Dominant Types (Red):</strong> Be direct and concise, focus on results and benefits, respect their time constraints and decision-making authority.")),
                      div(class = "concept-highlight",
                          HTML("<strong>For Expressive Types (Yellow):</strong> Use storytelling, emotional connections, and social proof. Allow for brainstorming and creative discussion.")),
                      div(class = "concept-highlight",
                          HTML("<strong>For Steady Types (Green):</strong> Build trust gradually, emphasize stability and team benefits, avoid sudden changes or aggressive tactics."))
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Advanced Personality Profiling", status = "success", solidHeader = TRUE,
                  width = 12,
                  tabsetPanel(
                    tabPanel("Myers-Briggs Integration",
                             div(class = "academic-content",
                                 h5("16 Personality Types in Professional Context"),
                                 p("While controversial in academic circles, MBTI provides practical frameworks for understanding cognitive preferences:"),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Thinking vs. Feeling:</strong> Decision-making based on logic versus values and impact on people")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Sensing vs. Intuition:</strong> Focus on concrete details versus patterns and possibilities")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Judging vs. Perceiving:</strong> Preference for structure versus flexibility and adaptability")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Introversion vs. Extraversion:</strong> Energy source and processing style preferences"))
                             )
                    ),
                    tabPanel("Dark Triad Recognition",
                             div(class = "academic-content",
                                 h5("Identifying Potentially Problematic Personalities"),
                                 p("Research by Paulhus and Williams identifies three problematic personality clusters:"),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Narcissism:</strong> Grandiose self-view, need for admiration, lack of empathy. Look for excessive self-promotion and entitlement behaviors.")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Machiavellianism:</strong> Manipulative, strategic, emotionally detached. Watch for inconsistent stories and exploitation of others.")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Psychopathy:</strong> Lack of empathy, impulsivity, antisocial behavior. Notice charm combined with disregard for social norms."))
                             )
                    )
                  )
                )
              ),
              # References for Tab 2
              div(class = "references",
                  h5("Academic References"),
                  div(class = "reference-item",
                      "Costa, P. T., & McCrae, R. R. (1992). Revised NEO Personality Inventory (NEO-PI-R) and NEO Five-Factor Inventory (NEO-FFI) professional manual. Psychological Assessment Resources."),
                  div(class = "reference-item",
                      "Ekman, P. (2003). Emotions revealed: Recognizing faces and feelings to improve communication and emotional life. Times Books."),
                  div(class = "reference-item",
                      "Erikson, T. (2019). Surrounded by idiots: The four types of human behaviour and how to effectively communicate with each in business (and in life). Vermilion."),
                  div(class = "reference-item",
                      "Greene, R. (2018). The laws of human nature. Viking."),
                  div(class = "reference-item",
                      "Paulhus, D. L., & Williams, K. M. (2002). The dark triad of personality: Narcissism, Machiavellianism, and psychopathy. Journal of Research in Personality, 36(6), 556-563.")
              )
      ),
      
      # Tab 3: Memorable Introductions
      tabItem(tabName = "introductions",
              fluidRow(
                box(
                  title = "The Science of First Impressions", status = "primary", solidHeader = TRUE,
                  width = 6, height = "auto",
                  div(class = "academic-content",
                      h5("Psychological Foundations of Memorable Introductions"),
                      p("Research demonstrates that first impressions form within 7 seconds and significantly influence all subsequent interactions. Understanding the psychological mechanisms behind impression formation enables strategic self-presentation."),
                      div(class = "concept-highlight",
                          HTML("<strong>Primacy Effect:</strong> Initial information carries disproportionate weight in forming judgments. Craft your opening words carefully to establish the desired frame.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Halo Effect:</strong> Positive traits in one area create positive assumptions about other areas. Lead with your strongest, most relevant competency.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Reciprocity Principle:</strong> People feel obligated to return favors. Offer value immediately to trigger reciprocal engagement.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Social Proof Integration:</strong> Reference mutual connections or shared experiences to establish credibility and common ground quickly."))
                  )
                ),
                box(
                  title = "Advanced Introduction Frameworks", status = "info", solidHeader = TRUE,
                  width = 6, height = "auto",
                  div(class = "academic-content",
                      h5("Structured Approaches to Professional Introductions"),
                      div(class = "concept-highlight",
                          HTML("<strong>The SOAR Method:</strong><br>
                          • <em>Situation:</em> Brief context for the meeting<br>
                          • <em>Objective:</em> What you hope to achieve<br>
                          • <em>Advantage:</em> Unique value you bring<br>
                          • <em>Request:</em> Specific next step or engagement")),
                      div(class = "concept-highlight",
                          HTML("<strong>The Story Hook:</strong> Open with a compelling anecdote that illustrates your expertise while creating emotional engagement and memorability.")),
                      div(class = "concept-highlight",
                          HTML("<strong>The Insight Offer:</strong> Begin with a valuable industry insight or trend observation that demonstrates thought leadership and provides immediate value."))
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Contextual Introduction Strategies", status = "success", solidHeader = TRUE,
                  width = 12,
                  tabsetPanel(
                    tabPanel("Networking Events",
                             div(class = "academic-content",
                                 h5("Optimizing Introductions for Group Settings"),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Conference Positioning:</strong> Position yourself near registration, coffee stations, or session exits where natural conversation opportunities arise.")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>The Connector Introduction:</strong> 'I'm Sarah, and I help connect innovative startups with enterprise clients. I noticed you mentioned X in your presentation - I actually work with several companies facing that exact challenge.'")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Value-First Approach:</strong> Lead with how you can help others rather than what you need. This creates positive association and encourages reciprocal interest.")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Follow-Up Framework:</strong> End conversations with specific next steps: 'I'll send you that article we discussed by Thursday' creates accountability and reason for continued contact."))
                             )
                    ),
                    tabPanel("Digital Introductions",
                             div(class = "academic-content",
                                 h5("Virtual Networking and Online Relationship Building"),
                                 div(class = "concept-highlight",
                                     HTML("<strong>LinkedIn Outreach Formula:</strong> Personalized connection requests that reference specific content they've shared or mutual connections, followed by value-adding messages.")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Email Introduction Structure:</strong> Subject line with clear value proposition, brief personal background, specific reason for reaching out, and concrete next step proposal.")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Social Media Engagement:</strong> Thoughtful comments on posts that add insights rather than generic praise, establishing thought leadership before direct contact."))
                             )
                    ),
                    tabPanel("Cold Outreach Mastery",
                             div(class = "academic-content",
                                 h5("Strategic Approaches to Unsolicited Contact"),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Research-Based Personalization:</strong> Reference specific achievements, recent news, or published content to demonstrate genuine interest and preparation.")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Mutual Benefit Proposition:</strong> Clearly articulate how the interaction benefits both parties, moving beyond one-sided requests for time or advice.")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Timing and Frequency:</strong> Optimal outreach timing based on industry schedules, with strategic follow-up sequences that add value with each touchpoint."))
                             )
                    )
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Non-Verbal Communication Mastery", status = "warning", solidHeader = TRUE,
                  width = 6,
                  div(class = "academic-content",
                      h5("Body Language and Presence Optimization"),
                      div(class = "concept-highlight",
                          HTML("<strong>Power Posing Research:</strong> Amy Cuddy's research on high-power poses shows 2-minute positioning can increase confidence hormones by 20% and decrease stress hormones by 25%.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Eye Contact Patterns:</strong> Maintain 60-70% eye contact during conversations, looking away occasionally to avoid appearing aggressive while demonstrating confidence.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Handshake Science:</strong> Firm grip, 2-3 pumps, slight forward lean, and matching the other person's pressure creates optimal first physical impression.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Voice Tonality Control:</strong> Lower pitch conveys authority, moderate pace suggests thoughtfulness, and slight volume variations maintain engagement."))
                  )
                ),
                box(
                  title = "Introduction Success Metrics", status = "primary", solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("introduction_effectiveness")
                )
              ),
              # References for Tab 3
              div(class = "references",
                  h5("Academic References"),
                  div(class = "reference-item",
                      "Cuddy, A. (2015). Presence: Bringing your boldest self to your biggest challenges. Little, Brown and Company."),
                  div(class = "reference-item",
                      "Todorov, A., Mandisodza, A. N., Goren, A., & Hall, C. C. (2005). Inferences of competence from faces predict election outcomes. Science, 308(5728), 1623-1626."),
                  div(class = "reference-item",
                      "Willis, J., & Todorov, A. (2006). First impressions: Making up your mind after a 100-ms exposure to a face. Psychological Science, 17(7), 592-598."),
                  div(class = "reference-item",
                      "Hall, J. A., Carter, S., Cody, M. J., & Albright, J. M. (2010). Individual differences in the communication of romantic interest: Development of the flirting styles inventory. Communication Quarterly, 58(4), 365-393."),
                  div(class = "reference-item",
                      "Mehrabian, A. (1971). Silent messages: Implicit communication of emotions and attitudes. Wadsworth.")
              )
      ),
      
      # Tab 4: Appearing Resourceful
      tabItem(tabName = "resourceful",
              fluidRow(
                box(
                  title = "Strategic Resource Positioning", status = "primary", solidHeader = TRUE,
                  width = 6, height = "auto",
                  div(class = "academic-content",
                      h5("Building Perception of Capability and Access"),
                      p("Appearing resourceful without seeming needy requires careful balance between demonstrating capability and maintaining authentic humility. Research in social psychology shows that perceived resourcefulness significantly impacts professional relationships and opportunities."),
                      div(class = "concept-highlight",
                          HTML("<strong>Competency Signaling:</strong> Subtly demonstrate knowledge through informed questions rather than direct statements. 'Have you considered the implications of the new EU regulations on your compliance strategy?' shows awareness without lecturing.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Network Visibility:</strong> Casually reference connections and experiences that indicate access to valuable resources. 'When I was discussing this with the McKinsey team last week...' suggests high-level access.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Solution Orientation:</strong> Consistently offer potential solutions or resources rather than just identifying problems. This positions you as someone who adds value to every interaction.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Information Currency:</strong> Share relevant insights, trends, or opportunities that others might not have access to, establishing yourself as a valuable information node."))
                  )
                ),
                box(
                  title = "The Abundance Mindset Framework", status = "info", solidHeader = TRUE,
                  width = 6, height = "auto",
                  div(class = "academic-content",
                      h5("Psychological Foundations of Resourcefulness"),
                      div(class = "concept-highlight",
                          HTML("<strong>Scarcity vs. Abundance Thinking:</strong> Stephen Covey's research shows that abundant thinkers are perceived as more resourceful because they approach challenges with possibility rather than limitation.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Growth Mindset Application:</strong> Carol Dweck's growth mindset research applies to resourcefulness - viewing challenges as opportunities to learn and expand capabilities rather than threats.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Cognitive Flexibility:</strong> Demonstrate ability to think creatively about problems and see multiple solution pathways. This signals mental agility and resourcefulness.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Proactive Problem-Solving:</strong> Anticipate challenges and present solutions before problems become critical, positioning yourself as strategic rather than reactive."))
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Avoiding Neediness Indicators", status = "warning", solidHeader = TRUE,
                  width = 6,
                  div(class = "academic-content",
                      h5("Behavioral Patterns that Signal Desperation"),
                      div(class = "concept-highlight",
                          HTML("<strong>Over-Eagerness Warning Signs:</strong><br>
                          • Responding too quickly to requests<br>
                          • Agreeing to everything without consideration<br>
                          • Constant availability without boundaries<br>
                          • Excessive gratitude for minor favors<br>
                          • One-sided conversation dominance")),
                      div(class = "concept-highlight",
                          HTML("<strong>Healthy Boundary Setting:</strong> Demonstrate that your time and expertise have value by being selective about commitments and maintaining professional standards.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Reciprocity Balance:</strong> Ensure exchanges are mutual rather than always giving or always receiving. Imbalanced relationships signal either neediness or exploitation."))
                  )
                ),
                box(
                  title = "Resource Building Strategies", status = "success", solidHeader = TRUE,
                  width = 6,
                  div(class = "academic-content",
                      h5("Systematic Capability Development"),
                      div(class = "concept-highlight",
                          HTML("<strong>Knowledge Stacking:</strong> Continuously build expertise in adjacent fields to increase your problem-solving versatility and cross-functional value.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Network Diversification:</strong> Cultivate relationships across industries, functions, and hierarchical levels to access varied perspectives and resources.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Platform Building:</strong> Develop thought leadership through content creation, speaking, or community building to establish yourself as a go-to resource.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Strategic Learning:</strong> Stay ahead of industry trends and emerging technologies to provide forward-looking insights and solutions."))
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Resourcefulness Indicators Dashboard", status = "primary", solidHeader = TRUE,
                  width = 12,
                  tabsetPanel(
                    tabPanel("Capability Signals",
                             div(class = "academic-content",
                                 h5("Demonstrating Competence Without Arrogance"),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Question Quality:</strong> Ask sophisticated questions that reveal deep understanding. 'How are you handling the integration challenges between your legacy systems and the new API architecture?' shows technical knowledge.")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Contextual References:</strong> Make relevant connections between seemingly unrelated topics. 'This reminds me of a similar challenge in the pharmaceutical industry where they solved it through...' demonstrates broad knowledge.")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Resource Offers:</strong> Provide specific, actionable resources. 'I can introduce you to the CTO at TechCorp who implemented something similar' is more valuable than vague promises to help.")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Future-Focused Insights:</strong> Share forward-looking perspectives that help others prepare for upcoming challenges or opportunities."))
                             )
                    ),
                    tabPanel("Access Indicators",
                             div(class = "academic-content",
                                 h5("Subtle Demonstrations of Network and Resource Access"),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Casual Name-Dropping:</strong> Reference interactions with notable figures in context rather than for bragging. 'The conversation with [Industry Leader] confirmed that trend is accelerating.'")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Exclusive Information:</strong> Share insights from private events, closed meetings, or advance knowledge that indicates insider access.")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Resource Deployment:</strong> Demonstrate ability to mobilize resources quickly and effectively when situations demand action.")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Cross-Industry Connections:</strong> Show ability to draw insights and resources from multiple sectors and domains."))
                             )
                    )
                  )
                )
              ),
              # References for Tab 4
              div(class = "references",
                  h5("Academic References"),
                  div(class = "reference-item",
                      "Covey, S. R. (1989). The 7 habits of highly effective people: Powerful lessons in personal change. Free Press."),
                  div(class = "reference-item",
                      "Dweck, C. S. (2006). Mindset: The new psychology of success. Random House."),
                  div(class = "reference-item",
                      "Cialdini, R. B. (2006). Influence: The psychology of persuasion. Harper Business."),
                  div(class = "reference-item",
                      "Goleman, D. (1995). Emotional intelligence: Why it matters more than IQ. Bantam Books."),
                  div(class = "reference-item",
                      "Carnegie, D. (1936). How to win friends and influence people. Simon & Schuster.")
              )
      ),
      
      # Tab 5: Connecting Through Value
      tabItem(tabName = "value",
              fluidRow(
                box(
                  title = "Value-Based Connection Strategy", status = "primary", solidHeader = TRUE,
                  width = 12, height = "auto",
                  div(class = "academic-content",
                      h5("Creating Meaningful Professional Relationships Through Mutual Benefit"),
                      p("Research in social exchange theory demonstrates that sustainable relationships are built on perceived mutual benefit and value creation. The key is to leverage your unique experience and skills while avoiding patterns that trigger defensiveness or inferiority."),
                      fluidRow(
                        column(4,
                               h5("Value Identification Framework", style = "color: #4f46e5;"),
                               div(class = "concept-highlight",
                                   HTML("• <strong>Skills Inventory:</strong> Catalog your technical and soft skills<br>
                                   • <strong>Experience Mapping:</strong> Identify unique experiences and lessons<br>
                                   • <strong>Network Assets:</strong> Assess your relationship capital<br>
                                   • <strong>Knowledge Areas:</strong> Map your expertise domains<br>
                                   • <strong>Access Points:</strong> Identify resources you can provide"))
                        ),
                        column(4,
                               h5("Value Delivery Mechanisms", style = "color: #4f46e5;"),
                               div(class = "concept-highlight",
                                   HTML("• <strong>Introduction Facilitation:</strong> Connect others strategically<br>
                                   • <strong>Knowledge Sharing:</strong> Provide insights and best practices<br>
                                   • <strong>Resource Access:</strong> Share tools, contacts, and opportunities<br>
                                   • <strong>Problem Solving:</strong> Apply expertise to their challenges<br>
                                   • <strong>Perspective Offering:</strong> Provide external viewpoints"))
                        ),
                        column(4,
                               h5("Relationship Balance", style = "color: #4f46e5;"),
                               div(class = "concept-highlight",
                                   HTML("• <strong>Reciprocity Awareness:</strong> Monitor give-and-take dynamics<br>
                                   • <strong>Ego Protection:</strong> Preserve others' self-esteem<br>
                                   • <strong>Collaborative Framing:</strong> Position as partnership<br>
                                   • <strong>Credit Attribution:</strong> Acknowledge others' contributions<br>
                                   • <strong>Humble Expertise:</strong> Share knowledge without condescension"))
                        )
                      )
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Advanced Value Creation Techniques", status = "info", solidHeader = TRUE,
                  width = 6,
                  div(class = "academic-content",
                      h5("Sophisticated Approaches to Professional Value Delivery"),
                      div(class = "concept-highlight",
                          HTML("<strong>The Insight Synthesis Method:</strong> Combine information from multiple sources to create unique perspectives. 'Based on trends I'm seeing across automotive and tech sectors, there might be an opportunity to...' demonstrates cross-industry thinking.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Strategic Introduction Protocol:</strong> Connect people with specific, articulated value propositions. 'I think you and Sarah should meet - she's solved the exact scaling challenge you mentioned in the fintech space.'")),
                      div(class = "concept-highlight",
                          HTML("<strong>Anticipatory Problem Solving:</strong> Identify challenges before they become critical and offer preemptive solutions based on your experience with similar situations.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Resource Aggregation:</strong> Combine multiple resources, tools, or connections to create comprehensive solutions rather than piecemeal assistance."))
                  )
                ),
                box(
                  title = "Avoiding Ego Threats", status = "warning", solidHeader = TRUE,
                  width = 6,
                  div(class = "academic-content",
                      h5("Psychological Safety in Knowledge Sharing"),
                      div(class = "concept-highlight",
                          HTML("<strong>Collaborative Language:</strong> Use 'we' instead of 'you' when discussing challenges. 'How might we approach this differently?' vs. 'You should try this approach.'")),
                      div(class = "concept-highlight",
                          HTML("<strong>Question-Based Guidance:</strong> Lead with questions that help others reach insights rather than direct advice. This preserves their sense of discovery and ownership.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Context Attribution:</strong> Frame your knowledge as situational rather than superior. 'In the specific context I worked in, what seemed to help was...' acknowledges different circumstances.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Mutual Learning Framing:</strong> Position interactions as bidirectional learning opportunities. 'I'm curious about your perspective on X because my experience with Y might be limiting my view.'"))
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Value Exchange Analytics", status = "success", solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("value_exchange_metrics")
                ),
                box(
                  title = "Relationship Capital Building", status = "primary", solidHeader = TRUE,
                  width = 6,
                  div(class = "academic-content",
                      h5("Strategic Relationship Investment"),
                      div(class = "concept-highlight",
                          HTML("<strong>Long-term Value Perspective:</strong> Invest in relationships before you need them. Provide value consistently over time rather than transactionally.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Compound Value Creation:</strong> Small, consistent value additions compound over time. Regular sharing of relevant articles, insights, or connections builds strong relationship foundations.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Network Effect Amplification:</strong> Help others succeed in ways that reflect positively on your judgment and ability to identify talent and opportunities.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Reputation Reinforcement:</strong> Consistent value delivery creates reputation for reliability and expertise, leading to referral opportunities and expanded network access."))
                  )
                )
              ),
              # References for Tab 5
              div(class = "references",
                  h5("Academic References"),
                  div(class = "reference-item",
                      "Homans, G. C. (1958). Social behavior as exchange. American Journal of Sociology, 63(6), 597-606."),
                  div(class = "reference-item",
                      "Blau, P. M. (1964). Exchange and power in social life. John Wiley & Sons."),
                  div(class = "reference-item",
                      "Lin, N. (2001). Social capital: A theory of social structure and action. Cambridge University Press."),
                  div(class = "reference-item",
                      "Baker, W. (2000). Achieving success through social capital: Tapping the hidden resources in your personal and business networks. Jossey-Bass."),
                  div(class = "reference-item",
                      "Putnam, R. D. (2000). Bowling alone: The collapse and revival of American community. Simon & Schuster.")
              )
      ),
      
      # Tab 6: Inspiring Collaboration
      tabItem(tabName = "inspire",
              fluidRow(
                box(
                  title = "The Psychology of Inspiration", status = "primary", solidHeader = TRUE,
                  width = 6, height = "auto",
                  div(class = "academic-content",
                      h5("Research-Based Approaches to Motivating Collaboration"),
                      p("Psychological research identifies specific mechanisms that inspire people to engage in collaborative endeavors. Understanding these principles enables strategic influence without manipulation."),
                      div(class = "concept-highlight",
                          HTML("<strong>Autonomy Preservation:</strong> Self-Determination Theory shows people are most motivated when they feel autonomous. Frame opportunities as choices rather than directives.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Mastery Orientation:</strong> People are inspired by opportunities to develop competence. Position collaborations as learning and growth opportunities.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Purpose Connection:</strong> Viktor Frankl's research demonstrates that meaning drives motivation more than reward. Connect initiatives to larger purposes and values.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Social Identity Activation:</strong> Henri Tajfel's social identity theory shows people are motivated by group membership. Create shared identity around the collaboration.")),
                  )
                ),
                box(
                  title = "Vision Creation and Communication", status = "info", solidHeader = TRUE,
                  width = 6, height = "auto",
                  div(class = "academic-content",
                      h5("Crafting Compelling Collaborative Visions"),
                      div(class = "concept-highlight",
                          HTML("<strong>Future-Back Thinking:</strong> Start with the desired future state and work backward to present actions. This creates clarity about the journey and destination.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Benefit Stacking:</strong> Articulate multiple levels of benefit - personal, professional, organizational, and societal - to appeal to different motivational drivers.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Narrative Structure:</strong> Use storytelling frameworks that include challenge, journey, and transformation to create emotional engagement with the vision.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Concrete Visualization:</strong> Provide specific, tangible details about what success looks like to make the vision feel achievable and real."))
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Motivation Framework Analysis", status = "success", solidHeader = TRUE,
                  width = 12,
                  tabsetPanel(
                    tabPanel("Intrinsic Motivation Drivers",
                             div(class = "academic-content",
                                 h5("Tapping Into Internal Motivation Sources"),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Competence Building:</strong> Frame collaborations as opportunities to develop new skills, gain experience, or demonstrate expertise in novel contexts.")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Autonomy Enhancement:</strong> Offer meaningful choices in how people contribute, allowing them to leverage their strengths and interests.")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Relatedness Satisfaction:</strong> Create opportunities for meaningful connection with others who share similar values or goals.")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Growth Mindset Activation:</strong> Position challenges as learning opportunities rather than performance tests, reducing fear of failure."))
                             )
                    ),
                    tabPanel("Social Influence Principles",
                             div(class = "academic-content",
                                 h5("Leveraging Social Psychology for Collaboration"),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Social Proof Integration:</strong> Reference others who have engaged in similar initiatives, particularly those the target person respects or identifies with.")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Commitment and Consistency:</strong> Help people articulate their own reasons for participating, increasing psychological commitment to follow through.")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Reciprocity Activation:</strong> Provide value first, creating psychological pressure to reciprocate with engagement or contribution.")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Authority Positioning:</strong> Establish credibility through expertise, experience, or endorsements from respected figures."))
                             )
                    ),
                    tabPanel("Overcoming Resistance",
                             div(class = "academic-content",
                                 h5("Strategic Approaches to Addressing Objections"),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Preemptive Objection Handling:</strong> Acknowledge likely concerns before they're raised, demonstrating understanding and preparation.")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Risk Mitigation Strategies:</strong> Address fears about time commitment, reputation risk, or opportunity cost with specific safeguards.")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Pilot Program Approach:</strong> Offer low-commitment entry points that allow people to test engagement before full commitment.")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Exit Strategy Clarity:</strong> Provide clear pathways for disengagement if circumstances change, reducing perceived commitment pressure."))
                             )
                    )
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Collaboration Success Metrics", status = "warning", solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("collaboration_effectiveness")
                ),
                box(
                  title = "Engagement Sustainability", status = "primary", solidHeader = TRUE,
                  width = 6,
                  div(class = "academic-content",
                      h5("Maintaining Long-term Collaborative Momentum"),
                      div(class = "concept-highlight",
                          HTML("<strong>Progress Celebration:</strong> Regularly acknowledge and celebrate incremental progress to maintain motivation and momentum.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Role Evolution:</strong> Allow people's roles and contributions to evolve as their interests and capabilities develop within the collaboration.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Communication Cadence:</strong> Establish regular communication rhythms that keep people informed and engaged without overwhelming them.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Value Reinforcement:</strong> Continuously reinforce the personal and collective value being created through the collaborative effort."))
                  )
                )
              ),
              # References for Tab 6
              div(class = "references",
                  h5("Academic References"),
                  div(class = "reference-item",
                      "Deci, E. L., & Ryan, R. M. (2000). The 'what' and 'why' of goal pursuits: Human needs and the self-determination of behavior. Psychological Inquiry, 11(4), 227-268."),
                  div(class = "reference-item",
                      "Pink, D. H. (2009). Drive: The surprising truth about what motivates us. Riverhead Books."),
                  div(class = "reference-item",
                      "Frankl, V. E. (1946). Man's search for meaning. Beacon Press."),
                  div(class = "reference-item",
                      "Tajfel, H., & Turner, J. C. (1979). An integrative theory of intergroup conflict. In W. G. Austin & S. Worchel (Eds.), The social psychology of intergroup relations (pp. 33-47). Brooks/Cole."),
                  div(class = "reference-item",
                      "Kouzes, J. M., & Posner, B. Z. (2016). Learning leadership: The five fundamentals of becoming an exemplary leader. Wiley.")
              )
      ),
      
      # Tab 7: Creating Desire
      tabItem(tabName = "desire",
              fluidRow(
                box(
                  title = "The Psychology of Desire and Scarcity", status = "primary", solidHeader = TRUE,
                  width = 6, height = "auto",
                  div(class = "academic-content",
                      h5("Evidence-Based Approaches to Creating Professional Magnetism"),
                      p("Research in behavioral psychology reveals specific principles that make people more desirable as professional connections and collaborators. These principles must be applied ethically and authentically."),
                      div(class = "concept-highlight",
                          HTML("<strong>Scarcity Principle:</strong> Robert Cialdini's research shows that perceived scarcity increases value. Manage your availability strategically without being artificially elusive.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Social Proof Amplification:</strong> Others' desire for your time and expertise increases your perceived value. Display social proof subtly through selective sharing of opportunities and engagements.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Uncertainty Reduction:</strong> People desire what helps them feel more secure. Position yourself as someone who provides clarity and reduces uncertainty in complex situations.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Status Enhancement:</strong> People are attracted to those who can elevate their own status. Demonstrate how association with you benefits others' professional standing."))
                  )
                ),
                box(
                  title = "Value Perception Management", status = "info", solidHeader = TRUE,
                  width = 6, height = "auto",
                  div(class = "academic-content",
                      h5("Strategic Positioning for Increased Desirability"),
                      div(class = "concept-highlight",
                          HTML("<strong>Selective Accessibility:</strong> Be strategically available. Respond promptly to high-value requests while maintaining boundaries around your time for lower-priority interactions.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Competency Demonstration:</strong> Regularly showcase expertise through thoughtful insights, successful outcomes, and sophisticated problem-solving approaches.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Network Quality Signaling:</strong> Casually reference interactions with high-caliber individuals, demonstrating that accomplished people seek your input and company.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Future Value Indication:</strong> Hint at upcoming opportunities, projects, or developments that position you as someone worth staying connected to."))
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Advanced Influence Strategies", status = "success", solidHeader = TRUE,
                  width = 12,
                  tabsetPanel(
                    tabPanel("Curiosity Creation",
                             div(class = "academic-content",
                                 h5("Generating Intellectual and Professional Intrigue"),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Information Gaps:</strong> Share compelling beginnings or insights that create curiosity about the full story or complete analysis.")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Contrarian Perspectives:</strong> Offer well-reasoned viewpoints that challenge conventional wisdom, positioning yourself as an independent thinker.")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Future-Focused Insights:</strong> Share predictions or trend analyses that demonstrate forward-thinking and industry foresight.")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Cross-Industry Connections:</strong> Draw unexpected parallels between different fields, showcasing unique perspective and broad knowledge base."))
                             )
                    ),
                    tabPanel("Exclusivity Dynamics",
                             div(class = "academic-content",
                                 h5("Creating Sense of Special Access and Privilege"),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Inner Circle Positioning:</strong> Share insights or information that positions people as part of an exclusive group with special access to your thinking.")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Selective Invitations:</strong> Extend invitations to exclusive events, private discussions, or special opportunities to create sense of privilege.")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Early Access:</strong> Provide advance notice of opportunities, insights, or developments before they become widely available.")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Personalized Attention:</strong> Offer customized insights or recommendations that demonstrate special consideration for their specific situation."))
                             )
                    ),
                    tabPanel("Reciprocity Amplification",
                             div(class = "academic-content",
                                 h5("Creating Positive Obligation Cycles"),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Unexpected Value Delivery:</strong> Provide value that exceeds expectations and comes without explicit request, creating surprise and gratitude.")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Compound Reciprocity:</strong> Build series of positive interactions that create mounting sense of obligation and appreciation.")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Indirect Benefit Creation:</strong> Provide value that benefits them indirectly through third parties, demonstrating your network influence.")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Recognition and Credit:</strong> Publicly acknowledge their contributions or insights, enhancing their reputation and status."))
                             )
                    )
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Desirability Metrics Dashboard", status = "warning", solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("desirability_metrics")
                ),
                box(
                  title = "Relationship Magnetism Indicators", status = "primary", solidHeader = TRUE,
                  width = 6,
                  div(class = "academic-content",
                      h5("Measurable Signs of Professional Attractiveness"),
                      div(class = "concept-highlight",
                          HTML("<strong>Inbound Request Volume:</strong> Frequency of people reaching out for advice, collaboration, or connection")),
                      div(class = "concept-highlight",
                          HTML("<strong>Response Rate Quality:</strong> Speed and enthusiasm of responses to your outreach attempts")),
                      div(class = "concept-highlight",
                          HTML("<strong>Referral Frequency:</strong> How often others recommend you or refer opportunities your way")),
                      div(class = "concept-highlight",
                          HTML("<strong>Network Growth Rate:</strong> Speed at which high-quality connections are added to your professional network")),
                      div(class = "concept-highlight",
                          HTML("<strong>Opportunity Access:</strong> Frequency of exclusive or early-stage opportunities presented to you"))
                  )
                )
              ),
              # References for Tab 7
              div(class = "references",
                  h5("Academic References"),
                  div(class = "reference-item",
                      "Cialdini, R. B. (2006). Influence: The psychology of persuasion. Harper Business."),
                  div(class = "reference-item",
                      "Loewenstein, G. (1994). The psychology of curiosity: A review and reinterpretation. Psychological Bulletin, 116(1), 75-98."),
                  div(class = "reference-item",
                      "Festinger, L. (1957). A theory of cognitive dissonance. Stanford University Press."),
                  div(class = "reference-item",
                      "Kahneman, D., & Tversky, A. (1984). Choices, values, and frames. American Psychologist, 39(4), 341-350."),
                  div(class = "reference-item",
                      "Heath, C., & Heath, D. (2007). Made to stick: Why some ideas survive and others die. Random House.")
              )
      ),
      
      # Tab 8: Advanced Strategies
      tabItem(tabName = "advanced",
              fluidRow(
                box(
                  title = "Meta-Networking Strategies", status = "primary", solidHeader = TRUE,
                  width = 12, height = "auto",
                  div(class = "academic-content",
                      h5("Advanced Frameworks for Strategic Relationship Building"),
                      p("Beyond basic networking principles lie sophisticated strategies that leverage systems thinking, behavioral economics, and social network theory to create exponential relationship value."),
                      fluidRow(
                        column(4,
                               h5("Network Effect Optimization", style = "color: #4f46e5;"),
                               div(class = "concept-highlight",
                                   HTML("• <strong>Structural Holes Theory:</strong> Position yourself as bridge between disconnected networks<br>
                                   • <strong>Weak Tie Leverage:</strong> Cultivate relationships with distant connections for novel information<br>
                                   • <strong>Clustered Growth:</strong> Build dense connections within specific domains<br>
                                   • <strong>Cross-Pollination:</strong> Facilitate connections between disparate networks"))
                        ),
                        column(4,
                               h5("Behavioral Economics Application", style = "color: #4f46e5;"),
                               div(class = "concept-highlight",
                                   HTML("• <strong>Loss Aversion:</strong> Frame value propositions around preventing losses<br>
                                   • <strong>Anchoring Effects:</strong> Set high initial reference points for value<br>
                                   • <strong>Social Proof Cascades:</strong> Create momentum through visible adoption<br>
                                   • <strong>Mental Accounting:</strong> Separate relationship investments mentally"))
                        ),
                        column(4,
                               h5("Systems Thinking Integration", style = "color: #4f46e5;"),
                               div(class = "concept-highlight",
                                   HTML("• <strong>Feedback Loop Creation:</strong> Design relationships that strengthen over time<br>
                                   • <strong>Leverage Point Identification:</strong> Find high-impact relationship investments<br>
                                   • <strong>Emergence Facilitation:</strong> Allow organic network growth<br>
                                   • <strong>Dynamic Rebalancing:</strong> Continuously optimize network composition"))
                        )
                      )
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Emotional Intelligence Mastery", status = "info", solidHeader = TRUE,
                  width = 6,
                  div(class = "academic-content",
                      h5("Advanced Emotional and Social Intelligence Applications"),
                      div(class = "concept-highlight",
                          HTML("<strong>Micro-Expression Reading:</strong> Paul Ekman's FACS system for detecting concealed emotions and true feelings during interactions.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Emotional Contagion Management:</strong> Strategic use of emotional states to influence group dynamics and individual responses.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Empathic Accuracy:</strong> Daniel Goleman's research on accurately perceiving others' emotions and responding appropriately.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Emotional Labor Optimization:</strong> Arlie Hochschild's framework for managing emotional energy in professional relationships.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Social Baseline Theory:</strong> Using others' emotional regulation systems to enhance your own emotional stability and effectiveness."))
                  )
                ),
                box(
                  title = "Strategic Communication Frameworks", status = "warning", solidHeader = TRUE,
                  width = 6,
                  div(class = "academic-content",
                      h5("Advanced Persuasion and Influence Techniques"),
                      div(class = "concept-highlight",
                          HTML("<strong>Neuro-Linguistic Programming:</strong> Language patterns that access unconscious processing and create deeper rapport.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Cognitive Dissonance Utilization:</strong> Creating productive tension that motivates attitude and behavior change.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Framing Effect Mastery:</strong> Strategic presentation of information to influence perception and decision-making.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Priming Techniques:</strong> Subtle environmental and conversational cues that prepare minds for desired responses.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Dialectical Thinking:</strong> Holding contradictory ideas simultaneously to find creative solutions and build bridges."))
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Advanced Networking Analytics", status = "success", solidHeader = TRUE,
                  width = 12,
                  tabsetPanel(
                    tabPanel("Network Analysis Metrics",
                             div(class = "academic-content",
                                 h5("Quantitative Assessment of Relationship Networks"),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Betweenness Centrality:</strong> Measure your position as bridge between different network clusters, indicating brokerage power.")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Closeness Centrality:</strong> Assessment of how quickly you can reach any other person in your network through connections.")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Eigenvector Centrality:</strong> Evaluation of your connections' influence levels - being connected to influential people increases your score.")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Clustering Coefficient:</strong> Measurement of how interconnected your contacts are with each other, indicating network density."))
                             )
                    ),
                    tabPanel("Relationship Quality Assessment",
                             div(class = "academic-content",
                                 h5("Evaluating Connection Strength and Value"),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Tie Strength Analysis:</strong> Frequency, duration, and intimacy of interactions combined with reciprocal services exchanged.")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Value Exchange Ratios:</strong> Quantitative and qualitative assessment of mutual benefit in relationships over time.")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Relationship ROI:</strong> Return on investment calculation for time and energy invested in specific relationships.")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Influence Propagation:</strong> How effectively information, opportunities, and influence flow through your network connections."))
                             )
                    ),
                    tabPanel("Strategic Network Design",
                             div(class = "academic-content",
                                 h5("Intentional Network Architecture and Growth"),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Diversity Metrics:</strong> Industry, functional, geographic, and demographic diversity indexes for optimal network composition.")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Gap Analysis:</strong> Identification of missing connections that would significantly enhance network value and reach.")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Redundancy Optimization:</strong> Balancing network efficiency with resilience through strategic relationship redundancy.")),
                                 div(class = "concept-highlight",
                                     HTML("<strong>Growth Strategy Modeling:</strong> Predictive analysis of network expansion scenarios and their expected value outcomes."))
                             )
                    )
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Integration Dashboard", status = "primary", solidHeader = TRUE,
                  width = 6,
                  plotlyOutput("advanced_metrics")
                ),
                box(
                  title = "Continuous Improvement Framework", status = "info", solidHeader = TRUE,
                  width = 6,
                  div(class = "academic-content",
                      h5("Systematic Development of Networking Capabilities"),
                      div(class = "concept-highlight",
                          HTML("<strong>Skill Assessment Matrix:</strong> Regular evaluation of networking competencies across all domains with targeted improvement plans.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Feedback Loop Integration:</strong> Systematic collection and analysis of relationship feedback to identify improvement opportunities.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Experimental Methodology:</strong> A/B testing different approaches to relationship building and measuring outcomes systematically.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Learning Integration:</strong> Continuous incorporation of new research, techniques, and insights from psychology, neuroscience, and behavioral economics.")),
                      div(class = "concept-highlight",
                          HTML("<strong>Mastery Progression:</strong> Structured development pathway from basic networking skills to advanced strategic relationship architecture."))
                  )
                )
              ),
              # References for Tab 8
              div(class = "references",
                  h5("Academic References"),
                  div(class = "reference-item",
                      "Burt, R. S. (2005). Brokerage and closure: An introduction to social capital. Oxford University Press."),
                  div(class = "reference-item",
                      "Granovetter, M. S. (1973). The strength of weak ties. American Journal of Sociology, 78(6), 1360-1380."),
                  div(class = "reference-item",
                      "Ekman, P. (2003). Emotions revealed: Recognizing faces and feelings to improve communication and emotional life. Times Books."),
                  div(class = "reference-item",
                      "Hochschild, A. R. (1983). The managed heart: Commercialization of human feeling. University of California Press."),
                  div(class = "reference-item",
                      "Wasserman, S., & Faust, K. (1994). Social network analysis: Methods and applications. Cambridge University Press."),
                  div(class = "reference-item",
                      "Bandler, R., & Grinder, J. (1975). The structure of magic I: A book about language and therapy. Science & Behavior Books.")
              )
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  
  # Value boxes for Tab 1
  output$network_size <- renderValueBox({
    valueBox(
      value = "2,847",
      subtitle = "Professional Connections",
      icon = icon("users"),
      color = "blue"
    )
  })
  
  output$industry_reach <- renderValueBox({
    valueBox(
      value = "23",
      subtitle = "Industry Sectors",
      icon = icon("industry"),
      color = "green"
    )
  })
  
  output$influence_score <- renderValueBox({
    valueBox(
      value = "8.7/10",
      subtitle = "Network Influence Rating",
      icon = icon("chart-line"),
      color = "yellow"
    )
  })
  
  # Network visualization for Tab 1
  output$network_map <- renderPlotly({
    # Sample network data
    network_data <- data.frame(
      x = c(1, 2, 3, 4, 5, 6, 7, 8),
      y = c(2, 4, 1, 5, 3, 6, 2, 4),
      size = c(20, 15, 25, 18, 22, 16, 19, 21),
      category = c("Tech Leaders", "Finance Executives", "Startup Founders", 
                   "Academic Researchers", "Government Officials", "Media Contacts",
                   "Consultants", "Industry Experts"),
      connections = c(156, 89, 203, 67, 134, 78, 145, 167)
    )
    
    p <- plot_ly(network_data, x = ~x, y = ~y, size = ~size, color = ~category,
                 type = 'scatter', mode = 'markers',
                 text = ~paste("Category:", category, "<br>Connections:", connections),
                 hovertemplate = "%{text}<extra></extra>") %>%
      layout(title = "Professional Network Mapping",
             xaxis = list(showgrid = FALSE, showticklabels = FALSE, title = ""),
             yaxis = list(showgrid = FALSE, showticklabels = FALSE, title = ""),
             showlegend = TRUE)
    p
  })
  
  # Introduction effectiveness chart for Tab 3
  output$introduction_effectiveness <- renderPlotly({
    effectiveness_data <- data.frame(
      Method = c("Standard Introduction", "SOAR Framework", "Story Hook", 
                 "Insight Offer", "Connector Approach"),
      Success_Rate = c(42, 73, 68, 81, 76),
      Follow_Up_Rate = c(28, 65, 59, 74, 68)
    )
    
    p <- plot_ly(effectiveness_data, x = ~Method, y = ~Success_Rate, 
                 type = 'bar', name = 'Initial Success Rate',
                 marker = list(color = primary_colour)) %>%
      add_trace(y = ~Follow_Up_Rate, name = 'Follow-up Engagement',
                marker = list(color = secondary_colour)) %>%
      layout(title = "Introduction Method Effectiveness",
             xaxis = list(title = "Introduction Method"),
             yaxis = list(title = "Success Rate (%)"),
             barmode = 'group')
    p
  })
  
  # Value exchange metrics for Tab 5
  output$value_exchange_metrics <- renderPlotly({
    value_data <- data.frame(
      Quarter = c("Q1", "Q2", "Q3", "Q4"),
      Value_Given = c(85, 92, 88, 94),
      Value_Received = c(78, 89, 91, 96),
      Relationship_Strength = c(7.2, 7.8, 8.1, 8.5)
    )
    
    p <- plot_ly(value_data, x = ~Quarter) %>%
      add_trace(y = ~Value_Given, type = 'scatter', mode = 'lines+markers',
                name = 'Value Given', line = list(color = primary_colour)) %>%
      add_trace(y = ~Value_Received, type = 'scatter', mode = 'lines+markers',
                name = 'Value Received', line = list(color = secondary_colour)) %>%
      add_trace(y = ~Relationship_Strength * 10, type = 'scatter', mode = 'lines+markers',
                name = 'Relationship Strength (x10)', line = list(color = accent_colour),
                yaxis = 'y2') %>%
      layout(title = "Value Exchange Analysis",
             xaxis = list(title = "Quarter"),
             yaxis = list(title = "Value Index"),
             yaxis2 = list(title = "Relationship Strength", overlaying = 'y', side = 'right'))
    p
  })
  
  # Collaboration effectiveness for Tab 6
  output$collaboration_effectiveness <- renderPlotly({
    collab_data <- data.frame(
      Initiative_Type = c("Joint Ventures", "Knowledge Sharing", "Resource Pooling", 
                          "Co-Innovation", "Strategic Partnerships"),
      Engagement_Rate = c(67, 84, 72, 78, 81),
      Completion_Rate = c(73, 89, 76, 82, 85),
      Satisfaction_Score = c(7.8, 8.4, 7.9, 8.2, 8.6)
    )
    
    p <- plot_ly(collab_data, x = ~Initiative_Type, y = ~Engagement_Rate,
                 type = 'bar', name = 'Engagement Rate',
                 marker = list(color = primary_colour)) %>%
      add_trace(y = ~Completion_Rate, name = 'Completion Rate',
                marker = list(color = secondary_colour)) %>%
      layout(title = "Collaboration Initiative Effectiveness",
             xaxis = list(title = "Initiative Type"),
             yaxis = list(title = "Success Rate (%)"),
             barmode = 'group')
    p
  })
  
  # Desirability metrics for Tab 7
  output$desirability_metrics <- renderPlotly({
    desire_data <- data.frame(
      Month = 1:12,
      Inbound_Requests = c(23, 28, 31, 35, 42, 38, 45, 48, 52, 56, 61, 58),
      Response_Quality = c(6.8, 7.1, 7.3, 7.6, 7.9, 8.0, 8.2, 8.4, 8.5, 8.7, 8.8, 8.9),
      Network_Growth = c(15, 18, 22, 19, 26, 23, 28, 31, 29, 33, 35, 32)
    )
    
    p <- plot_ly(desire_data, x = ~Month) %>%
      add_trace(y = ~Inbound_Requests, type = 'scatter', mode = 'lines+markers',
                name = 'Inbound Requests', line = list(color = primary_colour)) %>%
      add_trace(y = ~Response_Quality * 7, type = 'scatter', mode = 'lines+markers',
                name = 'Response Quality (x7)', line = list(color = secondary_colour)) %>%
      add_trace(y = ~Network_Growth, type = 'scatter', mode = 'lines+markers',
                name = 'Network Growth', line = list(color = accent_colour)) %>%
      layout(title = "Professional Desirability Trends",
             xaxis = list(title = "Month"),
             yaxis = list(title = "Metric Value"))
    p
  })
  
  # Advanced metrics for Tab 8
  output$advanced_metrics <- renderPlotly({
    advanced_data <- data.frame(
      Metric = c("Betweenness Centrality", "Network Diversity", "Influence Propagation",
                 "Relationship ROI", "Strategic Positioning"),
      Current_Score = c(0.73, 0.81, 0.76, 0.84, 0.79),
      Industry_Average = c(0.45, 0.52, 0.48, 0.51, 0.49),
      Target_Score = c(0.85, 0.90, 0.88, 0.92, 0.87)
    )
    
    p <- plot_ly(advanced_data, x = ~Metric, y = ~Current_Score,
                 type = 'bar', name = 'Current Score',
                 marker = list(color = primary_colour)) %>%
      add_trace(y = ~Industry_Average, name = 'Industry Average',
                marker = list(color = secondary_colour)) %>%
      add_trace(y = ~Target_Score, name = 'Target Score',
                marker = list(color = accent_colour)) %>%
      layout(title = "Advanced Networking Metrics",
             xaxis = list(title = "Metric Category"),
             yaxis = list(title = "Score (0-1)"),
             barmode = 'group')
    p
  })
}

# Run the application
shinyApp(ui = ui, server = server)