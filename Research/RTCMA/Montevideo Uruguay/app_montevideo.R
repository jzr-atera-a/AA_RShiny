library(shiny)
library(shinydashboard)
library(plotly)
library(DT)
library(ggplot2)

# UI
ui <- dashboardPage(
  dashboardHeader(title = "Condition Monitoring of Brushless DC Motors"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Introduction", tabName = "intro", icon = icon("home")),
      menuItem("Related Work", tabName = "related", icon = icon("book")),
      menuItem("Experiment Design", tabName = "design", icon = icon("flask")),
      menuItem("Results & Classification", tabName = "results", icon = icon("chart-bar")),
      menuItem("Summary & Future Work", tabName = "summary", icon = icon("flag-checkered")),
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
                          "This research introduces a novel multi-sensor measurement framework for condition monitoring of brushless 
                          DC motors (BLDCMs) with bearings under non-stationary dynamic conditions. The work addresses critical challenges 
                          in predictive maintenance for industrial machinery, where catastrophic failures can have significant safety, 
                          environmental, and economic consequences. Unlike traditional condition-based maintenance that responds after 
                          failure occurrence, this research focuses on prognosis—using statistical and signal analysis approaches to enable 
                          effective predictive maintenance before failures happen. A key innovation is the comprehensive multi-sensor approach 
                          incorporating 18 measurement channels including voltage, current, vibration, temperature, sound, torque, and force 
                          sensors. This enables more accurate failure detection compared to single-sensor approaches. The experimental platform 
                          tests BLDCMs under well-defined non-stationary conditions where parameters like rotating speed and external forces 
                          vary over time, better representing real-world operating scenarios. The research produces a public benchmark dataset 
                          with extensive failure scenarios that will be unique compared to existing datasets. Supervised learning classifiers 
                          including back-propagation neural networks and support vector machines are employed to identify fault states. The 
                          work is oriented toward maximizing the lifecycle of industrial machinery through reliable behavior classification, 
                          preventing catastrophic failures before they occur. This research bridges the gap between theoretical fault detection 
                          methods and practical industrial applications by providing detailed testing protocols, comprehensive sensor data, 
                          and validated classification approaches for BLDCM health monitoring."
                        )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Research Motivation", status = "primary", solidHeader = TRUE,
                    column(6,
                           div(class = "concept-box",
                               h4("Industrial Challenges:"),
                               tags$ul(
                                 tags$li(strong("Safety Standards:"), " Preventing catastrophic failures that endanger personnel"),
                                 tags$li(strong("Asset Optimization:"), " Maximizing equipment lifecycle and operational efficiency"),
                                 tags$li(strong("Environmental Protection:"), " Preventing environmental damage from equipment failures"),
                                 tags$li(strong("Ubiquity of Rotatory Machinery:"), " Electric motors fail across multiple industries"),
                                 tags$li(strong("External Conditions & Fatigue:"), " Failures caused by operating conditions and wear")
                               )
                           ),
                           
                           div(class = "highlight-box",
                               h4("Why Brushless DC Motors?"),
                               p(class = "description-text",
                                 "BLDCMs are selected due to their multi-phase similarity to AC induction motors while maintaining 
                                 safety compliance with Workplace Health and Safety (WHS) standards through DC operation. This allows 
                                 research findings to transfer to broader motor types while ensuring safe laboratory conditions."
                               )
                           )
                    ),
                    column(6,
                           div(class = "concept-box",
                               h4("Research Gaps Addressed:"),
                               tags$ul(
                                 tags$li(strong("Limited Public Datasets:"), " Few reliable datasets demonstrate machinery under various conditions"),
                                 tags$li(strong("Incomplete Documentation:"), " Existing datasets lack detailed degradation parameters"),
                                 tags$li(strong("Stationary Assumptions:"), " Most research assumes constant operating conditions"),
                                 tags$li(strong("Single-Sensor Limitations:"), " Traditional approaches use limited measurement channels"),
                                 tags$li(strong("Replication Challenges:"), " Testing settings not sufficiently detailed for reproduction")
                               )
                           ),
                           
                           div(class = "concept-box",
                               h4("Non-Stationary Dynamic Conditions:"),
                               p(class = "description-text",
                                 strong("Definition:"), " Physical settings such as rotating speed and external forces that vary over 
                                 time during BLDCM operation. This contrasts with traditional stationary testing where parameters remain 
                                 constant, better representing real-world operating scenarios where conditions change continuously."
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Research Contributions", status = "success", solidHeader = TRUE,
                    p(class = "description-text",
                      "This work makes several significant contributions to the field of predictive maintenance and equipment health 
                      monitoring. Each contribution addresses specific limitations in current approaches while providing practical tools 
                      for industrial application."
                    )
                )
              ),
              
              fluidRow(
                column(4,
                       box(width = 12, title = "Multi-Sensor Framework", status = "success", solidHeader = TRUE,
                           div(style = "text-align: center; padding: 20px;",
                               icon("network-wired", style = "font-size: 48px; color: #00A39A;"),
                               h4(style = "margin-top: 10px; color: #008A82;", "18 Measurement Channels")
                           ),
                           div(class = "concept-box",
                               p(class = "description-text",
                                 "Comprehensive measurement system incorporating voltage (9 channels), current (3 channels), 
                                 vibration (3-axis), temperature, sound pressure, torque, force, and speed sensors. This multi-modal 
                                 approach enables cross-validation and more robust fault detection compared to single-sensor methods."
                               )
                           )
                       )
                ),
                column(4,
                       box(width = 12, title = "Public Benchmark Dataset", status = "info", solidHeader = TRUE,
                           div(style = "text-align: center; padding: 20px;",
                               icon("database", style = "font-size: 48px; color: #3498db;"),
                               h4(style = "margin-top: 10px; color: #2980b9;", "Well-Defined Testing Conditions")
                           ),
                           div(class = "concept-box",
                               p(class = "description-text",
                                 "Creation of a unique public dataset containing key failure scenarios under non-stationary conditions. 
                                 Includes detailed testing protocols, degradation parameters, and comprehensive sensor data enabling 
                                 replication and advancing prognostics research across the community."
                               )
                           )
                       )
                ),
                column(4,
                       box(width = 12, title = "Machine Learning Classification", status = "warning", solidHeader = TRUE,
                           div(style = "text-align: center; padding: 20px;",
                               icon("brain", style = "font-size: 48px; color: #9b59b6;"),
                               h4(style = "margin-top: 10px; color: #8e44ad;", "Supervised Learning Approaches")
                           ),
                           div(class = "concept-box",
                               p(class = "description-text",
                                 "Implementation and validation of back-propagation neural networks and support vector machines for 
                                 fault state identification. Demonstrates classification accuracy improvements through multi-sensor 
                                 integration and optimal feature selection from time and frequency domain analysis."
                               )
                           )
                       )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Experimental Platform", status = "info", solidHeader = TRUE,
                    column(6,
                           h4("Platform Components:"),
                           div(class = "concept-box",
                               tags$ul(
                                 tags$li(strong("Motor:"), " 17.5 turn BLDCM with Hall sensor (Turnigy TrackStar)"),
                                 tags$li(strong("Bearing:"), " NSK 10mm bearing with 7 balls"),
                                 tags$li(strong("Force Load Cell:"), " Measures perpendicular force on shaft"),
                                 tags$li(strong("Flexible Coupling:"), " Connects motor to load system"),
                                 tags$li(strong("Data Acquisition:"), " NI PXIe chassis with multiple modules"),
                                 tags$li(strong("Controller:"), " Maxon Motor controller for speed regulation"),
                                 tags$li(strong("Electronic Load:"), " Applies axial load to motor"),
                                 tags$li(strong("Sampling Rate:"), " Up to 50,000 samples/second per channel")
                               )
                           )
                    ),
                    column(6,
                           h4("Key Design Features:"),
                           div(class = "concept-box",
                               tags$ul(
                                 tags$li(strong("Non-Invasive:"), " Quick motor replacement without sensor reconfiguration"),
                                 tags$li(strong("Extensible:"), " Designed for additional testing scenarios"),
                                 tags$li(strong("User-Friendly:"), " Minimal customization required for operation"),
                                 tags$li(strong("Comprehensive:"), " Integrates mechanical, electrical, and acoustic measurements"),
                                 tags$li(strong("Controlled:"), " Three independently controllable variables (speed, axial load, force)"),
                                 tags$li(strong("Safety Compliant:"), " Meets WHS standards through DC operation"),
                                 tags$li(strong("Reproducible:"), " Detailed documentation enables replication")
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
                          "This section reviews the state-of-the-art in BLDCM condition monitoring, bearing fault detection, and 
                          prognostics research. Bearing-related failures are identified as the most frequent cause of BLDCM failures, 
                          motivating focused research on bearing health monitoring. Various signature extraction and analysis methods 
                          are examined, including magnetic flux density monitoring, stator current signature analysis, and phase-current 
                          monitoring for detecting turn-to-turn failures from heating. The review highlights cost-effective techniques 
                          using FFT analysis of rotor bearing tests to detect harmonics caused by unbalanced loads and shaft misalignments. 
                          Artificial neural networks have been applied to detect stator insulation faults from voltage and current measurements, 
                          though most approaches assume stationary operating conditions. This represents a significant limitation as 
                          real-world machinery often operates under time-varying conditions. The work by Rajagopalan on monitoring load 
                          and bearing faults under non-stationary conditions demonstrates the feasibility of current-based detection 
                          techniques during transient operations, using time-frequency methods, Hidden Markov Models, and time-series 
                          approaches. Various signal analysis methods based on frequency sidebands, harmonics, and RMS vibration are 
                          discussed for handling time-variant conditions. The review emphasizes the correlation between phase voltage, 
                          current measurements, and multi-sensor data including vibrations and noise. A key insight is that while vibration-based 
                          diagnostics provides valuable information, it requires expensive dedicated accelerometers, whereas current-based 
                          techniques offer more cost-effective alternatives. This literature review establishes the foundation for the 
                          multi-sensor approach and non-stationary testing methodology developed in this research."
                        )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Bearing Fault Detection Methods", status = "info", solidHeader = TRUE,
                    column(4,
                           div(class = "concept-box",
                               h4("Magnetic Flux Density (Φ) Monitoring:"),
                               p(class = "description-text",
                                 "Signature extraction based on magnetic flux density variations to detect mechanical faults linked 
                                 with bearings. Changes in Φ indicate arising mechanical faults, enabling prediction of potential 
                                 failures through continuous monitoring."
                               ),
                               
                               h4(style = "margin-top: 15px;", "Key Advantage:"),
                               tags$ul(
                                 tags$li("Non-invasive measurement"),
                                 tags$li("Early fault detection capability"),
                                 tags$li("Sensitive to mechanical degradation")
                               )
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h4("Stator Current Signature Analysis:"),
                               p(class = "description-text",
                                 "Monitoring of phase-currents to detect bearing faults in induction motors and BLDCMs. Also used 
                                 to identify turn-to-turn failures caused by heating—when turns drastically modify their resistance 
                                 due to overheating, leading to turn-to-turn shortcuts."
                               ),
                               
                               h4(style = "margin-top: 15px;", "Detection Mechanisms:"),
                               tags$ul(
                                 tags$li("Current harmonic analysis"),
                                 tags$li("Resistance change detection"),
                                 tags$li("Phase imbalance identification")
                               )
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h4("FFT-Based Harmonic Detection:"),
                               p(class = "description-text",
                                 "Cost-effective technique using Fast Fourier Transform on rotor bearing tests to detect harmonics 
                                 in current caused by unbalanced loads and shaft misalignments. Current RMS increases with magnitude 
                                 of angular and linear shaft deviation."
                               ),
                               
                               h4(style = "margin-top: 15px;", "Detected Conditions:"),
                               tags$ul(
                                 tags$li("Unbalanced loads"),
                                 tags$li("Shaft misalignment"),
                                 tags$li("Angular deviations"),
                                 tags$li("Bearing wear patterns")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Machine Learning for Fault Detection", status = "success", solidHeader = TRUE,
                    column(6,
                           h4("Artificial Neural Networks (ANNs):"),
                           div(class = "concept-box",
                               p(class = "description-text",
                                 "ANNs trained with voltage and current measurements for detecting stator insulation faults, including 
                                 those derived from heat. However, traditional ANN approaches face limitations:"
                               ),
                               
                               div(class = "highlight-box",
                                   h5("Limitations:"),
                                   tags$ul(
                                     tags$li(strong("Stationary Assumptions:"), " Learning often based on time-invariant conditions"),
                                     tags$li(strong("Discrimination Challenges:"), " Difficult to separate inherent electrical measurements 
                                             from fault signatures under varying conditions"),
                                     tags$li(strong("Adaptation Issues:"), " Algorithms become inaccurate when physical conditions change over time"),
                                     tags$li(strong("Retraining Requirements:"), " Need periodic retraining for non-stationary environments")
                                   )
                               ),
                               
                               p(class = "description-text", style = "margin-top: 10px;",
                                 strong("This Research's Approach:"), " Evaluates fault-leading behaviors with time-varying conditions 
                                 (rotating speed and load) to overcome these limitations."
                               )
                           )
                    ),
                    column(6,
                           h4("Support Vector Machines (SVMs):"),
                           div(class = "concept-box",
                               p(class = "description-text",
                                 "SVMs offer advantages over ANNs for fault diagnostics due to structural risk minimization rather 
                                 than empirical risk minimization, preventing overfitting and enabling better generalization."
                               ),
                               
                               h5("SVM Advantages:"),
                               tags$ul(
                                 tags$li(strong("Overfitting Prevention:"), " Structural risk minimization avoids overtraining"),
                                 tags$li(strong("High-Dimensional Data:"), " Effectively models complex, multi-sensor datasets"),
                                 tags$li(strong("Better Generalization:"), " More accurate function modeling than ANNs"),
                                 tags$li(strong("Proven Applications:"), " Successfully used in bearing and gear prognostics")
                               ),
                               
                               div(class = "math-formula",
                                   h5("SVM Optimization Problem:"),
                                   withMathJax("$$\\min_{w,b,\\xi} W^TW + C\\sum_{i=1}^{l}\\xi_i$$"),
                                   withMathJax("$$\\text{subject to: } y_i(W^T\\phi(X_i)+b) \\geq 1-\\xi_i, \\xi_i \\geq 0$$")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Non-Stationary Condition Monitoring", status = "warning", solidHeader = TRUE,
                    p(class = "description-text",
                      "Monitoring under non-stationary (time-variant) conditions represents a significant advancement over traditional 
                      stationary approaches. Rajagopalan's work demonstrates that faults in electromechanical devices can be detected 
                      by monitoring voltage and current even during transient operations."
                    ),
                    
                    column(4,
                           div(class = "concept-box",
                               h4("Signal Analysis Methods:"),
                               tags$ul(
                                 tags$li(strong("Time-Frequency Methods:"), " Capture temporal evolution of frequency content"),
                                 tags$li(strong("Hidden Markov Models:"), " Model temporal sequences and state transitions"),
                                 tags$li(strong("Time-Series Methods:"), " Analyze temporal patterns and trends"),
                                 tags$li(strong("RMS Quantification:"), " Root mean square metrics aid fault detection"),
                                 tags$li(strong("Spectral Analysis:"), " Frequency domain characterization of faults")
                               )
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h4("Detection Metrics:"),
                               tags$ul(
                                 tags$li(strong("Frequency Sidebands:"), " Indicate modulation from bearing defects"),
                                 tags$li(strong("Harmonics:"), " Reflect mechanical and electrical imbalances"),
                                 tags$li(strong("RMS Vibration:"), " Overall vibration energy indicator"),
                                 tags$li(strong("Kurtosis:"), " Statistical measure of impulsive events"),
                                 tags$li(strong("Mean Values:"), " Baseline drift indicators")
                               )
                           )
                    ),
                    column(4,
                           div(class = "highlight-box",
                               h4("Advantage Over Vibration-Based Diagnostics:"),
                               p(class = "description-text",
                                 "Current-based detection techniques offer cost-effective alternatives to vibration-based approaches 
                                 that require expensive dedicated accelerometers. However, this research demonstrates that combining 
                                 multiple sensor modalities provides the most robust fault detection."
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
                                 tags$li(strong("Multi-Sensor Integration:"), " Extends beyond single-modality approaches by 
                                         correlating electrical, mechanical, acoustic, and thermal measurements"),
                                 tags$li(strong("Non-Stationary Testing:"), " Implements time-varying conditions (speed, force) 
                                         rather than stationary operation"),
                                 tags$li(strong("Comprehensive Documentation:"), " Provides detailed testing protocols enabling replication"),
                                 tags$li(strong("Public Dataset:"), " Creates benchmark data with extensive failure scenarios"),
                                 tags$li(strong("Classifier Comparison:"), " Validates both ANN and SVM approaches under consistent conditions")
                               )
                           )
                    ),
                    column(6,
                           h4("Novel Contributions:"),
                           div(class = "concept-box",
                               tags$ul(
                                 tags$li(strong("18-Channel Measurement:"), " Most comprehensive sensor suite in public bearing datasets"),
                                 tags$li(strong("Well-Defined Degradation:"), " Precise tracking of failure progression over 4.5 hours"),
                                 tags$li(strong("Non-Invasive Design:"), " Platform enables rapid testing of multiple motors"),
                                 tags$li(strong("Feature Extraction Framework:"), " Systematic approach to time and frequency domain features"),
                                 tags$li(strong("Validated Under Real Conditions:"), " Multiple motors tested to failure with repeatable protocols")
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
                          "This section details the comprehensive experimental methodology developed for condition monitoring of BLDCMs 
                          under non-stationary conditions. The testing apparatus integrates mechanical components, multi-sensor measurements, 
                          data acquisition systems, and analysis software into a cohesive platform. The 17.5 turn BLDCM manufactured with 
                          Hall sensor by Turnigy TrackStar serves as the motor under test, selected for its representative characteristics 
                          and availability for multiple test replicates. A key design principle is non-invasive measurement allowing quick 
                          motor replacement without sensor reconfiguration, ensuring platform extensibility to complex testing scenarios 
                          with minimal customization. The force load cell measures perpendicular force applied to the motor shaft for bearing 
                          stress testing, which is progressively increased to create accelerated failure conditions. The experimental design 
                          emphasizes data quality through high-fidelity acquisition: 18 measurement channels sampled at rates up to 50,000 
                          samples per second capture comprehensive system behavior. Three independently controllable variables—rotational 
                          speed (RPM), axial load, and perpendicular force—enable precise experimental control. The bearing test protocol 
                          increases perpendicular force over time while maintaining constant speed, creating non-stationary conditions that 
                          better represent real-world operating scenarios. Signal processing includes second-order Butterworth filtering: 
                          10 kHz cutoff for voltage/current removes motor driver switching effects, while 2-10 kHz bandpass filtering for 
                          vibration channels captures bearing-related frequency content. Feature extraction computes RMS, kurtosis, and mean 
                          values across all channels, providing input vectors for machine learning classifiers. The methodology produces 
                          a validated, reproducible framework for BLDCM health monitoring research."
                        )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Testing Platform Architecture", status = "info", solidHeader = TRUE,
                    column(4,
                           h4("Mechanical Components:"),
                           div(class = "concept-box",
                               tags$ul(
                                 tags$li(strong("BLDCM:"), " 17.5 turn motor with Hall sensor"),
                                 tags$li(strong("Bearing:"), " NSK 10mm, 7-ball bearing"),
                                 tags$li(strong("Flexible Coupling:"), " Connects motor to load system"),
                                 tags$li(strong("Force Load Cell:"), " Tension/compression sensor"),
                                 tags$li(strong("Custom Bearing Holder:"), " Precise force application"),
                                 tags$li(strong("Reaction Torque Sensor:"), " Measures output torque"),
                                 tags$li(strong("BLDC Generator:"), " Provides controlled loading")
                               )
                           )
                    ),
                    column(4,
                           h4("Sensing Equipment:"),
                           div(class = "concept-box",
                               tags$ul(
                                 tags$li(strong("Voltage Sensors (9):"), " Phase-to-ground (3), phase-to-phase (3), supply (3)"),
                                 tags$li(strong("Current Sensors (3):"), " Shunt resistors per phase"),
                                 tags$li(strong("3D Accelerometer:"), " X, Y, Z vibration measurement"),
                                 tags$li(strong("Microphone:"), " Sound pressure level"),
                                 tags$li(strong("RTD Sensor:"), " Temperature monitoring"),
                                 tags$li(strong("Hall Sensor:"), " Motor speed (RPM)"),
                                 tags$li(strong("Load Cell:"), " Perpendicular force on bearing")
                               )
                           )
                    ),
                    column(4,
                           h4("Control & Acquisition:"),
                           div(class = "concept-box",
                               tags$ul(
                                 tags$li(strong("NI PXIe Chassis:"), " Data acquisition platform"),
                                 tags$li(strong("Multiple Modules:"), " Voltage, current, sensor inputs"),
                                 tags$li(strong("Maxon Controller:"), " Motor speed regulation"),
                                 tags$li(strong("Electronic Load:"), " Axial load application"),
                                 tags$li(strong("Custom PCB:"), " Signal conditioning & integration"),
                                 tags$li(strong("Software:"), " LabVIEW-based control & logging"),
                                 tags$li(strong("Max Sample Rate:"), " 51,000 samples/s per channel")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Multi-Sensor Measurement System", status = "success", solidHeader = TRUE,
                    p(class = "description-text",
                      "The measurement system comprises 18 channels capturing electrical, mechanical, acoustic, and thermal phenomena. 
                      This multi-modal approach enables cross-validation and comprehensive fault characterization."
                    ),
                    
                    column(6,
                           div(class = "concept-box",
                               h4("Channel Breakdown:"),
                               tags$ol(
                                 tags$li("Voltage Phase A to GND"),
                                 tags$li("Voltage Phase B to GND"),
                                 tags$li("Voltage Phase C to GND"),
                                 tags$li("Voltage Phase A-B"),
                                 tags$li("Voltage Phase B-C"),
                                 tags$li("Voltage Phase C-A"),
                                 tags$li("Current Phase A (shunt resistor)"),
                                 tags$li("Current Phase B (shunt resistor)"),
                                 tags$li("Current Phase C (shunt resistor)"),
                                 tags$li("Vibration X-axis (accelerometer)"),
                                 tags$li("Vibration Y-axis (accelerometer)"),
                                 tags$li("Vibration Z-axis (accelerometer)"),
                                 tags$li("Sound pressure (microphone)"),
                                 tags$li("Temperature (RTD)"),
                                 tags$li("Motor speed (Hall sensor)"),
                                 tags$li("Reaction torque (torque sensor)"),
                                 tags$li("Perpendicular force (load cell)"),
                                 tags$li("Power supply voltage")
                               )
                           )
                    ),
                    column(6,
                           div(class = "concept-box",
                               h4("Sensor Integration Philosophy:"),
                               p(class = "description-text",
                                 "The data acquisition system design prioritizes user focus on analysis rather than signal conditioning. 
                                 All sensors integrate through the NI PXIe chassis with appropriate conditioning circuits on the custom PCB."
                               ),
                               
                               h5(style = "margin-top: 15px;", "Key Design Decisions:"),
                               tags$ul(
                                 tags$li(strong("Differential Voltage:"), " Both single-ended and differential measurements for robustness"),
                                 tags$li(strong("Shunt Resistors:"), " Precision current measurement without expensive Hall effect sensors"),
                                 tags$li(strong("Accelerometer Placement:"), " Next to bearing for maximum sensitivity"),
                                 tags$li(strong("RTD Selection:"), " High accuracy temperature measurement"),
                                 tags$li(strong("Microphone Position:"), " Captures acoustic emissions from bearing"),
                                 tags$li(strong("Synchronous Sampling:"), " All channels time-aligned for correlation analysis")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Bearing Test Protocol", status = "warning", solidHeader = TRUE,
                    column(4,
                           div(class = "concept-box",
                               h4("Test Objectives:"),
                               tags$ul(
                                 tags$li("Monitor operation while increasing perpendicular force"),
                                 tags$li("Perform accelerated wear from raceway stresses"),
                                 tags$li("Capture comprehensive sensor data during degradation"),
                                 tags$li("Identify signatures that intensify over time"),
                                 tags$li("Detect failure point with multiple sensors")
                               )
                           ),
                           
                           div(class = "math-formula",
                               h4("Controlled Variables:"),
                               withMathJax("$$\\text{Rotating Speed: } 2000 \\text{ RPM (constant)}$$"),
                               withMathJax("$$\\text{Axial Load: } 0 \\text{ N (constant)}$$"),
                               withMathJax("$$\\text{Perpendicular Force: } 360 \\to 464 \\text{ N (increasing)}$$")
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h4("Non-Stationary Scenario:"),
                               p(class = "description-text",
                                 "By progressively increasing perpendicular force over time while maintaining constant speed, a truly 
                                 non-stationary testing scenario is created. This better represents real-world conditions where bearing 
                                 stress accumulates gradually."
                               ),
                               
                               h5("Force Profile:"),
                               tags$ul(
                                 tags$li("Initial: 360 N"),
                                 tags$li("Gradual increase over 4.5 hours"),
                                 tags$li("Failure at: ~464 N"),
                                 tags$li("Increment rate: ~23 N/hour")
                               )
                           )
                    ),
                    column(4,
                           div(class = "highlight-box",
                               h4("Multiple Motor Testing:"),
                               p(class = "description-text",
                                 "Five BLDCMs of the same model were tested (one per experiment) to generate multiple datasets. 
                                 This enables:"),
                               tags$ul(
                                 tags$li("Statistical validation of findings"),
                                 tags$li("Training/testing dataset separation"),
                                 tags$li("Verification of repeatability"),
                                 tags$li("Assessment of inter-motor variability"),
                                 tags$li("Creation of comprehensive benchmark dataset")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Signal Processing Pipeline", status = "primary", solidHeader = TRUE,
                    column(6,
                           h4("Filtering Specifications:"),
                           div(class = "concept-box",
                               p(class = "description-text",
                                 "Raw data from 18 channels sampled at 50 kHz requires preprocessing before classification. 
                                 Software-based second-order Butterworth filters remove noise while preserving fault signatures."
                               ),
                               
                               div(class = "math-formula",
                                   h5("Voltage & Current Channels:"),
                                   p("Low-pass filter: 10 kHz cutoff"),
                                   p(strong("Rationale:"), " Remove BLDCM driver switching artifacts at 50 kHz"),
                                   
                                   h5("Vibration Channels:"),
                                   p("Band-pass filter: 2 kHz - 10 kHz"),
                                   p(strong("Rationale:"), " Capture bearing vibration energy content while rejecting low-frequency 
                                     mechanical noise and high-frequency electrical interference")
                               )
                           )
                    ),
                    column(6,
                           h4("Feature Extraction:"),
                           div(class = "concept-box",
                               p(class = "description-text",
                                 "Statistical features extracted from filtered signals provide informative inputs for machine learning 
                                 classifiers. Features computed over sliding windows of 8,192 data points."
                               ),
                               
                               div(class = "math-formula",
                                   h5("Extracted Features (per channel):"),
                                   
                                   p(strong("1. Root Mean Square (RMS):")),
                                   withMathJax("$$\\text{RMS} = \\sqrt{\\frac{1}{N}\\sum_{i=1}^{N}x_i^2}$$"),
                                   
                                   p(strong("2. Mean Value:")),
                                   withMathJax("$$\\mu = \\frac{1}{N}\\sum_{i=1}^{N}x_i$$"),
                                   
                                   p(strong("3. Kurtosis:")),
                                   withMathJax("$$\\text{Kurt} = \\frac{\\frac{1}{N}\\sum_{i=1}^{N}(x_i-\\mu)^4}{\\left(\\frac{1}{N}\\sum_{i=1}^{N}(x_i-\\mu)^2\\right)^2}$$"),
                                   
                                   p("Total features: 3 × 18 channels = 54-dimensional feature vector")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Data Processing Workflow", status = "info", solidHeader = TRUE,
                    p(class = "description-text",
                      "The complete data processing pipeline transforms raw sensor measurements into classified fault states through 
                      systematic stages."
                    ),
                    
                    column(3,
                           div(class = "concept-box",
                               h4("Stage 1: Acquisition"),
                               tags$ul(
                                 tags$li("18 channels sampled at 50 kHz"),
                                 tags$li("Analog-to-digital conversion"),
                                 tags$li("Time-synchronized capture"),
                                 tags$li("Continuous logging to disk"),
                                 tags$li("4.5 hours per experiment")
                               )
                           )
                    ),
                    column(3,
                           div(class = "concept-box",
                               h4("Stage 2: Filtering"),
                               tags$ul(
                                 tags$li("2nd order Butterworth filters"),
                                 tags$li("Channel-specific cutoffs"),
                                 tags$li("Zero-phase filtering"),
                                 tags$li("Artifact removal"),
                                 tags$li("Noise reduction")
                               )
                           )
                    ),
                    column(3,
                           div(class = "concept-box",
                               h4("Stage 3: Features"),
                               tags$ul(
                                 tags$li("Sliding window (8192 points)"),
                                 tags$li("RMS computation"),
                                 tags$li("Mean value extraction"),
                                 tags$li("Kurtosis calculation"),
                                 tags$li("54D feature vector")
                               )
                           )
                    ),
                    column(3,
                           div(class = "concept-box",
                               h4("Stage 4: Classification"),
                               tags$ul(
                                 tags$li("ANN or SVM training"),
                                 tags$li("Binary classification"),
                                 tags$li("Normal vs. Faulty"),
                                 tags$li("Cross-validation"),
                                 tags$li("Performance metrics")
                               )
                           )
                    )
                )
              )
      ),
      
      # Results Tab
      tabItem(tabName = "results",
              fluidRow(
                box(width = 12, title = "Results & Classification - Overview", status = "primary", solidHeader = TRUE,
                    div(class = "concept-box",
                        p(class = "description-text",
                          "This section presents comprehensive experimental results demonstrating the effectiveness of the multi-sensor 
                          monitoring framework for BLDCM bearing fault detection. Five BLDCMs were tested to failure under controlled 
                          non-stationary conditions: constant 2000 RPM rotation with progressively increasing perpendicular force from 
                          360N to 464N over approximately 4.5 hours. The high sampling rate of 50,000 samples per second across 18 channels 
                          generated rich datasets capturing the complete failure progression. Spectral analysis revealed noticeable changes 
                          in phase current signatures before and after failure, validating the measurement approach. Statistical features 
                          (RMS, kurtosis, mean values) extracted from all sensor signals reflected significant variations after failure 
                          compared to normal operation baselines. To validate the practical utility of the multi-sensor data, three dataset 
                          configurations were created: T1 with essential channels (force, speed, voltage, current), T2 adding mechanical 
                          sensors (torque, sound, temperature), and T3 incorporating all sensors including 3-axis vibration and power supply. 
                          Both back-propagation artificial neural networks and support vector machines were trained for binary classification 
                          (normal vs. faulty behavior). Results demonstrated that classification accuracy improved substantially with additional 
                          sensor channels: from 56-64% accuracy with T1 to 92-94% with T3 using 300 training vectors. The SVM consistently 
                          outperformed ANN by 2-4% across all configurations, attributed to structural risk minimization preventing overfitting. 
                          Variance in classification accuracy decreased with more sensors and training data, indicating more robust performance. 
                          The 4.5-hour test duration revealed temporal evolution of fault signatures: RMS current increasing, speed decreasing, 
                          torque declining, temperature rising, and vibration intensifying as bearing degradation progressed. These results 
                          conclusively demonstrate the inherent value of multi-sensor integration for reliable BLDCM fault detection."
                        )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Testing Conditions & Sampling", status = "info", solidHeader = TRUE,
                    column(4,
                           div(class = "concept-box",
                               h4("Experimental Parameters:"),
                               div(class = "math-formula",
                                   withMathJax("$$\\text{Rotational Speed: } 2000 \\text{ RPM}$$"),
                                   withMathJax("$$\\text{Axial Load: } 0 \\text{ N}$$"),
                                   withMathJax("$$\\text{Initial Force: } 360 \\text{ N}$$"),
                                   withMathJax("$$\\text{Final Force: } 464 \\text{ N}$$"),
                                   withMathJax("$$\\text{Test Duration: } 4.5 \\text{ hours}$$"),
                                   withMathJax("$$\\text{Number of Motors: } 5$$")
                               )
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h4("Sampling Rate Rationale:"),
                               p(class = "description-text",
                                 strong("Requirement:"), " Maximum 10ms time period to apply actions before failure propagation from 
                                 heat transfer that can damage electronic equipment."
                               ),
                               
                               div(class = "math-formula",
                                   withMathJax("$$\\text{Hardware Max: } 51{,}000 \\text{ samples/s}$$"),
                                   withMathJax("$$\\text{Selected Rate: } 50{,}000 \\text{ samples/s}$$"),
                                   withMathJax("$$\\text{Sample Period: } 20 \\mu\\text{s}$$"),
                                   withMathJax("$$\\text{Motor Period: } 30 \\text{ ms (2000 RPM)}$$")
                               )
                           )
                    ),
                    column(4,
                           div(class = "highlight-box",
                               h4("Failure Observations:"),
                               p(class = "description-text",
                                 "After approximately 480 minutes (8 hours) of testing with increasing perpendicular force:"
                               ),
                               tags$ul(
                                 tags$li(strong("Speed:"), " Decreased from 33.3 to 18 rev/s"),
                                 tags$li(strong("Torque:"), " Decreased significantly"),
                                 tags$li(strong("Sound:"), " Sound pressure decreased"),
                                 tags$li(strong("Vibration:"), " Vibration intensity decreased"),
                                 tags$li(strong("Temperature:"), " Continued increasing"),
                                 tags$li(strong("Current:"), " Phase currents increased")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Spectral Analysis Results", status = "success", solidHeader = TRUE,
                    column(6,
                           h4("Current Spectrum Changes:"),
                           div(class = "concept-box",
                               p(class = "description-text",
                                 "Fast Fourier Transform analysis of phase current signals revealed noticeable changes in frequency 
                                 content before and after bearing failure. This validates that electrical signatures reflect mechanical 
                                 degradation."
                               ),
                               
                               h5("Observed Changes:"),
                               tags$ul(
                                 tags$li(strong("Phase A:"), " Increased low-frequency content, additional harmonics"),
                                 tags$li(strong("Phase B:"), " Similar pattern to Phase A with slight phase shift"),
                                 tags$li(strong("Phase C:"), " Consistent spectral changes across all phases"),
                                 tags$li(strong("Frequency Range:"), " Changes most prominent 0-1000 Hz"),
                                 tags$li(strong("Magnitude:"), " Overall spectrum magnitude increased post-failure")
                               )
                           )
                    ),
                    column(6,
                           div(class = "concept-box",
                               h4("Feature Evolution Over Test:"),
                               p(class = "description-text",
                                 "Time-series plots of extracted features from 4.5-hour tests show clear trends indicating progressive 
                                 bearing degradation:"
                               ),
                               
                               tags$ul(
                                 tags$li(strong("Current RMS:"), " Steady increase from 5.4 to 6.6 A indicating higher resistance/load"),
                                 tags$li(strong("Voltage RMS:"), " Slight variations reflecting current-induced changes"),
                                 tags$li(strong("Perpendicular Force:"), " Controlled increase from 360 to 464 N over test duration"),
                                 tags$li(strong("Temperature:"), " Monotonic increase from 20°C to 60°C"),
                                 tags$li(strong("Hall Sensor:"), " Abrupt drop at failure from 33 to 18 Hz"),
                                 tags$li(strong("Torque:"), " Progressive decrease then sharp drop at failure"),
                                 tags$li(strong("Vibration:"), " Initial increase then decrease as bearing seized")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Dataset Configurations", status = "warning", solidHeader = TRUE,
                    p(class = "description-text",
                      "Three dataset configurations were created to systematically evaluate the contribution of different sensor modalities 
                      to classification accuracy. Each configuration includes all channels from previous tiers plus additional sensors."
                    ),
                    
                    column(4,
                           div(class = "concept-box",
                               h4("T1: Essential Channels"),
                               p(class = "description-text",
                                 "Baseline configuration including only channels commonly used in previous bearing fault studies:"
                               ),
                               tags$ul(
                                 tags$li("Perpendicular force (PF)"),
                                 tags$li("Hall sensor speed (Halls)"),
                                 tags$li("Voltage Phase A-Ground (VAG)"),
                                 tags$li("Voltage Phase B-Ground (VBG)"),
                                 tags$li("Voltage Phase C-Ground (VCG)"),
                                 tags$li("Current Phase A (IA)"),
                                 tags$li("Current Phase B (IB)"),
                                 tags$li("Current Phase C (IC)"),
                                 tags$li("Voltage Phase A-B (VAB)"),
                                 tags$li("Voltage Phase B-C (VBC)"),
                                 tags$li("Voltage Phase C-A (VCA)")
                               ),
                               p(strong("Total: 11 channels"))
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h4("T2: + Mechanical Sensors"),
                               p(class = "description-text",
                                 "Adds mechanical and acoustic measurements to T1 channels:"
                               ),
                               tags$ul(
                                 tags$li(strong("All T1 channels")),
                                 tags$li("Reaction Torque (T)"),
                                 tags$li("Sound Pressure (Ps)"),
                                 tags$li("Temperature (T)")
                               ),
                               p(strong("Total: 14 channels")),
                               
                               p(class = "description-text", style = "margin-top: 10px;",
                                 strong("Rationale:"), " Mechanical sensors capture bearing behavior more directly than electrical 
                                 measurements alone. Acoustic emissions and temperature provide early fault indicators."
                               )
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h4("T3: Full Sensor Suite"),
                               p(class = "description-text",
                                 "Complete multi-sensor configuration including all measurement channels:"
                               ),
                               tags$ul(
                                 tags$li(strong("All T2 channels")),
                                 tags$li("Power Supply (SP)"),
                                 tags$li("Vibration X-axis (AX)"),
                                 tags$li("Vibration Y-axis (AY)"),
                                 tags$li("Vibration Z-axis (AZ)")
                               ),
                               p(strong("Total: 18 channels")),
                               
                               p(class = "description-text", style = "margin-top: 10px;",
                                 strong("Hypothesis:"), " 3-axis vibration provides most direct bearing fault signatures, expected 
                                 to significantly improve classification accuracy."
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Classification Results", status = "primary", solidHeader = TRUE,
                    p(class = "description-text",
                      "Both Artificial Neural Networks (ANN) and Support Vector Machines (SVM) were trained for binary classification 
                      of motor health state. Feature vectors consisted of RMS, mean, and kurtosis values computed over 8,192-point 
                      windows, resulting in 54-dimensional vectors (3 features × 18 channels)."
                    ),
                    
                    column(6,
                           h4("ANN Configuration:"),
                           div(class = "concept-box",
                               div(class = "math-formula",
                                   h5("Architecture & Training:"),
                                   p("Activation function: Logistic regression"),
                                   withMathJax("$$c_m = \\frac{1}{1+e^{-z}}$$"),
                                   p("where ", withMathJax("$z = \\sum_{i=1}^{n}w_ia_i$")),
                                   
                                   p(strong("Training Parameters:")),
                                   tags$ul(
                                     tags$li("Stop criterion: MSE = ", withMathJax("$10^{-8}$")),
                                     tags$li("Maximum iterations: 4000"),
                                     tags$li("Algorithm: Back-propagation"),
                                     tags$li("Weight initialization: Random"),
                                     tags$li("Learning rate: Adaptive")
                                   )
                               )
                           )
                    ),
                    column(6,
                           h4("SVM Configuration:"),
                           div(class = "concept-box",
                               div(class = "math-formula",
                                   h5("Optimization Problem:"),
                                   withMathJax("$$\\min_{w,b,\\xi} W^TW + C\\sum_{i=1}^{l}\\xi_i$$"),
                                   
                                   p(strong("Subject to:")),
                                   withMathJax("$$y_i(W^T\\phi(X_i)+b) \\geq 1-\\xi_i$$"),
                                   withMathJax("$$\\xi_i \\geq 0$$"),
                                   
                                   p(strong("Configuration:")),
                                   tags$ul(
                                     tags$li("Kernel: Gaussian (RBF)"),
                                     tags$li("Penalty parameter C: Optimized via cross-validation"),
                                     tags$li("Binary classification: Normal vs. Faulty"),
                                     tags$li("Structural risk minimization prevents overfitting")
                                   )
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Performance Comparison", status = "success", solidHeader = TRUE,
                    p(class = "description-text",
                      "Classification accuracy and variance were evaluated across dataset configurations (T1, T2, T3) and training set 
                      sizes (100 vs. 300 vectors). Each experiment was repeated 5 times with different train/test splits."
                    ),
                    
                    column(6,
                           h4("Accuracy Results:"),
                           div(class = "concept-box",
                               h5("With 100 Training Vectors:"),
                               tags$ul(
                                 tags$li(strong("T1:"), " ANN: 56.1%, SVM: 64.1%"),
                                 tags$li(strong("T2:"), " ANN: 58.3%, SVM: 72.3%"),
                                 tags$li(strong("T3:"), " ANN: 82.1%, SVM: 83.8%")
                               ),
                               
                               h5("With 300 Training Vectors:"),
                               tags$ul(
                                 tags$li(strong("T1:"), " ANN: 62.9%, SVM: 76.2%"),
                                 tags$li(strong("T2:"), " ANN: 88.7%, SVM: 91.3%"),
                                 tags$li(strong("T3:"), " ANN: 91.5%, SVM: 93.5%")
                               ),
                               
                               div(class = "highlight-box", style = "margin-top: 10px;",
                                   p(strong("Key Finding:"), " Number of sensor channels more determinant than training set size 
                                     for classification accuracy.")
                               )
                           )
                    ),
                    column(6,
                           h4("Variance Analysis:"),
                           div(class = "concept-box",
                               h5("Variance with 100 Vectors:"),
                               tags$ul(
                                 tags$li(strong("T1:"), " ANN: 0.17, SVM: 0.21"),
                                 tags$li(strong("T2:"), " ANN: 0.14, SVM: 0.17"),
                                 tags$li(strong("T3:"), " ANN: 0.13, SVM: 0.14")
                               ),
                               
                               h5("Variance with 300 Vectors:"),
                               tags$ul(
                                 tags$li(strong("T1:"), " ANN: 0.09, SVM: 0.11"),
                                 tags$li(strong("T2:"), " ANN: 0.11, SVM: 0.14"),
                                 tags$li(strong("T3:"), " ANN: 0.11, SVM: 0.09")
                               ),
                               
                               div(class = "highlight-box", style = "margin-top: 10px;",
                                   p(strong("Key Finding:"), " Classification variance decreased with more channels and training data, 
                                     indicating more robust performance.")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Interactive Results Visualization", status = "info", solidHeader = TRUE,
                    column(6,
                           h4("Classifier Comparison:"),
                           plotlyOutput("accuracy_plot", height = "350px")
                    ),
                    column(6,
                           h4("Dataset Configuration Impact:"),
                           plotlyOutput("dataset_plot", height = "350px")
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Key Findings & Implications", status = "warning", solidHeader = TRUE,
                    column(4,
                           div(class = "concept-box",
                               h4("Multi-Sensor Value:"),
                               tags$ul(
                                 tags$li("T3 (18 channels) achieved 93.5% accuracy vs. 76.2% for T1 (11 channels)"),
                                 tags$li("Adding vibration sensors (T2→T3) provided largest accuracy improvement"),
                                 tags$li("Mechanical sensors crucial for bearing fault detection"),
                                 tags$li("Electrical measurements alone insufficient for reliable classification"),
                                 tags$li("Demonstrates inherent value of comprehensive sensor integration")
                               )
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h4("Classifier Performance:"),
                               tags$ul(
                                 tags$li("SVM consistently outperformed ANN by 2-4%"),
                                 tags$li("Structural risk minimization prevents overfitting"),
                                 tags$li("Better generalization with limited training data"),
                                 tags$li("Lower variance indicates more stable performance"),
                                 tags$li("Both classifiers benefited substantially from additional sensors")
                               )
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h4("Practical Implications:"),
                               tags$ul(
                                 tags$li("Multi-sensor approach justified by substantial accuracy gains"),
                                 tags$li("Investment in comprehensive instrumentation worthwhile"),
                                 tags$li("Dataset size less critical than sensor diversity"),
                                 tags$li("Results validate platform design and methodology"),
                                 tags$li("Benchmark dataset will enable community research advancement")
                               )
                           )
                    )
                )
              )
      ),
      
      # Summary Tab
      tabItem(tabName = "summary",
              fluidRow(
                box(width = 12, title = "Summary & Future Work - Overview", status = "primary", solidHeader = TRUE,
                    div(class = "concept-box",
                        p(class = "description-text",
                          "This research successfully demonstrates a novel multi-sensor measurement framework for condition monitoring 
                          of brushless DC motors under non-stationary dynamic conditions. The comprehensive experimental platform integrates 
                          18 measurement channels capturing electrical, mechanical, acoustic, and thermal phenomena, enabling robust fault 
                          detection superior to single-modality approaches. Five BLDCMs were systematically tested to failure under well-defined 
                          conditions: constant 2000 RPM rotation with progressively increasing perpendicular bearing force from 360N to 464N 
                          over 4.5 hours. High-fidelity data acquisition at 50 kHz per channel captured complete failure progression, producing 
                          a rich benchmark dataset for prognostics research. Signal processing through second-order Butterworth filtering and 
                          feature extraction (RMS, kurtosis, mean values) generated 54-dimensional feature vectors for machine learning 
                          classification. Both back-propagation artificial neural networks and support vector machines achieved excellent 
                          performance, with the full 18-channel configuration (T3) reaching 91.5% (ANN) and 93.5% (SVM) accuracy compared 
                          to just 62.9% (ANN) and 76.2% (SVM) with the baseline 11-channel configuration (T1). The SVM consistently outperformed 
                          ANN by 2-4% due to structural risk minimization preventing overfitting. Spectral analysis revealed clear changes in 
                          phase current signatures before and after failure, while temporal feature analysis showed progressive degradation 
                          signatures: increasing current, rising temperature, decreasing speed and torque. These results conclusively validate 
                          the multi-sensor approach for reliable BLDCM health monitoring. Future work will expand to gear and stator failures, 
                          implement dimensionality reduction and feature selection to optimize classifier performance, and make the complete 
                          benchmark dataset publicly available to advance the prognostics research community."
                        )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Research Summary", status = "success", solidHeader = TRUE,
                    column(6,
                           h4("Methodology Contributions:"),
                           div(class = "concept-box",
                               tags$ul(
                                 tags$li(strong("Multi-Sensor Framework:"), " Integrated 18-channel measurement system capturing 
                                         electrical, mechanical, acoustic, and thermal phenomena"),
                                 tags$li(strong("Non-Stationary Testing:"), " Time-varying conditions (increasing bearing force) 
                                         better represent real-world operations"),
                                 tags$li(strong("Comprehensive Documentation:"), " Detailed protocols enable replication and validation"),
                                 tags$li(strong("High-Fidelity Acquisition:"), " 50 kHz sampling captures complete fault signatures"),
                                 tags$li(strong("Systematic Feature Extraction:"), " RMS, kurtosis, mean values from time and frequency domains"),
                                 tags$li(strong("Classifier Comparison:"), " ANN vs. SVM evaluated under consistent conditions")
                               )
                           )
                    ),
                    column(6,
                           h4("Key Findings:"),
                           div(class = "concept-box",
                               tags$ul(
                                 tags$li(strong("Multi-Sensor Value:"), " 93.5% accuracy with 18 channels vs. 76.2% with 11 channels"),
                                 tags$li(strong("Vibration Critical:"), " 3-axis accelerometer provided largest accuracy improvement"),
                                 tags$li(strong("SVM Superiority:"), " Consistently outperformed ANN by 2-4% across configurations"),
                                 tags$li(strong("Spectral Signatures:"), " Clear FFT changes in phase currents indicate bearing faults"),
                                 tags$li(strong("Temporal Evolution:"), " Progressive degradation signatures captured over 4.5 hours"),
                                 tags$li(strong("Validated Platform:"), " Five motors tested to failure with repeatable results")
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Achievements", status = "info", solidHeader = TRUE,
                    p(class = "description-text",
                      "This work makes several significant achievements in the field of predictive maintenance and equipment health 
        monitoring. Each achievement addresses specific limitations in current approaches while providing practical tools 
        for industrial application."
                    )
                )
              ),
              
              fluidRow(
                column(3,
                       box(width = 12, status = "success", solidHeader = TRUE,
                           div(style = "text-align: center; padding: 15px; min-height: 120px;",
                               div(style = "font-size: 48px; font-weight: bold; color: #00A39A;", "93.5%"),
                               h4(style = "margin-top: 10px; color: #008A82;", "Classification Accuracy"),
                               p(style = "font-size: 14px; color: #666;", "(SVM, 18 channels)")
                           ),
                           div(class = "concept-box",
                               p(class = "description-text",
                                 "Achieved with full multi-sensor configuration (T3) and 300 training vectors, 
                   demonstrating excellent fault detection capability."
                               )
                           )
                       )
                ),
                column(3,
                       box(width = 12, status = "info", solidHeader = TRUE,
                           div(style = "text-align: center; padding: 15px; min-height: 120px;",
                               div(style = "font-size: 48px; font-weight: bold; color: #3498db;", "18"),
                               h4(style = "margin-top: 10px; color: #2980b9;", "Measurement Channels"),
                               p(style = "font-size: 14px; color: #666;", "Comprehensive System")
                           ),
                           div(class = "concept-box",
                               p(class = "description-text",
                                 "Most extensive sensor suite in public bearing fault datasets, enabling 
                   multi-modal fault characterization."
                               )
                           )
                       )
                ),
                column(3,
                       box(width = 12, status = "warning", solidHeader = TRUE,
                           div(style = "text-align: center; padding: 15px; min-height: 120px;",
                               div(style = "font-size: 48px; font-weight: bold; color: #9b59b6;", "5"),
                               h4(style = "margin-top: 10px; color: #8e44ad;", "Motors Tested"),
                               p(style = "font-size: 14px; color: #666;", "Test Replicates")
                           ),
                           div(class = "concept-box",
                               p(class = "description-text",
                                 "Multiple test replicates enable statistical validation and creation of 
                   comprehensive benchmark dataset."
                               )
                           )
                       )
                ),
                column(3,
                       box(width = 12, status = "danger", solidHeader = TRUE,
                           div(style = "text-align: center; padding: 15px; min-height: 120px;",
                               div(style = "font-size: 48px; font-weight: bold; color: #e74c3c;", "4.5"),
                               h4(style = "margin-top: 10px; color: #c0392b;", "Hours per Test"),
                               p(style = "font-size: 14px; color: #666;", "Failure Progression Captured")
                           ),
                           div(class = "concept-box",
                               p(class = "description-text",
                                 "Complete temporal evolution from healthy operation to catastrophic failure 
                   documented at high sampling rate."
                               )
                           )
                       )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Benchmark Dataset", status = "warning", solidHeader = TRUE,
                    column(6,
                           div(class = "concept-box",
                               h4("Dataset Characteristics:"),
                               tags$ul(
                                 tags$li(strong("Multiple Motors:"), " 5 BLDCMs tested to failure"),
                                 tags$li(strong("Comprehensive Sensors:"), " 18 measurement channels"),
                                 tags$li(strong("High Sampling Rate:"), " 50 kHz per channel"),
                                 tags$li(strong("Long Duration:"), " 4.5 hours per test"),
                                 tags$li(strong("Non-Stationary:"), " Time-varying force conditions"),
                                 tags$li(strong("Well-Documented:"), " Complete testing protocols"),
                                 tags$li(strong("Processed Features:"), " RMS, kurtosis, mean values"),
                                 tags$li(strong("Labeled Data:"), " Normal and faulty states identified")
                               )
                           )
                    ),
                    column(6,
                           div(class = "concept-box",
                               h4("Unique Advantages:"),
                               p(class = "description-text",
                                 "This dataset will be unique compared to existing public datasets (NASA IGBT, CMAPSS) due to:"
                               ),
                               tags$ul(
                                 tags$li(strong("Sensor Diversity:"), " More measurement modalities than other datasets"),
                                 tags$li(strong("Non-Stationary:"), " Includes time-varying operating conditions"),
                                 tags$li(strong("Detailed Protocols:"), " Complete testing procedures enable replication"),
                                 tags$li(strong("Degradation Parameters:"), " Precise force profiles and failure points"),
                                 tags$li(strong("Multiple Replicates:"), " Statistical validation through repeated tests"),
                                 tags$li(strong("Raw + Processed:"), " Both raw signals and extracted features available")
                               ),
                               
                               div(class = "highlight-box", style = "margin-top: 10px;",
                                   p(strong("Availability:"), " Dataset details and access information available at:"),
                                   p(tags$a(href = "http://www-personal.acfr.usyd.edu.au/zubizarreta/", 
                                            "http://www-personal.acfr.usyd.edu.au/zubizarreta/"))
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Future Work", status = "primary", solidHeader = TRUE,
                    p(class = "description-text",
                      "Several promising directions will extend and enhance this research, expanding the framework to additional 
                      failure modes and optimizing the classification methodology."
                    ),
                    
                    column(4,
                           div(class = "concept-box",
                               h4("Expanded Failure Scenarios:"),
                               
                               h5("Gear Failures:"),
                               tags$ul(
                                 tags$li("Tooth wear progression"),
                                 tags$li("Misalignment detection"),
                                 tags$li("Lubrication degradation"),
                                 tags$li("Crack propagation monitoring")
                               ),
                               
                               h5("Stator Failures:"),
                               tags$ul(
                                 tags$li("Insulation breakdown"),
                                 tags$li("Turn-to-turn shorts"),
                                 tags$li("Phase imbalance"),
                                 tags$li("Thermal degradation")
                               ),
                               
                               p(class = "description-text",
                                 strong("Goal:"), " Create comprehensive failure library covering all major BLDCM failure modes"
                               )
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h4("Feature Optimization:"),
                               
                               h5("Dimensionality Reduction:"),
                               tags$ul(
                                 tags$li("Principal Component Analysis (PCA)"),
                                 tags$li("Linear Discriminant Analysis (LDA)"),
                                 tags$li("t-SNE for visualization"),
                                 tags$li("Autoencoder-based compression")
                               ),
                               
                               h5("Feature Selection:"),
                               tags$ul(
                                 tags$li("Correlation analysis"),
                                 tags$li("Mutual information criteria"),
                                 tags$li("Sequential forward/backward selection"),
                                 tags$li("Genetic algorithm optimization")
                               ),
                               
                               p(class = "description-text",
                                 strong("Goal:"), " Identify minimal feature set maintaining high classification accuracy"
                               )
                           )
                    ),
                    column(4,
                           div(class = "concept-box",
                               h4("Advanced Analytics:"),
                               
                               h5("Time-Series Analysis:"),
                               tags$ul(
                                 tags$li("Long Short-Term Memory (LSTM) networks"),
                                 tags$li("Hidden Markov Models"),
                                 tags$li("Recurrent Neural Networks"),
                                 tags$li("Temporal convolutional networks")
                               ),
                               
                               h5("Prognostics:"),
                               tags$ul(
                                 tags$li("Remaining Useful Life (RUL) estimation"),
                                 tags$li("Degradation trajectory modeling"),
                                 tags$li("Uncertainty quantification"),
                                 tags$li("Confidence interval prediction")
                               ),
                               
                               p(class = "description-text",
                                 strong("Goal:"), " Move beyond detection to predict when failures will occur"
                               )
                           )
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Impact & Applications", status = "success", solidHeader = TRUE,
                    column(6,
                           div(class = "concept-box",
                               h4("Industrial Applications:"),
                               tags$ul(
                                 tags$li(strong("Manufacturing:"), " Prevent unplanned downtime in production machinery"),
                                 tags$li(strong("Mining:"), " Maximize equipment uptime in remote operations"),
                                 tags$li(strong("Transportation:"), " Ensure safety and reliability of electric vehicles"),
                                 tags$li(strong("Aerospace:"), " Monitor critical actuator systems"),
                                 tags$li(strong("Robotics:"), " Enable autonomous health monitoring"),
                                 tags$li(strong("Renewable Energy:"), " Wind turbine generator monitoring")
                               )
                           ),
                           
                           div(class = "highlight-box", style = "margin-top: 15px;",
                               h4("Economic Benefits:"),
                               tags$ul(
                                 tags$li("Reduced maintenance costs through predictive approaches"),
                                 tags$li("Minimized unplanned downtime"),
                                 tags$li("Extended equipment lifecycle"),
                                 tags$li("Optimized spare parts inventory"),
                                 tags$li("Prevention of catastrophic failures")
                               )
                           )
                    ),
                    column(6,
                           div(class = "concept-box",
                               h4("Research Community Impact:"),
                               tags$ul(
                                 tags$li(strong("Public Dataset:"), " Enables algorithm benchmarking and comparison"),
                                 tags$li(strong("Reproducible Protocols:"), " Facilitates independent validation"),
                                 tags$li(strong("Methodological Framework:"), " Template for future condition monitoring studies"),
                                 tags$li(strong("Multi-Sensor Standards:"), " Establishes comprehensive measurement practices"),
                                 tags$li(strong("Educational Resource:"), " Training dataset for students and researchers")
                               )
                           ),
                           
                           div(class = "highlight-box", style = "margin-top: 15px;",
                               h4("Safety & Environmental Benefits:"),
                               tags$ul(
                                 tags$li("Prevention of catastrophic equipment failures"),
                                 tags$li("Reduced environmental impact from failures"),
                                 tags$li("Enhanced workplace safety"),
                                 tags$li("Compliance with safety standards"),
                                 tags$li("Mitigation of environmental contamination risks")
                               )
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
                      "This research builds upon foundational work in condition monitoring, signal processing, machine learning, 
                      and prognostics. The references span bearing fault detection, motor diagnostics, classification algorithms, 
                      and experimental methodologies. Key works include industry reliability surveys, current signature analysis 
                      techniques, neural network applications, support vector machine implementations, and time-frequency analysis 
                      methods for non-stationary conditions."
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
                               h4("Bearing Fault Detection:"),
                               tags$ul(
                                 tags$li(strong("[4] O'Donnell:"), " Large motor reliability survey"),
                                 tags$li(strong("[5] Da et al.:"), " Health monitoring for brushless PM machines"),
                                 tags$li(strong("[6] Benbouzid:"), " Induction motor signature analysis review"),
                                 tags$li(strong("[13] Carter:"), " Rolling element bearing testing method")
                               )
                           )
                    ),
                    column(3,
                           div(class = "concept-box",
                               h4("Non-Stationary Analysis:"),
                               tags$ul(
                                 tags$li(strong("[9] Rajagopalan et al.:"), " Rotor fault detection under non-stationary conditions"),
                                 tags$li(strong("[10] Supangat:"), " Online condition monitoring thesis"),
                                 tags$li(strong("[11] Zubizarreta & Vasudevan:"), " Experiment design and data analysis")
                               )
                           )
                    ),
                    column(3,
                           div(class = "concept-box",
                               h4("Machine Learning:"),
                               tags$ul(
                                 tags$li(strong("[8] Samanta & K.R.:"), " ANN-based fault diagnostics"),
                                 tags$li(strong("[14] Widodo & Yang:"), " SVM in condition monitoring"),
                                 tags$li(strong("[7] Habetler:"), " Online diagnostics review")
                               )
                           )
                    ),
                    column(3,
                           div(class = "concept-box",
                               h4("Datasets & Methods:"),
                               tags$ul(
                                 tags$li(strong("[2] Celaya et al.:"), " NASA IGBT dataset"),
                                 tags$li(strong("[3] Saxena & Goebel:"), " C-MAPSS dataset"),
                                 tags$li(strong("[1] Mahajan & Vasudevan:"), " RTCMA equipment setup")
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
  
  # Results Tab - Accuracy Comparison Plot
  output$accuracy_plot <- renderPlotly({
    accuracy_data <- data.frame(
      Configuration = rep(c("T1 (100)", "T2 (100)", "T3 (100)", "T1 (300)", "T2 (300)", "T3 (300)"), 2),
      Classifier = rep(c("ANN", "SVM"), each = 6),
      Accuracy = c(0.561, 0.583, 0.821, 0.629, 0.887, 0.915,
                   0.641, 0.723, 0.838, 0.762, 0.913, 0.935)
    )
    
    plot_ly(accuracy_data, x = ~Configuration, y = ~Accuracy, color = ~Classifier,
            type = "bar", colors = c("#008A82", "#3498db")) %>%
      layout(
        title = "Classification Accuracy: ANN vs SVM",
        xaxis = list(title = "Dataset Configuration (Training Vectors)"),
        yaxis = list(title = "Accuracy", range = c(0, 1)),
        barmode = "group",
        plot_bgcolor = '#f8f9fa',
        paper_bgcolor = 'rgba(0,0,0,0)'
      )
  })
  
  # Results Tab - Dataset Configuration Impact
  output$dataset_plot <- renderPlotly({
    dataset_data <- data.frame(
      Channels = c(11, 14, 18),
      ANN_100 = c(0.561, 0.583, 0.821),
      SVM_100 = c(0.641, 0.723, 0.838),
      ANN_300 = c(0.629, 0.887, 0.915),
      SVM_300 = c(0.762, 0.913, 0.935)
    )
    
    plot_ly(dataset_data) %>%
      add_trace(x = ~Channels, y = ~ANN_100, type = 'scatter', mode = 'lines+markers',
                name = 'ANN (100 vectors)', line = list(color = '#008A82', dash = 'dash')) %>%
      add_trace(x = ~Channels, y = ~SVM_100, type = 'scatter', mode = 'lines+markers',
                name = 'SVM (100 vectors)', line = list(color = '#3498db', dash = 'dash')) %>%
      add_trace(x = ~Channels, y = ~ANN_300, type = 'scatter', mode = 'lines+markers',
                name = 'ANN (300 vectors)', line = list(color = '#008A82')) %>%
      add_trace(x = ~Channels, y = ~SVM_300, type = 'scatter', mode = 'lines+markers',
                name = 'SVM (300 vectors)', line = list(color = '#3498db')) %>%
      layout(
        title = "Impact of Sensor Channels on Accuracy",
        xaxis = list(title = "Number of Channels", tickmode = "array", tickvals = c(11, 14, 18),
                     ticktext = c("T1 (11)", "T2 (14)", "T3 (18)")),
        yaxis = list(title = "Classification Accuracy", range = c(0.5, 1)),
        plot_bgcolor = '#f8f9fa',
        paper_bgcolor = 'rgba(0,0,0,0)'
      )
  })
  
  # References Table
  ref_data <- data.frame(
    ID = 1:15,
    Authors = c(
      "Mahajan, A. & Vasudevan, S.",
      "Celaya, J. et al.",
      "Saxena, A. & Goebel, K.",
      "O'Donnell, P.",
      "Da, Y. et al.",
      "Benbouzid, M.",
      "Habetler, T.G.",
      "Samanta, B. & K.R., A.-B.",
      "Rajagopalan, S. et al.",
      "Supangat, R.",
      "Zubizarreta-Rodriguez, J.F. & Vasudevan, S.",
      "Maxon Motor",
      "Carter, D.",
      "Widodo, A. & Yang, B.",
      "Haylock, J.A. et al."
    ),
    Year = c(2013, 2009, 2008, 1985, 2011, 2000, 2005, 2003, 2006, 2008, 2013, 2013, 1995, 2007, 1997),
    Type = c(
      "Technical Report", "Dataset", "Dataset", "Report", "Conference",
      "Journal", "Report", "Journal", "Journal", "Thesis",
      "Technical Report", "Manual", "Patent", "Journal", "Conference"
    ),
    Category = c(
      "Experimental Setup", "Dataset", "Dataset", "Reliability Survey", "Diagnostics",
      "Signature Analysis", "Online Monitoring", "Machine Learning", "Non-Stationary",
      "Condition Monitoring", "Experimental Design", "Motor Specifications", "Testing Method",
      "Machine Learning", "Fault Tolerance"
    ),
    stringsAsFactors = FALSE
  )
  
  output$ref_table <- renderDT({
    datatable(
      ref_data,
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