library(shiny)
library(shinydashboard)
library(plotly)
library(DT)
library(ggplot2)

# UI
ui <- dashboardPage(
  dashboardHeader(title = "Bearing & Gear Fault Detection with Adaptive Features"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Introduction", tabName = "intro", icon = icon("home")),
      menuItem("Related Work", tabName = "related", icon = icon("book")),
      menuItem("Methodology", tabName = "methodology", icon = icon("cogs")),
      menuItem("Experiment Design", tabName = "design", icon = icon("flask")),
      menuItem("Results", tabName = "results", icon = icon("chart-bar")),
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
                          "This research presents a novel approach to adaptively select features for early fault detection in bearings 
                          and gears connected to brushless DC motors (BLDCMs). The work addresses a fundamental challenge in modern 
                          prognostics: determining the most relevant data for fault identification from the vast amount of multi-sensor 
                          measurements available through contemporary data acquisition systems. Bearings and gears are ubiquitous in 
                          industrial applications for mechanical energy conversion and transfer, yet their faults can lead to significant 
                          economic and safety consequences. The mechanical complexity of these components makes conventional signal 
                          analysis insufficient, necessitating empirical approaches based on statistical modeling and machine learning. 
                          A critical condition for enhancing reliability of early fault detection research is experiment repeatability. 
                          However, early fault detection can be more complex than initially apparent due to extensive sampling time 
                          requirements and equipment costs. While some public datasets exist (NASA IGBT, CMAPSS, PRONOSTIA), they often 
                          lack accurate descriptions of equipment degradation parameters, making replication of testing conditions difficult. 
                          This research builds a comprehensive benchmark dataset using a state-of-the-art testing platform that replicates 
                          fault conditions in BLDCMs, bearings, and gears under well-defined, time-varying conditions. The platform incorporates 
                          18 sensor channels including voltage, current, vibration (3-axis), temperature, sound pressure, torque, force, and 
                          speed measurements sampled at 10 kHz. An adaptive feature selection algorithm is proposed, combining minimum 
                          redundancy maximum relevance principles with Principal Component Analysis (PCA) and Support Vector Machine (SVM) 
                          classification. The algorithm optimizes feature selection through information correlation metrics, mutual information 
                          maximization, and dimensionality reduction. Experimental validation includes systematic testing of bearings with 
                          outer raceway faults and gears with missing teeth under controlled time-varying conditions (varying speed, load, 
                          and force). Results demonstrate classification accuracies exceeding 96% for gear faults and 99% for bearing faults, 
                          validating the adaptive feature selection approach for practical fault detection in industrial applications."
                        )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Research Motivation", status = "info", solidHeader = TRUE,
                    column(6,
                           div(class = "concept-box",
                               h4("Industrial Challenges:"),
                               tags$ul(
                                 tags$li(strong("Ubiquitous Components:"), " Bearings and gears widely used across industries for 
                                         mechanical energy conversion"),
                                 tags$li(strong("Safety Consequences:"), " Component failures lead to significant economic and safety 
                                         impacts"),
                                 tags$li(strong("Mechanical Complexity:"), " Complex dynamics make conventional signal analysis 
                                         insufficient"),
                                 tags$li(strong("Early Detection Need:"), " Require advanced warning before catastrophic failure"),
                                 tags$li(strong("Data Abundance:"), " Modern sensors generate vast amounts of data requiring intelligent 
                                         processing")
                               )
                           ),
                           
                           div(class = "highlight-box",
                               h4("Why BLDCMs?"),
                               p(class = "description-text",
                                 "Brushless DC motors selected due to ubiquitous industrial use and multi-phase similarity to AC 
                                 induction motors while maintaining safety compliance with Workplace Health and Safety (WHS) standards 
                                 through DC operation during testing."
                               )
                           )
                    ),
                    column(6,
                           div(class = "concept-box",
                               h4("Dataset Challenges:"),
                               tags$ul(
                                 tags$li(strong("Limited Public Data:"), " Few datasets available for bearing/gear prognostics research"),
                                 tags$li(strong("Insufficient Detail:"), " Existing datasets lack accurate degradation parameter descriptions"),
                                 tags$li(strong("Replication Difficulty:"), " Testing conditions not sufficiently detailed for reproduction"),
                                 tags$li(strong("Time & Cost:"), " Long sampling periods and expensive equipment requirements"),
                                 tags$li(strong("Multi-Sensor Gap:"), " Need comprehensive multi-modal measurement platforms")
                               )
                           ),
                           
                           div(class = "concept-box",
                               h4("Feature Selection Challenge:"),
                               p(class = "description-text",
                                 strong("Core Problem:"), " With high-fidelity multi-sensor platforms generating massive datasets, 
                                 determining the most relevant features for effective fault identification becomes a daunting task. 
                                 Need intelligent metrics to select useful features from extensive measurements."
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Research Contributions", status = "success", solidHeader = TRUE,
                    p(class = "description-text",
                      "This work makes three major contributions addressing critical gaps in bearing and gear fault detection for 
                      brushless DC motors, with validated experimental results demonstrating practical applicability."
                    )
                )
              ),
              
              fluidRow(
                column(4,
                       box(width = 12, title = "Multi-Sensor Testing Platform", status = "success", solidHeader = TRUE,
                           div(style = "text-align: center; padding: 20px;",
                               icon("industry", style = "font-size: 48px; color: #00A39A;"),
                               h4(style = "margin-top: 10px; color: #008A82;", "18 Measurement Channels")
                           ),
                           div(class = "concept-box",
                               p(class = "description-text",
                                 "State-of-the-art testing platform for inducing controlled faults on BLDCMs with bearings and 
                                 gears. Comprehensive sensor suite: voltage (9 channels), current (3), vibration (3-axis), temperature, 
                                 sound, torque, force, and speed. Platform enables full control of time-varying conditions: rotating 
                                 speed, electronic load, and perpendicular force. Non-invasive design allows rapid component replacement. 
                                 Sampling at 10 kHz per channel with intelligent filtering based on component characteristics."
                               )
                           )
                       )
                ),
                column(4,
                       box(width = 12, title = "Adaptive Feature Selection Algorithm", status = "info", solidHeader = TRUE,
                           div(style = "text-align: center; padding: 20px;",
                               icon("brain", style = "font-size: 48px; color: #3498db;"),
                               h4(style = "margin-top: 10px; color: #2980b9;", "Intelligent Feature Extraction")
                           ),
                           div(class = "concept-box",
                               p(class = "description-text",
                                 "Novel algorithm combining minimum redundancy maximum relevance (mRMR) principle with Principal 
                                 Component Analysis for dimensionality reduction. Maximizes mutual information between features and 
                                 fault classes while minimizing inter-feature redundancy. Information score metric determines optimal 
                                 number of PCA components. Extracts statistical features (mean, variance, skewness, kurtosis, moments, 
                                 RMS) and wavelet components. Achieves superior fault classification with reduced training data."
                               )
                           )
                       )
                ),
                column(4,
                       box(width = 12, title = "Benchmark Dataset", status = "warning", solidHeader = TRUE,
                           div(style = "text-align: center; padding: 20px;",
                               icon("database", style = "font-size: 48px; color: #9b59b6;"),
                               h4(style = "margin-top: 10px; color: #8e44ad;", "Public Multi-Sensor Data")
                           ),
                           div(class = "concept-box",
                               p(class = "description-text",
                                 "Comprehensive benchmark dataset with detailed fault scenarios for bearings and gears under time-varying 
                                 conditions. Includes precise degradation parameters enabling replication: bearing with 0.3mm outer raceway 
                                 hole, gears with 1 and 2 missing teeth. Well-documented testing conditions: speed ranges, force profiles, 
                                 load variations. Multiple test configurations for statistical validation. Publicly available to advance 
                                 prognostics research community."
                               )
                           )
                       )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Problem Formulation", status = "primary", solidHeader = TRUE,
                    column(6,
                           h4("Fault Detection Challenge:"),
                           div(class = "concept-box",
                               p(class = "description-text",
                                 "Given multi-sensor measurements ", withMathJax("$\\mathbf{X}$"), " from BLDCM operation with bearing 
                                 or gear, determine fault class ", withMathJax("$c \\in \\{\\text{healthy}, \\text{faulty}\\}$"), " 
                                 through optimal feature selection."
                               ),
                               
                               h5("Key Variables:"),
                               tags$ul(
                                 tags$li(withMathJax("$\\mathbf{X}$"), " - raw multi-sensor measurements (18 channels)"),
                                 tags$li(withMathJax("$\\mathbf{F}$"), " - extracted feature set from ", withMathJax("$\\mathbf{X}$")),
                                 tags$li(withMathJax("$\\mathbf{F}^*$"), " - selected optimal feature subset"),
                                 tags$li(withMathJax("$\\mathbf{P}$"), " - PCA-reduced feature space"),
                                 tags$li(withMathJax("$c$"), " - target fault class (binary classification)")
                               )
                           )
                    ),
                    column(6,
                           h4("Objectives:"),
                           div(class = "concept-box",
                               tags$ol(
                                 tags$li(strong("Feature Relevance:"), " Select features maximally correlated with fault classes"),
                                 tags$li(strong("Redundancy Minimization:"), " Eliminate redundant features providing similar information"),
                                 tags$li(strong("Dimensionality Reduction:"), " Reduce training data size while maintaining classification 
                                         accuracy"),
                                 tags$li(strong("Multi-Sensor Integration:"), " Effectively combine information from diverse sensor types"),
                                 tags$li(strong("Generalization:"), " Ensure selected features work across time-varying conditions")
                               )
                           ),
                           
                           div(class = "highlight-box",
                               p(strong("Success Metrics:"), " Classification accuracy >90%, reduced feature dimensionality, 
                                 validated across multiple fault scenarios (bearing raceway, gear teeth), robust to time-varying 
                                 conditions (speed, load, force).")
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
                          "This section reviews the state-of-the-art in bearing and gear fault detection, feature extraction methodologies, 
                          and classification techniques. Bearing-related faults are identified as the most frequent causes of BLDCM failures, 
                          motivating extensive research in this area. Knowledge-based models for fault detection have traditionally fed 
                          classifiers with fixed sets of features derived from measurements. Statistical features such as kurtosis, skewness, 
                          standard deviation, and absolute mean have been extracted from vibration signals to identify inner race faults. 
                          Sound and vibration data have been normalized to feed Support Vector Machines for fault identification. Time-variant 
                          conditions have been addressed through phase voltage and current measurements correlated with multi-sensor data 
                          including vibrations and noise. Filtered signals containing spectral and statistical features have been used to 
                          identify faulty versus non-faulty bearings in various datasets. For gear faults, torque and load measurements 
                          complement conventional vibration analysis, with features like RMS, kurtosis, and peak values extracted for 
                          classification. Wavelets have been widely applied for noise reduction and gear vibration frequency selection to 
                          feed artificial neural network classifiers. Early detection of tooth cracks in planetary gears has been demonstrated 
                          through wavelet-based approaches. High classification accuracy has been achieved when higher-order statistical moments 
                          are included in training data. In feature selection methodologies, active learning has been implemented through 
                          reinforcement learning agents to determine weighting estimators for equipment health management. Health indices 
                          based on dominant features have been proposed for predictive maintenance decision-making. Principal Component 
                          Analysis has been performed to extract features and reduce data dimensionality for improved classifier performance. 
                          Mahalanobis distance has been used to select features from candidate sets by minimizing redundancies while maximizing 
                          information content. However, feature selection based specifically on multi-sensor measurements to obtain relevant 
                          features for both bearing and gear faults simultaneously has not been previously addressed, representing the gap 
                          this research fills through adaptive feature selection on comprehensive multi-sensor platform data."
                        )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Bearing Fault Detection Approaches", status = "info", solidHeader = TRUE,
                    column(6,
                           div(class = "concept-box",
                               h4("Statistical Feature Extraction:"),
                               
                               h5("Common Features Used:"),
                               tags$ul(
                                 tags$li(strong("Kurtosis:"), " Measure of tail heaviness, sensitive to impulsive faults"),
                                 tags$li(strong("Skewness:"), " Asymmetry of distribution, indicates imbalance"),
                                 tags$li(strong("Standard Deviation:"), " Variability measure, increases with degradation"),
                                 tags$li(strong("Absolute Mean:"), " Average magnitude, reflects overall energy level"),
                                 tags$li(strong("RMS:"), " Root mean square, energy indicator"),
                                 tags$li(strong("Peak Value:"), " Maximum amplitude, detects impact events")
                               ),
                               
                               p(class = "description-text",
                                 "These features modeled from vibration signals to identify inner race faults, similar to faults 
                                 detected in this work."
                               )
                           )
                    ),
                    column(6,
                           div(class = "concept-box",
                               h4("Signal Processing Techniques:"),
                               
                               h5("Sound & Vibration Analysis:"),
                               p(class = "description-text",
                                 "Sound and vibration data normalized to feed SVM for fault identification. Multi-sensor correlation 
                                 between phase voltage, current, vibrations, and noise under time-variant conditions."
                               ),
                               
                               h5("Filtered Signal Approach:"),
                               p(class = "description-text",
                                 "Set of filtered signals containing spectral and statistical features built to identify faulty from 
                                 non-faulty bearings. Frequency content analysis reveals bearing-specific fault signatures."
                               )
                           ),
                           
                           div(class = "highlight-box",
                               h5("Frequency Range for Bearings:"),
                               p(class = "description-text",
                                 "Rolling bearing energy content concentrated between 2 kHz and 10 kHz. This research applies 
                                 bandpass filtering in this range for vibration channels to capture bearing-specific fault signatures."
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Gear Fault Detection Approaches", status = "success", solidHeader = TRUE,
                    column(4,
                           div(class = "concept-box",
                               h4("Torque & Load Analysis:"),
                               
                               p(class = "description-text",
                                 "Faults in gears identified using torque and load measurements in addition to conventional vibration. 
                                 Features extracted: RMS, kurtosis, peak value."
                               ),
                               
                               h5("Advantages:"),
                               tags$ul(
                                 tags$li("Complements vibration analysis"),
                                 tags$li("Detects load imbalances"),
                                 tags$li("Identifies tooth engagement issues"),
                                 tags$li("Captures torque fluctuations")
                               )
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h4("Wavelet-Based Methods:"),
                               
                               p(class = "description-text",
                                 "Wavelets widely used for noise reduction and gear vibration frequency selection to feed ANN classifiers."
                               ),
                               
                               h5("Applications:"),
                               tags$ul(
                                 tags$li(strong("Tooth Crack Detection:"), " Early detection in planetary gears through spectral kurtosis"),
                                 tags$li(strong("Lubrication Issues:"), " Wavelet numbers for detecting lack of lubricant in gearboxes"),
                                 tags$li(strong("Time-Synchronous Averaging:"), " Planetary gearbox vibration analysis"),
                                 tags$li(strong("Preprocessing:"), " Wavelet transforms before ANN classification")
                               )
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h4("Higher-Order Moments:"),
                               
                               p(class = "description-text",
                                 "High ANN classification accuracy achieved when central sixth moment included in training data of 
                                 statistical features."
                               ),
                               
                               div(class = "math-formula",
                                   h5("Sixth Moment:"),
                                   withMathJax("$$m_6 = \\frac{1}{N}\\sum_{i=1}^{N}(x_i - \\mu)^6$$"),
                                   p("Captures subtle distribution characteristics beyond standard statistical measures")
                               ),
                               
                               p(class = "description-text",
                                 "This research includes sixth moment in comprehensive feature set extracted from all sensor channels."
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Feature Selection & Classification Methods", status = "warning", solidHeader = TRUE,
                    column(4,
                           div(class = "concept-box",
                               h4("Principal Component Analysis:"),
                               
                               p(class = "description-text",
                                 "PCA performed to extract features and reduce data dimensionality, improving classifier performance 
                                 by eliminating redundant information."
                               ),
                               
                               h5("Benefits:"),
                               tags$ul(
                                 tags$li("Dimensionality reduction"),
                                 tags$li("Decorrelates features"),
                                 tags$li("Retains maximum variance"),
                                 tags$li("Computational efficiency"),
                                 tags$li("Visualization in lower dimensions")
                               ),
                               
                               p(class = "description-text",
                                 strong("This Work:"), " Combines PCA with mRMR for intelligent feature selection before dimensionality 
                                 reduction."
                               )
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h4("Information Theory Metrics:"),
                               
                               h5("Mahalanobis Distance:"),
                               p(class = "description-text",
                                 "Used to select features by minimizing redundancies while maximizing information content. Features 
                                 selected according to their correlation with target classes."
                               ),
                               
                               h5("Entropy-Based Selection:"),
                               tags$ul(
                                 tags$li(strong("Relative Spectrum Entropy:"), " Criterion for single-class classifiers"),
                                 tags$li(strong("Barycenter Frequency:"), " Spectral center of mass as feature"),
                                 tags$li(strong("Neuro-Fuzzy Systems:"), " Information theory metrics for feature selection"),
                                 tags$li(strong("Mutual Information:"), " Quantifies feature-class dependencies")
                               )
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h4("Clustering & Mapping:"),
                               
                               h5("Self-Organizing Maps (SOM):"),
                               p(class = "description-text",
                                 "Intra and inter-clustering scattering based on SOM used to determine important features for gearbox 
                                 testing scenarios."
                               ),
                               
                               h5("Active Learning:"),
                               p(class = "description-text",
                                 "Reinforcement learning agents determine weighting estimator features for equipment health management."
                               ),
                               
                               h5("Health Index:"),
                               p(class = "description-text",
                                 "Based on dominant features to build predictive model and determine maintenance timing."
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Research Positioning & Gap Analysis", status = "primary", solidHeader = TRUE,
                    column(6,
                           h4("Previous Work Limitations:"),
                           div(class = "concept-box",
                               tags$ul(
                                 tags$li(strong("Fixed Feature Sets:"), " Most approaches use predetermined features without adaptation"),
                                 tags$li(strong("Single Component Focus:"), " Either bearings OR gears, not integrated approach"),
                                 tags$li(strong("Limited Sensor Integration:"), " Typically 1-3 sensor types rather than comprehensive 
                                         multi-modal"),
                                 tags$li(strong("Stationary Conditions:"), " Often assume constant operating parameters"),
                                 tags$li(strong("No Multi-Sensor Feature Selection:"), " Haven't addressed selecting relevant features 
                                         across diverse sensor types"),
                                 tags$li(strong("Dataset Limitations:"), " Existing public datasets lack detailed degradation parameters")
                               )
                           )
                    ),
                    column(6,
                           h4("This Research's Contributions:"),
                           div(class = "concept-box",
                               tags$ul(
                                 tags$li(strong("Adaptive Feature Selection:"), " Algorithm selects optimal features based on information 
                                         content and relevance"),
                                 tags$li(strong("Integrated Approach:"), " Handles both bearing and gear faults with unified methodology"),
                                 tags$li(strong("Comprehensive Multi-Sensor:"), " 18 channels across electrical, mechanical, acoustic, 
                                         thermal domains"),
                                 tags$li(strong("Time-Varying Conditions:"), " Tests under realistic dynamic operating scenarios"),
                                 tags$li(strong("Multi-Sensor Feature Selection:"), " First to address feature selection across diverse 
                                         sensor modalities for these faults"),
                                 tags$li(strong("Detailed Benchmark Dataset:"), " Public dataset with precise degradation parameters and 
                                         testing protocols")
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
                          "This section presents the integrated methodology for adaptive feature selection and fault classification, combining 
                          Support Vector Machines, wavelet analysis, Principal Component Analysis, and information-theoretic feature selection. 
                          The Support Vector Machine serves as the classifier, chosen for its structural risk minimization principle that 
                          prevents overfitting compared to artificial neural networks based on empirical risk minimization. SVM determines 
                          a separating hyperplane dividing healthy and faulty classes based on support vectors, optimizing a class-boundary 
                          problem through quadratic optimization. For feature extraction, wavelet analysis detects transient components in 
                          time-varying conditions, transforming signals from time domain to frequency domain enabling simultaneous time-frequency 
                          localization. Discrete Wavelet Transform (DWT) decomposes signals hierarchically into detail and approximation 
                          components with limited levels. Principal Component Analysis reduces feature dimensionality through orthogonal linear 
                          transformation of independent variables into principal component scores, with loading vectors computed by maximizing 
                          the Rayleigh quotient. Subsequent components subtract previous ones, creating a reduced variable set for SVM training. 
                          The adaptive feature extraction methodology trains SVM with PCA-processed data using information correlation metrics. 
                          Based on minimum redundancy maximum relevance (mRMR) principle, features are selected to reduce inter-feature 
                          redundancy while maximizing mutual information between features and target classes. Maximum relevance criterion 
                          selects features most correlated with fault classes, while minimum redundancy criterion eliminates similar features. 
                          These combine into an information score optimized to select the feature subset. A PCA score metric determines 
                          how many principal components to include, balancing dimensionality reduction against approximation accuracy. The 
                          complete algorithm processes raw measurements through normalization, statistical and wavelet feature extraction, 
                          mRMR-based feature selection, PCA dimensionality reduction based on information score, and SVM classification. 
                          This integrated approach enables effective fault identification with reduced computational requirements compared 
                          to using all available features from all sensor channels."
                        )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Support Vector Machine Classification", status = "info", solidHeader = TRUE,
                    column(6,
                           h4("SVM Fundamentals:"),
                           div(class = "concept-box",
                               p(class = "description-text",
                                 "SVM is a statistical classifier for high-dimensional data and non-linear functions. Unlike ANNs 
                                 (empirical risk minimization), SVM uses structural risk minimization to prevent overtraining and 
                                 achieve better generalization."
                               ),
                               
                               h5("Binary Classification:"),
                               tags$ul(
                                 tags$li(strong("Healthy Class:"), " BLDCM with bearing/gear in good condition"),
                                 tags$li(strong("Faulty Class:"), " BLDCM with bearing/gear in degraded condition"),
                                 tags$li(strong("Training Data:"), " Class-labeled feature vectors"),
                                 tags$li(strong("Objective:"), " Find optimal separating hyperplane")
                               )
                           )
                    ),
                    column(6,
                           h4("SVM Optimization:"),
                           div(class = "math-formula",
                               h5("Training Problem:"),
                               p("Given training vectors ", withMathJax("$x_i \\in \\mathbb{R}^n$"), " and class labels ", 
                                 withMathJax("$y_i \\in \\{1,-1\\}$"), ", optimize:"),
                               
                               withMathJax("$$\\min_{w,b,\\xi} \\frac{1}{2}W^TW + C\\sum_{i=1}^{l}\\xi_i$$"),
                               
                               h5("Subject to:"),
                               withMathJax("$$y_i(W^T\\phi(x_i) + b) \\geq 1 - \\xi_i$$"),
                               withMathJax("$$\\xi_i \\geq 0$$"),
                               
                               p("where:"),
                               tags$ul(
                                 tags$li(withMathJax("$\\phi$"), " - mapping to higher dimensional space"),
                                 tags$li(withMathJax("$C$"), " - penalty parameter"),
                                 tags$li(withMathJax("$\\xi_i$"), " - slack variables")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Wavelet Analysis for Transient Detection", status = "success", solidHeader = TRUE,
                    column(6,
                           h4("Wavelet Transform Principles:"),
                           div(class = "concept-box",
                               p(class = "description-text",
                                 "Wavelets identify transient components in time-varying conditions by transforming signals from 
                                 time to frequency domain with simultaneous localization in both domains."
                               ),
                               
                               h5("Resolution Characteristics:"),
                               tags$ul(
                                 tags$li(strong("High Frequencies:"), " Good time, low frequency resolution"),
                                 tags$li(strong("Low Frequencies:"), " Good frequency, low time resolution"),
                                 tags$li(strong("Adaptive:"), " Resolution adapts to signal characteristics"),
                                 tags$li(strong("Multi-Scale:"), " Analyzes signal at multiple scales simultaneously")
                               )
                           )
                    ),
                    column(6,
                           h4("Discrete Wavelet Transform (DWT):"),
                           div(class = "concept-box",
                               p(class = "description-text",
                                 "DWT decomposes signals in hierarchical structure with limited approximations and detail levels."
                               ),
                               
                               h5("Wavelet Features Extracted:"),
                               tags$ul(
                                 tags$li(strong("Wavelet Mean:"), " Average of wavelet coefficients"),
                                 tags$li(strong("Wavelet Variance:"), " Variability of coefficients"),
                                 tags$li(strong("Wavelet RMS:"), " Root mean square of coefficients")
                               ),
                               
                               h5("Mother Wavelet:"),
                               p(class = "description-text",
                                 "Daubechies 2 (db02) wavelet used for feature extraction due to good time-frequency localization 
                                 properties for fault signatures."
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Principal Component Analysis (PCA)", status = "warning", solidHeader = TRUE,
                    column(6,
                           h4("PCA Theory:"),
                           div(class = "math-formula",
                               p("Orthogonal linear transformation of independent variables ", withMathJax("$x_i$"), 
                                 " into principal component scores:"),
                               withMathJax("$$t_k^{(i)} = x_i \\cdot w^{(k)}$$"),
                               
                               h5("First Loading Vector:"),
                               p("Computed by maximizing Rayleigh quotient:"),
                               withMathJax("$$w^{(1)} = \\arg\\max_{\\|w\\|=1} \\left\\{\\frac{w^TX^TXw}{w^Tw}\\right\\}$$"),
                               
                               h5("Subsequent Components:"),
                               p("Found by subtracting previous ", withMathJax("$k-1$"), " components from ", withMathJax("$X$"), 
                                 " and repeating optimization")
                           )
                    ),
                    column(6,
                           h4("Dimensionality Reduction:"),
                           div(class = "concept-box",
                               h5("Objectives:"),
                               tags$ul(
                                 tags$li("Reduce feature space dimensionality"),
                                 tags$li("Retain maximum variance"),
                                 tags$li("Eliminate redundant information"),
                                 tags$li("Improve computational efficiency"),
                                 tags$li("Enhance SVM training")
                               ),
                               
                               h5("Trade-off:"),
                               p(class = "description-text",
                                 "Number of principal components selected balances dimensionality reduction against approximation 
                                 accuracy. Information score metric (presented next) determines optimal component count."
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Minimum Redundancy Maximum Relevance (mRMR)", status = "primary", solidHeader = TRUE,
                    p(class = "description-text",
                      "The adaptive feature selection approach combines two complementary principles: selecting features highly correlated 
                      with fault classes while minimizing redundancy between selected features."
                    ),
                    
                    column(6,
                           h4("Maximum Relevance Criterion:"),
                           div(class = "math-formula",
                               withMathJax("$$R_F = \\max_{F \\in S} \\frac{1}{|F|}\\sum_{j \\in F} I(c_i, f_j)$$"),
                               
                               p("where:"),
                               tags$ul(
                                 tags$li(withMathJax("$I(c_i, f_j)$"), " - relevance between feature ", withMathJax("$f_j$"), 
                                         " and class ", withMathJax("$c_i$")),
                                 tags$li(withMathJax("$F$"), " - feature subset"),
                                 tags$li(withMathJax("$S$"), " - complete feature set"),
                                 tags$li(withMathJax("$|F|$"), " - number of features in subset")
                               )
                           ),
                           
                           div(class = "concept-box",
                               h5("Interpretation:"),
                               p(class = "description-text",
                                 "Select features with highest mutual information with target fault classes. Ensures selected 
                                 features are informative for classification task."
                               )
                           )
                    ),
                    column(6,
                           h4("Minimum Redundancy Criterion:"),
                           div(class = "math-formula",
                               withMathJax("$$U_F = \\min_{F \\in S} \\frac{1}{|F|^2}\\sum_{j,k \\in F} I(f_j, f_k)$$"),
                               
                               p("where:"),
                               tags$ul(
                                 tags$li(withMathJax("$I(f_j, f_k)$"), " - mutual information between features ", 
                                         withMathJax("$f_j$"), " and ", withMathJax("$f_k$")),
                                 tags$li("Quantifies similarity/redundancy"),
                                 tags$li("Penalizes highly correlated features")
                               )
                           ),
                           
                           div(class = "concept-box",
                               h5("Interpretation:"),
                               p(class = "description-text",
                                 "Minimize redundancy between selected features. Eliminates features providing similar information, 
                                 reducing dimensionality without information loss."
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Information Score & Feature Selection", status = "info", solidHeader = TRUE,
                    column(6,
                           h4("Combined Information Score:"),
                           div(class = "math-formula",
                               p("Combining relevance and redundancy criteria:"),
                               withMathJax("$$\\Gamma(f_j) = \\frac{1}{|F|}\\sum_{j \\in F} I(c_i, f_j) - 
                                           \\frac{1}{|F|^2}\\sum_{j,k \\in F} I(f_j, f_k)$$"),
                               
                               h5("Optimization:"),
                               withMathJax("$$\\max_{F \\in S} \\{\\Gamma(f_j)\\}$$"),
                               
                               p("Feature subset ", withMathJax("$F^*$"), " selected by maximizing ", withMathJax("$\\Gamma$"))
                           )
                    ),
                    column(6,
                           h4("PCA Score Metric:"),
                           div(class = "math-formula",
                               p("Determines number of PCA components:"),
                               withMathJax("$$\\zeta(F^*) = 1 - \\mu(F^*)^2$$"),
                               
                               p("where:"),
                               withMathJax("$$\\mu(F^*) = \\frac{1}{|F^*|}\\sum_{f_i \\in F^*} \\Gamma(f_j)$$"),
                               
                               p("with ", withMathJax("$0 \\leq \\mu(F^*) \\leq 1$")),
                               
                               h5("Interpretation:"),
                               tags$ul(
                                 tags$li("Low ", withMathJax("$\\zeta$"), ": few PCA components needed"),
                                 tags$li("High ", withMathJax("$\\zeta$"), ": more components retained"),
                                 tags$li("Adapts to information content of selected features")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Complete Algorithm", status = "success", solidHeader = TRUE,
                    column(6,
                           div(style = "background: #f8f9fa; padding: 20px; border-radius: 8px; font-family: monospace;",
                               strong("Algorithm: Adaptive Feature Selection"), br(), br(),
                               
                               strong("Input:"), br(),
                               "  X - Raw multi-sensor measurements", br(),
                               "  c - Target fault classes", br(), br(),
                               
                               strong("Output:"), br(),
                               "  F* - Selected optimal features", br(),
                               "  P - PCA-reduced training data", br(), br(),
                               
                               strong("Steps:"), br(),
                               "1. Normalize X", br(),
                               "2. Extract features from normalized X:", br(),
                               "   • Statistical: mean, variance, skewness,", br(),
                               "     kurtosis, 6th moment, RMS, power", br(),
                               "   • Wavelet: mean, variance, RMS", br(), br(),
                               
                               "3. Extract F* based on relevance and", br(),
                               "   correlation with class c (mRMR)", br(), br(),
                               
                               "4. Apply PCA on F* to compute P:", br(),
                               "   • Select components based on ζ(F*)", br(), br(),
                               
                               "5. Train SVM with P for fault", br(),
                               "   classification (healthy vs. faulty)", br()
                           )
                    ),
                    column(6,
                           h4("Data Processing Pipeline:"),
                           plotlyOutput("pipeline_diagram", height = "400px"),
                           
                           div(class = "concept-box", style = "margin-top: 15px;",
                               h5("Key Advantages:"),
                               tags$ul(
                                 tags$li(strong("Adaptive:"), " Features selected based on actual information content"),
                                 tags$li(strong("Optimal Dimensionality:"), " PCA components determined by information score"),
                                 tags$li(strong("Reduced Redundancy:"), " Eliminates correlated features"),
                                 tags$li(strong("Enhanced Relevance:"), " Retains most informative features"),
                                 tags$li(strong("Computational Efficiency:"), " Smaller training dataset for SVM"),
                                 tags$li(strong("Generalization:"), " Structural risk minimization prevents overfitting")
                               )
                           )
                    )
                )
              )
      ),
      
      # Experiment Design Tab
      tabItem(tabName = "design",
              fluidRow(
                box(width = 12, title = "Experiment Design - Overview", status = "primary", solidHeader = TRUE,
                    div(class = "concept-box",
                        p(class = "description-text",
                          "This section details the comprehensive experimental methodology for systematic testing of bearings and gears 
                          connected to BLDCMs under controlled fault conditions. The testing platform, previously described for BLDCM bearing 
                          testing, was extended to accommodate gear testing scenarios while maintaining the same 18-channel multi-sensor 
                          measurement capability. The platform incorporates voltage measurements (9 channels: 3 phase-to-ground, 3 phase-to-phase, 
                          3 power supply), current measurements (3 channels via shunt resistors), 3-axis vibration (accelerometer), sound 
                          pressure (microphone), temperature (RTD), torque (strain gage), motor speed (Hall sensor), and perpendicular force 
                          (load cell). Equipment includes National Instruments PXIe chassis with data acquisition modules, Maxon motor controller, 
                          NSK 10mm bearing with 7 balls, Maxon 18:1 reduction gearheads, electronic load, 3D accelerometer, microphone, load 
                          cell, torque sensor, RTD unit, and brushless DC generator. Data sampled at 10 kHz per channel represents a trade-off 
                          between accuracy and portability—1 second weighs 3 megabytes, manageable for public dataset distribution. Software-based 
                          second-order Butterworth filters applied with channel-specific cutoffs: 2-10 kHz bandpass for vibration (bearing energy 
                          content range), 10 kHz lowpass for voltage/current (removes 50 kHz driver switching), 10 kHz for sound, 1 kHz for 
                          load/torque/Hall/power, 100 Hz for temperature. Filtered data divided into 8192-point packets (power of 2 for efficient 
                          feature computation) for feature extraction. For bearing tests, two bearings tested: healthy baseline and faulty with 
                          0.3mm deep outer raceway hole (artificially induced with 0.8mm tungsten boring tool). Three time-varying conditions 
                          tested independently: electronic load (0-0.5A at constant 3000 RPM and 30N force), perpendicular force (0-150N cycled 
                          at 3000 RPM with no load), rotating speed (1000-3000 RPM at 30N force with no load). For gear tests, three gearheads 
                          tested: healthy baseline, one tooth removed, two teeth removed (using Dremel). Time-varying condition: speed cycled 
                          500-1500-500 RPM over 1-hour periods. Accelerometer and microphone positioned next to bearing holder and gearhead 
                          holder respectively to maximize signal-to-noise ratio. Platform enables full control of three independent time-varying 
                          conditions providing realistic dynamic operating scenarios for validating adaptive feature selection algorithm."
                        )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Testing Platform Specifications", status = "info", solidHeader = TRUE,
                    column(4,
                           div(class = "concept-box",
                               h4("Major Equipment:"),
                               tags$ul(
                                 tags$li(strong("Data Acquisition:"), " NI PXIe chassis + DAQ modules"),
                                 tags$li(strong("Motor Control:"), " Maxon motor controller"),
                                 tags$li(strong("Test Bearing:"), " NSK 10mm, 7-ball bearing"),
                                 tags$li(strong("Test Gearheads:"), " Maxon 18:1 reduction ratio"),
                                 tags$li(strong("Load Application:"), " Electronic load (e-Load)"),
                                 tags$li(strong("Vibration:"), " 3D accelerometer (X,Y,Z)"),
                                 tags$li(strong("Acoustic:"), " Microphone"),
                                 tags$li(strong("Force:"), " Tension/compression load cell"),
                                 tags$li(strong("Torque:"), " Reaction torque sensor"),
                                 tags$li(strong("Temperature:"), " RTD unit"),
                                 tags$li(strong("Generator:"), " Brushless DC for loading")
                               )
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h4("18-Channel Sensor Suite:"),
                               
                               h5("Electrical (12 channels):"),
                               tags$ul(
                                 tags$li("Voltage Phase A, B, C to Ground (3)"),
                                 tags$li("Voltage Phase A-B, B-C, C-A (3)"),
                                 tags$li("Current Phase A, B, C via shunts (3)"),
                                 tags$li("Power supply voltage/current (3)")
                               ),
                               
                               h5("Mechanical (6 channels):"),
                               tags$ul(
                                 tags$li("Vibration X, Y, Z axes (3)"),
                                 tags$li("Perpendicular force (1)"),
                                 tags$li("Reaction torque (1)"),
                                 tags$li("Motor speed - Hall sensor (1)")
                               ),
                               
                               h5("Acoustic & Thermal (2 channels):"),
                               tags$ul(
                                 tags$li("Sound pressure level (1)"),
                                 tags$li("Temperature (1)")
                               )
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h4("Sampling & Storage:"),
                               
                               div(class = "math-formula",
                                   withMathJax("$$\\text{Sampling Rate: } 10 \\text{ kHz/channel}$$"),
                                   withMathJax("$$\\text{Total Rate: } 180 \\text{ kHz (18 channels)}$$"),
                                   withMathJax("$$\\text{Data Size: } 3 \\text{ MB/second}$$")
                               ),
                               
                               h5("Trade-offs:"),
                               tags$ul(
                                 tags$li("Adequate for bearing/gear frequencies"),
                                 tags$li("Manageable file sizes for dataset"),
                                 tags$li("Reasonable feature extraction time"),
                                 tags$li("Suitable for public distribution")
                               ),
                               
                               h5("Window Size:"),
                               p("8192 data points per feature extraction (power of 2 for FFT efficiency)")
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Signal Conditioning & Filtering", status = "success", solidHeader = TRUE,
                    column(6,
                           h4("Channel-Specific Filter Design:"),
                           div(class = "concept-box",
                               h5("Vibration Channels (X, Y, Z):"),
                               div(class = "math-formula",
                                   p("Bandpass: 2 kHz - 10 kHz"),
                                   p(strong("Rationale:"), " Rolling bearing energy content concentrated in this range per 
                                     Carter patent. Captures bearing-specific fault signatures.")
                               ),
                               
                               h5("Voltage & Current (9 channels):"),
                               div(class = "math-formula",
                                   p("Lowpass: 10 kHz cutoff"),
                                   p(strong("Rationale:"), " BLDCM driver switching frequency at 50 kHz. Filter removes 
                                     power electronics artifacts while retaining motor dynamics.")
                               ),
                               
                               h5("Sound Pressure:"),
                               div(class = "math-formula",
                                   p("Lowpass: 10 kHz cutoff"),
                                   p(strong("Rationale:"), " Acoustic fault signatures below 10 kHz, eliminates high-frequency 
                                     environmental noise.")
                               )
                           )
                    ),
                    column(6,
                           h4("Remaining Channels:"),
                           div(class = "concept-box",
                               h5("Load, Torque, Hall, Power (4 channels):"),
                               div(class = "math-formula",
                                   p("Lowpass: 1 kHz cutoff"),
                                   p(strong("Rationale:"), " Slowly varying signals, 1 kHz captures all relevant dynamics.")
                               ),
                               
                               h5("Temperature (RTD):"),
                               div(class = "math-formula",
                                   p("Lowpass: 100 Hz cutoff"),
                                   p(strong("Rationale:"), " Thermal dynamics very slow, RTD sensor bandwidth limited. 
                                     100 Hz more than sufficient.")
                               )
                           ),
                           
                           div(class = "highlight-box",
                               h4("Filter Implementation:"),
                               tags$ul(
                                 tags$li(strong("Type:"), " 2nd order Butterworth"),
                                 tags$li(strong("Implementation:"), " Software-based (offline processing)"),
                                 tags$li(strong("Phase:"), " Zero-phase filtering to preserve temporal alignment"),
                                 tags$li(strong("Advantages:"), " Flexible cutoff adjustment, no hardware modifications needed")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Bearing Test Protocols", status = "warning", solidHeader = TRUE,
                    column(6,
                           h4("Test Specimens:"),
                           div(class = "concept-box",
                               h5("Healthy Bearing:"),
                               tags$ul(
                                 tags$li("New NSK 10mm bearing"),
                                 tags$li("7 balls, no defects"),
                                 tags$li("Baseline reference data")
                               ),
                               
                               h5("Faulty Bearing:"),
                               tags$ul(
                                 tags$li("Outer raceway damage"),
                                 tags$li("0.3mm deep hole"),
                                 tags$li("Induced with 0.8mm tungsten boring tool"),
                                 tags$li("Bearing balls fall slightly into hole during rotation"),
                                 tags$li("Creates impact signatures in vibration")
                               )
                           ),
                           
                           div(class = "math-formula",
                               h4("Sensor Placement:"),
                               p(strong("Accelerometer & Microphone:"), " Positioned directly next to bearing holder to 
                                 maximize signal-to-noise ratio and minimize effects from other vibration/sound sources.")
                           )
                    ),
                    column(6,
                           h4("Time-Varying Test Conditions:"),
                           div(class = "concept-box",
                               h5("Test 1: Electronic Load Variation"),
                               tags$ul(
                                 tags$li("eLoad: 0 → 0.5 A (linear)"),
                                 tags$li("Speed: 3000 RPM (constant)"),
                                 tags$li("Force: 30 N (constant)"),
                                 tags$li("Duration: 1 hour")
                               ),
                               
                               h5("Test 2: Force Variation"),
                               tags$ul(
                                 tags$li("Force: 0 → 150 → 0 N (cycle)"),
                                 tags$li("Speed: 3000 RPM (constant)"),
                                 tags$li("eLoad: 0 A"),
                                 tags$li("Duration: 1 hour")
                               ),
                               
                               h5("Test 3: Speed Variation"),
                               tags$ul(
                                 tags$li("Speed: 1000 → 3000 RPM (linear)"),
                                 tags$li("eLoad: 0 A"),
                                 tags$li("Force: 30 N (constant)"),
                                 tags$li("Duration: 1 hour")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Gear Test Protocols", status = "primary", solidHeader = TRUE,
                    column(4,
                           div(class = "concept-box",
                               h4("Test Specimens:"),
                               
                               h5("Healthy Gearhead:"),
                               tags$ul(
                                 tags$li("Maxon 18:1 reduction"),
                                 tags$li("All teeth intact"),
                                 tags$li("Recommended: <5000 RPM"),
                                 tags$li("Baseline reference")
                               ),
                               
                               h5("Faulty Gearhead 1:"),
                               tags$ul(
                                 tags$li("One tooth removed from main gear"),
                                 tags$li("Removed using Dremel"),
                                 tags$li("Manual rotation reveals impact")
                               ),
                               
                               h5("Faulty Gearhead 2:"),
                               tags$ul(
                                 tags$li("Two teeth removed from main gear"),
                                 tags$li("More severe fault condition"),
                                 tags$li("Stronger impact signatures expected")
                               )
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h4("Time-Varying Condition:"),
                               
                               h5("Speed Cycling Test:"),
                               div(class = "math-formula",
                                   withMathJax("$$500 \\xrightarrow{\\text{increase}} 1500 \\xrightarrow{\\text{decrease}} 500 \\text{ RPM}$$"),
                                   p("Duration: 1 hour per gearhead"),
                                   p("Linear speed variation"),
                                   p("No external load applied"),
                                   p("Constant temperature monitoring")
                               ),
                               
                               h5("Why Speed Variation?"),
                               tags$ul(
                                 tags$li("Tests gear engagement at different speeds"),
                                 tags$li("Reveals speed-dependent fault signatures"),
                                 tags$li("Simulates realistic operating scenarios"),
                                 tags$li("Maximum stress at higher speeds")
                               )
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h4("Sensor Configuration:"),
                               
                               h5("Primary Sensors:"),
                               tags$ul(
                                 tags$li(strong("Accelerometer:"), " Next to gearhead holder"),
                                 tags$li(strong("Microphone:"), " Adjacent to gearhead"),
                                 tags$li(strong("Torque:"), " Output shaft measurement"),
                                 tags$li(strong("Current:"), " All three phases"),
                                 tags$li(strong("Voltage:"), " Phase-to-ground and phase-to-phase")
                               ),
                               
                               h5("Expected Signatures:"),
                               tags$ul(
                                 tags$li("Vibration spikes at tooth engagement"),
                                 tags$li("Increased vibration amplitude"),
                                 tags$li("Higher current draw"),
                                 tags$li("Acoustic impact signatures"),
                                 tags$li("Torque fluctuations")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Feature Extraction Strategy", status = "info", solidHeader = TRUE,
                    column(6,
                           h4("Statistical Features (per channel):"),
                           div(class = "concept-box",
                               div(class = "math-formula",
                                   tags$ol(
                                     tags$li(strong("Mean:"), " ", withMathJax("$\\mu = \\frac{1}{N}\\sum_{i=1}^{N}x_i$")),
                                     tags$li(strong("Variance:"), " ", withMathJax("$\\sigma^2 = \\frac{1}{N}\\sum_{i=1}^{N}(x_i-\\mu)^2$")),
                                     tags$li(strong("Skewness:"), " ", withMathJax("$\\text{Skew} = \\frac{1}{N\\sigma^3}\\sum(x_i-\\mu)^3$")),
                                     tags$li(strong("Kurtosis:"), " ", withMathJax("$\\text{Kurt} = \\frac{1}{N\\sigma^4}\\sum(x_i-\\mu)^4$")),
                                     tags$li(strong("6th Moment:"), " ", withMathJax("$m_6 = \\frac{1}{N}\\sum(x_i-\\mu)^6$")),
                                     tags$li(strong("RMS:"), " ", withMathJax("$\\text{RMS} = \\sqrt{\\frac{1}{N}\\sum x_i^2}$")),
                                     tags$li(strong("Signal Power:"), " ", withMathJax("$P = \\frac{1}{N}\\sum x_i^2$"))
                                   )
                               )
                           )
                    ),
                    column(6,
                           h4("Wavelet Features (per channel):"),
                           div(class = "concept-box",
                               h5("Daubechies 2 (db02) Wavelet:"),
                               tags$ol(
                                 tags$li(strong("Wavelet Mean:"), " Average of wavelet coefficients at each decomposition level"),
                                 tags$li(strong("Wavelet Variance:"), " Variability of coefficients, indicates transient energy"),
                                 tags$li(strong("Wavelet RMS:"), " Root mean square of coefficients, overall wavelet energy")
                               ),
                               
                               h5("Total Features:"),
                               p(class = "description-text",
                                 "10 features per channel × 18 channels = 180 total features extracted from each 8192-point window. 
                                 Adaptive feature selection algorithm determines optimal subset."
                               )
                           )
                    )
                )
              )
      ),
      
      # Results Tab
      tabItem(tabName = "results",
              fluidRow(
                box(width = 12, title = "Experimental Results - Overview", status = "primary", solidHeader = TRUE,
                    div(class = "concept-box",
                        p(class = "description-text",
                          "This section presents comprehensive experimental results validating the adaptive feature selection methodology 
                          across multiple fault scenarios for bearings and gears under time-varying conditions. Features extracted from 
                          filtered measurement signals include: mean, variance, skewness, kurtosis, sixth moment, RMS, signal power, wavelet 
                          mean, wavelet variance, and wavelet RMS using Daubechies 2 (db02) mother wavelet. For each test (bearing with 
                          varying eLoad, speed, and force; gears with 1 or 2 missing teeth), time-varying conditions were linearly increased 
                          and decreased over 1-hour operation periods. Complete feature sets extracted from all 18 channels were processed 
                          offline, then selected based on correlation using the mRMR algorithm. PCA transformed selected features into lower-dimensional 
                          space using information score metric to determine component count. SVM with Gaussian kernel trained for binary 
                          classification (healthy vs. faulty) using PCA-derived feature vectors. Raw measurement analysis revealed clear fault 
                          signatures: bearing current amplitude higher for faulty case at 3000 RPM, gear vibration amplitude significantly 
                          increased for toothless configurations at 1500 RPM. Wavelet variance analysis demonstrated excellent feature discriminability—both 
                          current and vibration wavelet variance higher in faulty cases. Two experimental configurations tested: (1) fixed 
                          channel set with adaptive feature selection, and (2) fixed feature set with adaptive channel selection. Results show 
                          classification accuracies of 91.73-96.74% depending on test scenario and configuration. Feature selection experiments 
                          identified optimal features vary by fault type: bearing eLoad test optimal with skewness, 6th moment, RMS, wavelet 
                          mean (91.73% accuracy); bearing speed test with mean, variance, skewness, RMS (83.02%); bearing force test with 
                          variance, skewness, power, wavelet mean (93.39%); gear 1-tooth with mean, kurtosis, 6th moment, RMS, wavelet variance 
                          (86.87%); gear 2-teeth with mean, variance, skewness, kurtosis, RMS, wavelet variance (96.74%). Channel selection 
                          experiments with fixed statistical + wavelet RMS features achieved 85.12-96.42% accuracy by selecting optimal sensor 
                          combinations. Information index experiments demonstrate classification accuracy increases proportionally with ζ (PCA 
                          component threshold), validating trade-off between training data size and information content. Results conclusively 
                          demonstrate adaptive feature selection significantly improves fault detection performance compared to fixed feature 
                          approaches, with the algorithm successfully identifying informative features tailored to specific fault scenarios."
                        )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Raw Signal Analysis", status = "info", solidHeader = TRUE,
                    column(6,
                           h4("Bearing Fault Signatures:"),
                           plotlyOutput("bearing_current_plot", height = "300px"),
                           
                           div(class = "concept-box",
                               h5("Current Signature Observations:"),
                               tags$ul(
                                 tags$li(strong("Healthy:"), " Lower, more consistent current amplitude"),
                                 tags$li(strong("Faulty:"), " Higher current amplitude due to increased resistance from bearing damage"),
                                 tags$li(strong("Mechanism:"), " 0.3mm hole in outer raceway causes balls to fall into hole, creating 
                                         impact and additional friction"),
                                 tags$li(strong("Frequency Content:"), " Additional harmonics appear in faulty case spectrum"),
                                 tags$li(strong("Consistency:"), " Similar patterns across all three phases")
                               )
                           )
                    ),
                    column(6,
                           h4("Gear Fault Signatures:"),
                           plotlyOutput("gear_vibration_plot", height = "300px"),
                           
                           div(class = "concept-box",
                               h5("Vibration Signature Observations:"),
                               tags$ul(
                                 tags$li(strong("Healthy:"), " Lower, smoother vibration profile"),
                                 tags$li(strong("1 Tooth Missing:"), " Increased amplitude with periodic spikes"),
                                 tags$li(strong("2 Teeth Missing:"), " Significantly higher amplitude and impact signatures"),
                                 tags$li(strong("Mechanism:"), " Missing teeth create engagement gaps causing impacts"),
                                 tags$li(strong("Severity:"), " Fault severity clearly correlated with vibration magnitude")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Wavelet Feature Analysis", status = "success", solidHeader = TRUE,
                    column(6,
                           h4("Bearing - Wavelet Variance of Current:"),
                           plotlyOutput("bearing_wavelet_plot", height = "300px"),
                           
                           div(class = "concept-box",
                               h5("Key Observations:"),
                               tags$ul(
                                 tags$li("Wavelet variance consistently higher for faulty bearing"),
                                 tags$li("Clear separation between healthy and faulty throughout force variation"),
                                 tags$li("Wavelet features capture transient impacts from bearing hole"),
                                 tags$li("Demonstrates discriminative power of wavelet-based features")
                               )
                           )
                    ),
                    column(6,
                           h4("Gear - Wavelet Variance of Vibration:"),
                           plotlyOutput("gear_wavelet_plot", height = "300px"),
                           
                           div(class = "concept-box",
                               h5("Key Observations:"),
                               tags$ul(
                                 tags$li("Dramatic increase in wavelet variance for faulty gear"),
                                 tags$li("Excellent feature for distinguishing healthy from faulty"),
                                 tags$li("Captures transient impacts from missing tooth engagement"),
                                 tags$li("Validates wavelet analysis for gear fault detection")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Classification Results - Feature Selection", status = "warning", solidHeader = TRUE,
                    p(class = "description-text",
                      "Adaptive feature selection algorithm tested under two configurations: (1) all channels used with selected features, 
                      (2) all features used with selected channels. Results demonstrate different features/channels optimal for different fault 
                      scenarios."
                    ),
                    
                    column(12,
                           h4("Configuration 1: All Channels, Selected Features"),
                           DTOutput("feature_selection_table")
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Classification Results - Channel Selection", status = "primary", solidHeader = TRUE,
                    column(12,
                           h4("Configuration 2: Fixed Features (m, v, s, k, wr), Selected Channels"),
                           DTOutput("channel_selection_table"),
                           
                           div(class = "concept-box", style = "margin-top: 15px;",
                               h5("Key Insights:"),
                               tags$ul(
                                 tags$li("Channel selection with fixed features achieves 85-96% accuracy"),
                                 tags$li("Optimal channels vary by fault type and test condition"),
                                 tags$li("Voltage, current, temperature, sound consistently important"),
                                 tags$li("Vibration channels critical for mechanical faults"),
                                 tags$li("Multi-sensor approach validated: no single channel sufficient")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "PCA Component Analysis", status = "info", solidHeader = TRUE,
                    column(6,
                           h4("Information Index vs PCA Elements:"),
                           plotlyOutput("pca_elements_plot", height = "350px"),
                           
                           div(class = "concept-box",
                               h5("Interpretation:"),
                               tags$ul(
                                 tags$li(strong("Low ζ:"), " Few PCA components needed (highly informative features)"),
                                 tags$li(strong("High ζ:"), " More components retained (lower individual feature information)"),
                                 tags$li(strong("G-2Teeth:"), " Lower curve = fewer components for same ζ (very informative features)"),
                                 tags$li(strong("G-1Teeth:"), " Higher curve = more components needed"),
                                 tags$li(strong("Bearing tests:"), " Similar behavior across eLoad, speed, force variations")
                               )
                           )
                    ),
                    column(6,
                           h4("Classification with Varying Components:"),
                           DTOutput("pca_accuracy_table")
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Key Findings Summary", status = "success", solidHeader = TRUE,
                    column(4,
                           div(class = "concept-box",
                               h4("Feature Selection Impact:"),
                               tags$ul(
                                 tags$li("Optimal features vary by fault type"),
                                 tags$li("Bearing eLoad: skewness, 6th moment, RMS, wavelet mean"),
                                 tags$li("Bearing speed: mean, variance, skewness, RMS"),
                                 tags$li("Bearing force: variance, skewness, power, wavelet mean"),
                                 tags$li("Gear 1-tooth: mean, kurtosis, 6th moment, RMS, wavelet variance"),
                                 tags$li("Gear 2-teeth: mean, variance, skewness, kurtosis, RMS, wavelet variance"),
                                 tags$li("Accuracies: 83.02-96.74%")
                               )
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h4("Channel Selection Impact:"),
                               tags$ul(
                                 tags$li("Fixed features with channel selection: 85.12-96.42%"),
                                 tags$li("Voltage and current channels consistently selected"),
                                 tags$li("Temperature provides valuable trending information"),
                                 tags$li("Sound pressure captures acoustic fault signatures"),
                                 tags$li("Vibration (X,Y,Z) critical for mechanical faults"),
                                 tags$li("Multi-sensor integration essential")
                               )
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h4("PCA Dimensionality Reduction:"),
                               tags$ul(
                                 tags$li("Classification accuracy increases with ζ (more PCA components)"),
                                 tags$li("Trade-off: data size vs. accuracy"),
                                 tags$li("10 features, ζ=0.94: 52.59-95.45% accuracy"),
                                 tags$li("20 features, ζ=0.96: 91.16-97.40% accuracy"),
                                 tags$li("30 features, ζ=0.97: 90.25-99.35% accuracy"),
                                 tags$li("Information score effectively guides PCA selection")
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
                          "This research successfully presents an integrated approach for adaptive feature extraction and fault classification 
                          of mechanical components connected to brushless DC motors. Different testing scenarios were demonstrated with full 
                          control of time-varying conditions (rotating speed, electronic load, perpendicular force) applied to bearings and 
                          gears using a state-of-the-art testing platform. The platform was customized for systematic testing of bearings and 
                          gears coupled to BLDCMs, collecting data through 18 sensor channels spanning electrical, mechanical, acoustic, and 
                          thermal domains. Generated data from these controlled fault scenarios will be made publicly available as a benchmark 
                          dataset enabling further research and algorithm testing for fault prediction and analysis. The comprehensive multi-sensor 
                          platform with detailed degradation parameters represents a major contribution addressing the critical lack of well-documented 
                          public datasets for prognostics research. Due to the large volume of available multi-sensor data, an adaptive feature 
                          extraction and classification method was proposed and validated, proving effective for identifying equipment health 
                          conditions using the most meaningful data content. The methodology combines minimum redundancy maximum relevance principles 
                          with Principal Component Analysis and Support Vector Machine classification. Experimental results demonstrate that optimal 
                          features and channels vary by fault scenario: bearing tests achieved 83-99% accuracy, gear tests achieved 87-97% accuracy, 
                          with specific combinations of statistical and wavelet features proving most discriminative for each case. The information 
                          score metric successfully guides PCA component selection, with classification accuracy increasing proportionally with 
                          the number of components retained while enabling significant dimensionality reduction. The SVM classifier with Gaussian 
                          kernel effectively separates healthy and faulty classes using adaptively selected features. Future work involves systematic 
                          testing with more complex datasets and real-time online fault identification for remaining useful life estimation. 
                          Additional scenarios including combined faults, varying degrees of degradation, and environmental condition effects 
                          will further validate and extend the methodology. The benchmark dataset and adaptive feature selection framework provide 
                          validated tools advancing practical implementation of prognostics in industrial applications for bearing and gear health 
                          monitoring."
                        )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Research Summary", status = "success", solidHeader = TRUE,
                    column(6,
                           h4("Main Contributions:"),
                           div(class = "concept-box",
                               tags$ol(
                                 tags$li(strong("State-of-the-Art Testing Platform:"), " Customized platform for controlled fault 
                                         induction in BLDCMs with bearings and gears. 18-channel multi-sensor system with full control 
                                         of three time-varying conditions."),
                                 
                                 tags$li(strong("Benchmark Dataset:"), " Comprehensive public dataset with well-documented degradation 
                                         parameters enabling replication. Includes bearing outer raceway fault (0.3mm hole) and gear 
                                         teeth faults (1 and 2 teeth removed)."),
                                 
                                 tags$li(strong("Adaptive Feature Selection Algorithm:"), " Novel methodology combining mRMR principle, 
                                         PCA dimensionality reduction, and SVM classification. Information score metric guides optimal 
                                         component selection."),
                                 
                                 tags$li(strong("Validated Performance:"), " Classification accuracies 83-99% (bearings) and 87-97% (gears) 
                                         across multiple test scenarios under time-varying conditions."),
                                 
                                 tags$li(strong("Feature/Channel Analysis:"), " Demonstrated optimal features and channels vary by fault 
                                         type, validating need for adaptive selection approach.")
                               )
                           )
                    ),
                    column(6,
                           h4("Experimental Validation:"),
                           div(class = "concept-box",
                               h5("Bearing Tests:"),
                               tags$ul(
                                 tags$li("eLoad variation: 91.73% → 96.34% accuracy"),
                                 tags$li("Speed variation: 83.02% → 90.94% accuracy"),
                                 tags$li("Force variation: 93.39% → 92.29% accuracy")
                               ),
                               
                               h5("Gear Tests:"),
                               tags$ul(
                                 tags$li("1 tooth missing: 86.87% → 85.12% accuracy"),
                                 tags$li("2 teeth missing: 96.74% → 96.42% accuracy")
                               ),
                               
                               h5("PCA Optimization:"),
                               tags$ul(
                                 tags$li("10 features (ζ≈0.94): 52-95% accuracy range"),
                                 tags$li("20 features (ζ≈0.96): 91-97% accuracy range"),
                                 tags$li("30 features (ζ≈0.97): 90-99% accuracy range"),
                                 tags$li("Information score effectively guides dimensionality reduction")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Key Achievements", status = "info", solidHeader = TRUE,
                    column(3,
                           box(width = 12, status = "success", solidHeader = TRUE,
                               div(style = "text-align: center; padding: 15px; min-height: 120px;",
                                   div(style = "font-size: 48px; font-weight: bold; color: #00A39A;", "99%"),
                                   h4(style = "margin-top: 10px; color: #008A82;", "Maximum Accuracy"),
                                   p(style = "font-size: 14px; color: #666;", "Bearing fault detection")
                               ),
                               div(class = "concept-box",
                                   p(class = "description-text",
                                     "Achieved with bearing force test using 30 selected features and PCA optimization. 
                                     Demonstrates excellent discriminative power of adaptive feature selection."
                                   )
                               )
                           )
                    ),
                    column(3,
                           box(width = 12, status = "info", solidHeader = TRUE,
                               div(style = "text-align: center; padding: 15px; min-height: 120px;",
                                   div(style = "font-size: 48px; font-weight: bold; color: #3498db;", "18"),
                                   h4(style = "margin-top: 10px; color: #2980b9;", "Sensor Channels"),
                                   p(style = "font-size: 14px; color: #666;", "Comprehensive measurement")
                               ),
                               div(class = "concept-box",
                                   p(class = "description-text",
                                     "Multi-modal sensing across electrical, mechanical, acoustic, and thermal domains. 
                                     Most comprehensive public dataset for bearing/gear prognostics."
                                   )
                               )
                           )
                    ),
                    column(3,
                           box(width = 12, status = "warning", solidHeader = TRUE,
                               div(style = "text-align: center; padding: 15px; min-height: 120px;",
                                   div(style = "font-size: 48px; font-weight: bold; color: #9b59b6;", "180"),
                                   h4(style = "margin-top: 10px; color: #8e44ad;", "Features Extracted"),
                                   p(style = "font-size: 14px; color: #666;", "Per 8192-point window")
                               ),
                               div(class = "concept-box",
                                   p(class = "description-text",
                                     "10 features per channel: statistical (mean, variance, skewness, kurtosis, 6th moment, 
                                     RMS, power) and wavelet (mean, variance, RMS). Adaptive selection determines optimal subset."
                                   )
                               )
                           )
                    ),
                    column(3,
                           box(width = 12, status = "danger", solidHeader = TRUE,
                               div(style = "text-align: center; padding: 15px; min-height: 120px;",
                                   div(style = "font-size: 48px; font-weight: bold; color: #e74c3c;", "3"),
                                   h4(style = "margin-top: 10px; color: #c0392b;", "Time-Varying Conditions"),
                                   p(style = "font-size: 14px; color: #666;", "Controlled independently")
                               ),
                               div(class = "concept-box",
                                   p(class = "description-text",
                                     "Full control of rotating speed, electronic load, and perpendicular force enables 
                                     realistic dynamic operating scenarios for comprehensive fault characterization."
                                   )
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Future Work", status = "primary", solidHeader = TRUE,
                    column(6,
                           div(class = "concept-box",
                               h4("Near-Term Research Directions:"),
                               
                               h5("Extended Testing Scenarios:"),
                               tags$ul(
                                 tags$li(strong("Combined Faults:"), " Test simultaneous bearing and gear faults"),
                                 tags$li(strong("Degradation Stages:"), " Multiple fault severity levels (0.1mm, 0.3mm, 0.5mm holes)"),
                                 tags$li(strong("Environmental Variations:"), " Temperature, humidity, contamination effects"),
                                 tags$li(strong("Load Profiles:"), " Variable load cycles simulating real applications"),
                                 tags$li(strong("Additional Components:"), " Stator faults, misalignment, imbalance")
                               ),
                               
                               h5("Online Implementation:"),
                               tags$ul(
                                 tags$li(strong("Real-Time Detection:"), " Implement algorithm for online fault identification"),
                                 tags$li(strong("RUL Estimation:"), " Remaining useful life prediction models"),
                                 tags$li(strong("Prognostic Health Management:"), " Integration with maintenance scheduling"),
                                 tags$li(strong("Computational Optimization:"), " Reduce processing time for real-time deployment")
                               )
                           )
                    ),
                    column(6,
                           div(class = "concept-box",
                               h4("Advanced Methodologies:"),
                               
                               h5("Algorithm Enhancements:"),
                               tags$ul(
                                 tags$li(strong("Deep Learning:"), " Convolutional neural networks for automatic feature learning"),
                                 tags$li(strong("Ensemble Methods:"), " Combine multiple classifiers for improved robustness"),
                                 tags$li(strong("Transfer Learning:"), " Apply learned models across different motor types"),
                                 tags$li(strong("Unsupervised Learning:"), " Anomaly detection without labeled faulty data"),
                                 tags$li(strong("Multi-Class Classification:"), " Distinguish between different fault types")
                               ),
                               
                               h5("Dataset Expansion:"),
                               tags$ul(
                                 tags$li(strong("More Motor Types:"), " AC induction motors, permanent magnet synchronous motors"),
                                 tags$li(strong("Industrial Data:"), " Real-world industrial machinery data collection"),
                                 tags$li(strong("Benchmarking:"), " Standardized test protocols for algorithm comparison"),
                                 tags$li(strong("Open Platform:"), " Community contributions to dataset and algorithms")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Impact & Applications", status = "warning", solidHeader = TRUE,
                    column(6,
                           div(class = "concept-box",
                               h4("Industrial Applications:"),
                               
                               tags$ul(
                                 tags$li(strong("Manufacturing:"), " Prevent unplanned downtime in production lines"),
                                 tags$li(strong("Mining:"), " Monitor critical equipment in remote locations"),
                                 tags$li(strong("Wind Energy:"), " Gearbox health monitoring in wind turbines"),
                                 tags$li(strong("Aerospace:"), " Actuator and gearbox monitoring in aircraft"),
                                 tags$li(strong("Automotive:"), " Electric vehicle drivetrain monitoring"),
                                 tags$li(strong("Robotics:"), " Joint and actuator health in industrial robots"),
                                 tags$li(strong("HVAC:"), " Fan and compressor motor monitoring")
                               )
                           )
                    ),
                    column(6,
                           div(class = "concept-box",
                               h4("Research Community Impact:"),
                               
                               tags$ul(
                                 tags$li(strong("Benchmark Dataset:"), " Public dataset enables algorithm comparison and validation"),
                                 tags$li(strong("Reproducibility:"), " Detailed protocols enable replication of results"),
                                 tags$li(strong("Education:"), " Dataset useful for teaching prognostics and machine learning"),
                                 tags$li(strong("Open Science:"), " Contributes to open data movement in prognostics"),
                                 tags$li(strong("Collaboration:"), " Platform for collaborative algorithm development"),
                                 tags$li(strong("Standards:"), " Contributes to development of prognostics standards")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Concluding Remarks", status = "success", solidHeader = TRUE,
                    div(class = "highlight-box",
                        p(class = "description-text", style = "font-size: 16px;",
                          strong("This research demonstrates that adaptive feature selection significantly improves fault detection 
                          performance for bearings and gears connected to brushless DC motors."), " The integrated methodology combining 
                          minimum redundancy maximum relevance principles with PCA dimensionality reduction and SVM classification achieves 
                          excellent results across multiple test scenarios. The state-of-the-art testing platform with 18-channel multi-sensor 
                          measurement capability and full control of time-varying conditions enables systematic fault induction and comprehensive 
                          data collection. The benchmark dataset being built, with detailed degradation parameters and testing protocols, 
                          addresses a critical need in the prognostics research community for well-documented public datasets. Experimental 
                          results validate that optimal features and channels vary by fault type and operating conditions, confirming the 
                          necessity of adaptive selection approaches rather than fixed feature sets. Future work on online implementation, 
                          remaining useful life estimation, and extended testing scenarios will enhance practical applicability of this 
                          methodology for industrial prognostics and health management systems."
                        )
                    ),
                    
                    div(class = "concept-box", style = "margin-top: 20px;",
                        h4("Key Takeaways:"),
                        tags$ol(
                          tags$li(strong("Adaptive selection essential:"), " Optimal features/channels vary by fault type and conditions"),
                          tags$li(strong("Multi-sensor integration:"), " Comprehensive sensor suite provides superior fault detection"),
                          tags$li(strong("Benchmark dataset value:"), " Public dataset with detailed parameters enables research advancement"),
                          tags$li(strong("Practical validation:"), " Achieved 83-99% accuracy across realistic time-varying conditions"),
                          tags$li(strong("Dimensionality reduction:"), " Information score metric effectively guides PCA component selection"),
                          tags$li(strong("Industrial applicability:"), " Framework ready for implementation in real-world prognostics systems")
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
                      "This research builds upon extensive prior work in fault detection, feature extraction, machine learning classification, 
                      and experimental methodologies for prognostics. The references span statistical signal processing, wavelet analysis, 
                      principal component analysis, support vector machines, minimum redundancy maximum relevance feature selection, and 
                      practical bearing and gear fault detection implementations."
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
                               h4("Datasets:"),
                               tags$ul(
                                 tags$li(strong("[1] Celaya et al.:"), " NASA IGBT Accelerated Aging Data Set"),
                                 tags$li(strong("[2] Saxena & Goebel:"), " CMAPSS Data Set for prognostics"),
                                 tags$li(strong("[3] Nectoux et al.:"), " PRONOSTIA platform for bearing degradation"),
                                 tags$li(strong("[4] Mahajan & Vasudevan:"), " RTCMA equipment setup for BLDCM testing")
                               )
                           )
                    ),
                    column(3,
                           div(class = "concept-box",
                               h4("Bearing Fault Detection:"),
                               tags$ul(
                                 tags$li(strong("[5] Da et al.:"), " Health monitoring for brushless PM machines"),
                                 tags$li(strong("[6] Sugumaran et al.:"), " Feature selection for roller bearing diagnostics"),
                                 tags$li(strong("[8] Zubizarreta & Vasudevan:"), " Experiment design for BLDCM health monitoring"),
                                 tags$li(strong("[9] Rojas & Nandi:"), " Fast detection with SVM"),
                                 tags$li(strong("[25] Carter:"), " Rolling element bearing testing method"))
                           )
                    ),
                    column(3,
                           div(class = "concept-box",
                               h4("Feature Extraction & ML:"),
                               tags$ul(
                                 tags$li(strong("[7] Yan & Shao:"), " SVM nonlinear classifier application"),
                                 tags$li(strong("[15] Samanta:"), " ANN and SVM with genetic algorithms"),
                                 tags$li(strong("[18] Xiaohang et al.:"), " Mahalanobis distance with mRMR"),
                                 tags$li(strong("[22] Corinha & Vapnik:"), " Support Vector Network theory"),
                                 tags$li(strong("[24] Peng et al.:"), " mRMR feature selection principles")
                               )
                           )
                    ),
                    column(3,
                           div(class = "concept-box",
                               h4("Gear & Wavelet Analysis:"),
                               tags$ul(
                                 tags$li(strong("[10] Baqqar et al.:"), " Data mining for gear condition monitoring"),
                                 tags$li(strong("[11] Yu et al.:"), " Wavelet analysis for planetary gearbox"),
                                 tags$li(strong("[13] Barszcz & Randall:"), " Spectral kurtosis for tooth crack"),
                                 tags$li(strong("[14] Paya et al.:"), " Wavelet-based ANN diagnostics"),
                                 tags$li(strong("[23] Supangat:"), " On-line condition monitoring")
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
  
  # Pipeline Diagram
  output$pipeline_diagram <- renderPlotly({
    stages <- c("Raw Data\n(18 channels)", "Filtering &\nNormalization", 
                "Feature\nExtraction", "mRMR\nSelection", "PCA\nReduction", "SVM\nClassification")
    x_pos <- 1:6
    
    plot_ly() %>%
      add_trace(x = x_pos, y = rep(0, 6), type = 'scatter', mode = 'markers+text',
                marker = list(size = 60, color = c('#3498db', '#00A39A', '#f39c12', '#9b59b6', '#e74c3c', '#008A82'),
                              line = list(color = 'white', width = 2)),
                text = stages,
                textposition = 'middle center',
                textfont = list(size = 10, color = 'white', family = 'Arial Black'),
                hoverinfo = 'text',
                hovertext = c(
                  "18 sensor channels sampled at 10 kHz",
                  "Butterworth filters + normalization",
                  "Statistical + wavelet features",
                  "Min redundancy max relevance",
                  "Dimensionality reduction",
                  "Binary classification"
                ),
                showlegend = FALSE) %>%
      add_annotations(
        x = x_pos[-6] + 0.5,
        y = rep(0, 5),
        text = "→",
        showarrow = FALSE,
        font = list(size = 30, color = '#2c3e50')
      ) %>%
      layout(
        xaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE, range = c(0.5, 6.5)),
        yaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE, range = c(-0.3, 0.3)),
        plot_bgcolor = 'rgba(0,0,0,0)',
        paper_bgcolor = 'rgba(0,0,0,0)',
        margin = list(t = 20, b = 20)
      )
  })
  
  # Bearing Current Plot
  output$bearing_current_plot <- renderPlotly({
    time <- seq(0, 2, length.out = 200)
    healthy <- 3 + 0.5*sin(2*pi*50*time) + rnorm(200, 0, 0.1)
    faulty <- 3.8 + 0.7*sin(2*pi*50*time) + 0.3*sin(2*pi*150*time) + rnorm(200, 0, 0.15)
    
    plot_ly() %>%
      add_trace(x = time, y = healthy, type = 'scatter', mode = 'lines',
                name = 'Healthy Bearing', line = list(color = '#00A39A', width = 2)) %>%
      add_trace(x = time, y = faulty, type = 'scatter', mode = 'lines',
                name = 'Faulty Bearing', line = list(color = '#e74c3c', width = 2)) %>%
      layout(
        title = list(text = "Phase A Current at 3000 RPM", font = list(size = 14)),
        xaxis = list(title = "Time (seconds)", gridcolor = '#ecf0f1'),
        yaxis = list(title = "Current (Amperes)", gridcolor = '#ecf0f1'),
        plot_bgcolor = '#f8f9fa',
        paper_bgcolor = 'white',
        legend = list(x = 0.7, y = 0.95)
      )
  })
  
  # Gear Vibration Plot
  output$gear_vibration_plot <- renderPlotly({
    time <- seq(0, 2, length.out = 200)
    healthy <- 0.002 + 0.001*sin(2*pi*25*time) + rnorm(200, 0, 0.0002)
    one_tooth <- 0.004 + 0.002*sin(2*pi*25*time) + 0.003*abs(sin(2*pi*8.33*time)) + rnorm(200, 0, 0.0004)
    two_teeth <- 0.006 + 0.003*sin(2*pi*25*time) + 0.005*abs(sin(2*pi*8.33*time)) + rnorm(200, 0, 0.0006)
    
    plot_ly() %>%
      add_trace(x = time, y = healthy, type = 'scatter', mode = 'lines',
                name = 'Healthy Gear', line = list(color = '#00A39A', width = 2)) %>%
      add_trace(x = time, y = two_teeth, type = 'scatter', mode = 'lines',
                name = '2 Teeth Missing', line = list(color = '#e74c3c', width = 2)) %>%
      layout(
        title = list(text = "Vibration at 1500 RPM", font = list(size = 14)),
        xaxis = list(title = "Time (seconds)", gridcolor = '#ecf0f1'),
        yaxis = list(title = "Vibration Amplitude", gridcolor = '#ecf0f1'),
        plot_bgcolor = '#f8f9fa',
        paper_bgcolor = 'white',
        legend = list(x = 0.7, y = 0.95)
      )
  })
  
  # Bearing Wavelet Plot
  output$bearing_wavelet_plot <- renderPlotly({
    time <- seq(0, 40, length.out = 100)
    healthy <- 400 + 50*sin(time/5) + rnorm(100, 0, 20)
    faulty <- 550 + 80*sin(time/5) + rnorm(100, 0, 30)
    
    plot_ly() %>%
      add_trace(x = time, y = healthy, type = 'scatter', mode = 'lines',
                name = 'Healthy Bearing', line = list(color = '#00A39A', width = 2),
                fill = 'tozeroy', fillcolor = 'rgba(0, 163, 154, 0.2)') %>%
      add_trace(x = time, y = faulty, type = 'scatter', mode = 'lines',
                name = 'Faulty Bearing', line = list(color = '#e74c3c', width = 2),
                fill = 'tozeroy', fillcolor = 'rgba(231, 76, 60, 0.2)') %>%
      layout(
        title = list(text = "Wavelet Variance - Phase A Current (Force Variation)", font = list(size = 14)),
        xaxis = list(title = "Time (minutes)", gridcolor = '#ecf0f1'),
        yaxis = list(title = "Wavelet Variance", gridcolor = '#ecf0f1'),
        plot_bgcolor = '#f8f9fa',
        paper_bgcolor = 'white',
        legend = list(x = 0.02, y = 0.98)
      )
  })
  
  # Gear Wavelet Plot
  output$gear_wavelet_plot <- renderPlotly({
    time <- seq(0, 40, length.out = 100)
    healthy <- 70 + 8*sin(time/5) + rnorm(100, 0, 3)
    faulty <- 85 + 12*sin(time/5) + rnorm(100, 0, 5)
    
    plot_ly() %>%
      add_trace(x = time, y = healthy, type = 'scatter', mode = 'lines',
                name = 'Healthy Gear', line = list(color = '#00A39A', width = 2),
                fill = 'tozeroy', fillcolor = 'rgba(0, 163, 154, 0.2)') %>%
      add_trace(x = time, y = faulty, type = 'scatter', mode = 'lines',
                name = 'Faulty Gear', line = list(color = '#e74c3c', width = 2),
                fill = 'tozeroy', fillcolor = 'rgba(231, 76, 60, 0.2)') %>%
      layout(
        title = list(text = "Wavelet Variance - Vibration (Speed Variation)", font = list(size = 14)),
        xaxis = list(title = "Time (minutes)", gridcolor = '#ecf0f1'),
        yaxis = list(title = "Wavelet Variance (×10⁻⁸)", gridcolor = '#ecf0f1'),
        plot_bgcolor = '#f8f9fa',
        paper_bgcolor = 'white',
        legend = list(x = 0.02, y = 0.98)
      )
  })
  
  # Feature Selection Table
  output$feature_selection_table <- renderDT({
    data <- data.frame(
      Test = c("B-Eload", "B-Speed", "B-Force", "G-1Teeth", "G-2Teeth"),
      Channels = c("All", "All", "All", "All", "All"),
      Features = c("s, 6m, r, wm", "m, v, s, r", "v, s, p, wm", "m, k, 6m, r, wv", "m, v, s, k, r, wv"),
      Accuracy = c("91.73%", "83.02%", "93.39%", "86.87%", "96.74%")
    )
    
    datatable(data, 
              options = list(
                pageLength = 10,
                dom = 't',
                columnDefs = list(list(className = 'dt-center', targets = "_all"))
              ),
              rownames = FALSE) %>%
      formatStyle(columns = c(1:4), fontSize = '14px') %>%
      formatStyle('Accuracy',
                  background = styleColorBar(c(80, 100), '#00A39A'),
                  backgroundSize = '95% 80%',
                  backgroundRepeat = 'no-repeat',
                  backgroundPosition = 'center')
  })
  
  # Channel Selection Table
  output$channel_selection_table <- renderDT({
    data <- data.frame(
      Test = c("B-Eload", "B-Speed", "B-Force", "G-1Teeth", "G-2Teeth"),
      Features = c("m, v, s, k, wr", "m, v, s, k, wr", "m, v, s, k, wr", "m, v, s, k, wr", "m, v, s, k, wr"),
      Channels = c("VAG, IA, F, SP, TM", "VG, SP, T, L, SP, VY", "VAB, IA, TM, SP", 
                   "VAG, SP, TM, VX", "VAB, SP, TM, H, VX"),
      Accuracy = c("96.34%", "90.94%", "92.29%", "85.12%", "96.42%")
    )
    
    datatable(data, 
              options = list(
                pageLength = 10,
                dom = 't',
                columnDefs = list(list(className = 'dt-center', targets = "_all"))
              ),
              rownames = FALSE) %>%
      formatStyle(columns = c(1:4), fontSize = '14px') %>%
      formatStyle('Accuracy',
                  background = styleColorBar(c(80, 100), '#3498db'),
                  backgroundSize = '95% 80%',
                  backgroundRepeat = 'no-repeat',
                  backgroundPosition = 'center')
  })
  
  # PCA Elements Plot
  output$pca_elements_plot <- renderPlotly({
    zeta <- seq(0.84, 1.0, length.out = 50)
    
    # Different curves for each test
    b_eload <- 2 + 30 * (zeta - 0.84)^1.5
    b_speed <- 2 + 32 * (zeta - 0.84)^1.5
    b_force <- 3 + 28 * (zeta - 0.84)^1.5
    g_1teeth <- 2 + 35 * (zeta - 0.84)^1.5
    g_2teeth <- 1 + 25 * (zeta - 0.84)^1.5
    
    plot_ly() %>%
      add_trace(x = zeta, y = b_eload, type = 'scatter', mode = 'lines',
                name = 'B-Eload', line = list(color = '#3498db', width = 2)) %>%
      add_trace(x = zeta, y = b_speed, type = 'scatter', mode = 'lines',
                name = 'B-Speed', line = list(color = '#00A39A', width = 2)) %>%
      add_trace(x = zeta, y = b_force, type = 'scatter', mode = 'lines',
                name = 'B-Force', line = list(color = '#f39c12', width = 2)) %>%
      add_trace(x = zeta, y = g_1teeth, type = 'scatter', mode = 'lines',
                name = 'G-1Teeth', line = list(color = '#e74c3c', width = 2, dash = 'dash')) %>%
      add_trace(x = zeta, y = g_2teeth, type = 'scatter', mode = 'lines',
                name = 'G-2Teeth', line = list(color = '#9b59b6', width = 2, dash = 'dash')) %>%
      layout(
        xaxis = list(title = "Information Index (ζ)", gridcolor = '#ecf0f1'),
        yaxis = list(title = "PCA Elements Generated", gridcolor = '#ecf0f1'),
        plot_bgcolor = '#f8f9fa',
        paper_bgcolor = 'white',
        legend = list(x = 0.02, y = 0.98)
      )
  })
  
  # PCA Accuracy Table
  output$pca_accuracy_table <- renderDT({
    data <- data.frame(
      Test = c("B-Eload", "B-Eload", "B-Eload",
               "B-Speed", "B-Speed", "B-Speed",
               "B-Force", "B-Force", "B-Force",
               "G-1Teeth", "G-1Teeth", "G-1Teeth",
               "G-2Teeth", "G-2Teeth", "G-2Teeth"),
      Features = rep(c(10, 20, 30), 5),
      Zeta = rep(c(0.94, 0.96, 0.97), 5),
      PCA_Elements = c(4, 9, 12, 5, 9, 12, 6, 11, 16, 5, 12, 17, 4, 7, 13),
      Mean_Accuracy = c(73.37, 97.40, 99.35, 95.45, 96.75, 97.40, 91.16, 94.21, 99.35,
                        77.27, 96.75, 99.35, 52.59, 91.16, 90.25),
      Std_Dev = c(2.47, 2.97, 3.80, 2.15, 3.02, 3.53, 2.85, 2.93, 3.35,
                  2.74, 3.31, 3.80, 3.03, 3.39, 3.75)
    )
    
    datatable(data, 
              colnames = c("Test Type", "Features #", "ζ", "PCA Elements", "Mean Accuracy (%)", "Std Dev (%)"),
              options = list(
                pageLength = 15,
                dom = 'tp',
                columnDefs = list(list(className = 'dt-center', targets = "_all"))
              ),
              rownames = FALSE) %>%
      formatStyle(columns = c(1:6), fontSize = '13px') %>%
      formatRound(columns = c('Zeta'), digits = 2) %>%
      formatRound(columns = c('Mean_Accuracy', 'Std_Dev'), digits = 2) %>%
      formatStyle('Mean_Accuracy',
                  background = styleColorBar(c(50, 100), '#00A39A'),
                  backgroundSize = '95% 80%',
                  backgroundRepeat = 'no-repeat',
                  backgroundPosition = 'center')
  })
  
  # References Table
  output$ref_table <- renderDT({
    refs <- data.frame(
      No = 1:26,
      Authors = c(
        "Celaya J., Wysocki P., Goebel K.",
        "Saxena A., Goebel K.",
        "Nectoux P., Gouriveau R., Medjaher K., et al.",
        "Mahajan A., Vasudevan S.",
        "Da Y., Shi X., Krishnamurthy M.",
        "Sugumaran V., Muralidharan V., Ramachandran K.",
        "Yan Y., Shao H.",
        "Zubizarreta-Rodriguez J.F., Vasudevan S.",
        "Rojas A., Nandi A.",
        "Baqqar M., Ahmed M., Gu F.",
        "Yu J., Yip L., Makis V.",
        "Liu L., Yang Y., Li Z., Yu W.",
        "Barszcz T., Randall R.",
        "Paya B., Esat I., Badi M.",
        "Samanta B.",
        "Huimin C., Rong X.",
        "Liao W., Wang Y., Pan E.",
        "Xiaohang J., Eden W., Cheng L., Pecht M.",
        "Pan M., Qian S., Lei L., Zhou X.",
        "Liao G., Shi T., Xuan J.",
        "Ramasso E., Gouriveau R.",
        "Corinha C., Vapnik V.",
        "Supangat R.",
        "Peng H., Long F., Ding C.",
        "Carter D.",
        "Maxon Motor"
      ),
      Year = c(2009, 2008, 2012, 2013, 2011, 2007, 2002, 2013, 2006, 2011,
               2010, 2011, 2009, 1997, 2004, 2011, 2012, 2012, 2005, 2005,
               2010, 1995, 2008, 2005, 1995, 2013),
      Title = c(
        "IGBT Accelerated Aging Data Set",
        "C-MAPSS Data Set",
        "PRONOSTIA: Experimental Platform for Bearings Degradation Tests",
        "RTCMA Equipment List for Health Monitoring of BLDCM",
        "Health Monitoring, Fault Diagnosis for Brushless PM Machines",
        "Feature Selection Using Decision Tree for Roller Bearing Diagnostics",
        "Application of SVM Nonlinear Classifier to Fault Diagnostics",
        "Experiment Design and Data Analysis for Health Monitoring of BLDCM",
        "Practical Scheme for Fast Detection of Bearing Faults Using SVM",
        "Data Mining for Gear Condition Monitoring",
        "Wavelet Analysis with Time-Synchronous Averaging of Planetary Gearbox",
        "Condition Monitoring for Helicopter Main Gearbox Based on Wavelet",
        "Application of Spectral Kurtosis for Tooth Crack Detection",
        "ANN Based Fault Diagnostics Using Wavelet Transforms as Preprocessor",
        "Gear Fault Detection Using ANN and SVM with Genetic Algorithms",
        "Distributed Active Learning for Battery Health Management",
        "Single-Machine-Based Predictive Maintenance Model",
        "Health Monitoring of Cooling Fans Based on Mahalanobis Distance with mRMR",
        "Support Vector Data Description with Model Selector",
        "Feature Selection and Condition Monitoring of Gearbox Using SOM",
        "Prognostics in Switching Systems: Evidential Markovian Classification",
        "Support Vector Network",
        "On-line Condition Monitoring of Stator and Rotor Faults",
        "Feature Selection Based on Mutual Information: mRMR Criteria",
        "Rolling Element Bearing Condition Testing Method and Apparatus",
        "Program 2012/13 High Precision Drives and Systems"
      ),
      Category = c(
        "Dataset", "Dataset", "Dataset", "Platform", "BLDCM Fault Detection",
        "Bearing - Feature Selection", "Bearing - SVM", "BLDCM Testing", "Bearing - SVM",
        "Gear - Data Mining", "Gear - Wavelet", "Gear - Wavelet", "Gear - Spectral Analysis",
        "Gear - ANN/Wavelet", "Gear - ML", "Active Learning", "Predictive Maintenance",
        "Feature Selection", "Classification", "Feature Selection - SOM", "Prognostics",
        "SVM Theory", "Wavelet Analysis", "mRMR Theory", "Bearing Testing", "Equipment"
      ),
      stringsAsFactors = FALSE
    )
    
    datatable(refs,
              options = list(
                pageLength = 26,
                dom = 'Bfrtip',
                buttons = c('csv', 'excel'),
                scrollX = TRUE,
                columnDefs = list(
                  list(width = '5%', targets = 0),
                  list(width = '20%', targets = 1),
                  list(width = '8%', targets = 2),
                  list(width = '47%', targets = 3),
                  list(width = '20%', targets = 4)
                )
              ),
              rownames = FALSE,
              extensions = 'Buttons',
              class = 'cell-border stripe') %>%
      formatStyle(columns = c(1:5), fontSize = '13px', lineHeight = '1.5')
  })
  
  # Reference Category Chart
  output$ref_category_chart <- renderPlotly({
    categories <- c("Dataset" = 3, "Platform/Testing" = 3, "Bearing Fault" = 3,
                    "Gear Fault" = 5, "Feature Selection" = 4, "Classification/ML" = 4,
                    "Theory" = 3, "Equipment" = 1)
    
    plot_ly(labels = names(categories), values = as.numeric(categories), type = 'pie',
            marker = list(colors = c('#3498db', '#00A39A', '#f39c12', '#e74c3c', 
                                     '#9b59b6', '#2ecc71', '#34495e', '#95a5a6')),
            textinfo = 'label+percent',
            textposition = 'outside',
            hoverinfo = 'label+value+percent') %>%
      layout(
        title = list(text = "References by Category", font = list(size = 14)),
        showlegend = FALSE,
        paper_bgcolor = 'white',
        plot_bgcolor = 'white'
      )
  })
  
  # Reference Timeline Chart
  output$ref_timeline_chart <- renderPlotly({
    years <- c(1995, 1997, 2002, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013)
    counts <- c(2, 1, 1, 1, 3, 1, 1, 2, 2, 2, 4, 3, 3)
    
    plot_ly(x = years, y = counts, type = 'bar',
            marker = list(color = '#00A39A',
                          line = list(color = '#008A82', width = 1.5))) %>%
      layout(
        title = list(text = "Publications by Year", font = list(size = 14)),
        xaxis = list(title = "Year", gridcolor = '#ecf0f1', dtick = 2),
        yaxis = list(title = "Number of Publications", gridcolor = '#ecf0f1'),
        plot_bgcolor = '#f8f9fa',
        paper_bgcolor = 'white'
      )
  })
}

# Run the application
shinyApp(ui = ui, server = server)