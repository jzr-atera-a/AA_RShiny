# Deployment Fix: Missing Packages on shinyapps.io

## Symptom

App runs fine in RStudio Desktop. After publishing to shinyapps.io, the
log shows:

```
Warning in module_loader$load_packages() : Package not installed: plotly
Warning in module_loader$load_packages() : Package not installed: dplyr
Warning in module_loader$load_packages() : Package not installed: stringr
Warning in module_loader$load_packages() : Package not installed: tidyr
...
Error in plotlyOutput(ns("numeric_chart"), height = "500px") :
  could not find function "plotlyOutput"
Execution halted
```

## Root Cause

`rsconnect` (the package used to publish to shinyapps.io) does not upload
your entire local R library. Before publishing, it statically scans the
app's `.R` files to decide which packages need to be installed on the
server. That scanner only recognizes two patterns:

1. A literal call: `library("pkgname")` or `require("pkgname")`
2. A literal namespaced reference: `pkgname::function_name()`

It cannot resolve a package name stored in a variable. This app's
`R/module_loader.R` loads packages dynamically based on what each
module's `manifest.yml` declares:

```r
library(pkg, character.only = TRUE)   # pkg is a variable here
```

Because `pkg` is a variable populated from YAML at runtime (not a
string literal in the source code, and YAML files aren't scanned at
all), `rsconnect` has no way to know that `plotly`, `dplyr`, `stringr`,
or `tidyr` are required. It installs only what it can prove is needed
(packages referenced as `DT::...` or `shinyjs::...` elsewhere in the
code were detected that way), and the rest are silently skipped.

The app works locally only because those packages already happen to be
installed in your personal R library from previous projects -
`requireNamespace()` succeeds locally for a reason that has nothing to
do with whether the deployment scanner could detect the dependency.

## Fix

Added an explicit, literal `library()` block to `global.R`:

```r
suppressPackageStartupMessages({
  library(shinyjs)
  library(httr)
  library(jsonlite)
  library(bigrquery)
  library(DT)
  library(plotly)
  library(dplyr)
  library(stringr)
  library(tidyr)
})
```

This gives `rsconnect`'s dependency scanner literal evidence for every
package any module currently declares, so all of them get installed on
the shinyapps.io server during the next deploy - regardless of which
modules happen to be enabled in `modules/_module_registry.yml` at
deploy time. The dynamic `ModuleLoader$load_packages()` logic is
untouched and still controls which packages are actually *attached*
for the currently enabled module set; this block only guarantees they
are *available* on the server.

## Why Keep the Dynamic Loader At All?

The dynamic loader still serves its original purpose: if you disable a
module in the registry, its packages are not attached at runtime (no
behavior change, no extra memory/startup cost for unused packages).
The explicit `library()` block in `global.R` only affects what gets
*installed* on the server at publish time, so re-enabling a module
later doesn't require a fresh `rsconnect::deployApp()` call just to add
a missing package.

## Action Required Before Redeploying

After pulling this update, redeploy with:

```r
library(rsconnect)
rsconnect::deployApp()
```

You do not need to change anything else. If you ever add a brand-new
package to a module (one not already in the list above), add a
corresponding literal `library(...)` call to this same block in
`global.R`, or the same issue will recur for that package.
