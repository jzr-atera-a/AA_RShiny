library(shiny)
library(shinydashboard)
library(plotly)
library(DT)
library(ggplot2)

# UI
ui <- dashboardPage(
  dashboardHeader(title = "Multi-Task Learning with Maximum Information Gain"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Introduction", tabName = "intro", icon = icon("home")),
      menuItem("Related Work", tabName = "related", icon = icon("book")),
      menuItem("Methodology", tabName = "methodology", icon = icon("cogs")),
      menuItem("Information Gain Strategy", tabName = "strategy", icon = icon("chart-line")),
      menuItem("Experiments", tabName = "experiments", icon = icon("flask")),
      menuItem("Conclusions", tabName = "conclusions", icon = icon("flag-checkered")),
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
        .description-text {
          font-size: 15px;
          line-height: 1.8;
          text-align: justify;
          color: #2c3e50;
        }
        .highlight-box {
          background: #fff3cd;
          border-left: 4px solid #f39c12;
          padding: 15px;
          margin: 10px 0;
          border-radius: 8px;
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
      # Introduction Tab
      tabItem(tabName = "intro",
              fluidRow(
                box(width = 12, title = "Introduction - Overview", status = "primary", solidHeader = TRUE,
                    div(class = "concept-box",
                        p(class = "description-text",
                          "This research introduces a novel approach to adaptively learn the dynamics of robotic systems using 
                          Multiple Output Gaussian Processes (MOGP) combined with maximum information gain strategies. The 
                          methodology addresses fundamental challenges in learning high-dimensional state-action spaces with 
                          unknown dependencies between inputs and outputs, which can be computationally expensive. Traditional 
                          model-based control relies on ordinary differential equations requiring extensive system knowledge and 
                          typically assumes stationary dynamics, ignoring environmental complexities like unknown disturbances. 
                          This research proposes a flexible learning methodology capable of learning complex dynamics from scratch 
                          and updating itself to current dynamic conditions, potentially providing more robustness than traditional 
                          approaches. Gaussian process modeling serves as the foundation—a Bayesian technique that naturally 
                          overcomes overfitting, one of machine learning's most difficult problems, making it highly appealing for 
                          online problems where testing multiple hypotheses is difficult. The computational cost of learning is 
                          reduced by maintaining a smaller dataset of highly informative training points rather than exhaustive 
                          sampling. The information gain strategy efficiently selects points from extremely large datasets through 
                          incremental updates, focusing on state-action pairs that maximize knowledge gain. This approach proves 
                          particularly valuable for learning behaviors of dynamic systems where complexity and disturbances make 
                          analytical definition infeasible. The benefits are verified through two comprehensive experiments: learning 
                          cart-pole dynamics in simulation and learning the dynamics of a real robotic blimp. Results demonstrate 
                          that MOGP with information gain achieves superior performance compared to random sampling and independent 
                          Gaussian processes, requiring fewer training points while maintaining higher prediction accuracy."
                        )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Research Motivation", status = "info", solidHeader = TRUE,
                    column(6,
                           div(class = "concept-box",
                               h4("Challenges in Traditional Approaches:"),
                               tags$ul(
                                 tags$li(strong("Parametric Model Limitations:"), " Traditional model-based control requires extensive 
                                         system knowledge and assumes stationary dynamics"),
                                 tags$li(strong("Ignored Complexities:"), " Environmental disturbances and time-varying conditions 
                                         often ignored in classical approaches"),
                                 tags$li(strong("High-Dimensional Spaces:"), " Learning from high-dimensional state-action spaces 
                                         computationally expensive"),
                                 tags$li(strong("Unknown Dependencies:"), " Dependencies between input and output dimensions 
                                         difficult to model"),
                                 tags$li(strong("Overfitting Risks:"), " Traditional machine learning approaches susceptible to 
                                         overfitting without careful regularization")
                               )
                           ),
                           
                           div(class = "highlight-box",
                               h4("Why Non-Parametric Bayesian Learning?"),
                               p(class = "description-text",
                                 "Non-parametric Bayesian techniques using Gaussian Processes offer significant advantages: they 
                                 naturally estimate prediction uncertainty, avoid overfitting through inherent Occam's Razor principles, 
                                 and can model complex nonlinear functions without requiring explicit functional forms."
                               )
                           )
                    ),
                    column(6,
                           div(class = "concept-box",
                               h4("Proposed Solution - Key Innovations:"),
                               tags$ul(
                                 tags$li(strong("MOGP Framework:"), " Multiple Output Gaussian Processes model dependencies between 
                                         output dimensions, requiring less training data"),
                                 tags$li(strong("Information Gain Strategy:"), " Actively selects most informative state-action 
                                         pairs rather than random or exhaustive sampling"),
                                 tags$li(strong("Incremental Learning:"), " Updates model incrementally as new observations 
                                         become available"),
                                 tags$li(strong("Efficient Exploration:"), " Maximizes knowledge gain per observation, reducing 
                                         data requirements"),
                                 tags$li(strong("Adaptive Control:"), " Uses LQR with learned model gradients to reach desired 
                                         state-action pairs")
                               )
                           ),
                           
                           div(class = "concept-box",
                               h4("Applications:"),
                               p(class = "description-text",
                                 "This methodology can be implemented for learning behavior of dynamic systems where complexity 
                                 and disturbances make analytical definition infeasible—ideal for autonomous robots, aerial 
                                 vehicles, and systems operating in uncertain environments."
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Research Contributions", status = "success", solidHeader = TRUE,
                    p(class = "description-text",
                      "This work makes three major contributions to robotic learning and control, each addressing critical 
                      limitations in current approaches while providing validated methodologies for practical applications."
                    )
                )
              ),
              
              fluidRow(
                column(4,
                       box(width = 12, title = "Multi-Task Learning with MOGP", status = "success", solidHeader = TRUE,
                           div(style = "text-align: center; padding: 20px;",
                               icon("project-diagram", style = "font-size: 48px; color: #00A39A;"),
                               h4(style = "margin-top: 10px; color: #008A82;", "Exploiting Output Dependencies")
                           ),
                           div(class = "concept-box",
                               p(class = "description-text",
                                 "Extends Gaussian Process regression to multiple outputs through process convolutions, 
                                 enabling the model to learn cross-correlations between output dimensions. This significantly 
                                 reduces training data requirements compared to independent single-output GPs. Uses specialized 
                                 covariance functions (auto-covariance and cross-covariance) to model task dependencies, 
                                 improving prediction accuracy and generalization."
                               )
                           )
                       )
                ),
                column(4,
                       box(width = 12, title = "Maximum Information Gain Strategy", status = "info", solidHeader = TRUE,
                           div(style = "text-align: center; padding: 20px;",
                               icon("chart-line", style = "font-size: 48px; color: #3498db;"),
                               h4(style = "margin-top: 10px; color: #2980b9;", "Active Learning Approach")
                           ),
                           div(class = "concept-box",
                               p(class = "description-text",
                                 "Develops greedy algorithm for selecting training points that maximize differential entropy 
                                 reduction, efficiently exploring state-action space. Selects observations with highest predicted 
                                 variance, focusing computational resources on informative regions. Enables incremental model 
                                 updates as new observations become available, suitable for online learning scenarios. Achieves 
                                 faster convergence than random or uniform sampling strategies."
                               )
                           )
                       )
                ),
                column(4,
                       box(width = 12, title = "Integrated Learning-Control Framework", status = "warning", solidHeader = TRUE,
                           div(style = "text-align: center; padding: 20px;",
                               icon("robot", style = "font-size: 48px; color: #9b59b6;"),
                               h4(style = "margin-top: 10px; color: #8e44ad;", "LQR with Learned Dynamics")
                           ),
                           div(class = "concept-box",
                               p(class = "description-text",
                                 "Combines information gain strategy with Linear Quadratic Regulator (LQR) control to reach 
                                 desired state-action pairs for observation. Computes LQR matrices from learned model gradients, 
                                 enabling closed-loop exploration. Validated on both simulated systems (cart-pole, blimp) and 
                                 real robotic platform (1.8m blimp with monocular camera). Demonstrates practical applicability 
                                 for autonomous systems learning in real-time."
                               )
                           )
                       )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Problem Formulation", status = "primary", solidHeader = TRUE,
                    column(6,
                           h4("Learning Objective:"),
                           div(class = "math-formula",
                               p("Model state transitions in discrete-time dynamic systems:"),
                               withMathJax("$$s_{t+1} = f(s_t, a_t)$$"),
                               p("where:"),
                               tags$ul(
                                 tags$li(withMathJax("$s_t \\in \\mathbb{R}^d$"), " is the system state at time ", 
                                         withMathJax("$t$")),
                                 tags$li(withMathJax("$a_t \\in \\mathbb{R}^m$"), " is the action at time ", 
                                         withMathJax("$t$")),
                                 tags$li(withMathJax("$f: \\mathbb{R}^{d+m} \\rightarrow \\mathbb{R}^d$"), 
                                         " is the unknown dynamics function"),
                                 tags$li(withMathJax("$s_{t+1}$"), " is the resultant state")
                               )
                           ),
                           
                           div(class = "concept-box",
                               h5("Training Data:"),
                               withMathJax("$$\\mathcal{D} = \\{(x_i, y_i)\\}_{i=1}^N$$"),
                               p("where ", withMathJax("$x_i = [s_i, a_i]$"), " (state-action pairs) and ", 
                                 withMathJax("$y_i = s_{i+1}$"), " (resultant states)")
                           )
                    ),
                    column(6,
                           h4("Key Challenges:"),
                           div(class = "concept-box",
                               tags$ul(
                                 tags$li(strong("High Dimensionality:"), " State-action spaces can have many dimensions 
                                         (e.g., cart-pole: 5D input, 4D output)"),
                                 tags$li(strong("Unknown Dependencies:"), " Correlations between output dimensions not 
                                         known a priori"),
                                 tags$li(strong("Computational Cost:"), " Standard GP: ", withMathJax("$O(n^3)$"), 
                                         " for training, MOGP: ", withMathJax("$O(m^3n^3)$"), " where ", 
                                         withMathJax("$m$"), " is number of outputs"),
                                 tags$li(strong("Data Efficiency:"), " Need to minimize training points while maintaining 
                                         prediction accuracy"),
                                 tags$li(strong("Online Learning:"), " Must update model as system operates in real-time")
                               )
                           ),
                           
                           div(class = "highlight-box",
                               h5("Solution Approach:"),
                               tags$ol(
                                 tags$li("Use MOGP to model output dependencies"),
                                 tags$li("Select informative points via maximum information gain"),
                                 tags$li("Use LQR to reach desired state-action pairs"),
                                 tags$li("Update model incrementally with new observations")
                               )
                           )
                    )
                )
              )
      ),
      
      # Related Work Tab
      tabItem(tabName = "related",
              fluidRow(
                box(width = 12, title = "Related Work - Overview", status = "primary", solidHeader = TRUE,
                    div(class = "concept-box",
                        p(class = "description-text",
                          "This section reviews the state-of-the-art in Gaussian Process-based learning for dynamic systems, 
                          active learning strategies, and multi-task learning approaches. Gaussian Processes have been successfully 
                          applied to learning discrete-time dynamic processes, where the difference between consecutive states 
                          conditioned on previous state-action pairs serves as training data. Each output dimension is typically 
                          treated as an independent task with a single-output GP, requiring trajectory sampling to ensure reliable 
                          correlation in training data. This approach was implemented on robotic blimps for yaw control, though 
                          the large exploration requirement makes it time-consuming and typically assumes time-invariant models 
                          without accounting for environmental changes. Reinforcement learning approaches have been proposed to 
                          model environment uncertainty through continuous interaction, with Bayesian active learning using utility 
                          functions to maximize information gain. Efficient exploration through sparsification has been explored, 
                          selecting observations based on minimum distance thresholds, though this can be suboptimal for highly 
                          nonlinear functions without sufficient training data. Various sparse approximation methods for GPs have 
                          been proposed using conditional independence between training and test data given inducing variables. 
                          The differential entropy score offers another approach for reducing training dataset size, selecting 
                          points for active datasets while jointly optimizing model parameters. Information gain has also been 
                          applied to robot path planning for environmental surveillance, selecting informative locations. Multi-task 
                          learning can improve generalization by exploring dependencies between related tasks—applied successfully 
                          to robot inverse dynamics where different load conditions are treated as contexts representing different 
                          inverse dynamics functions. Multi-task GPs exploit inter-task similarities among contexts for improved 
                          control performance. Multi-task covariance functions have been constructed through kernel convolutions, 
                          providing the theoretical foundation for defining valid covariance functions for MOGPs used in this research."
                        )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Gaussian Processes for Dynamics Learning", status = "info", solidHeader = TRUE,
                    column(6,
                           div(class = "concept-box",
                               h4("Traditional GP Approaches:"),
                               
                               h5("State Difference Modeling:"),
                               p(class = "description-text",
                                 "GPs used to learn discrete-time dynamic processes by modeling the difference between 
                                 consecutive states conditioned on previous state-action pairs. Each output dimension 
                                 treated as independent task with single-output GP."
                               ),
                               
                               h5("Trajectory-Based Training:"),
                               tags$ul(
                                 tags$li("Trajectory defined by consecutive state-action pairs"),
                                 tags$li("Multiple trajectories sampled for reliable correlation"),
                                 tags$li("Applied to robotic blimp yaw control"),
                                 tags$li("Performance depends on large exploration task"),
                                 tags$li("Can be very time-consuming")
                               ),
                               
                               div(class = "highlight-box",
                                   h5("Limitations:"),
                                   tags$ul(
                                     tags$li("Assumes time-invariant (stationary) model"),
                                     tags$li("Does not account for dynamics changes"),
                                     tags$li("Ignores environmental variations"),
                                     tags$li("Requires extensive trajectory sampling"),
                                     tags$li("Independent output modeling ignores correlations")
                                   )
                               )
                           )
                    ),
                    column(6,
                           div(class = "concept-box",
                               h4("Reinforcement Learning Integration:"),
                               
                               p(class = "description-text",
                                 "Proposed approaches model environment uncertainty through continuous interaction using 
                                 reinforcement learning. Bayesian active learning with utility functions selects training 
                                 data to maximize information gain."
                               ),
                               
                               h5("Key Works:"),
                               tags$ul(
                                 tags$li(strong("Ko et al.:"), " GP and RL for autonomous blimp identification and control"),
                                 tags$li(strong("Liu et al.:"), " Q-learning for navigation control of autonomous blimp"),
                                 tags$li(strong("Deisenroth et al.:"), " Gaussian Process Dynamic Programming"),
                                 tags$li(strong("Rottmann & Burgard:"), " Adaptive control using online value iteration with GPs")
                               )
                           ),
                           
                           div(class = "concept-box",
                               h4("Advantages of GP-Based Learning:"),
                               tags$ul(
                                 tags$li("Natural uncertainty quantification"),
                                 tags$li("Avoids overfitting through Bayesian principles"),
                                 tags$li("No explicit functional form required"),
                                 tags$li("Handles nonlinear dynamics effectively"),
                                 tags$li("Provides probabilistic predictions")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Sparse Approximations & Active Learning", status = "success", solidHeader = TRUE,
                    column(4,
                           div(class = "concept-box",
                               h4("Sparsification Methods:"),
                               
                               h5("Distance-Based Selection:"),
                               p(class = "description-text",
                                 "Observations selected based on minimum distance threshold. Works well for uniformly 
                                 spaced data points but can be suboptimal for highly nonlinear functions."
                               ),
                               
                               h5("Limitations:"),
                               tags$ul(
                                 tags$li("Requires equally spaced points"),
                                 tags$li("May struggle with high variation regions"),
                                 tags$li("Assumes smooth stationary kernel"),
                                 tags$li("Not adaptive to local complexity")
                               ),
                               
                               h5("Inducing Variable Approaches:"),
                               p(class = "description-text",
                                 "Sparse approximations using conditional independence between training and test data 
                                 given inducing variables. Provides unifying framework for GP sparsification."
                               )
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h4("Differential Entropy Score:"),
                               
                               p(class = "description-text",
                                 "Alternative approach using differential entropy score to reduce training dataset size. 
                                 Selects training points for active dataset while jointly optimizing model parameters."
                               ),
                               
                               div(class = "math-formula",
                                   h5("Entropy-Based Selection:"),
                                   withMathJax("$$\\Delta_j = H[p(f_j)] - H[p^{new}(f_j)]$$"),
                                   p("Select point that maximizes entropy reduction")
                               ),
                               
                               h5("Key Reference:"),
                               p(strong("Lawrence et al.:"), " Fast sparse Gaussian process methods - The Informative 
                                 Vector Machine. Focuses computational effort on most informative observations.")
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h4("Path Planning Applications:"),
                               
                               p(class = "description-text",
                                 "Information gain applied to robot path planning for environmental surveillance. 
                                 New training point selected when information gain threshold exceeded."
                               ),
                               
                               h5("Singh et al. Approach:"),
                               tags$ul(
                                 tags$li("Spatio-temporal process modeling"),
                                 tags$li("Environmental surveillance tasks"),
                                 tags$li("Selects most informative locations"),
                                 tags$li("Optimizes exploration path"),
                                 tags$li("Balances coverage and information gain")
                               ),
                               
                               div(class = "highlight-box",
                                   p(strong("Connection to This Work:"), " Similar information gain principle 
                                     applied to dynamics learning rather than spatial exploration.")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Multi-Task Learning", status = "warning", solidHeader = TRUE,
                    column(6,
                           div(class = "concept-box",
                               h4("Multi-Task Learning Principles:"),
                               
                               p(class = "description-text",
                                 "Multi-task learning improves generalization by exploring dependencies between related 
                                 tasks. Rather than learning each task independently, shared structure across tasks 
                                 enables more efficient learning with less data per task."
                               ),
                               
                               h5("Key Concepts:"),
                               tags$ul(
                                 tags$li(strong("Task Relatedness:"), " Exploits similarities between tasks"),
                                 tags$li(strong("Shared Representations:"), " Learns common features across tasks"),
                                 tags$li(strong("Transfer Learning:"), " Knowledge from one task helps others"),
                                 tags$li(strong("Data Efficiency:"), " Reduces per-task data requirements"),
                                 tags$li(strong("Improved Generalization:"), " Better performance on all tasks")
                               ),
                               
                               div(class = "math-formula",
                                   h5("Multi-Task Advantage:"),
                                   p("For ", withMathJax("$m$"), " tasks with ", withMathJax("$n$"), " samples each:"),
                                   tags$ul(
                                     tags$li("Independent GPs: ", withMathJax("$m \\times O(n^3)$"), " complexity"),
                                     tags$li("MOGP: ", withMathJax("$O(m^3n^3)$"), " but requires fewer samples"),
                                     tags$li("Net benefit when task dependencies strong")
                                   )
                               )
                           )
                    ),
                    column(6,
                           div(class = "concept-box",
                               h4("Multi-Task GPs for Robotics:"),
                               
                               h5("Robot Inverse Dynamics (Chai et al.):"),
                               p(class = "description-text",
                                 "Multi-task GP applied to robot manipulator control with different loads. Each load 
                                 condition (context) represents different inverse dynamics function. Multi-task GP 
                                 exploits inter-context similarities for improved control."
                               ),
                               
                               h5("Contexts as Tasks:"),
                               tags$ul(
                                 tags$li("Different loads = different contexts"),
                                 tags$li("Each context has unique dynamics"),
                                 tags$li("Contexts share underlying structure"),
                                 tags$li("Cross-context learning improves all tasks"),
                                 tags$li("Achieves higher control performance")
                               )
                           ),
                           
                           div(class = "concept-box",
                               h4("Kernel Convolutions (Boyle & Frean):"),
                               
                               p(class = "description-text",
                                 "Multi-task covariance functions constructed through kernel convolutions. Provides 
                                 theoretical foundation for valid covariance functions in MOGPs."
                               ),
                               
                               h5("Contribution to This Work:"),
                               p(class = "description-text",
                                 "This research builds on kernel convolution framework to define auto-covariance and 
                                 cross-covariance functions for modeling dependencies between output dimensions in 
                                 dynamic system learning."
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Research Positioning", status = "primary", solidHeader = TRUE,
                    column(6,
                           h4("Building on Prior Work:"),
                           div(class = "concept-box",
                               tags$ul(
                                 tags$li(strong("GP Dynamics Learning:"), " Extends trajectory-based approaches with information 
                                         gain for efficient exploration"),
                                 tags$li(strong("Active Learning:"), " Applies differential entropy score to dynamics learning 
                                         rather than just spatial exploration"),
                                 tags$li(strong("Multi-Task Framework:"), " Uses kernel convolution theory to model output 
                                         dependencies in system dynamics"),
                                 tags$li(strong("Sparse Methods:"), " Incorporates information gain for intelligent sample 
                                         selection rather than distance-based sparsification"),
                                 tags$li(strong("Control Integration:"), " Combines learning strategy with LQR for closed-loop 
                                         exploration")
                               )
                           )
                    ),
                    column(6,
                           h4("Novel Contributions:"),
                           div(class = "concept-box",
                               tags$ul(
                                 tags$li(strong("Integrated Framework:"), " Combines MOGP + information gain + LQR control in 
                                         unified approach"),
                                 tags$li(strong("Dynamics-Specific:"), " Tailored specifically for learning system dynamics 
                                         rather than general regression"),
                                 tags$li(strong("Real-Time Capability:"), " Demonstrated on real robotic platform with online 
                                         learning"),
                                 tags$li(strong("Validated Performance:"), " Comprehensive experiments on simulation and real 
                                         systems"),
                                 tags$li(strong("Practical Applicability:"), " Proven effective for autonomous aerial vehicle 
                                         in real-world conditions")
                               )
                           )
                    )
                )
              )
      ),
      
      # Methodology Tab
      tabItem(tabName = "methodology",
              fluidRow(
                box(width = 12, title = "Methodology - Overview", status = "primary", solidHeader = TRUE,
                    div(class = "concept-box",
                        p(class = "description-text",
                          "This section presents the theoretical foundations of the multi-task learning approach for system 
                          dynamics. The methodology centers on Gaussian Process regression, extended to multiple outputs through 
                          the Multiple Output Gaussian Process (MOGP) framework. Standard GP regression provides a non-parametric 
                          Bayesian technique that places multivariate Gaussian prior distributions over function spaces, naturally 
                          encoding Occam's Razor principle by balancing data fit with model complexity to avoid overfitting. Given 
                          a training dataset of input locations and target values, GPs compute predictive distributions at unobserved 
                          locations with associated uncertainties. The computational cost scales as O(n³) for training due to covariance 
                          matrix inversion and O(n²) for prediction. The MOGP extends this framework to model dependencies between 
                          multiple output dimensions through process convolutions with smoothing kernels. For two dependent outputs, 
                          the model constructs auto-covariance functions (relationships within same task) and cross-covariance functions 
                          (relationships between different tasks). These covariance functions are derived through convolution integrals 
                          with Gaussian smoothing kernels, yielding closed-form expressions parameterized by hyperparameters. The 
                          computational cost increases to O(m³n³) for m tasks, where the covariance matrix comprises m×m sub-matrices 
                          of auto-covariance and cross-covariance terms. However, when task dependencies are strong, the MOGP requires 
                          significantly less training data than independent GPs, providing net computational advantages. Hyperparameter 
                          learning maximizes the log marginal likelihood of observed training data. The predictive distribution for 
                          new points follows from conditioning the joint Gaussian distribution on observed data. This methodology 
                          provides the foundation for efficiently learning robotic system dynamics where multiple output dimensions 
                          (position, velocity, etc.) exhibit strong correlations, enabling more data-efficient learning than treating 
                          each dimension independently."
                        )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Gaussian Process Regression", status = "info", solidHeader = TRUE,
                    column(6,
                           h4("GP Fundamentals:"),
                           div(class = "concept-box",
                               p(class = "description-text",
                                 "A Gaussian Process is a non-parametric Bayesian technique that places a multivariate 
                                 Gaussian prior distribution over the space of functions ", withMathJax("$f(x)$"), 
                                 ", mapping inputs to outputs."
                               ),
                               
                               div(class = "math-formula",
                                   h5("GP Definition:"),
                                   withMathJax("$$f(x) \\sim \\mathcal{GP}(m(x), k(x,x'))$$"),
                                   p("where:"),
                                   tags$ul(
                                     tags$li(withMathJax("$m(x)$"), " is the mean function"),
                                     tags$li(withMathJax("$k(x,x')$"), " is the covariance (kernel) function")
                                   )
                               ),
                               
                               h5("Training Data:"),
                               withMathJax("$$\\mathcal{D} = \\{x_i, y_i\\}_{i=1}^N$$"),
                               p("where ", withMathJax("$x_i \\in \\mathbb{R}^D$"), " (inputs) and ", 
                                 withMathJax("$y_i \\in \\mathbb{R}$"), " (targets)")
                           )
                    ),
                    column(6,
                           h4("Observation Model:"),
                           div(class = "math-formula",
                               p("Noisy observations:"),
                               withMathJax("$$y = f(x) + \\epsilon$$"),
                               p("where ", withMathJax("$\\epsilon \\sim \\mathcal{N}(0, \\sigma_n^2)$")),
                               
                               h5("Joint Distribution:"),
                               withMathJax("$$\\begin{bmatrix} y \\\\ f_* \\end{bmatrix} \\sim \\mathcal{N}\\left(0, 
                                           \\begin{bmatrix} K(X,X) + \\sigma_n^2 I & K(X,X_*) \\\\ 
                                           K(X_*,X) & K(X_*,X_*) \\end{bmatrix}\\right)$$")
                           ),
                           
                           div(class = "concept-box",
                               h5("Key Advantages:"),
                               tags$ul(
                                 tags$li("Models complex nonlinear functions"),
                                 tags$li("Avoids overfitting (Occam's Razor)"),
                                 tags$li("Provides uncertainty estimates"),
                                 tags$li("No explicit functional form needed"),
                                 tags$li("Balances data fit with complexity")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "GP Prediction & Covariance Functions", status = "success", solidHeader = TRUE,
                    column(6,
                           h4("Predictive Distribution:"),
                           div(class = "math-formula",
                               p("Conditioning on observed data:"),
                               withMathJax("$$(f_* | X_*, X, y) = \\mathcal{N}(\\mu_*, \\Sigma_*)$$"),
                               
                               h5("Predictive Mean:"),
                               withMathJax("$$\\mu_* = K(X_*,X)[K(X,X) + \\sigma_n^2 I]^{-1}y$$"),
                               
                               h5("Predictive Variance:"),
                               withMathJax("$$\\Sigma_* = K(X_*,X_*) - K(X_*,X)[K(X,X) + \\sigma_n^2 I]^{-1}K(X,X_*)$$"),
                               
                               p(class = "description-text",
                                 "The mean is a linear combination of ", withMathJax("$N$"), " kernel functions: ",
                                 withMathJax("$\\mu_* = \\sum_{i=1}^N \\alpha_i k(x_i, x_*)$"), " with ",
                                 withMathJax("$\\alpha = [K(X,X) + \\sigma_n^2 I]^{-1}y$")
                               )
                           )
                    ),
                    column(6,
                           h4("Square Exponential Covariance:"),
                           div(class = "math-formula",
                               p("Most commonly used kernel function:"),
                               withMathJax("$$k(x,x') = \\sigma_f^2 \\exp\\left(-\\frac{1}{2}(x-x')^T\\Lambda(x-x')\\right)$$"),
                               
                               h5("Hyperparameters:"),
                               withMathJax("$$\\theta = \\{\\Lambda, \\sigma_f, \\sigma_n\\}$$"),
                               tags$ul(
                                 tags$li(withMathJax("$\\Lambda = \\text{diag}(l_1, \\ldots, l_d)$"), 
                                         " - weight matrix with length-scales"),
                                 tags$li(withMathJax("$\\sigma_f$"), " - signal variance (scale factor)"),
                                 tags$li(withMathJax("$\\sigma_n^2$"), " - noise variance")
                               )
                           ),
                           
                           div(class = "concept-box",
                               h5("Final Covariance Matrix:"),
                               withMathJax("$$K(X,X) + \\sigma_n^2 I$$"),
                               p(class = "description-text",
                                 "Combines signal covariance with observation noise on diagonal")
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Hyperparameter Learning", status = "warning", solidHeader = TRUE,
                    column(6,
                           h4("Maximum Likelihood Optimization:"),
                           div(class = "math-formula",
                               withMathJax("$$\\theta_{max} = \\arg\\max_\\theta \\{\\log(p(y|X,\\theta))\\}$$"),
                               
                               h5("Log Marginal Likelihood:"),
                               withMathJax("$$\\log(p(y|X)) = -\\frac{1}{2}y^T(K(X,X) + \\sigma_n^2 I)^{-1}y$$"),
                               withMathJax("$$-\\frac{1}{2}\\log|K(X,X) + \\sigma_n^2 I| - \\frac{n}{2}\\log 2\\pi$$"),
                               
                               p(class = "description-text",
                                 "Three terms represent: (1) data fit, (2) complexity penalty, (3) normalization constant"
                               )
                           )
                    ),
                    column(6,
                           h4("Computational Complexity:"),
                           div(class = "concept-box",
                               h5("Training (Hyperparameter Learning):"),
                               withMathJax("$$O(n^3)$$"),
                               p("Due to covariance matrix inversion ", 
                                 withMathJax("$(K(X,X) + \\sigma_n^2 I)^{-1}$")),
                               
                               h5("Prediction (Single Test Point):"),
                               withMathJax("$$O(n^2)$$"),
                               p("Matrix-vector multiplication for computing ", withMathJax("$\\mu_*$")),
                               
                               div(class = "highlight-box",
                                   p(strong("Motivation for Sparse Approaches:"), " Computational cost grows cubically 
                                     with training set size, making efficient data selection crucial for large-scale 
                                     or real-time applications.")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Multiple Output Gaussian Process (MOGP)", status = "primary", solidHeader = TRUE,
                    p(class = "description-text",
                      "The MOGP extends single-output GPs to model dependencies between multiple output dimensions through 
                      process convolutions. This section presents the two-output case; generalization to more outputs follows 
                      straightforwardly."
                    ),
                    
                    column(6,
                           div(class = "concept-box",
                               h4("Process Convolution Framework:"),
                               
                               h5("Single Output GP:"),
                               p(class = "description-text",
                                 "Output obtained by convolving input with smoothing kernel plus noise: ",
                                 withMathJax("$y = V + \\epsilon$")
                               ),
                               
                               h5("Two-Output MOGP:"),
                               p(class = "description-text",
                                 "Each output is sum of two process convolutions plus noise:"
                               ),
                               withMathJax("$$y_1 = V_1 + U_1 + \\epsilon_1$$"),
                               withMathJax("$$y_2 = V_2 + U_2 + \\epsilon_2$$"),
                               
                               p(class = "description-text",
                                 "where ", withMathJax("$V_i$"), " and ", withMathJax("$U_i$"), 
                                 " are process convolutions with smoothing kernels ", withMathJax("$h_i$"), 
                                 " and ", withMathJax("$k_i$")
                               )
                           ),
                           
                           div(class = "math-formula",
                               h5("Training Data Structure:"),
                               tags$ul(
                                 tags$li(withMathJax("$X_0$"), " - shared training data between outputs"),
                                 tags$li(withMathJax("$X_1$"), " - training data only for ", withMathJax("$y_1$")),
                                 tags$li(withMathJax("$X_2$"), " - training data only for ", withMathJax("$y_2$"))
                               )
                           )
                    ),
                    column(6,
                           div(class = "concept-box",
                               h4("Gaussian Smoothing Kernels:"),
                               div(class = "math-formula",
                                   withMathJax("$$k_1(x) = v_1 \\exp\\left(-\\frac{1}{2}x^T\\Lambda_1 x\\right)$$"),
                                   withMathJax("$$k_2(x) = v_2 \\exp\\left(-\\frac{1}{2}x^T\\Lambda_2 x\\right)$$"),
                                   withMathJax("$$h_i(x) = w_i \\exp\\left(-\\frac{1}{2}x^T\\beta_i x\\right)$$")
                               )
                           ),
                           
                           div(class = "concept-box",
                               h4("Hyperparameters:"),
                               withMathJax("$$\\Theta = \\{v_1, v_2, w_1, w_2, \\Lambda_1, \\Lambda_2, \\beta_1, \\beta_2, 
                                           \\sigma_1, \\sigma_2\\}$$"),
                               
                               h5("Physical Interpretation:"),
                               tags$ul(
                                 tags$li(withMathJax("$v_i, w_i$"), " - amplitude parameters"),
                                 tags$li(withMathJax("$\\Lambda_i, \\beta_i$"), " - length-scale matrices"),
                                 tags$li(withMathJax("$\\sigma_i$"), " - observation noise")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "MOGP Covariance Functions", status = "info", solidHeader = TRUE,
                    column(6,
                           h4("Auto-Covariance & Cross-Covariance:"),
                           div(class = "math-formula",
                               h5("Auto-Covariance (i = j):"),
                               p("Models relationships within same task:"),
                               withMathJax("$$K_{11}^Y(x,x') = K_{11}^U(x,x') + K_{11}^V(x,x') + \\delta_{ab}\\sigma_1^2$$"),
                               withMathJax("$$K_{22}^Y(x,x') = K_{22}^U(x,x') + K_{22}^V(x,x') + \\delta_{ab}\\sigma_2^2$$"),
                               
                               h5("Cross-Covariance (i ≠ j):"),
                               p("Models relationships between tasks:"),
                               withMathJax("$$K_{12}^Y(x,x') = K_{12}^U(x,x')$$"),
                               withMathJax("$$K_{21}^Y(x,x') = K_{21}^U(x,x')$$"),
                               
                               p(class = "description-text",
                                 "where ", withMathJax("$\\delta_{ab}$"), " is Kronecker delta (1 if a=b, 0 otherwise)"
                               )
                           )
                    ),
                    column(6,
                           h4("Closed-Form Expressions:"),
                           div(class = "math-formula",
                               withMathJax("$$K_{ii}^U(x,x') = \\frac{\\pi^{p/2}v_i^2}{\\sqrt{|\\Lambda_i|}} 
                                           \\exp\\left(-\\frac{1}{4}(x-x')^T\\Lambda_i(x-x')\\right)$$"),
                               
                               withMathJax("$$K_{12}^U(x,x') = \\frac{2\\pi^{p/2}v_1v_2}{\\sqrt{|\\Lambda_1+\\Lambda_2|}} 
                                           \\exp\\left(-\\frac{1}{2}(x-x')^T\\Sigma(x-x')\\right)$$"),
                               
                               withMathJax("$$K_{ii}^V(x,x') = \\frac{\\pi^{p/2}w_i^2}{\\sqrt{|\\beta_i|}} 
                                           \\exp\\left(-\\frac{1}{4}(x-x')^T\\beta_i(x-x')\\right)$$"),
                               
                               p("where:"),
                               withMathJax("$$\\Sigma = \\Lambda_1(\\Lambda_1+\\Lambda_2)^{-1}\\Lambda_2 = 
                                           \\Lambda_2(\\Lambda_1+\\Lambda_2)^{-1}\\Lambda_1$$")
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "MOGP Inference & Complexity", status = "success", solidHeader = TRUE,
                    column(6,
                           h4("Covariance Matrix Structure:"),
                           div(class = "math-formula",
                               p("For two outputs:"),
                               withMathJax("$$K = \\begin{bmatrix} K_{11} & K_{12} \\\\ K_{21} & K_{22} \\end{bmatrix}$$"),
                               
                               p("Each sub-matrix:"),
                               withMathJax("$$K_{ij} = \\begin{bmatrix} K_{ij}^Y(x_{i,1},x_{j,1}) & \\cdots & 
                                           K_{ij}^Y(x_{i,1},x_{j,N_j}) \\\\ 
                                           \\vdots & \\ddots & \\vdots \\\\ 
                                           K_{ij}^Y(x_{i,N_i},x_{j,1}) & \\cdots & K_{ij}^Y(x_{i,N_i},x_{j,N_j}) 
                                           \\end{bmatrix}$$")
                           ),
                           
                           div(class = "concept-box",
                               h5("Log Marginal Likelihood:"),
                               withMathJax("$$\\log(p(y|X)) = -\\frac{1}{2}\\log|K| - \\frac{1}{2}y^TK^{-1}y 
                                           - \\frac{N_1+N_2}{2}\\log 2\\pi$$"),
                               p("where ", withMathJax("$y^T = [y_{1,1} \\cdots y_{1,N_1} \\, y_{2,1} \\cdots y_{2,N_2}]$"))
                           )
                    ),
                    column(6,
                           h4("MOGP Predictions:"),
                           div(class = "math-formula",
                               p("For output ", withMathJax("$i$"), " at point ", withMathJax("$x_*$"), ":"),
                               
                               h5("Predictive Distribution:"),
                               withMathJax("$$(f_* | x_*, X, y) = \\mathcal{N}(\\mu_*, \\Sigma_*)$$"),
                               
                               h5("Predictive Mean:"),
                               withMathJax("$$\\mu_* = k^T K^{-1}y$$"),
                               
                               h5("Predictive Variance:"),
                               withMathJax("$$\\Sigma_* = \\bar{k} - k^T K^{-1}k$$"),
                               
                               p("where:"),
                               withMathJax("$$\\bar{k} = K_{ii}^Y(0) = v_i^2 + w_i^2 + \\sigma_i^2$$"),
                               withMathJax("$$k = \\begin{bmatrix} K_{i1}^Y(x_*,x_{1,1}) \\cdots K_{i1}^Y(x_*,x_{1,N_1}) \\\\ 
                                           K_{i2}^Y(x_*,x_{2,1}) \\cdots K_{i2}^Y(x_*,x_{2,N_2}) \\end{bmatrix}^T$$")
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Computational Complexity Comparison", status = "warning", solidHeader = TRUE,
                    column(6,
                           div(class = "concept-box",
                               h4("Single-Output GP:"),
                               tags$ul(
                                 tags$li(strong("Training:"), " ", withMathJax("$O(n^3)$")),
                                 tags$li(strong("Prediction:"), " ", withMathJax("$O(n^2)$")),
                                 tags$li(strong("For m independent tasks:"), " ", withMathJax("$m \\times O(n^3)$"))
                               )
                           ),
                           
                           div(class = "concept-box",
                               h4("Multiple-Output GP (MOGP):"),
                               tags$ul(
                                 tags$li(strong("Training:"), " ", withMathJax("$O(m^3n^3)$")),
                                 tags$li(strong("Prediction:"), " ", withMathJax("$O(m^2n^2)$")),
                                 tags$li(strong("Covariance matrix:"), " ", withMathJax("$m \\times m$"), 
                                         " blocks of ", withMathJax("$n \\times n$"), " matrices")
                               )
                           )
                    ),
                    column(6,
                           div(class = "highlight-box",
                               h4("When is MOGP Beneficial?"),
                               
                               p(class = "description-text",
                                 "Despite higher computational complexity, MOGP can be more efficient when:"
                               ),
                               
                               tags$ul(
                                 tags$li(strong("Strong Task Dependencies:"), " Cross-covariance captures correlations 
                                         between outputs"),
                                 tags$li(strong("Reduced Data Requirements:"), " Requires fewer samples ", withMathJax("$n$"), 
                                         " compared to independent GPs"),
                                 tags$li(strong("Shared Information:"), " Training data for one task helps predict others"),
                                 tags$li(strong("Net Computational Gain:"), " Smaller ", withMathJax("$n$"), " can offset 
                                         ", withMathJax("$m^3$"), " factor"),
                                 tags$li(strong("Better Generalization:"), " Exploiting task structure improves predictions")
                               ),
                               
                               p(class = "description-text", style = "margin-top: 10px;",
                                 strong("Key Insight:"), " For system dynamics where output dimensions (position, velocity, 
                                 acceleration, etc.) are strongly correlated, MOGP achieves better performance with less 
                                 total training data than independent GPs."
                               )
                           )
                    )
                )
              )
      ),
      
      # Strategy Tab
      tabItem(tabName = "strategy",
              fluidRow(
                box(width = 12, title = "Information Gain Strategy - Overview", status = "primary", solidHeader = TRUE,
                    div(class = "concept-box",
                        p(class = "description-text",
                          "This section presents the information gain strategy for efficient exploration of state-action spaces 
                          in robotic learning. The core idea is to select training points that maximize differential entropy 
                          reduction rather than sampling randomly or uniformly. The strategy is based on the Informative Vector 
                          Machine approach, using a greedy algorithm to select the next training point that maximizes the information 
                          gain between the current model and the model after adding a new observation. Information gain is quantified 
                          through the differential entropy score, computed as the difference between the current prediction entropy 
                          and the entropy after observation inclusion. For Gaussian distributions, this reduces to selecting points 
                          with the highest predicted variance. The Linear Quadratic Regulator (LQR) provides closed-loop control 
                          to reach desired state-action pairs for observation. LQR is optimal for linear systems and can be applied 
                          to nonlinear systems through first-order linearization using Jacobians of the learned dynamics model. 
                          The integrated algorithm iteratively: (1) optimizes hyperparameters based on current training data, 
                          (2) computes information gain scores for all candidate points, (3) selects the point with maximum gain, 
                          (4) uses LQR to reach that state-action pair, (5) adds the observed outcome to the training set, and 
                          (6) repeats until information gain falls below a threshold indicating sufficient model quality. For 
                          multiple-output GPs, the variance differs across output dimensions, so one new point is selected per 
                          output dimension at each iteration. The computational cost per iteration is O(n²) for single-output GP 
                          and O(m²n²) for MOGP with m outputs. This active learning strategy enables efficient exploration by 
                          focusing on informative regions of the state-action space, achieving higher prediction accuracy with 
                          fewer training points compared to random or uniform sampling approaches. The method proves particularly 
                          effective for high-dimensional nonlinear systems where uniform grids become computationally prohibitive."
                        )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Information Gain Principles", status = "info", solidHeader = TRUE,
                    column(6,
                           div(class = "concept-box",
                               h4("Motivation for Active Learning:"),
                               
                               p(class = "description-text",
                                 "Random or uniform sampling is inefficient for high-dimensional spaces. Not all regions 
                                 of state-action space are equally informative. Active learning focuses computational 
                                 resources on regions of high uncertainty."
                               ),
                               
                               h5("Key Challenges:"),
                               tags$ul(
                                 tags$li("High-dimensional state-action spaces"),
                                 tags$li("Computational cost grows with training data"),
                                 tags$li("Nonlinear dynamics require dense sampling"),
                                 tags$li("Uniform grids become intractable"),
                                 tags$li("Need intelligent exploration strategy")
                               )
                           ),
                           
                           div(class = "highlight-box",
                               h4("Information Gain Intuition:"),
                               p(class = "description-text",
                                 "Select training points that maximally reduce our uncertainty about the dynamics. 
                                 Points in well-understood regions provide little new information, while points in 
                                 high-uncertainty regions significantly improve the model."
                               )
                           )
                    ),
                    column(6,
                           div(class = "concept-box",
                               h4("Differential Entropy Score:"),
                               
                               div(class = "math-formula",
                                   h5("Information Gain Definition:"),
                                   withMathJax("$$\\Delta_j = H[p(f_j)] - H[p^{new}(f_j)]$$"),
                                   
                                   p("where:"),
                                   tags$ul(
                                     tags$li(withMathJax("$H[p(f_j)]$"), " - entropy before observation"),
                                     tags$li(withMathJax("$H[p^{new}(f_j)]$"), " - entropy after observation"),
                                     tags$li(withMathJax("$\\Delta_j$"), " - reduction in uncertainty")
                                   )
                               ),
                               
                               h5("For Gaussian Distributions:"),
                               p("Entropy of Gaussian with variance ", withMathJax("$v_j$"), ":"),
                               withMathJax("$$H[p(f_j)] = \\log(2\\pi e v_j)$$")
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Information Gain Computation", status = "success", solidHeader = TRUE,
                    column(6,
                           h4("Variance After Observation:"),
                           div(class = "math-formula",
                               p("Bayesian update with new observation:"),
                               withMathJax("$$p(f_j | y_I, y_j) \\propto p(f_j|y_I)\\mathcal{N}(y_j|f_j, \\sigma^2)$$"),
                               
                               p("where ", withMathJax("$y_I$"), " is current training data"),
                               
                               h5("Updated Variance:"),
                               withMathJax("$$(v_j^{new})^{-1} = v_j^{-1} + \\sigma^{-2}$$"),
                               
                               p("Solving for ", withMathJax("$v_j^{new}$"), ":"),
                               withMathJax("$$v_j^{new} = \\frac{v_j \\sigma^2}{v_j + \\sigma^2}$$")
                           )
                    ),
                    column(6,
                           h4("Closed-Form Information Gain:"),
                           div(class = "math-formula",
                               h5("Entropy Difference:"),
                               withMathJax("$$\\Delta_j = \\log(2\\pi e v_j) - \\log(2\\pi e v_j^{new})$$"),
                               
                               h5("Simplified Form:"),
                               withMathJax("$$\\Delta_j = \\log\\left(1 + \\frac{v_j}{\\sigma^2}\\right)$$"),
                               
                               div(class = "highlight-box",
                                   p(strong("Key Result:"), " Information gain is maximized by selecting points with 
                                     highest predicted variance ", withMathJax("$v_j$"), ". This is equivalent to 
                                     uncertainty sampling.")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Point Selection Strategy", status = "warning", solidHeader = TRUE,
                    column(4,
                           div(class = "concept-box",
                               h4("Single-Output GP:"),
                               
                               div(class = "math-formula",
                                   h5("Selection Criterion:"),
                                   withMathJax("$$x_{new} = \\arg\\max_{x_{new} \\in \\mathbb{R}^D} \\Delta_j$$"),
                                   
                                   p("Equivalent to:"),
                                   withMathJax("$$x_{new} = \\arg\\max_{x_{new} \\in \\mathbb{R}^D} v_j$$")
                               ),
                               
                               p(class = "description-text",
                                 "Select the point with maximum predictive variance from GP model"
                               )
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h4("Multiple-Output GP:"),
                               
                               p(class = "description-text",
                                 "For MOGP with ", withMathJax("$m$"), " outputs, variance ", withMathJax("$v_{f,n}$"), 
                                 " differs for each output dimension ", withMathJax("$y_n$"), "."
                               ),
                               
                               h5("Selection Strategy:"),
                               tags$ul(
                                 tags$li("Compute variance for each output dimension"),
                                 tags$li("Select ", withMathJax("$m$"), " new points per iteration"),
                                 tags$li("One point per output dimension"),
                                 tags$li("Each maximizes that dimension's variance")
                               ),
                               
                               p(class = "description-text",
                                 "This accounts for different uncertainty levels across output tasks"
                               )
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h4("Stopping Criterion:"),
                               
                               div(class = "math-formula",
                                   withMathJax("$$\\max_j \\Delta_j < \\text{threshold}$$")
                               ),
                               
                               p(class = "description-text",
                                 "Stop when maximum information gain falls below acceptable threshold, indicating 
                                 sufficient model quality"
                               ),
                               
                               h5("Threshold Selection:"),
                               tags$ul(
                                 tags$li("Application-dependent"),
                                 tags$li("Balances accuracy vs. data cost"),
                                 tags$li("Related to prediction requirements"),
                                 tags$li("Can be based on validation error")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Linear Quadratic Regulator (LQR)", status = "primary", solidHeader = TRUE,
                    p(class = "description-text",
                      "LQR provides optimal control for reaching desired state-action pairs identified by the information 
                      gain strategy. It enables closed-loop exploration where the system actively navigates to informative regions."
                    ),
                    
                    column(6,
                           h4("LQR for Linear Systems:"),
                           div(class = "math-formula",
                               h5("Linear Dynamics:"),
                               withMathJax("$$s_{t+1} = A_t s_t + B_t a_t + \\epsilon_t$$"),
                               
                               p("where:"),
                               tags$ul(
                                 tags$li(withMathJax("$s_t, s_{t+1}$"), " - states at times ", withMathJax("$t, t+1$")),
                                 tags$li(withMathJax("$a_t$"), " - action at time ", withMathJax("$t$")),
                                 tags$li(withMathJax("$A_t, B_t$"), " - system matrices"),
                                 tags$li(withMathJax("$\\epsilon_t$"), " - system noise")
                               ),
                               
                               p(class = "description-text",
                                 "LQR computes optimal control that minimizes quadratic cost function"
                               )
                           ),
                           
                           div(class = "concept-box",
                               h4("LQR Benefits:"),
                               tags$ul(
                                 tags$li("Optimal control for linear systems"),
                                 tags$li("Handles state and control constraints"),
                                 tags$li("Provides smooth trajectories"),
                                 tags$li("Computationally efficient"),
                                 tags$li("Well-established theory")
                               )
                           )
                    ),
                    column(6,
                           h4("LQR for Nonlinear Systems:"),
                           div(class = "math-formula",
                               h5("Linearization via Jacobians:"),
                               withMathJax("$$s_{t+1} \\approx \\hat{f}(s_t, a_t)$$"),
                               
                               h5("Jacobian Matrices:"),
                               withMathJax("$$\\hat{A}_t = D_s\\hat{f}(s,a)|_{s=s_t^*, a=a_t^*}$$"),
                               withMathJax("$$\\hat{B}_t = D_a\\hat{f}(s,a)|_{s=s_t^*, a=a_t^*}$$"),
                               
                               p("where:"),
                               tags$ul(
                                 tags$li(withMathJax("$D_s, D_a$"), " - derivatives w.r.t. state and action"),
                                 tags$li(withMathJax("$s_t^*, a_t^*$"), " - points along target trajectory"),
                                 tags$li(withMathJax("$\\hat{f}$"), " - learned dynamics model (MOGP)")
                               )
                           ),
                           
                           div(class = "highlight-box",
                               h4("Approximation Validity:"),
                               p(class = "description-text",
                                 "Linearization sufficient when approximate model captures derivatives well, especially 
                                 the sign of derivative elements along trajectory. MOGP provides continuous differentiable 
                                 predictions enabling gradient computation."
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Complete Learning Algorithm", status = "success", solidHeader = TRUE,
                    column(6,
                           div(class = "concept-box",
                               h4("Algorithm 1: Information Gain Learning"),
                               
                               div(style = "background: #f8f9fa; padding: 15px; border-radius: 8px; font-family: monospace;",
                                   strong("Input:"), br(),
                                   "  X, y, Θ (initial training data and hyperparameters)", br(), br(),
                                   
                                   strong("Output:"), br(),
                                   "  Θ_trained, X_I, y_I (optimized model and active set)", br(), br(),
                                   
                                   strong("Repeat until information gain < threshold:"), br(), br(),
                                   
                                   "  1. Optimize Θ based on X_I and y_I", br(),
                                   "     (Maximize log marginal likelihood)", br(), br(),
                                   
                                   "  2. For all points in X and y:", br(),
                                   "     Compute information gain score Δ_j", br(),
                                   "     Select: x_j = argmax Δ_j", br(), br(),
                                   
                                   "  3. Use LQR to reach x_j:", br(),
                                   "     Compute Jacobians from learned model", br(),
                                   "     Apply LQR actions until close to x_j", br(), br(),
                                   
                                   "  4. Add x_j and y_j to X_I and y_I", br(), br(),
                                   
                                   "  5. Return to step 1", br()
                               )
                           )
                    ),
                    column(6,
                           div(class = "concept-box",
                               h4("Key Features:"),
                               
                               h5("Incremental Updates:"),
                               tags$ul(
                                 tags$li("Model updated after each new observation"),
                                 tags$li("Hyperparameters re-optimized periodically"),
                                 tags$li("Information gain recomputed with updated model"),
                                 tags$li("Active set grows iteratively")
                               ),
                               
                               h5("Adaptive Exploration:"),
                               tags$ul(
                                 tags$li("Focuses on high-uncertainty regions"),
                                 tags$li("Handles stochasticity in reaching targets"),
                                 tags$li("Incorporates nearby observations"),
                                 tags$li("Adjusts exploration based on current knowledge")
                               )
                           ),
                           
                           div(class = "math-formula",
                               h4("Computational Cost per Iteration:"),
                               tags$ul(
                                 tags$li(strong("Single GP:"), " ", withMathJax("$O(n^2)$"), " per candidate point"),
                                 tags$li(strong("MOGP:"), " ", withMathJax("$O(m^2n^2)$"), " per candidate point"),
                                 tags$li(strong("Hyperparameter optimization:"), " Periodic, not every iteration"),
                                 tags$li(strong("LQR computation:"), " Fast, uses learned gradients")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Interactive Algorithm Visualization", status = "info", solidHeader = TRUE,
                    column(6,
                           h4("Information Gain Process:"),
                           plotlyOutput("info_gain_demo", height = "400px")
                    ),
                    column(6,
                           h4("Algorithm Controls:"),
                           sliderInput("n_iterations", "Number of Iterations:", 
                                       min = 1, max = 20, value = 10, step = 1),
                           sliderInput("threshold", "Information Gain Threshold:", 
                                       min = 0.01, max = 0.5, value = 0.1, step = 0.01),
                           actionButton("run_algorithm", "Run Algorithm", class = "btn-primary"),
                           
                           div(class = "concept-box", style = "margin-top: 20px;",
                               h5("Visualization Shows:"),
                               tags$ul(
                                 tags$li("Blue dots: candidate points"),
                                 tags$li("Red stars: selected high-information points"),
                                 tags$li("Green region: low uncertainty (well-modeled)"),
                                 tags$li("Yellow/red regions: high uncertainty (needs exploration)")
                               )
                           )
                    )
                )
              )
      ),
      
      # Experiments Tab  
      tabItem(tabName = "experiments",
              fluidRow(
                box(width = 12, title = "Experiments - Overview", status = "primary", solidHeader = TRUE,
                    div(class = "concept-box",
                        p(class = "description-text",
                          "This section validates the information gain learning strategy through comprehensive experiments on 
                          simulated and real robotic systems. Three experimental platforms are examined: simulated blimp vertical 
                          dynamics, simulated cart-pole system, and a real autonomous blimp. All experiments use discrete-time 
                          continuous-state environments with square exponential covariance functions. The simulated blimp experiment 
                          learns vertical position and speed using a two-output MOGP based on an established blimp model. The system 
                          state evolves as s_t+1 = f(s_t, u_t) with 0.2 second time steps. Training data spans -5m to 5m height, 
                          -1 to 1 m/s speed, with normalized actions multiplied by 10N vertical force. Performance is compared across 
                          three configurations: single GPs with random points, MOGP with random points, and MOGP with information 
                          gain strategy. Results demonstrate that MOGP with information gain achieves superior performance, requiring 
                          only 56 points to reach prediction errors at the noise level, compared to slower convergence with random 
                          sampling. The information gain strategy selects more spread-out points covering the state-action space 
                          efficiently. The cart-pole experiment extends to higher dimensions with four outputs (position, velocity, 
                          angle, angular velocity) and five inputs. The MOGP trained with information gain (MOGP-A) significantly 
                          outperforms equally-spaced sampling (MOGP-B) across all output dimensions, particularly for the nonlinear 
                          pole dynamics. The real blimp experiment validates the approach on a 1.8m aerial platform with monocular 
                          camera and dual propellers, learning vertical dynamics under real-world conditions. The MOGP with information 
                          gain achieved 0.05cm height prediction error with ~100 training points, substantially better than random 
                          sampling. Even when LQR could not perfectly reach target state-action pairs due to actuator constraints, 
                          the information gain strategy still outperformed random selection by effectively using nearby observations."
                        )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Experimental Setup Summary", status = "info", solidHeader = TRUE,
                    column(4,
                           div(class = "concept-box",
                               h4("Simulated Blimp:"),
                               tags$ul(
                                 tags$li(strong("State:"), " [height, speed]"),
                                 tags$li(strong("Outputs:"), " 2 (position, velocity)"),
                                 tags$li(strong("Inputs:"), " 3 (state + action)"),
                                 tags$li(strong("Range:"), " ±5m height, ±1m/s speed"),
                                 tags$li(strong("Actions:"), " [-1, 1] → 10N force"),
                                 tags$li(strong("Time step:"), " δt = 0.2s"),
                                 tags$li(strong("Sampling:"), " 5 samples/s"),
                                 tags$li(strong("Training points:"), " 56 total"),
                                 tags$li(strong("Initial:"), " 4 points"),
                                 tags$li(strong("Test points:"), " 4 random")
                               )
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h4("Simulated Cart-Pole:"),
                               tags$ul(
                                 tags$li(strong("State:"), " [x, ẋ, θ, θ̇]"),
                                 tags$li(strong("Outputs:"), " 4 dimensions"),
                                 tags$li(strong("Inputs:"), " 5 (state + action)"),
                                 tags$li(strong("Range x:"), " ±5cm"),
                                 tags$li(strong("Range ẋ:"), " ±1cm/s"),
                                 tags$li(strong("Range θ:"), " [-π, π]"),
                                 tags$li(strong("Range θ̇:"), " ±1rad/s"),
                                 tags$li(strong("Actions:"), " ±1N"),
                                 tags$li(strong("Sampling:"), " 10 samples/s"),
                                 tags$li(strong("Training points:"), " up to 56"),
                                 tags$li(strong("Test points:"), " 10 random")
                               )
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h4("Real Blimp:"),
                               tags$ul(
                                 tags$li(strong("Platform:"), " 1.8m length, 1.0m diameter"),
                                 tags$li(strong("Sensors:"), " Monocular camera"),
                                 tags$li(strong("Actuators:"), " 2 propellers"),
                                 tags$li(strong("State:"), " [height, speed]"),
                                 tags$li(strong("Range h:"), " ±1m (2.2m total)"),
                                 tags$li(strong("Range ḣ:"), " ±0.6m/s (0.7m/s max)"),
                                 tags$li(strong("Actions:"), " -40 to 40 rev/s"),
                                 tags$li(strong("Sampling:"), " 4 samples/s"),
                                 tags$li(strong("Update rate:"), " 2.5s retraining"),
                                 tags$li(strong("Training:"), " 10 points per iteration"),
                                 tags$li(strong("Processor:"), " 2.4 GHz")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Experiment 1: Simulated Blimp Dynamics", status = "success", solidHeader = TRUE,
                    p(class = "description-text",
                      "Learning vertical dynamics (height and speed) of simulated blimp with comparison across three approaches: 
                      independent single-output GPs with random sampling, MOGP with random sampling, and MOGP with information 
                      gain strategy."
                    ),
                    
                    column(6,
                           h4("Experimental Design:"),
                           div(class = "concept-box",
                               h5("Dynamics Model:"),
                               withMathJax("$$s_{t+1} = f(s_t, u_t)$$"),
                               p("where ", withMathJax("$s = [h, \\dot{h}]^T$"), " (height, speed)"),
                               
                               h5("Training Configurations:"),
                               tags$ul(
                                 tags$li(strong("Config 1:"), " Two independent single-output GPs, random points"),
                                 tags$li(strong("Config 2:"), " MOGP with shared inputs X₀, random points"),
                                 tags$li(strong("Config 3:"), " MOGP with shared inputs X₀, information gain points"),
                                 tags$li(strong("All configs:"), " Started with same 4 initial points (shown as squares)"),
                                 tags$li(strong("Added points:"), " 52 additional (total 56)"),
                                 tags$li(strong("Experiments:"), " Repeated 15 times each")
                               )
                           ),
                           
                           div(class = "math-formula",
                               h5("Operating Range:"),
                               withMathJax("$$-5m \\leq h \\leq 5m$$"),
                               withMathJax("$$-1m/s \\leq \\dot{h} \\leq 1m/s$$"),
                               withMathJax("$$-1 \\leq a \\leq 1$$"),
                               p("Vertical force: ", withMathJax("$F_m = 10N \\times a$"))
                           )
                    ),
                    column(6,
                           h4("Key Results:"),
                           div(class = "concept-box",
                               h5("Prediction Error Comparison:"),
                               tags$ul(
                                 tags$li(strong("Single GPs (Config 1):"), " Slower error reduction, especially for height. 
                                         Independent modeling ignores output correlations."),
                                 tags$li(strong("MOGP Random (Config 2):"), " Better than single GPs due to multi-task learning. 
                                         Exploits height-speed dependencies."),
                                 tags$li(strong("MOGP Info Gain (Config 3):"), " Best performance. Reached noise-level error 
                                         (~0.05m height, ~0.02m/s speed) with 56 points.")
                               ),
                               
                               h5("Training Point Distribution:"),
                               p(class = "description-text",
                                 "Information gain points more spread throughout state-action space compared to random clustering. 
                                 Efficient coverage of high-uncertainty regions."
                               )
                           ),
                           
                           div(class = "highlight-box",
                               h5("Key Findings:"),
                               tags$ul(
                                 tags$li("MOGP requires less data than independent GPs"),
                                 tags$li("Information gain faster convergence than random"),
                                 tags$li("Best: MOGP + information gain combination"),
                                 tags$li("Variance decreased with more training points")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Experiment 2: Simulated Cart-Pole System", status = "warning", solidHeader = TRUE,
                    p(class = "description-text",
                      "Higher-dimensional experiment with four output dimensions (cart position, cart velocity, pole angle, 
                      pole angular velocity) to test scalability and performance on nonlinear dynamics."
                    ),
                    
                    column(6,
                           h4("System Description:"),
                           div(class = "concept-box",
                               h5("State Vector (4D):"),
                               withMathJax("$$y = [x, \\dot{x}, \\theta, \\dot{\\theta}]^T$$"),
                               tags$ul(
                                 tags$li(withMathJax("$x$"), " - cart horizontal position"),
                                 tags$li(withMathJax("$\\dot{x}$"), " - cart horizontal velocity"),
                                 tags$li(withMathJax("$\\theta$"), " - pole angle from vertical"),
                                 tags$li(withMathJax("$\\dot{\\theta}$"), " - pole angular velocity")
                               ),
                               
                               h5("Input Vector (5D):"),
                               withMathJax("$$X = [x, \\dot{x}, \\theta, \\dot{\\theta}, a]^T$$"),
                               p("(state + action)")
                           ),
                           
                           div(class = "math-formula",
                               h5("Operating Range:"),
                               withMathJax("$$-5cm \\leq x \\leq 5cm$$"),
                               withMathJax("$$-1cm/s \\leq \\dot{x} \\leq 1cm/s$$"),
                               withMathJax("$$-\\pi \\leq \\theta \\leq \\pi$$"),
                               withMathJax("$$-1rad/s \\leq \\dot{\\theta} \\leq 1rad/s$$"),
                               withMathJax("$$-1N \\leq a \\leq 1N$$")
                           )
                    ),
                    column(6,
                           h4("Experimental Protocol:"),
                           div(class = "concept-box",
                               h5("Two MOGP Configurations:"),
                               tags$ul(
                                 tags$li(strong("MOGP-A:"), " Information gain strategy"),
                                 tags$li(strong("MOGP-B:"), " Equally spaced points"),
                                 tags$li(strong("Initial:"), " Both started with same 8 points"),
                                 tags$li(strong("Test set:"), " 10 random points"),
                                 tags$li(strong("Repeated:"), " 15 experiments per configuration")
                               )
                           ),
                           
                           h4("Results Summary:"),
                           plotlyOutput("cartpole_results", height = "300px")
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Cart-Pole Detailed Results", status = "primary", solidHeader = TRUE,
                    column(3,
                           div(class = "concept-box",
                               h4("Cart Position (x):"),
                               tags$ul(
                                 tags$li("MOGP-A: Significant error decrease"),
                                 tags$li("MOGP-B: Slower convergence"),
                                 tags$li("Difference most pronounced"),
                                 tags$li("Information gain focused on high-variance regions")
                               )
                           )
                    ),
                    column(3,
                           div(class = "concept-box",
                               h4("Pole Angle (θ):"),
                               tags$ul(
                                 tags$li("MOGP-A: Higher accuracy achieved"),
                                 tags$li("MOGP-B: Slightly similar initially"),
                                 tags$li("Nonlinear pole dynamics challenging"),
                                 tags$li("Information gain adapts to complexity")
                               )
                           )
                    ),
                    column(3,
                           div(class = "concept-box",
                               h4("Cart Velocity (ẋ):"),
                               tags$ul(
                                 tags$li("MOGP-A: Better performance"),
                                 tags$li("MOGP-B: Acceptable accuracy"),
                                 tags$li("Linear dynamics easier to model"),
                                 tags$li("Still benefits from active selection")
                               )
                           )
                    ),
                    column(3,
                           div(class = "concept-box",
                               h4("Angular Velocity (θ̇):"),
                               tags$ul(
                                 tags$li("MOGP-A: Higher accuracy after 20 points"),
                                 tags$li("MOGP-B: Slower improvement"),
                                 tags$li("Coupled with nonlinear pole dynamics"),
                                 tags$li("Demonstrates scalability to 4D output")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Cart-Pole Key Insights", status = "info", solidHeader = TRUE,
                    column(6,
                           div(class = "highlight-box",
                               h4("Why Information Gain Outperforms Equal Spacing:"),
                               
                               p(class = "description-text",
                                 "The cart-pole dynamics are highly nonlinear, especially pole dynamics. Uniform spacing 
                                 doesn't account for regions of high variation in state-space."
                               ),
                               
                               tags$ul(
                                 tags$li(strong("Adaptive Coverage:"), " Information gain identifies high-uncertainty regions"),
                                 tags$li(strong("Nonlinearity Handling:"), " Focuses samples where model needs improvement"),
                                 tags$li(strong("Efficient Exploration:"), " Avoids over-sampling well-understood regions"),
                                 tags$li(strong("Multi-Task Benefit:"), " MOGP exploits correlations between x, ẋ, θ, θ̇")
                               )
                           )
                    ),
                    column(6,
                           div(class = "concept-box",
                               h4("Performance Metrics:"),
                               tags$ul(
                                 tags$li(strong("Convergence Speed:"), " MOGP-A reached target accuracy with fewer points"),
                                 tags$li(strong("Final Accuracy:"), " MOGP-A superior across all four output dimensions"),
                                 tags$li(strong("Variance:"), " Lower variance indicates more reliable performance"),
                                 tags$li(strong("Scalability:"), " Method scales effectively to higher-dimensional systems"),
                                 tags$li(strong("Practical Value:"), " Demonstrates real-world applicability for complex dynamics")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Experiment 3: Real Robotic Blimp", status = "success", solidHeader = TRUE,
                    p(class = "description-text",
                      "Validation on real autonomous aerial vehicle operating under real-world conditions with sensor noise, 
                      environmental disturbances, and actuator limitations. This experiment demonstrates practical applicability 
                      of the approach beyond simulation."
                    ),
                    
                    column(4,
                           h4("Platform Specifications:"),
                           div(class = "concept-box",
                               h5("Physical Characteristics:"),
                               tags$ul(
                                 tags$li(strong("Length:"), " 1.8 meters"),
                                 tags$li(strong("Diameter:"), " 1.0 meter"),
                                 tags$li(strong("Gondola:"), " Carries sensors and actuators")
                               ),
                               
                               h5("Sensing & Actuation:"),
                               tags$ul(
                                 tags$li(strong("Camera:"), " Monocular vision"),
                                 tags$li(strong("Propellers:"), " 2 independently actuated"),
                                 tags$li(strong("Motor range:"), " -40 to 40 rev/s"),
                                 tags$li(strong("Scaled actions:"), " -1 to 1")
                               )
                           )
                    ),
                    column(4,
                           h4("Experimental Protocol:"),
                           div(class = "concept-box",
                               h5("Learning Configuration:"),
                               tags$ul(
                                 tags$li(strong("State:"), " [height, vertical velocity]"),
                                 tags$li(strong("Physical limits:"), " 2.2m vertical range"),
                                 tags$li(strong("Max speed:"), " 0.7 m/s"),
                                 tags$li(strong("Sampling:"), " 4 samples/second"),
                                 tags$li(strong("Iterations:"), " 10 total"),
                                 tags$li(strong("Points/iteration:"), " 10 new points"),
                                 tags$li(strong("Total training:"), " Up to 100 points")
                               ),
                               
                               h5("Computational Performance:"),
                               tags$ul(
                                 tags$li(strong("Training time:"), " ~0.1s (2.4 GHz CPU)"),
                                 tags$li(strong("Update frequency:"), " Every 2.5 seconds"),
                                 tags$li(strong("Real-time capable:"), " Yes")
                               )
                           )
                    ),
                    column(4,
                           h4("Comparison:"),
                           div(class = "concept-box",
                               h5("Two MOGP Approaches:"),
                               tags$ul(
                                 tags$li(strong("MOGP-A:"), " Information gain strategy"),
                                 tags$li(strong("MOGP-B:"), " Randomly selected points"),
                                 tags$li(strong("Repeated:"), " 10 experiments each"),
                                 tags$li(strong("Initial data:"), " Same for both"),
                                 tags$li(strong("Test set:"), " 4 random points"),
                                 tags$li(strong("LQR control:"), " Used to reach target states")
                               )
                           ),
                           
                           div(class = "math-formula",
                               h5("State-Action Boundaries:"),
                               withMathJax("$$-1m \\leq h \\leq 1m$$"),
                               withMathJax("$$-0.6m/s \\leq \\dot{h} \\leq 0.6m/s$$"),
                               withMathJax("$$-1 \\leq a \\leq 1$$")
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Real Blimp Results", status = "warning", solidHeader = TRUE,
                    column(6,
                           h4("Height Prediction:"),
                           plotlyOutput("blimp_height_results", height = "300px"),
                           
                           div(class = "concept-box",
                               h5("Height Performance:"),
                               tags$ul(
                                 tags$li("MOGP-A: Significant improvement after 30 points"),
                                 tags$li("MOGP-B: Slower convergence throughout"),
                                 tags$li("Final accuracy: ~0.05cm threshold reached at 100 points"),
                                 tags$li("Variance: Decreased substantially for MOGP-A"),
                                 tags$li("Practical threshold met earlier than random sampling")
                               )
                           )
                    ),
                    column(6,
                           h4("Vertical Velocity Prediction:"),
                           plotlyOutput("blimp_speed_results", height = "300px"),
                           
                           div(class = "concept-box",
                               h5("Velocity Performance:"),
                               tags$ul(
                                 tags$li("MOGP-A: Considerable improvement after 40 points"),
                                 tags$li("MOGP-B: Continued higher error"),
                                 tags$li("Velocity more challenging due to derivative estimation"),
                                 tags$li("Information gain strategy more effective"),
                                 tags$li("Real-world noise and disturbances handled well")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Real-World Validation Insights", status = "primary", solidHeader = TRUE,
                    column(4,
                           div(class = "concept-box",
                               h4("Robustness to Imperfect Control:"),
                               
                               p(class = "description-text",
                                 "LQR could not always reach exact desired state-action pairs due to physical 
                                 constraints of actuators and environmental disturbances."
                               ),
                               
                               h5("Key Observation:"),
                               p(class = "description-text",
                                 "Even when target not reached exactly, nearby observations still valuable. 
                                 MOGP-A still outperformed MOGP-B, demonstrating robustness."
                               ),
                               
                               tags$ul(
                                 tags$li("Actuator limitations handled gracefully"),
                                 tags$li("Approximate target reaching sufficient"),
                                 tags$li("Information gain strategy adapts"),
                                 tags$li("Practical for real robotic systems")
                               )
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h4("Online Learning Capability:"),
                               
                               tags$ul(
                                 tags$li(strong("Real-time updates:"), " Model retrained every 2.5 seconds"),
                                 tags$li(strong("Fast training:"), " 0.1s per iteration"),
                                 tags$li(strong("Continuous operation:"), " Blimp flies while learning"),
                                 tags$li(strong("Adaptive:"), " Adjusts to changing conditions"),
                                 tags$li(strong("Practical deployment:"), " Suitable for autonomous systems")
                               ),
                               
                               h5("Stopping Criterion:"),
                               p(class = "description-text",
                                 "Iterations stopped when height prediction error reached 0.05cm threshold 
                                 around 100 training points."
                               )
                           )
                    ),
                    column(4,
                           div(class = "highlight-box",
                               h4("Significance of Real-World Results:"),
                               
                               p(class = "description-text",
                                 "This experiment validates the entire framework on an actual robotic platform, 
                                 demonstrating:"
                               ),
                               
                               tags$ul(
                                 tags$li("Method works beyond simulation"),
                                 tags$li("Handles sensor noise effectively"),
                                 tags$li("Robust to environmental disturbances"),
                                 tags$li("Computationally feasible for real-time"),
                                 tags$li("Practical for autonomous aerial vehicles"),
                                 tags$li("Information gain superior in real conditions")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Cross-Experiment Comparison", status = "info", solidHeader = TRUE,
                    column(6,
                           h4("Summary Table:"),
                           div(style = "overflow-x: auto;",
                               tags$table(class = "table table-striped", style = "width: 100%;",
                                          tags$thead(
                                            tags$tr(
                                              tags$th("Experiment"),
                                              tags$th("Outputs"),
                                              tags$th("Inputs"),
                                              tags$th("Training Points"),
                                              tags$th("MOGP-A Advantage")
                                            )
                                          ),
                                          tags$tbody(
                                            tags$tr(
                                              tags$td("Sim Blimp"),
                                              tags$td("2"),
                                              tags$td("3"),
                                              tags$td("56"),
                                              tags$td("Faster convergence, noise-level error")
                                            ),
                                            tags$tr(
                                              tags$td("Cart-Pole"),
                                              tags$td("4"),
                                              tags$td("5"),
                                              tags$td("56"),
                                              tags$td("Superior in all dimensions, handles nonlinearity")
                                            ),
                                            tags$tr(
                                              tags$td("Real Blimp"),
                                              tags$td("2"),
                                              tags$td("3"),
                                              tags$td("100"),
                                              tags$td("0.05cm accuracy, robust to real-world conditions")
                                            )
                                          )
                               )
                           )
                    ),
                    column(6,
                           h4("Consistent Findings:"),
                           div(class = "concept-box",
                               tags$ol(
                                 tags$li(strong("MOGP Superiority:"), " Multi-task learning consistently outperforms 
                                         independent GPs by exploiting output correlations"),
                                 tags$li(strong("Information Gain Benefit:"), " Active selection outperforms random 
                                         and uniform sampling across all experiments"),
                                 tags$li(strong("Scalability:"), " Method scales from 2D to 4D outputs effectively"),
                                 tags$li(strong("Real-World Applicability:"), " Validated on actual robotic platform 
                                         with real constraints"),
                                 tags$li(strong("Efficiency:"), " Achieves high accuracy with fewer training points 
                                         than alternatives"),
                                 tags$li(strong("Computational Feasibility:"), " Fast enough for online learning 
                                         in real-time applications")
                               )
                           )
                    )
                )
              )
      ),
      
      # Conclusions Tab
      tabItem(tabName = "conclusions",
              fluidRow(
                box(width = 12, title = "Conclusions & Future Work - Overview", status = "primary", solidHeader = TRUE,
                    div(class = "concept-box",
                        p(class = "description-text",
                          "This research successfully demonstrates an integrated method for active learning of system dynamics 
                          through Multiple Output Gaussian Processes combined with information gain learning strategies. The 
                          Multi-Task Learning approach performed by MOGP achieves higher prediction accuracy with less training 
                          data compared to independent Gaussian processes, validated across simulated and real robotic systems. 
                          This prediction performance results from MOGP's ability to correlate output dimensions through cross-covariance 
                          functions, exploiting underlying task dependencies. The information gain strategy proves significantly 
                          more efficient for learning dynamics than random or uniform selection procedures. At each algorithm 
                          iteration, the prediction error reduces substantially compared to baseline approaches, as demonstrated 
                          in simulated blimp, cart-pole, and real blimp experiments. The strategy selects training points that 
                          minimize posterior variance (maximize information gain), focusing computational resources on regions 
                          of high uncertainty rather than over-sampling well-understood areas. Linear Quadratic Regulator control 
                          enables practical application by directing the system to obtain requested state-action observations, 
                          with the controller using derivatives from the learned MOGP model. The approach's reliability depends 
                          on the approximated model capturing system derivatives reasonably well, which the MOGP provides through 
                          continuous differentiable predictions. Experimental validation encompassed three diverse scenarios: 
                          simulated blimp vertical dynamics (2 outputs, 3 inputs), simulated cart-pole (4 outputs, 5 inputs), 
                          and real autonomous blimp platform (1.8m aerial vehicle with monocular camera and dual propellers). 
                          Results consistently show the combined MOGP + information gain approach outperforms alternatives, achieving 
                          noise-level prediction errors with minimal training data. Future work will investigate performance on 
                          higher-dimensional dynamic systems and reformulate the information gain strategy to select single training 
                          points representing highest entropy decrease independent of output dimension count, further improving 
                          computational efficiency for multi-output scenarios. This research provides a validated framework for 
                          data-efficient learning of complex robotic dynamics applicable to autonomous systems operating in uncertain 
                          real-world environments."
                        )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Key Contributions", status = "success", solidHeader = TRUE,
                    p(class = "description-text",
                      "This work makes several significant contributions to robotic learning, multi-task learning, and active 
                      learning for dynamic systems. Each contribution has been validated through comprehensive experiments."
                    )
                )
              ),
              
              fluidRow(
                column(4,
                       box(width = 12, status = "success", solidHeader = TRUE,
                           div(style = "text-align: center; padding: 15px; min-height: 120px;",
                               div(style = "font-size: 48px; font-weight: bold; color: #00A39A;", "MOGP"),
                               h4(style = "margin-top: 10px; color: #008A82;", "Multi-Task Dynamics Learning"),
                               p(style = "font-size: 14px; color: #666;", "Exploiting Output Correlations")
                           ),
                           div(class = "concept-box",
                               p(class = "description-text",
                                 "Demonstrated that MOGP achieves higher prediction accuracy with less training data than 
                                 independent GPs. Cross-covariance functions capture correlations between output dimensions 
                                 (e.g., position, velocity, angle), enabling more efficient learning of system dynamics."
                               )
                           )
                       )
                ),
                column(4,
                       box(width = 12, status = "info", solidHeader = TRUE,
                           div(style = "text-align: center; padding: 15px; min-height: 120px;",
                               div(style = "font-size: 48px; font-weight: bold; color: #3498db;", "Active"),
                               h4(style = "margin-top: 10px; color: #2980b9;", "Information Gain Strategy"),
                               p(style = "font-size: 14px; color: #666;", "Efficient State-Action Exploration")
                           ),
                           div(class = "concept-box",
                               p(class = "description-text",
                                 "Verified information gain strategy significantly reduces training data requirements. 
                                 Selecting points that maximize entropy reduction focuses exploration on high-uncertainty 
                                 regions, achieving faster convergence than random or uniform sampling across all experiments."
                               )
                           )
                       )
                ),
                column(4,
                       box(width = 12, status = "warning", solidHeader = TRUE,
                           div(style = "text-align: center; padding: 15px; min-height: 120px;",
                               div(style = "font-size: 48px; font-weight: bold; color: #9b59b6;", "LQR"),
                               h4(style = "margin-top: 10px; color: #8e44ad;", "Integrated Control Framework"),
                               p(style = "font-size: 14px; color: #666;", "Closed-Loop Exploration")
                           ),
                           div(class = "concept-box",
                               p(class = "description-text",
                                 "Integrated LQR control with learning strategy for practical robotic applications. 
                                 Uses gradients from learned MOGP model to compute control actions, enabling the system 
                                 to actively navigate to informative state-action pairs for observation."
                               )
                           )
                       )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Experimental Validation Summary", status = "info", solidHeader = TRUE,
                    column(4,
                           div(class = "concept-box",
                               h4("Simulated Blimp:"),
                               
                               h5("Key Results:"),
                               tags$ul(
                                 tags$li("2 outputs, 3 inputs"),
                                 tags$li("56 training points total"),
                                 tags$li("MOGP-A vs MOGP-B vs Single GPs"),
                                 tags$li("Reached noise-level error (~0.05m)"),
                                 tags$li("Information gain points well-distributed"),
                                 tags$li("15 repeated experiments")
                               ),
                               
                               h5("Conclusion:"),
                               p(class = "description-text",
                                 "MOGP with information gain achieved best performance, demonstrating value of 
                                 both multi-task learning and active selection."
                               )
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h4("Simulated Cart-Pole:"),
                               
                               h5("Key Results:"),
                               tags$ul(
                                 tags$li("4 outputs, 5 inputs"),
                                 tags$li("Higher-dimensional validation"),
                                 tags$li("Nonlinear pole dynamics"),
                                 tags$li("MOGP-A superior in all dimensions"),
                                 tags$li("Especially effective for θ and θ̇"),
                                 tags$li("Demonstrates scalability")
                               ),
                               
                               h5("Conclusion:"),
                               p(class = "description-text",
                                 "Information gain effectively handles high-dimensional nonlinear systems where 
                                 uniform sampling struggles with varying complexity across state-space."
                               )
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h4("Real Robotic Blimp:"),
                               
                               h5("Key Results:"),
                               tags$ul(
                                 tags$li("1.8m autonomous aerial vehicle"),
                                 tags$li("Real-world sensor noise"),
                                 tags$li("Environmental disturbances"),
                                 tags$li("Actuator limitations"),
                                 tags$li("0.05cm accuracy at 100 points"),
                                 tags$li("Online learning demonstrated")
                               ),
                               
                               h5("Conclusion:"),
                               p(class = "description-text",
                                 "Framework validated on real platform, proving practical applicability beyond 
                                 simulation with robustness to real-world conditions."
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Research Impact", status = "warning", solidHeader = TRUE,
                    column(6,
                           div(class = "concept-box",
                               h4("Theoretical Contributions:"),
                               
                               tags$ul(
                                 tags$li(strong("Unified Framework:"), " Combines MOGP, information gain, and LQR 
                                         into integrated learning-control system"),
                                 tags$li(strong("Multi-Task Learning:"), " Demonstrates value of exploiting task 
                                         dependencies for dynamics learning"),
                                 tags$li(strong("Active Learning Theory:"), " Applies information gain principle 
                                         specifically to dynamics learning"),
                                 tags$li(strong("Computational Analysis:"), " Characterizes complexity trade-offs 
                                         between data requirements and computational cost"),
                                 tags$li(strong("Convergence Properties:"), " Shows faster error reduction with 
                                         information gain across diverse systems")
                               )
                           )
                    ),
                    column(6,
                           div(class = "concept-box",
                               h4("Practical Impact:"),
                               
                               tags$ul(
                                 tags$li(strong("Reduced Data Requirements:"), " Learn accurate models with fewer 
                                         observations, reducing exploration time"),
                                 tags$li(strong("Online Learning:"), " Real-time model updates enable adaptation 
                                         to changing conditions"),
                                 tags$li(strong("Robotic Applications:"), " Validated on real platform, ready for 
                                         autonomous systems"),
                                 tags$li(strong("Scalability:"), " Demonstrated from 2D to 4D output spaces with 
                                         consistent benefits"),
                                 tags$li(strong("Robustness:"), " Works despite sensor noise, disturbances, and 
                                         imperfect control")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Future Work", status = "primary", solidHeader = TRUE,
                    p(class = "description-text",
                      "Several promising directions extend this research toward higher-dimensional systems and improved 
                      computational efficiency for multi-output scenarios."
                    ),
                    
                    column(6,
                           div(class = "concept-box",
                               h4("Higher-Dimensional Systems:"),
                               
                               h5("Motivation:"),
                               p(class = "description-text",
                                 "Current experiments tested up to 4 output dimensions. Many robotic systems have 
                                 higher-dimensional state spaces (e.g., humanoid robots, multi-agent systems)."
                               ),
                               
                               h5("Research Questions:"),
                               tags$ul(
                                 tags$li("How does performance scale to 10+ output dimensions?"),
                                 tags$li("What computational strategies maintain efficiency?"),
                                 tags$li("Can sparse MOGP approximations help?"),
                                 tags$li("How to handle heterogeneous output types?"),
                                 tags$li("What about partial observability?")
                               ),
                               
                               h5("Potential Approaches:"),
                               tags$ul(
                                 tags$li(strong("Task Clustering:"), " Group related outputs to reduce effective dimensionality"),
                                 tags$li(strong("Hierarchical MOGPs:"), " Multi-level structure for output dependencies"),
                                 tags$li(strong("Sparse Approximations:"), " Inducing points to reduce computational cost"),
                                 tags$li(strong("Structured Kernels:"), " Exploit known structure in output space")
                               )
                           )
                    ),
                    column(6,
                           div(class = "concept-box",
                               h4("Improved Information Gain Strategy:"),
                               
                               h5("Current Limitation:"),
                               p(class = "description-text",
                                 "Currently selects ", withMathJax("$m$"), " new points per iteration (one per output). 
                                 For high-dimensional outputs, this adds ", withMathJax("$m$"), " observations simultaneously."
                               ),
                               
                               h5("Proposed Improvement:"),
                               p(class = "description-text",
                                 "Reformulate to select single training point representing highest entropy decrease 
                                 independent of output dimension count."
                               ),
                               
                               div(class = "math-formula",
                                   h5("Multi-Output Information Gain:"),
                                   p("Instead of ", withMathJax("$m$"), " separate scores:"),
                                   withMathJax("$$\\Delta_j^{(i)} = \\log\\left(1 + \\frac{v_j^{(i)}}{\\sigma_i^2}\\right)$$"),
                                   
                                   p("Use joint entropy across all outputs:"),
                                   withMathJax("$$\\Delta_j = H[p(f_j^{(1)}, \\ldots, f_j^{(m)})] - 
                                               H[p^{new}(f_j^{(1)}, \\ldots, f_j^{(m)})]$$")
                               ),
                               
                               h5("Benefits:"),
                               tags$ul(
                                 tags$li("Reduces points added per iteration"),
                                 tags$li("Considers multi-output uncertainty jointly"),
                                 tags$li("More computationally efficient"),
                                 tags$li("Better for high-dimensional systems")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Additional Future Directions", status = "success", solidHeader = TRUE,
                    column(4,
                           div(class = "concept-box",
                               h4("Theoretical Extensions:"),
                               
                               tags$ul(
                                 tags$li(strong("Convergence Analysis:"), " Formal convergence rates for information 
                                         gain strategy"),
                                 tags$li(strong("Sample Complexity:"), " Theoretical bounds on required training points"),
                                 tags$li(strong("Optimality:"), " Comparison to optimal sequential design"),
                                 tags$li(strong("Regret Bounds:"), " PAC-learning style guarantees"),
                                 tags$li(strong("Non-Gaussian Noise:"), " Extension beyond Gaussian observation models")
                               )
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h4("Algorithmic Improvements:"),
                               
                               tags$ul(
                                 tags$li(strong("Batch Selection:"), " Select multiple informative points simultaneously"),
                                 tags$li(strong("Transfer Learning:"), " Leverage learned models across related systems"),
                                 tags$li(strong("Incremental Updates:"), " More efficient hyperparameter re-optimization"),
                                 tags$li(strong("Approximate Inference:"), " Variational methods for faster training"),
                                 tags$li(strong("Deep Kernel Learning:"), " Neural network feature extractors")
                               )
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h4("Application Domains:"),
                               
                               tags$ul(
                                 tags$li(strong("Humanoid Robotics:"), " Full-body dynamics learning"),
                                 tags$li(strong("Multi-Agent Systems:"), " Coordinated learning of team dynamics"),
                                 tags$li(strong("Deformable Objects:"), " Learning soft-body dynamics"),
                                 tags$li(strong("Hybrid Systems:"), " Continuous and discrete state spaces"),
                                 tags$li(strong("Underwater Vehicles:"), " Complex fluid-structure interaction")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Concluding Remarks", status = "primary", solidHeader = TRUE,
                    div(class = "highlight-box",
                        p(class = "description-text", style = "font-size: 16px;",
                          strong("This research demonstrates that combining Multiple Output Gaussian Processes with information 
                          gain-based active learning provides an effective framework for data-efficient learning of robotic 
                          system dynamics."), " The approach reduces training data requirements compared to independent 
                          Gaussian processes and random sampling, while achieving superior prediction accuracy. Validation 
                          on simulated and real robotic platforms confirms practical applicability for autonomous systems 
                          operating in uncertain environments. The integrated learning-control framework using LQR enables 
                          closed-loop exploration where systems actively navigate to informative regions of state-action space. 
                          Future work on higher-dimensional systems and improved multi-output information gain strategies will 
                          extend the framework's applicability to increasingly complex robotic platforms."
                        )
                    ),
                    
                    div(class = "concept-box", style = "margin-top: 20px;",
                        h4("Key Takeaways:"),
                        tags$ol(
                          tags$li(strong("Multi-task learning matters:"), " Exploiting output correlations significantly 
                                  reduces data requirements"),
                          tags$li(strong("Active learning works:"), " Information gain outperforms passive sampling strategies"),
                          tags$li(strong("Real-world validation:"), " Framework proven on actual robotic platform with 
                                  real constraints"),
                          tags$li(strong("Computational feasibility:"), " Fast enough for online learning in real-time applications"),
                          tags$li(strong("Scalability demonstrated:"), " Effective from 2D to 4D output spaces with consistent 
                                  benefits"),
                          tags$li(strong("Practical impact:"), " Enables autonomous systems to learn complex dynamics efficiently")
                        )
                    )
                )
              )
      ),
      
      # References Tab
      tabItem(tabName = "refs",
              fluidRow(
                box(width = 12, title = "References", status = "primary", solidHeader = TRUE,
                    p(class = "description-text",
                      "This research builds upon foundational work in Gaussian processes, multi-task learning, active learning, 
                      optimal control, and robotic learning. The references span theoretical foundations in machine learning, 
                      practical applications in robotics, and established techniques in control theory."
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Reference List", status = "success", solidHeader = TRUE,
                    DTOutput("ref_table")
                )
              ),
              
              fluidRow(
                box(width = 6, title = "References by Category", status = "info", solidHeader = TRUE,
                    plotlyOutput("ref_category_chart", height = "300px")
                ),
                box(width = 6, title = "Publication Timeline", status = "warning", solidHeader = TRUE,
                    plotlyOutput("ref_timeline_chart", height = "300px")
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Key References by Topic", status = "primary", solidHeader = TRUE,
                    column(3,
                           div(class = "concept-box",
                               h4("Gaussian Processes:"),
                               tags$ul(
                                 tags$li(strong("[12] Rasmussen & Williams:"), " Gaussian Processes for Machine Learning 
                                         - foundational text"),
                                 tags$li(strong("[7] Quionero-Candela & Rasmussen:"), " Unifying view of sparse GP regression"),
                                 tags$li(strong("[8] Lawrence et al.:"), " Informative Vector Machine for sparse GPs")
                               )
                           )
                    ),
                    column(3,
                           div(class = "concept-box",
                               h4("Multi-Task Learning:"),
                               tags$ul(
                                 tags$li(strong("[1] Boyle & Frean:"), " Multiple output GP regression via kernel convolutions"),
                                 tags$li(strong("[10] Caruana:"), " Multitask learning thesis"),
                                 tags$li(strong("[11] Chai et al.:"), " Multi-task GP for robot inverse dynamics")
                               )
                           )
                    ),
                    column(3,
                           div(class = "concept-box",
                               h4("Active Learning & Control:"),
                               tags$ul(
                                 tags$li(strong("[2] MacKay:"), " Information Theory, Inference, and Learning"),
                                 tags$li(strong("[5] Deisenroth et al.:"), " GP dynamic programming"),
                                 tags$li(strong("[13] Anderson & Moore:"), " Optimal Control - LQR theory")
                               )
                           )
                    ),
                    column(3,
                           div(class = "concept-box",
                               h4("Robotic Applications:"),
                               tags$ul(
                                 tags$li(strong("[3] Ko et al.:"), " GP and RL for autonomous blimp"),
                                 tags$li(strong("[6] Rottmann & Burgard:"), " Adaptive control with online value iteration"),
                                 tags$li(strong("[9] Singh et al.:"), " Environmental surveillance with GPs")
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
  
  # Strategy Tab - Information Gain Demo
  output$info_gain_demo <- renderPlotly({
    set.seed(42)
    x <- seq(-5, 5, length.out = 50)
    y <- seq(-5, 5, length.out = 50)
    grid <- expand.grid(x = x, y = y)
    
    # Simulate variance (uncertainty)
    grid$variance <- exp(-0.1 * (grid$x^2 + grid$y^2)) + 
      0.5 * exp(-0.2 * ((grid$x-2)^2 + (grid$y+2)^2))
    
    # Selected points (high variance)
    selected <- data.frame(
      x = c(-3, 2, -1, 3),
      y = c(2, -2, -3, 3)
    )
    
    plot_ly() %>%
      add_trace(data = grid, x = ~x, y = ~y, z = ~variance, 
                type = "contour", colorscale = "YlOrRd",
                contours = list(showlabels = TRUE),
                name = "Uncertainty") %>%
      add_trace(data = selected, x = ~x, y = ~y, 
                type = "scatter", mode = "markers",
                marker = list(size = 15, color = "red", symbol = "star",
                              line = list(color = "black", width = 2)),
                name = "Selected Points") %>%
      layout(
        title = "Information Gain Selection Strategy",
        xaxis = list(title = "State Dimension 1"),
        yaxis = list(title = "State Dimension 2"),
        showlegend = TRUE,
        paper_bgcolor = 'rgba(0,0,0,0)',
        plot_bgcolor = '#f8f9fa'
      )
  })
  
  # Experiments Tab - Cart-Pole Results
  output$cartpole_results <- renderPlotly({
    training_points <- seq(8, 56, by = 4)
    
    data <- data.frame(
      points = rep(training_points, 2),
      method = rep(c("MOGP-A (Info Gain)", "MOGP-B (Equal Spacing)"), each = length(training_points)),
      error = c(
        5 * exp(-0.15 * (training_points - 8)) + 0.3,  # MOGP-A
        5 * exp(-0.08 * (training_points - 8)) + 0.8   # MOGP-B
      )
    )
    
    plot_ly(data, x = ~points, y = ~error, color = ~method,
            type = "scatter", mode = "lines+markers",
            colors = c("#00A39A", "#e74c3c")) %>%
      layout(
        title = "Cart-Pole: Average Prediction Error",
        xaxis = list(title = "Number of Training Points"),
        yaxis = list(title = "Root Mean Square Error"),
        paper_bgcolor = 'rgba(0,0,0,0)',
        plot_bgcolor = '#f8f9fa'
      )
  })
  
  # Experiments Tab - Blimp Height Results
  output$blimp_height_results <- renderPlotly({
    training_points <- seq(10, 100, by = 10)
    
    data <- data.frame(
      points = rep(training_points, 2),
      method = rep(c("MOGP-A", "MOGP-B"), each = length(training_points)),
      error = c(
        0.3 * exp(-0.03 * training_points) + 0.03,  # MOGP-A
        0.3 * exp(-0.015 * training_points) + 0.08  # MOGP-B
      )
    )
    
    plot_ly(data, x = ~points, y = ~error, color = ~method,
            type = "scatter", mode = "lines+markers",
            colors = c("#00A39A", "#e74c3c")) %>%
      layout(
        title = "Blimp Height Prediction Error",
        xaxis = list(title = "Number of Training Points"),
        yaxis = list(title = "Mean Error (meters)"),
        paper_bgcolor = 'rgba(0,0,0,0)',
        plot_bgcolor = '#f8f9fa'
      )
  })
  
  # Experiments Tab - Blimp Speed Results
  output$blimp_speed_results <- renderPlotly({
    training_points <- seq(10, 100, by = 10)
    
    data <- data.frame(
      points = rep(training_points, 2),
      method = rep(c("MOGP-A", "MOGP-B"), each = length(training_points)),
      error = c(
        0.7 * exp(-0.025 * training_points) + 0.05,  # MOGP-A
        0.7 * exp(-0.012 * training_points) + 0.15   # MOGP-B
      )
    )
    
    plot_ly(data, x = ~points, y = ~error, color = ~method,
            type = "scatter", mode = "lines+markers",
            colors = c("#00A39A", "#e74c3c")) %>%
      layout(
        title = "Blimp Velocity Prediction Error",
        xaxis = list(title = "Number of Training Points"),
        yaxis = list(title = "Mean Error (m/s)"),
        paper_bgcolor = 'rgba(0,0,0,0)',
        plot_bgcolor = '#f8f9fa'
      )
  })
  
  # References Table
  ref_data <- data.frame(
    ID = 1:14,
    Authors = c(
      "Boyle, P. & Frean, M.",
      "MacKay, D.",
      "Ko, J., Klein, D., Fox, D. & Haehnel, D.",
      "Liu, Y., Pan, Z., Stirling, D. & Naghdy, F.",
      "Deisenroth, M.P., Rasmussen, C.E. & Peters, J.",
      "Rottmann, A. & Burgard, W.",
      "Quionero-Candela, J. & Rasmussen, K.",
      "Lawrence, N., Seeger, M. & Herbrich, R.",
      "Singh, A., Ramos, F., Durrant-Whyte, H. & Kaiser, W.",
      "Caruana, R.",
      "Chai, K., Williams, C., Klanke, S. & Vijayakumar, S.",
      "Rasmussen, C.E. & Williams, C.K.I.",
      "Anderson, B.D. & Moore, J.B.",
      "Kolter, J., Plagemann, C., Jackson, D., Ng, A. & Thrun, S."
    ),
    Year = c(2005, 2003, 2007, 2009, 2009, 2009, 2005, 2003, 2010, 1997, 2008, 2006, 1989, 2010),
    Type = c(
      "Technical Report", "Book", "Conference", "Conference", "Journal",
      "Conference", "Journal", "Conference", "Conference", "Thesis",
      "Conference", "Book", "Book", "Conference"
    ),
    Category = c(
      "Multi-Task Learning", "Information Theory", "GP Robotics", "RL Navigation", "GP Control",
      "Adaptive Control", "Sparse GPs", "Active Learning", "Path Planning", "Multi-Task Theory",
      "Robot Control", "GP Theory", "Optimal Control", "Probabilistic Control"
    ),
    stringsAsFactors = FALSE
  )
  
  output$ref_table <- renderDT({
    datatable(
      ref_data,
      options = list(
        pageLength = 14,
        scrollX = TRUE,
        dom = 'Bfrtip',
        buttons = c('copy', 'csv', 'excel')
      ),
      rownames = FALSE,
      class = 'cell-border stripe'
    )
  })
  
  # Reference Category Chart
  output$ref_category_chart <- renderPlotly({
    category_counts <- table(ref_data$Category)
    
    plot_ly(
      labels = names(category_counts),
      values = as.vector(category_counts),
      type = 'pie',
      marker = list(colors = c('#008A82', '#3498db', '#f39c12', '#e74c3c', '#9b59b6', '#2ecc71'))
    ) %>%
      layout(
        title = "References by Category",
        showlegend = TRUE,
        paper_bgcolor = 'rgba(0,0,0,0)'
      )
  })
  
  # Reference Timeline Chart
  output$ref_timeline_chart <- renderPlotly({
    year_counts <- as.data.frame(table(ref_data$Year))
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