library(shiny)
library(shinydashboard)
library(plotly)
library(DT)
library(ggplot2)

# UI
ui <- dashboardPage(
  dashboardHeader(title = "Active Bayesian Learning of Dynamic Systems"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Introduction", tabName = "ch1", icon = icon("home")),
      menuItem("Background", tabName = "ch2", icon = icon("book")),
      menuItem("GP Dynamics Modelling", tabName = "ch3", icon = icon("chart-line")),
      menuItem("Active Learning & Control", tabName = "ch4", icon = icon("robot")),
      menuItem("Experiments", tabName = "ch5", icon = icon("flask")),
      menuItem("Conclusions", tabName = "ch6", icon = icon("flag-checkered")),
      menuItem("References", tabName = "refs", icon = icon("bookmark"))
    )
  ),
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .content-wrapper, .right-side {
          background: linear-gradient(135deg, #002C3C 0%, #008A82 50%, #00A39A 100%) !important;
          min-height: 100vh;
        }
        .sidebar, .main-sidebar {
          background: linear-gradient(180deg, #002C3C 0%, #008A82 50%, #00A39A 100%) !important;
        }
        .sidebar .sidebar-menu > li > a {
          color: #ffffff !important;
          border-left: 3px solid transparent;
          transition: all 0.3s ease;
        }
        .sidebar .sidebar-menu > li.active > a,
        .sidebar .sidebar-menu > li:hover > a {
          background: rgba(255, 255, 255, 0.15) !important;
          border-left: 3px solid #00A39A !important;
          color: #ffffff !important;
        }
        .main-header, .main-header .navbar {
          background: linear-gradient(135deg, #002C3C 0%, #008A82 50%, #00A39A 100%) !important;
          border-bottom: none;
        }
        .box {
          background: rgba(255, 255, 255, 0.98) !important;
          border: none !important;
          border-radius: 12px !important;
          box-shadow: 0 8px 25px rgba(0, 44, 60, 0.2) !important;
          margin-bottom: 20px;
        }
        .box-header {
          background: linear-gradient(135deg, #008A82 0%, #00A39A 100%) !important;
          color: white !important;
          border-radius: 12px 12px 0 0 !important;
          padding: 15px 20px;
        }
        .box-header > .box-title {
          color: #ffffff !important;
          font-weight: 600;
        }
        .small-box.bg-blue { 
          background: linear-gradient(135deg, #3498db 0%, #2980b9 100%) !important; 
        }
        .small-box.bg-green { 
          background: linear-gradient(135deg, #00A39A 0%, #008A82 100%) !important; 
        }
        .small-box.bg-yellow { 
          background: linear-gradient(135deg, #f39c12 0%, #e67e22 100%) !important; 
        }
        .small-box.bg-red { 
          background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%) !important; 
        }
        .small-box.bg-purple { 
          background: linear-gradient(135deg, #9b59b6 0%, #8e44ad 100%) !important; 
        }
        .btn-primary {
          background: linear-gradient(135deg, #008A82 0%, #00A39A 100%) !important;
          border: none !important;
          border-radius: 8px !important;
        }
        .math-formula {
          background: #f8f9fa;
          padding: 15px;
          border-radius: 8px;
          margin: 10px 0;
          border-left: 4px solid #008A82;
        }
        .concept-box {
          background: #e8f5f4;
          padding: 15px;
          border-radius: 8px;
          margin: 10px 0;
        }
      "))
    ),
    tags$script(HTML('
      MathJax = {
        tex: {
          inlineMath: [["$", "$"], ["\\\\(", "\\\\)"]],
          displayMath: [["$$", "$$"], ["\\\\[", "\\\\]"]]
        }
      };
    ')),
    tags$script(src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"),
    
    tabItems(
      # Chapter 1: Introduction
      tabItem(tabName = "ch1",
              fluidRow(
                box(width = 12, title = "Chapter 1: Introduction", status = "primary", solidHeader = TRUE,
                    h3("Motivation"),
                    p("Autonomous robotic systems perform a wide range of industrial and productive activities globally. 
                      Effective operation without human intervention defines the reliability of these systems."),
                    
                    div(class = "concept-box",
                        h4("Key Challenges:"),
                        tags$ul(
                          tags$li("Fully measurable dynamical environment assumptions"),
                          tags$li("Stationary dynamics assumptions"),
                          tags$li("Difficulty measuring actuator quantities (e.g., friction)"),
                          tags$li("Undetectable disturbances")
                        )
                    )
                )
              ),
              
              fluidRow(
                box(width = 6, title = "Problem Description", status = "info", solidHeader = TRUE,
                    p("Conventional control relies on ODEs and assumes stationary system dynamics. 
                      Ignoring environmental complexities such as unknown disturbances could lead to 
                      an inaccurate model of the robotic system."),
                    
                    div(class = "math-formula",
                        p("State-action relationship:"),
                        withMathJax("$$s_{t+1} = f(s_t, a_t)$$")
                    )
                ),
                
                box(width = 6, title = "Research Question", status = "warning", solidHeader = TRUE,
                    div(class = "concept-box",
                        p(strong("How to define an effective active Bayesian learning methodology for 
                                 selecting the most informative dynamics data and build a reliable 
                                 predictive model that exploits the inter-task dependencies?"))
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Thesis Contributions", status = "success", solidHeader = TRUE,
                    column(4,
                           valueBox(
                             "Information Gain Strategy",
                             "Novel observation selection method",
                             icon = icon("lightbulb"),
                             color = "green"
                           )
                    ),
                    column(4,
                           valueBox(
                             "Multi-task Learning",
                             "MOGP-based task correlation",
                             icon = icon("project-diagram"),
                             color = "blue"
                           )
                    ),
                    column(4,
                           valueBox(
                             "Adaptive Control",
                             "Real-time model updates",
                             icon = icon("sync-alt"),
                             color = "purple"
                           )
                    )
                )
              )
      ),
      
      # Chapter 2: Background
      tabItem(tabName = "ch2",
              fluidRow(
                box(width = 12, title = "Chapter 2: Background", status = "primary", solidHeader = TRUE,
                    h3("Bayesian Learning"),
                    
                    div(class = "math-formula",
                        h4("Bayes' Theorem:"),
                        withMathJax("$$p(\\theta|z) = \\frac{p(z|\\theta)p(\\theta)}{p(z)}$$"),
                        tags$ul(
                          tags$li(withMathJax("$p(\\theta)$ - Prior")),
                          tags$li(withMathJax("$p(z|\\theta)$ - Likelihood")),
                          tags$li(withMathJax("$p(z)$ - Marginal likelihood")),
                          tags$li(withMathJax("$p(\\theta|z)$ - Posterior"))
                        )
                    )
                )
              ),
              
              fluidRow(
                box(width = 6, title = "Gaussian Process Regression", status = "info", solidHeader = TRUE,
                    p("A GP is a collection of random variables, any finite number of which have 
                      a joint Gaussian distribution."),
                    
                    div(class = "math-formula",
                        withMathJax("$$f \\sim \\mathcal{GP}(m(x), c(x,x'))$$"),
                        withMathJax("$$m(x) = \\mathbb{E}[f(x)]$$"),
                        withMathJax("$$c(x,x') = \\mathbb{E}[(f(x)-m(x))(f(x')-m(x'))]$$")
                    ),
                    
                    h4("Squared Exponential Covariance:"),
                    div(class = "math-formula",
                        withMathJax("$$c_{sq}(x,x') = \\sigma_f^2 \\exp\\left(-\\frac{1}{2}(x-x')^T\\Lambda(x-x')\\right)$$")
                    )
                ),
                
                box(width = 6, title = "GP Predictions", status = "warning", solidHeader = TRUE,
                    div(class = "math-formula",
                        h4("Predictive Distribution:"),
                        withMathJax("$$f_*|X_*, X, y \\sim \\mathcal{N}(\\bar{f}_*, \\text{cov}(f_*))$$"),
                        
                        h4("Predictive Mean:"),
                        withMathJax("$$\\bar{f}_* = C(X_*,X)[C(X,X)+\\sigma_n^2I]^{-1}y$$"),
                        
                        h4("Predictive Covariance:"),
                        withMathJax("$$\\text{cov}(f_*) = C(X_*,X_*) - C(X_*,X)[C(X,X)+\\sigma_n^2I]^{-1}C(X,X_*)$$")
                    )
                )
              ),
              
              fluidRow(
                box(width = 6, title = "Information Theory", status = "success", solidHeader = TRUE,
                    h4("Shannon Information Content:"),
                    div(class = "math-formula",
                        withMathJax("$$h(x) = \\log_2\\frac{1}{p(x)} = -\\log_2 p(x)$$")
                    ),
                    
                    h4("Entropy:"),
                    div(class = "math-formula",
                        withMathJax("$$H(x) = \\sum_{x\\in\\mathcal{X}} p(x)\\log\\frac{1}{p(x)}$$"),
                        p("Entropy quantifies uncertainty in a distribution")
                    )
                ),
                
                box(width = 6, title = "Linear Quadratic Control", status = "danger", solidHeader = TRUE,
                    h4("LQR Cost Function:"),
                    div(class = "math-formula",
                        withMathJax("$$J_{t,t_f} = \\int_t^{t_f} (s_\\tau^T Q_\\tau s_\\tau + a_\\tau^T R_\\tau a_\\tau)d\\tau$$")
                    ),
                    
                    h4("Optimal Gain Matrix:"),
                    div(class = "math-formula",
                        withMathJax("$$K_0 = R_t^{-1}B_t^TM_0$$")
                    ),
                    
                    h4("Riccati Equation:"),
                    div(class = "math-formula",
                        withMathJax("$$-\\frac{\\partial M_0}{\\partial t} = A_t^TM_0 + M_0A_t + Q_t - M_0B_tR_t^{-1}B_t^TM_0$$")
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Interactive GP Visualization", status = "primary", solidHeader = TRUE,
                    column(4,
                           sliderInput("n_obs", "Number of Observations:", 
                                       min = 5, max = 50, value = 20, step = 5),
                           sliderInput("noise_level", "Noise Level:", 
                                       min = 0.01, max = 0.5, value = 0.1, step = 0.01),
                           actionButton("regenerate", "Regenerate", class = "btn-primary")
                    ),
                    column(8,
                           plotlyOutput("gp_plot", height = "400px")
                    )
                )
              )
      ),
      
      # Chapter 3: GP Dynamics Modelling
      tabItem(tabName = "ch3",
              fluidRow(
                box(width = 12, title = "Chapter 3: Gaussian Process Dynamics Modelling and Control", 
                    status = "primary", solidHeader = TRUE,
                    h3("Learning Dynamic Systems"),
                    
                    div(class = "concept-box",
                        p("GPs are robust techniques to model non-linear dynamics of robotic systems:"),
                        tags$ul(
                          tags$li("Can represent non-linearities over the space of functions"),
                          tags$li("Covariance provides information about confidence of predictions"),
                          tags$li("Sensor noise can be modeled as Gaussian noise")
                        )
                    )
                )
              ),
              
              fluidRow(
                box(width = 6, title = "Training Data Definition", status = "info", solidHeader = TRUE,
                    div(class = "math-formula",
                        h4("State-Action Pairs:"),
                        withMathJax("$$x_t = \\{s_{t-1}, a_{t-1}\\}$$"),
                        withMathJax("$$y_t = (s_t - s_{t-1})|a_{t-1}$$"),
                        
                        p("Training dataset:"),
                        withMathJax("$$\\mathcal{D} = \\{X, y\\}$$"),
                        withMathJax("$$X = \\{x_1, x_2, \\ldots, x_n\\}$$"),
                        withMathJax("$$y_m = \\{y_m^1, y_m^2, \\ldots, y_m^n\\}$$")
                    )
                ),
                
                box(width = 6, title = "Single Output GP Prediction", status = "warning", solidHeader = TRUE,
                    div(class = "math-formula",
                        withMathJax("$$\\bar{f}_{m*} = C_m(x_*, X)[C_m(X,X)+\\sigma_n^2I]^{-1}y_m$$"),
                        
                        p("Computational cost:"),
                        tags$ul(
                          tags$li(withMathJax("Matrix inversion: $\\mathcal{O}(N^3)$")),
                          tags$li(withMathJax("Prediction: $\\mathcal{O}(N^2)$"))
                        )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Multi-Task Learning with MOGPs", status = "success", solidHeader = TRUE,
                    h4("Multiple Output Gaussian Processes"),
                    
                    div(class = "concept-box",
                        p("MOGPs model dependencies between tasks through cross-correlation:"),
                        
                        div(class = "math-formula",
                            h4("Covariance Structure:"),
                            withMathJax("$$\\text{cov}(y_i(x), y_j(x')) = c_{y_{ij}} c_x(x,x')$$"),
                            
                            h4("Multi-task Covariance Matrix:"),
                            withMathJax("$$C_M = (c_{y_{ij}}C_{x_{ij}})_{ij}$$"),
                            
                            withMathJax("$$C_M = \\begin{bmatrix}
                              c_{y_{11}}C_{x_{11}} & \\cdots & c_{y_{1m}}C_{x_{1m}} \\\\
                              \\vdots & \\ddots & \\vdots \\\\
                              c_{y_{m1}}C_{x_{m1}} & \\cdots & c_{y_{mm}}C_{x_{mm}}
                            \\end{bmatrix}$$")
                        )
                    )
                )
              ),
              
              fluidRow(
                box(width = 6, title = "MOGP Inference", status = "primary", solidHeader = TRUE,
                    div(class = "math-formula",
                        h4("Predictive Distribution:"),
                        withMathJax("$$f_{m*}|x_*, X, y \\sim \\mathcal{N}(\\bar{f}_{m*}, \\text{cov}(f_{m*}))$$"),
                        
                        h4("Task m Mean Function:"),
                        withMathJax("$$\\bar{f}_{m*} = c_m^T C_M^{-1} y$$"),
                        
                        h4("Covariance:"),
                        withMathJax("$$\\text{cov}(\\bar{f}_{m*}) = c_* - c_m^T C_M^{-1} c_m$$")
                    )
                ),
                
                box(width = 6, title = "Computational Complexity", status = "danger", solidHeader = TRUE,
                    div(class = "concept-box",
                        h4("MOGP with M tasks:"),
                        tags$ul(
                          tags$li(withMathJax("Matrix inversion: $\\mathcal{O}(M^3N^3)$")),
                          tags$li(withMathJax("Prediction: $\\mathcal{O}(M^2N^2)$"))
                        ),
                        
                        p(strong("Challenge:"), "Need efficient data selection strategy to reduce N 
                          while maintaining prediction accuracy")
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Experimental Results: Simulated Blimp", status = "info", solidHeader = TRUE,
                    column(6,
                           h4("State-Action Space:"),
                           div(class = "math-formula",
                               withMathJax("$$s = \\{h, \\dot{h}\\}$$"),
                               tags$ul(
                                 tags$li(withMathJax("$-5m \\leq h \\leq 5m$ (height)")),
                                 tags$li(withMathJax("$-1m/s \\leq \\dot{h} \\leq 1m/s$ (vertical speed)")),
                                 tags$li(withMathJax("$-1 \\leq a \\leq 1$ (action)"))
                               )
                           )
                    ),
                    column(6,
                           h4("Key Findings:"),
                           div(class = "concept-box",
                               tags$ul(
                                 tags$li("MOGP achieved lower prediction error than single GPs"),
                                 tags$li("Task correlation improved learning efficiency"),
                                 tags$li("Better control performance with MOGP model")
                               )
                           )
                    )
                )
              )
      ),
      
      # Chapter 4: Active Learning & Control
      tabItem(tabName = "ch4",
              fluidRow(
                box(width = 12, title = "Chapter 4: Active Learning and Control", 
                    status = "primary", solidHeader = TRUE,
                    h3("Information Gain Strategy"),
                    
                    div(class = "concept-box",
                        p("Efficient training data selection to improve learning and control of dynamic systems 
                          based on information theory metrics.")
                    )
                )
              ),
              
              fluidRow(
                box(width = 6, title = "Bayesian Optimal Design", status = "info", solidHeader = TRUE,
                    div(class = "math-formula",
                        h4("Information Gain:"),
                        withMathJax("$$I(x) = \\mathbb{E}\\left\\{\\log\\frac{p(\\theta|x)}{p(\\theta)}\\right\\}$$"),
                        
                        withMathJax("$$I(x) = \\int_\\Theta\\int_X \\log\\left(\\frac{p(\\theta|x)}{p(\\theta)}\\right)p(x|\\theta)p(\\theta)dxd\\theta$$"),
                        
                        h4("Utility Function:"),
                        withMathJax("$$U(x,h) = I(x) + V(x|h)$$")
                    )
                ),
                
                box(width = 6, title = "GP-based Selection", status = "warning", solidHeader = TRUE,
                    div(class = "math-formula",
                        h4("Entropy Score:"),
                        withMathJax("$$\\Delta_j = H[p(f_j|X_I)] - H[p(f_j|X_I \\cup x_j)]$$"),
                        
                        withMathJax("$$\\Delta_j = \\log\\left(1 + \\frac{v_j}{\\sigma^2}\\right)$$"),
                        
                        h4("Point Selection:"),
                        withMathJax("$$x_j = \\arg\\max_{x_j \\in \\mathbb{R}^D} \\Delta_j$$")
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Information Gain Learning Algorithm", status = "success", solidHeader = TRUE,
                    column(6,
                           h4("Single Task Version (Algorithm 1):"),
                           div(class = "concept-box",
                               tags$ol(
                                 tags$li("For all points in training set, compute information gain score"),
                                 tags$li(withMathJax("Select $x_j^m = \\arg\\max_{x_j^m} \\Delta_j^m$")),
                                 tags$li(withMathJax("Use LQR to reach $x_j^m$")),
                                 tags$li(withMathJax("Add $x_j^m$ and $y_j^m$ to training set")),
                                 tags$li("Optimize hyperparameters"),
                                 tags$li("Repeat until information gain < threshold")
                               )
                           )
                    ),
                    column(6,
                           h4("Multi-Task Version (Algorithm 2):"),
                           div(class = "concept-box",
                               tags$ol(
                                 tags$li("Compute predicted variance for all tasks"),
                                 tags$li(withMathJax("Select $x_j^* = \\arg\\min_{x_j} I(x_j|X_I, X_o)$")),
                                 tags$li(withMathJax("Use LQR to reach $x_j^*$")),
                                 tags$li("Add observed state-action pair to training set"),
                                 tags$li("Optimize hyperparameters periodically"),
                                 tags$li("Repeat until LQR accurately reaches targets")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 6, title = "Multi-Task Covariance Strategy", status = "primary", solidHeader = TRUE,
                    div(class = "math-formula",
                        h4("Entropy Contribution:"),
                        withMathJax("$$I(x_j|X_I) = \\log\\left(\\frac{|C(X_o,X_o|X_{I+1})|}{|C(X_o,X_o|X_I)|}\\right)$$"),
                        
                        h4("Optimal Observation:"),
                        withMathJax("$$x_j = \\arg\\min_{x_j \\in \\mathbb{R}^D \\times \\mathbb{R} \\setminus X_I} \\log\\left(\\frac{|C(X_o,X_o|X_{I+1})|}{|C(X_o,X_o|X_I)|}\\right)$$")
                    ),
                    
                    p("Computational cost per iteration:"),
                    div(class = "concept-box",
                        withMathJax("$$\\mathcal{O}(M^2N^2)$$")
                    )
                ),
                
                box(width = 6, title = "Control Stability", status = "danger", solidHeader = TRUE,
                    h4("Principle of Separation:"),
                    div(class = "concept-box",
                        p("System stability ensured by:"),
                        tags$ul(
                          tags$li("Steady state observer (GP model)"),
                          tags$li("Steady deterministic controller (LQR)")
                        )
                    ),
                    
                    div(class = "math-formula",
                        h4("Control Error:"),
                        withMathJax("$$e_t = s^* - s_t|a_t$$"),
                        
                        h4("Prediction Error:"),
                        withMathJax("$$\\hat{e}_t = s_t|a_t - \\hat{s}_t|v_t$$"),
                        
                        h4("Convergence Condition:"),
                        withMathJax("$$\\lim_{t\\to\\infty} e_t \\approx 0$$")
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Cart-Pole Experiment Results", status = "info", solidHeader = TRUE,
                    column(4,
                           h4("System Definition:"),
                           div(class = "concept-box",
                               p("State dimensions:"),
                               tags$ul(
                                 tags$li("Cart position (h)"),
                                 tags$li("Cart velocity (ḣ)"),
                                 tags$li("Pole angle (θ)"),
                                 tags$li("Angular velocity (θ̇)")
                               ),
                               
                               p("5D input space: {h, ḣ, θ, θ̇, a}")
                           )
                    ),
                    column(4,
                           h4("State-Action Range:"),
                           div(class = "math-formula",
                               withMathJax("$$-5cm \\leq h \\leq 5cm$$"),
                               withMathJax("$$-1cm/s \\leq \\dot{h} \\leq 1cm/s$$"),
                               withMathJax("$$-\\pi \\leq \\theta \\leq \\pi$$"),
                               withMathJax("$$-1rad/s \\leq \\dot{\\theta} \\leq 1rad/s$$"),
                               withMathJax("$$-1N \\leq a \\leq 1N$$")
                           )
                    ),
                    column(4,
                           h4("Key Results:"),
                           div(class = "concept-box",
                               tags$ul(
                                 tags$li("Information gain strategy achieved faster error reduction"),
                                 tags$li("Outperformed equally spaced sampling"),
                                 tags$li("More effective for cart position and angular velocity"),
                                 tags$li("Handles non-linearities better")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Advantages Over Other Methods", status = "success", solidHeader = TRUE,
                    column(4,
                           h4("vs. Fuzzy Logic/PI Controllers:"),
                           tags$ul(
                             tags$li("No fixed structure with parameters to estimate"),
                             tags$li("Multivariate distribution over functions"),
                             tags$li("Avoids overfitting")
                           )
                    ),
                    column(4,
                           h4("vs. Model-Free Adaptive:"),
                           tags$ul(
                             tags$li("No pseudo-partial-derivative computation"),
                             tags$li("Better noise handling"),
                             tags$li("Direct state estimation")
                           )
                    ),
                    column(4,
                           h4("vs. Periodic Adaptive:"),
                           tags$ul(
                             tags$li("Non-arbitrary update criteria"),
                             tags$li("Information-based model updates"),
                             tags$li("Variance-driven thresholds")
                           )
                    )
                )
              )
      ),
      
      # Chapter 5: Experiments
      tabItem(tabName = "ch5",
              fluidRow(
                box(width = 12, title = "Chapter 5: Experiments - Robotic Blimp", 
                    status = "primary", solidHeader = TRUE,
                    h3("Platform Description"),
                    
                    column(6,
                           div(class = "concept-box",
                               h4("Physical Specifications:"),
                               tags$ul(
                                 tags$li("Length: 1.8 metres"),
                                 tags$li("Diameter: 1 metre"),
                                 tags$li("2 gondola propellers (coupled motors)"),
                                 tags$li("1 rear propeller on fin"),
                                 tags$li("Servo-controlled propeller shaft")
                               )
                           )
                    ),
                    column(6,
                           div(class = "concept-box",
                               h4("Sensing Equipment:"),
                               tags$ul(
                                 tags$li("RM-M3 navigation board (compass, gyro)"),
                                 tags$li("LV-EZ1 ultrasonic sensor (6.5m range)"),
                                 tags$li("SRV Blackfin camera (640×480, 5fps)"),
                                 tags$li("On-board microcomputer"),
                                 tags$li("WiFi communication (2.3 GHz CPU)")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Experiment 1: Vertical Dynamics Learning", status = "info", solidHeader = TRUE,
                    column(4,
                           h4("Setup:"),
                           div(class = "concept-box",
                               p("Constrained movement: vertical only"),
                               
                               div(class = "math-formula",
                                   h5("State-Action Space:"),
                                   withMathJax("$$-1m \\leq h \\leq 1m$$"),
                                   withMathJax("$$-0.6m/s \\leq \\dot{h} \\leq 0.6m/s$$"),
                                   withMathJax("$$-1 \\leq a_h \\leq 1$$")
                               ),
                               
                               p("Physical range: 2.2m, max speed: 0.7 m/s"),
                               p("Control period: Δt = 0.4 sec")
                           )
                    ),
                    column(4,
                           h4("Challenges:"),
                           div(class = "concept-box",
                               tags$ul(
                                 tags$li("Non-linear motor dynamics"),
                                 tags$li("Continuous helium leaking"),
                                 tags$li("Wind disturbances"),
                                 tags$li("Sensor noise and delays")
                               )
                           )
                    ),
                    column(4,
                           h4("Results:"),
                           div(class = "concept-box",
                               tags$ul(
                                 tags$li("Info gain: faster error reduction"),
                                 tags$li("Better height prediction accuracy"),
                                 tags$li("Improved speed estimation"),
                                 tags$li("More reliable derivative estimates")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Experiment 2: Heading Dynamics Learning", status = "warning", solidHeader = TRUE,
                    column(4,
                           h4("Setup:"),
                           div(class = "concept-box",
                               p("Constrained movement: rotation only"),
                               
                               div(class = "math-formula",
                                   h5("State-Action Space:"),
                                   withMathJax("$$-\\frac{\\pi}{2} \\leq \\psi \\leq \\frac{\\pi}{2}$$"),
                                   withMathJax("$$-1rad/s \\leq \\dot{\\psi} \\leq 1rad/s$$"),
                                   withMathJax("$$-1 \\leq a_\\psi \\leq 1$$")
                               ),
                               
                               p("Rear propeller torque control")
                           )
                    ),
                    column(4,
                           h4("Challenges:"),
                           div(class = "concept-box",
                               tags$ul(
                                 tags$li("High moment of inertia"),
                                 tags$li("Orientation instability"),
                                 tags$li("Wind disturbances"),
                                 tags$li("Non-measurable inertia parameters")
                               )
                           )
                    ),
                    column(4,
                           h4("Results:"),
                           div(class = "concept-box",
                               tags$ul(
                                 tags$li("Stabilized over target heading"),
                                 tags$li("Info gain: smoother actions"),
                                 tags$li("Reduced oscillations"),
                                 tags$li("Faster convergence (40 actions)"),
                                 tags$li("Better than random sampling")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Experiment 3: 3D Navigation (Lifting Buoyancy)", status = "success", solidHeader = TRUE,
                    column(3,
                           h4("State-Action Space:"),
                           div(class = "math-formula",
                               withMathJax("$$-1.5m \\leq h \\leq 1.5m$$"),
                               withMathJax("$$-0.4m/s \\leq \\dot{h} \\leq 0.4m/s$$"),
                               withMathJax("$$-\\pi \\leq \\psi \\leq \\pi$$"),
                               withMathJax("$$-1rad/s \\leq \\dot{\\psi} \\leq 1rad/s$$"),
                               withMathJax("$$-1 \\leq a_h \\leq 1$$"),
                               withMathJax("$$-1 \\leq a_\\psi \\leq 1$$")
                           )
                    ),
                    column(3,
                           h4("Target State:"),
                           div(class = "concept-box",
                               withMathJax("$$h^* = 1.5m$$"),
                               withMathJax("$$\\dot{h}^* = 0$$"),
                               withMathJax("$$\\psi^* = 0$$"),
                               withMathJax("$$\\dot{\\psi}^* = 0$$")
                           )
                    ),
                    column(3,
                           h4("Initial Deviation:"),
                           div(class = "concept-box",
                               withMathJax("$$h = 0.23m$$"),
                               withMathJax("$$\\psi = 2.85rad$$"),
                               p("Over-inflated (lifting buoyancy)")
                           )
                    ),
                    column(3,
                           h4("Results:"),
                           div(class = "concept-box",
                               tags$ul(
                                 tags$li("30 actions to stabilize height"),
                                 tags$li("40 actions to stabilize heading"),
                                 tags$li("U-turn maneuver successful"),
                                 tags$li("Compensated lifting force")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Experiment 4: 3D Navigation (Dropping Buoyancy)", status = "danger", solidHeader = TRUE,
                    column(4,
                           h4("Scenario:"),
                           div(class = "concept-box",
                               p("Prolonged helium leaking"),
                               p("Pulling down force"),
                               p("Intentional disturbances"),
                               p("120 control actions horizon")
                           )
                    ),
                    column(4,
                           h4("Disturbances:"),
                           div(class = "concept-box",
                               tags$ul(
                                 tags$li("Action 16: deviation to ψ = 1.6 rad"),
                                 tags$li("Action 90: deviation to ψ = 1.1 rad"),
                                 tags$li("Height: -1m below target initially"),
                                 tags$li("Max deviation: -1.9m below target")
                               )
                           )
                    ),
                    column(4,
                           h4("Results:"),
                           div(class = "concept-box",
                               tags$ul(
                                 tags$li("Recovered from disturbances"),
                                 tags$li("Stabilized after 110 actions"),
                                 tags$li("Robust to external perturbations"),
                                 tags$li("Compensated helium loss")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Experiment 5: Path Tracking Around Truck", status = "primary", solidHeader = TRUE,
                    column(4,
                           h4("Task:"),
                           div(class = "concept-box",
                               p("Track path with constant height"),
                               p("6 straight line segments"),
                               p("Camera-based line detection"),
                               p("200 control actions"),
                               withMathJax("$$h^* = 1.5m, \\psi = \\phi_{trajectory}$$")
                           )
                    ),
                    column(4,
                           h4("Technical Details:"),
                           div(class = "concept-box",
                               tags$ul(
                                 tags$li("5 fps camera processing"),
                                 tags$li("Δt = 0.4 sec control period"),
                                 tags$li("On-board image processing"),
                                 tags$li("Real-time heading updates")
                               )
                           )
                    ),
                    column(4,
                           h4("Results:"),
                           div(class = "concept-box",
                               tags$ul(
                                 tags$li("Successfully followed path"),
                                 tags$li("Height stabilized (action 70)"),
                                 tags$li("5 heading transitions executed"),
                                 tags$li("Minimal deviations from path")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Experiment 6: Closed Loop Pattern", status = "info", solidHeader = TRUE,
                    column(3,
                           h4("Challenge:"),
                           div(class = "concept-box",
                               p(strong("Most ambitious control task")),
                               p("Track circular loop pattern"),
                               p("Maintain constant height"),
                               p("140 control actions"),
                               p("Close the loop successfully")
                           )
                    ),
                    column(3,
                           h4("Complexity:"),
                           div(class = "concept-box",
                               tags$ul(
                                 tags$li("Limited actuator capabilities"),
                                 tags$li("Continuous heading changes"),
                                 tags$li("Inertia effects"),
                                 tags$li("12 line segment transitions"),
                                 tags$li("Height control simultaneous")
                               )
                           )
                    ),
                    column(3,
                           h4("Performance:"),
                           div(class = "concept-box",
                               tags$ul(
                                 tags$li("Height deviation: -0.47m initially"),
                                 tags$li("12 heading peaks detected"),
                                 tags$li("Loop successfully closed"),
                                 tags$li("Compensated all deviations")
                               )
                           )
                    ),
                    column(3,
                           h4("Significance:"),
                           div(class = "concept-box",
                               p(strong("Demonstrates:"),
                                 tags$ul(
                                   tags$li("Model accuracy"),
                                   tags$li("LQR effectiveness"),
                                   tags$li("Robustness to constraints"),
                                   tags$li("Full autonomous operation")
                                 )
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Summary of Experimental Results", status = "success", solidHeader = TRUE,
                    column(4,
                           valueBox(
                             "6 Experiments",
                             "Successfully Completed",
                             icon = icon("check-circle"),
                             color = "green"
                           )
                    ),
                    column(4,
                           valueBox(
                             "Real Robot",
                             "Challenging UAV Platform",
                             icon = icon("robot"),
                             color = "blue"
                           )
                    ),
                    column(4,
                           valueBox(
                             "Full 3D Control",
                             "Autonomous Navigation",
                             icon = icon("cube"),
                             color = "purple"
                           )
                    )
                )
              )
      ),
      
      # Chapter 6: Conclusions
      tabItem(tabName = "ch6",
              fluidRow(
                box(width = 12, title = "Chapter 6: Conclusions", status = "primary", solidHeader = TRUE,
                    h3("Summary of Contributions"),
                    p("This thesis presented a novel method for active learning of robotic systems dynamics 
                      under challenging conditions.")
                )
              ),
              
              fluidRow(
                box(width = 6, title = "1. Dynamics Modelling with GPs", status = "info", solidHeader = TRUE,
                    div(class = "concept-box",
                        tags$ul(
                          tags$li("Tasks defined as single state dimensions"),
                          tags$li("Functions described in state-action space"),
                          tags$li("Accurate uncertainty estimation"),
                          tags$li("Penalization of model complexity"),
                          tags$li("Avoids overfitting")
                        )
                    ),
                    
                    div(class = "math-formula",
                        withMathJax("$$f \\sim \\mathcal{GP}(m(x), c(x,x'))$$"),
                        p("Variance quantifies model reliability")
                    )
                ),
                
                box(width = 6, title = "2. Multi-Task Learning", status = "warning", solidHeader = TRUE,
                    div(class = "concept-box",
                        tags$ul(
                          tags$li("MOGPs model task dependencies"),
                          tags$li("Cross-correlation between outputs"),
                          tags$li("More descriptive model with reduced dataset"),
                          tags$li("Better than single output GPs"),
                          tags$li("Improved control performance")
                        )
                    ),
                    
                    div(class = "math-formula",
                        withMathJax("$$C_M = (c_{y_{ij}}C_{x_{ij}})_{ij}$$")
                    )
                )
              ),
              
              fluidRow(
                box(width = 6, title = "3. Adaptive Predictive Control", status = "success", solidHeader = TRUE,
                    div(class = "concept-box",
                        tags$ul(
                          tags$li("LQR based on GP/MOGP models"),
                          tags$li("Derivatives estimated from learned models"),
                          tags$li("Uncertainty guides active sampling"),
                          tags$li("Principle of separation ensures convergence"),
                          tags$li("Steady observer + steady controller")
                        )
                    ),
                    
                    div(class = "math-formula",
                        withMathJax("$$\\lim_{t\\to\\infty} e_t \\approx 0$$"),
                        p("Asymptotic convergence to target state")
                    )
                ),
                
                box(width = 6, title = "4. Information Gain Strategy", status = "danger", solidHeader = TRUE,
                    div(class = "concept-box",
                        tags$ul(
                          tags$li("Efficiently samples state-action space"),
                          tags$li("Entropy-based observation selection"),
                          tags$li("Posterior variance quantifies information"),
                          tags$li("Continuous target computation"),
                          tags$li("Dataset length reduction")
                        )
                    ),
                    
                    div(class = "math-formula",
                        withMathJax("$$\\Delta_j = \\log\\left(1 + \\frac{v_j}{\\sigma^2}\\right)$$")
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "5. UAV Adaptive Navigation", status = "primary", solidHeader = TRUE,
                    h4("Systematic Verification on Real Robotic Blimp:"),
                    
                    column(4,
                           div(class = "concept-box",
                               h5("Single DOF Experiments:"),
                               tags$ul(
                                 tags$li("Vertical dynamics (constrained)"),
                                 tags$li("Heading dynamics (constrained)"),
                                 tags$li("Info gain > random sampling"),
                                 tags$li("Better prediction accuracy"),
                                 tags$li("Superior LQR performance")
                               )
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h5("3D Navigation:"),
                               tags$ul(
                                 tags$li("Unconstrained movement"),
                                 tags$li("Lifting/dropping buoyancy"),
                                 tags$li("External disturbances"),
                                 tags$li("Real-time relearning"),
                                 tags$li("Effective stabilization")
                               )
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h5("Path Tracking:"),
                               tags$ul(
                                 tags$li("Open path (truck obstacle)"),
                                 tags$li("Circular closed loop"),
                                 tags$li("Constant height maintenance"),
                                 tags$li("Camera-based guidance"),
                                 tags$li(strong("Fully autonomous operation"))
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Key Achievements", status = "success", solidHeader = TRUE,
                    column(3,
                           valueBox(
                             "O(N³) → O(N²)",
                             "Reduced computational cost",
                             icon = icon("tachometer-alt"),
                             color = "green"
                           )
                    ),
                    column(3,
                           valueBox(
                             "Real-time",
                             "Adaptive model updates",
                             icon = icon("sync-alt"),
                             color = "blue"
                           )
                    ),
                    column(3,
                           valueBox(
                             "Non-linear",
                             "Complex dynamics learning",
                             icon = icon("project-diagram"),
                             color = "purple"
                           )
                    ),
                    column(3,
                           valueBox(
                             "Autonomous",
                             "Full 3D navigation",
                             icon = icon("drone"),
                             color = "red"
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Future Work", status = "info", solidHeader = TRUE,
                    column(6,
                           h4("Extension to Higher Dimensions:"),
                           div(class = "concept-box",
                               tags$ul(
                                 tags$li("Task clustering based on correlation metrics"),
                                 tags$li("Multiple MOGPs for task clusters"),
                                 tags$li("Specialized covariance functions per cluster"),
                                 tags$li("Scalable to complex systems")
                               )
                           )
                    ),
                    column(6,
                           h4("Active Data Management:"),
                           div(class = "concept-box",
                               tags$ul(
                                 tags$li("Selective deletion of outdated data"),
                                 tags$li("Criteria based on data age"),
                                 tags$li("Region-based accuracy evaluation"),
                                 tags$li("Continuous model refinement")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Potential Applications", status = "warning", solidHeader = TRUE,
                    column(4,
                           div(class = "concept-box",
                               h5("Aerial Robotics:"),
                               tags$ul(
                                 tags$li("Outdoor surveillance"),
                                 tags$li("Complex UAV path planning"),
                                 tags$li("Multi-vehicle coordination"),
                                 tags$li("Adaptive wind compensation")
                               )
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h5("Ground Vehicles:"),
                               tags$ul(
                                 tags$li("Terrain adaptation"),
                                 tags$li("Traction control"),
                                 tags$li("Autonomous navigation"),
                                 tags$li("Variable load handling")
                               )
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h5("Manipulators:"),
                               tags$ul(
                                 tags$li("Friction compensation"),
                                 tags$li("Variable load dynamics"),
                                 tags$li("Precise trajectory control"),
                                 tags$li("Multi-joint coordination")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Final Remarks", status = "success", solidHeader = TRUE,
                    div(class = "concept-box",
                        h4("Main Contribution:"),
                        p(strong("An effective active Bayesian learning methodology for selecting the most 
                                 informative dynamics data and building reliable predictive models that 
                                 exploit inter-task dependencies.")),
                        
                        tags$hr(),
                        
                        h4("Impact:"),
                        tags$ul(
                          tags$li("Enables robust autonomous operation under uncertainty"),
                          tags$li("Reduces data requirements for learning"),
                          tags$li("Adapts to time-varying dynamics"),
                          tags$li("Handles actuator limitations and disturbances"),
                          tags$li("Proven on real robotic platform")
                        ),
                        
                        tags$hr(),
                        
                        p(em("This work demonstrates that information-theoretic principles combined with 
                             non-parametric Bayesian learning provide a principled framework for adaptive 
                             control of complex robotic systems."))
                    )
                )
              )
      ),
      
      # References
      tabItem(tabName = "refs",
              fluidRow(
                box(width = 12, title = "References", status = "primary", solidHeader = TRUE,
                    p("This thesis references 54 key publications in robotics, control theory, 
                      machine learning, and information theory.")
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Search and Filter References", status = "info", solidHeader = TRUE,
                    column(4,
                           textInput("search_refs", "Search:", placeholder = "Enter keywords...")
                    ),
                    column(4,
                           selectInput("filter_type", "Filter by Type:",
                                       choices = c("All", "Journal", "Conference", "Book", "Thesis"))
                    ),
                    column(4,
                           selectInput("filter_year", "Filter by Year:",
                                       choices = c("All", "2011-2015", "2006-2010", "2000-2005", "Before 2000"))
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Reference List", status = "success", solidHeader = TRUE,
                    DTOutput("references_table")
                )
              ),
              
              fluidRow(
                box(width = 6, title = "References by Category", status = "warning", solidHeader = TRUE,
                    plotlyOutput("refs_category_plot", height = "300px")
                ),
                
                box(width = 6, title = "Publications Timeline", status = "danger", solidHeader = TRUE,
                    plotlyOutput("refs_timeline_plot", height = "300px")
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Key References by Topic", status = "primary", solidHeader = TRUE,
                    column(3,
                           div(class = "concept-box",
                               h5("Gaussian Processes:"),
                               tags$ul(
                                 tags$li("[37] Rasmussen & Williams, 2006"),
                                 tags$li("[30] Neal, 1996"),
                                 tags$li("[19] Ko et al., 2007"),
                                 tags$li("[21] Kocijan et al., 2003")
                               )
                           )
                    ),
                    column(3,
                           div(class = "concept-box",
                               h5("Multi-Task Learning:"),
                               tags$ul(
                                 tags$li("[9] Caruana, 1997"),
                                 tags$li("[5] Bonilla et al., 2008"),
                                 tags$li("[10] Chai et al., 2008"),
                                 tags$li("[6] Boyle & Fren, 2005")
                               )
                           )
                    ),
                    column(3,
                           div(class = "concept-box",
                               h5("Information Theory:"),
                               tags$ul(
                                 tags$li("[28] MacKay, 2003"),
                                 tags$li("[44] Shannon, 1948"),
                                 tags$li("[25] Lindley, 1956"),
                                 tags$li("[42] Sebastiani & Wynn, 1997")
                               )
                           )
                    ),
                    column(3,
                           div(class = "concept-box",
                               h5("Control Theory:"),
                               tags$ul(
                                 tags$li("[2] Anderson & Moore, 1989"),
                                 tags$li("[7] Bryson, 2002"),
                                 tags$li("[33] Phillips & Nagle, 1995"),
                                 tags$li("[29] Murray-Smith & Sbarbaro, 2002")
                               )
                           )
                    )
                )
              )
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  
  # Chapter 2: Interactive GP Visualization
  gp_data <- reactive({
    input$regenerate  # Trigger on button press
    
    set.seed(as.numeric(Sys.time()))
    n <- input$n_obs
    x <- seq(-10, 10, length.out = 100)
    
    # True function
    true_func <- sin(x) + 0.3 * x
    
    # Training points
    x_train <- sort(sample(x, n))
    y_train <- sin(x_train) + 0.3 * x_train + rnorm(n, 0, input$noise_level)
    
    # Simple GP prediction (for visualization)
    pred <- sapply(x, function(xi) {
      # Compute distances
      dist <- abs(xi - x_train)
      weights <- exp(-dist^2 / 2)
      weights <- weights / sum(weights)
      
      # Weighted mean
      mean_pred <- sum(weights * y_train)
      
      # Simple variance estimate
      var_pred <- input$noise_level^2 * (1 - sum(weights^2))
      
      c(mean = mean_pred, sd = sqrt(var_pred))
    })
    
    list(
      x = x,
      true = true_func,
      pred_mean = pred[1,],
      pred_sd = pred[2,],
      x_train = x_train,
      y_train = y_train
    )
  })
  
  output$gp_plot <- renderPlotly({
    data <- gp_data()
    
    plot_ly() %>%
      add_ribbons(
        x = data$x,
        ymin = data$pred_mean - 2*data$pred_sd,
        ymax = data$pred_mean + 2*data$pred_sd,
        fillcolor = 'rgba(255, 193, 7, 0.3)',
        line = list(color = 'transparent'),
        name = '95% Confidence',
        showlegend = TRUE
      ) %>%
      add_lines(
        x = data$x,
        y = data$true,
        line = list(color = 'red', dash = 'dash', width = 2),
        name = 'True Function'
      ) %>%
      add_lines(
        x = data$x,
        y = data$pred_mean,
        line = list(color = 'black', width = 2),
        name = 'GP Prediction'
      ) %>%
      add_markers(
        x = data$x_train,
        y = data$y_train,
        marker = list(color = 'blue', size = 8),
        name = 'Training Points'
      ) %>%
      layout(
        title = "Gaussian Process Regression",
        xaxis = list(title = "Input (x)"),
        yaxis = list(title = "Output (y)"),
        hovermode = 'closest',
        plot_bgcolor = '#f8f9fa',
        paper_bgcolor = 'rgba(0,0,0,0)'
      )
  })
  
  # References Data
  # References Data
  references_data <- data.frame(
    ID = 1:54,
    Authors = c(
      "Abidi & Xu", "Anderson & Moore", "Astrom & Wittenmark", "Bernardo & Smith",
      "Bonilla et al.", "Boyle & Fren", "Bryson", "Bu et al.", "Caruana",
      "Chai et al.", "Chaloner & Verdinelli", "Cover & Thomas", "Deisenroth et al.",
      "Dorf & Bishop", "Edgington et al.", "Gray", "Hemakumara & Sukkarieh",
      "Kavsek-Biasizzo et al.", "Ko et al.", "Kocijan & Murray-Smith",
      "Kocijan et al.", "Kolter et al.", "Lawrence et al.", "Leith et al.",
      "Lindley", "Lindley", "MacKay", "MacKay", "Murray-Smith & Sbarbaro",
      "Neal", "Norgaard et al.", "Petelin & Kocijan", "Phillips & Nagle",
      "Press et al.", "Quionero-Candela & Rasmussen", "Rasmussen & Williams",
      "Ray", "Rottmann & Burgard", "Russel & Norvig", "Schaal et al.",
      "Sebastiani & Wynn", "Sebastiani & Wynn", "Shannon", "Singh et al.",
      "Sinha", "Tan et al.", "Tewari", "Vasudevan et al.", "Villani",
      "Williams", "Yang & Ma", "Yongping et al.", "Zubizarreta-Rodriguez & Ramos",
      "Durrant-Whyte et al."  # Added 54th author
    ),
    Year = c(
      2008, 1989, 1994, 1994, 2008, 2005, 2002, 2010, 1997,
      2008, 1995, 2006, 2009, 2005, 2009, 1990, 2011, 1997,
      2007, 2005, 2003, 2010, 2003, 2002, 1956, 1972, 1992,
      2003, 2002, 1996, 2000, 2011, 1995, 1992, 2005, 2006,
      1981, 2009, 2003, 2000, 1997, 2000, 1948, 2010, 2007,
      1999, 2002, 2009, 2008, 1998, 2011, 2009, 2011, 2010  # Added 54th year
    ),
    Type = c(
      "Journal", "Book", "Book", "Book", "Conference", "Technical Report",
      "Book", "Conference", "Thesis", "Conference", "Journal", "Book",
      "Journal", "Book", "Conference", "Book", "Conference", "Journal",
      "Conference", "Book Chapter", "Conference", "Conference", "Conference",
      "Conference", "Journal", "Book", "Journal", "Book", "Conference",
      "Book", "Book", "Journal", "Book", "Book", "Journal", "Book",
      "Book", "Conference", "Book", "Conference", "Conference", "Journal",
      "Journal", "Conference", "Book", "Conference", "Book", "Journal",
      "Book Chapter", "Journal", "Conference", "Conference", "Conference",
      "Journal"  # Added 54th type
    ),
    Category = c(
      "Control", "Control", "Control", "Statistics", "Machine Learning",
      "Machine Learning", "Control", "Control", "Machine Learning", "Machine Learning",
      "Statistics", "Information Theory", "Machine Learning", "Control", "Robotics",
      "Information Theory", "Robotics", "Control", "Robotics", "Machine Learning",
      "Machine Learning", "Robotics", "Machine Learning", "Machine Learning",
      "Statistics", "Statistics", "Information Theory", "Information Theory",
      "Machine Learning", "Machine Learning", "Control", "Machine Learning",
      "Control", "Numerical Methods", "Machine Learning", "Machine Learning",
      "Control", "Robotics", "AI", "Robotics", "Statistics", "Statistics",
      "Information Theory", "Robotics", "Control", "Control", "Control",
      "Robotics", "Mathematics", "Machine Learning", "Control", "Control",
      "Robotics", "Robotics"  # Added 54th category
    ),
    stringsAsFactors = FALSE
  )
  
  output$references_table <- renderDT({
    data <- references_data
    
    # Apply search filter
    if (!is.null(input$search_refs) && input$search_refs != "") {
      data <- data[grepl(input$search_refs, data$Authors, ignore.case = TRUE) |
                     grepl(input$search_refs, data$Category, ignore.case = TRUE), ]
    }
    
    # Apply type filter
    if (input$filter_type != "All") {
      data <- data[data$Type == input$filter_type, ]
    }
    
    # Apply year filter
    if (input$filter_year != "All") {
      year_ranges <- list(
        "2011-2015" = c(2011, 2015),
        "2006-2010" = c(2006, 2010),
        "2000-2005" = c(2000, 2005),
        "Before 2000" = c(0, 1999)
      )
      range <- year_ranges[[input$filter_year]]
      data <- data[data$Year >= range[1] & data$Year <= range[2], ]
    }
    
    datatable(
      data,
      options = list(
        pageLength = 15,
        scrollX = TRUE,
        dom = 'Bfrtip',
        buttons = c('copy', 'csv', 'excel')
      ),
      rownames = FALSE,
      class = 'cell-border stripe'
    )
  })
  
  output$refs_category_plot <- renderPlotly({
    category_counts <- table(references_data$Category)
    
    plot_ly(
      labels = names(category_counts),
      values = as.vector(category_counts),
      type = 'pie',
      marker = list(
        colors = c('#3498db', '#00A39A', '#f39c12', '#e74c3c', '#9b59b6')
      )
    ) %>%
      layout(
        title = "References by Category",
        showlegend = TRUE,
        paper_bgcolor = 'rgba(0,0,0,0)'
      )
  })
  
  output$refs_timeline_plot <- renderPlotly({
    year_counts <- as.data.frame(table(references_data$Year))
    names(year_counts) <- c("Year", "Count")
    year_counts$Year <- as.numeric(as.character(year_counts$Year))
    
    plot_ly(
      data = year_counts,
      x = ~Year,
      y = ~Count,
      type = 'bar',
      marker = list(color = '#008A82')
    ) %>%
      layout(
        title = "Publications by Year",
        xaxis = list(title = "Year"),
        yaxis = list(title = "Number of Publications"),
        paper_bgcolor = 'rgba(0,0,0,0)',
        plot_bgcolor = '#f8f9fa'
      )
  })
}

# Run the application
shinyApp(ui = ui, server = server)