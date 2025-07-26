# .Rprofile
if (!require("bigrquery", quietly = TRUE) || packageVersion("bigrquery") != "1.4.0") {
  if (!require("devtools")) install.packages("devtools")
  devtools::install_version("bigrquery", version = "1.4.0", dependencies = FALSE)
}