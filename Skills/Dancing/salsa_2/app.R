# Simplified Salsa Beat Detector
library(shiny)
library(shinydashboard)
library(tuneR)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "Salsa Beat Detector"),
  dashboardSidebar(disable = TRUE),
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .content-wrapper { background-color: #2c3e50; color: white; }
        .main-container { max-width: 800px; margin: 0 auto; padding: 40px 20px; text-align: center; }
        .upload-section { background: #34495e; padding: 30px; border-radius: 15px; margin-bottom: 30px; }
        .player-section { background: #34495e; padding: 40px; border-radius: 15px; margin-bottom: 30px; }
        .beat-indicator { 
          width: 120px; height: 120px; border-radius: 50%; 
          background: linear-gradient(45deg, #e74c3c, #c0392b);
          margin: 30px auto; display: flex; align-items: center; justify-content: center;
          font-size: 24px; font-weight: bold; color: white;
          transition: all 0.1s ease;
        }
        .beat-indicator.pulse { 
          transform: scale(1.3); 
          background: linear-gradient(45deg, #f39c12, #e67e22);
          box-shadow: 0 0 30px rgba(243, 156, 18, 0.8);
        }
        .tempo-display { background: #2c3e50; padding: 20px; border-radius: 10px; margin: 20px 0; }
        .tempo-value { font-size: 48px; font-weight: bold; color: #3498db; }
        .control-buttons .btn { margin: 10px; padding: 12px 25px; font-size: 16px; border-radius: 25px; }
        .spectrum-container { 
          background: #2c3e50; border-radius: 10px; padding: 20px; margin: 20px 0;
          border: 2px solid #34495e;
        }
        #spectrumCanvas { 
          width: 100%; height: 200px; border-radius: 5px; 
          background: linear-gradient(to bottom, #1a252f, #2c3e50);
        }
        .frequency-labels {
          display: flex; justify-content: space-between; margin-top: 10px;
          font-size: 12px; color: #95a5a6;
        }
      ")),
      tags$script(HTML("
        var audioContext, analyser, source, dataArray;
        var beatThreshold = 0.15;
        var lastBeatTime = 0;
        var analysisActive = false;
        var spectrumCanvas, spectrumCtx;
        var animationId;
        
        function initAudio() {
          if (analysisActive) return;
          try {
            audioContext = new (window.AudioContext || window.webkitAudioContext)();
            analyser = audioContext.createAnalyser();
            analyser.fftSize = 1024;  // Increased for better spectrum resolution
            analyser.smoothingTimeConstant = 0.8;
            dataArray = new Uint8Array(analyser.frequencyBinCount);
            
            var audio = document.getElementById('audioPlayer');
            if (audio && !analysisActive) {
              source = audioContext.createMediaElementSource(audio);
              source.connect(analyser);
              analyser.connect(audioContext.destination);
              analysisActive = true;
              
              // Initialize spectrum canvas
              initSpectrum();
              
              // Start analysis
              analyzeAudio();
            }
          } catch(e) { console.log('Audio init failed:', e); }
        }
        
        function initSpectrum() {
          spectrumCanvas = document.getElementById('spectrumCanvas');
          if (spectrumCanvas) {
            spectrumCtx = spectrumCanvas.getContext('2d');
            // Set canvas size
            spectrumCanvas.width = spectrumCanvas.offsetWidth;
            spectrumCanvas.height = 200;
          }
        }
        
        function analyzeAudio() {
          if (!analyser || !analysisActive) return;
          
          analyser.getByteFrequencyData(dataArray);
          
          // Beat detection (bass frequencies)
          var bassSum = 0;
          for (var i = 1; i < 9; i++) bassSum += dataArray[i];
          var bassEnergy = bassSum / (8 * 255);
          
          var currentTime = Date.now();
          if (bassEnergy > beatThreshold && (currentTime - lastBeatTime) > 150) {
            triggerBeat();
            lastBeatTime = currentTime;
          }
          
          // Draw spectrum
          drawSpectrum();
          
          animationId = requestAnimationFrame(analyzeAudio);
        }
        
        function drawSpectrum() {
          if (!spectrumCtx || !dataArray) return;
          
          var canvas = spectrumCanvas;
          var ctx = spectrumCtx;
          var width = canvas.width;
          var height = canvas.height;
          
          // Clear canvas
          ctx.fillStyle = 'rgba(26, 37, 47, 0.3)';
          ctx.fillRect(0, 0, width, height);
          
          // Calculate bar width
          var barCount = Math.min(64, dataArray.length);  // Show first 64 frequency bins
          var barWidth = width / barCount;
          
          for (var i = 0; i < barCount; i++) {
            var barHeight = (dataArray[i] / 255) * height;
            
            // Color coding for different frequency ranges
            var hue;
            if (i < 8) {
              // Bass frequencies (red/orange)
              hue = 0 + (i * 5);  // Red to orange
            } else if (i < 24) {
              // Mid frequencies (orange/yellow)
              hue = 40 + ((i - 8) * 3);  // Orange to yellow
            } else if (i < 40) {
              // Upper mid (yellow/green)
              hue = 80 + ((i - 24) * 4);  // Yellow to green
            } else {
              // High frequencies (green/blue)
              hue = 140 + ((i - 40) * 5);  // Green to blue
            }
            
            // Saturation and lightness based on amplitude
            var saturation = Math.min(100, 50 + (dataArray[i] / 255) * 50);
            var lightness = Math.min(70, 30 + (dataArray[i] / 255) * 40);
            
            ctx.fillStyle = 'hsl(' + hue + ', ' + saturation + '%, ' + lightness + '%)';
            
            // Draw bar from bottom
            ctx.fillRect(i * barWidth, height - barHeight, barWidth - 1, barHeight);
            
            // Highlight dominant frequencies with glow effect
            if (dataArray[i] > 180) {  // Strong signal
              ctx.shadowColor = 'hsl(' + hue + ', 100%, 70%)';
              ctx.shadowBlur = 10;
              ctx.fillRect(i * barWidth, height - barHeight, barWidth - 1, barHeight);
              ctx.shadowBlur = 0;
            }
          }
          
          // Draw frequency grid lines
          ctx.strokeStyle = 'rgba(149, 165, 166, 0.3)';
          ctx.lineWidth = 1;
          ctx.setLineDash([2, 2]);
          
          // Horizontal lines (amplitude)
          for (var j = 0; j < 5; j++) {
            var y = (height / 4) * j;
            ctx.beginPath();
            ctx.moveTo(0, y);
            ctx.lineTo(width, y);
            ctx.stroke();
          }
          
          // Vertical lines (frequency markers)
          var markers = [8, 16, 24, 32, 48];  // Frequency bin markers
          for (var k = 0; k < markers.length; k++) {
            if (markers[k] < barCount) {
              var x = markers[k] * barWidth;
              ctx.beginPath();
              ctx.moveTo(x, 0);
              ctx.lineTo(x, height);
              ctx.stroke();
            }
          }
          
          ctx.setLineDash([]);
          
          // Add text labels for dominant frequencies
          var dominantFreq = findDominantFrequency();
          if (dominantFreq.index > -1) {
            ctx.fillStyle = '#ecf0f1';
            ctx.font = '12px Arial';
            ctx.textAlign = 'center';
            var freqHz = Math.round((dominantFreq.index * audioContext.sampleRate) / (analyser.fftSize * 2));
            ctx.fillText(freqHz + ' Hz', dominantFreq.index * barWidth, 20);
          }
        }
        
        function findDominantFrequency() {
          var maxValue = 0;
          var maxIndex = -1;
          
          // Focus on musical frequency range (skip DC and very high frequencies)
          for (var i = 2; i < Math.min(64, dataArray.length); i++) {
            if (dataArray[i] > maxValue) {
              maxValue = dataArray[i];
              maxIndex = i;
            }
          }
          
          return { index: maxIndex, value: maxValue };
        }
        
        function triggerBeat() {
          var indicator = document.getElementById('beatIndicator');
          if (indicator) {
            indicator.classList.add('pulse');
            setTimeout(function() { indicator.classList.remove('pulse'); }, 200);
          }
        }
        
        function stopAnalysis() {
          analysisActive = false;
          if (animationId) {
            cancelAnimationFrame(animationId);
          }
        }
        
        document.addEventListener('DOMContentLoaded', function() {
          setTimeout(function() {
            var audio = document.getElementById('audioPlayer');
            if (audio) {
              audio.addEventListener('play', function() {
                if (audioContext && audioContext.state === 'suspended') {
                  audioContext.resume();
                }
                if (!analysisActive) initAudio();
              });
              
              audio.addEventListener('pause', function() {
                stopAnalysis();
              });
              
              audio.addEventListener('ended', function() {
                stopAnalysis();
              });
            }
          }, 1000);
        });
      "))
    ),
    
    div(class = "main-container",
        h1("🎵 Salsa Beat Detector", style = "color: #3498db; margin-bottom: 40px;"),
        
        div(class = "upload-section",
            h3("Upload Your Salsa Music", style = "color: #ecf0f1; margin-bottom: 20px;"),
            fileInput("audioFile", "Choose MP3 File", 
                      accept = c(".mp3", ".wav")),
            textOutput("uploadStatus")
        ),
        
        conditionalPanel(
          condition = "output.audioLoaded",
          div(class = "player-section",
              h3("Now Playing", style = "color: #ecf0f1; margin-bottom: 30px;"),
              
              tags$audio(id = "audioPlayer", controls = "controls", 
                         style = "width: 100%; height: 60px;"),
              
              br(), br(),
              
              div(class = "control-buttons",
                  actionButton("playBtn", "▶ Play", class = "btn btn-success btn-lg"),
                  actionButton("pauseBtn", "⏸ Pause", class = "btn btn-warning btn-lg"),
                  actionButton("stopBtn", "⏹ Stop", class = "btn btn-danger btn-lg")
              ),
              
              div(id = "beatIndicator", class = "beat-indicator", "BEAT"),
              
              div(class = "spectrum-container",
                  h4("Real-Time Audio Spectrum", style = "color: #ecf0f1; margin-bottom: 15px;"),
                  tags$canvas(id = "spectrumCanvas", width = "800", height = "200"),
                  div(class = "frequency-labels",
                      span("Bass", style = "color: #e74c3c;"),
                      span("Low Mid", style = "color: #f39c12;"),
                      span("Mid", style = "color: #f1c40f;"),
                      span("High Mid", style = "color: #2ecc71;"),
                      span("Treble", style = "color: #3498db;")
                  ),
                  div(style = "margin-top: 10px; font-size: 12px; color: #95a5a6;",
                      "• Red/Orange: Bass frequencies (rhythm/beat)",
                      br(),
                      "• Yellow/Green: Mid frequencies (melody/harmony)", 
                      br(),
                      "• Blue: High frequencies (percussion/details)"
                  )
              ),
              
              div(class = "tempo-display",
                  div(class = "tempo-value", textOutput("currentTempo", inline = TRUE)),
                  div("BPM", style = "color: #95a5a6; font-size: 18px;")
              ),
              
              textOutput("status")
          )
        )
    )
  )
)

# Define Server
server <- function(input, output, session) {
  values <- reactiveValues(
    audioData = NULL,
    fileName = NULL,
    currentTempo = 120,
    isPlaying = FALSE
  )
  
  # Handle file upload
  observeEvent(input$audioFile, {
    req(input$audioFile)
    
    cat("Loading:", input$audioFile$name, "\n")
    
    # Create www directory
    if (!dir.exists("www")) dir.create("www")
    
    # Copy file
    file.copy(input$audioFile$datapath, "www/current_audio.mp3", overwrite = TRUE)
    
    # Try to read for analysis
    tryCatch({
      if (grepl("\\.mp3$", input$audioFile$name, ignore.case = TRUE)) {
        tryCatch({
          audio <- readMP3(input$audioFile$datapath)
          values$audioData <- if(audio@stereo) audio@left else audio@left
          analyzeTempoSimple(values$audioData, audio@samp.rate)
        }, error = function(e) {
          cat("MP3 read failed, using default tempo\n")
          values$currentTempo <- 120
        })
      } else if (grepl("\\.wav$", input$audioFile$name, ignore.case = TRUE)) {
        audio <- readWave(input$audioFile$datapath)
        values$audioData <- if(audio@stereo) audio@left else audio@left
        analyzeTempoSimple(values$audioData, audio@samp.rate)
      }
    }, error = function(e) {
      cat("Audio analysis failed\n")
      values$currentTempo <- 120
    })
    
    values$fileName <- input$audioFile$name
    
    # Update audio source
    session$sendCustomMessage("updateAudio", 
                              list(src = "current_audio.mp3", 
                                   time = as.numeric(Sys.time())))
  })
  
  # Simple tempo analysis
  analyzeTempoSimple <- function(audio_data, sample_rate) {
    tryCatch({
      if (length(audio_data) < 8192) return()
      
      window <- audio_data[1:8192]
      energy <- numeric()
      
      for (i in seq(1, length(window) - 1024, by = 512)) {
        chunk <- window[i:(i + 1023)]
        energy <- c(energy, sqrt(mean(chunk^2)))
      }
      
      if (length(energy) > 10) {
        autocorr <- acf(energy, lag.max = min(30, length(energy) - 1), plot = FALSE)
        peaks <- which(autocorr$acf[-1] > 0.3)
        
        if (length(peaks) > 0) {
          period <- peaks[1] * 512 / sample_rate
          tempo <- 60 / period
          values$currentTempo <- max(80, min(200, round(tempo)))
          cat("Detected tempo:", values$currentTempo, "BPM\n")
        }
      }
    }, error = function(e) {
      cat("Tempo analysis error\n")
    })
  }
  
  # Audio loaded check
  output$audioLoaded <- reactive({
    !is.null(values$audioData)
  })
  outputOptions(output, "audioLoaded", suspendWhenHidden = FALSE)
  
  # Upload status
  output$uploadStatus <- renderText({
    if (is.null(values$fileName)) {
      "No file selected"
    } else {
      paste("Loaded:", values$fileName)
    }
  })
  
  # Control buttons
  observeEvent(input$playBtn, {
    session$sendCustomMessage("audioControl", list(action = "play"))
    values$isPlaying <- TRUE
  })
  
  observeEvent(input$pauseBtn, {
    session$sendCustomMessage("audioControl", list(action = "pause"))
    values$isPlaying <- FALSE
  })
  
  observeEvent(input$stopBtn, {
    session$sendCustomMessage("audioControl", list(action = "stop"))
    values$isPlaying <- FALSE
  })
  
  # Display tempo
  output$currentTempo <- renderText({
    paste(values$currentTempo)
  })
  
  # Status
  output$status <- renderText({
    if (values$isPlaying) {
      "🎵 Playing - Beat detection active"
    } else if (!is.null(values$fileName)) {
      "⏸ Ready to play"
    } else {
      "Upload a file to start"
    }
  })
}

# Add JavaScript handlers
js_code <- tags$script(HTML("
  Shiny.addCustomMessageHandler('updateAudio', function(data) {
    setTimeout(function() {
      var audio = document.getElementById('audioPlayer');
      if (audio) {
        audio.src = data.src + '?t=' + data.time;
        audio.load();
      }
    }, 500);
  });
  
  Shiny.addCustomMessageHandler('audioControl', function(data) {
    var audio = document.getElementById('audioPlayer');
    if (audio) {
      if (data.action === 'play') {
        audio.play().catch(function(e) { console.log('Play failed:', e); });
      } else if (data.action === 'pause') {
        audio.pause();
      } else if (data.action === 'stop') {
        audio.pause();
        audio.currentTime = 0;
      }
    }
  });
"))

# Create www directory
if (!dir.exists("www")) dir.create("www")

# Combine UI with JavaScript
final_ui <- tagList(ui, js_code)

# Run the app
shinyApp(ui = final_ui, server = server)