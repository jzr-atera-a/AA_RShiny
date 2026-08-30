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
        .description-text {
          font-size: 15px;
          line-height: 1.8;
          text-align: justify;
          color: #2c3e50;
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
                box(width = 12, title = "Chapter 1: Introduction - Overview", status = "primary", solidHeader = TRUE,
                    div(class = "concept-box",
                        p(class = "description-text",
                          "This chapter presents the fundamental motivation and problem formulation for active Bayesian learning 
                          of dynamic systems in robotics. The research addresses critical challenges in autonomous systems where 
                          conventional control approaches fail due to unmeasurable quantities, time-variant dynamics, and unpredictable 
                          disturbances. Traditional control methods rely on ordinary differential equations (ODEs) and assume fully 
                          measurable, stationary environments—assumptions that rarely hold in real-world scenarios. The chapter introduces 
                          the core research question: how to develop an effective active Bayesian learning methodology that selects the 
                          most informative dynamics data while building reliable predictive models exploiting inter-task dependencies. 
                          Three main contributions are outlined: an information gain strategy for efficient observation selection, 
                          multi-task learning through Multiple Output Gaussian Processes (MOGPs) for task correlation, and adaptive 
                          predictive control capable of real-time model updates. The motivation stems from practical limitations in 
                          field robotics where systems like robotic arms experience varying friction with different loads, underwater 
                          vehicles face unpredictable currents, and aerial vehicles must compensate for wind disturbances and gas leakage. 
                          These scenarios demand flexible, adaptive learning frameworks that can continuously update their understanding 
                          of system dynamics without requiring complete knowledge of the environment or perfect sensor measurements. 
                          The chapter establishes the foundation for a novel approach combining information theory, Bayesian inference, 
                          and optimal control to achieve robust autonomous operation in uncertain, time-varying environments."
                        )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Motivation", status = "primary", solidHeader = TRUE,
                    p(class = "description-text",
                      "Autonomous robotic systems perform a wide range of industrial and productive activities globally. 
                      Effective operation without human intervention defines the reliability of these systems. However, current 
                      implementations face significant constraints that limit true autonomy. The first major constraint involves 
                      the difficulty of measuring quantities in robotic actuators such as friction, which varies non-linearly 
                      with load and environmental conditions. For example, in robotic arms, inner friction of actuators changes 
                      based on the handled load, making it extremely difficult to measure with high-accuracy sensors. Similarly, 
                      in hybrid ground vehicles, terrain friction affects maneuvering capabilities in ways that conventional 
                      controllers cannot generalize effectively."
                    ),
                    
                    div(class = "concept-box",
                        h4("Key Challenges in Autonomous Robotics:"),
                        tags$ul(
                          tags$li(strong("Actuator Limitations:"), " Difficulty measuring internal quantities like friction, 
                                  wear, and non-linear behaviors that change with operating conditions."),
                          tags$li(strong("Stationary Dynamics Assumption:"), " Traditional controllers assume time-invariant 
                                  dynamics, failing when disturbances arise or system parameters drift over time."),
                          tags$li(strong("Undetectable Disturbances:"), " Environmental factors like water currents, wind, 
                                  and gas leakage cannot be directly sensed but significantly affect system behavior."),
                          tags$li(strong("Model Inaccuracy:"), " Ordinary differential equations often cannot capture the 
                                  full complexity of real-world robotic systems with sufficient fidelity.")
                        )
                    ),
                    
                    p(class = "description-text", style = "margin-top: 15px;",
                      "The second major constraint is the presence of disturbances that cannot be detected directly by sensors. 
                      Robotic submarines face water currents that shift trajectories sideways, while robotic blimps experience 
                      wind currents and gas leakage affecting buoyancy and maneuverability. These conditions have profound 
                      implications in field robotics where the environment cannot be assumed predictable or fully measurable. 
                      A control system must therefore be complemented with a model capable of adapting to current dynamic 
                      conditions, leading naturally to a learning approach where each function describing the dynamics is 
                      modeled as a task in a statistical learning framework."
                    )
                )
              ),
              
              fluidRow(
                box(width = 6, title = "Problem Description", status = "info", solidHeader = TRUE,
                    p(class = "description-text",
                      "Conventional control relies on ODEs and assumes stationary system dynamics. Ignoring environmental 
                      complexities such as unknown disturbances leads to inaccurate system models. While non-linear model-based 
                      predictive control can model disturbances, it still relies on time-invariant dynamics. Learning from 
                      high-dimensional state-action spaces becomes challenging, especially when dynamic conditions change. 
                      A flexible model capable of learning complex dynamics from scratch and updating itself to current 
                      conditions is essential."
                    ),
                    
                    div(class = "concept-box",
                        h4("Example: Robotic Blimp Challenges"),
                        p("The aerial robot faces multiple dynamic challenges:"),
                        tags$ul(
                          tags$li("Time-variant dynamics due to continuous air leakage"),
                          tags$li("Changing buoyancy affects actuator effectiveness"),
                          tags$li("External wind disturbances alter trajectory"),
                          tags$li("Body dynamics not fully predictable")
                        ),
                        p(strong("Solution:"), " Continuous knowledge updates through active learning")
                    ),
                    
                    div(class = "math-formula",
                        p("State-action relationship defining system transitions:"),
                        withMathJax("$$s_{t+1} = f(s_t, a_t)$$"),
                        p("where ", withMathJax("$s_t$"), " is the state at time t, ", 
                          withMathJax("$a_t$"), " is the applied action, and ", 
                          withMathJax("$f$"), " is the dynamics function to be learned.")
                    )
                ),
                
                box(width = 6, title = "Research Question", status = "warning", solidHeader = TRUE,
                    div(class = "concept-box",
                        p(class = "description-text",
                          "The core challenge addressed in this thesis centers on developing a methodology that efficiently 
                          learns robotic system dynamics while simultaneously selecting the most informative training data. 
                          This involves balancing two competing objectives: maximizing knowledge of the system plant versus 
                          minimizing the control time-step for steady operation. The training dataset must be descriptive 
                          enough for reliable predictions while remaining computationally tractable for real-time control."
                        ),
                        
                        h4("Central Research Question:", style = "color: #e67e22; margin-top: 15px;"),
                        p(strong("How to define an effective active Bayesian learning methodology for 
                                 selecting the most informative dynamics data and build a reliable 
                                 predictive model that exploits the inter-task dependencies?"))
                    ),
                    
                    div(class = "concept-box", style = "background: #fff3cd; margin-top: 15px;",
                        h4("Key Requirements:"),
                        tags$ol(
                          tags$li("Efficient data selection to reduce dataset length"),
                          tags$li("Exploitation of inter-task dependencies"),
                          tags$li("Real-time model updates for changing dynamics"),
                          tags$li("Computational tractability for control applications"),
                          tags$li("Reliable predictions under uncertainty")
                        )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Thesis Contributions", status = "success", solidHeader = TRUE,
                    p(class = "description-text",
                      "This thesis presents three main contributions that address the challenges of learning and controlling 
                      robotic systems in uncertain, time-varying environments. Each contribution builds upon established 
                      theoretical foundations while introducing novel methodologies that have been validated through extensive 
                      simulations and real-world experiments with an autonomous aerial vehicle."
                    )
                )
              ),
              
              fluidRow(
                column(4,
                       box(width = 12, title = "Information Gain Strategy", status = "success", solidHeader = TRUE,
                           div(style = "text-align: center; padding: 20px;",
                               icon("lightbulb", style = "font-size: 48px; color: #00A39A;"),
                               h4(style = "margin-top: 10px; color: #008A82;", "Novel observation selection method")
                           ),
                           div(class = "concept-box",
                               p(class = "description-text",
                                 "A novel method for selecting new observations that maximize information gain with respect 
                                     to already observed training data. This strategy efficiently identifies data points representing 
                                     higher knowledge gain about real tasks according to dataset entropy. The method outperforms 
                                     approaches based on Euclidean distances, particularly as dimensionality increases. Active 
                                     sampling continues until sufficient knowledge enables reliable dynamics predictions."
                               )
                           )
                       )
                ),
                column(4,
                       box(width = 12, title = "Multi-task Learning", status = "info", solidHeader = TRUE,
                           div(style = "text-align: center; padding: 20px;",
                               icon("project-diagram", style = "font-size: 48px; color: #3498db;"),
                               h4(style = "margin-top: 10px; color: #2980b9;", "MOGP-based task correlation")
                           ),
                           div(class = "concept-box",
                               p(class = "description-text",
                                 "Given dependencies among tasks modeled with non-parametric methods, cross-correlation enhances 
                                     prediction accuracy. A specialized covariance function models task dependencies, used in 
                                     conjunction with information gain criteria to select the most relevant observations. This 
                                     provides significant advantages over conventional single-task Gaussian processes limited to 
                                     single-output modeling without cross-task correlation capabilities."
                               )
                           )
                       )
                ),
                column(4,
                       box(width = 12, title = "Adaptive Control", status = "warning", solidHeader = TRUE,
                           div(style = "text-align: center; padding: 20px;",
                               icon("sync-alt", style = "font-size: 48px; color: #9b59b6;"),
                               h4(style = "margin-top: 10px; color: #8e44ad;", "Real-time model updates")
                           ),
                           div(class = "concept-box",
                               p(class = "description-text",
                                 "Learning methods enable predictive controllers to estimate new actions regardless of variations 
                                     and stochastic events affecting the system. Considering constantly changing dynamics, 
                                     non-parametric predictive models update with the most recent system data. Active relearning 
                                     represents a significant advantage over conventional model-based predictive control assuming 
                                     time-invariant dynamics, enabling robust operation under real-world conditions."
                               )
                           )
                       )
                )
              )
      ),
      
      # Chapter 2: Background
      tabItem(tabName = "ch2",
              fluidRow(
                box(width = 12, title = "Chapter 2: Background - Overview", status = "primary", solidHeader = TRUE,
                    div(class = "concept-box",
                        p(class = "description-text",
                          "This chapter provides the theoretical foundations essential for understanding active Bayesian learning 
                          of robotic systems dynamics. Four fundamental topics converge to form the framework: Bayesian learning, 
                          Gaussian process regression, information theory, and optimal linear control. Bayesian learning offers 
                          robust statistical techniques for inferring probability distributions over random variables, avoiding 
                          the overfitting problems inherent in maximum likelihood approaches. Gaussian processes extend Bayesian 
                          principles by placing multivariate Gaussian distributions over function spaces, enabling non-parametric 
                          modeling of complex, non-linear relationships with principled uncertainty quantification. The chapter 
                          details how GPs naturally incorporate Occam's Razor through their marginal likelihood formulation, 
                          penalizing model complexity while fitting data. Information theory concepts, particularly Shannon entropy 
                          and information content, provide mathematical tools for quantifying the informativeness of observations—a 
                          critical foundation for the active learning strategy developed later. The entropy of probability 
                          distributions measures how exceptional outcomes are, guiding efficient training data selection. Linear 
                          Quadratic Regulator (LQR) control theory provides the optimal control framework, showing how to find 
                          feedback gain matrices that minimize quadratic cost functions. The chapter demonstrates how LQR extends 
                          to non-linear systems through first-order linearization and establishes the principle of separation, 
                          which decouples observer and controller design while maintaining system stability. These theoretical 
                          elements form an integrated foundation enabling the novel contributions presented in subsequent chapters."
                        )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Bayesian Learning", status = "primary", solidHeader = TRUE,
                    p(class = "description-text",
                      "Bayesian learning represents a powerful statistical framework for building probabilistic models from data. 
                      Unlike frequentist approaches that treat parameters as fixed unknown values, Bayesian methods treat parameters 
                      as random variables with probability distributions. This paradigm shift enables incorporation of prior knowledge, 
                      principled uncertainty quantification, and sequential updating as new data arrives. The framework revolves around 
                      Bayes' theorem, which provides a systematic way to update beliefs about parameters given observed data."
                    ),
                    
                    div(class = "math-formula",
                        h4("Bayes' Theorem:"),
                        withMathJax("$$p(\\theta|z) = \\frac{p(z|\\theta)p(\\theta)}{p(z)}$$"),
                        tags$ul(
                          tags$li(withMathJax("$p(\\theta)$ - "), strong("Prior:"), " Initial beliefs about parameter values before observing data"),
                          tags$li(withMathJax("$p(z|\\theta)$ - "), strong("Likelihood:"), " Probability of observing data given parameter values"),
                          tags$li(withMathJax("$p(z)$ - "), strong("Marginal likelihood:"), " Normalizing constant (evidence) independent of parameters"),
                          tags$li(withMathJax("$p(\\theta|z)$ - "), strong("Posterior:"), " Updated beliefs about parameters after observing data")
                        )
                    ),
                    
                    div(class = "concept-box",
                        h4("Advantages Over Maximum Likelihood:"),
                        p(class = "description-text",
                          "The prior ", withMathJax("$p(\\theta)$"), " expresses initial beliefs about parameter values before training 
                          data is available. This capability to incorporate prior knowledge distinguishes Bayesian learning from Maximum 
                          Likelihood Estimation (MLE), which simply maximizes ", withMathJax("$p(z|\\theta)$"), " with respect to ", 
                          withMathJax("$\\theta$"), ". MLE can lead to overfitting—creating overly complex models that fit training 
                          data perfectly but generalize poorly to new data. Bayesian methods naturally balance model complexity against 
                          data fit through the prior and marginal likelihood, embodying the principle of Occam's Razor: prefer simpler 
                          explanations unless data strongly supports complexity."
                        )
                    ),
                    
                    div(class = "math-formula",
                        h4("Marginal Likelihood (Evidence):"),
                        withMathJax("$$p(z) = \\int p(z|\\theta)p(\\theta)d\\theta$$"),
                        p("This integral marginalizes over all possible parameter values, automatically accounting for model complexity.")
                    )
                )
              ),
              
              fluidRow(
                box(width = 6, title = "Gaussian Process Regression", status = "info", solidHeader = TRUE,
                    p(class = "description-text",
                      "A Gaussian Process (GP) is a collection of random variables, any finite number of which have a joint Gaussian 
                      distribution. GPs provide a Bayesian non-parametric approach to regression, placing priors directly over function 
                      spaces rather than over parameters of a fixed functional form. This flexibility allows GPs to model complex, 
                      non-linear relationships while maintaining principled uncertainty estimates. The GP is fully specified by its 
                      mean function and covariance (kernel) function, which encode assumptions about the smoothness and structure of 
                      the underlying function."
                    ),
                    
                    div(class = "math-formula",
                        h4("GP Definition:"),
                        withMathJax("$$f \\sim \\mathcal{GP}(m(x), c(x,x'))$$"),
                        withMathJax("$$m(x) = \\mathbb{E}[f(x)]$$"),
                        withMathJax("$$c(x,x') = \\mathbb{E}[(f(x)-m(x))(f(x')-m(x'))]$$"),
                        p("The mean function ", withMathJax("$m(x)$"), " represents the expected value of the function at input ", 
                          withMathJax("$x$"), ", while the covariance function ", withMathJax("$c(x,x')$"), " encodes the correlation 
                          between function values at different inputs.")
                    ),
                    
                    h4("Squared Exponential Covariance:"),
                    div(class = "math-formula",
                        withMathJax("$$c_{sq}(x,x') = \\sigma_f^2 \\exp\\left(-\\frac{1}{2}(x-x')^T\\Lambda(x-x')\\right)$$"),
                        p("where ", withMathJax("$\\sigma_f^2$"), " controls the overall variance and ", withMathJax("$\\Lambda = \\text{diag}(l_1, \\ldots, l_d)$"), 
                          " contains length-scales ", withMathJax("$l_i$"), " for each input dimension. The length-scale determines 
                          how quickly the correlation decays with distance—small length-scales allow rapid variation while large 
                          length-scales enforce smoothness.")
                    ),
                    
                    div(class = "concept-box",
                        h4("Key Properties:"),
                        tags$ul(
                          tags$li(strong("Non-parametric:"), " Model complexity adapts to data rather than being fixed a priori"),
                          tags$li(strong("Uncertainty quantification:"), " Provides predictive variance indicating confidence"),
                          tags$li(strong("Occam's Razor:"), " Automatically penalizes complex models through marginal likelihood"),
                          tags$li(strong("Flexible:"), " Different kernels encode different assumptions about function structure")
                        )
                    )
                ),
                
                box(width = 6, title = "GP Predictions", status = "warning", solidHeader = TRUE,
                    p(class = "description-text",
                      "Given training data consisting of inputs ", withMathJax("$X$"), " and corresponding noisy observations ", 
                      withMathJax("$y$"), ", GP regression provides a posterior distribution over possible functions consistent with 
                      the data. This posterior is itself a GP, allowing prediction at new test points ", withMathJax("$X_*$"), " 
                      with both mean predictions and uncertainty estimates. The predictive distribution is obtained by conditioning 
                      the joint Gaussian distribution of training and test points on the observed training data."
                    ),
                    
                    div(class = "math-formula",
                        h4("Predictive Distribution:"),
                        withMathJax("$$f_*|X_*, X, y \\sim \\mathcal{N}(\\bar{f}_*, \\text{cov}(f_*))$$"),
                        
                        h4("Predictive Mean:"),
                        withMathJax("$$\\bar{f}_* = C(X_*,X)[C(X,X)+\\sigma_n^2I]^{-1}y$$"),
                        p("The mean prediction is a weighted combination of training outputs, where weights depend on the similarity 
                          (covariance) between test and training inputs."),
                        
                        h4("Predictive Covariance:"),
                        withMathJax("$$\\text{cov}(f_*) = C(X_*,X_*) - C(X_*,X)[C(X,X)+\\sigma_n^2I]^{-1}C(X,X_*)$$"),
                        p("The covariance represents remaining uncertainty after conditioning on training data. It decreases near 
                          training points and increases in regions with sparse data.")
                    ),
                    
                    div(class = "concept-box",
                        h4("Computational Complexity:"),
                        tags$ul(
                          tags$li(withMathJax("Matrix inversion $(C(X,X)+\\sigma_n^2I)^{-1}$: $\\mathcal{O}(N^3)$")),
                          tags$li(withMathJax("Prediction at one test point: $\\mathcal{O}(N^2)$")),
                          tags$li("Adding one training point increases cost cubically")
                        ),
                        p(strong("Implication:"), " Efficient data selection is crucial to maintain computational tractability 
                          while ensuring model accuracy. This motivates the information gain strategy developed in Chapter 4.")
                    ),
                    
                    div(class = "math-formula",
                        h4("Hyperparameter Learning:"),
                        withMathJax("$$\\theta_{max} = \\arg\\max_\\theta \\{\\log(p(y|X,\\theta))\\}$$"),
                        p("Hyperparameters (length-scales, signal variance, noise variance) are learned by maximizing the log 
                          marginal likelihood, which automatically trades off data fit against model complexity.")
                    )
                )
              ),
              
              fluidRow(
                box(width = 6, title = "Information Theory", status = "success", solidHeader = TRUE,
                    p(class = "description-text",
                      "Information theory, pioneered by Claude Shannon in 1948, provides mathematical tools for quantifying information 
                      content and uncertainty in probability distributions. These concepts are fundamental to the active learning strategy, 
                      as they enable principled selection of the most informative observations. Shannon information content measures how 
                      'surprising' or exceptional an event is—rare events carry more information than common events. Entropy generalizes 
                      this concept to entire distributions, measuring the average information content or uncertainty."
                    ),
                    
                    h4("Shannon Information Content:"),
                    div(class = "math-formula",
                        withMathJax("$$h(x) = \\log_2\\frac{1}{p(x)} = -\\log_2 p(x)$$"),
                        p("An outcome ", withMathJax("$x$"), " with low probability ", withMathJax("$p(x)$"), " has high information 
                          content ", withMathJax("$h(x)$"), ". Intuitively, observing a rare event tells us more than observing 
                          a common event. Information content is measured in bits when using logarithm base 2.")
                    ),
                    
                    div(class = "concept-box",
                        h4("Example: English Text"),
                        p("In English text, the letter 'e' occurs frequently (", withMathJax("$p(e) \\approx 0.127$"), 
                          "), giving low information content ", withMathJax("$h(e) \\approx 2.98$"), " bits. The letter 'z' 
                          is rare (", withMathJax("$p(z) \\approx 0.0007$"), "), yielding high information content ", 
                          withMathJax("$h(z) \\approx 10.48$"), " bits. Observing 'z' provides more information than observing 'e'.")
                    ),
                    
                    h4("Entropy:"),
                    div(class = "math-formula",
                        withMathJax("$$H(x) = \\sum_{x\\in\\mathcal{X}} p(x)\\log\\frac{1}{p(x)} = \\mathbb{E}[-\\log p(x)]$$"),
                        p("Entropy is the expected information content—the average surprise when sampling from distribution ", 
                          withMathJax("$p(x)$"), ". High entropy indicates high uncertainty; low entropy indicates the distribution 
                          is concentrated on a few outcomes.")
                    ),
                    
                    div(class = "concept-box",
                        h4("Properties of Entropy:"),
                        tags$ul(
                          tags$li(withMathJax("$H(x) \\geq 0$"), " (non-negative)"),
                          tags$li(withMathJax("$H(x) = 0$"), " iff one outcome has probability 1 (no uncertainty)"),
                          tags$li(withMathJax("$H(x) \\leq \\log|\\mathcal{X}|$"), " (maximized by uniform distribution)"),
                          tags$li("Different logarithm bases change units: base 2 gives bits, base e gives nats")
                        )
                    )
                ),
                
                box(width = 6, title = "Linear Quadratic Control", status = "danger", solidHeader = TRUE,
                    p(class = "description-text",
                      "The Linear Quadratic Regulator (LQR) provides an optimal control framework for systems with linear dynamics 
                      and quadratic cost functions. LQR finds the feedback gain matrix that minimizes a weighted combination of 
                      state deviation and control effort, providing elegant closed-form solutions via the Riccati equation. While 
                      originally formulated for linear systems, LQR extends to non-linear systems through local linearization around 
                      operating points, making it applicable to robotic systems with complex dynamics."
                    ),
                    
                    h4("System Dynamics:"),
                    div(class = "math-formula",
                        withMathJax("$$s_{t+1} = A_t s_t + B_t a_t + \\epsilon_t$$"),
                        p("where ", withMathJax("$s_t$"), " is the state, ", withMathJax("$a_t$"), " is the action (control input), ", 
                          withMathJax("$A_t$"), " is the state transition matrix, ", withMathJax("$B_t$"), " is the control matrix, 
                          and ", withMathJax("$\\epsilon_t$"), " is system noise.")
                    ),
                    
                    h4("LQR Cost Function:"),
                    div(class = "math-formula",
                        withMathJax("$$J_{t,t_f} = \\int_t^{t_f} (s_\\tau^T Q_\\tau s_\\tau + a_\\tau^T R_\\tau a_\\tau)d\\tau$$"),
                        p("The cost function penalizes state deviations (via ", withMathJax("$Q$"), " matrix) and control effort 
                          (via ", withMathJax("$R$"), " matrix). Larger ", withMathJax("$Q$"), " values enforce tighter state tracking; 
                          larger ", withMathJax("$R$"), " values discourage large control actions.")
                    ),
                    
                    h4("Optimal Gain Matrix:"),
                    div(class = "math-formula",
                        withMathJax("$$K_0 = R_t^{-1}B_t^TM_0$$"),
                        withMathJax("$$a_t = -K_0 s_t$$"),
                        p("The optimal control is linear feedback with gain ", withMathJax("$K_0$"), " determined by solving the 
                          Riccati equation for ", withMathJax("$M_0$"), ".")
                    ),
                    
                    h4("Riccati Equation:"),
                    div(class = "math-formula",
                        withMathJax("$$-\\frac{\\partial M_0}{\\partial t} = A_t^TM_0 + M_0A_t + Q_t - M_0B_tR_t^{-1}B_t^TM_0$$"),
                        p("This first-order non-linear differential equation is solved backwards in time from the terminal condition ", 
                          withMathJax("$M_0(t_f) = 0$"), " using numerical methods.")
                    ),
                    
                    div(class = "concept-box",
                        h4("Extension to Non-linear Systems:"),
                        p(class = "description-text",
                          "For non-linear systems ", withMathJax("$s_{t+1} = f(s_t, a_t)$"), ", LQR applies through local linearization. 
                          Jacobian matrices ", withMathJax("$\\hat{A} = \\frac{\\partial f}{\\partial s}$"), " and ", 
                          withMathJax("$\\hat{B} = \\frac{\\partial f}{\\partial a}$"), " are computed at the current operating point, 
                          then used in place of ", withMathJax("$A$"), " and ", withMathJax("$B$"), " in the Riccati equation. 
                          This approximation works well when the linearization captures the sign and magnitude of derivatives along 
                          the trajectory. In this thesis, GPs provide these derivatives by modeling the system dynamics.")
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Interactive GP Visualization", status = "primary", solidHeader = TRUE,
                    p(class = "description-text",
                      "This interactive visualization demonstrates Gaussian Process regression in action. The true function (red dashed line) 
                      represents an unknown underlying relationship we want to learn. Training points (blue dots) are noisy observations of 
                      this function. The GP prediction (black line) is the mean of the posterior distribution, while the yellow region shows 
                      the 95% confidence interval (±2 standard deviations). Notice how uncertainty increases in regions far from training data 
                      and decreases near observed points. Adjust the number of observations to see how more data reduces uncertainty and improves 
                      predictions. The noise level parameter controls measurement uncertainty—higher noise leads to wider confidence intervals."
                    ),
                    
                    column(4,
                           div(class = "concept-box",
                               sliderInput("n_obs", "Number of Observations:", 
                                           min = 5, max = 50, value = 20, step = 5),
                               p("Controls the number of training points. More observations generally lead to better predictions and lower uncertainty."),
                               
                               sliderInput("noise_level", "Noise Level:", 
                                           min = 0.01, max = 0.5, value = 0.1, step = 0.01),
                               p("Controls measurement noise. Higher values create noisier observations and wider confidence bands."),
                               
                               actionButton("regenerate", "Regenerate", class = "btn-primary"),
                               p(style = "margin-top: 10px;", "Click to generate a new random dataset with the current settings.")
                           )
                    ),
                    column(8,
                           plotlyOutput("gp_plot", height = "400px"),
                           div(class = "concept-box", style = "margin-top: 10px;",
                               h4("Interpretation:"),
                               tags$ul(
                                 tags$li(strong("Black line:"), " GP mean prediction—our best estimate of the true function"),
                                 tags$li(strong("Yellow region:"), " 95% confidence interval—quantifies prediction uncertainty"),
                                 tags$li(strong("Red dashed:"), " True underlying function (unknown in practice)"),
                                 tags$li(strong("Blue points:"), " Noisy training observations"),
                                 tags$li(strong("Key insight:"), " Uncertainty is lowest near data and grows in unexplored regions")
                               )
                           )
                    )
                )
              )
      ),
      
      # Chapter 3: GP Dynamics Modelling
      tabItem(tabName = "ch3",
              fluidRow(
                box(width = 12, title = "Chapter 3: GP Dynamics Modelling and Control - Overview", status = "primary", solidHeader = TRUE,
                    div(class = "concept-box",
                        p(class = "description-text",
                          "This chapter extends Gaussian Process regression to the specific domain of robotic dynamics learning and control. 
                          While Chapter 2 established GP fundamentals, this chapter addresses the practical challenge of modeling dynamic 
                          systems where the relationship between states, actions, and future states must be learned from data. The chapter 
                          introduces the concept of defining each state dimension as a separate task, leading to a multi-task learning framework. 
                          Single-output GPs can model each task independently, but this approach ignores potential correlations between tasks—for 
                          example, how vertical velocity affects height in an aerial vehicle, or how joint angles interact in a robotic arm. 
                          Multiple Output Gaussian Processes (MOGPs) address this limitation by explicitly modeling inter-task dependencies through 
                          cross-covariance functions. The MOGP covariance matrix has a block structure where diagonal blocks capture auto-covariance 
                          within tasks and off-diagonal blocks capture cross-covariance between tasks. This structure enables information sharing 
                          across tasks, improving prediction accuracy with fewer training points. The chapter details the mathematical formulation 
                          of MOGPs, including covariance matrix construction, hyperparameter learning, and multi-task inference. Computational 
                          complexity increases from O(N³) for single GPs to O(M³N³) for MOGPs with M tasks, motivating the need for efficient 
                          data selection strategies. Experimental results on a simulated blimp demonstrate that MOGPs achieve lower prediction 
                          error than independent GPs and provide superior control performance when combined with LQR, validating the multi-task 
                          approach for robotics applications."
                        )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Learning Dynamic Systems", status = "primary", solidHeader = TRUE,
                    p(class = "description-text",
                      "Robotic systems evolve over time according to dynamics that map current states and actions to future states. 
                      Traditional control assumes these dynamics are known through ordinary differential equations (ODEs), but deriving 
                      accurate ODEs requires detailed knowledge of physical parameters (masses, inertias, friction coefficients) that 
                      may be difficult or impossible to measure precisely. Moreover, dynamics can be time-varying due to wear, environmental 
                      changes, or unmodeled effects. Gaussian Processes offer an alternative: learn the dynamics directly from observed 
                      state transitions without requiring explicit physical models. This data-driven approach automatically captures 
                      non-linearities, interactions, and even some unmodeled disturbances, while providing uncertainty estimates that 
                      indicate prediction reliability."
                    ),
                    
                    div(class = "concept-box",
                        h4("Why GPs for Dynamics Learning?"),
                        tags$ul(
                          tags$li(strong("Non-parametric flexibility:"), " Can represent complex, non-linear dynamics without 
                                  committing to a specific functional form"),
                          tags$li(strong("Uncertainty quantification:"), " Provides confidence estimates essential for safe control—the 
                                  controller knows when predictions are unreliable"),
                          tags$li(strong("Automatic complexity control:"), " Occam's Razor built into marginal likelihood prevents overfitting"),
                          tags$li(strong("Handles sensor noise:"), " Explicitly models observation noise as Gaussian, appropriate for 
                                  many sensors"),
                          tags$li(strong("Data efficiency:"), " Can learn from relatively small datasets, important when data collection 
                                  is expensive or dangerous")
                        )
                    )
                )
              ),
              
              fluidRow(
                box(width = 6, title = "Training Data Definition", status = "info", solidHeader = TRUE,
                    p(class = "description-text",
                      "To learn dynamics with GPs, we must first define how to construct training data from observed system behavior. 
                      The key insight is to model the change in state as a function of the current state and action. Rather than predicting 
                      the next state directly, we predict the state difference, which often has more regular statistical properties. This 
                      formulation naturally handles systems with momentum and integrator-like behavior."
                    ),
                    
                    div(class = "math-formula",
                        h4("State-Action Pairs:"),
                        withMathJax("$$x_t = \\{s_{t-1}, a_{t-1}\\}$$"),
                        p("The input to our GP combines the state at time ", withMathJax("$t-1$"), " with the action applied at that time."),
                        
                        h4("State Difference Output:"),
                        withMathJax("$$y_t = (s_t - s_{t-1})|a_{t-1}$$"),
                        p("The output is the observed change in state resulting from applying action ", withMathJax("$a_{t-1}$"), 
                          " at state ", withMathJax("$s_{t-1}$"), "."),
                        
                        h4("Training Dataset:"),
                        withMathJax("$$\\mathcal{D} = \\{X, y\\}$$"),
                        withMathJax("$$X = \\{x_1, x_2, \\ldots, x_n\\}$$"),
                        withMathJax("$$y_m = \\{y_m^1, y_m^2, \\ldots, y_m^n\\}$$"),
                        p("where ", withMathJax("$m$"), " indexes different output dimensions (tasks).")
                    ),
                    
                    div(class = "concept-box",
                        h4("Example: Blimp Vertical Dynamics"),
                        p("For a blimp controlling height:"),
                        tags$ul(
                          tags$li(withMathJax("State: $s_t = \\{h_t, \\dot{h}_t\\}$ (height and vertical velocity)")),
                          tags$li(withMathJax("Action: $a_t$ (propeller thrust command)")),
                          tags$li(withMathJax("Input: $x_t = \\{h_t, \\dot{h}_t, a_t\\}$ (5D if including time)")),
                          tags$li(withMathJax("Output: $y_t = \\{\\Delta h, \\Delta \\dot{h}\\}$ (change in height and velocity)"))
                        ),
                        p("Each output dimension becomes a separate task to learn.")
                    )
                ),
                
                box(width = 6, title = "Single Output GP Prediction", status = "warning", solidHeader = TRUE,
                    p(class = "description-text",
                      "A straightforward approach is to train a separate GP for each task (output dimension). Each GP learns to predict 
                      one component of the state change vector independently. This approach is simple and parallelizable but ignores 
                      potential correlations between tasks—for example, vertical velocity strongly affects height change, and these 
                      dependencies could improve predictions if exploited."
                    ),
                    
                    div(class = "math-formula",
                        h4("Prediction for Task m:"),
                        withMathJax("$$\\bar{f}_{m*} = C_m(x_*, X)[C_m(X,X)+\\sigma_n^2I]^{-1}y_m$$"),
                        p("This is the standard GP prediction formula applied to task ", withMathJax("$m$"), " in isolation."),
                        
                        h4("Complete State Prediction:"),
                        withMathJax("$$\\hat{s}_{t+1} = s_t + \\begin{bmatrix} \\bar{f}_{1*} \\\\ \\bar{f}_{2*} \\\\ \\vdots \\\\ \\bar{f}_{M*} \\end{bmatrix}$$"),
                        p("The predicted next state is the current state plus the predicted changes from all ", withMathJax("$M$"), " tasks.")
                    ),
                    
                    div(class = "concept-box",
                        h4("Computational Cost per Task:"),
                        tags$ul(
                          tags$li(withMathJax("Matrix inversion: $\\mathcal{O}(N^3)$")),
                          tags$li(withMathJax("Prediction: $\\mathcal{O}(N^2)$")),
                          tags$li(withMathJax("Total for $M$ tasks: $M \\times \\mathcal{O}(N^3)$"))
                        )
                    ),
                    
                    div(class = "concept-box",
                        h4("Limitations of Independent GPs:"),
                        tags$ul(
                          tags$li("Ignores correlations between tasks"),
                          tags$li("Cannot share information across dimensions"),
                          tags$li("May require more data per task"),
                          tags$li("Misses opportunities for improved predictions through task relationships")
                        ),
                        p(strong("Solution:"), " Use Multiple Output Gaussian Processes (MOGPs) to explicitly model task dependencies.")
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Multi-Task Learning with MOGPs", status = "success", solidHeader = TRUE,
                    p(class = "description-text",
                      "Many robotic systems exhibit strong correlations between different state dimensions. In a blimp, vertical velocity 
                      directly influences height change. In a robotic arm, joint angles interact through kinematic constraints. In a ground 
                      vehicle, lateral and longitudinal motions couple through wheel slip. Multi-task learning with Multiple Output Gaussian 
                      Processes (MOGPs) exploits these correlations to improve prediction accuracy and data efficiency. The key idea is to 
                      model the joint distribution over all outputs simultaneously, using a covariance function that captures both auto-correlations 
                      (within each task) and cross-correlations (between tasks). This allows information from one task to inform predictions 
                      in related tasks, especially valuable when data is sparse in some dimensions."
                    ),
                    
                    column(6,
                           div(class = "concept-box",
                               h4("Motivation for Multi-Task Learning:"),
                               tags$ul(
                                 tags$li(strong("Physical coupling:"), " State dimensions often interact through physical laws"),
                                 tags$li(strong("Shared context:"), " Different tasks may be affected by common unobserved factors"),
                                 tags$li(strong("Data efficiency:"), " Observations in one task provide information about related tasks"),
                                 tags$li(strong("Improved generalization:"), " Sharing information across tasks acts as regularization")
                               )
                           ),
                           
                           div(class = "math-formula",
                               h4("Covariance Structure:"),
                               withMathJax("$$\\text{cov}(y_i(x), y_j(x')) = c_{y_{ij}} c_x(x,x')$$"),
                               p("The covariance between output ", withMathJax("$i$"), " at input ", withMathJax("$x$"), 
                                 " and output ", withMathJax("$j$"), " at input ", withMathJax("$x'$"), " factorizes into:"),
                               tags$ul(
                                 tags$li(withMathJax("$c_{y_{ij}}$: "), "task similarity (how correlated are tasks ", 
                                         withMathJax("$i$"), " and ", withMathJax("$j$"), ")"),
                                 tags$li(withMathJax("$c_x(x,x')$: "), "input similarity (standard GP kernel)")
                               )
                           )
                    ),
                    
                    column(6,
                           div(class = "math-formula",
                               h4("Multi-task Covariance Matrix:"),
                               withMathJax("$$C_M = (c_{y_{ij}}C_{x_{ij}})_{ij}$$"),
                               
                               withMathJax("$$C_M = \\begin{bmatrix}
                                 c_{y_{11}}C_{x_{11}} & \\cdots & c_{y_{1m}}C_{x_{1m}} \\\\
                                 \\vdots & \\ddots & \\vdots \\\\
                                 c_{y_{m1}}C_{x_{m1}} & \\cdots & c_{y_{mm}}C_{x_{mm}}
                               \\end{bmatrix}$$"),
                               
                               p("This block matrix structure is central to MOGPs:"),
                               tags$ul(
                                 tags$li(strong("Diagonal blocks:"), " Auto-covariance within each task"),
                                 tags$li(strong("Off-diagonal blocks:"), " Cross-covariance between tasks"),
                                 tags$li(strong("Symmetry:"), withMathJax("$c_{y_{ij}} = c_{y_{ji}}$"))
                               )
                           ),
                           
                           div(class = "concept-box",
                               h4("Hyperparameter Reduction:"),
                               p("The task correlation matrix ", withMathJax("$C_y = (c_{y_{ij}})$"), " is parametrized using 
                                 Cholesky decomposition: ", withMathJax("$C_y = P^TP$"), " where ", withMathJax("$P$"), 
                                 " is lower triangular. This requires only ", withMathJax("$M(M+1)/2$"), " parameters instead of ", 
                                 withMathJax("$M^2$"), ", reducing optimization complexity while ensuring ", withMathJax("$C_y$"), 
                                 " remains positive semidefinite.")
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 6, title = "MOGP Inference", status = "primary", solidHeader = TRUE,
                    p(class = "description-text",
                      "With the multi-task covariance matrix defined, MOGP inference proceeds analogously to standard GP regression 
                      but operates on the stacked vector of all outputs simultaneously. The key difference is that predictions for 
                      one task now depend on observations from all tasks through the cross-covariance structure. This sharing of 
                      information is what enables MOGPs to achieve better predictions with less data per task."
                    ),
                    
                    div(class = "math-formula",
                        h4("Predictive Distribution:"),
                        withMathJax("$$f_{m*}|x_*, X, y \\sim \\mathcal{N}(\\bar{f}_{m*}, \\text{cov}(f_{m*}))$$"),
                        
                        h4("Task m Mean Function:"),
                        withMathJax("$$\\bar{f}_{m*} = c_m^T C_M^{-1} y$$"),
                        p("where ", withMathJax("$c_m$"), " contains covariances between test point ", withMathJax("$x_*$"), 
                          " and all training points across all tasks, weighted by task correlations."),
                        
                        h4("Covariance:"),
                        withMathJax("$$\\text{cov}(\\bar{f}_{m*}) = c_* - c_m^T C_M^{-1} c_m$$"),
                        withMathJax("$$c_* = c_x^{mm}(x_*, x_*) + \\sigma_m^2$$")
                    ),
                    
                    div(class = "concept-box",
                        h4("Stacked Output Vector:"),
                        withMathJax("$$y = [y_{1,1}, \\ldots, y_{1,N_1}, y_{2,1}, \\ldots, y_{2,N_2}, \\ldots, y_{M,1}, \\ldots, y_{M,N_M}]^T$$"),
                        p("All observations from all tasks are concatenated into a single vector. The MOGP covariance matrix ", 
                          withMathJax("$C_M$"), " has dimension ", withMathJax("$(\\sum_m N_m) \\times (\\sum_m N_m)$"), 
                          " where ", withMathJax("$N_m$"), " is the number of observations for task ", withMathJax("$m$"), ".")
                    )
                ),
                
                box(width = 6, title = "Computational Complexity", status = "danger", solidHeader = TRUE,
                    p(class = "description-text",
                      "The primary computational cost in MOGP inference is inverting the multi-task covariance matrix. This complexity 
                      grows cubically with the total number of observations across all tasks. For systems with many tasks or long 
                      operation times, this can become prohibitive, motivating the development of efficient data selection strategies 
                      to minimize the number of required training points while maintaining prediction accuracy."
                    ),
                    
                    div(class = "concept-box",
                        h4("MOGP with M tasks:"),
                        tags$ul(
                          tags$li(withMathJax("Matrix inversion: $\\mathcal{O}(M^3N^3)$")),
                          tags$li(withMathJax("Prediction: $\\mathcal{O}(M^2N^2)$")),
                          tags$li(withMathJax("Grows cubically with both $M$ and $N$"))
                        ),
                        
                        h4("Comparison to Independent GPs:"),
                        tags$ul(
                          tags$li(withMathJax("Independent: $M \\times \\mathcal{O}(N^3) = \\mathcal{O}(MN^3)$")),
                          tags$li(withMathJax("MOGP: $\\mathcal{O}(M^3N^3)$")),
                          tags$li(withMathJax("MOGP is $M^2$ times more expensive"))
                        ),
                        
                        p(strong("Critical Challenge:"), " Need efficient data selection strategy to reduce ", withMathJax("$N$"), 
                          " while maintaining prediction accuracy across all tasks.")
                    ),
                    
                    div(class = "math-formula",
                        h4("Log Marginal Likelihood:"),
                        withMathJax("$$\\log p(y|X) = -\\frac{1}{2}\\log|\\Sigma_M| - \\frac{1}{2}y^T\\Sigma_M^{-1}y - \\frac{MN}{2}\\log(2\\pi)$$"),
                        withMathJax("$$\\Sigma_M = C_M + \\Gamma_M$$"),
                        p("where ", withMathJax("$\\Gamma_M$"), " is a diagonal matrix containing noise variances ", 
                          withMathJax("$\\sigma_m^2$"), " for each task. Hyperparameters are learned by maximizing this likelihood.")
                    ),
                    
                    div(class = "concept-box",
                        h4("Hyperparameters:"),
                        withMathJax("$$\\Theta = \\{P, \\theta_x, \\sigma\\}$$"),
                        tags$ul(
                          tags$li(withMathJax("$P$: "), "Cholesky factor of task correlation matrix"),
                          tags$li(withMathJax("$\\theta_x = \\{\\theta_1, \\ldots, \\theta_M\\}$: "), "kernel parameters per task"),
                          tags$li(withMathJax("$\\sigma = \\{\\sigma_1, \\ldots, \\sigma_M\\}$: "), "noise variances per task")
                        )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Experimental Results: Simulated Blimp", status = "info", solidHeader = TRUE,
                    p(class = "description-text",
                      "To validate the multi-task learning approach, experiments were conducted on a simulated robotic blimp with vertical 
                      dynamics modeled using theoretical ODEs including drag and buoyancy. Gaussian noise was added to simulate sensor 
                      uncertainty. The vertical state consists of two tasks: height (h) and vertical velocity (ḣ). These tasks are naturally 
                      correlated—velocity directly determines height change. The experiment compared prediction accuracy and control performance 
                      between independent single-output GPs (one per task) and a two-output MOGP exploiting task correlation. Both models were 
                      trained with the same randomly selected observations to ensure fair comparison."
                    ),
                    
                    column(4,
                           h4("State-Action Space:"),
                           div(class = "math-formula",
                               withMathJax("$$s = \\{h, \\dot{h}\\}$$"),
                               tags$ul(
                                 tags$li(withMathJax("$-5m \\leq h \\leq 5m$ (height)")),
                                 tags$li(withMathJax("$-1m/s \\leq \\dot{h} \\leq 1m/s$ (vertical speed)")),
                                 tags$li(withMathJax("$-1 \\leq a \\leq 1$ (action)"))
                               ),
                               p("Action ", withMathJax("$a$"), " multiplied by ", withMathJax("$F_m = 10N$"), " to produce vertical force."),
                               p("Sampling rate: 5 Hz (", withMathJax("$\\Delta t = 0.2s$"), ")")
                           )
                    ),
                    column(4,
                           h4("Experimental Setup:"),
                           div(class = "concept-box",
                               tags$ul(
                                 tags$li("Initial training: 56 random points"),
                                 tags$li("Iterative addition: 4 points per iteration"),
                                 tags$li("Test set: Fixed random points"),
                                 tags$li("Repetitions: 15 experiments per method"),
                                 tags$li("Metric: Root mean square error"),
                                 tags$li("Comparison: Single GP vs. MOGP")
                               )
                           )
                    ),
                    column(4,
                           h4("Key Findings:"),
                           div(class = "concept-box",
                               tags$ul(
                                 tags$li(strong("MOGP achieved lower prediction error"), " than single GPs for both tasks"),
                                 tags$li(strong("Height prediction:"), " MOGP significantly more accurate after 30 points"),
                                 tags$li(strong("Velocity prediction:"), " MOGP advantage clear throughout"),
                                 tags$li(strong("Task correlation:"), " improved learning efficiency by sharing information"),
                                 tags$li(strong("Control performance:"), " MOGP-based LQR showed smoother, more robust control")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Control Performance Comparison", status = "success", solidHeader = TRUE,
                    p(class = "description-text",
                      "Beyond prediction accuracy, the ultimate test of a dynamics model is its performance when used in a control loop. 
                      The learned GP and MOGP models were integrated with a Linear Quadratic Regulator (LQR) controller to track a height 
                      reference. The LQR computes optimal actions based on the system derivatives (Jacobians) estimated from the learned models. 
                      More accurate models lead to better derivative estimates, enabling the controller to make better decisions. The control 
                      objective was to move the simulated blimp from initial height h=0 to target height h=2 meters while minimizing overshoot 
                      and settling time."
                    ),
                    
                    column(6,
                           div(class = "concept-box",
                               h4("Control Setup:"),
                               tags$ul(
                                 tags$li("Controller: Linear Quadratic Regulator (LQR)"),
                                 tags$li("Derivatives: Estimated from GP/MOGP models"),
                                 tags$li("Initial state: h = 0m, ḣ = 0m/s"),
                                 tags$li("Target state: h* = 2m, ḣ* = 0m/s"),
                                 tags$li("Time step: Δt = 0.2s"),
                                 tags$li("Horizon: 50 control iterations (10 seconds)")
                               )
                           ),
                           
                           div(class = "math-formula",
                               h4("LQR with Learned Dynamics:"),
                               withMathJax("$$\\hat{A}_t = \\frac{\\partial \\bar{f}}{\\partial s}\\bigg|_{s_t, a_t}, \\quad \\hat{B}_t = \\frac{\\partial \\bar{f}}{\\partial a}\\bigg|_{s_t, a_t}$$"),
                               p("Jacobians computed from GP/MOGP mean function ", withMathJax("$\\bar{f}$"), " at current state and action."),
                               
                               withMathJax("$$a_t = -K_t s_t$$"),
                               p("Optimal gain ", withMathJax("$K_t$"), " determined by solving Riccati equation with ", 
                                 withMathJax("$\\hat{A}_t, \\hat{B}_t$"), ".")
                           )
                    ),
                    column(6,
                           div(class = "concept-box",
                               h4("Observed Behaviors:"),
                               
                               h5("Single GP Controller:"),
                               tags$ul(
                                 tags$li("Reached target faster (20 iterations)"),
                                 tags$li("Overshoot: ~0.4m (20% above target)"),
                                 tags$li("More oscillation in velocity"),
                                 tags$li("Less smooth control actions")
                               ),
                               
                               h5("MOGP Controller:"),
                               tags$ul(
                                 tags$li("Slightly slower convergence"),
                                 tags$li("Similar overshoot: ~0.4m"),
                                 tags$li("Smoother velocity profile"),
                                 tags$li("More refined control actions"),
                                 tags$li("Better damping behavior")
                               )
                           ),
                           
                           div(class = "concept-box",
                               h4("Conclusion:"),
                               p(class = "description-text",
                                 "The MOGP model provided more robust control despite similar overshoot. The key advantage was 
                                 smoother dynamics estimates leading to less aggressive control actions. This is particularly important 
                                 for physical systems where actuator wear and energy consumption matter. The results validate the 
                                 multi-task learning approach: by exploiting task correlations, MOGPs learn better models from the 
                                 same amount of data, translating to improved control performance.")
                           )
                    )
                )
              )
      ),
      
      # Chapter 4: Active Learning & Control
      tabItem(tabName = "ch4",
              fluidRow(
                box(width = 12, title = "Chapter 4: Active Learning and Control - Overview", status = "primary", solidHeader = TRUE,
                    div(class = "concept-box",
                        p(class = "description-text",
                          "This chapter addresses the critical challenge of efficient training data selection for learning robotic system 
                          dynamics. While Chapters 2 and 3 established the theoretical foundations and modeling frameworks, practical 
                          deployment requires strategies for deciding which observations to collect. Random or uniform sampling is computationally 
                          wasteful—many observations provide little new information. Active learning strategies intelligently select observations 
                          that maximize information gain, dramatically reducing the number of required data points. The chapter begins by 
                          introducing Bayesian optimal design, which formalizes the concept of informative experiments using Shannon information 
                          theory. The entropy of a posterior distribution quantifies remaining uncertainty; observations reducing entropy most 
                          are most informative. For Gaussian Processes, entropy reduction relates directly to posterior variance reduction, 
                          providing a natural selection criterion. Two information gain algorithms are presented: a single-task version selecting 
                          high-variance points independently per task, and a multi-task version jointly optimizing observation selection across 
                          all tasks using the MOGP covariance structure. The multi-task version exploits correlations to select observations 
                          benefiting multiple tasks simultaneously, further improving efficiency. A key innovation combines information gain with 
                          LQR control: the algorithm identifies informative target points in state-action space, then uses LQR to guide the 
                          system toward those targets while learning. This simultaneous sampling and control strategy enables on-line learning 
                          during normal operation. The chapter analyzes control stability using the separation principle, showing that steady-state 
                          observers (low-variance GPs) combined with optimal controllers (LQR) guarantee system convergence. Experimental validation 
                          on a simulated cart-pole system demonstrates that information gain sampling achieves lower prediction error with fewer 
                          observations compared to equally-spaced sampling, particularly for non-linear systems where uniform grids miss important 
                          regions."
                        )
                    )
                )
              ),
              
              fluidRow(
                box(width = 6, title = "Bayesian Optimal Design", status = "info", solidHeader = TRUE,
                    p(class = "description-text",
                      "Bayesian optimal design provides a principled framework for experimental design based on information theory. 
                      The goal is to select experiments (observations) that maximize information gain about unknown parameters or functions. 
                      In the context of GP dynamics learning, 'experiments' correspond to visiting specific state-action pairs and observing 
                      the resulting state transitions. Some state-action regions are more informative than others—regions where the current 
                      model is uncertain provide more information when observed than regions where predictions are already confident."
                    ),
                    
                    div(class = "math-formula",
                        h4("Prior and Posterior Information:"),
                        withMathJax("$$I(\\theta) = \\int p(\\theta)\\log p(\\theta)d\\theta$$"),
                        p("Information (negative entropy) before observing data ", withMathJax("$x$"), "."),
                        
                        withMathJax("$$I(\\theta|x) = \\int p(\\theta|x)\\log p(\\theta|x)d\\theta$$"),
                        p("Information after observing ", withMathJax("$x$"), ". Lower entropy means more certainty.")
                    ),
                    
                    div(class = "math-formula",
                        h4("Information Gain:"),
                        withMathJax("$$I(x) = \\mathbb{E}\\left\\{\\log\\frac{p(\\theta|x)}{p(\\theta)}\\right\\}$$"),
                        
                        withMathJax("$$I(x) = \\int_\\Theta\\int_X \\log\\left(\\frac{p(\\theta|x)}{p(\\theta)}\\right)p(x|\\theta)p(\\theta)dxd\\theta$$"),
                        p("The expected reduction in entropy from observing ", withMathJax("$x$"), ". Higher values indicate more informative observations.")
                    ),
                    
                    div(class = "concept-box",
                        h4("Interpretation:"),
                        p("Information gain measures how much an observation ", withMathJax("$x$"), " is expected to reduce uncertainty 
                          about parameters ", withMathJax("$\\theta$"), " (or in our case, the function ", withMathJax("$f$"), "). 
                          The expectation is over possible observations weighted by their probability under the current model. Observations 
                          in high-uncertainty regions have high information gain because they resolve substantial ambiguity.")
                    )
                ),
                
                box(width = 6, title = "Utility Functions", status = "warning", solidHeader = TRUE,
                    p(class = "description-text",
                      "While pure information gain identifies the most informative observations, practical considerations may require 
                      incorporating additional objectives. Utility functions generalize information gain by adding value functions encoding 
                      task-specific goals. For example, in robotics we might want observations that are not only informative but also 
                      safe (avoiding dangerous states) or efficient (minimizing travel distance). The utility function balances these 
                      competing objectives."
                    ),
                    
                    div(class = "math-formula",
                        h4("General Utility Function:"),
                        withMathJax("$$U(x,h) = I(x) + V(x|h)$$"),
                        tags$ul(
                          tags$li(withMathJax("$I(x)$: "), "Information gain from observation ", withMathJax("$x$")),
                          tags$li(withMathJax("$V(x|h)$: "), "Value function encoding task-specific preferences under design ", 
                                  withMathJax("$h$"))
                        ),
                        p("The optimal observation maximizes this utility.")
                    ),
                    
                    div(class = "concept-box",
                        h4("Example: Information Gain + Control Cost"),
                        withMathJax("$$U(x_j) = \\alpha J(x^*, x_j)^{-1} + \\beta(-\\log v_j)$$"),
                        tags$ul(
                          tags$li(withMathJax("$J(x^*, x_j)$: "), "Cost (e.g., distance) from target ", withMathJax("$x^*$"), 
                                  " to candidate ", withMathJax("$x_j$")),
                          tags$li(withMathJax("$v_j$: "), "Predictive variance (higher = more informative)"),
                          tags$li(withMathJax("$\\alpha, \\beta$: "), "Weights balancing goal proximity vs. information gain")
                        ),
                        p("This formulation encourages exploring informative regions while progressing toward control objectives.")
                    ),
                    
                    div(class = "concept-box",
                        h4("Optimal Experimental Design Principle (Lindley 1956):"),
                        p(strong("\"Perform an experiment for which the expected gain in information is the greatest, and continue 
                                 experimentation until a pre-assigned amount of information has been obtained.\"")),
                        p("This principle underpins the information gain strategies developed in this thesis. Active learning terminates 
                          when model uncertainty falls below a threshold, indicating sufficient knowledge for reliable control.")
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "GP-based Information Gain", status = "success", solidHeader = TRUE,
                    p(class = "description-text",
                      "For Gaussian Processes, information gain has an elegant closed-form expression in terms of predictive variance. 
                      The entropy of a Gaussian distribution depends only on its variance, making variance reduction equivalent to entropy 
                      reduction. This connection enables computationally efficient active learning: instead of computing complex integrals, 
                      we simply identify high-variance points. The predictive variance naturally captures both distance from training data 
                      (points far from observed regions have high variance) and model uncertainty (regions where the function could behave 
                      in many ways consistent with data)."
                    ),
                    
                    column(6,
                           div(class = "math-formula",
                               h4("Entropy of Gaussian:"),
                               withMathJax("$$H[p(f_j)] = \\frac{1}{2}\\log(2\\pi e v_j)$$"),
                               p("For a Gaussian random variable with variance ", withMathJax("$v_j$"), ", entropy depends only on variance."),
                               
                               h4("Entropy Score:"),
                               withMathJax("$$\\Delta_j = H[p(f_j|X_I)] - H[p(f_j|X_I \\cup x_j)]$$"),
                               p("Change in entropy from adding observation ", withMathJax("$x_j$"), " to training set ", withMathJax("$X_I$"), "."),
                               
                               h4("Simplified Form:"),
                               withMathJax("$$\\Delta_j = \\log\\left(1 + \\frac{v_j}{\\sigma^2}\\right)$$"),
                               p("Derived using properties of Gaussian conditioning. Monotonically related to variance ", withMathJax("$v_j$"), ".")
                           ),
                           
                           div(class = "concept-box",
                               h4("Key Insight:"),
                               p(strong("Maximizing information gain ≡ Selecting high-variance points")),
                               p("This equivalence makes GP active learning computationally tractable. We don't need to compute complex 
                                 information-theoretic quantities—just evaluate the GP predictive variance at candidate locations.")
                           )
                    ),
                    column(6,
                           div(class = "math-formula",
                               h4("Point Selection:"),
                               withMathJax("$$x_j = \\arg\\max_{x_j \\in \\mathbb{R}^D} \\Delta_j = \\arg\\max_{x_j} v_j$$"),
                               p("Select the observation with maximum predictive variance."),
                               
                               h4("After Adding ", withMathJax("$x_j$"), ":"),
                               withMathJax("$$(v_j^{new})^{-1} = v_j^{-1} + \\sigma^{-2}$$"),
                               p("Variance at ", withMathJax("$x_j$"), " reduces substantially after observing it. The reduction is larger 
                                 for smaller noise ", withMathJax("$\\sigma^2$"), " (more informative observations).")
                           ),
                           
                           div(class = "concept-box",
                               h4("Advantages Over Distance-Based Selection:"),
                               tags$ul(
                                 tags$li(strong("Adapts to function structure:"), " Smooth regions need fewer points than rapidly varying regions"),
                                 tags$li(strong("Handles non-linear dynamics:"), " Automatically focuses on complex areas"),
                                 tags$li(strong("Scales with dimensionality:"), " Distance-based methods suffer \"curse of dimensionality\""),
                                 tags$li(strong("Theoretically grounded:"), " Based on information theory rather than heuristics")
                               )
                           ),
                           
                           div(class = "concept-box",
                               h4("Termination Criterion:"),
                               p("Active learning stops when ", withMathJax("$\\Delta_j < \\epsilon$"), " for some threshold ", 
                                 withMathJax("$\\epsilon$"), ". This indicates remaining model uncertainty is acceptably low across 
                                 the state-action space. The threshold depends on control requirements—safety-critical applications 
                                 demand lower uncertainty.")
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Information Gain Learning Algorithm", status = "primary", solidHeader = TRUE,
                    p(class = "description-text",
                      "Two algorithmic variants are presented for applying information gain to dynamics learning. Algorithm 1 (single-task version) 
                      treats each output dimension independently, selecting high-variance points per task. This is simpler and works well when 
                      tasks are weakly correlated. Algorithm 2 (multi-task version) leverages the MOGP covariance structure to jointly select 
                      observations benefiting multiple tasks simultaneously. This is more sophisticated and efficient when tasks are strongly 
                      correlated. Both algorithms integrate with LQR control to enable simultaneous learning and operation."
                    ),
                    
                    column(6,
                           h4("Algorithm 1: Single Task Version"),
                           div(class = "concept-box",
                               p(strong("For each task m ∈ {1,...,M}:")),
                               tags$ol(
                                 tags$li(strong("Compute variance:"), " Evaluate GP predictive variance ", withMathJax("$v_j^m$"), 
                                         " at all candidate points for task ", withMathJax("$m$")),
                                 tags$li(strong("Select point:"), withMathJax("$x_j^m = \\arg\\max_{x_j} \\Delta_j^m = \\arg\\max_{x_j} v_j^m$")),
                                 tags$li(strong("Navigate to point:"), " Use LQR to guide system toward ", withMathJax("$x_j^m$"), 
                                         ". May take multiple control actions."),
                                 tags$li(strong("Add observation:"), " Once close enough, add ", withMathJax("$(x_j^m, y_j^m)$"), 
                                         " to training set for task ", withMathJax("$m$")),
                                 tags$li(strong("Update hyperparameters:"), " If ", withMathJax("$m = M$"), ", optimize ", 
                                         withMathJax("$\\Theta$"), " based on updated training set"),
                                 tags$li(strong("Repeat:"), " Until ", withMathJax("$\\Delta_j^m < \\epsilon$"), " for all tasks")
                               )
                           ),
                           
                           div(class = "concept-box",
                               h4("Characteristics:"),
                               tags$ul(
                                 tags$li("Selects ", withMathJax("$M$"), " observations per iteration (one per task)"),
                                 tags$li("Each task's selection is independent"),
                                 tags$li("May visit different regions for different tasks"),
                                 tags$li("Simple to implement"),
                                 tags$li("Suitable for weakly correlated tasks")
                               )
                           )
                    ),
                    column(6,
                           h4("Algorithm 2: Multi-Task Version"),
                           div(class = "concept-box",
                               tags$ol(
                                 tags$li(strong("Compute joint variance:"), " Evaluate MOGP predictive covariance for all tasks jointly"),
                                 tags$li(strong("Compute entropy contribution:"), 
                                         withMathJax("$$I(x_j|X_I) = \\log\\left(\\frac{|C(X_o,X_o|X_{I+1})|}{|C(X_o,X_o|X_I)|}\\right)$$")),
                                 tags$li(strong("Select point:"), 
                                         withMathJax("$$x_j^* = \\arg\\min_{x_j \\in \\mathbb{R}^D \\times \\mathbb{R} \\setminus X_I} I(x_j|X_I, X_o)$$")),
                                 tags$li(strong("Navigate to point:"), " Use LQR to guide system toward ", withMathJax("$x_j^*$")),
                                 tags$li(strong("Add observation:"), " Add observed state-action pair ", withMathJax("$(x_{j|LQR}, y_{j|LQR})$"), 
                                         " actually reached by LQR"),
                                 tags$li(strong("Update periodically:"), " Optimize ", withMathJax("$\\Theta$"), " after adding several points"),
                                 tags$li(strong("Repeat:"), " Until LQR can accurately reach target points")
                               )
                           ),
                           
                           div(class = "concept-box",
                               h4("Characteristics:"),
                               tags$ul(
                                 tags$li("Selects ", strong("one"), " observation per iteration benefiting all tasks"),
                                 tags$li("Exploits task correlations through MOGP covariance"),
                                 tags$li("More data-efficient than Algorithm 1"),
                                 tags$li("Computational cost: ", withMathJax("$\\mathcal{O}(M^2N^2)$"), " per iteration"),
                                 tags$li("Best for strongly correlated tasks")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 6, title = "Multi-Task Covariance Strategy", status = "primary", solidHeader = TRUE,
                    p(class = "description-text",
                      "The multi-task version computes entropy reduction using the full MOGP covariance matrix, which captures correlations 
                      across all tasks. An observation informative for one task may also be informative for correlated tasks due to the 
                      cross-covariance structure. This joint selection strategy is more efficient than selecting independently per task, 
                      potentially reducing the total number of required observations significantly."
                    ),
                    
                    div(class = "math-formula",
                        h4("Predicted Covariance After Observations:"),
                        withMathJax("$$C(X_o, X_o|X_I) = C(X_o, X_o) - C(X_o, X_I)C(X_I, X_I)^{-1}C(X_o, X_I)^T$$"),
                        p("This is the posterior covariance at unobserved locations ", withMathJax("$X_o$"), " given observed locations ", 
                          withMathJax("$X_I$"), ", incorporating all task correlations through the MOGP structure."),
                        
                        h4("Entropy Contribution:"),
                        withMathJax("$$I(x_j|X_I) = \\log\\left(\\frac{|C(X_o,X_o|X_{I+1})|}{|C(X_o,X_o|X_I)|}\\right)$$"),
                        p("The log-ratio of determinants measures how much adding ", withMathJax("$x_j$"), " reduces overall uncertainty. 
                          Determinants summarize the 'volume' of uncertainty—smaller determinants indicate less uncertainty."),
                        
                        h4("Optimal Observation:"),
                        withMathJax("$$x_j = \\arg\\min_{x_j \\in \\mathbb{R}^D \\times \\mathbb{R} \\setminus X_I} \\log\\left(\\frac{|C(X_o,X_o|X_{I+1})|}{|C(X_o,X_o|X_I)|}\\right)$$"),
                        p("Minimize posterior entropy (equivalently, maximize information gain) considering all tasks jointly.")
                    ),
                    
                    div(class = "concept-box",
                        h4("Why Log-Determinants?"),
                        p("For multivariate Gaussians, entropy is:"),
                        withMathJax("$$H = \\frac{1}{2}\\log|2\\pi e \\Sigma|$$"),
                        p("Thus entropy differences reduce to log-determinant ratios. The determinant captures the 'generalized variance' 
                          of the multivariate distribution. A small determinant means the distribution is concentrated; large means spread out.")
                    )
                ),
                
                box(width = 6, title = "Simultaneous Sampling and Control", status = "danger", solidHeader = TRUE,
                    p(class = "description-text",
                      "A key practical challenge is that the most informative state-action pair may not be reachable in a single control 
                      step, especially when the dynamics model is still being learned. The strategy addresses this by using LQR to navigate 
                      toward informative targets while continuously adding observations along the trajectory. This simultaneous sampling 
                      and control approach enables on-line learning during normal operation rather than requiring separate exploration phases."
                    ),
                    
                    div(class = "concept-box",
                        h4("Key Insight:"),
                        p("Rather than requiring the system to reach exactly ", withMathJax("$x_j^*$"), " (which may be impossible with 
                          imperfect model), we:"),
                        tags$ol(
                          tags$li("Compute most informative target ", withMathJax("$x_j^*$")),
                          tags$li("Use LQR to move toward ", withMathJax("$x_j^*$")),
                          tags$li("Add the ", strong("actually observed"), " state-action pair ", withMathJax("$x_{j|LQR}$"), " to training set"),
                          tags$li("Recompute new informative target ", withMathJax("$x_{j+1}^*$"), " with updated model"),
                          tags$li("Repeat until model is sufficiently accurate")
                        )
                    ),
                    
                    div(class = "math-formula",
                        h4("Observed vs. Target:"),
                        withMathJax("$$x_{j|LQR} = \\text{state reached by LQR trying to reach } x_j^*$$"),
                        p("Due to model inaccuracy, ", withMathJax("$x_{j|LQR} \\neq x_j^*$"), " initially. As model improves, ", 
                          withMathJax("$x_{j|LQR} \\to x_j^*$"), "."),
                        
                        h4("Termination Criterion:"),
                        p("Learning stops when LQR consistently reaches targets accurately:"),
                        withMathJax("$$||x_{j|LQR} - x_j^*|| < \\delta$$"),
                        p("This indicates the model is accurate enough for reliable control.")
                    ),
                    
                    div(class = "concept-box",
                        h4("Advantages:"),
                        tags$ul(
                          tags$li(strong("On-line learning:"), " No separate exploration phase needed"),
                          tags$li(strong("Safe:"), " LQR respects control constraints and dynamics"),
                          tags$li(strong("Efficient:"), " Collects data while moving toward goals"),
                          tags$li(strong("Adaptive:"), " Continuously updates targets as model improves"),
                          tags$li(strong("Practical:"), " Handles real-world constraints and imperfections")
                        )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Control Stability Analysis", status = "info", solidHeader = TRUE,
                    p(class = "description-text",
                      "A critical concern in adaptive control is stability: will the coupled system of learning and control converge to 
                      the desired state, or could the interaction between imperfect model learning and control actions lead to instability? 
                      The principle of separation from classical control theory provides the foundation for analyzing stability. The key 
                      insight is that system stability can be guaranteed by ensuring two independent conditions: (1) the state observer 
                      (GP model) converges to accurate predictions, and (2) the controller (LQR) is stable for the true system. When both 
                      conditions hold, the overall system converges."
                    ),
                    
                    column(6,
                           h4("Principle of Separation:"),
                           div(class = "concept-box",
                               p("System stability ensured by designing independently:"),
                               tags$ul(
                                 tags$li(strong("Steady state observer:"), " GP model with decreasing prediction error"),
                                 tags$li(strong("Steady deterministic controller:"), " LQR with appropriate gains")
                               ),
                               p("If both components are stable, the closed-loop system is stable.")
                           ),
                           
                           div(class = "math-formula",
                               h4("Control Error:"),
                               withMathJax("$$e_t = s^* - s_t|a_t$$"),
                               p("Deviation of actual state ", withMathJax("$s_t$"), " from target ", withMathJax("$s^*$"), 
                                 " after applying action ", withMathJax("$a_t$"), "."),
                               
                               h4("Prediction Error:"),
                               withMathJax("$$\\hat{e}_t = s_t|a_t - \\hat{s}_t|v_t$$"),
                               p("Difference between actual next state ", withMathJax("$s_t|a_t$"), " and GP predicted state ", 
                                 withMathJax("$\\hat{s}_t$"), " with variance ", withMathJax("$v_t$"), "."),
                               withMathJax("$$\\hat{s}_t|v_t = s_{t-1}|a_{t-1} + f_*|v_t$$"),
                               p("where ", withMathJax("$f_*|v_t$"), " is the GP predicted state change.")
                           )
                    ),
                    column(6,
                           div(class = "math-formula",
                               h4("Convergence Conditions:"),
                               
                               h5("1. Observer Convergence:"),
                               withMathJax("$$\\lim_{t\\to\\infty} \\hat{e}_t = 0$$"),
                               p("Prediction error must decrease to zero asymptotically. Information gain strategy ensures this by 
                                 reducing model uncertainty (variance) to acceptable levels."),
                               
                               h5("2. Controller Stability:"),
                               withMathJax("$$\\hat{e}_t \\ll e_t$$"),
                               p("Prediction error must be much smaller than control error. When GP predictions are accurate, LQR 
                                 can effectively reduce ", withMathJax("$e_t$"), "."),
                               
                               h5("3. System Convergence:"),
                               withMathJax("$$\\lim_{t\\to\\infty} e_t \\approx 0$$"),
                               p("If conditions 1 and 2 hold, control error converges to zero (or small neighborhood around ", 
                                 withMathJax("$s^*$"), ").")
                           ),
                           
                           div(class = "concept-box",
                               h4("Practical Implications:"),
                               tags$ul(
                                 tags$li("Initial learning phase may show poor control"),
                                 tags$li("As ", withMathJax("$v_t \\to 0$"), " (variance decreases), control improves"),
                                 tags$li("Information gain threshold ", withMathJax("$\\epsilon$"), " determines final performance"),
                                 tags$li("Smaller ", withMathJax("$\\epsilon$"), " = better control but more training data"),
                                 tags$li("Safety margins can be incorporated through conservative variance thresholds")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Cart-Pole Experiment Results", status = "success", solidHeader = TRUE,
                    p(class = "description-text",
                      "The cart-pole system provides an excellent testbed for validating the information gain strategy. This classic 
                      under-actuated system has complex, non-linear dynamics: a pole balanced on a cart that can only be controlled by 
                      applying horizontal forces to the cart. The challenge is to learn the four-dimensional dynamics (cart position, 
                      cart velocity, pole angle, angular velocity) from observations and use this learned model for control. The system 
                      exhibits strong non-linearities, especially near the upright configuration where small angle changes dramatically 
                      affect dynamics. The experiment compared MOGP models trained with: (1) information gain sampling selecting high-variance 
                      points, versus (2) equally-spaced sampling on a uniform grid in state-action space."
                    ),
                    
                    column(4,
                           h4("System Definition:"),
                           div(class = "concept-box",
                               p(strong("State (4 dimensions):")),
                               tags$ul(
                                 tags$li("Cart horizontal position ", withMathJax("$(h)$")),
                                 tags$li("Cart horizontal velocity ", withMathJax("$(\\dot{h})$")),
                                 tags$li("Pole angle from vertical ", withMathJax("$(\\theta)$")),
                                 tags$li("Pole angular velocity ", withMathJax("$(\\dot{\\theta})$"))
                               ),
                               
                               p(strong("Action (1 dimension):"), " Horizontal force on cart ", withMathJax("$(a)$")),
                               
                               p(strong("Input space:"), " 5D: ", withMathJax("$\\{h, \\dot{h}, \\theta, \\dot{\\theta}, a\\}$")),
                               
                               p(strong("Output space:"), " 4D state changes (4 tasks)")
                           )
                    ),
                    column(4,
                           h4("State-Action Range:"),
                           div(class = "math-formula",
                               withMathJax("$$-5cm \\leq h \\leq 5cm$$"),
                               withMathJax("$$-1cm/s \\leq \\dot{h} \\leq 1cm/s$$"),
                               withMathJax("$$-\\pi \\leq \\theta \\leq \\pi$$"),
                               withMathJax("$$-1rad/s \\leq \\dot{\\theta} \\leq 1rad/s$$"),
                               withMathJax("$$-1N \\leq a \\leq 1N$$"),
                               p("Sampling rate: 10 Hz (", withMathJax("$\\Delta t = 0.1s$"), ")")
                           ),
                           
                           div(class = "concept-box",
                               h4("Experimental Protocol:"),
                               tags$ul(
                                 tags$li("Initial training: same for both methods"),
                                 tags$li("Iterative addition: 4 points per iteration"),
                                 tags$li("Total points: up to 55"),
                                 tags$li("Repetitions: 15 independent runs"),
                                 tags$li("Metric: RMSE on fixed test set")
                               )
                           )
                    ),
                    column(4,
                           h4("Key Results:"),
                           div(class = "concept-box",
                               tags$ul(
                                 tags$li(strong("Cart position:"), " Info gain significantly better after 30 points"),
                                 tags$li(strong("Pole angle:"), " Similar improvement pattern"),
                                 tags$li(strong("Cart velocity:"), " Comparable performance initially, info gain better later"),
                                 tags$li(strong("Angular velocity:"), " Info gain substantially outperforms throughout"),
                                 tags$li(strong("Overall:"), " Info gain requires fewer points for same accuracy")
                               )
                           ),
                           
                           div(class = "concept-box",
                               h4("Why Information Gain Wins:"),
                               tags$ul(
                                 tags$li("Focuses on non-linear regions"),
                                 tags$li("Avoids redundant observations"),
                                 tags$li("Adapts to complexity of dynamics"),
                                 tags$li("Especially effective for angular dimensions")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Advantages Over Other Methods", status = "warning", solidHeader = TRUE,
                    p(class = "description-text",
                      "The proposed information gain strategy with MOGP dynamics learning offers several advantages over alternative 
                      approaches to adaptive control. This section compares against recent methods from the literature to contextualize 
                      the contributions. Each comparison highlights specific aspects where the GP-based approach with active learning 
                      provides theoretical or practical benefits."
                    ),
                    
                    column(4,
                           h4("vs. Fuzzy Logic/PI Controllers:"),
                           div(class = "concept-box",
                               p(strong("Fixed Structure Limitation:")),
                               p(class = "description-text",
                                 "Methods like fuzzy logic systems and PI controllers with least-squares tuning assume a fixed structure 
                                 with parameters to estimate. The structure (fuzzy rules, basis functions) must be specified by a designer. 
                                 If the structure is inadequate, no amount of parameter tuning will achieve good performance."),
                               
                               p(strong("GP Advantage:")),
                               tags$ul(
                                 tags$li("No fixed structure—GP places distributions over function spaces"),
                                 tags$li("Complexity adapts automatically to data"),
                                 tags$li("Does not search for parameters of basis functions"),
                                 tags$li("Discovers relationships directly from observations"),
                                 tags$li("Occam's Razor prevents overfitting without manual tuning")
                               )
                           )
                    ),
                    column(4,
                           h4("vs. Model-Free Adaptive:"),
                           div(class = "concept-box",
                               p(strong("Pseudo-Partial-Derivative (PPD) Complexity:")),
                               p(class = "description-text",
                                 "Model-free adaptive control computes pseudo-partial-derivatives to linearize non-linear systems. 
                                 This adds complexity and is sensitive to noisy measurements. PPD estimation requires specific assumptions 
                                 like Lipschitz continuity and requires at least two data point pairs to initialize."),
                               
                               p(strong("GP Advantage:")),
                               tags$ul(
                                 tags$li("Direct derivative estimation from GP mean function"),
                                 tags$li("Noise explicitly modeled per state dimension"),
                                 tags$li("Uncertainty quantification for derivatives"),
                                 tags$li("Smoothness assumptions encoded in kernel"),
                                 tags$li("Handles sensor noise naturally through Gaussian likelihood")
                               )
                           )
                    ),
                    column(4,
                           h4("vs. Periodic Adaptive:"),
                           div(class = "concept-box",
                               p(strong("Arbitrary Update Schedules:")),
                               p(class = "description-text",
                                 "Periodic adaptive control updates model parameters at fixed time intervals or after fixed numbers 
                                 of observations. The period length is arbitrary—too short wastes computation, too long allows performance 
                                 degradation. Lifting approaches use multiple periods but still require manual specification."),
                               
                               p(strong("GP Advantage:")),
                               tags$ul(
                                 tags$li("Update criterion based on model uncertainty (variance)"),
                                 tags$li("Information gain quantifies when updates are needed"),
                                 tags$li("Adapts naturally to rate of environment change"),
                                 tags$li("Threshold ", withMathJax("$\\epsilon$"), " has clear interpretation"),
                                 tags$li("No arbitrary period parameters to tune")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Additional Comparisons", status = "primary", solidHeader = TRUE,
                    column(4,
                           h4("vs. Weighted Statistical Learning:"),
                           div(class = "concept-box",
                               p(strong("Threshold-Based Inclusion:")),
                               p(class = "description-text",
                                 "Weighted statistical learning adds observations when likelihood exceeds a threshold based on weighted 
                                 Gaussian pairs. The threshold is somewhat arbitrary and does not directly relate to information content."),
                               
                               p(strong("GP Advantage:")),
                               tags$ul(
                                 tags$li("Information-theoretic threshold (entropy/variance)"),
                                 tags$li("Principled basis in Bayesian optimal design"),
                                 tags$li("Clear relationship to prediction quality"),
                                 tags$li("Threshold has units interpretable as uncertainty")
                               )
                           )
                    ),
                    column(4,
                           h4("vs. Receptive Field Methods:"),
                           div(class = "concept-box",
                               p(strong("Limited Validity Regions:")),
                               p(class = "description-text",
                                 "Locally weighted learning defines 'receptive fields' where models are valid. Restricts operation 
                                 to known regions, requiring extensive pre-exploration. Does not gracefully handle novel situations."),
                               
                               p(strong("GP Advantage:")),
                               tags$ul(
                                 tags$li("Global model with uncertainty quantification"),
                                 tags$li("Operates across full state-action space"),
                                 tags$li("Uncertainty indicates where predictions are unreliable"),
                                 tags$li("Active learning explores based on need, not arbitrary boundaries"),
                                 tags$li("Continuous improvement without hard region boundaries")
                               )
                           )
                    ),
                    column(4,
                           h4("vs. Evolving GPs:"),
                           div(class = "concept-box",
                               p(strong("Fixed Dataset Size:")),
                               p(class = "description-text",
                                 "Evolving GP approaches update models from streaming data but typically use fixed-size datasets 
                                 (inducing points). When capacity is reached, old points are discarded regardless of informativeness."),
                               
                               p(strong("Our Advantage:")),
                               tags$ul(
                                 tags$li("Dynamic stopping based on information gain"),
                                 tags$li("No arbitrary capacity limit"),
                                 tags$li("MOGP structure exploits task correlations"),
                                 tags$li("Multi-task joint variance for selection"),
                                 tags$li("Focuses on most informative regions naturally")
                               )
                           )
                    )
                )
              )
      ),
      
      # Chapter 5: Experiments
      tabItem(tabName = "ch5",
              fluidRow(
                box(width = 12, title = "Chapter 5: Experiments - Overview", status = "primary", solidHeader = TRUE,
                    div(class = "concept-box",
                        p(class = "description-text",
                          "This chapter presents comprehensive experimental validation of the active learning methodology on a real robotic 
                          platform—a small autonomous blimp. Unlike simulations where dynamics are known and conditions are controlled, real 
                          robot experiments face numerous challenges: sensor noise, actuator limitations, unpredictable disturbances, and 
                          time-varying dynamics. The blimp is particularly challenging due to continuous helium leakage (changing buoyancy), 
                          susceptibility to wind, non-linear aerodynamics, and coupled dynamics across multiple degrees of freedom. The experimental 
                          campaign follows a systematic progression from simple to complex scenarios. First, single degree-of-freedom experiments 
                          establish baseline performance with movement constrained to either vertical (height control) or rotational (heading control). 
                          These experiments compare information gain sampling against random sampling, demonstrating superior prediction accuracy 
                          and control performance. Second, unconstrained 3D navigation experiments test the full methodology under realistic operating 
                          conditions including lifting/dropping buoyancy, external disturbances, and simultaneous multi-dimensional control. Third, 
                          trajectory tracking experiments represent the ultimate validation: the blimp must follow paths defined by ground markings 
                          using visual feedback while maintaining constant height—a task requiring accurate models, robust control, and real-time 
                          adaptation. The experiments conclusively demonstrate that: (1) information gain sampling learns better models with less 
                          data than random sampling, (2) MOGP task correlation improves predictions beyond independent GPs, (3) the learned models 
                          enable effective LQR control despite actuator limitations and disturbances, and (4) continuous relearning handles time-varying 
                          dynamics from helium leakage. The successful completion of a closed-loop path following task—where the blimp returns to 
                          its starting point—represents a significant achievement validating the entire active Bayesian learning framework for 
                          real-world autonomous operation."
                        )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Robotic Blimp Platform", status = "primary", solidHeader = TRUE,
                    p(class = "description-text",
                      "The experimental platform is a small indoor autonomous blimp designed for navigation in constrained environments. 
                      The blimp's physical characteristics present significant control challenges: large moment of inertia makes orientation 
                      changes slow, low mass makes it sensitive to air currents, and the helium-filled envelope continuously leaks affecting 
                      buoyancy over time. These properties make the blimp an excellent testbed for adaptive learning—the dynamics are 
                      genuinely time-varying and affected by disturbances that cannot be directly measured."
                    ),
                    
                    column(4,
                           div(class = "concept-box",
                               h4("Physical Specifications:"),
                               tags$ul(
                                 tags$li(strong("Length:"), " 1.8 metres"),
                                 tags$li(strong("Diameter:"), " 1.0 metre"),
                                 tags$li(strong("Envelope:"), " Helium-filled (subject to leakage)"),
                                 tags$li(strong("Gondola:"), " Contains sensors, computer, and propellers"),
                                 tags$li(strong("Navigation board:"), " Attached at front"),
                                 tags$li(strong("Rear fin:"), " Mounted with yaw propeller")
                               )
                           ),
                           
                           div(class = "concept-box",
                               h4("Actuation:"),
                               tags$ul(
                                 tags$li(strong("2 coupled propellers:"), " In gondola, electrically coupled (same speed)"),
                                 tags$li(strong("Servo-controlled shaft:"), " Rotates gondola propellers for vertical/horizontal thrust"),
                                 tags$li(strong("1 rear propeller:"), " Provides yaw torque for heading control"),
                                 tags$li(strong("Control frequency:"), " Updates every 0.4s (2.5 Hz)")
                               )
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h4("Sensing Equipment:"),
                               
                               p(strong("RM-M3 Navigation Board:")),
                               tags$ul(
                                 tags$li("Compass for heading measurement"),
                                 tags$li("Gyroscope for yaw rate"),
                                 tags$li("Updates: continuous")
                               ),
                               
                               p(strong("LV-EZ1 Ultrasonic Sensor:")),
                               tags$ul(
                                 tags$li("Range: 6.5 metres"),
                                 tags$li("Effective period: 0.1s (10 Hz)"),
                                 tags$li("Purpose: height measurement")
                               ),
                               
                               p(strong("SRV Blackfin Camera:")),
                               tags$ul(
                                 tags$li("Resolution: 640×480 pixels"),
                                 tags$li("Frame rate: 5 fps"),
                                 tags$li("Purpose: visual feedback for height/heading")
                               )
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h4("Computing Architecture:"),
                               tags$ul(
                                 tags$li(strong("On-board:"), " Microcomputer for sensor preprocessing"),
                                 tags$li(strong("Ground station:"), " 2.3 GHz CPU for GP learning and LQR control"),
                                 tags$li(strong("Communication:"), " WiFi ad-hoc network"),
                                 tags$li(strong("Latency:"), " ~0.4s total loop time")
                               )
                           ),
                           
                           div(class = "concept-box",
                               h4("Operational Challenges:"),
                               tags$ul(
                                 tags$li("Continuous helium leakage → time-varying buoyancy"),
                                 tags$li("Susceptible to indoor air currents"),
                                 tags$li("Non-linear aerodynamic effects"),
                                 tags$li("Actuator saturation limits"),
                                 tags$li("Sensor noise and delays"),
                                 tags$li("Coupled multi-dimensional dynamics")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Experiment 1: Vertical Dynamics Learning", status = "info", solidHeader = TRUE,
                    p(class = "description-text",
                      "The first experiment establishes baseline performance for learning a subset of the blimp dynamics with movement 
                      constrained to a single degree of freedom. The blimp is physically tethered to allow only vertical motion, eliminating 
                      horizontal drift and rotation. This simplification isolates the vertical dynamics (height and vertical velocity) for 
                      focused study of the learning methodology. The two-dimensional state space is much easier to visualize and analyze 
                      than the full 6D dynamics, making it ideal for demonstrating the effectiveness of information gain sampling versus 
                      random sampling. The vertical dynamics exhibit non-linearities due to aerodynamic drag (proportional to velocity squared) 
                      and time-varying buoyancy from helium leakage."
                    ),
                    
                    column(4,
                           h4("Experimental Setup:"),
                           div(class = "concept-box",
                               p(strong("Constraints:")),
                               tags$ul(
                                 tags$li("Movement: vertical only"),
                                 tags$li("Horizontal position: fixed by tether"),
                                 tags$li("Orientation: fixed (no rotation)")
                               ),
                               
                               div(class = "math-formula",
                                   h4("State-Action Space:"),
                                   withMathJax("$$-1m \\leq h \\leq 1m$$"),
                                   withMathJax("$$-0.6m/s \\leq \\dot{h} \\leq 0.6m/s$$"),
                                   withMathJax("$$-1 \\leq a_h \\leq 1$$"),
                                   p("Physical range: 2.2m height, 0.7 m/s max speed"),
                                   p("Motor speed: -40 to +40 rev/s (scaled to action range)")
                               )
                           )
                    ),
                    column(4,
                           h4("Learning Comparison:"),
                           div(class = "concept-box",
                               p(strong("Two MOGP models trained:")),
                               tags$ol(
                                 tags$li(strong("Information gain:"), " Points selected by Algorithm 1 (high variance)"),
                                 tags$li(strong("Random sampling:"), " Points selected uniformly at random")
                               ),
                               
                               p(strong("Procedure:")),
                               tags$ul(
                                 tags$li("Both start with same initial dataset"),
                                 tags$li("Iteratively add points (4 per iteration)"),
                                 tags$li("Retrain MOGP after each addition"),
                                 tags$li("Evaluate prediction error on fixed test set"),
                                 tags$li("Repeat 10 times for statistical significance")
                               ),
                               
                               p("Control period: ", withMathJax("$\\Delta t = 0.4s$"))
                           )
                    ),
                    column(4,
                           h4("Results:"),
                           div(class = "concept-box",
                               p(strong("Height Prediction:")),
                               tags$ul(
                                 tags$li("Info gain: significant improvement after 30 points"),
                                 tags$li("Random: slower error reduction"),
                                 tags$li("Final RMSE: ~0.1m (info) vs ~0.3m (random)")
                               ),
                               
                               p(strong("Velocity Prediction:")),
                               tags$ul(
                                 tags$li("Info gain: clear advantage after 40 points"),
                                 tags$li("Random: higher error throughout"),
                                 tags$li("Final RMSE: ~0.02m/s (info) vs ~0.08m/s (random)")
                               ),
                               
                               p(strong("Conclusion:"), " Information gain sampling learns more accurate 
                                 models with fewer observations by focusing on high-uncertainty regions.")
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Experiment 2: Heading Dynamics Learning", status = "warning", solidHeader = TRUE,
                    p(class = "description-text",
                      "The second single-DOF experiment focuses on rotational dynamics—learning how the blimp's heading (orientation) 
                      responds to yaw control from the rear propeller. The blimp is constrained against horizontal and vertical motion, 
                      allowing only rotation about the vertical axis. Heading control is particularly challenging due to the large moment 
                      of inertia (slow response) and susceptibility to disturbances. Small air currents can easily deflect the lightweight 
                      blimp from its desired orientation. This experiment demonstrates both learning effectiveness and control robustness 
                      against disturbances."
                    ),
                    
                    column(3,
                           h4("Setup:"),
                           div(class = "concept-box",
                               p(strong("Constraints:")),
                               tags$ul(
                                 tags$li("Movement: rotation only"),
                                 tags$li("Position: fixed (horizontal & vertical)"),
                                 tags$li("Actuation: rear propeller only")
                               ),
                               
                               div(class = "math-formula",
                                   h4("State-Action Space:"),
                                   withMathJax("$$-\\frac{\\pi}{2} \\leq \\psi \\leq \\frac{\\pi}{2}$$"),
                                   withMathJax("$$-1rad/s \\leq \\dot{\\psi} \\leq 1rad/s$$"),
                                   withMathJax("$$-1 \\leq a_\\psi \\leq 1$$"),
                                   p("Rear propeller provides torque ", withMathJax("$\\tau_Z$"))
                               )
                           )
                    ),
                    column(3,
                           h4("Challenges:"),
                           div(class = "concept-box",
                               tags$ul(
                                 tags$li(strong("High inertia:"), " Slow angular response"),
                                 tags$li(strong("Orientation instability:"), " Small disturbances have large effects"),
                                 tags$li(strong("Wind sensitivity:"), " Air currents easily deflect blimp"),
                                 tags$li(strong("Unmeasurable parameters:"), " Cannot directly sense moment of inertia"),
                                 tags$li(strong("Non-linear aerodynamics:"), " Drag varies with angular velocity")
                               )
                           )
                    ),
                    column(3,
                           h4("Control Task:"),
                           div(class = "concept-box",
                               p(strong("Objective:"), " Stabilize at target heading despite disturbances"),
                               
                               div(class = "math-formula",
                                   p("Target state:"),
                                   withMathJax("$$\\psi^* = 0 rad$$"),
                                   withMathJax("$$\\dot{\\psi}^* = 0 rad/s$$"),
                                   p("(perpendicular to reference wall)")
                               ),
                               
                               p(strong("Comparison:")),
                               tags$ul(
                                 tags$li("MOGP with information gain"),
                                 tags$li("MOGP with random sampling"),
                                 tags$li("Both trained with 100 points"),
                                 tags$li("Control horizon: 50 actions")
                               )
                           )
                    ),
                    column(3,
                           h4("Results:"),
                           div(class = "concept-box",
                               p(strong("Information Gain Model:")),
                               tags$ul(
                                 tags$li("Stabilized after ~40 actions"),
                                 tags$li("Smoother control actions"),
                                 tags$li("Less oscillation"),
                                 tags$li("Better disturbance rejection")
                               ),
                               
                               p(strong("Random Sampling Model:")),
                               tags$ul(
                                 tags$li("Still oscillating at 50 actions"),
                                 tags$li("More aggressive actions"),
                                 tags$li("Higher overshoot"),
                                 tags$li("Poorer robustness")
                               ),
                               
                               p(strong("Conclusion:"), " Info gain provides more reliable derivatives, 
                                 enabling smoother, more robust control.")
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Experiment 3: 3D Navigation (Lifting Buoyancy)", status = "success", solidHeader = TRUE,
                    p(class = "description-text",
                      "Having validated the learning methodology on single-DOF scenarios, the next experiments remove all physical constraints, 
                      allowing the blimp free movement in 3D space. This represents a major increase in complexity: the system must now coordinate 
                      control across multiple coupled dimensions simultaneously. The blimp tends to have either lifting buoyancy (over-inflated, 
                      pulls upward) or dropping buoyancy (under-inflated, pulls downward) due to helium leakage. This experiment tests the first 
                      scenario with lifting buoyancy, requiring continuous downward thrust to maintain target height while executing a U-turn 
                      maneuver."
                    ),
                    
                    column(3,
                           h4("State-Action Space:"),
                           div(class = "math-formula",
                               withMathJax("$$-1.5m \\leq h \\leq 1.5m$$"),
                               withMathJax("$$-0.4m/s \\leq \\dot{h} \\leq 0.4m/s$$"),
                               withMathJax("$$-\\pi \\leq \\psi \\leq \\pi$$"),
                               withMathJax("$$-1rad/s \\leq \\dot{\\psi} \\leq 1rad/s$$"),
                               withMathJax("$$-1 \\leq a_h \\leq 1$$"),
                               withMathJax("$$-1 \\leq a_\\psi \\leq 1$$")
                           ),
                           
                           div(class = "concept-box",
                               p(strong("Actuation:")),
                               tags$ul(
                                 tags$li(withMathJax("$a_h$: "), "gondola propeller shaft angle (vertical thrust)"),
                                 tags$li(withMathJax("$a_\\psi$: "), "rear propeller speed (yaw torque)"),
                                 tags$li("Forward speed: constant (horizontal thrust component)")
                               )
                           )
                    ),
                    column(3,
                           h4("Target State:"),
                           div(class = "concept-box",
                               div(class = "math-formula",
                                   withMathJax("$$h^* = 1.5m$$"),
                                   withMathJax("$$\\dot{h}^* = 0$$"),
                                   withMathJax("$$\\psi^* = 0$$"),
                                   withMathJax("$$\\dot{\\psi}^* = 0$$")
                               )
                           ),
                           
                           h4("Initial Deviation:"),
                           div(class = "concept-box",
                               div(class = "math-formula",
                                   withMathJax("$$h = 0.23m$$"),
                                   withMathJax("$$\\psi = 2.85rad \\approx 163°$$")
                               ),
                               p("Blimp starts below target and facing almost opposite direction"),
                               p(strong("Challenge:"), " Over-inflated (lifting buoyancy) tends to rise")
                           )
                    ),
                    column(3,
                           h4("Control Performance:"),
                           div(class = "concept-box",
                               p(strong("Height Control:")),
                               tags$ul(
                                 tags$li("30 actions ", withMathJax("$a_h = -1$"), " to pull down"),
                                 tags$li("Max height reached at action 17"),
                                 tags$li("Stabilized after 60 actions"),
                                 tags$li("Compensated lifting force successfully")
                               ),
                               
                               p(strong("Heading Control:")),
                               tags$ul(
                                 tags$li("U-turn executed in ~20 actions"),
                                 tags$li("Stabilized after ~40 actions"),
                                 tags$li("Simultaneous with height control"),
                                 tags$li("Heading converges faster than height")
                               )
                           )
                    ),
                    column(3,
                           h4("Key Observations:"),
                           div(class = "concept-box",
                               tags$ul(
                                 tags$li(strong("Coupling:"), " Height and heading controlled simultaneously without interference"),
                                 tags$li(strong("Robustness:"), " Compensated strong lifting buoyancy"),
                                 tags$li(strong("Model accuracy:"), " LQR based on learned MOGP selected appropriate actions"),
                                 tags$li(strong("Convergence:"), " Both dimensions reached target despite initial large errors"),
                                 tags$li(strong("Relearning:"), " Dynamics model updated before experiment to account for current buoyancy")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Experiment 4: 3D Navigation (Dropping Buoyancy)", status = "danger", solidHeader = TRUE,
                    p(class = "description-text",
                      "This experiment tests the opposite buoyancy scenario: after prolonged helium leakage, the blimp is under-inflated 
                      and tends to sink. Without continuous upward thrust, the blimp would descend to the ground. This represents a different 
                      control challenge requiring sustained energy expenditure. Additionally, intentional disturbances are introduced mid-experiment 
                      to test the controller's ability to recover and maintain stability. The combination of dropping buoyancy and external 
                      perturbations provides a rigorous test of the learned model's accuracy and the controller's robustness."
                    ),
                    
                    column(4,
                           h4("Scenario:"),
                           div(class = "concept-box",
                               tags$ul(
                                 tags$li(strong("Buoyancy:"), " Dropping (under-inflated)"),
                                 tags$li(strong("Disturbances:"), " Intentional deflections at actions 16 and 90"),
                                 tags$li(strong("Horizon:"), " 120 control actions"),
                                 tags$li(strong("Challenge:"), " Maintain height and recover from perturbations")
                               ),
                               
                               div(class = "math-formula",
                                   h4("Target:"),
                                   withMathJax("$$h^* = 2.3m, \\dot{h}^* = 0$$"),
                                   withMathJax("$$\\psi^* = 0, \\dot{\\psi}^* = 0$$")
                               )
                           )
                    ),
                    column(4,
                           h4("Disturbances:"),
                           div(class = "concept-box",
                               p(strong("Disturbance 1 (action 16):")),
                               tags$ul(
                                 tags$li("Deflection to ", withMathJax("$\\psi = 1.6rad$")),
                                 tags$li("Recovery: ~64 actions"),
                                 tags$li("Stabilized at action 80")
                               ),
                               
                               p(strong("Disturbance 2 (action 90):")),
                               tags$ul(
                                 tags$li("Deflection to ", withMathJax("$\\psi = 1.1rad$")),
                                 tags$li("Recovery: ~30 actions"),
                                 tags$li("Stabilized at action 120")
                               ),
                               
                               p(strong("Height Behavior:")),
                               tags$ul(
                                 tags$li("Initial: -1m below target"),
                                 tags$li("Min: -1.9m below target (action 36)"),
                                 tags$li("Recovered after 110 actions")
                               )
                           )
                    ),
                    column(4,
                           h4("Results:"),
                           div(class = "concept-box",
                               tags$ul(
                                 tags$li(strong("Disturbance rejection:"), " Recovered from both perturbations"),
                                 tags$li(strong("Buoyancy compensation:"), " Prevented sinking despite under-inflation"),
                                 tags$li(strong("Simultaneous control:"), " Height and heading controlled concurrently"),
                                 tags$li(strong("Model validity:"), " Learned model captured complex coupled dynamics"),
                                 tags$li(strong("Robustness:"), " Maintained performance under adverse conditions")
                               )
                           ),
                           
                           div(class = "concept-box",
                               h4("Significance:"),
                               p(class = "description-text",
                                 "This experiment demonstrates that the active learning methodology enables robust autonomous operation 
                                 under challenging real-world conditions. The system continuously adapts to time-varying dynamics (changing 
                                 buoyancy) and recovers from unexpected disturbances, validating the core thesis contributions.")
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Experiment 5: Path Tracking Around Truck", status = "primary", solidHeader = TRUE,
                    p(class = "description-text",
                      "Having demonstrated robust stabilization, the next challenge is trajectory tracking: following a predefined path 
                      while maintaining constant height. The path consists of straight line segments marked on the ground, detected using 
                      the on-board camera. This adds visual servoing to the control problem—the blimp must process camera images in real-time 
                      to extract heading references from line orientations. The 6-segment path navigates around a truck obstacle, requiring 
                      multiple heading changes while maintaining stable height control. Image processing time constrains the control frequency, 
                      making this a challenging real-time control task."
                    ),
                    
                    column(3,
                           h4("Task Description:"),
                           div(class = "concept-box",
                               tags$ul(
                                 tags$li(strong("Path:"), " 6 straight line segments"),
                                 tags$li(strong("Obstacle:"), " Truck (navigate around)"),
                                 tags$li(strong("Height:"), " Constant 1.5m"),
                                 tags$li(strong("Guidance:"), " Visual feedback from camera"),
                                 tags$li(strong("Processing:"), " On-board image segmentation"),
                                 tags$li(strong("Horizon:"), " 200 control actions")
                               )
                           ),
                           
                           div(class = "math-formula",
                               h4("Target State:"),
                               withMathJax("$$h^* = 1.5m, \\dot{h}^* = 0$$"),
                               withMathJax("$$\\psi^* = \\phi_{trajectory}$$"),
                               p("where ", withMathJax("$\\phi_{trajectory}$"), " is the orientation of the currently detected line segment")
                           )
                    ),
                    column(3,
                           h4("Technical Details:"),
                           div(class = "concept-box",
                               tags$ul(
                                 tags$li(strong("Camera:"), " 5 fps, 640×480 pixels"),
                                 tags$li(strong("Processing time:"), " Depends on segment complexity"),
                                 tags$li(strong("Control period:"), withMathJax("$\\Delta t = 0.4s$"), " maintained"),
                                 tags$li(strong("Line detection:"), " Image segmentation algorithm"),
                                 tags$li(strong("Heading update:"), " Each new segment triggers new ", withMathJax("$\\psi^*$"))
                               )
                           ),
                           
                           div(class = "concept-box",
                               h4("Why Straight Segments?"),
                               p(class = "description-text",
                                 "Straight lines minimize image processing complexity, ensuring the 0.4s control period can be maintained. 
                                 Complex curves would require longer processing, increasing latency and degrading control quality.")
                           )
                    ),
                    column(3,
                           h4("Performance:"),
                           div(class = "concept-box",
                               p(strong("Height Control:")),
                               tags$ul(
                                 tags$li("Initial: -0.47m below target"),
                                 tags$li("Stabilized from action 70 onward"),
                                 tags$li("Slight damped oscillation"),
                                 tags$li("Most actions positive (compensating helium loss)")
                               ),
                               
                               p(strong("Heading Control:")),
                               tags$ul(
                                 tags$li("5 heading reference transitions"),
                                 tags$li("Follows path segments accurately"),
                                 tags$li("Small deviations from ideal path"),
                                 tags$li("Smooth heading changes between segments")
                               )
                           )
                    ),
                    column(3,
                           h4("Key Achievements:"),
                           div(class = "concept-box",
                               tags$ul(
                                 tags$li(strong("Visual servoing:"), " Successfully integrated camera feedback"),
                                 tags$li(strong("Multi-segment:"), " Handled 6 sequential heading changes"),
                                 tags$li(strong("Obstacle avoidance:"), " Navigated around truck"),
                                 tags$li(strong("Height maintenance:"), " Stable despite helium leakage"),
                                 tags$li(strong("Real-time:"), " Maintained control frequency despite image processing"),
                                 tags$li(strong("Path accuracy:"), " Small deviations from desired trajectory")
                               )
                           ),
                           
                           div(class = "concept-box",
                               h4("Significance:"),
                               p("Demonstrates integration of perception, learning, and control in a unified autonomous system.")
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Experiment 6: Closed Loop Pattern", status = "info", solidHeader = TRUE,
                    p(class = "description-text",
                      "The ultimate validation of the active learning methodology is the closed-loop path following task. The blimp must 
                      track a circular pattern defined by 12 straight line segments, eventually returning to its starting position. Closing 
                      the loop is extremely challenging due to accumulated errors from: imperfect line following, height variations, wind 
                      disturbances, and time-varying dynamics. Success requires that the learned model accurately captures the system behavior 
                      across the entire state-action space encountered during the maneuver. This experiment represents the most ambitious 
                      control task in the thesis, testing all aspects of the methodology simultaneously."
                    ),
                    
                    column(3,
                           h4("Challenge:"),
                           div(class = "concept-box",
                               p(strong("Most ambitious control task")),
                               tags$ul(
                                 tags$li("Track circular loop pattern"),
                                 tags$li("12 straight line segments"),
                                 tags$li("Maintain constant height throughout"),
                                 tags$li("140 control actions"),
                                 tags$li("Return to starting point (close loop)")
                               ),
                               
                               div(class = "math-formula",
                                   h4("Success Criterion:"),
                                   p("Starting position ≈ Final position"),
                                   withMathJax("$$||s_{final} - s_{start}|| < \\delta$$")
                               )
                           )
                    ),
                    column(3,
                           h4("Complexity Factors:"),
                           div(class = "concept-box",
                               tags$ul(
                                 tags$li(strong("Limited actuators:"), " Cannot move sideways, only forward with rotation"),
                                 tags$li(strong("Continuous heading changes:"), " 12 transitions in 140 actions"),
                                 tags$li(strong("Inertia effects:"), " Cannot stop/turn instantly"),
                                 tags$li(strong("Height control:"), " Simultaneous with trajectory following"),
                                 tags$li(strong("Error accumulation:"), " Small deviations compound over loop"),
                                 tags$li(strong("Time-varying dynamics:"), " Helium leakage continues")
                               )
                           )
                    ),
                    column(3,
                           h4("Performance:"),
                           div(class = "concept-box",
                               p(strong("Height:")),
                               tags$ul(
                                 tags$li("Initial deviation: -0.47m"),
                                 tags$li("Stabilizes while following loop"),
                                 tags$li("Maintains ", withMathJax("$h^* = 1.5m$"), " throughout")
                               ),
                               
                               p(strong("Heading:")),
                               tags$ul(
                                 tags$li("12 heading peaks in plot"),
                                 tags$li("Corresponds to 12 line segments"),
                                 tags$li("Smooth transitions between segments"),
                                 tags$li("Follows circular pattern accurately")
                               ),
                               
                               p(strong("Loop Closure:")),
                               tags$ul(
                                 tags$li(strong("SUCCESS:"), " Loop closed"),
                                 tags$li("Returned to starting region"),
                                 tags$li("Small final position error")
                               )
                           )
                    ),
                    column(3,
                           h4("Significance:"),
                           div(class = "concept-box",
                               p(strong("Demonstrates:")),
                               tags$ul(
                                 tags$li(strong("Model accuracy:"), " Captures dynamics well enough to close loop"),
                                 tags$li(strong("LQR effectiveness:"), " Generates appropriate actions throughout"),
                                 tags$li(strong("Robustness:"), " Handles actuator constraints and disturbances"),
                                 tags$li(strong("Full autonomy:"), " Complete task without human intervention"),
                                 tags$li(strong("Integration:"), " Perception, learning, control work together seamlessly")
                               )
                           ),
                           
                           div(class = "concept-box",
                               h4("Conclusion:"),
                               p(class = "description-text",
                                 strong("The successful completion of the closed-loop task validates the entire active Bayesian learning 
                                 framework for real-world autonomous robotic operation. This represents a major achievement demonstrating 
                                 that information gain-based active learning combined with MOGP dynamics modeling enables robust navigation 
                                 in uncertain, time-varying environments."))
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Summary of Experimental Results", status = "success", solidHeader = TRUE,
                    p(class = "description-text",
                      "The comprehensive experimental campaign on the robotic blimp validates all major contributions of this thesis. 
                      The progression from constrained single-DOF to unconstrained 3D navigation to complex trajectory tracking demonstrates 
                      the methodology's scalability and robustness. Each experiment added complexity while maintaining consistent performance, 
                      showing that the active learning approach generalizes well across different scenarios. The key insight is that principled 
                      information-theoretic observation selection combined with non-parametric Bayesian modeling enables effective learning 
                      from limited data, which translates to robust autonomous control even under challenging conditions."
                    ),
                    
                    column(4,
                           valueBox(
                             "6 Experiments",
                             "Successfully Completed",
                             icon = icon("check-circle"),
                             color = "green"
                           ),
                           div(class = "concept-box",
                               h4("Experimental Progression:"),
                               tags$ol(
                                 tags$li("Vertical dynamics (constrained)"),
                                 tags$li("Heading dynamics (constrained)"),
                                 tags$li("3D lifting buoyancy"),
                                 tags$li("3D dropping buoyancy + disturbances"),
                                 tags$li("Open path tracking"),
                                 tags$li("Closed loop tracking")
                               )
                           )
                    ),
                    column(4,
                           valueBox(
                             "Real Robot",
                             "Challenging UAV Platform",
                             icon = icon("robot"),
                             color = "blue"
                           ),
                           div(class = "concept-box",
                               h4("Platform Challenges:"),
                               tags$ul(
                                 tags$li("Continuous helium leakage"),
                                 tags$li("Susceptible to wind"),
                                 tags$li("Non-linear aerodynamics"),
                                 tags$li("Actuator saturation"),
                                 tags$li("Sensor noise and delays"),
                                 tags$li("Coupled multi-dimensional dynamics")
                               )
                           )
                    ),
                    column(4,
                           valueBox(
                             "Full 3D Control",
                             "Autonomous Navigation",
                             icon = icon("cube"),
                             color = "purple"
                           ),
                           div(class = "concept-box",
                               h4("Validated Capabilities:"),
                               tags$ul(
                                 tags$li("Real-time learning and control"),
                                 tags$li("Disturbance rejection"),
                                 tags$li("Time-varying dynamics adaptation"),
                                 tags$li("Visual servoing integration"),
                                 tags$li("Complex trajectory following"),
                                 tags$li("Loop closure (ultimate test)")
                               )
                           )
                    )
                )
              )
      ),
      
      # Chapter 6: Conclusions
      tabItem(tabName = "ch6",
              fluidRow(
                box(width = 12, title = "Chapter 6: Conclusions - Overview", status = "primary", solidHeader = TRUE,
                    div(class = "concept-box",
                        p(class = "description-text",
                          "This chapter synthesizes the contributions and outcomes of the thesis, providing a comprehensive summary of the 
                          active Bayesian learning methodology developed for robotic systems dynamics. The research addressed a fundamental 
                          challenge in autonomous robotics: how to learn accurate dynamical models efficiently while operating in uncertain, 
                          time-varying environments. Five major contributions are summarized: (1) Dynamics modeling with Gaussian Processes, 
                          establishing GPs as effective non-parametric models for robotic systems with principled uncertainty quantification 
                          and automatic complexity control. (2) Multi-task learning with Multiple Output Gaussian Processes, exploiting 
                          inter-task correlations to improve learning efficiency and prediction accuracy. (3) Adaptive predictive control 
                          integrating learned GP models with Linear Quadratic Regulators, enabling real-time model updates as dynamics change. 
                          (4) Information gain strategy for active data selection, using entropy-based metrics to identify the most informative 
                          observations and dramatically reducing required training data. (5) UAV adaptive navigation, validating the complete 
                          methodology through extensive experiments on a real robotic blimp, culminating in successful closed-loop trajectory 
                          tracking. The experimental results demonstrate that information gain sampling outperforms random and uniform sampling, 
                          MOGPs improve upon independent GPs, and the integrated system achieves robust autonomous operation despite actuator 
                          limitations, sensor noise, disturbances, and time-varying dynamics. Looking forward, the chapter identifies opportunities 
                          for extending the methodology to higher-dimensional systems through task clustering, implementing active data management 
                          with selective deletion of outdated observations, and applying the framework to complex UAV path planning for outdoor 
                          surveillance. The work establishes information-theoretic principles combined with non-parametric Bayesian learning as 
                          a principled, effective framework for adaptive control of complex robotic systems, with broad applicability across 
                          aerial, ground, and manipulator robotics domains."
                        )
                    )
                )
              ),
              
              fluidRow(
                box(width = 6, title = "1. Dynamics Modelling with GPs", status = "info", solidHeader = TRUE,
                    div(class = "concept-box",
                        h4("Core Contribution:"),
                        p(class = "description-text",
                          "Established Gaussian Processes as effective non-parametric models for learning robotic system dynamics directly 
                          from observed state transitions. Unlike parametric approaches requiring fixed functional forms, GPs place distributions 
                          over function spaces, allowing automatic adaptation to problem complexity. The GP framework naturally balances model 
                          fit against complexity through the marginal likelihood, embodying Occam's Razor to prevent overfitting."
                        )
                    ),
                    
                    div(class = "math-formula",
                        h4("Key Formulation:"),
                        withMathJax("$$f \\sim \\mathcal{GP}(m(x), c(x,x'))$$"),
                        withMathJax("$$y_t = (s_t - s_{t-1})|\\{s_{t-1}, a_{t-1}\\}$$"),
                        p("Modeling state changes as functions of state-action pairs")
                    ),
                    
                    div(class = "concept-box",
                        h4("Advantages Demonstrated:"),
                        tags$ul(
                          tags$li("Captures non-linearities without explicit specification"),
                          tags$li("Quantifies uncertainty—critical for safe control"),
                          tags$li("Handles sensor noise through Gaussian likelihood"),
                          tags$li("No manual tuning of basis functions"),
                          tags$li("Complexity adapts to data automatically")
                        )
                    )
                ),
                
                box(width = 6, title = "2. Multi-Task Learning", status = "warning", solidHeader = TRUE,
                    div(class = "concept-box",
                        h4("Core Contribution:"),
                        p(class = "description-text",
                          "Developed Multiple Output Gaussian Processes (MOGPs) to exploit correlations between different state dimensions 
                          (tasks). By modeling task dependencies through cross-covariance functions, MOGPs share information across related 
                          dimensions, improving prediction accuracy with less data per task. This is especially valuable for high-dimensional 
                          systems where independent modeling would require prohibitive amounts of data."
                        )
                    ),
                    
                    div(class = "math-formula",
                        withMathJax("$$C_M = (c_{y_{ij}}C_{x_{ij}})_{ij}$$"),
                        p("Block-structured covariance matrix capturing auto- and cross-correlations")
                    ),
                    
                    div(class = "concept-box",
                        h4("Validated Benefits:"),
                        tags$ul(
                          tags$li("Lower prediction error than independent GPs"),
                          tags$li("Faster learning from same amount of data"),
                          tags$li("Better control performance (smoother actions)"),
                          tags$li("Natural modeling of physically coupled dynamics"),
                          tags$li("Demonstrated on blimp: height-velocity correlation")
                        )
                    )
                )
              ),
              
              fluidRow(
                box(width = 6, title = "3. Adaptive Predictive Control", status = "success", solidHeader = TRUE,
                    div(class = "concept-box",
                        h4("Core Contribution:"),
                        p(class = "description-text",
                          "Integrated GP-based dynamics models with Linear Quadratic Regulator (LQR) control to enable adaptive operation 
                          under time-varying conditions. The LQR computes optimal actions based on system derivatives estimated from the GP 
                          mean function. As new data are collected, the GP model updates, allowing the controller to adapt to changing dynamics. 
                          This contrasts with conventional model-based predictive control assuming time-invariant dynamics."
                        )
                    ),
                    
                    div(class = "math-formula",
                        withMathJax("$$\\hat{A}_t = \\frac{\\partial \\bar{f}}{\\partial s}\\bigg|_{s_t,a_t}, \\quad \\hat{B}_t = \\frac{\\partial \\bar{f}}{\\partial a}\\bigg|_{s_t,a_t}$$"),
                        p("Jacobians from GP enable LQR for non-linear systems")
                    ),
                    
                    div(class = "concept-box",
                        h4("Stability Analysis:"),
                        p("Principle of separation ensures convergence:"),
                        tags$ul(
                          tags$li("Steady observer: GP variance → 0"),
                          tags$li("Steady controller: LQR minimizes cost"),
                          tags$li(withMathJax("System convergence: $\\lim_{t\\to\\infty} e_t \\approx 0$"))
                        )
                    ),
                    
                    div(class = "concept-box",
                        h4("Demonstrated Capabilities:"),
                        tags$ul(
                          tags$li("Real-time model updates during operation"),
                          tags$li("Adaptation to helium leakage (buoyancy changes)"),
                          tags$li("Recovery from external disturbances"),
                          tags$li("Simultaneous multi-dimensional control"),
                          tags$li("Maintained performance across diverse scenarios")
                        )
                    )
                ),
                
                box(width = 6, title = "4. Information Gain Strategy", status = "danger", solidHeader = TRUE,
                    div(class = "concept-box",
                        h4("Core Contribution:"),
                        p(class = "description-text",
                          "Developed an information gain-based strategy for active selection of training observations, dramatically reducing 
                          data requirements while maintaining or improving model accuracy. The strategy identifies state-action pairs with 
                          high predictive variance (entropy), which are most informative for reducing model uncertainty. This principled approach 
                          outperforms heuristic methods like uniform sampling or distance-based selection, especially in high dimensions."
                        )
                    ),
                    
                    div(class = "math-formula",
                        h4("Single-Task Version:"),
                        withMathJax("$$x_j = \\arg\\max_{x_j} \\Delta_j = \\arg\\max_{x_j} \\log\\left(1 + \\frac{v_j}{\\sigma^2}\\right)$$"),
                        
                        h4("Multi-Task Version:"),
                        withMathJax("$$x_j = \\arg\\min_{x_j} \\log\\left(\\frac{|C(X_o,X_o|X_{I+1})|}{|C(X_o,X_o|X_I)|}\\right)$$")
                    ),
                    
                    div(class = "concept-box",
                        h4("Validated Advantages:"),
                        tags$ul(
                          tags$li("Fewer observations for same accuracy"),
                          tags$li("Faster error reduction than random/uniform sampling"),
                          tags$li("Adapts to function complexity automatically"),
                          tags$li("Theoretically grounded (information theory)"),
                          tags$li("Reduces computational cost (smaller datasets)"),
                          tags$li("Enables real-time control (less prediction time)")
                        )
                    ),
                    
                    div(class = "concept-box",
                        h4("Key Innovation:"),
                        p(strong("Simultaneous sampling and control:"), " LQR guides system toward informative targets while learning, 
                          enabling on-line exploration during normal operation rather than requiring separate exploration phases.")
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "5. UAV Adaptive Navigation", status = "primary", solidHeader = TRUE,
                    p(class = "description-text",
                      "Comprehensive experimental validation on a real robotic blimp demonstrated the practical effectiveness of the complete 
                      methodology. Six progressively challenging experiments tested all aspects: learning accuracy, control performance, disturbance 
                      rejection, time-varying adaptation, and trajectory tracking. The successful completion of the closed-loop path following 
                      task represents a major achievement, validating that the active Bayesian learning framework enables robust autonomous 
                      navigation in uncertain, time-varying environments."
                    ),
                    
                    column(3,
                           div(class = "concept-box",
                               h4("Platform Characteristics:"),
                               tags$ul(
                                 tags$li("Length: 1.8m, Diameter: 1.0m"),
                                 tags$li("Continuous helium leakage"),
                                 tags$li("Susceptible to air currents"),
                                 tags$li("Limited actuators (3 propellers)"),
                                 tags$li("Sensor noise and delays"),
                                 tags$li("Non-linear coupled dynamics")
                               )
                           )
                    ),
                    column(3,
                           div(class = "concept-box",
                               h4("Experimental Progression:"),
                               tags$ol(
                                 tags$li(strong("Single DOF:"), " Vertical & heading (constrained)"),
                                 tags$li(strong("3D stabilization:"), " Lifting & dropping buoyancy"),
                                 tags$li(strong("Disturbance rejection:"), " External perturbations"),
                                 tags$li(strong("Path tracking:"), " Open trajectory"),
                                 tags$li(strong("Loop closure:"), " Ultimate validation")
                               )
                           )
                    ),
                    column(3,
                           div(class = "concept-box",
                               h4("Key Results:"),
                               tags$ul(
                                 tags$li("Info gain > random sampling (prediction)"),
                                 tags$li("Info gain > random sampling (control)"),
                                 tags$li("MOGP > independent GPs"),
                                 tags$li("Stable control despite disturbances"),
                                 tags$li("Adapted to time-varying dynamics"),
                                 tags$li("Successfully closed loop path")
                               )
                           )
                    ),
                    column(3,
                           div(class = "concept-box",
                               h4("Significance:"),
                               tags$ul(
                                 tags$li(strong("Real-world validation"), " of all contributions"),
                                 tags$li(strong("Challenging platform"), " demonstrates robustness"),
                                 tags$li(strong("Progressive complexity"), " shows scalability"),
                                 tags$li(strong("Closed-loop success"), " ultimate proof of concept"),
                                 tags$li(strong("Practical deployment"), " ready for applications")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Key Achievements Summary", status = "success", solidHeader = TRUE,
                    column(3,
                           valueBox(
                             "O(N³) → O(N²)",
                             "Reduced computational cost through data selection",
                             icon = icon("tachometer-alt"),
                             color = "green"
                           ),
                           div(class = "concept-box",
                               p("Information gain strategy reduces training dataset size while maintaining accuracy, directly 
                                 decreasing computational complexity of GP inference.")
                           )
                    ),
                    column(3,
                           valueBox(
                             "Real-time",
                             "Adaptive model updates during operation",
                             icon = icon("sync-alt"),
                             color = "blue"
                           ),
                           div(class = "concept-box",
                               p("Continuous learning and control enable adaptation to time-varying dynamics (e.g., helium leakage) 
                                 without interrupting operation.")
                           )
                    ),
                    column(3,
                           valueBox(
                             "Non-linear",
                             "Complex dynamics learning without ODEs",
                             icon = icon("project-diagram"),
                             color = "purple"
                           ),
                           div(class = "concept-box",
                               p("GP-based approach captures non-linearities, interactions, and unmodeled effects directly from data, 
                                 without requiring explicit physical models.")
                           )
                    ),
                    column(3,
                           valueBox(
                             "Autonomous",
                             "Full 3D navigation with loop closure",
                             icon = icon("drone"),
                             color = "red"
                           ),
                           div(class = "concept-box",
                               p("Complete autonomous operation demonstrated: perception, learning, control integrated seamlessly 
                                 to achieve complex navigation tasks.")
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Future Work", status = "info", solidHeader = TRUE,
                    p(class = "description-text",
                      "While this thesis established a comprehensive framework for active Bayesian learning of robotic dynamics, several 
                      directions offer opportunities for extending and enhancing the methodology. These extensions address scalability to 
                      more complex systems, efficiency improvements through data management, and application to broader problem domains."
                    ),
                    
                    column(6,
                           h4("Extension to Higher Dimensions:"),
                           div(class = "concept-box",
                               p(class = "description-text",
                                 "For systems with many degrees of freedom (e.g., humanoid robots, multi-agent systems), the number of tasks 
                                 grows large, making a single MOGP computationally prohibitive. Task clustering offers a solution:"),
                               
                               tags$ol(
                                 tags$li(strong("Define correlation metrics:"), " Measure dependencies between task pairs using mutual information 
                                         or correlation coefficients from initial data"),
                                 tags$li(strong("Cluster strongly correlated tasks:"), " Group tasks with high correlation into clusters"),
                                 tags$li(strong("Train separate MOGPs per cluster:"), " Each cluster modeled by its own MOGP with specialized 
                                         covariance structure"),
                                 tags$li(strong("Coordinate across clusters:"), " Higher-level coordination ensures consistency between cluster 
                                         predictions")
                               ),
                               
                               p(strong("Benefits:"), " Reduces per-MOGP size from O(M³N³) to O(K³C³N³) where K is cluster size and C is number 
                                 of clusters with K << M.")
                           )
                    ),
                    column(6,
                           h4("Active Data Management:"),
                           div(class = "concept-box",
                               p(class = "description-text",
                                 "For long-term operation, training datasets grow unbounded, eventually becoming computationally intractable. 
                                 Active deletion of outdated observations can maintain fixed computational cost:"),
                               
                               tags$ol(
                                 tags$li(strong("Age-based criteria:"), " Remove observations beyond a time horizon—older than recent dynamics"),
                                 tags$li(strong("Accuracy-based criteria:"), " Identify state-action regions where predictions are no longer accurate 
                                         (high test error)"),
                                 tags$li(strong("Redundancy-based criteria:"), " Remove observations in densely sampled regions where nearby points 
                                         provide similar information"),
                                 tags$li(strong("Trigger resampling:"), " When deletions occur, information gain strategy identifies new informative 
                                         observations to replace them")
                               ),
                               
                               p(strong("Benefits:"), " Maintains constant dataset size and computational cost while adapting to evolving dynamics.")
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Potential Applications", status = "warning", solidHeader = TRUE,
                    p(class = "description-text",
                      "The active Bayesian learning framework developed in this thesis has broad applicability across robotics domains. 
                      The key enabling properties—data efficiency, adaptation to time-varying dynamics, and uncertainty quantification—address 
                      common challenges in autonomous systems operating in unpredictable environments."
                    ),
                    
                    column(4,
                           div(class = "concept-box",
                               h4("Aerial Robotics:"),
                               tags$ul(
                                 tags$li(strong("Outdoor surveillance:"), " Adapt to varying wind conditions, battery drainage, payload changes"),
                                 tags$li(strong("Complex UAV path planning:"), " Low-level control for executing planned trajectories robustly"),
                                 tags$li(strong("Multi-vehicle coordination:"), " Learn interaction dynamics between vehicles"),
                                 tags$li(strong("Adaptive wind compensation:"), " Model and compensate for persistent wind patterns"),
                                 tags$li(strong("Fault tolerance:"), " Detect and adapt to actuator failures or degradation")
                               ),
                               
                               p(strong("Key advantage:"), " Real-time adaptation crucial for outdoor operation where conditions change rapidly.")
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h4("Ground Vehicles:"),
                               tags$ul(
                                 tags$li(strong("Terrain adaptation:"), " Learn traction characteristics of different surfaces (mud, gravel, ice)"),
                                 tags$li(strong("Traction control:"), " Optimize torque distribution based on learned wheel-terrain interactions"),
                                 tags$li(strong("Autonomous navigation:"), " Handle changing conditions (weather, wear, load) without recalibration"),
                                 tags$li(strong("Variable load handling:"), " Adapt to different cargo weights affecting dynamics"),
                                 tags$li(strong("Off-road operation:"), " Learn complex terrain interactions not captured in simple models")
                               ),
                               
                               p(strong("Key advantage:"), " Terrain properties often unmeasurable but learnable through interaction.")
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h4("Manipulators:"),
                               tags$ul(
                                 tags$li(strong("Friction compensation:"), " Learn joint friction varying with wear, temperature, load"),
                                 tags$li(strong("Variable load dynamics:"), " Adapt to handled objects with unknown properties"),
                                 tags$li(strong("Precise trajectory control:"), " Improve tracking accuracy through learned corrections"),
                                 tags$li(strong("Multi-joint coordination:"), " Exploit task correlation for coupled joint dynamics"),
                                 tags$li(strong("Contact tasks:"), " Learn interaction forces during assembly, polishing, etc.")
                               ),
                               
                               p(strong("Key advantage:"), " Internal quantities (friction, compliance) difficult to measure but critical for performance.")
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Final Remarks", status = "success", solidHeader = TRUE,
                    div(class = "concept-box",
                        h4("Main Contribution:"),
                        p(strong(style = "font-size: 18px;",
                                 "An effective active Bayesian learning methodology for selecting the most informative dynamics data and 
                          building reliable predictive models that exploit inter-task dependencies.")),
                        
                        tags$hr(),
                        
                        h4("Theoretical Foundations:"),
                        p(class = "description-text",
                          "The work integrates three fundamental areas: (1) Bayesian non-parametric modeling (Gaussian Processes) providing 
                          flexible function approximation with principled uncertainty, (2) Information theory (Shannon entropy, information gain) 
                          enabling principled observation selection, and (3) Optimal control (LQR, separation principle) ensuring stable convergence. 
                          This integration creates a coherent framework where each component reinforces the others: GP uncertainty guides active 
                          sampling, efficient sampling reduces GP computational cost, and accurate GP models enable effective control."
                        ),
                        
                        tags$hr(),
                        
                        h4("Practical Impact:"),
                        tags$ul(
                          tags$li(strong("Data efficiency:"), " Learn accurate models with fewer observations than alternative methods"),
                          tags$li(strong("Computational tractability:"), " Reduced dataset size enables real-time control"),
                          tags$li(strong("Adaptation capability:"), " Continuous relearning handles time-varying dynamics"),
                          tags$li(strong("Robustness:"), " Uncertainty quantification enables safe operation under model mismatch"),
                          tags$li(strong("Generality:"), " Applicable across aerial, ground, and manipulator systems"),
                          tags$li(strong("Proven effectiveness:"), " Validated on real robot with challenging dynamics")
                        ),
                        
                        tags$hr(),
                        
                        h4("Broader Significance:"),
                        p(class = "description-text", style = "font-size: 16px;",
                          em("This work demonstrates that information-theoretic principles combined with non-parametric Bayesian learning 
                             provide a principled, effective framework for adaptive control of complex robotic systems. By explicitly accounting 
                             for uncertainty and intelligently selecting observations, autonomous systems can learn accurate models efficiently 
                             and maintain performance despite unpredictable environments. The successful closed-loop navigation experiment represents 
                             more than technical achievement—it validates a paradigm shift from assuming known, stationary dynamics to actively 
                             learning and adapting to the world as it is. This paradigm enables truly autonomous operation where robots continuously 
                             improve their understanding and capabilities through experience, moving closer to the goal of robust, reliable automation 
                             in uncontrolled real-world environments."))
                    )
                )
              )
      ),
      
      # References
      tabItem(tabName = "refs",
              fluidRow(
                box(width = 12, title = "References", status = "primary", solidHeader = TRUE,
                    p(class = "description-text",
                      "This thesis references 54 key publications spanning robotics, control theory, machine learning, statistics, and information 
                      theory. The references represent foundational works in Bayesian learning (Rasmussen & Williams, Neal), multi-task learning 
                      (Caruana, Bonilla et al.), information theory (Shannon, MacKay, Lindley), control systems (Anderson & Moore, Bryson), and 
                      their applications to robotics. The bibliography demonstrates the interdisciplinary nature of this research, drawing on 
                      established principles from multiple fields to create a novel integrated framework."
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Search and Filter References", status = "info", solidHeader = TRUE,
                    column(4,
                           textInput("search_refs", "Search:", placeholder = "Enter author, keyword, or topic..."),
                           p(style = "font-size: 12px; color: #666;", 
                             "Search across authors and categories (e.g., 'Rasmussen', 'Gaussian', 'Control')")
                    ),
                    column(4,
                           selectInput("filter_type", "Filter by Type:",
                                       choices = c("All", "Journal", "Conference", "Book", "Thesis", "Technical Report", "Book Chapter")),
                           p(style = "font-size: 12px; color: #666;", 
                             "Publication type: journals, conference proceedings, books, etc.")
                    ),
                    column(4,
                           selectInput("filter_year", "Filter by Year Range:",
                                       choices = c("All", "2011-2015", "2006-2010", "2000-2005", "1990-1999", "Before 1990")),
                           p(style = "font-size: 12px; color: #666;", 
                             "Publication date ranges for temporal analysis")
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Reference List", status = "success", solidHeader = TRUE,
                    p(class = "description-text",
                      "The table below contains all 54 references cited in this thesis. Use the search and filter tools above to find specific 
                      publications. Click column headers to sort. The table supports export to CSV and Excel for further analysis."
                    ),
                    DTOutput("references_table")
                )
              ),
              
              fluidRow(
                box(width = 6, title = "References by Category", status = "warning", solidHeader = TRUE,
                    p(class = "description-text",
                      "Distribution of references across research categories. The dominance of Machine Learning and Control reflects the 
                      interdisciplinary nature of this work, integrating learning techniques with control theory."
                    ),
                    plotlyOutput("refs_category_plot", height = "300px")
                ),
                
                box(width = 6, title = "Publications Timeline", status = "danger", solidHeader = TRUE,
                    p(class = "description-text",
                      "Temporal distribution of cited works. The concentration in 2000-2010 reflects the maturation of Gaussian Process 
                      methods and their application to robotics during this period."
                    ),
                    plotlyOutput("refs_timeline_plot", height = "300px")
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Key References by Topic", status = "primary", solidHeader = TRUE,
                    p(class = "description-text",
                      "Highlighted seminal works that provided foundational concepts for this thesis. Each category represents a core 
                      theoretical pillar of the methodology."
                    ),
                    
                    column(3,
                           div(class = "concept-box",
                               h4("Gaussian Processes:"),
                               tags$ul(
                                 tags$li(strong("[37] Rasmussen & Williams, 2006:"), " Definitive textbook on GP regression"),
                                 tags$li(strong("[30] Neal, 1996:"), " Bayesian learning for neural networks, foundations of GP theory"),
                                 tags$li(strong("[19] Ko et al., 2007:"), " GP-based reinforcement learning for blimp control"),
                                 tags$li(strong("[21] Kocijan et al., 2003:"), " Predictive control with GP models")
                               )
                           )
                    ),
                    column(3,
                           div(class = "concept-box",
                               h4("Multi-Task Learning:"),
                               tags$ul(
                                 tags$li(strong("[9] Caruana, 1997:"), " Foundational thesis on multi-task learning"),
                                 tags$li(strong("[5] Bonilla et al., 2008:"), " Multi-task GP prediction methods"),
                                 tags$li(strong("[10] Chai et al., 2008:"), " Multi-task GP for robot inverse dynamics"),
                                 tags$li(strong("[6] Boyle & Fren, 2005:"), " Multiple output GP regression theory")
                               )
                           )
                    ),
                    column(3,
                           div(class = "concept-box",
                               h4("Information Theory:"),
                               tags$ul(
                                 tags$li(strong("[28] MacKay, 2003:"), " Information theory, inference, and learning algorithms"),
                                 tags$li(strong("[44] Shannon, 1948:"), " Original paper on mathematical theory of communication"),
                                 tags$li(strong("[25] Lindley, 1956:"), " Bayesian optimal design and information measures"),
                                 tags$li(strong("[42] Sebastiani & Wynn, 1997:"), " Maximum entropy sampling principles")
                               )
                           )
                    ),
                    column(3,
                           div(class = "concept-box",
                               h4("Control Theory:"),
                               tags$ul(
                                 tags$li(strong("[2] Anderson & Moore, 1989:"), " Optimal control and LQR theory"),
                                 tags$li(strong("[7] Bryson, 2002:"), " Applied linear optimal control"),
                                 tags$li(strong("[33] Phillips & Nagle, 1995:"), " Digital control system analysis and design"),
                                 tags$li(strong("[29] Murray-Smith & Sbarbaro, 2002:"), " Nonlinear adaptive control with GPs")
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
      "Durrant-Whyte et al."
    ),
    Year = c(
      2008, 1989, 1994, 1994, 2008, 2005, 2002, 2010, 1997,
      2008, 1995, 2006, 2009, 2005, 2009, 1990, 2011, 1997,
      2007, 2005, 2003, 2010, 2003, 2002, 1956, 1972, 1992,
      2003, 2002, 1996, 2000, 2011, 1995, 1992, 2005, 2006,
      1981, 2009, 2003, 2000, 1997, 2000, 1948, 2010, 2007,
      1999, 2002, 2009, 2008, 1998, 2011, 2009, 2011, 2010
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
      "Journal"
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
      "Robotics", "Robotics"
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
        "1990-1999" = c(1990, 1999),
        "Before 1990" = c(0, 1989)
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
        colors = c('#3498db', '#00A39A', '#f39c12', '#e74c3c', '#9b59b6', '#2ecc71')
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
                           