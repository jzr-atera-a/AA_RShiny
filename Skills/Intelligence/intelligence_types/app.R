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

# UI Definition
ui <- dashboardPage(
  dashboardHeader(title = "Intelligence Development Academy"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Rational Intelligence", tabName = "rational", icon = icon("brain")),
      menuItem("Deductive Intelligence", tabName = "deductive", icon = icon("search")),
      menuItem("Algorithmic Intelligence", tabName = "algorithmic", icon = icon("code")),
      menuItem("Strategic Intelligence", tabName = "strategic", icon = icon("chess")),
      menuItem("Mathematical Intelligence", tabName = "mathematical", icon = icon("calculator")),
      menuItem("Musical Intelligence", tabName = "musical", icon = icon("music")),
      menuItem("Emotional Intelligence", tabName = "emotional", icon = icon("heart")),
      menuItem("Social Intelligence", tabName = "social", icon = icon("users")),
      menuItem("Creative Intelligence", tabName = "creative", icon = icon("lightbulb")),
      menuItem("Intuitive Intelligence", tabName = "intuitive", icon = icon("eye")),
      menuItem("Influential Intelligence", tabName = "influential", icon = icon("bullhorn")),
      menuItem("Additional Intelligences", tabName = "additional", icon = icon("plus"))
    )
  ),
  dashboardBody(
    tags$head(tags$style(HTML(custom_css))),
    
    tabItems(
      # Rational Intelligence Tab
      tabItem(tabName = "rational",
              fluidRow(
                box(width = 12, status = "primary", solidHeader = TRUE,
                    title = "Rational Intelligence Development",
                    div(class = "academic-content",
                        h5("Core Components of Rational Intelligence"),
                        p("Rational intelligence encompasses the ability to think logically, analyze information systematically, and make decisions based on evidence and reason rather than emotion or bias. This form of intelligence is foundational to scientific thinking, philosophical reasoning, and effective problem-solving."),
                        
                        div(class = "concept-highlight",
                            h5("Key Development Areas:"),
                            tags$ul(
                              tags$li("Critical thinking and logical reasoning"),
                              tags$li("Evidence-based decision making"),
                              tags$li("Cognitive bias recognition and mitigation"),
                              tags$li("Systematic analysis and synthesis"),
                              tags$li("Philosophical inquiry and reasoning")
                            )
                        ),
                        
                        h5("Development Strategies"),
                        p("Developing exceptional rational intelligence requires deliberate practice in logical reasoning, exposure to diverse philosophical perspectives, and consistent application of scientific methodology. Regular engagement with complex problems, formal logic training, and systematic bias testing are essential components."),
                        
                        div(class = "concept-highlight",
                            h5("Practical Exercises:"),
                            tags$ul(
                              tags$li("Daily practice with logical puzzles and syllogisms"),
                              tags$li("Systematic analysis of news articles for bias"),
                              tags$li("Engagement with formal philosophical arguments"),
                              tags$li("Scientific methodology application in daily decisions"),
                              tags$li("Regular debate and argumentation practice")
                            )
                        )
                    ),
                    
                    div(class = "references",
                        h5("References"),
                        div(class = "reference-item", "Evans, J. S. B. T. (2002). Logic and human reasoning: An assessment of the deduction paradigm. Psychological Bulletin, 128(6), 978-996."),
                        div(class = "reference-item", "Kahneman, D. (2011). Thinking, fast and slow. Farrar, Straus and Giroux."),
                        div(class = "reference-item", "Stanovich, K. E. (2009). What intelligence tests miss: The psychology of rational thought. Yale University Press."),
                        div(class = "reference-item", "Mercier, H., & Sperber, D. (2017). The enigma of reason. Harvard University Press.")
                    )
                )
              )
      ),
      
      # Deductive Intelligence Tab
      tabItem(tabName = "deductive",
              fluidRow(
                box(width = 12, status = "primary", solidHeader = TRUE,
                    title = "Deductive Intelligence Development",
                    div(class = "academic-content",
                        h5("Understanding Deductive Reasoning"),
                        p("Deductive intelligence involves the ability to draw specific conclusions from general principles or premises. This form of reasoning moves from the general to the specific, ensuring that if the premises are true, the conclusion must necessarily follow. It forms the backbone of mathematical proof, logical argumentation, and systematic problem-solving."),
                        
                        div(class = "concept-highlight",
                            h5("Core Elements:"),
                            tags$ul(
                              tags$li("Syllogistic reasoning and formal logic"),
                              tags$li("Pattern recognition and rule application"),
                              tags$li("Mathematical proof construction"),
                              tags$li("Systematic elimination processes"),
                              tags$li("Conditional reasoning mastery")
                            )
                        ),
                        
                        h5("Advanced Development Techniques"),
                        p("Exceptional deductive intelligence requires mastery of formal logical systems, extensive practice with complex reasoning chains, and the ability to maintain logical consistency across multiple premises. Training should focus on both speed and accuracy in logical operations."),
                        
                        div(class = "concept-highlight",
                            h5("Training Methods:"),
                            tags$ul(
                              tags$li("Formal logic course completion (propositional and predicate logic)"),
                              tags$li("Mathematical proof writing and verification"),
                              tags$li("Complex puzzle solving (logic grids, sudoku variants)"),
                              tags$li("Programming with logical languages (Prolog, logic programming)"),
                              tags$li("Competitive reasoning challenges and olympiads")
                            )
                        )
                    ),
                    
                    div(class = "references",
                        h5("References"),
                        div(class = "reference-item", "Rips, L. J. (1994). The psychology of proof: Deductive reasoning in human thinking. MIT Press."),
                        div(class = "reference-item", "Johnson-Laird, P. N. (2006). How we reason. Oxford University Press."),
                        div(class = "reference-item", "Braine, M. D., & O'Brien, D. P. (Eds.). (1998). Mental logic. Lawrence Erlbaum Associates."),
                        div(class = "reference-item", "Stenning, K., & van Lambalgen, M. (2008). Human reasoning and cognitive science. MIT Press.")
                    )
                )
              )
      ),
      
      # Algorithmic Intelligence Tab
      tabItem(tabName = "algorithmic",
              fluidRow(
                box(width = 12, status = "primary", solidHeader = TRUE,
                    title = "Algorithmic and Coding Intelligence Development",
                    div(class = "academic-content",
                        h5("Computational Thinking Mastery"),
                        p("Algorithmic intelligence encompasses the ability to think computationally, design efficient algorithms, and implement complex solutions through programming. This intelligence type is increasingly crucial in our digital age, combining logical reasoning with creative problem-solving and systematic optimization."),
                        
                        div(class = "concept-highlight",
                            h5("Core Competencies:"),
                            tags$ul(
                              tags$li("Algorithm design and complexity analysis"),
                              tags$li("Data structure optimization and selection"),
                              tags$li("Programming paradigm mastery (functional, OOP, procedural)"),
                              tags$li("System architecture and design patterns"),
                              tags$li("Computational problem decomposition")
                            )
                        ),
                        
                        h5("Advanced Development Framework"),
                        p("Developing exceptional algorithmic intelligence requires progressive exposure to increasingly complex computational problems, mastery of multiple programming paradigms, and deep understanding of computational complexity. The focus should be on both theoretical foundations and practical implementation skills."),
                        
                        div(class = "concept-highlight",
                            h5("Progression Path:"),
                            tags$ul(
                              tags$li("Master fundamental algorithms and data structures"),
                              tags$li("Competitive programming participation (ACM-ICPC, Codeforces)"),
                              tags$li("Open source contribution to complex projects"),
                              tags$li("Algorithm research and novel solution development"),
                              tags$li("Cross-disciplinary application (bioinformatics, ML, cryptography)")
                            )
                        )
                    ),
                    
                    div(class = "references",
                        h5("References"),
                        div(class = "reference-item", "Cormen, T. H., Leiserson, C. E., Rivest, R. L., & Stein, C. (2009). Introduction to algorithms (3rd ed.). MIT Press."),
                        div(class = "reference-item", "Wing, J. M. (2006). Computational thinking. Communications of the ACM, 49(3), 33-35."),
                        div(class = "reference-item", "Knuth, D. E. (1997). The art of computer programming (Vols. 1-3). Addison-Wesley."),
                        div(class = "reference-item", "Sedgewick, R., & Wayne, K. (2011). Algorithms (4th ed.). Addison-Wesley Professional.")
                    )
                )
              )
      ),
      
      # Strategic Intelligence Tab
      tabItem(tabName = "strategic",
              fluidRow(
                box(width = 12, status = "primary", solidHeader = TRUE,
                    title = "Strategic Intelligence Development",
                    div(class = "academic-content",
                        h5("Strategic Thinking Excellence"),
                        p("Strategic intelligence involves the ability to think several moves ahead, anticipate consequences, plan complex multi-step operations, and navigate competitive environments effectively. This intelligence type is crucial for leadership, business success, and any domain requiring long-term planning and tactical execution."),
                        
                        div(class = "concept-highlight",
                            h5("Key Components:"),
                            tags$ul(
                              tags$li("Long-term vision and planning capabilities"),
                              tags$li("Competitive analysis and game theory application"),
                              tags$li("Resource allocation and optimization"),
                              tags$li("Risk assessment and contingency planning"),
                              tags$li("Systems thinking and complexity management")
                            )
                        ),
                        
                        h5("Development Methodology"),
                        p("Exceptional strategic intelligence develops through exposure to complex strategic scenarios, study of historical strategic successes and failures, and practical application in competitive environments. Chess, business strategy, military history, and game theory provide excellent training grounds."),
                        
                        div(class = "concept-highlight",
                            h5("Training Approaches:"),
                            tags$ul(
                              tags$li("Master-level chess and complex board game play"),
                              tags$li("Business case study analysis and strategy development"),
                              tags$li("Military history and tactical study"),
                              tags$li("Game theory and decision science application"),
                              tags$li("Leadership roles in complex organizational challenges")
                            )
                        )
                    ),
                    
                    div(class = "references",
                        h5("References"),
                        div(class = "reference-item", "Porter, M. E. (1985). Competitive advantage: Creating and sustaining superior performance. Free Press."),
                        div(class = "reference-item", "Von Neumann, J., & Morgenstern, O. (2007). Theory of games and economic behavior. Princeton University Press."),
                        div(class = "reference-item", "Mintzberg, H. (1994). The rise and fall of strategic planning. Free Press."),
                        div(class = "reference-item", "Rumelt, R. (2011). Good strategy bad strategy: The difference and why it matters. Crown Business.")
                    )
                )
              )
      ),
      
      # Mathematical Intelligence Tab
      tabItem(tabName = "mathematical",
              fluidRow(
                box(width = 12, status = "primary", solidHeader = TRUE,
                    title = "Mathematical Intelligence Development",
                    div(class = "academic-content",
                        h5("Mathematical Reasoning Excellence"),
                        p("Mathematical intelligence encompasses numerical reasoning, spatial mathematics, algebraic thinking, and the ability to see patterns and relationships in abstract mathematical concepts. This intelligence type is fundamental to scientific thinking, engineering, and analytical problem-solving across diverse domains."),
                        
                        div(class = "concept-highlight",
                            h5("Core Areas:"),
                            tags$ul(
                              tags$li("Abstract algebraic and geometric reasoning"),
                              tags$li("Statistical and probabilistic thinking"),
                              tags$li("Calculus and mathematical analysis"),
                              tags$li("Discrete mathematics and combinatorics"),
                              tags$li("Mathematical modeling and application")
                            )
                        ),
                        
                        h5("Advanced Development Strategy"),
                        p("Developing exceptional mathematical intelligence requires progressive exposure to increasingly abstract mathematical concepts, regular problem-solving practice, and application of mathematical thinking to real-world problems. The key is building both computational fluency and conceptual understanding."),
                        
                        div(class = "concept-highlight",
                            h5("Development Path:"),
                            tags$ul(
                              tags$li("Mathematical olympiad training and competition"),
                              tags$li("Advanced university mathematics (real analysis, abstract algebra)"),
                              tags$li("Mathematical research and proof development"),
                              tags$li("Cross-disciplinary mathematical application"),
                              tags$li("Mathematical modeling of complex systems")
                            )
                        )
                    ),
                    
                    div(class = "references",
                        h5("References"),
                        div(class = "reference-item", "Polya, G. (1945). How to solve it: A new aspect of mathematical method. Princeton University Press."),
                        div(class = "reference-item", "Devlin, K. (2000). The math gene: How mathematical thinking evolved and why numbers are like gossip. Basic Books."),
                        div(class = "reference-item", "Gardner, H. (2011). Frames of mind: The theory of multiple intelligences. Basic Books."),
                        div(class = "reference-item", "Burton, D. M. (2010). The history of mathematics: An introduction (7th ed.). McGraw-Hill.")
                    )
                )
              )
      ),
      
      # Musical Intelligence Tab
      tabItem(tabName = "musical",
              fluidRow(
                box(width = 12, status = "primary", solidHeader = TRUE,
                    title = "Musical Intelligence Development",
                    div(class = "academic-content",
                        h5("Musical Cognition and Excellence"),
                        p("Musical intelligence involves the ability to perceive, understand, create, and manipulate musical patterns, rhythms, and structures. This intelligence type encompasses not only performance abilities but also composition, improvisation, and deep appreciation of musical complexity and emotional expression."),
                        
                        div(class = "concept-highlight",
                            h5("Core Components:"),
                            tags$ul(
                              tags$li("Pitch discrimination and tonal memory"),
                              tags$li("Rhythmic precision and temporal processing"),
                              tags$li("Harmonic understanding and analysis"),
                              tags$li("Musical composition and improvisation"),
                              tags$li("Cross-modal musical-emotional integration")
                            )
                        ),
                        
                        h5("Comprehensive Development Approach"),
                        p("Exceptional musical intelligence develops through intensive practice, formal music theory study, exposure to diverse musical traditions, and integration of performance with analytical understanding. The key is developing both technical proficiency and deep musical intuition."),
                        
                        div(class = "concept-highlight",
                            h5("Training Framework:"),
                            tags$ul(
                              tags$li("Intensive instrumental or vocal training (10,000+ hours)"),
                              tags$li("Advanced music theory and harmonic analysis"),
                              tags$li("Composition and arrangement practice"),
                              tags$li("Diverse genre exploration and cultural music study"),
                              tags$li("Performance psychology and stage mastery")
                            )
                        )
                    ),
                    
                    div(class = "references",
                        h5("References"),
                        div(class = "reference-item", "Sloboda, J. A. (2005). Exploring the musical mind: Cognition, emotion, ability, function. Oxford University Press."),
                        div(class = "reference-item", "Patel, A. D. (2008). Music, language, and the brain. Oxford University Press."),
                        div(class = "reference-item", "Ericsson, K. A., Krampe, R. T., & Tesch-Römer, C. (1993). The role of deliberate practice in the acquisition of expert performance. Psychological Review, 100(3), 363-406."),
                        div(class = "reference-item", "Levitin, D. J. (2006). This is your brain on music: The science of a human obsession. Dutton.")
                    )
                )
              )
      ),
      
      # Emotional Intelligence Tab
      tabItem(tabName = "emotional",
              fluidRow(
                box(width = 12, status = "primary", solidHeader = TRUE,
                    title = "Emotional Intelligence Development",
                    div(class = "academic-content",
                        h5("Emotional Mastery and Social Competence"),
                        p("Emotional intelligence encompasses the ability to recognize, understand, manage, and effectively use emotions in oneself and others. This intelligence type is crucial for leadership, relationships, mental health, and overall life success, often predicting outcomes better than traditional IQ measures."),
                        
                        div(class = "concept-highlight",
                            h5("Four Core Domains:"),
                            tags$ul(
                              tags$li("Self-awareness: emotional self-perception and understanding"),
                              tags$li("Self-regulation: emotional control and adaptive responses"),
                              tags$li("Social awareness: empathy and organizational awareness"),
                              tags$li("Relationship management: influence and conflict resolution")
                            )
                        ),
                        
                        h5("Evidence-Based Development"),
                        p("Developing exceptional emotional intelligence requires systematic self-reflection, mindfulness practice, feedback-seeking, and deliberate practice in social situations. Research shows that emotional intelligence can be significantly improved through targeted interventions and consistent practice."),
                        
                        div(class = "concept-highlight",
                            h5("Development Strategies:"),
                            tags$ul(
                              tags$li("Mindfulness meditation and emotional awareness training"),
                              tags$li("Regular feedback collection and emotional impact assessment"),
                              tags$li("Difficult conversation practice and conflict resolution"),
                              tags$li("Empathy-building exercises and perspective-taking"),
                              tags$li("Leadership roles and team management experience")
                            )
                        )
                    ),
                    
                    div(class = "references",
                        h5("References"),
                        div(class = "reference-item", "Goleman, D. (2006). Emotional intelligence: Why it matters more than IQ (10th ed.). Bantam Books."),
                        div(class = "reference-item", "Mayer, J. D., & Salovey, P. (1997). What is emotional intelligence? In P. Salovey & D. Sluyter (Eds.), Emotional development and emotional intelligence (pp. 3-31). Basic Books."),
                        div(class = "reference-item", "Bar-On, R. (2006). The Bar-On model of emotional-social intelligence (ESI). Psicothema, 18, 13-25."),
                        div(class = "reference-item", "Bradberry, T., & Greaves, J. (2009). Emotional intelligence 2.0. TalentSmart.")
                    )
                )
              )
      ),
      
      # Social Intelligence Tab
      tabItem(tabName = "social",
              fluidRow(
                box(width = 12, status = "primary", solidHeader = TRUE,
                    title = "Social Intelligence Development",
                    div(class = "academic-content",
                        h5("Social Cognition and Interpersonal Mastery"),
                        p("Social intelligence involves the ability to understand social situations, navigate complex interpersonal dynamics, influence others effectively, and build strong networks and relationships. This intelligence type is essential for leadership, collaboration, and success in any people-centered endeavor."),
                        
                        div(class = "concept-highlight",
                            h5("Key Capabilities:"),
                            tags$ul(
                              tags$li("Social situation analysis and context reading"),
                              tags$li("Nonverbal communication mastery"),
                              tags$li("Influence and persuasion techniques"),
                              tags$li("Network building and relationship management"),
                              tags$li("Group dynamics understanding and facilitation")
                            )
                        ),
                        
                        h5("Advanced Social Skills Development"),
                        p("Exceptional social intelligence develops through diverse social exposure, systematic study of human behavior, practice in various social contexts, and conscious development of interpersonal skills. The key is combining theoretical understanding with extensive practical application."),
                        
                        div(class = "concept-highlight",
                            h5("Training Methods:"),
                            tags$ul(
                              tags$li("Cross-cultural interaction and communication practice"),
                              tags$li("Public speaking and presentation skill development"),
                              tags$li("Negotiation and mediation training"),
                              tags$li("Social psychology and behavioral economics study"),
                              tags$li("Leadership roles in diverse group settings")
                            )
                        )
                    ),
                    
                    div(class = "references",
                        h5("References"),
                        div(class = "reference-item", "Thorndike, E. L. (1920). Intelligence and its uses. Harper's Magazine, 140, 227-235."),
                        div(class = "reference-item", "Cantor, N., & Kihlstrom, J. F. (1987). Personality and social intelligence. Prentice-Hall."),
                        div(class = "reference-item", "Baron-Cohen, S. (1995). Mindblindness: An essay on autism and theory of mind. MIT Press."),
                        div(class = "reference-item", "Cialdini, R. B. (2006). Influence: The psychology of persuasion. Harper Business.")
                    )
                )
              )
      ),
      
      # Creative Intelligence Tab
      tabItem(tabName = "creative",
              fluidRow(
                box(width = 12, status = "primary", solidHeader = TRUE,
                    title = "Creative Intelligence Development",
                    div(class = "academic-content",
                        h5("Innovation and Creative Problem-Solving"),
                        p("Creative intelligence encompasses the ability to generate novel, useful, and original ideas, solutions, and artistic expressions. This intelligence type involves divergent thinking, pattern breaking, synthesis of disparate concepts, and the ability to see possibilities that others miss."),
                        
                        div(class = "concept-highlight",
                            h5("Core Elements:"),
                            tags$ul(
                              tags$li("Divergent thinking and idea generation"),
                              tags$li("Creative problem-solving methodologies"),
                              tags$li("Artistic expression and aesthetic sensitivity"),
                              tags$li("Innovation and entrepreneurial thinking"),
                              tags$li("Cross-domain knowledge synthesis")
                            )
                        ),
                        
                        h5("Systematic Creativity Development"),
                        p("Exceptional creative intelligence develops through exposure to diverse fields, systematic creativity training, regular creative practice, and cultivation of a creative mindset. Research shows that creativity can be significantly enhanced through specific techniques and environmental factors."),
                        
                        div(class = "concept-highlight",
                            h5("Enhancement Strategies:"),
                            tags$ul(
                              tags$li("Design thinking and systematic innovation methods"),
                              tags$li("Cross-disciplinary learning and knowledge synthesis"),
                              tags$li("Regular artistic practice and aesthetic development"),
                              tags$li("Improvisation and spontaneous creation exercises"),
                              tags$li("Collaborative creativity and brainstorming mastery")
                            )
                        )
                    ),
                    
                    div(class = "references",
                        h5("References"),
                        div(class = "reference-item", "Guilford, J. P. (1967). The nature of human intelligence. McGraw-Hill."),
                        div(class = "reference-item", "Torrance, E. P. (1974). Torrance tests of creative thinking. Scholastic Testing Service."),
                        div(class = "reference-item", "Csikszentmihalyi, M. (1996). Creativity: Flow and the psychology of discovery and invention. Harper Collins."),
                        div(class = "reference-item", "Sternberg, R. J., & Lubart, T. I. (1999). The concept of creativity: Prospects and paradigms. In R. J. Sternberg (Ed.), Handbook of creativity (pp. 3-15). Cambridge University Press.")
                    )
                )
              )
      ),
      
      # Intuitive Intelligence Tab
      tabItem(tabName = "intuitive",
              fluidRow(
                box(width = 12, status = "primary", solidHeader = TRUE,
                    title = "Intuitive Intelligence Development",
                    div(class = "academic-content",
                        h5("Intuition and Implicit Pattern Recognition"),
                        p("Intuitive intelligence involves the ability to rapidly process complex information below the threshold of consciousness, recognize patterns without explicit analysis, and arrive at insights through non-linear thinking processes. This intelligence type complements analytical thinking and is crucial for rapid decision-making and creative breakthroughs."),
                        
                        div(class = "concept-highlight",
                            h5("Key Components:"),
                            tags$ul(
                              tags$li("Rapid pattern recognition and implicit learning"),
                              tags$li("Gut feeling accuracy and somatic decision-making"),
                              tags$li("Holistic information processing"),
                              tags$li("Unconscious competence and expert intuition"),
                              tags$li("Non-verbal communication sensitivity")
                            )
                        ),
                        
                        h5("Developing Reliable Intuition"),
                        p("Exceptional intuitive intelligence develops through extensive domain expertise, mindfulness practices that enhance bodily awareness, and systematic validation of intuitive insights. Research shows that expert intuition is based on rapid recognition of learned patterns and can be highly accurate in familiar domains."),
                        
                        div(class = "concept-highlight",
                            h5("Training Approaches:"),
                            tags$ul(
                              tags$li("Domain expertise development (10,000+ hours in specific fields)"),
                              tags$li("Mindfulness and body awareness meditation"),
                              tags$li("Intuition journaling and accuracy tracking"),
                              tags$li("Rapid decision-making practice with feedback"),
                              tags$li("Pattern recognition training across multiple domains")
                            )
                        )
                    ),
                    
                    div(class = "references",
                        h5("References"),
                        div(class = "reference-item", "Kahneman, D., & Klein, G. (2009). Conditions for intuitive expertise: A failure to disagree. American Psychologist, 64(6), 515-526."),
                        div(class = "reference-item", "Klein, G. (1998). Sources of power: How people make decisions. MIT Press."),
                        div(class = "reference-item", "Damasio, A. (1994). Descartes' error: Emotion, reason, and the human brain. Putnam."),
                        div(class = "reference-item", "Gigerenzer, G. (2007). Gut feelings: The intelligence of the unconscious. Viking.")
                    )
                )
              )
      ),
      
      # Influential Intelligence Tab
      tabItem(tabName = "influential",
              fluidRow(
                box(width = 12, status = "primary", solidHeader = TRUE,
                    title = "Influential Intelligence Development",
                    div(class = "academic-content",
                        h5("Persuasion and Impact Mastery"),
                        p("Influential intelligence encompasses the ability to persuade, motivate, and inspire others to action, change their perspectives, and achieve collective goals. This intelligence type combines understanding of human psychology, communication mastery, and ethical leadership to create positive change and drive results through others."),
                        
                        div(class = "concept-highlight",
                            h5("Core Capabilities:"),
                            tags$ul(
                              tags$li("Persuasion psychology and influence techniques"),
                              tags$li("Charismatic communication and presence"),
                              tags$li("Motivational leadership and inspiration"),
                              tags$li("Stakeholder alignment and coalition building"),
                              tags$li("Ethical influence and authentic leadership")
                            )
                        ),
                        
                        h5("Ethical Influence Development"),
                        p("Exceptional influential intelligence requires deep understanding of human motivation, masterful communication skills, and strong ethical foundations. The goal is to influence others in ways that serve mutual benefit and create positive outcomes for all stakeholders involved."),
                        
                        div(class = "concept-highlight",
                            h5("Development Framework:"),
                            tags$ul(
                              tags$li("Advanced rhetoric and persuasive communication training"),
                              tags$li("Psychology of influence and behavioral change study"),
                              tags$li("Leadership experience in diverse challenging contexts"),
                              tags$li("Public speaking and mass communication mastery"),
                              tags$li("Ethical decision-making and value-based leadership")
                            )
                        )
                    ),
                    
                    div(class = "references",
                        h5("References"),
                        div(class = "reference-item", "Cialdini, R. B. (2016). Pre-suasion: A revolutionary way to influence and persuade. Random House."),
                        div(class = "reference-item", "Heath, C., & Heath, D. (2007). Made to stick: Why some ideas survive and others die. Random House."),
                        div(class = "reference-item", "Kouzes, J. M., & Posner, B. Z. (2017). The leadership challenge: How to make extraordinary things happen in organizations (6th ed.). Jossey-Bass."),
                        div(class = "reference-item", "Carnegie, D. (1936). How to win friends and influence people. Simon & Schuster.")
                    )
                )
              )
      ),
      
      # Additional Intelligences Tab
      tabItem(tabName = "additional",
              fluidRow(
                box(width = 12, status = "primary", solidHeader = TRUE,
                    title = "Additional Intelligence Types",
                    div(class = "academic-content",
                        h5("Kinesthetic Intelligence"),
                        p("Kinesthetic intelligence involves the ability to use one's body skillfully and handle objects adroitly. This includes athletic performance, dance, surgery, craftsmanship, and any activity requiring precise motor control and body awareness."),
                        
                        div(class = "concept-highlight",
                            h5("Development: Physical practice, motor skill refinement, body awareness training, competitive athletics, precision crafts")
                        ),
                        
                        h5("Spatial Intelligence"),
                        p("Spatial intelligence encompasses the ability to perceive, manipulate, and create mental spatial representations. This intelligence is crucial for architecture, engineering, navigation, art, and scientific visualization."),
                        
                        div(class = "concept-highlight",
                            h5("Development: 3D modeling, architecture study, navigation challenges, visual art, mechanical engineering")
                        ),
                        
                        h5("Naturalistic Intelligence"),
                        p("Naturalistic intelligence involves the ability to recognize, categorize, and understand patterns in nature. This includes botanical knowledge, animal behavior understanding, environmental awareness, and ecological thinking."),
                        
                        div(class = "concept-highlight",
                            h5("Development: Field biology, environmental science, taxonomy study, ecological research, outdoor exploration")
                        ),
                        
                        h5("Existential Intelligence"),
                        p("Existential intelligence encompasses the ability to contemplate deep philosophical questions about existence, meaning, life, and death. This intelligence drives philosophical inquiry and spiritual understanding."),
                        
                        div(class = "concept-highlight",
                            h5("Development: Philosophy study, meditation practice, existential literature, spiritual inquiry, meaning-making activities")
                        ),
                        
                        h5("Cultural Intelligence"),
                        p("Cultural intelligence involves the ability to function effectively in culturally diverse settings, understand different cultural contexts, and adapt behavior appropriately across cultures."),
                        
                        div(class = "concept-highlight",
                            h5("Development: Cross-cultural exposure, language learning, cultural anthropology, international experience, diversity training")
                        )
                    ),
                    
                    div(class = "references",
                        h5("References"),
                        div(class = "reference-item", "Gardner, H. (2011). Frames of mind: The theory of multiple intelligences (3rd ed.). Basic Books."),
                        div(class = "reference-item", "Earley, P. C., & Ang, S. (2003). Cultural intelligence: Individual interactions across cultures. Stanford University Press."),
                        div(class = "reference-item", "Armstrong, T. (2009). Multiple intelligences in the classroom (3rd ed.). ASCD."),
                        div(class = "reference-item", "Chen, J. Q., Moran, S., & Gardner, H. (Eds.). (2009). Multiple intelligences around the world. Jossey-Bass.")
                    )
                )
              )
      )
    )
  )
)

# Server Logic
server <- function(input, output, session) {
  # Add any reactive elements or server-side logic here
  # Currently, the app is primarily content-based with static information
  
  # You can add interactive elements such as:
  # - Progress tracking for each intelligence type
  # - Self-assessment tools
  # - Personalized development plans
  # - Interactive exercises
  
  # Example of a reactive element (uncomment to use):
  # output$intelligence_summary <- renderText({
  #   "Track your progress across all intelligence types here."
  # })
}

# Run the application
shinyApp(ui = ui, server = server)