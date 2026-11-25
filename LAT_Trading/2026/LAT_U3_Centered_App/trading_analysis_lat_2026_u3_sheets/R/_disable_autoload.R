# Shiny would also source every file in R/ by itself when the app starts; global.R already sources them once, in the
# right order. This file tells Shiny not to do it a second time (faster start, no surprises).
