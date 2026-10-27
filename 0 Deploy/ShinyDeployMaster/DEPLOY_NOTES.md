# ShinyDeployMaster v2 — how deployment works

rsconnect writes manifest.json from the packages INSTALLED in the R session that
deploys. Anything missing is silently dropped, so shinyapps.io never installs it
and the app crashes at startup ("there is no package called ..."). RStudio works
because your laptop has every package installed. v2 recreates that condition for
any app, with nothing app-specific hard-coded:

1. `renv::dependencies()` scans the uploaded app (the same scanner rsconnect uses).
2. The full Depends/Imports/LinkingTo tree is resolved from the repository index.
3. Missing or too-old packages are installed into a cache library
   (`/tmp/sdm_deploy_lib/R-x.y.z`) from Posit Package Manager Linux binaries,
   with a CRAN source fallback. The cache is reused by later deployments.
4. `rsconnect::deployApp(dependencyResolution = "library")` builds a complete
   manifest; shinyapps.io installs everything, as it does for RStudio.
5. The worker opens the deployed URL and reads the server log, so "deployed but
   failed to start" is reported as a failure, not a success.

All of this runs in `worker/deploy_worker.R` (its own Rscript process).

## Using it
- Deploy Auth: upload the setAccountInfo() .R file. It is parsed, never executed.
- Upload App: upload the app zip. The app name is suggested from the zip name.
- Deploy App: run Pre-flight, optionally tick "Test only" for a no-upload check,
  then Deploy. The first deploy of a new app takes 1-3 minutes (package installs).

## Exit codes shown in the console
0 = deployed and running | 1 = stopped before upload (reason on the [FAIL] line)
2 = rsconnect/deploy error | 3 = uploaded but the app failed to start (log shown)

## Limits
- Packages must be on CRAN. GitHub/Bioconductor/private packages are reported
  before upload.
- Packages loaded only by name at runtime (library(x, character.only = TRUE))
  are invisible to every scanner, RStudio included. Also reference them
  literally (library(x) or x::fn).
- The app is public on shinyapps.io. Restrict access in the shinyapps.io
  dashboard if your plan allows it.

## Version 1 changes (password, Explore Apps, deploy registry)

### Access
- The app opens on a password screen. The password is `SDM_PASSWORD` in `global.R`
  (basic protection for v1; replace with proper authentication in v2).

### App registry (BigQuery + local file)
- Table: `atera-2.business_strategy.deploy_apps`
  columns `title_of_app | active_url | Updated_Date | status`
  (`active_url` = `https://atera-analytics.shinyapps.io/<title_of_app>/`, status = `Active` / `Archived`).
- The table is created and seeded automatically the first time BigQuery connects
  (`CREATE TABLE IF NOT EXISTS`; seed rows inserted only into an empty table).
  The same setup is available as `sql/deploy_apps_setup.sql` for the BigQuery console.
- Local mirror: `data/deploy_apps.txt` (tab-separated). It is rewritten after every
  successful BigQuery read or write. With no BigQuery connection the Explore Apps tab
  shows this file.
- To keep BigQuery connected from server start, set `SDM_BQ_SERVICE_ACCOUNT` to the path
  of the service-account JSON. Otherwise connect under APIs -> BigQuery as before.

### Explore Apps (default tab)
- Status checkbox per app: ticked = Active, unticked = Archived.
- "Save the Changes" appears when something differs. It needs a live BigQuery connection,
  writes the changes to BigQuery, then rewrites `data/deploy_apps.txt`.

### Deploy App
- "Update App" (ticked by default): the app name is a dropdown of registry titles.
  Unticked: the app name is a free-text box for a new app.
- Deployments (test builds excluded) require both shinyapps.io credentials and a live
  BigQuery connection.
- After a deployment that exits 0 (verified running), the registry is updated:
  an existing app gets `Updated_Date` = today (status unchanged); a new app is added as Active.
  A deployment that exits 3 (uploaded but failed to start) does not change the registry.
