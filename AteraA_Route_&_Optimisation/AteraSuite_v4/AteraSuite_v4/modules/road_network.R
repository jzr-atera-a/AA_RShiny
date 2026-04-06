# modules/road_network.R
# Road Network Module — Enhanced with 8-Category AV Feature Selection
# Atera Analytics | Innovate UK 10153306

# OSM query dispatch table
.osm_queries <- list(
  roundabout=list(osm_key="junction",osm_val="roundabout",geom="ways"),
  mini_roundabout=list(osm_key="highway",osm_val="mini_roundabout",geom="nodes"),
  traffic_signals=list(osm_key="highway",osm_val="traffic_signals",geom="nodes"),
  motorway_junction=list(osm_key="highway",osm_val="motorway_junction",geom="nodes"),
  ped_crossings=list(osm_key="highway",osm_val="crossing",geom="nodes"),
  give_way=list(osm_key="highway",osm_val="give_way",geom="nodes"),
  stop_sign=list(osm_key="highway",osm_val="stop",geom="nodes"),
  level_crossings=list(osm_key="railway",osm_val="level_crossing",geom="nodes"),
  box_junction=list(osm_key="marking",osm_val="box_junction",geom="nodes"),
  uncontrolled_crossroads=list(osm_key="junction",osm_val="yes",geom="nodes"),
  speed_limits=list(osm_key="maxspeed",osm_val=NULL,geom="ways"),
  weight_restrictions=list(osm_key="maxweight",osm_val=NULL,geom="ways"),
  height_restrictions=list(osm_key="maxheight",osm_val=NULL,geom="ways"),
  width_restrictions=list(osm_key="maxwidth",osm_val=NULL,geom="ways"),
  access_restrictions=list(osm_key="access",osm_val="no",geom="ways"),
  bus_lanes=list(osm_key="busway",osm_val="lane",geom="ways"),
  pedestrian_zones=list(osm_key="highway",osm_val="pedestrian",geom="ways"),
  variable_speed=list(osm_key="maxspeed:variable",osm_val="yes",geom="ways"),
  road_surface=list(osm_key="surface",osm_val=NULL,geom="ways"),
  surface_quality=list(osm_key="smoothness",osm_val=NULL,geom="ways"),
  gradient=list(osm_key="incline",osm_val=NULL,geom="ways"),
  road_lighting=list(osm_key="lit",osm_val=NULL,geom="ways"),
  lane_count=list(osm_key="lanes",osm_val=NULL,geom="ways"),
  bridges=list(osm_key="bridge",osm_val="yes",geom="ways"),
  tunnels=list(osm_key="tunnel",osm_val="yes",geom="ways"),
  fords=list(osm_key="ford",osm_val="yes",geom="nodes"),
  road_class=list(osm_key="highway",osm_val=NULL,geom="ways"),
  nsl_roads=list(osm_key="maxspeed",osm_val="national",geom="ways"),
  zebra_crossings=list(osm_key="crossing",osm_val="zebra",geom="nodes"),
  pelican_crossings=list(osm_key="crossing:signals",osm_val="pelican",geom="nodes"),
  puffin_crossings=list(osm_key="crossing:signals",osm_val="puffin",geom="nodes"),
  toucan_crossings=list(osm_key="crossing:signals",osm_val="toucan",geom="nodes"),
  pegasus_crossings=list(osm_key="crossing:signals",osm_val="pegasus",geom="nodes"),
  informal_crossings=list(osm_key="crossing",osm_val="informal",geom="nodes"),
  school_zones=list(osm_key="amenity",osm_val="school",geom="nodes"),
  footways=list(osm_key="sidewalk",osm_val=NULL,geom="ways"),
  shared_paths=list(osm_key="highway",osm_val="path",geom="ways"),
  dropped_kerbs=list(osm_key="kerb",osm_val="lowered",geom="nodes"),
  cycle_lanes=list(osm_key="cycleway",osm_val="lane",geom="ways"),
  cycle_tracks=list(osm_key="highway",osm_val="cycleway",geom="ways"),
  contraflow_cycling=list(osm_key="oneway:bicycle",osm_val="no",geom="ways"),
  cycle_asl=list(osm_key="cycleway",osm_val="asl",geom="ways"),
  shared_bus_cycle=list(osm_key="cycleway",osm_val="shared_lane",geom="ways"),
  ncn=list(osm_key="network",osm_val="ncn",geom="ways"),
  cycle_parking=list(osm_key="amenity",osm_val="bicycle_parking",geom="nodes"),
  no_cycling=list(osm_key="bicycle",osm_val="no",geom="ways"),
  flood_zones=list(osm_key="flood_prone",osm_val="yes",geom="ways"),
  road_works_osm=list(osm_key="highway",osm_val="construction",geom="ways"),
  tree_canopy=list(osm_key="natural",osm_val="tree_row",geom="ways"),
  speed_humps=list(osm_key="traffic_calming",osm_val="hump",geom="nodes"),
  speed_bumps=list(osm_key="traffic_calming",osm_val="bump",geom="nodes"),
  speed_cushions=list(osm_key="traffic_calming",osm_val="cushion",geom="nodes"),
  table_junctions=list(osm_key="traffic_calming",osm_val="table",geom="nodes"),
  chicanes=list(osm_key="traffic_calming",osm_val="chicane",geom="nodes"),
  bollards=list(osm_key="barrier",osm_val="bollard",geom="nodes"),
  height_barriers=list(osm_key="barrier",osm_val="height_restrictor",geom="nodes"),
  cattle_grids=list(osm_key="barrier",osm_val="cattle_grid",geom="nodes"),
  cctv=list(osm_key="man_made",osm_val="surveillance",geom="nodes"),
  vms=list(osm_key="highway",osm_val="vms",geom="nodes"),
  hgv_routes=list(osm_key="hgv",osm_val="designated",geom="ways"),
  smart_motorway=list(osm_key="motorway:type",osm_val="smart",geom="ways"),
  services=list(osm_key="highway",osm_val="services",geom="ways"),
  red_routes=list(osm_key="restriction:parking",osm_val="no_stopping",geom="ways"),
  nsl_resolution=list(osm_key="maxspeed",osm_val="national",geom="ways"),
  shared_space=list(osm_key="highway",osm_val="living_street",geom="ways")
)

.external_api_features <- c(
  flood_warnings="Environment Agency Flood Monitoring API (free): https://environment.data.gov.uk/flood-monitoring/api/floods",
  caz="Clean Air Zone API (JAQU, free+registration): https://api.chargeablezones.co.uk",
  air_quality="DEFRA UK-Air API (free): https://uk-air.defra.gov.uk/data/API",
  road_works_sm="Street Manager API (DfT, free+registration): https://streetmanager.dft.gov.uk",
  wind_exposure="Met Office DataPoint API: https://www.metoffice.gov.uk/services/data/datapoint",
  frost_risk="Met Office DataPoint API — temperature/frost forecast",
  seasonal_flood="Environment Agency API — river level monitoring",
  lez="Clean Air Zone API (JAQU) — Low Emission Zone boundaries",
  congestion_charge="TfL Unified API (free+registration): https://api.tfl.gov.uk",
  ulez="TfL Unified API — ULEZ boundary polygon",
  nr_level_crossings="Network Rail Open Data: https://www.networkrail.co.uk/who-we-are/transparency-and-ethics/transparency/open-data-feeds/",
  contraflows="Street Manager API — live contraflow systems",
  turn_restrictions="Derived from OSM relation type=restriction (osmdata relations)"
)

.presets <- list(
  critical=list(
    feat_cat1=c("roundabout","mini_roundabout","traffic_signals","motorway_junction","ped_crossings"),
    feat_cat1b=c("level_crossings"),
    feat_cat2=c("weight_restrictions","height_restrictions"),feat_cat2b=character(0),
    feat_cat3=character(0),feat_cat3b=c("tunnels"),
    feat_cat4=c("zebra_crossings","pelican_crossings","puffin_crossings","toucan_crossings"),feat_cat4b=character(0),
    feat_cat5=character(0),feat_cat5b=character(0),
    feat_cat6=c("flood_warnings"),feat_cat6b=character(0),
    feat_cat7=character(0),feat_cat7b=c("height_barriers"),
    feat_cat8=character(0),feat_cat8b=character(0)),
  high=list(
    feat_cat1=c("roundabout","mini_roundabout","traffic_signals","motorway_junction","ped_crossings"),
    feat_cat1b=c("give_way","stop_sign","level_crossings"),
    feat_cat2=c("speed_limits","weight_restrictions","height_restrictions","width_restrictions"),
    feat_cat2b=c("access_restrictions","bus_lanes","pedestrian_zones"),
    feat_cat3=c("road_surface","gradient"),feat_cat3b=c("bridges","tunnels","fords"),
    feat_cat4=c("zebra_crossings","pelican_crossings","puffin_crossings","toucan_crossings"),
    feat_cat4b=c("school_zones"),
    feat_cat5=c("cycle_lanes","contraflow_cycling"),feat_cat5b=character(0),
    feat_cat6=c("flood_warnings","road_works_osm"),feat_cat6b=character(0),
    feat_cat7=c("table_junctions"),feat_cat7b=c("bollards","height_barriers"),
    feat_cat8=c("hgv_routes","smart_motorway"),feat_cat8b=character(0)),
  medium=list(
    feat_cat1=c("roundabout","mini_roundabout","traffic_signals","motorway_junction","ped_crossings"),
    feat_cat1b=c("give_way","stop_sign","box_junction","level_crossings"),
    feat_cat2=c("speed_limits","weight_restrictions","height_restrictions","width_restrictions"),
    feat_cat2b=c("access_restrictions","bus_lanes","pedestrian_zones","caz"),
    feat_cat3=c("road_surface","surface_quality","gradient","road_lighting","lane_count"),
    feat_cat3b=c("bridges","tunnels","fords","road_class"),
    feat_cat4=c("zebra_crossings","pelican_crossings","puffin_crossings","toucan_crossings","pegasus_crossings"),
    feat_cat4b=c("informal_crossings","school_zones","footways","shared_paths"),
    feat_cat5=c("cycle_lanes","cycle_tracks","contraflow_cycling","cycle_asl","shared_bus_cycle"),
    feat_cat5b=c("ncn"),
    feat_cat6=c("flood_warnings","flood_zones","road_works_osm","air_quality"),feat_cat6b=character(0),
    feat_cat7=c("speed_humps","speed_cushions","table_junctions","chicanes"),
    feat_cat7b=c("bollards","height_barriers","vms"),
    feat_cat8=c("hgv_routes","smart_motorway","services"),feat_cat8b=character(0)),
  all_features=list(
    feat_cat1=c("roundabout","mini_roundabout","traffic_signals","motorway_junction","ped_crossings"),
    feat_cat1b=c("give_way","stop_sign","box_junction","uncontrolled_crossroads","level_crossings"),
    feat_cat2=c("speed_limits","weight_restrictions","height_restrictions","width_restrictions"),
    feat_cat2b=c("access_restrictions","bus_lanes","pedestrian_zones","caz","variable_speed"),
    feat_cat3=c("road_surface","surface_quality","gradient","road_lighting","lane_count"),
    feat_cat3b=c("bridges","tunnels","fords","road_class","nsl_roads"),
    feat_cat4=c("zebra_crossings","pelican_crossings","puffin_crossings","toucan_crossings","pegasus_crossings"),
    feat_cat4b=c("informal_crossings","school_zones","footways","shared_paths","dropped_kerbs"),
    feat_cat5=c("cycle_lanes","cycle_tracks","contraflow_cycling","cycle_asl","shared_bus_cycle"),
    feat_cat5b=c("ncn","cycle_parking","no_cycling"),
    feat_cat6=c("flood_warnings","flood_zones","road_works_osm","road_works_sm","air_quality"),
    feat_cat6b=c("tree_canopy","wind_exposure","frost_risk","seasonal_flood","lez"),
    feat_cat7=c("speed_humps","speed_bumps","speed_cushions","table_junctions","chicanes"),
    feat_cat7b=c("bollards","height_barriers","cattle_grids","cctv","vms"),
    feat_cat8=c("hgv_routes","smart_motorway","services","red_routes","nsl_resolution"),
    feat_cat8b=c("congestion_charge","ulez","nr_level_crossings","contraflows","shared_space")),
  none=list(
    feat_cat1=character(0),feat_cat1b=character(0),feat_cat2=character(0),feat_cat2b=character(0),
    feat_cat3=character(0),feat_cat3b=character(0),feat_cat4=character(0),feat_cat4b=character(0),
    feat_cat5=character(0),feat_cat5b=character(0),feat_cat6=character(0),feat_cat6b=character(0),
    feat_cat7=character(0),feat_cat7b=character(0),feat_cat8=character(0),feat_cat8b=character(0))
)

.run_osm_query <- function(bbox, feat_key, spec) {
  tryCatch({
    if (spec$geom == "relations") return(list(data=NULL,count=0,note="Relations not supported"))
    q <- opq(bbox, timeout=40)
    if (!is.null(spec$osm_val)) {
      q <- q %>% add_osm_feature(key=spec$osm_key, value=spec$osm_val)
    } else {
      q <- q %>% add_osm_feature(key=spec$osm_key)
    }
    res <- osmdata_sf(q)
    d <- if (spec$geom=="nodes") res$osm_points else res$osm_lines
    if (is.null(d) || nrow(d)==0) d <- if (spec$geom!="nodes") res$osm_polygons else NULL
    if (!is.null(d) && nrow(d)>0) list(data=d,count=nrow(d))
    else list(data=NULL,count=0)
  }, error=function(e){
    cat(sprintf("  [WARN] %s: %s\n", feat_key, conditionMessage(e)))
    list(data=NULL,count=0,error=conditionMessage(e))
  })
}

# ============================================================================
# UI
# ============================================================================
road_network_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title="Road Network Configuration", status="primary", solidHeader=TRUE, width=4,
        textInput(ns("placeName"), "Location Name:", value="Cambridge, England",
                  placeholder="e.g., Cambridge, England"),
        p(class="text-muted", "Enter a city or region to download road network from OpenStreetMap."),
        br(),
        actionButton(ns("downloadNetwork"), "Download Road Network",
                     class="btn-success", icon=icon("download"), width="100%"),
        br(), br(),
        uiOutput(ns("networkStatus")),
        br(),
        conditionalPanel(
          condition=paste0("output['",ns("networkLoaded"),"']"),
          div(h5("Network Statistics:"), verbatimTextOutput(ns("networkStats")))
        )
      ),
      box(title="Network Information", status="info", solidHeader=TRUE, width=8,
        h5("About Road Networks:"),
        p("Download from OpenStreetMap and convert to routing graph for vehicle path planning."),
        br(),
        fluidRow(
          column(4, valueBoxOutput(ns("networkNodes"),      width=NULL)),
          column(4, valueBoxOutput(ns("networkEdges"),      width=NULL)),
          column(4, valueBoxOutput(ns("networkStatus_box"), width=NULL))
        )
      )
    ),

    fluidRow(
      box(title="AV Navigation Feature Selection", status="warning", solidHeader=TRUE,
          width=12, collapsible=TRUE,

        # Preset bar
        div(style="margin-bottom:15px;padding:12px 15px;background:#fef9f0;border-radius:4px;border-left:4px solid #e67e22;",
          fluidRow(
            column(9,
              h5(style="margin-top:0;color:#e67e22;", icon("layer-group"), " Quick Presets"),
              p(class="text-muted", style="font-size:12px;margin-bottom:10px;",
                "Select a risk tier to auto-populate all 8 categories, then refine below. Road Network must be downloaded first."),
              div(style="display:flex;gap:8px;flex-wrap:wrap;",
                actionButton(ns("preset_critical"), "CRITICAL Only",  class="btn-danger btn-sm",  icon=icon("exclamation-triangle")),
                actionButton(ns("preset_high"),     "HIGH + Critical", class="btn-warning btn-sm", icon=icon("exclamation-circle")),
                actionButton(ns("preset_medium"),   "MEDIUM + Above",  class="btn-info btn-sm",    icon=icon("info-circle")),
                actionButton(ns("preset_all"),      "Select All",      class="btn-success btn-sm", icon=icon("check-square")),
                actionButton(ns("preset_none"),     "Clear All",       class="btn-default btn-sm", icon=icon("square"))
              )
            ),
            column(3, div(style="text-align:right;padding-top:28px;", uiOutput(ns("featureCount"))))
          )
        ),

        tabsetPanel(type="tabs", id=ns("feature_tabs"),

          # CAT 1
          tabPanel(title=tagList(icon("code-branch"), " 1. Junctions"), value="cat1", br(),
            div(style="padding:4px 0 8px;border-bottom:1px solid #eee;margin-bottom:12px;",
              tags$small(class="text-muted", icon("database"),
                " OSM: junction=roundabout, highway=mini_roundabout/traffic_signals/motorway_junction/crossing/give_way/stop, railway=level_crossing")),
            fluidRow(
              column(6,
                tags$strong(style="color:#c0392b;font-size:12px;", icon("exclamation-triangle"), " CRITICAL risk"),
                br(), br(),
                checkboxGroupInput(ns("feat_cat1"), label=NULL,
                  choices=c("Roundabouts (junction=roundabout)"="roundabout",
                            "Mini-roundabouts (highway=mini_roundabout)"="mini_roundabout",
                            "Traffic Signals (highway=traffic_signals)"="traffic_signals",
                            "Motorway Junctions (highway=motorway_junction)"="motorway_junction",
                            "Pedestrian Crossings (highway=crossing)"="ped_crossings"),
                  selected=c("roundabout","mini_roundabout","traffic_signals","motorway_junction","ped_crossings"))
              ),
              column(6,
                tags$strong(style="color:#e67e22;font-size:12px;", icon("exclamation-circle"), " HIGH risk"),
                br(), br(),
                checkboxGroupInput(ns("feat_cat1b"), label=NULL,
                  choices=c("Give Way Junctions (highway=give_way)"="give_way",
                            "Stop Junctions (highway=stop)"="stop_sign",
                            "Box Junctions — UK (marking=box_junction)"="box_junction",
                            "Uncontrolled Crossroads"="uncontrolled_crossroads",
                            "Level Crossings (railway=level_crossing)"="level_crossings"),
                  selected=c("give_way","stop_sign","level_crossings"))
              )
            )
          ),

          # CAT 2
          tabPanel(title=tagList(icon("ban"), " 2. Traffic Control"), value="cat2", br(),
            div(style="padding:4px 0 8px;border-bottom:1px solid #eee;margin-bottom:12px;",
              tags$small(class="text-muted", icon("database"),
                " OSM: maxspeed=*, maxweight=*, maxheight=*, maxwidth=*, access=no, busway=lane, highway=pedestrian | External: CAZ API (JAQU)")),
            fluidRow(
              column(6,
                tags$strong(style="color:#c0392b;font-size:12px;", icon("exclamation-triangle"), " CRITICAL for HGV"),
                br(), br(),
                checkboxGroupInput(ns("feat_cat2"), label=NULL,
                  choices=c("Speed Limits (maxspeed=*)"="speed_limits",
                            "Weight Restrictions (maxweight=*)"="weight_restrictions",
                            "Height Restrictions (maxheight=*)"="height_restrictions",
                            "Width Restrictions (maxwidth=*)"="width_restrictions"),
                  selected=c("weight_restrictions","height_restrictions"))
              ),
              column(6,
                tags$strong(style="color:#e67e22;font-size:12px;", icon("exclamation-circle"), " HIGH risk"),
                br(), br(),
                checkboxGroupInput(ns("feat_cat2b"), label=NULL,
                  choices=c("Access Restrictions (access=no, hgv=no)"="access_restrictions",
                            "Bus Lanes (busway=lane)"="bus_lanes",
                            "Pedestrian Zones (highway=pedestrian)"="pedestrian_zones",
                            "Clean Air Zones — CAZ API [External]"="caz",
                            "Variable Speed Limits — smart motorways"="variable_speed"),
                  selected=c("access_restrictions","bus_lanes"))
              )
            )
          ),

          # CAT 3
          tabPanel(title=tagList(icon("road"), " 3. Road Geometry"), value="cat3", br(),
            div(style="padding:4px 0 8px;border-bottom:1px solid #eee;margin-bottom:12px;",
              tags$small(class="text-muted", icon("database"),
                " OSM: surface=*, smoothness=*, incline=*, lit=*, lanes=*, bridge=yes, tunnel=yes, ford=yes | Elevation: Open Elevation API")),
            fluidRow(
              column(6,
                tags$strong(style="color:#2980b9;font-size:12px;", icon("info-circle"), " MEDIUM priority"),
                br(), br(),
                checkboxGroupInput(ns("feat_cat3"), label=NULL,
                  choices=c("Road Surface Type (surface=*)"="road_surface",
                            "Surface Quality (smoothness=*)"="surface_quality",
                            "Gradient / Incline (incline=* + Open Elevation)"="gradient",
                            "Road Lighting (lit=*)"="road_lighting",
                            "Lane Count (lanes=*)"="lane_count"),
                  selected=c("road_surface","gradient"))
              ),
              column(6,
                tags$strong(style="color:#e67e22;font-size:12px;", icon("exclamation-circle"), " HIGH risk"),
                br(), br(),
                checkboxGroupInput(ns("feat_cat3b"), label=NULL,
                  choices=c("Bridges (bridge=yes)"="bridges",
                            "Tunnels — GNSS blackout (tunnel=yes)"="tunnels",
                            "Fords — seasonal flooding (ford=yes)"="fords",
                            "Road Classification (highway=*)"="road_class",
                            "National Speed Limit roads"="nsl_roads"),
                  selected=c("bridges","tunnels"))
              )
            )
          ),

          # CAT 4
          tabPanel(title=tagList(icon("walking"), " 4. Pedestrian"), value="cat4", br(),
            div(style="padding:4px 0 8px;border-bottom:1px solid #eee;margin-bottom:12px;",
              tags$small(class="text-muted", icon("database"),
                " OSM: crossing=zebra/informal, crossing:signals=pelican/puffin/toucan/pegasus, amenity=school, sidewalk=*, highway=path, kerb=lowered")),
            fluidRow(
              column(6,
                tags$strong(style="color:#c0392b;font-size:12px;", icon("exclamation-triangle"), " CRITICAL — camera-dependent detection"),
                br(), br(),
                checkboxGroupInput(ns("feat_cat4"), label=NULL,
                  choices=c("Zebra Crossings — UK (crossing=zebra)"="zebra_crossings",
                            "Pelican Crossings (crossing:signals=pelican)"="pelican_crossings",
                            "Puffin Crossings (crossing:signals=puffin)"="puffin_crossings",
                            "Toucan Crossings — ped + cycle"="toucan_crossings",
                            "Pegasus Crossings — equestrian"="pegasus_crossings"),
                  selected=c("zebra_crossings","pelican_crossings","puffin_crossings","toucan_crossings"))
              ),
              column(6,
                tags$strong(style="color:#e67e22;font-size:12px;", icon("exclamation-circle"), " HIGH / MEDIUM"),
                br(), br(),
                checkboxGroupInput(ns("feat_cat4b"), label=NULL,
                  choices=c("Informal / Uncontrolled Crossings"="informal_crossings",
                            "School Zones (amenity=school)"="school_zones",
                            "Footways adjacent to carriageway"="footways",
                            "Shared Use Paths — ped + cycle (highway=path)"="shared_paths",
                            "Dropped Kerbs (kerb=lowered)"="dropped_kerbs"),
                  selected=c("school_zones"))
              )
            )
          ),

          # CAT 5
          tabPanel(title=tagList(icon("bicycle"), " 5. Cyclists"), value="cat5", br(),
            div(style="padding:4px 0 8px;border-bottom:1px solid #eee;margin-bottom:12px;",
              tags$small(class="text-muted", icon("database"),
                " OSM: cycleway=lane/asl/shared_lane, highway=cycleway, oneway:bicycle=no, network=ncn, amenity=bicycle_parking, bicycle=no")),
            fluidRow(
              column(6,
                tags$strong(style="color:#e67e22;font-size:12px;", icon("exclamation-circle"), " HIGH risk"),
                br(), br(),
                checkboxGroupInput(ns("feat_cat5"), label=NULL,
                  choices=c("On-carriageway Cycle Lanes (cycleway=lane)"="cycle_lanes",
                            "Segregated Cycle Tracks (highway=cycleway)"="cycle_tracks",
                            "Contraflow Cycling — one-way streets"="contraflow_cycling",
                            "Cycle ASL / Stop Box (cycleway=asl)"="cycle_asl",
                            "Shared Bus-Cycle Lanes (cycleway=shared_lane)"="shared_bus_cycle"),
                  selected=c("cycle_lanes","contraflow_cycling"))
              ),
              column(6,
                tags$strong(style="color:#2980b9;font-size:12px;", icon("info-circle"), " MEDIUM priority"),
                br(), br(),
                checkboxGroupInput(ns("feat_cat5b"), label=NULL,
                  choices=c("National Cycle Network (network=ncn)"="ncn",
                            "Cycle Parking (amenity=bicycle_parking)"="cycle_parking",
                            "Cycling Prohibited (bicycle=no)"="no_cycling"),
                  selected=character(0))
              )
            )
          ),

          # CAT 6
          tabPanel(title=tagList(icon("cloud-rain"), " 6. Environmental"), value="cat6", br(),
            div(style="padding:4px 0 8px;border-bottom:1px solid #eee;margin-bottom:12px;",
              tags$small(class="text-muted", icon("database"),
                " OSM: flood_prone=yes, highway=construction, natural=tree_row | External: Env. Agency API, Met Office DataPoint, DEFRA UK-Air, Street Manager")),
            fluidRow(
              column(6,
                tags$strong(style="color:#e67e22;font-size:12px;", icon("exclamation-circle"), " HIGH — dynamic data"),
                br(), br(),
                checkboxGroupInput(ns("feat_cat6"), label=NULL,
                  choices=c("Active Flood Warnings — Env. Agency API [External]"="flood_warnings",
                            "Flood Risk Zones — OSM (flood_prone=yes)"="flood_zones",
                            "Road Works — OSM (highway=construction)"="road_works_osm",
                            "Road Works — Street Manager API [External]"="road_works_sm",
                            "Air Quality Zones — DEFRA UK-Air [External]"="air_quality"),
                  selected=c("flood_warnings","road_works_osm"))
              ),
              column(6,
                tags$strong(style="color:#2980b9;font-size:12px;", icon("info-circle"), " MEDIUM / LOW"),
                br(), br(),
                checkboxGroupInput(ns("feat_cat6b"), label=NULL,
                  choices=c("Tree Canopy / GNSS obstruction (natural=tree_row)"="tree_canopy",
                            "Wind Exposure — Met Office API [External]"="wind_exposure",
                            "Ice / Frost Risk — Met Office API [External]"="frost_risk",
                            "Seasonal Flooding — Env. Agency [External]"="seasonal_flood",
                            "Low Emission Zones — CAZ API [External]"="lez"),
                  selected=character(0))
              )
            )
          ),

          # CAT 7
          tabPanel(title=tagList(icon("shield-alt"), " 7. Infrastructure"), value="cat7", br(),
            div(style="padding:4px 0 8px;border-bottom:1px solid #eee;margin-bottom:12px;",
              tags$small(class="text-muted", icon("database"),
                " OSM: traffic_calming=hump/bump/cushion/table/chicane, barrier=bollard/height_restrictor/cattle_grid, man_made=surveillance, highway=vms")),
            fluidRow(
              column(6,
                tags$strong(style="color:#2980b9;font-size:12px;", icon("info-circle"), " Traffic Calming — UK"),
                br(), br(),
                checkboxGroupInput(ns("feat_cat7"), label=NULL,
                  choices=c("Speed Humps (traffic_calming=hump)"="speed_humps",
                            "Speed Bumps (traffic_calming=bump)"="speed_bumps",
                            "Speed Cushions — UK straddle-able (cushion)"="speed_cushions",
                            "Raised Table Junctions (traffic_calming=table)"="table_junctions",
                            "Chicanes (traffic_calming=chicane)"="chicanes"),
                  selected=c("table_junctions"))
              ),
              column(6,
                tags$strong(style="color:#e67e22;font-size:12px;", icon("exclamation-circle"), " Barriers & Monitoring"),
                br(), br(),
                checkboxGroupInput(ns("feat_cat7b"), label=NULL,
                  choices=c("Bollards (barrier=bollard)"="bollards",
                            "Height Barriers (barrier=height_restrictor)"="height_barriers",
                            "Cattle Grids (barrier=cattle_grid)"="cattle_grids",
                            "CCTV / ANPR Cameras (man_made=surveillance)"="cctv",
                            "Variable Message Signs (highway=vms)"="vms"),
                  selected=c("height_barriers","bollards"))
              )
            )
          ),

          # CAT 8
          tabPanel(title=tagList(icon("flag"), " 8. UK-Specific"), value="cat8", br(),
            div(style="padding:4px 0 8px;border-bottom:1px solid #eee;margin-bottom:12px;",
              tags$small(class="text-muted", icon("database"),
                " OSM: hgv=designated, motorway:type=smart, highway=services/living_street, restriction:parking=no_stopping | External: TfL API, Network Rail Open Data")),
            fluidRow(
              column(6,
                tags$strong(style="color:#e67e22;font-size:12px;", icon("exclamation-circle"), " HGV & Motorway"),
                br(), br(),
                checkboxGroupInput(ns("feat_cat8"), label=NULL,
                  choices=c("Designated HGV / Lorry Routes (hgv=designated)"="hgv_routes",
                            "Smart Motorway sections (motorway:type=smart)"="smart_motorway",
                            "Motorway Service Areas (highway=services)"="services",
                            "Red Routes — London (restriction:parking=no_stopping)"="red_routes",
                            "National Speed Limit — road type resolution"="nsl_resolution"),
                  selected=c("hgv_routes","smart_motorway"))
              ),
              column(6,
                tags$strong(style="color:#2980b9;font-size:12px;", icon("info-circle"), " London & Regulation [External APIs]"),
                br(), br(),
                checkboxGroupInput(ns("feat_cat8b"), label=NULL,
                  choices=c("Congestion Charge Zone — TfL API [External]"="congestion_charge",
                            "ULEZ Boundary — TfL API [External]"="ulez",
                            "Network Rail Level Crossings [External]"="nr_level_crossings",
                            "Contraflow Systems — Street Manager [External]"="contraflows",
                            "Shared Space / Living Streets"="shared_space"),
                  selected=character(0))
              )
            )
          )
        ),

        br(),
        div(style="border-top:2px solid #e67e22;padding:15px;background:#fef9f0;border-radius:0 0 4px 4px;",
          fluidRow(
            column(4,
              actionButton(ns("downloadFeatures"), "Download Selected Features",
                           class="btn-warning btn-block", icon=icon("cloud-download-alt"))
            ),
            column(4, br(), uiOutput(ns("featureDownloadProgress"))),
            column(4, br(), uiOutput(ns("featureStatus")))
          )
        )
      )
    )
  )
}

# ============================================================================
# SERVER
# ============================================================================
road_network_server <- function(id, api_manager=NULL) {
  moduleServer(id, function(input, output, session) {

    network_data   <- reactiveVal(NULL)
    network_loaded <- reactiveVal(FALSE)
    features_data  <- reactiveVal(NULL)

    all_feat_inputs <- c("feat_cat1","feat_cat1b","feat_cat2","feat_cat2b",
                         "feat_cat3","feat_cat3b","feat_cat4","feat_cat4b",
                         "feat_cat5","feat_cat5b","feat_cat6","feat_cat6b",
                         "feat_cat7","feat_cat7b","feat_cat8","feat_cat8b")

    apply_preset <- function(preset_name) {
      p <- .presets[[preset_name]]
      if (is.null(p)) return()
      for (inp in all_feat_inputs)
        updateCheckboxGroupInput(session, inp, selected=p[[inp]] %||% character(0))
    }

    observeEvent(input$preset_critical, { apply_preset("critical")     })
    observeEvent(input$preset_high,     { apply_preset("high")         })
    observeEvent(input$preset_medium,   { apply_preset("medium")       })
    observeEvent(input$preset_all,      { apply_preset("all_features") })
    observeEvent(input$preset_none,     { apply_preset("none")         })

    total_selected <- reactive({
      sum(sapply(all_feat_inputs, function(inp) length(input[[inp]] %||% character(0))))
    })

    output$featureCount <- renderUI({
      n   <- total_selected()
      col <- if(n==0)"#95a5a6" else if(n<=10)"#27ae60" else if(n<=25)"#e67e22" else "#e74c3c"
      div(style=paste0("font-size:13px;font-weight:600;color:",col,";"),
          icon("check-square"),
          sprintf(" %d feature%s selected", n, if(n==1)"" else "s"))
    })

    # Road network download
    observeEvent(input$downloadNetwork, {
      if (is.null(input$placeName) || input$placeName=="") {
        output$networkStatus <- renderUI({
          div(class="status-error", h5("✗ Invalid"), p("Enter location"))
        })
        return()
      }
      withProgress(message="Downloading road network...", value=0, {
        tryCatch({
          incProgress(0.2, detail="Getting bounding box")
          bbox <- getbb(input$placeName)
          if (is.null(bbox)) stop("Location not found")
          incProgress(0.4, detail="Downloading highway ways")
          highway_query <- opq(bbox, timeout=60) %>%
            add_osm_feature(key="highway",
              value=c("motorway","trunk","primary","secondary","tertiary","residential")) %>%
            osmdata_sf()
          if (is.null(highway_query$osm_lines) || nrow(highway_query$osm_lines)==0)
            stop("No roads found for this location")
          incProgress(0.6, detail="Processing geometry")
          edges <- highway_query$osm_lines
          edges <- edges[st_geometry_type(edges$geometry)=="LINESTRING",]
          if (nrow(edges)==0) stop("No valid road geometries")
          edges <- st_transform(edges, 4326)
          keep_cols <- intersect(c("osm_id","name","highway","geometry"), names(edges))
          edges <- edges[, keep_cols]
          incProgress(0.7, detail="Building routing graph")
          graph <- tryCatch({
            weight_streetnet(edges, wt_profile="motorcar", type_col="highway", id_col="osm_id")
          }, error=function(e) {
            el <- do.call(rbind, lapply(1:min(nrow(edges),500), function(i) {
              lc <- st_coordinates(edges[i,])
              if (nrow(lc)<2) return(NULL)
              do.call(rbind, lapply(1:(nrow(lc)-1), function(j) {
                data.frame(from_lon=lc[j,1],from_lat=lc[j,2],
                           to_lon=lc[j+1,1],to_lat=lc[j+1,2],
                           d=sqrt((lc[j+1,1]-lc[j,1])^2+(lc[j+1,2]-lc[j,2])^2)*111320)
              }))
            }))
            el$d_weighted <- el$d; el
          })
          if (is.null(graph)||nrow(graph)==0) stop("Graph construction failed")
          incProgress(0.9, detail="Finalising")
          nd <- list(graph=graph, nodes=highway_query$osm_points,
                     edges=edges, bbox=bbox, location=input$placeName)
          network_data(nd)
          network_loaded(TRUE)
          if (!is.null(api_manager)) api_manager$network_data <- nd
          output$networkStatus <- renderUI({
            div(class="status-success",
                h5("✓ Network Ready"),
                p(strong("Location: "), input$placeName),
                p(strong("Edges: "), format(nrow(graph), big.mark=",")),
                p(class="text-muted", style="font-size:11px;margin-top:8px;",
                  icon("info-circle"), " Feature download is now unlocked below."))
          })
          showNotification("Road network downloaded!", type="message", duration=3)
        }, error=function(e) {
          network_loaded(FALSE)
          output$networkStatus <- renderUI({
            div(class="status-error", h5("✗ Failed"), p(as.character(e$message)))
          })
          showNotification(paste("Error:", e$message), type="error", duration=10)
        })
      })
    })

    # Feature download
    observeEvent(input$downloadFeatures, {
      if (!network_loaded()) {
        showNotification("Please download the road network first.", type="warning", duration=5)
        return()
      }
      selected_keys <- unique(unlist(lapply(all_feat_inputs,
                                            function(inp) input[[inp]] %||% character(0))))
      if (length(selected_keys)==0) {
        showNotification("No features selected.", type="warning", duration=5)
        return()
      }
      bbox     <- network_data()$bbox
      location <- network_data()$location
      osm_keys <- intersect(selected_keys, names(.osm_queries))
      ext_keys <- intersect(selected_keys, names(.external_api_features))

      cat(sprintf("\n[FEATURES] %d OSM + %d external for: %s\n",
                  length(osm_keys), length(ext_keys), location))

      results  <- list()
      n_ok     <- 0
      n_fail   <- 0
      n_total  <- length(osm_keys)

      output$featureDownloadProgress <- renderUI({
        div(style="color:#e67e22;font-size:12px;", icon("spinner"), " Querying Overpass API...")
      })
      output$featureStatus <- renderUI({ NULL })

      withProgress(message="Downloading AV features...", value=0, {
        for (i in seq_along(osm_keys)) {
          fk <- osm_keys[i]
          incProgress(i/max(n_total,1),
                      detail=sprintf("[%d/%d] %s", i, n_total, fk))
          qr <- .run_osm_query(bbox, fk, .osm_queries[[fk]])
          results[[fk]] <- qr
          if (is.null(qr$error)) n_ok <- n_ok+1 else n_fail <- n_fail+1
          cat(sprintf("  [%s] %-28s — %d features\n",
                      if(is.null(qr$error))"OK  " else "WARN", fk, qr$count))
        }
      })

      ext_notes <- lapply(ext_keys, function(ek) {
        list(note="External API — registration required",
             api_info=.external_api_features[[ek]], count=NA)
      })
      names(ext_notes) <- ext_keys

      total_pts <- sum(sapply(results, function(r) r$count %||% 0))

      feat_bundle <- list(
        osm_features=results, external_features=ext_notes,
        bbox=bbox, location=location,
        downloaded_at=Sys.time(), keys_requested=selected_keys
      )
      features_data(feat_bundle)
      if (!is.null(api_manager)) api_manager$features <- feat_bundle

      output$featureDownloadProgress <- renderUI({
        div(style="color:#27ae60;font-size:12px;",
            icon("check-circle"),
            sprintf(" %d feature locations downloaded", total_pts))
      })
      output$featureStatus <- renderUI({
        div(style="font-size:12px;",
          div(style="background:#eafaf1;border-radius:4px;padding:8px 10px;margin-bottom:6px;",
            icon("check-circle",style="color:#27ae60;"),
            strong(sprintf(" %d OSM queries: %d OK, %d warnings", length(osm_keys), n_ok, n_fail)),
            p(style="margin:2px 0 0;color:#555;",
              sprintf("%d total feature locations retrieved", total_pts))
          ),
          if (length(ext_keys)>0) div(
            style="background:#fef9e7;border-radius:4px;padding:8px 10px;",
            icon("info-circle",style="color:#e67e22;"),
            strong(sprintf(" %d external API features noted", length(ext_keys))),
            p(style="margin:2px 0 0;color:#777;font-size:11px;",
              "See the feature catalogue for API registration details.")
          )
        )
      })
      showNotification(
        sprintf("Feature download complete: %d locations from %d OSM queries.", total_pts, length(osm_keys)),
        type="message", duration=5)
    })

    output$networkStats <- renderText({
      net <- network_data()
      if (is.null(net)) return("No network downloaded yet.")
      paste0("Location : ", net$location,
             "\nNodes    : ", format(if(!is.null(net$nodes)) nrow(net$nodes) else 0, big.mark=","),
             "\nEdges    : ", format(nrow(net$edges), big.mark=","))
    })
    output$networkNodes <- renderValueBox({
      net <- network_data()
      valueBox(if(is.null(net))"N/A" else format(if(!is.null(net$nodes)) nrow(net$nodes) else 0, big.mark=","),
               "OSM Nodes", icon=icon("circle"), color="blue")
    })
    output$networkEdges <- renderValueBox({
      net <- network_data()
      valueBox(if(is.null(net))"N/A" else format(nrow(net$edges), big.mark=","),
               "Road Edges", icon=icon("road"), color="green")
    })
    output$networkStatus_box <- renderValueBox({
      valueBox(if(network_loaded())"Ready" else "Not Loaded", "Network Status",
               icon=icon(if(network_loaded())"check-circle" else "times-circle"),
               color=if(network_loaded())"green" else "red")
    })
    output$networkLoaded <- reactive({ network_loaded() })
    outputOptions(output, "networkLoaded", suspendWhenHidden=FALSE)
  })
}
