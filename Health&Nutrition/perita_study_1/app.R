# Culinary Education Dashboard - R Shiny App
# Interactive food science and cooking techniques learning platform

library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(ggplot2)
library(dplyr)
library(shinyWidgets)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "Culinary Education Dashboard"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Salmon Types", tabName = "salmon", icon = icon("fish")),
      menuItem("Molecular Gastronomy", tabName = "molecular", icon = icon("flask")),
      menuItem("Kitchen Measurements", tabName = "measurements", icon = icon("balance-scale")),
      menuItem("Cooking Methods", tabName = "cooking", icon = icon("fire")),
      menuItem("Knife Cuts", tabName = "cuts", icon = icon("cut")),
      menuItem("Soup Tier List", tabName = "soups", icon = icon("bowl-food")),
      menuItem("Chopping Boards", tabName = "boards", icon = icon("cutting-board")),
      menuItem("Beef Cuts", tabName = "beef", icon = icon("cow")),
      menuItem("Soup Formula", tabName = "formula", icon = icon("recipe")),
      menuItem("Prawns/Shrimp", tabName = "prawns", icon = icon("shrimp"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
       /* Header styling */
       .skin-blue .main-header .navbar {
         background-color: #FF8C00 !important;
       }
       .skin-blue .main-header .logo {
         background-color: #FF8C00 !important;
         color: #000000 !important;
         border-bottom: 0 solid transparent;
       }
       .skin-blue .main-header .logo:hover {
         background-color: #FF7F00 !important;
       }
       
       /* Sidebar styling */
       .skin-blue .main-sidebar {
         background-color: #B8860B !important;
       }
       .skin-blue .main-sidebar .sidebar .sidebar-menu .active a {
         background-color: #FFD700 !important;
         color: #000000 !important;
         font-weight: bold;
       }
       .skin-blue .main-sidebar .sidebar .sidebar-menu a {
         color: #000000 !important;
       }
       .skin-blue .main-sidebar .sidebar .sidebar-menu a:hover {
         background-color: #DAA520 !important;
         color: #000000 !important;
       }
       
       /* Content wrapper styling */
       .content-wrapper {
         background-color: #FFF8DC !important;
       }
       
       /* Box styling */
       .box {
         background-color: #FFFFE0 !important;
         border: 2px solid #DAA520 !important;
         border-radius: 8px !important;
         box-shadow: 0 4px 8px rgba(218, 165, 32, 0.3) !important;
       }
       .box.box-primary {
         border-top-color: #FF8C00 !important;
         border-top-width: 4px !important;
       }
       .box.box-primary .box-header {
         color: #000000 !important;
         background: linear-gradient(135deg, #FF8C00, #FFD700) !important;
         border-radius: 6px 6px 0 0 !important;
         border-bottom: 2px solid #DAA520 !important;
       }
       .box.box-primary .box-header .box-title {
         font-size: 18px !important;
         font-weight: bold !important;
         text-shadow: 1px 1px 2px rgba(0,0,0,0.1) !important;
       }
       .box-body {
         background-color: #FFFACD !important;
         color: #333333 !important;
         padding: 20px !important;
       }
       
       /* Text styling */
       p {
         color: #2F4F4F !important;
         line-height: 1.6 !important;
       }
       strong {
         color: #B8860B !important;
       }
       li {
         color: #2F4F4F !important;
         margin-bottom: 5px !important;
       }
       
       /* Example box styling */
       .example-box {
         background-color: #F0E68C !important;
         border: 1px solid #DAA520 !important;
         border-radius: 5px !important;
         padding: 10px !important;
         margin: 10px 0 !important;
       }
       
       /* Benefits and disadvantages styling */
       .benefits {
         background-color: #E6FFE6 !important;
         border-left: 4px solid #228B22 !important;
         padding: 10px !important;
         margin: 10px 0 !important;
       }
       
       .disadvantages {
         background-color: #FFE6E6 !important;
         border-left: 4px solid #DC143C !important;
         padding: 10px !important;
         margin: 10px 0 !important;
       }
       
       /* Link styling */
       a {
         color: #FF8C00 !important;
         text-decoration: none !important;
       }
       a:hover {
         color: #FF7F00 !important;
         text-decoration: underline !important;
       }
       
       /* Page title styling */
       .main-header .navbar-brand {
         color: #000000 !important;
         font-weight: bold !important;
       }
       
       /* Scrollbar styling */
       ::-webkit-scrollbar {
         width: 12px;
       }
       ::-webkit-scrollbar-track {
         background: #FFF8DC;
       }
       ::-webkit-scrollbar-thumb {
         background: #DAA520;
         border-radius: 6px;
       }
       ::-webkit-scrollbar-thumb:hover {
         background: #B8860B;
       }
       
       /* Intro box styling */
       .intro-box { 
         background-color: #F0E68C !important; 
         border: 1px solid #DAA520 !important;
         border-radius: 5px !important;
         padding: 15px; 
         margin-bottom: 20px; 
         border-left: 4px solid #B8860B; 
       }
       .intro-box h4 {
         color: #B8860B !important;
         margin-top: 0 !important;
       }
       .intro-box p {
         color: #2F4F4F !important;
         margin-bottom: 0 !important;
       }"))
    ),
    
    tabItems(
      # Salmon Types Tab
      tabItem(tabName = "salmon",
              fluidRow(
                div(class = "intro-box",
                    h4("Salmon Types Overview"),
                    p("This comprehensive guide explores six major salmon species, their unique characteristics, habitats, and optimal cooking methods. Learn about fat content variations, flavor profiles, texture differences, and price ranges to make informed choices for culinary applications. Understanding these distinctions helps in selecting the right salmon type for specific recipes and cooking techniques.")
                )
              ),
              fluidRow(
                box(width = 12, title = "Salmon Types Guide", status = "primary", solidHeader = TRUE,
                    fluidRow(
                      column(6,
                             h4("Select Salmon Type:"),
                             selectInput("salmon_type", "",
                                         choices = c("King (Chinook)", "Sockeye", "Coho", "Atlantic", "Chum", "Pink"),
                                         selected = "King (Chinook)")
                      ),
                      column(6,
                             h4("Cooking Method:"),
                             selectInput("cooking_method", "",
                                         choices = c("Raw", "Grilled", "Roasted", "Broiled", "Smoked", "Canned", "Baked"),
                                         selected = "Grilled")
                      )
                    ),
                    plotlyOutput("salmon_chart"),
                    br(),
                    div(style = "background-color: #f9f9f9; padding: 15px; border-radius: 5px;",
                        h4("Salmon Characteristics:"),
                        verbatimTextOutput("salmon_info")
                    )
                )
              ),
              fluidRow(
                box(width = 12, title = "References", status = "info",
                    tags$div(
                      tags$p("1. ", tags$a("NOAA Fisheries - Salmon Species Guide", 
                                           href = "https://www.fisheries.noaa.gov/species/salmon", target = "_blank")),
                      tags$p("2. ", tags$a("Seafood Health Facts - Salmon Nutrition", 
                                           href = "https://www.seafoodhealthfacts.org/seafood-choices/descriptions-popular-seafood/salmon", target = "_blank"))
                    )
                )
              )
      ),
      
      # Molecular Gastronomy Tab
      tabItem(tabName = "molecular",
              fluidRow(
                div(class = "intro-box",
                    h4("Molecular Gastronomy Introduction"),
                    p("Molecular gastronomy revolutionizes traditional cooking by applying scientific principles to create innovative textures and presentations. This section covers three fundamental techniques: emulsification for creating foams, gelification for forming pearls and gels, and spherification for liquid-filled spheres. These methods transform ordinary ingredients into extraordinary culinary experiences using compounds like lecithin, agar, and sodium alginate.")
                )
              ),
              fluidRow(
                box(width = 12, title = "Molecular Gastronomy Techniques", status = "primary", solidHeader = TRUE,
                    tabsetPanel(
                      tabPanel("Emulsification",
                               fluidRow(
                                 column(6,
                                        h4("Emulsification Process"),
                                        p("Process of taking a liquid substance and turning it into a foam by focusing on creating small bubbles inside or outside a liquid."),
                                        h5("Key Ingredients:"),
                                        tags$ul(
                                          tags$li("Soy Lecithin: Compound extracted from soybeans"),
                                          tags$li("Any flavored liquid (fruit juice, broth, etc.)")
                                        ),
                                        numericInput("emulsion_liquid", "Liquid amount (ml):", value = 250, min = 100, max = 500),
                                        numericInput("emulsion_lecithin", "Lecithin amount (g):", value = 2, min = 1, max = 5)
                                 ),
                                 column(6,
                                        h4("Emulsification Calculator"),
                                        plotlyOutput("emulsion_ratio")
                                 )
                               )
                      ),
                      tabPanel("Gelification",
                               fluidRow(
                                 column(6,
                                        h4("Gelification Process"),
                                        p("Process of turning a liquid substance into a solid with varying rigidity. Usually a gel with pearls, tiny caviar-like pearls are formed."),
                                        h5("Key Ingredients:"),
                                        tags$ul(
                                          tags$li("Agar: Compound extracted from algae"),
                                          tags$li("Any flavored liquid")
                                        ),
                                        sliderInput("gel_temp", "Setting Temperature (°C):", min = 0, max = 100, value = 85)
                                 ),
                                 column(6,
                                        h4("Gel Strength Chart"),
                                        plotlyOutput("gel_strength")
                                 )
                               )
                      ),
                      tabPanel("Spherification",
                               fluidRow(
                                 column(6,
                                        h4("Spherification Process"),
                                        p("Process of forming a liquid substance into sphere-shaped liquid pearls. They are held in place by a thin gel coating."),
                                        h5("Key Ingredients:"),
                                        tags$ul(
                                          tags$li("Sodium Alginate: Extracted from brown algae"),
                                          tags$li("Calcium Chloride: For gel formation")
                                        ),
                                        radioButtons("sphere_type", "Sphere Type:",
                                                     choices = c("Basic Spherification", "Reverse Spherification"),
                                                     selected = "Basic Spherification")
                                 ),
                                 column(6,
                                        h4("Spherification Timeline"),
                                        plotlyOutput("sphere_timeline")
                                 )
                               )
                      )
                    )
                )
              ),
              fluidRow(
                box(width = 12, title = "References", status = "info",
                    tags$div(
                      tags$p("1. ", tags$a("Molecular Gastronomy - Science Direct", 
                                           href = "https://www.sciencedirect.com/topics/food-science/molecular-gastronomy", target = "_blank")),
                      tags$p("2. ", tags$a("Khymos - Molecular Gastronomy Resources", 
                                           href = "http://blog.khymos.org/molecular-gastronomy/", target = "_blank"))
                    )
                )
              )
      ),
      
      # Kitchen Measurements Tab
      tabItem(tabName = "measurements",
              fluidRow(
                div(class = "intro-box",
                    h4("Kitchen Measurements Guide"),
                    p("Accurate measurements are fundamental to successful cooking and baking. This interactive conversion tool helps you navigate between imperial and metric systems for weights, volumes, and temperatures. Additionally, it provides cooking time calculations for various proteins and comprehensive reference charts. Master these conversions to ensure consistency and precision in your culinary endeavors, whether following international recipes or scaling portions.")
                )
              ),
              fluidRow(
                box(width = 6, title = "Weight Conversions", status = "primary", solidHeader = TRUE,
                    numericInput("weight_input", "Enter weight:", value = 8, min = 0),
                    selectInput("weight_from", "From:", choices = c("oz", "lb", "g", "kg"), selected = "oz"),
                    selectInput("weight_to", "To:", choices = c("oz", "lb", "g", "kg"), selected = "g"),
                    h4("Result:"),
                    verbatimTextOutput("weight_result")
                ),
                box(width = 6, title = "Volume Conversions", status = "primary", solidHeader = TRUE,
                    numericInput("volume_input", "Enter volume:", value = 1, min = 0),
                    selectInput("volume_from", "From:", choices = c("tsp", "tbsp", "cup", "fl oz", "ml", "L"), selected = "cup"),
                    selectInput("volume_to", "To:", choices = c("tsp", "tbsp", "cup", "fl oz", "ml", "L"), selected = "ml"),
                    h4("Result:"),
                    verbatimTextOutput("volume_result")
                )
              ),
              fluidRow(
                box(width = 6, title = "Temperature Converter", status = "primary", solidHeader = TRUE,
                    numericInput("temp_input", "Enter temperature:", value = 350, min = -50, max = 600),
                    selectInput("temp_from", "From:", choices = c("°F", "°C"), selected = "°F"),
                    selectInput("temp_to", "To:", choices = c("°F", "°C"), selected = "°C"),
                    h4("Result:"),
                    verbatimTextOutput("temp_result")
                ),
                box(width = 6, title = "Cooking Time Calculator", status = "primary", solidHeader = TRUE,
                    selectInput("protein_type", "Protein Type:", 
                                choices = c("Chicken Breast", "Beef Steak", "Pork Chop", "Fish Fillet"),
                                selected = "Chicken Breast"),
                    numericInput("protein_weight", "Weight (oz):", value = 6, min = 1, max = 20),
                    selectInput("cooking_style", "Cooking Method:", 
                                choices = c("Grilled", "Roasted", "Pan-fried", "Baked"),
                                selected = "Grilled"),
                    h4("Recommended Cooking Time:"),
                    verbatimTextOutput("cooking_time")
                )
              ),
              fluidRow(
                box(width = 12, title = "Measurement Reference Chart", status = "info",
                    DT::dataTableOutput("measurement_table")
                )
              ),
              fluidRow(
                box(width = 12, title = "References", status = "info",
                    tags$div(
                      tags$p("1. ", tags$a("USDA Food Safety - Cooking Times", 
                                           href = "https://www.fsis.usda.gov/food-safety/safe-food-handling-and-preparation/food-safety-basics/safe-temperature-chart", target = "_blank")),
                      tags$p("2. ", tags$a("King Arthur Baking - Measurement Conversions", 
                                           href = "https://www.kingarthurbaking.com/learn/ingredient-weight-chart", target = "_blank"))
                    )
                )
              )
      ),
      
      # Cooking Methods Tab
      tabItem(tabName = "cooking",
              fluidRow(
                div(class = "intro-box",
                    h4("Cooking Methods Classification"),
                    p("Understanding cooking methods is essential for culinary mastery. This section categorizes techniques into three main approaches: concentration methods that seal flavors through high heat, expansion methods that allow flavors to develop in liquid mediums, and mixed cooking that combines both techniques. Each method affects texture, flavor development, and nutritional content differently, making proper selection crucial for desired outcomes.")
                )
              ),
              fluidRow(
                box(width = 12, title = "Cooking Methods Classification", status = "primary", solidHeader = TRUE,
                    selectInput("cooking_category", "Select Cooking Category:",
                                choices = c("Concentration", "Expansion", "Mixed Cooking"),
                                selected = "Concentration"),
                    plotlyOutput("cooking_methods_chart")
                )
              ),
              fluidRow(
                box(width = 12, title = "Cooking Method Details", status = "info",
                    verbatimTextOutput("cooking_method_info")
                )
              ),
              fluidRow(
                box(width = 12, title = "References", status = "info",
                    tags$div(
                      tags$p("1. ", tags$a("Culinary Institute of America - Cooking Methods", 
                                           href = "https://www.ciachef.edu/culinary-arts-cooking-methods/", target = "_blank")),
                      tags$p("2. ", tags$a("The Food Network - Cooking Techniques", 
                                           href = "https://www.foodnetwork.com/how-to/packages/food-network-essentials/cooking-techniques", target = "_blank"))
                    )
                )
              )
      ),
      
      # Knife Cuts Tab
      tabItem(tabName = "cuts",
              fluidRow(
                div(class = "intro-box",
                    h4("Classic Vegetable Cuts"),
                    p("Proper knife skills and uniform cuts are hallmarks of professional cooking. This guide details eight classic French cuts from precise brunoise to rustic paysanne, each serving specific culinary purposes. Understanding cut specifications, appropriate vegetables, and applications ensures consistent cooking times, professional presentation, and optimal flavor extraction. Practice these fundamental techniques to elevate your culinary precision and efficiency.")
                )
              ),
              fluidRow(
                box(width = 12, title = "Classic Vegetable Cuts", status = "primary", solidHeader = TRUE,
                    selectInput("cut_type", "Select Cut Type:",
                                choices = c("Brunoise", "Chiffonade", "Jardinière", "Julienne", "Macédoine", "Matignon", "Mirepoix", "Paysanne"),
                                selected = "Brunoise"),
                    fluidRow(
                      column(6,
                             h4("Cut Specifications:"),
                             verbatimTextOutput("cut_specs")
                      ),
                      column(6,
                             h4("Cut Size Comparison:"),
                             plotlyOutput("cut_size_chart")
                      )
                    )
                )
              ),
              fluidRow(
                box(width = 12, title = "Knife Skills Practice Timer", status = "info",
                    fluidRow(
                      column(4,
                             numericInput("practice_time", "Practice Time (minutes):", value = 10, min = 1, max = 60),
                             actionButton("start_timer", "Start Practice", class = "btn-primary")
                      ),
                      column(8,
                             h4("Timer Display:"),
                             verbatimTextOutput("timer_display")
                      )
                    )
                )
              ),
              fluidRow(
                box(width = 12, title = "References", status = "info",
                    tags$div(
                      tags$p("1. ", tags$a("Culinary Arts - Knife Cuts Guide", 
                                           href = "https://www.culinaryschools.org/blog/knife-cuts/", target = "_blank")),
                      tags$p("2. ", tags$a("The Spruce Eats - Knife Skills", 
                                           href = "https://www.thespruceeats.com/knife-skills-and-cuts-3057897", target = "_blank"))
                    )
                )
              )
      ),
      
      # Soup Tier List Tab
      tabItem(tabName = "soups",
              fluidRow(
                div(class = "intro-box",
                    h4("Ultimate Soup Tier Rankings"),
                    p("This comprehensive soup ranking system evaluates global soup varieties based on flavor complexity, ingredient quality, cultural significance, and culinary technique requirements. From S-tier masterpieces like gazpacho and borscht to basic preparations, each tier represents different levels of culinary achievement. Use this guide to understand soup hierarchies, explore new recipes, and appreciate the artistry behind soup creation across different cuisines.")
                )
              ),
              fluidRow(
                box(width = 12, title = "Ultimate Soup Tier List", status = "primary", solidHeader = TRUE,
                    selectInput("soup_tier", "Select Tier:",
                                choices = c("S-Tier", "A-Tier", "B-Tier", "C-Tier", "F-Tier"),
                                selected = "S-Tier"),
                    plotlyOutput("soup_tier_chart")
                )
              ),
              fluidRow(
                box(width = 6, title = "Soup Complexity Analysis", status = "info",
                    plotlyOutput("soup_complexity")
                ),
                box(width = 6, title = "Soup Popularity Trends", status = "info",
                    plotlyOutput("soup_trends")
                )
              ),
              fluidRow(
                box(width = 12, title = "References", status = "info",
                    tags$div(
                      tags$p("1. ", tags$a("Food Network - Soup Recipes", 
                                           href = "https://www.foodnetwork.com/recipes/packages/soups-and-stews", target = "_blank")),
                      tags$p("2. ", tags$a("Bon Appétit - Soup Guide", 
                                           href = "https://www.bonappetit.com/recipes/soups", target = "_blank"))
                    )
                )
              )
      ),
      
      # Chopping Boards Tab
      tabItem(tabName = "boards",
              fluidRow(
                div(class = "intro-box",
                    h4("Food Safety: Chopping Board System"),
                    p("Color-coded chopping boards are essential for preventing cross-contamination in professional kitchens. This system assigns specific colors to different food categories: red for raw meat, blue for fish, green for vegetables, and more. Understanding and implementing this system reduces foodborne illness risks, maintains hygiene standards, and demonstrates professional kitchen management. Learn the complete color system for optimal food safety practices.")
                )
              ),
              fluidRow(
                box(width = 12, title = "Food Safety: Chopping Board Colors", status = "primary", solidHeader = TRUE,
                    selectInput("board_color", "Select Board Color:",
                                choices = c("Red", "Yellow", "Blue", "White", "Green", "Brown", "Purple"),
                                selected = "Red"),
                    fluidRow(
                      column(6,
                             h4("Board Usage:"),
                             verbatimTextOutput("board_usage")
                      ),
                      column(6,
                             h4("Cross-Contamination Prevention:"),
                             plotlyOutput("contamination_chart")
                      )
                    )
                )
              ),
              fluidRow(
                box(width = 12, title = "Food Safety Quiz", status = "info",
                    h4("Which board would you use for cooked chicken?"),
                    radioButtons("safety_quiz", "",
                                 choices = c("Red Board", "Yellow Board", "Blue Board", "Green Board"),
                                 selected = character(0)),
                    verbatimTextOutput("quiz_result")
                )
              ),
              fluidRow(
                box(width = 12, title = "References", status = "info",
                    tags$div(
                      tags$p("1. ", tags$a("FDA - Food Safety Guidelines", 
                                           href = "https://www.fda.gov/food/buy-store-serve-safe-food/safe-food-handling", target = "_blank")),
                      tags$p("2. ", tags$a("USDA - Kitchen Food Safety", 
                                           href = "https://www.fsis.usda.gov/food-safety/safe-food-handling-and-preparation/food-safety-basics", target = "_blank"))
                    )
                )
              )
      ),
      
      # Beef Cuts Tab
      tabItem(tabName = "beef",
              fluidRow(
                div(class = "intro-box",
                    h4("Beef Cuts and Applications"),
                    p("Understanding beef anatomy and cut characteristics is crucial for proper cooking method selection and cost management. This guide explores eight major beef sections, from tender premium cuts like ribeye to tougher, flavorful options requiring slow cooking. Learn about marbling, tenderness levels, best cooking applications, and internal temperature requirements to maximize flavor, texture, and value in beef preparations.")
                )
              ),
              fluidRow(
                box(width = 12, title = "Beef Cuts and Cooking Methods", status = "primary", solidHeader = TRUE,
                    selectInput("beef_section", "Select Beef Section:",
                                choices = c("Chuck", "Rib", "Short Loin", "Sirloin", "Round", "Brisket", "Plate", "Flank"),
                                selected = "Chuck"),
                    fluidRow(
                      column(6,
                             h4("Cut Information:"),
                             verbatimTextOutput("beef_info")
                      ),
                      column(6,
                             h4("Tenderness vs Price:"),
                             plotlyOutput("beef_chart")
                      )
                    )
                )
              ),
              fluidRow(
                box(width = 12, title = "Cooking Temperature Guide", status = "info",
                    DT::dataTableOutput("beef_temp_table")
                )
              ),
              fluidRow(
                box(width = 12, title = "References", status = "info",
                    tags$div(
                      tags$p("1. ", tags$a("Certified Angus Beef - Cut Guide", 
                                           href = "https://www.certifiedangusbeef.com/cuts/", target = "_blank")),
                      tags$p("2. ", tags$a("USDA - Beef Cuts and Cooking", 
                                           href = "https://www.fsis.usda.gov/food-safety/safe-food-handling-and-preparation/meat", target = "_blank"))
                    )
                )
              )
      ),
      
      # Soup Formula Tab
      tabItem(tabName = "formula",
              fluidRow(
                div(class = "intro-box",
                    h4("Soup Construction Formula"),
                    p("Building great soups follows a systematic approach combining aromatics, proteins, vegetables, and liquids in proper sequence. This interactive formula guides you through the essential steps: sautéing aromatics for flavor base, incorporating proteins and vegetables at optimal timing, and developing depth through proper simmering techniques. Master this fundamental framework to create countless soup variations with confidence and consistency.")
                )
              ),
              fluidRow(
                box(width = 12, title = "Soup Building Formula", status = "primary", solidHeader = TRUE,
                    h4("Interactive Soup Builder"),
                    fluidRow(
                      column(3,
                             h5("1. Aromatics:"),
                             checkboxGroupInput("aromatics", "",
                                                choices = c("Onions", "Garlic", "Celery", "Carrots", "Leeks"),
                                                selected = "Onions")
                      ),
                      column(3,
                             h5("2. Protein:"),
                             checkboxGroupInput("protein", "",
                                                choices = c("Chicken", "Beef", "Pork", "Seafood", "Beans"),
                                                selected = "Chicken")
                      ),
                      column(3,
                             h5("3. Vegetables:"),
                             checkboxGroupInput("vegetables", "",
                                                choices = c("Potatoes", "Tomatoes", "Mushrooms", "Corn", "Peas"),
                                                selected = "Potatoes")
                      ),
                      column(3,
                             h5("4. Liquid Base:"),
                             radioButtons("liquid_base", "",
                                          choices = c("Chicken Stock", "Beef Stock", "Vegetable Stock", "Water"),
                                          selected = "Chicken Stock")
                      )
                    ),
                    h4("Your Soup Recipe:"),
                    verbatimTextOutput("soup_recipe")
                )
              ),
              fluidRow(
                box(width = 6, title = "Cooking Steps Timeline", status = "info",
                    plotlyOutput("soup_steps")
                ),
                box(width = 6, title = "Flavor Profile", status = "info",
                    plotlyOutput("flavor_profile")
                )
              ),
              fluidRow(
                box(width = 12, title = "References", status = "info",
                    tags$div(
                      tags$p("1. ", tags$a("Serious Eats - Soup Making Guide", 
                                           href = "https://www.seriouseats.com/how-to-make-soup", target = "_blank")),
                      tags$p("2. ", tags$a("The Kitchn - Soup Basics", 
                                           href = "https://www.thekitchn.com/how-to-make-soup-cooking-lessons-from-the-kitchn-218286", target = "_blank"))
                    )
                )
              )
      ),
      
      # Prawns/Shrimp Tab
      tabItem(tabName = "prawns",
              fluidRow(
                div(class = "intro-box",
                    h4("Prawn and Shrimp Varieties"),
                    p("Understanding different prawn and shrimp species enhances seafood selection and preparation techniques. This guide covers five distinct varieties from small quisquilla to premium carabinero, each with unique size, flavor, and texture characteristics. Learn about habitat influences on taste, optimal cooking methods for each type, size classifications, and nutritional benefits to make informed choices for various culinary applications and budget considerations.")
                )
              ),
              fluidRow(
                box(width = 12, title = "Prawn/Shrimp Types and Characteristics", status = "primary", solidHeader = TRUE,
                    selectInput("prawn_type", "Select Type:",
                                choices = c("Camarón (Shrimp)", "Quisquilla (Small Shrimp)", "Gamba Blanca (White Prawn)", 
                                            "Gamba Gris (Grey Prawn)", "Carabinero (Red Prawn)"),
                                selected = "Gamba Blanca (White Prawn)"),
                    fluidRow(
                      column(6,
                             h4("Characteristics:"),
                             verbatimTextOutput("prawn_info")
                      ),
                      column(6,
                             h4("Size Comparison:"),
                             plotlyOutput("prawn_size_chart")
                      )
                    )
                )
              ),
              fluidRow(
                box(width = 6, title = "Cooking Methods", status = "info",
                    checkboxGroupInput("prawn_cooking", "Select cooking methods:",
                                       choices = c("Grilled", "Boiled", "Fried", "Steamed", "Raw (Sashimi)"),
                                       selected = "Grilled"),
                    h4("Cooking Times:"),
                    verbatimTextOutput("prawn_cooking_time")
                ),
                box(width = 6, title = "Nutritional Benefits", status = "info",
                    plotlyOutput("prawn_nutrition")
                )
              ),
              fluidRow(
                box(width = 12, title = "References", status = "info",
                    tags$div(
                      tags$p("1. ", tags$a("Seafood Source - Shrimp Guide", 
                                           href = "https://www.seafoodsource.com/seafood-handbook/crustaceans/shrimp", target = "_blank")),
                      tags$p("2. ", tags$a("Marine Stewardship Council - Shrimp", 
                                           href = "https://www.msc.org/what-we-are-doing/our-approach/what-does-the-blue-msc-label-mean/seafood-species/shrimp", target = "_blank"))
                    )
                )
              )
      )
    )
  )
)

# Define Server
server <- function(input, output, session) {
  
  # Salmon Tab Logic
  output$salmon_chart <- renderPlotly({
    salmon_data <- data.frame(
      Type = c("King", "Sockeye", "Coho", "Atlantic", "Chum", "Pink"),
      Fat_Content = c(15, 8, 6, 12, 4, 3),
      Price_Range = c(5, 4, 3, 2, 1, 1),
      Flavor_Intensity = c(5, 5, 4, 3, 2, 2)
    )
    
    p <- plot_ly(salmon_data, x = ~Fat_Content, y = ~Price_Range, 
                 text = ~Type, mode = 'markers+text',
                 marker = list(size = ~Flavor_Intensity*5, color = ~Flavor_Intensity,
                               colorscale = 'Viridis')) %>%
      layout(title = "Salmon Types: Fat Content vs Price",
             xaxis = list(title = "Fat Content (%)"),
             yaxis = list(title = "Price Range (1-5)"))
    p
  })
  
  output$salmon_info <- renderText({
    salmon_info <- list(
      "King (Chinook)" = "Habitat: North Pacific Ocean\nFlavor: High fat content, rich flavor\nTexture: Tender, moist with large flakes\nBest for: Grilling, roasting, smoking",
      "Sockeye" = "Habitat: North Pacific Ocean\nFlavor: Robust and intense, strong taste\nTexture: Dense and moist, firm flakes\nBest for: Grilling, roasting, broiling",
      "Coho" = "Habitat: Pacific Ocean\nFlavor: Buttery, slightly sweet, slightly rich\nTexture: Semi-firm and tender, moderate firm flakes\nBest for: Grilling, roasting, baking",
      "Atlantic" = "Habitat: North Atlantic Ocean\nFlavor: Mild and creamy, sweet taste\nTexture: Moderately firm, thin and smooth flakes\nBest for: Various cooking methods",
      "Chum" = "Habitat: North Pacific/Bering Arctic\nFlavor: Lightest taste, less rich\nTexture: Firm, meaty and moist, coarse flakes\nBest for: Smoking, canning, curing",
      "Pink" = "Habitat: North Pacific Ocean\nFlavor: Neutral and delicate, mildly sweet\nTexture: Softest and most delicate, finest flakes\nBest for: Canning, burgers, patties"
    )
    salmon_info[[input$salmon_type]]
  })
  
  # Molecular Gastronomy Logic
  output$emulsion_ratio <- renderPlotly({
    liquid <- input$emulsion_liquid
    lecithin <- input$emulsion_lecithin
    ratio <- liquid/lecithin
    
    data <- data.frame(
      Component = c("Liquid", "Lecithin"),
      Amount = c(liquid, lecithin),
      Percentage = c(liquid/(liquid+lecithin)*100, lecithin/(liquid+lecithin)*100)
    )
    
    # Random vivid colors for bars
    bar_colors <- c("#FF6B35", "#F7931E", "#FFD23F", "#06FFA5", "#4ECDC4", 
                    "#45B7D1", "#96CEB4", "#FFEAA7", "#DDA0DD", "#98D8C8")
    selected_colors <- sample(bar_colors, 2)
    
    p <- plot_ly(data, x = ~Component, y = ~Amount, type = 'bar',
                 text = ~paste(Amount, "ml/g"), textposition = 'outside',
                 marker = list(color = selected_colors,
                               line = list(color = '#B8860B', width = 2))) %>%
      layout(title = paste("Emulsion Ratio:", round(ratio, 1), ":1"),
             xaxis = list(title = "Component"),
             yaxis = list(title = "Amount"))
    p
  })
  
  output$gel_strength <- renderPlotly({
    temps <- seq(0, 100, 10)
    strength <- ifelse(temps < 40, 0, ifelse(temps > 85, 100, (temps-40)*100/45))
    
    data <- data.frame(Temperature = temps, Gel_Strength = strength)
    
    p <- plot_ly(data, x = ~Temperature, y = ~Gel_Strength, type = 'scatter', mode = 'lines',
                 line = list(color = 'blue', width = 3)) %>%
      add_segments(x = input$gel_temp, xend = input$gel_temp, y = 0, yend = 100, 
                   line = list(color = "red", dash = "dash")) %>%
      layout(title = "Gel Strength vs Temperature",
             xaxis = list(title = "Temperature (°C)"),
             yaxis = list(title = "Gel Strength (%)"))
    p
  })
  
  output$sphere_timeline <- renderPlotly({
    steps <- c("Mix Calcium Bath", "Prepare Alginate Solution", "Form Spheres", "Rinse Spheres")
    times <- c(2, 5, 10, 2)
    cumulative <- cumsum(times)
    
    data <- data.frame(Step = steps, Duration = times, Cumulative = cumulative)
    
    p <- plot_ly(data, x = ~Cumulative, y = ~Step, type = 'scatter', mode = 'markers+lines',
                 marker = list(size = 10), line = list(width = 3)) %>%
      layout(title = "Spherification Process Timeline",
             xaxis = list(title = "Time (minutes)"))
    p
  })
  
  # Measurements Tab Logic
  output$weight_result <- renderText({
    conversions <- list(
      "oz" = 1, "lb" = 16, "g" = 0.035274, "kg" = 35.274
    )
    
    from_oz <- input$weight_input / conversions[[input$weight_from]]
    result <- from_oz * conversions[[input$weight_to]]
    
    paste(input$weight_input, input$weight_from, "=", round(result, 3), input$weight_to)
  })
  
  output$volume_result <- renderText({
    conversions <- list(
      "tsp" = 1, "tbsp" = 3, "cup" = 48, "fl oz" = 6, "ml" = 0.202884, "L" = 202.884
    )
    
    from_tsp <- input$volume_input / conversions[[input$volume_from]]
    result <- from_tsp * conversions[[input$volume_to]]
    
    paste(input$volume_input, input$volume_from, "=", round(result, 3), input$volume_to)
  })
  
  output$temp_result <- renderText({
    if(input$temp_from == "°F" && input$temp_to == "°C") {
      result <- (input$temp_input - 32) * 5/9
    } else if(input$temp_from == "°C" && input$temp_to == "°F") {
      result <- input$temp_input * 9/5 + 32
    } else {
      result <- input$temp_input
    }
    
    paste(input$temp_input, input$temp_from, "=", round(result, 1), input$temp_to)
  })
  
  output$cooking_time <- renderText({
    times <- list(
      "Chicken Breast" = list("Grilled" = 6, "Roasted" = 8, "Pan-fried" = 7, "Baked" = 10),
      "Beef Steak" = list("Grilled" = 4, "Roasted" = 6, "Pan-fried" = 5, "Baked" = 8),
      "Pork Chop" = list("Grilled" = 5, "Roasted" = 7, "Pan-fried" = 6, "Baked" = 9),
      "Fish Fillet" = list("Grilled" = 3, "Roasted" = 5, "Pan-fried" = 4, "Baked" = 6)
    )
    
    base_time <- times[[input$protein_type]][[input$cooking_style]]
    adjusted_time <- base_time * (input$protein_weight / 6)  # 6 oz baseline
    
    paste(round(adjusted_time, 1), "minutes for", input$protein_weight, "oz", input$protein_type)
  })
  
  output$measurement_table <- DT::renderDataTable({
    measurements <- data.frame(
      Imperial = c("1 tsp", "1 tbsp", "1/4 cup", "1/2 cup", "1 cup", "1 pint", "1 quart", "1 gallon"),
      Metric = c("5 ml", "15 ml", "60 ml", "120 ml", "240 ml", "470 ml", "950 ml", "3.8 L"),
      Weight_Flour = c("2g", "6g", "28g", "57g", "115g", "230g", "460g", "1840g"),
      Weight_Sugar = c("4g", "12g", "50g", "100g", "200g", "400g", "800g", "3200g")
    )
    DT::datatable(measurements, options = list(pageLength = 10, searching = FALSE))
  })
  
  # Cooking Methods Tab Logic
  output$cooking_methods_chart <- renderPlotly({
    methods_data <- list(
      "Concentration" = c("Saltear", "Asar", "Emparrilla", "Risolar", "Freir", "Ebullicion", "Hornear", "Vapor"),
      "Expansion" = c("Partiendo de un liquido frio", "Gratinar", "Glasear", "Confitar", "Blanquear", "Escalfar"),
      "Mixed Cooking" = c("Brasear", "Estofar", "Guisar", "Coccion al vacio", "Rehogar/Sofieir", "Sudar")
    )
    
    selected_methods <- methods_data[[input$cooking_category]]
    
    data <- data.frame(
      Method = selected_methods,
      Heat_Level = sample(1:5, length(selected_methods), replace = TRUE),
      Time_Required = sample(10:120, length(selected_methods), replace = TRUE)
    )
    
    p <- plot_ly(data, x = ~Heat_Level, y = ~Time_Required, text = ~Method,
                 mode = 'markers+text', textposition = 'top center',
                 marker = list(size = 12, color = ~Heat_Level, colorscale = 'Hot')) %>%
      layout(title = paste("Cooking Methods:", input$cooking_category),
             xaxis = list(title = "Heat Level (1-5)"),
             yaxis = list(title = "Time Required (minutes)"))
    p
  })
  
  output$cooking_method_info <- renderText({
    method_descriptions <- list(
      "Concentration" = "Methods that seal in juices and flavors by applying high heat initially. Examples: Searing, Grilling, Roasting, Frying. These methods create caramelization and Maillard reactions.",
      "Expansion" = "Methods that start with liquid or low heat, allowing flavors to expand into the cooking medium. Examples: Boiling, Poaching, Steaming. These methods are gentler and preserve delicate textures.",
      "Mixed Cooking" = "Combination methods that use both dry and moist heat. Examples: Braising, Stewing. These methods typically start with searing then finish with liquid cooking."
    )
    method_descriptions[[input$cooking_category]]
  })
  
  # Knife Cuts Tab Logic
  output$cut_specs <- renderText({
    cut_info <- list(
      "Brunoise" = "Size: 1-3mm square cubes\nUse: Garnish for consommé\nVegetables: Carrot, onion, turnip, celery\nTechnique: Very precise, uniform cuts",
      "Chiffonade" = "Size: Thin strips\nUse: Garnish for soups, salads\nVegetables: Leafy greens, herbs\nTechnique: Stack, roll, and slice thinly",
      "Jardinière" = "Size: 2cm long batons, 3mm thick\nUse: Vegetable garnish\nVegetables: Mixed vegetables\nTechnique: Uniform rectangular cuts",
      "Julienne" = "Size: 4cm long matchsticks\nUse: Garnish, stir-fries\nVegetables: Carrots, peppers, zucchini\nTechnique: Thin, uniform strips",
      "Macédoine" = "Size: 5mm squares\nUse: Mixed vegetable dishes\nVegetables: Carrot, onion, turnip, beans, celery\nTechnique: Larger than brunoise",
      "Matignon" = "Size: Rough cut vegetables\nUse: Flavoring base for sauces\nVegetables: Cooked in butter with ham, thyme, bay leaf\nTechnique: Rustic, roughly chopped",
      "Mirepoix" = "Size: Roughly chopped\nUse: Flavoring base for stocks, sauces\nVegetables: Onion, celery, carrot (2:1:1 ratio)\nTechnique: Coarse, uniform pieces",
      "Paysanne" = "Size: Various shapes (squares, triangles, circles)\nUse: Country-style dishes\nVegetables: Mixed vegetables\nTechnique: Economical cutting to match vegetable shape"
    )
    cut_info[[input$cut_type]]
  })
  
  output$cut_size_chart <- renderPlotly({
    cut_sizes <- data.frame(
      Cut = c("Brunoise", "Chiffonade", "Jardinière", "Julienne", "Macédoine", "Matignon", "Mirepoix", "Paysanne"),
      Size_mm = c(2, 1, 5, 3, 5, 10, 15, 8),
      Precision = c(5, 4, 4, 5, 3, 2, 2, 3)
    )
    
    p <- plot_ly(cut_sizes, x = ~Size_mm, y = ~Precision, text = ~Cut,
                 mode = 'markers+text', textposition = 'top center',
                 marker = list(size = ~Size_mm*2, color = ~Precision, colorscale = 'Viridis')) %>%
      layout(title = "Cut Size vs Precision Required",
             xaxis = list(title = "Average Size (mm)"),
             yaxis = list(title = "Precision Level (1-5)"))
    p
  })
  
  # Timer logic (simplified)
  timer_start <- reactiveVal(NULL)
  
  observeEvent(input$start_timer, {
    timer_start(Sys.time())
  })
  
  output$timer_display <- renderText({
    if(is.null(timer_start())) {
      "Timer not started"
    } else {
      elapsed <- as.numeric(difftime(Sys.time(), timer_start(), units = "secs"))
      target <- input$practice_time * 60
      remaining <- max(0, target - elapsed)
      
      if(remaining > 0) {
        minutes <- floor(remaining / 60)
        seconds <- floor(remaining %% 60)
        paste("Time remaining:", sprintf("%02d:%02d", minutes, seconds))
      } else {
        "Practice time complete! Well done!"
      }
    }
  })
  
  # Soup Tier List Logic
  output$soup_tier_chart <- renderPlotly({
    soup_tiers <- list(
      "S-Tier" = c("Gazpacho", "Clam Chowder", "Borscht", "Grandma's Chicken", "Oxtail", "Sop Korma", "Zurek"),
      "A-Tier" = c("Laksa", "French Onion", "Cream of Mushroom", "Ramen", "Clam Miso", "Cullen Skink", "Zuppa Toscana"),
      "B-Tier" = c("Caldo de res", "Harira", "Cream of Crab", "Broccoli Cheddar", "Tomato", "Sausage", "Red Pepper Bisque"),
      "C-Tier" = c("Corn Chowder", "Black Beans", "Irish Colcannon", "Portuguese Bean", "Split Pea", "Potato", "Vegetable"),
      "F-Tier" = c("Canned Seed Oils")
    )
    
    selected_soups <- soup_tiers[[input$soup_tier]]
    tier_score <- 6 - which(names(soup_tiers) == input$soup_tier)  # S=5, A=4, B=3, C=2, F=1
    
    data <- data.frame(
      Soup = selected_soups,
      Tier_Score = rep(tier_score, length(selected_soups)),
      Popularity = sample(60:95, length(selected_soups), replace = TRUE)
    )
    
    # Random vivid colors for each soup
    vivid_colors <- c("#FF6B35", "#F7931E", "#FFD23F", "#06FFA5", "#4ECDC4", 
                      "#45B7D1", "#96CEB4", "#FFEAA7", "#DDA0DD", "#98D8C8",
                      "#FF9FF3", "#54A0FF", "#5F27CD", "#00D2D3", "#FF9F43",
                      "#F0932B", "#6C5CE7", "#A29BFE", "#FD79A8", "#E17055")
    
    selected_colors <- sample(vivid_colors, length(selected_soups), replace = TRUE)
    
    p <- plot_ly(data, 
                 x = ~reorder(Soup, Popularity), 
                 y = ~Popularity, 
                 type = 'bar',
                 marker = list(color = selected_colors,
                               line = list(color = '#B8860B', width = 2)),
                 text = ~paste(Soup, "<br>Score:", Popularity),
                 textposition = 'none',
                 hovertemplate = "%{text}<extra></extra>") %>%
      layout(title = paste("Soup Tier:", input$soup_tier, "- Popularity Rankings"),
             xaxis = list(title = "Soup Types", 
                          tickangle = -45,
                          tickfont = list(size = 10)),
             yaxis = list(title = "Popularity Score (%)"),
             margin = list(b = 100))  # Extra bottom margin for rotated labels
    p
  })
  
  output$soup_complexity <- renderPlotly({
    complexity_data <- data.frame(
      Tier = c("S-Tier", "A-Tier", "B-Tier", "C-Tier", "F-Tier"),
      Avg_Complexity = c(8, 7, 5, 3, 1),
      Ingredients = c(12, 10, 8, 6, 3)
    )
    
    p <- plot_ly(complexity_data, x = ~Avg_Complexity, y = ~Ingredients, text = ~Tier,
                 mode = 'markers+text', textposition = 'middle right',
                 marker = list(size = 15, color = c('#ff0000', '#ff8000', '#ffff00', '#80ff00', '#00ff00'))) %>%
      layout(title = "Soup Complexity Analysis",
             xaxis = list(title = "Average Complexity (1-10)"),
             yaxis = list(title = "Average Ingredients Count"))
    p
  })
  
  output$soup_trends <- renderPlotly({
    months <- c("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
    hot_soups <- c(95, 90, 70, 50, 30, 20, 25, 30, 60, 80, 90, 95)
    cold_soups <- c(5, 10, 30, 50, 70, 80, 75, 70, 40, 20, 10, 5)
    
    data <- data.frame(
      Month = factor(months, levels = months),
      Hot_Soups = hot_soups,
      Cold_Soups = cold_soups
    )
    
    p <- plot_ly(data, x = ~Month, y = ~Hot_Soups, type = 'scatter', mode = 'lines',
                 name = 'Hot Soups', line = list(color = 'red', width = 3)) %>%
      add_trace(y = ~Cold_Soups, name = 'Cold Soups', line = list(color = 'blue', width = 3)) %>%
      layout(title = "Seasonal Soup Popularity Trends",
             xaxis = list(title = "Month"),
             yaxis = list(title = "Popularity (%)"))
    p
  })
  
  # Chopping Boards Logic
  output$board_usage <- renderText({
    board_info <- list(
      "Red" = "Use for: Raw meat and poultry\nReason: Prevents cross-contamination from raw proteins\nCleaning: Hot soapy water, sanitize after use",
      "Yellow" = "Use for: Cooked meat and poultry\nReason: Separates cooked from raw proteins\nCleaning: Regular washing, less intensive sanitizing needed",
      "Blue" = "Use for: Raw fish and seafood\nReason: Prevents fishy odors from transferring to other foods\nCleaning: Thorough cleaning to remove fishy smells",
      "White" = "Use for: Dairy and bakery items\nReason: Clean appearance shows any contamination easily\nCleaning: Regular washing, easy to bleach if needed",
      "Green" = "Use for: Washed fruits and salad vegetables\nReason: Safe for ready-to-eat produce\nCleaning: Gentle cleaning to maintain food safety",
      "Brown" = "Use for: Unwashed root vegetables\nReason: Contains soil and dirt from root vegetables\nCleaning: Thorough cleaning to remove soil particles",
      "Purple" = "Use for: Free-from products (allergen-free)\nReason: Prevents allergen cross-contamination\nCleaning: Extra careful cleaning and separate storage"
    )
    board_info[[input$board_color]]
  })
  
  output$contamination_chart <- renderPlotly({
    risk_data <- data.frame(
      Food_Type = c("Raw Meat", "Cooked Meat", "Raw Fish", "Dairy", "Vegetables", "Root Veg", "Allergen-Free"),
      Risk_Level = c(5, 2, 4, 1, 1, 3, 1),
      Board_Color = c("Red", "Yellow", "Blue", "White", "Green", "Brown", "Purple")
    )
    
    colors <- c("red", "yellow", "blue", "white", "green", "brown", "purple")
    
    p <- plot_ly(risk_data, x = ~Food_Type, y = ~Risk_Level, type = 'bar',
                 marker = list(color = colors)) %>%
      layout(title = "Contamination Risk by Food Type",
             xaxis = list(title = "Food Type"),
             yaxis = list(title = "Contamination Risk Level (1-5)"))
    p
  })
  
  output$quiz_result <- renderText({
    if(length(input$safety_quiz) == 0) {
      "Please select an answer."
    } else if(input$safety_quiz == "Yellow Board") {
      "Correct! Yellow boards are used for cooked meat and poultry."
    } else {
      "Incorrect. Yellow boards should be used for cooked meat and poultry."
    }
  })
  
  # Beef Cuts Logic
  output$beef_info <- renderText({
    beef_cuts <- list(
      "Chuck" = "Location: Shoulder area\nCharacteristics: Well-marbled, tough but flavorful\nBest for: Braising, slow cooking, grinding\nPopular cuts: Chuck roast, chuck steak",
      "Rib" = "Location: Upper back\nCharacteristics: Well-marbled, tender, premium cuts\nBest for: Roasting, grilling\nPopular cuts: Ribeye, prime rib",
      "Short Loin" = "Location: Lower back\nCharacteristics: Very tender, lean to moderately marbled\nBest for: Grilling, pan-searing\nPopular cuts: T-bone, porterhouse, strip steak",
      "Sirloin" = "Location: Hip area\nCharacteristics: Moderately tender, good flavor\nBest for: Grilling, roasting\nPopular cuts: Sirloin steak, tri-tip",
      "Round" = "Location: Rear leg\nCharacteristics: Lean, less tender\nBest for: Slow cooking, marinating\nPopular cuts: Round steak, eye of round",
      "Brisket" = "Location: Chest area\nCharacteristics: Tough, requires long cooking\nBest for: Smoking, braising\nPopular cuts: Flat cut, point cut",
      "Plate" = "Location: Belly area\nCharacteristics: Fatty, tough\nBest for: Braising, grinding\nPopular cuts: Short ribs, skirt steak",
      "Flank" = "Location: Abdominal area\nCharacteristics: Lean, flavorful, somewhat tough\nBest for: Marinating, quick cooking\nPopular cuts: Flank steak"
    )
    beef_cuts[[input$beef_section]]
  })
  
  output$beef_chart <- renderPlotly({
    beef_data <- data.frame(
      Section = c("Chuck", "Rib", "Short Loin", "Sirloin", "Round", "Brisket", "Plate", "Flank"),
      Tenderness = c(3, 9, 9, 7, 4, 2, 3, 5),
      Price = c(3, 9, 8, 6, 3, 4, 3, 5),
      Flavor = c(8, 8, 7, 7, 5, 9, 7, 8)
    )
    
    p <- plot_ly(beef_data, x = ~Tenderness, y = ~Price, text = ~Section,
                 mode = 'markers+text', textposition = 'top center',
                 marker = list(size = ~Flavor*2, color = ~Flavor, colorscale = 'Reds')) %>%
      layout(title = "Beef Cuts: Tenderness vs Price",
             xaxis = list(title = "Tenderness (1-10)"),
             yaxis = list(title = "Price Level (1-10)"))
    p
  })
  
  output$beef_temp_table <- DT::renderDataTable({
    temps <- data.frame(
      Doneness = c("Rare", "Medium Rare", "Medium", "Medium Well", "Well Done"),
      Temperature_F = c("120-125°F", "130-135°F", "135-145°F", "145-155°F", "155°F+"),
      Temperature_C = c("49-52°C", "54-57°C", "57-63°C", "63-68°C", "68°C+"),
      Description = c("Cool red center", "Warm red center", "Warm pink center", "Slightly pink center", "No pink, fully cooked")
    )
    DT::datatable(temps, options = list(pageLength = 5, searching = FALSE))
  })
  
  # Soup Formula Logic
  output$soup_recipe <- renderText({
    recipe_steps <- c(
      "1. Heat oil in large pot over medium heat",
      paste("2. Sauté aromatics:", paste(input$aromatics, collapse = ", ")),
      if(length(input$protein) > 0) paste("3. Add protein:", paste(input$protein, collapse = ", ")),
      paste("4. Add vegetables:", paste(input$vegetables, collapse = ", ")),
      paste("5. Pour in", input$liquid_base),
      "6. Simmer for 20-30 minutes",
      "7. Season with salt and pepper to taste",
      "8. Serve hot with garnish"
    )
    
    paste(recipe_steps[!is.na(recipe_steps)], collapse = "\n")
  })
  
  output$soup_steps <- renderPlotly({
    steps <- c("Prep", "Sauté", "Add Protein", "Add Veg", "Add Liquid", "Simmer", "Season")
    times <- c(10, 5, 8, 5, 2, 25, 2)
    cumulative <- cumsum(times)
    
    data <- data.frame(Step = steps, Duration = times, Cumulative = cumulative)
    
    p <- plot_ly(data, x = ~Cumulative, y = ~Step, type = 'scatter', mode = 'markers+lines',
                 marker = list(size = 10), line = list(width = 3)) %>%
      layout(title = "Soup Cooking Timeline",
             xaxis = list(title = "Time (minutes)"))
    p
  })
  
  output$flavor_profile <- renderPlotly({
    aromatics_score <- length(input$aromatics) * 2
    protein_score <- length(input$protein) * 3
    veg_score <- length(input$vegetables) * 1.5
    
    flavor_data <- data.frame(
      Component = c("Aromatics", "Protein", "Vegetables"),
      Flavor_Contribution = c(aromatics_score, protein_score, veg_score)
    )
    
    p <- plot_ly(flavor_data, labels = ~Component, values = ~Flavor_Contribution, type = 'pie') %>%
      layout(title = "Soup Flavor Profile")
    p
  })
  
  # Prawns Logic
  output$prawn_info <- renderText({
    prawn_types <- list(
      "Camarón (Shrimp)" = "Size: Small to medium\nHabitat: Coastal waters\nFlavor: Sweet, delicate\nTexture: Firm when cooked properly\nBest use: Versatile cooking applications",
      "Quisquilla (Small Shrimp)" = "Size: Very small\nHabitat: Shallow coastal waters\nFlavor: Intense, concentrated\nTexture: Tender\nBest use: Garnish, tapas, whole consumption",
      "Gamba Blanca (White Prawn)" = "Size: Medium to large\nHabitat: Deeper Mediterranean waters\nFlavor: Sweet, mild\nTexture: Tender, succulent\nBest use: Grilling, boiling, paella",
      "Gamba Gris (Grey Prawn)" = "Size: Medium\nHabitat: North Sea, Atlantic\nFlavor: Rich, slightly briny\nTexture: Firm, meaty\nBest use: Cocktails, salads, cooking",
      "Carabinero (Red Prawn)" = "Size: Large (up to 30cm)\nHabitat: Deep Mediterranean waters\nFlavor: Exceptional, sweet, complex\nTexture: Firm, luxurious\nBest use: High-end cuisine, grilling, raw preparations"
    )
    prawn_types[[input$prawn_type]]
  })
  
  output$prawn_size_chart <- renderPlotly({
    prawn_data <- data.frame(
      Type = c("Camarón", "Quisquilla", "Gamba Blanca", "Gamba Gris", "Carabinero"),
      Size_cm = c(8, 3, 15, 10, 25),
      Price_Level = c(3, 2, 6, 4, 10)
    )
    
    p <- plot_ly(prawn_data, x = ~Size_cm, y = ~Price_Level, text = ~Type,
                 mode = 'markers+text', textposition = 'top center',
                 marker = list(size = ~Size_cm, color = ~Price_Level, colorscale = 'Viridis')) %>%
      layout(title = "Prawn Size vs Price Level",
             xaxis = list(title = "Average Size (cm)"),
             yaxis = list(title = "Price Level (1-10)"))
    p
  })
  
  output$prawn_cooking_time <- renderText({
    cooking_times <- list(
      "Grilled" = "2-3 minutes per side",
      "Boiled" = "2-4 minutes total",
      "Fried" = "1-2 minutes",
      "Steamed" = "3-5 minutes",
      "Raw (Sashimi)" = "No cooking required"
    )
    
    selected_methods <- input$prawn_cooking
    if(length(selected_methods) == 0) {
      "Please select cooking methods"
    } else {
      times <- sapply(selected_methods, function(x) cooking_times[[x]])
      paste(paste(selected_methods, ":", times), collapse = "\n")
    }
  })
  
  output$prawn_nutrition <- renderPlotly({
    nutrition_data <- data.frame(
      Nutrient = c("Protein", "Fat", "Carbs", "Omega-3", "Selenium", "Vitamin B12"),
      Value = c(85, 5, 0, 15, 95, 120),
      Unit = c("% DV", "g", "g", "% DV", "% DV", "% DV")
    )
    
    p <- plot_ly(nutrition_data, x = ~Nutrient, y = ~Value, type = 'bar',
                 text = ~paste(Value, Unit), textposition = 'outside',
                 marker = list(color = 'lightblue')) %>%
      layout(title = "Prawn Nutritional Benefits (per 100g)",
             xaxis = list(title = "Nutrient"),
             yaxis = list(title = "Value"))
    p
  })
}

# Run the application
shinyApp(ui = ui, server = server)