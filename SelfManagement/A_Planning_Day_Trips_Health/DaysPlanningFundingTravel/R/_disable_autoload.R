# R/_disable_autoload.R
# Its presence tells Shiny NOT to source every file in R/ automatically before app.R runs.
# global.R sources the helpers itself, once and in the right order (module_loader.R first).
# Without this file each helper was loaded twice at start-up.
