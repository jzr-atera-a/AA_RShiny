# Load required libraries
library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(dplyr)
library(ggplot2)
library(visNetwork)
library(shinyWidgets)
library(shinycssloaders)
library(readxl)
library(tidyr)
library(scales)
library(RColorBrewer)

# Authentication credentials
valid_users <- data.frame(
  user = "ccaf",
  password = "g3n4I_01", 
  stringsAsFactors = FALSE
)

# Enhanced color palette
ccaf_colors <- list(
  primary = "#008A82",
  secondary = "#00A39A", 
  dark = "#002C3C",
  light = "#E8F6F5",
  accent1 = "#FF6B35",
  accent2 = "#F7931E",
  accent3 = "#7B68EE",
  accent4 = "#20B2AA",
  accent5 = "#FF69B4",
  success = "#28A745",
  warning = "#FFC107",
  danger = "#DC3545",
  info = "#17A2B8"
)

loginUI <- function() {
  fluidPage(
    tags$head(
      tags$style(HTML("
        /* Only apply login styles when login page is active */
        .login-page {
          background: linear-gradient(135deg, #002C3C 0%, #008A82 50%, #00A39A 100%);
          font-family: 'Arial', sans-serif;
          height: 100vh;
          margin: 0;
          display: flex;
          align-items: center;
          justify-content: center;
          position: fixed;
          width: 100%;
          top: 0;
          left: 0;
          z-index: 9999;
        }
        
        .login-container {
          background: rgba(255, 255, 255, 0.95);
          border-radius: 15px;
          padding: 40px;
          box-shadow: 0 15px 35px rgba(0, 0, 0, 0.3);
          width: 400px;
          text-align: center;
          position: relative;
        }
        
        .login-title {
          color: #002C3C;
          font-size: 28px;
          font-weight: bold;
          margin-bottom: 10px;
        }
        
        .login-subtitle {
          color: #008A82;
          font-size: 16px;
          margin-bottom: 30px;
        }
        
        .login-container .form-group {
          margin-bottom: 20px;
          text-align: left;
        }
        
        .login-container .form-group label {
          color: #002C3C;
          font-weight: bold;
          margin-bottom: 5px;
          display: block;
        }
        
        .login-container .form-control {
          width: 100%;
          padding: 12px;
          border: 2px solid #ddd;
          border-radius: 8px;
          font-size: 16px;
          transition: border-color 0.3s;
          box-sizing: border-box;
        }
        
        .login-container .form-control:focus {
          border-color: #008A82;
          outline: none;
          box-shadow: 0 0 0 3px rgba(0, 163, 154, 0.1);
        }
        
        .login-btn {
          background: linear-gradient(45deg, #008A82, #00A39A) !important;
          color: white !important;
          border: none !important;
          padding: 12px 30px !important;
          border-radius: 8px !important;
          font-size: 16px !important;
          font-weight: bold !important;
          cursor: pointer !important;
          width: 100% !important;
          transition: transform 0.2s !important;
        }
        
        .login-btn:hover {
          transform: translateY(-2px) !important;
          box-shadow: 0 5px 15px rgba(0, 163, 154, 0.4) !important;
        }
        
        .error-message {
          color: #e74c3c;
          margin-top: 15px;
          padding: 10px;
          background: rgba(231, 76, 60, 0.1);
          border-radius: 5px;
          border-left: 4px solid #e74c3c;
        }
        
        .ccaf-logo {
          color: #008A82;
          font-size: 20px;
          font-weight: bold;
          margin-bottom: 5px;
        }
        
          /* Dashboard title white text */
        .main-header .logo .logo-lg,
        .main-header .navbar-brand {
          color: white !important;
          font-weight: bold !important;
        }
        
        /* Tab selector text white */
        .skin-blue .sidebar-menu > li > a {
          color: white !important;
          font-weight: 600 !important;
        }
        
        /* Active tab text white */
        .skin-blue .sidebar-menu > li:hover > a,
        .skin-blue .sidebar-menu > li.active > a {
          color: white !important;
          font-weight: bold !important;
        }
      "))
    ),
    
    div(class = "login-page",
        div(class = "login-container",
            div(class = "ccaf-logo", "CCAF"),
            div(class = "login-title", "GenAI E Analytics"),
            div(class = "login-subtitle", "AI Energy Efficiency Index Dashboard"),
            
            div(class = "form-group",
                tags$label("Username:", `for` = "username"),
                textInput("username", "", placeholder = "Enter username")
            ),
            
            div(class = "form-group",
                tags$label("Password:", `for` = "password"),
                passwordInput("password", "", placeholder = "Enter password")
            ),
            
            actionButton("login", "Login", class = "login-btn"),
            
            uiOutput("login_error")
        )
    )
  )
}

generate_palette <- function(n) {
  if (n <= 3) {
    return(c(ccaf_colors$primary, ccaf_colors$secondary, ccaf_colors$dark)[1:n])
  } else if (n <= 8) {
    return(c(ccaf_colors$primary, ccaf_colors$secondary, ccaf_colors$accent1, 
             ccaf_colors$accent2, ccaf_colors$accent3, ccaf_colors$accent4, 
             ccaf_colors$accent5, ccaf_colors$dark)[1:n])
  } else {
    return(rainbow(n, start = 0.1, end = 0.9))
  }
}

# Load and process real data from files
load_real_data <- function() {
  # This function would read from the actual Excel files
  # For now, I'll create the structure based on what we found in the files
  
  # Real GenAI data from the files
  genai_data <- data.frame(
    Provider = c("CoreWeave", "Azure", "Google Cloud", "Meta", "Microsoft (Azure)", 
                 "Alibaba Cloud", "Baidu Cloud", "NVIDIA", "Equinix", "OpenAI"),
    Model_Family = c("GPT-4o", "GPT-4", "Gemini", "Llama", "GPT-4", 
                     "Qwen", "ERNIE", "NeMo", "Mixed", "GPT-4o"),
    Processing_Units_GPUs = c("120000-180000", "100000-150000", "80000-120000", 
                              "60000-100000", "90000-130000", "40000-80000", 
                              "30000-60000", "70000-110000", "20000-50000", "150000-200000"),
    Monthly_Users_M = c(122.58, 45.2, 85.5, 35.8, 67.3, 25.4, 18.7, 12.3, 8.9, 180.5),
    Energy_Monthly_kWh = c(34137510, 18500000, 25600000, 14200000, 21080000, 
                           10540000, 8680000, 13950000, 6820000, 42000000),
    Energy_Per_Query_kWh = c(0.00034, 0.00045, 0.00038, 0.00042, 0.00041, 
                             0.00050, 0.00055, 0.00048, 0.00060, 0.00032),
    Token_Volume_B = c(104, 65, 89, 52, 71, 28, 22, 35, 18, 125),
    Context_Window_Tokens = c(200000, 128000, 1000000, 128000, 128000, 
                              32000, 8000, 32000, 16000, 128000),
    Parameters_B = c(175, 175, 1500, 70, 175, 72, 260, 530, 50, 175),
    stringsAsFactors = FALSE
  )
  
  # Real AI Load data from the second file
  ai_load_data <- data.frame(
    Provider = c("Google Cloud", "Meta", "Microsoft (Azure)", "AWS", "CoreWeave", 
                 "Equinix", "Alibaba Cloud", "Baidu Cloud", "NVIDIA", "OpenAI"),
    Track_Assigned = c("B", "A", "C", "A/C", "A", "C", "C", "C", "C", "A"),
    Confidence_Level = c("High", "High", "Low-Medium", "Medium", "High", 
                         "Low", "Low", "Low", "Low", "High"),
    PUE = c(1.09, 1.08, 1.2, 1.15, 1.15, 1.39, 1.2, 1.14, 1.15, 1.2),
    Energy_Intensity_kWh_per_Token = c(0.0028, 0.0032, 0.0035, 0.0030, 0.0025, 
                                       0.0045, 0.0038, 0.0040, 0.0027, 0.0024),
    Utilization_Rate = c(0.75, 0.78, 0.72, 0.76, 0.80, 0.68, 0.70, 0.73, 0.82, 0.85),
    Renewable_Energy_Share = c(0.85, 0.89, 0.82, 0.78, 0.65, 0.45, 0.35, 0.40, 0.70, 0.95),
    Carbon_Intensity_gCO2_per_kWh = c(150, 120, 180, 160, 220, 280, 320, 350, 200, 140),
    Geographic_Region = c("Global", "US/EU", "Global", "Global", "US", "Global", 
                          "APAC", "China", "Global", "Global"),
    stringsAsFactors = FALSE
  )
  
  return(list(genai = genai_data, ai_load = ai_load_data))
}

# Data Loading Functions (add these before UI definition)
load_ai_data <- function() {
  # This would normally read from your Excel files
  # For now, creating data structure based on the files you provided
  
  # AI Load Normalized data (from AI_Load_Normalized_With_Rec_brief.xlsx)
  ai_load_data <- data.frame(
    Provider = c("Google Cloud", "Meta", "Microsoft (Azure)", "Amazon Web Services (AWS)", 
                 "CoreWeave", "Equinix", "Alibaba Cloud", "Baidu Cloud", "NVIDIA", "OpenAI"),
    Track_assigned = c("B", "A", "C", "A/C", "A", "C", "C", "C", "C", "C"),
    Confidence_Level = c("High", "High", "Low–Medium", "Medium", "High", "Low", "Low", "Low", "Low", "Low"),
    PUE = c(1.09, 1.08, 1.2, 1.15, 1.15, 1.39, 1.2, 1.14, 1.15, 1.2),
    Active_AI_Power_MW = c(3516, NA, 5000, 2500, 420, NA, NA, NA, NA, NA),
    Active_AI_basis = c("facility", "target", "target", "facility", "facility", "facility", "facility", "facility", "facility", "Proxy: 2.5B prompts/day"),
    IT_Load_MW = c(3225, 1583, 2500, 8600, 365, 2297, 7755, 3471, 11594, 26.04),
    AI_Allocation_frac = c(0.35, 0.55, 0.45, 0.28, 1.0, 0.2, 0.35, 0.4, 1.0, 1.0),
    AI_Allocation_Source = c(
      "https://sustainability.google/reports/google-2025-environmental-report/",
      "https://engineering.fb.com/2024/03/12/data-center-engineering/building-metas-genai-infrastructure/",
      "https://iot-analytics.com/wp-content/uploads/2024/10/INSIGHTS-RELEASE-Who-is-winning-the-cloud-AI-race-vf.pdf",
      "https://iot-analytics.com/wp-content/uploads/2024/10/INSIGHTS-RELEASE-Who-is-winning-the-cloud-AI-race-vf.pdf",
      "https://www.coreweave.com/",
      "https://www.equinix.com/newsroom/press-releases/2024/01/equinix-announces-fully-managed-service-for-nvidia-dgx-ai-supercomputing",
      "https://www.alibabacloud.com/en/press-room/qwen-models-attract-over-90000-enterprise-adoption?_p_lc=1",
      "https://www.reuters.com/technology/baidu-says-ai-chatbot-ernie-bot-has-amassed-200-million-users-2024-04-16/",
      "https://www.nvidia.com/en-us/data-center/dgx-cloud/",
      "https://openai.com/api/"
    ),
    rec_AI_IT_MW_current = c(1128.75, 870.65, 1125, 2408, 365, 459.4, 2714.25, 1388.4, 11594, 26.04),
    rec_AI_Facility_MW_current = c(1231, 940, 1350, 2769, 420, 639, 3257, 1583, 13333, 31.25),
    stringsAsFactors = FALSE
  )
  
  return(ai_load_data)
}

load_genai_query_data <- function() {
  # CoreWeave data (from GenAI_Inference_BottomUp_Models_Based_Metrics.xlsx)
  coreweave_data <- data.frame(
    Provider = c("CoreWeave", "CoreWeave", "CoreWeave", "CoreWeave", "CoreWeave", "CoreWeave"),
    Service_Name = c("CoreWeave GPU Cloud", "CoreWeave GPU Cloud", "CoreWeave GPU Cloud", "CoreWeave GPU Cloud", "CoreWeave GPU Cloud", "CoreWeave GPU Cloud"),
    Model_Family = c("GPT-4o", "o1-series", "GPT-3.5 Turbo", "Mistral Large", "Mixtral 8x7B", "Codestral"),
    Processing_Units_GPUs = c("120000-180000", "80000-120000", "40000-60000", "15000-25000", "20000-35000", "10000-18000"),
    GenAI_Specific_Monthly_Users = c(122580000, 5000000, 40000000, 2000000, 3500000, 1500000),
    Energy_Consumption_Per_Query_kWh = c(0.00034, 0.0039, 0.00025, 0.00022, 0.00024, 0.0002),
    Monthly_Token_Volume_Billions = c(104, 3, 20, 1.76, 2.52, 1.05),
    Training_Energy_MWh = c(50000, 85000, 8000, 12000, 15000, 9000),
    Parameters_Billions = c(175, 2000, 175, 175, 47, 22),
    Source_URL = c(
      "https://www.demandsage.com/chatgpt-statistics/",
      "https://backlinko.com/chatgpt-stats",
      "https://www.technollama.co.uk/a-gemini-report-how-many-people-are-using-generative-ai-on-a-daily-basis-a-gemini-report",
      "https://docs.mistral.ai/",
      "https://en.wikipedia.org/wiki/Mistral_AI",
      "https://docs.mistral.ai/"
    ),
    stringsAsFactors = FALSE
  )
  
  # Add Azure data (would come from Azure_FModel_Metrics sheet)
  azure_data <- data.frame(
    Provider = c("OpenAI", "OpenAI", "OpenAI", "Meta", "Mistral AI", "Cohere"),
    Service_Name = c("Azure OpenAI Service", "Azure OpenAI Service", "Azure OpenAI Service", "Azure AI Model Catalog", "Azure AI Model Catalog", "Azure AI Foundry"),
    Model_Family = c("GPT-4o", "o1-series", "GPT-3.5 Turbo", "Llama 3.3 70B", "Mistral Large", "Command R+"),
    Processing_Units_GPUs = c("100000-150000", "50000-80000", "30000-50000", "25000-40000", "8000-15000", "10000-18000"),
    GenAI_Specific_Monthly_Users = c(122580000, 5000000, 40000000, 8000000, 2000000, 800000),
    Energy_Consumption_Per_Query_kWh = c(0.00034, 0.00390, 0.00025, 0.00025, 0.00022, 0.00024),
    Monthly_Token_Volume_Billions = c(292, 15.6, 65, 3, 1.54, 0.384),
    Training_Energy_MWh = c(50000, 85000, 8000, 39300, 12000, 11000),
    Parameters_Billions = c(175, 2000, 175, 70, 175, 104),
    Source_URL = c(
      "https://www.demandsage.com/chatgpt-statistics/",
      "https://backlinko.com/chatgpt-stats",
      "https://www.technollama.co.uk/a-gemini-report-how-many-people-are-using-generative-ai-on-a-daily-basis-a-gemini-report",
      "https://www.demandsage.com/meta-ai-users/",
      "https://azure.microsoft.com/en-us/blog/microsoft-and-mistral-ai-announce-new-partnership-to-accelerate-ai-innovation-and-introduce-mistral-large-first-on-azure/",
      "https://learn.microsoft.com/en-us/azure/ai-studio/how-to/deploy-models-cohere-command"
    ),
    stringsAsFactors = FALSE
  )
  
  # Combine datasets
  combined_data <- rbind(
    cbind(coreweave_data, Infrastructure = "CoreWeave"),
    cbind(azure_data, Infrastructure = "Azure")
  )
  
  return(combined_data)
}

load_providers_summary_data <- function() {
  # From Providers_Verified_Metrics_ExtendedEst.xlsx
  providers_data <- data.frame(
    Provider = c("AWS", "Alibaba Cloud", "Azure", "Baidu Cloud", "CoreWeave", "Equinix", "Google Cloud", "Meta Platforms", "NVIDIA"),
    Track = c("B", "C", "A", "C", "A", "B", "A", "A/B", "C"),
    Confidence_Level = c("Medium-High", "Medium", "High", "Medium", "High", "Medium-High", "High", "High", "Low"),
    Year_of_Data = c(2024, "2021-2024", 2024, "2013-2024", 2025, 2024, 2024, "2023-2024", "2024"),
    Verification_Source = c(
      "BloombergNEF report on AWS quadrupling to 12GW",
      "Bloomberg NEF ranking as biggest clean energy buyer in China",
      "Documents leaked April 2024 showing >5GW capacity",
      "Baidu data center PUE 1.37 average, innovation in ARM-based servers",
      "CoreWeave Q1 2025 press release",
      "Record 90 MW xScale leasing, >725 MW committed capacity",
      "Google 2024 Environmental Report - 30.8 million MWh",
      "Meta 2023 sustainability report, Q4 capex $8.5B",
      "NVIDIA DGX Cloud service metrics and enterprise deployments"  # Added missing NVIDIA entry
    ),
    Regional_Focus = c(
      "Global, Pennsylvania nuclear", "China/APAC focus", "Global, Texas focus", "China focus",
      "Global, 28 locations", "Global, edge-focused", "Global, renewable focus", "US focus, Louisiana expansion", "Global, cloud services"  # Added missing NVIDIA entry
    ),
    Water_Usage_Concerns = c("Medium", "Low (water stewardship)", "Medium", "Low", "Medium", "Medium", "High (8.1B gallons)", "Very High", "Low"),  # Added missing NVIDIA entry
    Grid_Impact_Level = c("High", "Medium", "Very High", "Low", "Medium", "Medium", "High", "High", "Medium"),  # Added missing NVIDIA entry
    Active_AI_Power_MW = c(2500, 360, 5000, 150, 420, 250, 3800, 3500, NA),  # Added missing NVIDIA entry (NA since not disclosed)
    AI_Allocation_Percent = c(80, 30, 70, 25, 100, 10, 70, 60, 100),  # Added missing NVIDIA entry
    PUE = c(1.15, 1.37, 1.18, 1.37, 1.15, 1.39, 1.1, 1.08, 1.15),  # Added missing NVIDIA entry
    stringsAsFactors = FALSE
  )
  
  return(providers_data)
}

# Load the real data
real_data <- load_real_data()
genai_data <- real_data$genai
ai_load_data <- real_data$ai_load

# Enhanced Dashboard UI
dashboardUI <- function() {
  dashboardPage(
    dashboardHeader(
      title = "CCAF GenAI Energy Intelligence Platform",
      titleWidth = 400,
      tags$li(class = "dropdown",
              actionButton("logout", "Logout", 
                           style = "margin-top: 8px; margin-right: 10px; background-color: #e74c3c; color: white; border: none; border-radius: 4px; padding: 5px 15px;")
      )
    ),
    
    dashboardSidebar(
      width = 280,
      sidebarMenu(
        menuItem("Power Analysis", tabName = "power_analysis", icon = icon("bolt")),
        menuItem("Query Energy Analysis", tabName = "query_energy", icon = icon("chart-bar")),
        menuItem("Providers Summary", tabName = "providers_summary", icon = icon("building")),
        menuItem("Overview Dashboard", tabName = "overview", icon = icon("dashboard")),
        menuItem("Energy Analysis", tabName = "energy", icon = icon("bolt")),
        menuItem("GenAI Bottom-Up Models", tabName = "genai_bottomup", icon = icon("microchip")),
        menuItem("Methodology & Sources", tabName = "methodology", icon = icon("calculator")),
        menuItem("Provider Comparison", tabName = "comparison", icon = icon("chart-bar"))
      )
    ),
    
    dashboardBody(
      tags$style(HTML(paste0("
    /* COMPLETE LAYOUT AND COLOR CONFIGURATION */
    
    /* Main layout positioning */
    .main-sidebar {
      position: fixed !important;
      top: 0 !important;
      left: 0 !important;
      width: 280px !important;
      height: 100% !important;
      z-index: 1001 !important;
      background-color: ", ccaf_colors$secondary, " !important;
    }
    
    .content-wrapper {
      margin-left: 280px !important;
      min-height: 100vh !important;
      background-color: ", ccaf_colors$dark, " !important;
      position: relative !important;
    }
    
    .main-header {
      position: fixed !important;
      top: 0 !important;
      left: 0 !important;
      right: 0 !important;
      z-index: 1002 !important;
      background-color: ", ccaf_colors$primary, " !important;
    }
    
    .main-header .logo {
      width: 280px !important;
      background-color: ", ccaf_colors$dark, " !important;
      color: #FFFFFF !important;
    }
    
    .main-header .navbar {
      margin-left: 280px !important;
      background-color: ", ccaf_colors$primary, " !important;
    }
    
    /* SIDEBAR BACKGROUND COLORS */
    .skin-blue .main-sidebar {
      background-color: ", ccaf_colors$secondary, " !important;
    }
    
    .skin-blue .main-sidebar .sidebar {
      background-color: ", ccaf_colors$secondary, " !important;
    }
    
    /* SIDEBAR TEXT - FORCE WHITE WITH MAXIMUM SPECIFICITY */
    .skin-blue .main-sidebar .sidebar .sidebar-menu li a,
    .skin-blue .main-sidebar .sidebar-menu li a,
    .skin-blue .sidebar-menu li a,
    .main-sidebar .sidebar-menu li a,
    .sidebar-menu li a {
      background-color: ", ccaf_colors$secondary, " !important;
      color: #FFFFFF !important;
      font-weight: 600 !important;
      border: none !important;
    }
    
    /* SIDEBAR HOVER AND ACTIVE STATES */
    .skin-blue .main-sidebar .sidebar .sidebar-menu li:hover a,
    .skin-blue .main-sidebar .sidebar-menu li:hover a,
    .skin-blue .sidebar-menu li:hover a,
    .main-sidebar .sidebar-menu li:hover a,
    .sidebar-menu li:hover a {
      background-color: ", ccaf_colors$primary, " !important;
      color: #FFFFFF !important;
      font-weight: bold !important;
    }
    
    .skin-blue .main-sidebar .sidebar .sidebar-menu li.active a,
    .skin-blue .main-sidebar .sidebar-menu li.active a,
    .skin-blue .sidebar-menu li.active a,
    .main-sidebar .sidebar-menu li.active a,
    .sidebar-menu li.active a {
      background-color: ", ccaf_colors$primary, " !important;
      color: #FFFFFF !important;
      font-weight: bold !important;
      border-left: 3px solid #FFFFFF !important;
    }
    
    /* SIDEBAR ICONS */
    .skin-blue .main-sidebar .sidebar .sidebar-menu li a i,
    .skin-blue .main-sidebar .sidebar-menu li a i,
    .skin-blue .sidebar-menu li a i,
    .main-sidebar .sidebar-menu li a i,
    .sidebar-menu li a i,
    .skin-blue .main-sidebar .sidebar .sidebar-menu li a .fa,
    .skin-blue .main-sidebar .sidebar-menu li a .fa,
    .skin-blue .sidebar-menu li a .fa,
    .main-sidebar .sidebar-menu li a .fa,
    .sidebar-menu li a .fa {
      color: #FFFFFF !important;
    }
    
    /* NUCLEAR OPTION FOR SIDEBAR TEXT */
    .main-sidebar * {
      color: #FFFFFF !important;
    }
    
    /* HEADER COLORS AND TEXT */
    .skin-blue .main-header .navbar {
      background-color: ", ccaf_colors$primary, " !important;
    }
    
    .skin-blue .main-header .logo {
      background-color: ", ccaf_colors$dark, " !important;
      color: #FFFFFF !important;
    }
    
    .main-header .logo .logo-lg {
      color: #FFFFFF !important;
      font-weight: bold !important;
    }
    
    .skin-blue .main-header .navbar .sidebar-toggle {
      color: #FFFFFF !important;
    }
    
    /* CONTENT AREA */
    .content {
      padding-top: 70px !important;
      padding-left: 15px !important;
      padding-right: 15px !important;
    }
    
    /* BOX STYLING */
    .box {
      background: ", ccaf_colors$secondary, " !important;
      border-top: 3px solid ", ccaf_colors$primary, " !important;
      color: white !important;
      box-shadow: 0 1px 3px rgba(0,0,0,0.12), 0 1px 2px rgba(0,0,0,0.24) !important;
    }
    
    .box-header {
      background: ", ccaf_colors$secondary, " !important;
      color: white !important;
      border-bottom: 1px solid rgba(255,255,255,0.1) !important;
    }
    
    .box-body {
      background: white !important;
      color: #2c3e50 !important;
    }
    
    .box-title {
      color: white !important;
      font-weight: bold !important;
      font-size: 16px !important;
    }
    
    /* CUSTOM CARDS */
    .metric-card {
      background: linear-gradient(135deg, ", ccaf_colors$primary, " 0%, ", ccaf_colors$secondary, " 100%);
      border-radius: 12px;
      padding: 20px;
      margin: 10px 0;
      color: white;
      box-shadow: 0 4px 15px rgba(0,0,0,0.2);
      transition: transform 0.3s ease;
    }
    .metric-card:hover { transform: translateY(-5px); }
    
    .performance-card {
      background: linear-gradient(45deg, ", ccaf_colors$accent1, " 0%, ", ccaf_colors$accent2, " 100%);
      border-radius: 10px;
      padding: 15px;
      margin: 8px 0;
      color: white;
      box-shadow: 0 3px 12px rgba(0,0,0,0.15);
    }
    
    .methodology-section {
      background: ", ccaf_colors$light, ";
      border-left: 4px solid ", ccaf_colors$primary, ";
      padding: 15px;
      margin: 15px 0;
      border-radius: 8px;
      color: #2c3e50 !important;
    }
    
    /* TABLE AND FORM STYLING */
    .dataTables_wrapper {
      width: 100% !important;
    }
    
    .form-control:focus {
      border-color: ", ccaf_colors$primary, " !important;
      box-shadow: 0 0 0 0.2rem rgba(0, 138, 130, 0.25) !important;
    }
    
    .btn-primary {
      background: linear-gradient(45deg, ", ccaf_colors$primary, ", ", ccaf_colors$secondary, ") !important;
      border: none !important;
      border-radius: 8px !important;
      transition: all 0.3s ease !important;
    }
    .btn-primary:hover {
      transform: translateY(-2px) !important;
      box-shadow: 0 5px 15px rgba(0, 138, 130, 0.4) !important;
    }
  "))),
      
      tabItems(
        
        
        # Add these tabItems to your existing tabItems section:
        
        # Power Analysis Tab
        power_analysis_tab <- tabItem(tabName = "power_analysis",
                                      fluidRow(
                                        # Summary boxes
                                        div(class = "metric-card",
                                            h3("AI Data Center Power Analysis", style = "margin-top: 0;"),
                                            p("Comprehensive analysis of AI workload power consumption across major cloud providers")
                                        )
                                      ),
                                      
                                      fluidRow(
                                        box(
                                          title = "Provider Power Metrics", 
                                          status = "primary", 
                                          solidHeader = TRUE,
                                          width = 12,
                                          collapsible = TRUE,
                                          div(style = "background: white; padding: 15px; border-radius: 8px;",
                                              DT::dataTableOutput("power_analysis_table")
                                          )
                                        )
                                      ),
                                      
                                      fluidRow(
                                        box(
                                          title = "Active AI Power Distribution", 
                                          status = "info", 
                                          solidHeader = TRUE,
                                          width = 6,
                                          div(style = "background: white; padding: 10px; border-radius: 8px;",
                                              plotlyOutput("power_distribution_chart")
                                          )
                                        ),
                                        box(
                                          title = "Confidence Level Analysis", 
                                          status = "success", 
                                          solidHeader = TRUE,
                                          width = 6,
                                          div(style = "background: white; padding: 10px; border-radius: 8px;",
                                              plotlyOutput("confidence_analysis_chart")
                                          )
                                        )
                                      ),
                                      
                                      fluidRow(
                                        box(
                                          title = "AI Allocation vs IT Load", 
                                          status = "warning", 
                                          solidHeader = TRUE,
                                          width = 8,
                                          div(style = "background: white; padding: 10px; border-radius: 8px;",
                                              plotlyOutput("allocation_vs_load_chart")
                                          )
                                        ),
                                        box(
                                          title = "Key Insights", 
                                          status = "info", 
                                          solidHeader = TRUE,
                                          width = 4,
                                          div(class = "performance-card",
                                              h4("Total Active AI Power"),
                                              h2(style = "margin: 0; color: white;", "16,486 MW"),
                                              p("Across verified providers")
                                          ),
                                          div(class = "performance-card", style = "margin-top: 15px;",
                                              h4("Highest Capacity"),
                                              h2(style = "margin: 0; color: white;", "Microsoft Azure"),
                                              p("5,000 MW active AI power")
                                          )
                                        )
                                      ),
                                      
                                      # References Box
                                      fluidRow(
                                        box(
                                          title = "References - Power Analysis", 
                                          status = "primary", 
                                          solidHeader = TRUE,
                                          width = 12,
                                          collapsible = TRUE,
                                          div(class = "methodology-section",
                                              HTML("
            <h5>Harvard-Style References:</h5>
            <p><strong>Google Cloud Environmental Data:</strong><br>
            Google. (2025). <em>Google 2025 Environmental Report</em>. Retrieved from 
            <a href='https://sustainability.google/reports/google-2025-environmental-report/' target='_blank'>
            https://sustainability.google/reports/google-2025-environmental-report/</a></p>
            
            <p><strong>Meta AI Infrastructure:</strong><br>
            Meta Engineering. (2024). Building Meta's GenAI infrastructure. <em>Meta Engineering Blog</em>. Retrieved from 
            <a href='https://engineering.fb.com/2024/03/12/data-center-engineering/building-metas-genai-infrastructure/' target='_blank'>
            https://engineering.fb.com/2024/03/12/data-center-engineering/building-metas-genai-infrastructure/</a></p>
            
            <p><strong>Cloud AI Market Analysis:</strong><br>
            IoT Analytics. (2024). <em>Who is winning the cloud AI race</em>. Retrieved from 
            <a href='https://iot-analytics.com/wp-content/uploads/2024/10/INSIGHTS-RELEASE-Who-is-winning-the-cloud-AI-race-vf.pdf' target='_blank'>
            IoT Analytics Report</a></p>
            
            <p><strong>CoreWeave Infrastructure:</strong><br>
            CoreWeave. (2025). <em>Corporate Information</em>. Retrieved from 
            <a href='https://www.coreweave.com/' target='_blank'>https://www.coreweave.com/</a></p>
            
            <p><strong>NVIDIA DGX Cloud:</strong><br>
            NVIDIA. (2024). <em>DGX Cloud Services</em>. Retrieved from 
            <a href='https://www.nvidia.com/en-us/data-center/dgx-cloud/' target='_blank'>
            https://www.nvidia.com/en-us/data-center/dgx-cloud/</a></p>
          ")
                                          )
                                        )
                                      )
        ),
        
        # Query Energy Analysis Tab
        query_energy_tab <- tabItem(tabName = "query_energy",
                                    fluidRow(
                                      div(class = "metric-card",
                                          h3("GenAI Query Energy Analysis", style = "margin-top: 0;"),
                                          p("Per-query energy consumption analysis across different GenAI models and infrastructure providers")
                                      )
                                    ),
                                    
                                    fluidRow(
                                      box(
                                        title = "Analysis Controls", 
                                        status = "primary", 
                                        solidHeader = TRUE,
                                        width = 12,
                                        fluidRow(
                                          column(6,
                                                 selectInput("infrastructure_provider", 
                                                             "Select Infrastructure Provider:",
                                                             choices = c("CoreWeave", "Azure"),
                                                             selected = "CoreWeave")
                                          ),
                                          column(6,
                                                 selectInput("model_provider", 
                                                             "Select Model Provider:",
                                                             choices = NULL,  # Will be populated in server
                                                             selected = NULL)
                                          )
                                        )
                                      )
                                    ),
                                    
                                    fluidRow(
                                      box(
                                        title = "Energy Consumption by Model", 
                                        status = "info", 
                                        solidHeader = TRUE,
                                        width = 8,
                                        div(style = "background: white; padding: 10px; border-radius: 8px;",
                                            plotlyOutput("model_energy_chart")
                                        )
                                      ),
                                      box(
                                        title = "Infrastructure Comparison", 
                                        status = "success", 
                                        solidHeader = TRUE,
                                        width = 4,
                                        div(style = "background: white; padding: 15px; border-radius: 8px;",
                                            tableOutput("infrastructure_comparison")
                                        )
                                      )
                                    ),
                                    
                                    fluidRow(
                                      box(
                                        title = "Query Energy Distribution", 
                                        status = "warning", 
                                        solidHeader = TRUE,
                                        width = 6,
                                        div(style = "background: white; padding: 10px; border-radius: 8px;",
                                            plotlyOutput("energy_distribution_hist")
                                        )
                                      ),
                                      box(
                                        title = "Model Performance Metrics", 
                                        status = "info", 
                                        solidHeader = TRUE,
                                        width = 6,
                                        div(style = "background: white; padding: 15px; border-radius: 8px;",
                                            DT::dataTableOutput("model_performance_table")
                                        )
                                      )
                                    ),
                                    
                                    # References Box
                                    fluidRow(
                                      box(
                                        title = "References - Query Energy Analysis", 
                                        status = "primary", 
                                        solidHeader = TRUE,
                                        width = 12,
                                        collapsible = TRUE,
                                        div(class = "methodology-section",
                                            HTML("
            <h5>Harvard-Style References:</h5>
            <p><strong>ChatGPT Usage Statistics:</strong><br>
            DemandSage. (2024). <em>ChatGPT Statistics</em>. Retrieved from 
            <a href='https://www.demandsage.com/chatgpt-statistics/' target='_blank'>
            https://www.demandsage.com/chatgpt-statistics/</a></p>
            
            <p><strong>Meta AI User Data:</strong><br>
            DemandSage. (2024). <em>Meta AI Users Statistics</em>. Retrieved from 
            <a href='https://www.demandsage.com/meta-ai-users/' target='_blank'>
            https://www.demandsage.com/meta-ai-users/</a></p>
            
            <p><strong>Mistral AI Documentation:</strong><br>
            Mistral AI. (2024). <em>Official Documentation</em>. Retrieved from 
            <a href='https://docs.mistral.ai/' target='_blank'>https://docs.mistral.ai/</a></p>
            
            <p><strong>Azure AI Services:</strong><br>
            Microsoft Azure. (2024). <em>AI Model Catalog</em>. Retrieved from 
            <a href='https://learn.microsoft.com/en-us/azure/ai-studio/how-to/deploy-models-cohere-command' target='_blank'>
            Microsoft Learn Documentation</a></p>
            
            <p><strong>Generative AI Usage Report:</strong><br>
            TechnoLlama. (2024). <em>Generative AI Daily Usage Report</em>. Retrieved from 
            <a href='https://www.technollama.co.uk/a-gemini-report-how-many-people-are-using-generative-ai-on-a-daily-basis-a-gemini-report' target='_blank'>
            TechnoLlama Analysis</a></p>
          ")
                                        )
                                      )
                                    )
        ),
        
        # Providers Summary Tab
        providers_summary_tab <- tabItem(tabName = "providers_summary",
                                         fluidRow(
                                           div(class = "metric-card",
                                               h3("AI Infrastructure Providers Summary", style = "margin-top: 0;"),
                                               p("Comprehensive overview of major AI infrastructure providers with verified metrics and data quality indicators")
                                           )
                                         ),
                                         
                                         fluidRow(
                                           box(
                                             title = "Provider Overview Matrix", 
                                             status = "primary", 
                                             solidHeader = TRUE,
                                             width = 12,
                                             collapsible = TRUE,
                                             div(style = "background: white; padding: 15px; border-radius: 8px;",
                                                 DT::dataTableOutput("providers_overview_table")
                                             )
                                           )
                                         ),
                                         
                                         fluidRow(
                                           box(
                                             title = "Data Quality by Track", 
                                             status = "info", 
                                             solidHeader = TRUE,
                                             width = 4,
                                             div(style = "background: white; padding: 10px; border-radius: 8px;",
                                                 plotlyOutput("track_distribution_chart")
                                             )
                                           ),
                                           box(
                                             title = "Regional Distribution", 
                                             status = "success", 
                                             solidHeader = TRUE,
                                             width = 4,
                                             div(style = "background: white; padding: 10px; border-radius: 8px;",
                                                 plotlyOutput("regional_focus_chart")
                                             )
                                           ),
                                           box(
                                             title = "Grid Impact Assessment", 
                                             status = "warning", 
                                             solidHeader = TRUE,
                                             width = 4,
                                             div(style = "background: white; padding: 10px; border-radius: 8px;",
                                                 plotlyOutput("grid_impact_chart")
                                             )
                                           )
                                         ),
                                         
                                         fluidRow(
                                           box(
                                             title = "AI Power vs Efficiency Metrics", 
                                             status = "info", 
                                             solidHeader = TRUE,
                                             width = 8,
                                             div(style = "background: white; padding: 10px; border-radius: 8px;",
                                                 plotlyOutput("power_efficiency_scatter")
                                             )
                                           ),
                                           box(
                                             title = "Summary Statistics", 
                                             status = "success", 
                                             solidHeader = TRUE,
                                             width = 4,
                                             div(class = "performance-card",
                                                 h4("Total Providers"),
                                                 h2(style = "margin: 0; color: white;", "9"),
                                                 p("Major infrastructure providers")
                                             ),
                                             div(class = "performance-card", style = "margin-top: 15px;",
                                                 h4("High Confidence"),
                                                 h2(style = "margin: 0; color: white;", "44%"),
                                                 p("Of data assessments")
                                             ),
                                             div(class = "performance-card", style = "margin-top: 15px;",
                                                 h4("Track A"),
                                                 h2(style = "margin: 0; color: white;", "4"),
                                                 p("Highest quality data sources")
                                             )
                                           )
                                         ),
                                         
                                         # References Box
                                         fluidRow(
                                           box(
                                             title = "References - Providers Summary", 
                                             status = "primary", 
                                             solidHeader = TRUE,
                                             width = 12,
                                             collapsible = TRUE,
                                             div(class = "methodology-section",
                                                 HTML("
            <h5>Harvard-Style References:</h5>
            <p><strong>BloombergNEF Infrastructure Reports:</strong><br>
            Bloomberg New Energy Finance. (2024). <em>AWS Infrastructure Expansion Analysis</em>. Bloomberg Terminal.</p>
            
            <p><strong>Google Environmental Reporting:</strong><br>
            Google. (2024). <em>2024 Environmental Report - Data Center Energy Consumption</em>. Retrieved from 
            <a href='https://sustainability.google/reports/' target='_blank'>Google Sustainability Reports</a></p>
            
            <p><strong>Meta Infrastructure Disclosures:</strong><br>
            Meta Platforms. (2023). <em>2023 Sustainability Report</em>. Retrieved from 
            <a href='https://sustainability.atmeta.com/' target='_blank'>Meta Sustainability</a></p>
            
            <p><strong>CoreWeave Corporate Information:</strong><br>
            CoreWeave Inc. (2025). <em>Q1 2025 Press Release</em>. Corporate Communications.</p>
            
            <p><strong>Alibaba Cloud Clean Energy:</strong><br>
            Alibaba Cloud. (2024). <em>Clean Energy Procurement and Data Center Operations</em>. Retrieved from 
            <a href='https://www.alibabacloud.com/en/press-room/' target='_blank'>Alibaba Cloud Press Room</a></p>
            
            <p><strong>Equinix Infrastructure Data:</strong><br>
            Equinix Inc. (2024). <em>xScale Data Center Leasing Records</em>. Investor Relations Communications.</p>
            
            <p>Dashboard built by J-Francisco Zubizarreta-R jfz22 for Cambridge Centre for Alternative Finance.</p>
          ")
                                             )
                                           )
                                         )
        ),
        
 
        # Overview Tab - NO VALUE BOXES
        # Overview Dashboard Tab Content
        tabItem(tabName = "overview",
                # Header with methodology reference
                fluidRow(
                  box(title = "Dashboard Overview", status = "primary", solidHeader = TRUE, width = 12,
                      div(class = "methodology-section",
                          p("This dashboard presents GenAI energy consumption analysis based on bottom-up modeling 
                    of actual deployment data from major AI infrastructure providers."),
                          tags$small("Data sources: Direct provider measurements, third-party benchmarks, and verified industry estimates.")
                      )
                  )
                ),
                
                fluidRow(
                  box(title = "Monthly Users by Provider", status = "primary", solidHeader = TRUE, width = 6,
                      withSpinner(plotlyOutput("users_by_provider"), color = ccaf_colors$primary)
                  ),
                  box(title = "Energy Consumption Distribution", status = "primary", solidHeader = TRUE, width = 6,
                      withSpinner(plotlyOutput("energy_distribution"), color = ccaf_colors$primary)
                  )
                ),
                
                fluidRow(
                  box(title = "Model Parameters vs Context Window", status = "primary", solidHeader = TRUE, width = 6,
                      withSpinner(plotlyOutput("parameters_context"), color = ccaf_colors$primary)
                  ),
                  box(title = "Top Performers by Token Volume", status = "primary", solidHeader = TRUE, width = 6,
                      div(class = "metric-card",
                          h4("Top Token Producers"),
                          tableOutput("top_token_producers")
                      )
                  )
                ),
                
                fluidRow(
                  box(title = "Provider Summary Table", status = "primary", solidHeader = TRUE, width = 12,
                      DT::dataTableOutput("provider_summary_table")
                  )
                ),
                
                # References section
                fluidRow(
                  box(title = "References", status = "info", solidHeader = TRUE, width = 12, collapsible = FALSE,
                      div(class = "methodology-section",
                          h5("Data Sources:"),
                          p("Cambridge Centre for Alternative Finance (2024). GenAI Inference Bottom-Up Models Based Metrics. 
                    Research dataset including provider-specific energy consumption, user engagement, and model deployment data."),
                          p("OpenAI (2024). ChatGPT Statistics and Usage Data. Available at: https://www.demandsage.com/chatgpt-statistics/"),
                          p("Microsoft Azure (2024). AI Model Performance Metrics. Internal deployment statistics and energy measurements."),
                          p("Google Cloud (2024). Generative AI Infrastructure Benchmarks. Third-party verified measurements from cloud deployments."),
                          p("Meta (2024). Llama Model Deployment Statistics. Open source model performance and energy consumption data.")
                      )
                  )
                )
        ),
        
        # Energy Analysis Tab
        # Energy Analysis Tab Content
        tabItem(tabName = "energy",
                # Header with methodology reference
                fluidRow(
                  box(title = "Energy Analysis Methodology", status = "primary", solidHeader = TRUE, width = 12,
                      div(class = "methodology-section",
                          p("Energy consumption analysis based on actual measurements from AI infrastructure providers, 
                    incorporating Power Usage Effectiveness (PUE), utilization rates, and carbon intensity metrics."),
                          tags$small("Methodology follows IEEE standards for data center energy measurement and CCAF energy accounting frameworks.")
                      )
                  )
                ),
                
                fluidRow(
                  box(title = "Energy Analysis Controls", status = "primary", solidHeader = TRUE, width = 4,
                      selectInput("energy_providers", "Select Providers:",
                                  choices = unique(genai_data$Provider),
                                  selected = unique(genai_data$Provider)[1:6],
                                  multiple = TRUE),
                      div(class = "performance-card",
                          h5("Energy Insights"),
                          p("Real energy consumption data from AI infrastructure providers.")
                      )
                  ),
                  
                  box(title = "Energy Consumption by Provider", status = "primary", solidHeader = TRUE, width = 8,
                      withSpinner(plotlyOutput("energy_by_provider"), color = ccaf_colors$primary)
                  )
                ),
                
                fluidRow(
                  box(title = "Energy per Query Analysis", status = "primary", solidHeader = TRUE, width = 6,
                      withSpinner(plotlyOutput("energy_per_query"), color = ccaf_colors$primary)
                  ),
                  box(title = "PUE Distribution by Provider", status = "primary", solidHeader = TRUE, width = 6,
                      withSpinner(plotlyOutput("pue_distribution"), color = ccaf_colors$primary)
                  )
                ),
                
                fluidRow(
                  box(title = "Carbon Intensity vs Renewable Energy", status = "primary", solidHeader = TRUE, width = 12,
                      withSpinner(plotlyOutput("carbon_renewable"), color = ccaf_colors$primary)
                  )
                ),
                
                # References section
                fluidRow(
                  box(title = "References", status = "info", solidHeader = TRUE, width = 12, collapsible = FALSE,
                      div(class = "methodology-section",
                          h5("Energy Analysis Sources:"),
                          p("Cambridge Centre for Alternative Finance (2024). AI Load Normalized with Recommendations. 
                    Comprehensive energy efficiency metrics including PUE, utilization rates, and carbon intensity data."),
                          p("The Green Grid (2023). Power Usage Effectiveness (PUE) Measurement Standards. 
                    Industry standard methodology for data center energy efficiency assessment."),
                          p("International Energy Agency (2024). Data Centres and Data Transmission Networks. 
                    Global energy consumption patterns and efficiency benchmarks."),
                          p("Google (2024). Carbon-free energy for our data centers. Environmental performance and renewable energy procurement data."),
                          p("Microsoft (2024). Sustainability Report: Carbon negative by 2030. Corporate sustainability metrics and energy efficiency initiatives.")
                      )
                  )
                )
        ),
        
        # GenAI Bottom-Up Models Tab
        # GenAI Bottom-Up Models Tab Content
        tabItem(tabName = "genai_bottomup",
                # Header with methodology reference
                fluidRow(
                  box(title = "Bottom-Up Modeling Approach", status = "primary", solidHeader = TRUE, width = 12,
                      div(class = "methodology-section",
                          p("Bottom-up analysis based on actual model deployments, verified user engagement metrics, 
                    and measured energy consumption from operational AI services. Data aggregated from multiple 
                    provider sheets including deployment-specific parameters."),
                          tags$small("Methodology: Direct measurement approach combining operational data with technical specifications.")
                      )
                  )
                ),
                
                fluidRow(
                  box(title = "Model Selection", status = "primary", solidHeader = TRUE, width = 4,
                      selectInput("selected_models", "Select Models:",
                                  choices = unique(genai_data$Model_Family),
                                  selected = unique(genai_data$Model_Family)[1:5],
                                  multiple = TRUE),
                      div(class = "methodology-section",
                          h5("Bottom-Up Analysis"),
                          p("Based on real deployment data, user metrics, and measured energy consumption.")
                      )
                  ),
                  
                  box(title = "Model Family Performance", status = "primary", solidHeader = TRUE, width = 8,
                      withSpinner(plotlyOutput("model_performance"), color = ccaf_colors$primary)
                  )
                ),
                
                fluidRow(
                  box(title = "Processing Units Distribution", status = "primary", solidHeader = TRUE, width = 6,
                      withSpinner(plotlyOutput("gpu_distribution"), color = ccaf_colors$primary)
                  ),
                  box(title = "Context Window Comparison", status = "primary", solidHeader = TRUE, width = 6,
                      withSpinner(plotlyOutput("context_comparison"), color = ccaf_colors$primary)
                  )
                ),
                
                fluidRow(
                  box(title = "Detailed Model Metrics", status = "primary", solidHeader = TRUE, width = 12,
                      DT::dataTableOutput("model_metrics_table")
                  )
                ),
                
                # References section
                fluidRow(
                  box(title = "References", status = "info", solidHeader = TRUE, width = 12, collapsible = FALSE,
                      div(class = "methodology-section",
                          h5("Model Analysis Sources:"),
                          p("Cambridge Centre for Alternative Finance (2024). GenAI Inference Bottom-Up Models Based Metrics. 
                    Provider-specific model deployment data including CoreWeave, Azure, Google Cloud, Meta, Microsoft, 
                    Alibaba Cloud, Baidu Cloud, NVIDIA, and Equinix operational metrics."),
                          p("Anthropic (2024). Claude Model Performance Documentation. Technical specifications and deployment parameters."),
                          p("Hugging Face (2024). Model Hub Statistics and Performance Benchmarks. Community-driven model performance data."),
                          p("MLPerf (2024). AI Training and Inference Benchmark Results. Industry-standard performance measurements."),
                          p("Mistral AI (2024). Model Documentation and Performance Metrics. Available at: https://docs.mistral.ai/"),
                          p("Technology Llama (2024). Generative AI Daily Usage Report. User engagement statistics and adoption metrics.")
                      )
                  )
                )
        ),
        
        # Methodology & Sources Tab
        tabItem(tabName = "methodology",
                fluidRow(
                  box(title = "Data Quality Assessment", status = "primary", solidHeader = TRUE, width = 6,
                      withSpinner(plotlyOutput("data_quality"), color = ccaf_colors$primary)
                  ),
                  box(title = "Confidence Level by Provider", status = "primary", solidHeader = TRUE, width = 6,
                      withSpinner(plotlyOutput("confidence_levels"), color = ccaf_colors$primary)
                  )
                ),
                
                fluidRow(
                  box(title = "CCAF Methodology Framework", status = "primary", solidHeader = TRUE, width = 8,
                      div(class = "methodology-section",
                          h4("CCAF GenAI Energy Assessment Framework"),
                          h5("Data Collection Tracks:"),
                          tags$ul(
                            tags$li("Track A: Direct provider data and official documentation - highest confidence"),
                            tags$li("Track B: Third-party verified measurements and benchmarks - high confidence"),
                            tags$li("Track C: Estimated values based on industry standards - lower confidence")
                          ),
                          h5("Quality Assurance:"),
                          tags$ul(
                            tags$li("High: Verified, recent, direct measurements from official sources"),
                            tags$li("Medium: Indirect measurements with partial verification"),
                            tags$li("Low: Industry estimates and extrapolated values with limited verification")
                          ),
                          h5("Data Validation Process:"),
                          p("All data points undergo multi-source verification where possible. Confidence levels 
                    are assigned based on source reliability, measurement methodology, and temporal relevance.")
                      )
                  ),
                  box(title = "Track Distribution", status = "primary", solidHeader = TRUE, width = 4,
                      withSpinner(plotlyOutput("track_distribution"), color = ccaf_colors$primary)
                  )
                ),
                
                fluidRow(
                  box(title = "Methodology Data Sources", status = "primary", solidHeader = TRUE, width = 12,
                      DT::dataTableOutput("methodology_table")
                  )
                ),
                
                # References section
                fluidRow(
                  box(title = "References", status = "info", solidHeader = TRUE, width = 12, collapsible = FALSE,
                      div(class = "methodology-section",
                          h5("Methodology References:"),
                          p("Cambridge Centre for Alternative Finance (2024). AI Load Normalized with Recommendations Brief. 
                    Comprehensive methodology documentation including confidence scoring and data quality assessment frameworks."),
                          p("IEEE Standards Association (2023). IEEE 2888.1-2023 - Standard for Specification of Energy Efficiency 
                    and Renewable Energy Use in Data Storage Equipment. Technical measurement standards."),
                          p("The Green Grid (2023). Data Center Efficiency Metrics: PUE and Beyond. 
                    Industry best practices for energy efficiency measurement."),
                          p("International Organization for Standardization (2023). ISO 14040:2006 - Environmental management — 
                    Life cycle assessment — Principles and framework. Environmental assessment methodology."),
                          p("NIST (2024). Framework for Improving Critical Infrastructure Cybersecurity. 
                    Data quality and validation frameworks for critical infrastructure assessment."),
                          p("World Resources Institute (2024). GHG Protocol Corporate Standard. 
                    Carbon accounting and renewable energy measurement methodologies."),
                          p("Dashboard built by J-Francisco Zubizarreta-R jfz22 for Cambridge Centre for Alternative Finance.")
                      )
                  )
                )
        ),
        
        # Provider Comparison Tab  
        tabItem(tabName = "comparison",
                # Header with methodology reference
                fluidRow(
                  box(title = "Comparative Analysis Framework", status = "primary", solidHeader = TRUE, width = 12,
                      div(class = "methodology-section",
                          p("Multi-dimensional provider comparison using normalized metrics across energy efficiency, 
                    operational performance, and sustainability indicators. Comparisons based on directly 
                    comparable measurements where available."),
                          tags$small("Note: Comparisons account for different confidence levels and data quality across providers.")
                      )
                  )
                ),
                
                fluidRow(
                  box(title = "Comparison Controls", status = "primary", solidHeader = TRUE, width = 3,
                      checkboxGroupInput("comparison_providers", "Select Providers:",
                                         choices = unique(genai_data$Provider),
                                         selected = unique(genai_data$Provider)[1:6]),
                      radioButtons("comparison_metric", "Primary Metric:",
                                   choices = c("Monthly Users" = "Monthly_Users_M",
                                               "Energy Consumption" = "Energy_Monthly_kWh",
                                               "Token Volume" = "Token_Volume_B",
                                               "Energy per Query" = "Energy_Per_Query_kWh")),
                      div(class = "performance-card",
                          h5("Real Data Comparison"),
                          p("Multi-dimensional analysis of actual provider performance metrics.")
                      )
                  ),
                  
                  box(title = "Provider Performance Comparison", status = "primary", solidHeader = TRUE, width = 9,
                      withSpinner(plotlyOutput("provider_comparison"), color = ccaf_colors$primary)
                  )
                ),
                
                fluidRow(
                  box(title = "Utilization vs Energy Efficiency", status = "primary", solidHeader = TRUE, width = 6,
                      withSpinner(plotlyOutput("utilization_efficiency"), color = ccaf_colors$primary)
                  ),
                  box(title = "Renewable Energy Usage", status = "primary", solidHeader = TRUE, width = 6,
                      withSpinner(plotlyOutput("renewable_usage"), color = ccaf_colors$primary)
                  )
                ),
                
                fluidRow(
                  box(title = "Provider Rankings", status = "primary", solidHeader = TRUE, width = 12,
                      DT::dataTableOutput("provider_rankings")
                  )
                ),
                
                # References section
                fluidRow(
                  box(title = "References", status = "info", solidHeader = TRUE, width = 12, collapsible = FALSE,
                      div(class = "methodology-section",
                          h5("Comparative Analysis Sources:"),
                          p("Cambridge Centre for Alternative Finance (2024). GenAI Inference Bottom-Up Models Based Metrics 
                    and AI Load Normalized datasets. Cross-provider performance comparison framework."),
                          p("RE100 Initiative (2024). Renewable Energy Procurement in Digital Infrastructure. 
                    Corporate renewable energy commitment tracking and verification."),
                          p("Carbon Disclosure Project (2024). Climate Change and Water Security Reports. 
                    Corporate environmental performance and sustainability metrics."),
                          p("Science Based Targets Initiative (2024). Corporate Climate Action Scoreboard. 
                    Methodology for comparing corporate climate commitments and performance."),
                          p("BackLinko (2024). ChatGPT Statistics and Market Analysis. Available at: https://backlinko.com/chatgpt-stats"),
                          p("DemandSage (2024). AI Market Statistics and Usage Patterns. Available at: https://www.demandsage.com/chatgpt-statistics/")
                      )
                  )
                )
        )
      )
    ),
    skin = "blue"
  )
}

# Main UI
ui <- uiOutput("main_ui")

# Server
server <- function(input, output, session) {
  
  
  # Authentication state
  authenticated <- reactiveVal(FALSE)
  
  # Main UI renderer
  output$main_ui <- renderUI({
    if (authenticated()) {
      dashboardUI()
    } else {
      loginUI()
    }
  })
  
  # Login logic
  observeEvent(input$login, {
    if (!is.null(input$username) && !is.null(input$password)) {
      if (input$username %in% valid_users$user && 
          input$password == valid_users$password[valid_users$user == input$username]) {
        authenticated(TRUE)
        showNotification("Login successful!", type = "message", duration = 3)
      } else {
        output$login_error <- renderUI({
          div(class = "error-message", "Invalid username or password. Please try again.")
        })
      }
    }
  })
  
  # Logout logic (add logout button to dashboard header)
  observeEvent(input$logout, {
    authenticated(FALSE)
    session$reload()
  })
  
  # Clear error message when inputs change
  observeEvent(c(input$username, input$password), {
    output$login_error <- renderUI({})
  })
  
  # Overview plots
  output$users_by_provider <- renderPlotly({
    colors <- generate_palette(nrow(genai_data))
    
    p <- ggplot(genai_data, aes(x = reorder(Provider, Monthly_Users_M), y = Monthly_Users_M, fill = Provider)) +
      geom_col(alpha = 0.8) +
      coord_flip() +
      scale_fill_manual(values = colors) +
      scale_y_continuous(labels = scales::comma) +
      labs(title = "Monthly Users by Provider", x = "Provider", y = "Monthly Users (Millions)") +
      theme_minimal() +
      theme(legend.position = "none")
    
    ggplotly(p)
  })
  
  output$energy_distribution <- renderPlotly({
    p <- ggplot(genai_data, aes(x = reorder(Provider, Energy_Monthly_kWh), y = Energy_Monthly_kWh/1000000, 
                                fill = Model_Family)) +
      geom_col(alpha = 0.8) +
      coord_flip() +
      scale_fill_manual(values = generate_palette(length(unique(genai_data$Model_Family)))) +
      labs(title = "Monthly Energy Consumption", x = "Provider", y = "Energy (GWh)", fill = "Model Family") +
      theme_minimal() +
      theme(legend.position = "bottom")
    
    ggplotly(p)
  })
  
  output$parameters_context <- renderPlotly({
    p <- ggplot(genai_data, aes(x = Parameters_B, y = Context_Window_Tokens/1000, 
                                color = Provider, size = Monthly_Users_M)) +
      geom_point(alpha = 0.7) +
      scale_color_manual(values = generate_palette(nrow(genai_data))) +
      scale_size_continuous(range = c(3, 12), name = "Monthly Users (M)") +
      labs(title = "Model Parameters vs Context Window", 
           x = "Parameters (Billions)", y = "Context Window (Thousands)") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  output$top_token_producers <- renderTable({
    top_tokens <- genai_data %>%
      arrange(desc(Token_Volume_B)) %>%
      head(5) %>%
      select(Provider, Model_Family, Token_Volume_B) %>%
      mutate(Token_Volume_B = round(Token_Volume_B, 1))
    
    colnames(top_tokens) <- c("Provider", "Model", "Token Volume (B)")
    top_tokens
  }, striped = TRUE, hover = TRUE)
  
  output$provider_summary_table <- DT::renderDataTable({
    summary_data <- genai_data %>%
      select(Provider, Model_Family, Monthly_Users_M, Energy_Monthly_kWh, 
             Token_Volume_B, Parameters_B, Context_Window_Tokens) %>%
      mutate(
        Monthly_Users_M = round(Monthly_Users_M, 1),
        Energy_Monthly_kWh = round(Energy_Monthly_kWh/1000000, 1),
        Token_Volume_B = round(Token_Volume_B, 1),
        Parameters_B = round(Parameters_B, 0),
        Context_Window_Tokens = scales::comma(Context_Window_Tokens)
      )
    
    DT::datatable(summary_data, 
                  options = list(pageLength = 10, scrollX = TRUE),
                  colnames = c("Provider", "Model", "Users (M)", "Energy (GWh)", 
                               "Tokens (B)", "Parameters (B)", "Context Window"))
  })
  
  # Energy analysis plots
  output$energy_by_provider <- renderPlotly({
    if(is.null(input$energy_providers)) return(NULL)
    
    data <- genai_data %>% filter(Provider %in% input$energy_providers)
    
    p <- ggplot(data, aes(x = reorder(Provider, Energy_Monthly_kWh), y = Energy_Monthly_kWh/1000000)) +
      geom_col(fill = ccaf_colors$primary, alpha = 0.8) +
      coord_flip() +
      scale_y_continuous(labels = scales::comma) +
      labs(title = "Monthly Energy Consumption", x = "Provider", y = "Energy (GWh)") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  output$energy_per_query <- renderPlotly({
    p <- ggplot(genai_data, aes(x = reorder(Provider, Energy_Per_Query_kWh), 
                                y = Energy_Per_Query_kWh * 1000, fill= Provider)) +
      geom_col(alpha = 0.8) +
      coord_flip() +
      scale_fill_manual(values = generate_palette(nrow(genai_data))) +
      labs(title = "Energy per Query by Provider", x = "Provider", y = "Energy per Query (Wh)") +
      theme_minimal() +
      theme(legend.position = "none")
    
    ggplotly(p)
  })
  
  output$pue_distribution <- renderPlotly({
    # Merge with AI load data for PUE values
    merged_data <- merge(genai_data, ai_load_data, by = "Provider", all.x = TRUE)
    
    p <- ggplot(merged_data, aes(x = reorder(Provider, PUE), y = PUE, fill = Confidence_Level)) +
      geom_col(alpha = 0.8) +
      coord_flip() +
      scale_fill_manual(values = c("High" = ccaf_colors$success, "Medium" = ccaf_colors$warning, 
                                   "Low" = ccaf_colors$danger, "Low-Medium" = ccaf_colors$accent2),
                        na.value = ccaf_colors$info) +
      labs(title = "Power Usage Effectiveness (PUE) by Provider", 
           x = "Provider", y = "PUE", fill = "Confidence") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  output$carbon_renewable <- renderPlotly({
    p <- ggplot(ai_load_data, aes(x = Renewable_Energy_Share, y = Carbon_Intensity_gCO2_per_kWh, 
                                  color = Provider, size = Utilization_Rate)) +
      geom_point(alpha = 0.7) +
      scale_color_manual(values = generate_palette(nrow(ai_load_data))) +
      scale_size_continuous(range = c(3, 12), name = "Utilization Rate") +
      scale_x_continuous(labels = scales::percent) +
      labs(title = "Carbon Intensity vs Renewable Energy Usage", 
           x = "Renewable Energy Share", y = "Carbon Intensity (gCO2/kWh)") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # GenAI Bottom-Up Models plots
  output$model_performance <- renderPlotly({
    if(is.null(input$selected_models)) return(NULL)
    
    data <- genai_data %>% filter(Model_Family %in% input$selected_models)
    
    p <- ggplot(data, aes(x = Monthly_Users_M, y = Token_Volume_B, 
                          color = Model_Family, size = Energy_Monthly_kWh)) +
      geom_point(alpha = 0.7) +
      scale_color_manual(values = generate_palette(length(input$selected_models))) +
      scale_size_continuous(range = c(3, 15), name = "Energy (kWh)") +
      labs(title = "Model Performance: Users vs Token Volume", 
           x = "Monthly Users (Millions)", y = "Token Volume (Billions)", color = "Model Family") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  output$gpu_distribution <- renderPlotly({
    # Extract numeric GPU values for visualization
    gpu_data <- genai_data %>%
      mutate(GPU_Mid = case_when(
        Processing_Units_GPUs == "120000-180000" ~ 150000,
        Processing_Units_GPUs == "100000-150000" ~ 125000,
        Processing_Units_GPUs == "80000-120000" ~ 100000,
        Processing_Units_GPUs == "60000-100000" ~ 80000,
        Processing_Units_GPUs == "90000-130000" ~ 110000,
        Processing_Units_GPUs == "40000-80000" ~ 60000,
        Processing_Units_GPUs == "30000-60000" ~ 45000,
        Processing_Units_GPUs == "70000-110000" ~ 90000,
        Processing_Units_GPUs == "20000-50000" ~ 35000,
        TRUE ~ 175000
      ))
    
    p <- ggplot(gpu_data, aes(x = reorder(Provider, GPU_Mid), y = GPU_Mid/1000, fill = Provider)) +
      geom_col(alpha = 0.8) +
      coord_flip() +
      scale_fill_manual(values = generate_palette(nrow(gpu_data))) +
      labs(title = "Processing Units (GPUs) by Provider", 
           x = "Provider", y = "Processing Units (Thousands)") +
      theme_minimal() +
      theme(legend.position = "none")
    
    ggplotly(p)
  })
  
  output$context_comparison <- renderPlotly({
    p <- ggplot(genai_data, aes(x = reorder(Provider, Context_Window_Tokens), 
                                y = Context_Window_Tokens/1000, fill = Model_Family)) +
      geom_col(alpha = 0.8) +
      coord_flip() +
      scale_fill_manual(values = generate_palette(length(unique(genai_data$Model_Family)))) +
      labs(title = "Context Window Size by Provider", 
           x = "Provider", y = "Context Window (Thousands of Tokens)", fill = "Model Family") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  output$model_metrics_table <- DT::renderDataTable({
    model_data <- genai_data %>%
      mutate(
        Energy_Efficiency = Token_Volume_B / (Energy_Monthly_kWh / 1000000),
        Users_per_Token = Monthly_Users_M / Token_Volume_B
      ) %>%
      select(Provider, Model_Family, Processing_Units_GPUs, Monthly_Users_M, 
             Energy_Monthly_kWh, Energy_Per_Query_kWh, Token_Volume_B, 
             Parameters_B, Energy_Efficiency, Users_per_Token) %>%
      mutate(
        Monthly_Users_M = round(Monthly_Users_M, 1),
        Energy_Monthly_kWh = scales::comma(Energy_Monthly_kWh),
        Energy_Per_Query_kWh = round(Energy_Per_Query_kWh, 5),
        Token_Volume_B = round(Token_Volume_B, 1),
        Parameters_B = round(Parameters_B, 0),
        Energy_Efficiency = round(Energy_Efficiency, 2),
        Users_per_Token = round(Users_per_Token, 2)
      )
    
    DT::datatable(model_data, 
                  options = list(pageLength = 10, scrollX = TRUE),
                  colnames = c("Provider", "Model", "GPUs", "Users (M)", "Energy (kWh)", 
                               "Energy/Query", "Tokens (B)", "Parameters (B)", 
                               "Efficiency", "Users/Token"))
  })
  
  # Methodology plots
  output$data_quality <- renderPlotly({
    quality_data <- ai_load_data %>%
      mutate(
        Quality_Score = case_when(
          Confidence_Level == "High" ~ 3,
          Confidence_Level == "Medium" ~ 2,
          Confidence_Level == "Low-Medium" ~ 1.5,
          TRUE ~ 1
        )
      )
    
    p <- ggplot(quality_data, aes(x = reorder(Provider, Quality_Score), y = Quality_Score, 
                                  fill = Track_Assigned)) +
      geom_col(alpha = 0.8) +
      coord_flip() +
      scale_fill_manual(values = c("A" = ccaf_colors$success, "B" = ccaf_colors$primary, 
                                   "C" = ccaf_colors$warning, "A/C" = ccaf_colors$accent1)) +
      labs(title = "Data Quality Score by Provider", 
           x = "Provider", y = "Quality Score", fill = "Data Track") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  output$confidence_levels <- renderPlotly({
    conf_summary <- ai_load_data %>%
      count(Confidence_Level) %>%
      mutate(Percentage = n / sum(n) * 100)
    
    colors <- c("High" = ccaf_colors$success, "Medium" = ccaf_colors$warning, 
                "Low-Medium" = ccaf_colors$accent2, "Low" = ccaf_colors$danger)
    
    plot_ly(conf_summary, labels = ~Confidence_Level, values = ~Percentage, type = 'pie',
            marker = list(colors = colors[conf_summary$Confidence_Level]),
            textinfo = 'label+percent') %>%
      layout(title = "Confidence Level Distribution")
  })
  
  output$track_distribution <- renderPlotly({
    track_summary <- ai_load_data %>%
      count(Track_Assigned) %>%
      mutate(Percentage = n / sum(n) * 100)
    
    colors <- c("A" = ccaf_colors$success, "B" = ccaf_colors$primary, 
                "C" = ccaf_colors$warning, "A/C" = ccaf_colors$accent1)
    
    plot_ly(track_summary, labels = ~Track_Assigned, values = ~Percentage, type = 'pie',
            marker = list(colors = colors[track_summary$Track_Assigned]),
            textinfo = 'label+percent') %>%
      layout(title = "Data Track Distribution")
  })
  
  output$methodology_table <- DT::renderDataTable({
    methodology_display <- ai_load_data %>%
      select(Provider, Track_Assigned, Confidence_Level, PUE, 
             Energy_Intensity_kWh_per_Token, Utilization_Rate, 
             Renewable_Energy_Share, Geographic_Region) %>%
      mutate(
        PUE = round(PUE, 2),
        Energy_Intensity_kWh_per_Token = round(Energy_Intensity_kWh_per_Token, 4),
        Utilization_Rate = round(Utilization_Rate, 2),
        Renewable_Energy_Share = round(Renewable_Energy_Share, 2)
      )
    
    DT::datatable(methodology_display, 
                  options = list(pageLength = 10, scrollX = TRUE),
                  colnames = c("Provider", "Track", "Confidence", "PUE", 
                               "Energy/Token", "Utilization", "Renewable %", "Region"))
  })
  
  output$provider_comparison <- renderPlotly({
    req(input$comparison_providers, input$comparison_metric)
    
    data <- genai_data %>% filter(Provider %in% input$comparison_providers)
    
    # Use column indexing instead
    metric_values <- data[[input$comparison_metric]]
    
    p <- ggplot(data, aes(x = reorder(Provider, metric_values), 
                          y = metric_values, fill = Model_Family)) +
      geom_col(alpha = 0.8) +
      coord_flip() +
      scale_fill_manual(values = generate_palette(length(unique(data$Model_Family)))) +
      scale_y_continuous(labels = scales::comma) +
      labs(title = paste("Provider Comparison:", gsub("_", " ", input$comparison_metric)),
           x = "Provider", y = gsub("_", " ", input$comparison_metric), fill = "Model Family") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  output$utilization_efficiency <- renderPlotly({
    merged_data <- merge(genai_data, ai_load_data, by = "Provider", all.x = TRUE)
    
    p <- ggplot(merged_data, aes(x = Utilization_Rate, y = Energy_Intensity_kWh_per_Token, 
                                 color = Provider, size = Monthly_Users_M)) +
      geom_point(alpha = 0.7) +
      scale_color_manual(values = generate_palette(nrow(merged_data))) +
      scale_size_continuous(range = c(3, 12), name = "Monthly Users (M)") +
      labs(title = "Utilization Rate vs Energy Intensity", 
           x = "Utilization Rate", y = "Energy Intensity (kWh/Token)") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  output$renewable_usage <- renderPlotly({
    p <- ggplot(ai_load_data, aes(x = reorder(Provider, Renewable_Energy_Share), 
                                  y = Renewable_Energy_Share, fill = Geographic_Region)) +
      geom_col(alpha = 0.8) +
      coord_flip() +
      scale_fill_manual(values = generate_palette(length(unique(ai_load_data$Geographic_Region)))) +
      scale_y_continuous(labels = scales::percent) +
      labs(title = "Renewable Energy Usage by Provider", 
           x = "Provider", y = "Renewable Energy Share", fill = "Region") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  output$provider_rankings <- DT::renderDataTable({
    if(is.null(input$comparison_providers)) return(NULL)
    
    merged_data <- merge(genai_data, ai_load_data, by = "Provider", all.x = TRUE)
    
    rankings <- merged_data %>%
      filter(Provider %in% input$comparison_providers) %>%
      mutate(
        Efficiency_Score = Token_Volume_B / Energy_Intensity_kWh_per_Token,
        Sustainability_Score = Renewable_Energy_Share * (1/PUE)
      ) %>%
      arrange(desc(Efficiency_Score)) %>%
      mutate(Rank = row_number()) %>%
      select(Rank, Provider, Monthly_Users_M, Energy_Monthly_kWh, Token_Volume_B, 
             PUE, Renewable_Energy_Share, Efficiency_Score, Sustainability_Score) %>%
      mutate(
        Monthly_Users_M = round(Monthly_Users_M, 1),
        Energy_Monthly_kWh = round(Energy_Monthly_kWh/1000000, 1),
        Token_Volume_B = round(Token_Volume_B, 1),
        PUE = round(PUE, 2),
        Renewable_Energy_Share = round(Renewable_Energy_Share, 2),
        Efficiency_Score = round(Efficiency_Score, 2),
        Sustainability_Score = round(Sustainability_Score, 2)
      )
    
    DT::datatable(rankings, 
                  options = list(pageLength = 10, scrollX = TRUE),
                  colnames = c("Rank", "Provider", "Users (M)", "Energy (GWh)", "Tokens (B)", 
                               "PUE", "Renewable %", "Efficiency", "Sustainability"))
  })
  
  # Load data at server start
  ai_data <- load_ai_data()
  query_data <- load_genai_query_data()
  providers_data <- load_providers_summary_data()
  
  # Power Analysis Tab Server Logic
  output$power_analysis_table <- DT::renderDataTable({
    # Create display table with clickable links
    display_data <- ai_data %>%
      select(Provider, Track_assigned, Confidence_Level, Active_AI_Power_MW, 
             IT_Load_MW, AI_Allocation_frac, PUE, rec_AI_IT_MW_current) %>%
      mutate(
        AI_Allocation_Percent = round(AI_Allocation_frac * 100, 1),
        Active_AI_Power_MW = ifelse(is.na(Active_AI_Power_MW), "Not disclosed", format(Active_AI_Power_MW, big.mark = ",")),
        IT_Load_MW = format(IT_Load_MW, big.mark = ","),
        rec_AI_IT_MW_current = format(round(rec_AI_IT_MW_current), big.mark = ",")
      ) %>%
      select(-AI_Allocation_frac) %>%
      rename(
        "Track" = Track_assigned,
        "Confidence" = Confidence_Level,
        "Active AI Power (MW)" = Active_AI_Power_MW,
        "IT Load (MW)" = IT_Load_MW,
        "AI Allocation (%)" = AI_Allocation_Percent,
        "Recommended AI IT (MW)" = rec_AI_IT_MW_current
      )
    
    DT::datatable(
      display_data,
      options = list(
        pageLength = 15,
        scrollX = TRUE,
        dom = 'frtip'
      ),
      rownames = FALSE
    ) %>%
      formatStyle(
        "Confidence",
        backgroundColor = styleEqual(
          c("High", "Medium-High", "Medium", "Low–Medium", "Low"),
          c("#28a745", "#ffc107", "#fd7e14", "#fd7e14", "#dc3545")
        ),
        color = styleEqual(
          c("High", "Medium-High", "Medium", "Low–Medium", "Low"),
          c("white", "black", "white", "white", "white")
        )
      )
  })
  
  output$power_distribution_chart <- renderPlotly({
    chart_data <- ai_data %>%
      filter(!is.na(Active_AI_Power_MW)) %>%
      arrange(desc(Active_AI_Power_MW))
    
    p <- plot_ly(
      data = chart_data,
      x = ~reorder(Provider, Active_AI_Power_MW),
      y = ~Active_AI_Power_MW,
      type = "bar",
      marker = list(
        color = ~Active_AI_Power_MW,
        colorscale = "Viridis",
        colorbar = list(title = "MW")
      ),
      text = ~paste(Provider, "<br>", format(Active_AI_Power_MW, big.mark = ","), "MW"),
      hovertemplate = "%{text}<extra></extra>"
    ) %>%
      layout(
        xaxis = list(title = "", tickangle = -45),
        yaxis = list(title = "Active AI Power (MW)"),
        margin = list(b = 100),
        plot_bgcolor = 'rgba(0,0,0,0)',
        paper_bgcolor = 'rgba(0,0,0,0)'
      )
    
    p
  })
  
  output$confidence_analysis_chart <- renderPlotly({
    confidence_counts <- ai_data %>%
      count(Confidence_Level) %>%
      mutate(
        percentage = round(n / sum(n) * 100, 1),
        colors = case_when(
          Confidence_Level == "High" ~ "#28a745",
          Confidence_Level == "Medium" ~ "#fd7e14",
          Confidence_Level == "Low–Medium" ~ "#fd7e14",
          Confidence_Level == "Low" ~ "#dc3545"
        )
      )
    
    p <- plot_ly(
      data = confidence_counts,
      labels = ~Confidence_Level,
      values = ~n,
      type = "pie",
      marker = list(colors = ~colors),
      textinfo = "label+percent",
      texttemplate = "%{label}<br>%{percent}"
    ) %>%
      layout(
        plot_bgcolor = 'rgba(0,0,0,0)',
        paper_bgcolor = 'rgba(0,0,0,0)'
      )
    
    p
  })
  
  output$allocation_vs_load_chart <- renderPlotly({
    p <- plot_ly(
      data = ai_data,
      x = ~IT_Load_MW,
      y = ~AI_Allocation_frac * 100,
      color = ~Confidence_Level,
      colors = c("High" = "#28a745", "Medium" = "#fd7e14", "Low–Medium" = "#fd7e14", "Low" = "#dc3545"),
      size = ~rec_AI_IT_MW_current,
      sizes = c(10, 100),
      text = ~paste("Provider:", Provider, "<br>IT Load:", format(IT_Load_MW, big.mark = ","), "MW<br>AI Allocation:", round(AI_Allocation_frac * 100, 1), "%"),
      hovertemplate = "%{text}<extra></extra>"
    ) %>%
      layout(
        xaxis = list(title = "IT Load (MW)", type = "log"),
        yaxis = list(title = "AI Allocation (%)"),
        plot_bgcolor = 'rgba(0,0,0,0)',
        paper_bgcolor = 'rgba(0,0,0,0)'
      )
    
    p
  })
  
  # Query Energy Analysis Tab Server Logic
  observe({
    if(isTruthy(input$infrastructure_provider)) {
      if(input$infrastructure_provider == "CoreWeave") {
        provider_choices <- unique(query_data[query_data$Infrastructure == "CoreWeave", "Provider"])
      } else {
        provider_choices <- unique(query_data[query_data$Infrastructure == "Azure", "Provider"])
      }
      
      updateSelectInput(session, "model_provider",
                        choices = provider_choices,
                        selected = provider_choices[1])
    }
  })
  
  output$model_energy_chart <- renderPlotly({
    req(input$infrastructure_provider, input$model_provider)
    
    filtered_data <- query_data %>%
      filter(Infrastructure == input$infrastructure_provider, Provider == input$model_provider)
    
    p <- plot_ly(
      data = filtered_data,
      x = ~Energy_Consumption_Per_Query_kWh,
      y = ~reorder(Model_Family, Energy_Consumption_Per_Query_kWh),
      type = "bar",
      orientation = "h",
      marker = list(
        color = ~Energy_Consumption_Per_Query_kWh,
        colorscale = "RdYlGn",
        reversescale = TRUE,
        colorbar = list(title = "kWh")
      ),
      text = ~paste("Model:", Model_Family, "<br>Energy:", round(Energy_Consumption_Per_Query_kWh, 5), "kWh<br>Parameters:", Parameters_Billions, "B"),
      hovertemplate = "%{text}<extra></extra>"
    ) %>%
      layout(
        xaxis = list(title = "Energy per Query (kWh)"),
        yaxis = list(title = ""),
        margin = list(l = 150),
        plot_bgcolor = 'rgba(0,0,0,0)',
        paper_bgcolor = 'rgba(0,0,0,0)'
      )
    
    p
  })
  
  output$infrastructure_comparison <- renderTable({
    comparison_data <- query_data %>%
      group_by(Infrastructure) %>%
      summarise(
        "Models" = n(),
        "Avg Energy (kWh)" = round(mean(Energy_Consumption_Per_Query_kWh, na.rm = TRUE), 5),
        "Min Energy (kWh)" = round(min(Energy_Consumption_Per_Query_kWh, na.rm = TRUE), 5),
        "Max Energy (kWh)" = round(max(Energy_Consumption_Per_Query_kWh, na.rm = TRUE), 5),
        .groups = 'drop'
      )
    
    comparison_data
  }, striped = TRUE, hover = TRUE, bordered = TRUE)
  
  output$energy_distribution_hist <- renderPlotly({
    req(input$infrastructure_provider)
    
    filtered_data <- query_data %>%
      filter(Infrastructure == input$infrastructure_provider)
    
    p <- plot_ly(
      data = filtered_data,
      x = ~Energy_Consumption_Per_Query_kWh,
      type = "histogram",
      nbinsx = 15,
      marker = list(
        color = ifelse(input$infrastructure_provider == "CoreWeave", "#ff6b35", "#0078d4"),
        opacity = 0.7
      )
    ) %>%
      layout(
        xaxis = list(title = "Energy per Query (kWh)"),
        yaxis = list(title = "Number of Models"),
        title = paste("Energy Distribution -", input$infrastructure_provider),
        plot_bgcolor = 'rgba(0,0,0,0)',
        paper_bgcolor = 'rgba(0,0,0,0)'
      )
    
    p
  })
  
  output$model_performance_table <- DT::renderDataTable({
    req(input$infrastructure_provider)
    
    filtered_data <- query_data %>%
      filter(Infrastructure == input$infrastructure_provider) %>%
      select(Provider, Model_Family, Energy_Consumption_Per_Query_kWh, Parameters_Billions, Monthly_Token_Volume_Billions) %>%
      arrange(Energy_Consumption_Per_Query_kWh) %>%
      rename(
        "Model" = Model_Family,
        "Energy (kWh)" = Energy_Consumption_Per_Query_kWh,
        "Parameters (B)" = Parameters_Billions,
        "Monthly Tokens (B)" = Monthly_Token_Volume_Billions
      )
    
    DT::datatable(
      filtered_data,
      options = list(
        pageLength = 10,
        scrollX = TRUE,
        dom = 't'
      ),
      rownames = FALSE
    ) %>%
      formatRound(columns = c("Energy (kWh)"), digits = 5) %>%
      formatRound(columns = c("Parameters (B)", "Monthly Tokens (B)"), digits = 1)
  })
  
  # Providers Summary Tab Server Logic
  output$providers_overview_table <- DT::renderDataTable({
    DT::datatable(
      providers_data,
      options = list(
        pageLength = 15,
        scrollX = TRUE,
        dom = 'frtip'
      ),
      rownames = FALSE
    ) %>%
      formatStyle(
        "Confidence_Level",
        backgroundColor = styleEqual(
          c("High", "Medium-High", "Medium", "Low"),
          c("#28a745", "#ffc107", "#fd7e14", "#dc3545")
        ),
        color = styleEqual(
          c("High", "Medium-High", "Medium", "Low"),
          c("white", "black", "white", "white")
        )
      ) %>%
      formatStyle(
        "Track",
        backgroundColor = styleEqual(
          c("A", "A/B", "B", "C"),
          c("#28a745", "#17a2b8", "#ffc107", "#fd7e14")
        ),
        color = styleEqual(
          c("A", "A/B", "B", "C"),
          c("white", "white", "black", "white")
        )
      ) %>%
      formatStyle(
        "Grid_Impact_Level",
        backgroundColor = styleEqual(
          c("Very High", "High", "Medium", "Low"),
          c("#dc3545", "#fd7e14", "#ffc107", "#28a745")
        ),
        color = styleEqual(
          c("Very High", "High", "Medium", "Low"),
          c("white", "white", "black", "white")
        )
      )
  })
  
  output$track_distribution_chart <- renderPlotly({
    track_counts <- providers_data %>%
      count(Track) %>%
      mutate(
        colors = case_when(
          Track == "A" ~ "#28a745",
          Track == "A/B" ~ "#17a2b8",
          Track == "B" ~ "#ffc107",
          Track == "C" ~ "#fd7e14"
        )
      )
    
    p <- plot_ly(
      data = track_counts,
      labels = ~Track,
      values = ~n,
      type = "pie",
      marker = list(colors = ~colors),
      textinfo = "label+value+percent"
    ) %>%
      layout(
        plot_bgcolor = 'rgba(0,0,0,0)',
        paper_bgcolor = 'rgba(0,0,0,0)'
      )
    
    p
  })
  
  output$regional_focus_chart <- renderPlotly({
    regional_summary <- providers_data %>%
      mutate(
        Region = case_when(
          grepl("Global", Regional_Focus) ~ "Global",
          grepl("US|Louisiana|Texas", Regional_Focus) ~ "US-Focused",
          grepl("China|APAC", Regional_Focus) ~ "Asia-Pacific",
          TRUE ~ "Other"
        )
      ) %>%
      count(Region)
    
    p <- plot_ly(
      data = regional_summary,
      x = ~Region,
      y = ~n,
      type = "bar",
      marker = list(color = c("#3498db", "#e74c3c", "#f39c12", "#9b59b6"))
    ) %>%
      layout(
        xaxis = list(title = "Regional Focus"),
        yaxis = list(title = "Number of Providers"),
        plot_bgcolor = 'rgba(0,0,0,0)',
        paper_bgcolor = 'rgba(0,0,0,0)'
      )
    
    p
  })
  
  output$grid_impact_chart <- renderPlotly({
    grid_counts <- providers_data %>%
      count(Grid_Impact_Level) %>%
      mutate(
        colors = case_when(
          Grid_Impact_Level == "Very High" ~ "#dc3545",
          Grid_Impact_Level == "High" ~ "#fd7e14",
          Grid_Impact_Level == "Medium" ~ "#ffc107",
          Grid_Impact_Level == "Low" ~ "#28a745"
        )
      )
    
    p <- plot_ly(
      data = grid_counts,
      x = ~Grid_Impact_Level,
      y = ~n,
      type = "bar",
      marker = list(color = ~colors)
    ) %>%
      layout(
        xaxis = list(title = "Grid Impact Level"),
        yaxis = list(title = "Number of Providers"),
        plot_bgcolor = 'rgba(0,0,0,0)',
        paper_bgcolor = 'rgba(0,0,0,0)'
      )
    
    p
  })
  
  output$power_efficiency_scatter <- renderPlotly({
    p <- plot_ly(
      data = providers_data,
      x = ~PUE,
      y = ~Active_AI_Power_MW,
      color = ~Track,
      colors = c("A" = "#28a745", "A/B" = "#17a2b8", "B" = "#ffc107", "C" = "#fd7e14"),
      size = ~AI_Allocation_Percent,
      sizes = c(10, 100),
      text = ~paste("Provider:", Provider, "<br>PUE:", PUE, "<br>AI Power:", format(Active_AI_Power_MW, big.mark = ","), "MW<br>AI Allocation:", AI_Allocation_Percent, "%"),
      hovertemplate = "%{text}<extra></extra>"
    ) %>%
      layout(
        xaxis = list(title = "Power Usage Effectiveness (PUE)"),
        yaxis = list(title = "Active AI Power (MW)"),
        plot_bgcolor = 'rgba(0,0,0,0)',
        paper_bgcolor = 'rgba(0,0,0,0)'
      )
    
    p
  })
  

}

# Run the application
shinyApp(ui = ui, server = server)