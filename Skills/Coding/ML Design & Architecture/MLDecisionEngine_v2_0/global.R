# global.R — ML Decision Engine

library(shiny)
library(shinydashboard)
library(R6)
library(yaml)
library(dplyr)
library(DT)

source("data/ml_models.R")

INDUSTRIES <- c(
  "Finance / Banking"       = "finance",
  "Trading / Quant Finance" = "trading",
  "Social Media / Retail"   = "social",
  "Online Retail"           = "retail",
  "Autonomous Vehicles"     = "av",
  "Energy / Utilities"      = "energy",
  "General / Other"         = "general"
)

PROBLEM_TYPES <- c(
  "Classification (binary/multi-class)" = "classification",
  "Regression (continuous output)"      = "regression",
  "Forecasting / Time Series"           = "forecasting",
  "Ranking / Recommendation"            = "ranking",
  "Recommendation"                      = "recommendation",
  "Anomaly / Fraud Detection"           = "anomaly",
  "Causal Inference / A-B Testing"      = "causal",
  "Generation (text, image, synthetic)" = "generation",
  "Sequential Decisions / RL"           = "sequential",
  "Clustering / Segmentation"           = "clustering",
  "Retrieval / Search"                  = "retrieval",
  "Uncertainty Quantification"          = "calibration",
  "Simulation / Digital Twin"           = "simulation",
  "Optimisation"                        = "optimisation"
)

DATA_TYPES <- c(
  "Tabular / Structured"     = "tabular",
  "Time Series"              = "timeseries",
  "Text / NLP"               = "text",
  "Image / Video"            = "image",
  "Audio"                    = "audio",
  "Graph / Network"          = "graph",
  "Sequences"                = "sequence",
  "Multimodal (mixed)"       = "multimodal"
)

DATA_VOLUMES <- c(
  "Small (<10K rows)"              = "small",
  "Medium (10K – 1M rows)"         = "medium",
  "Large (1M – 1B rows)"           = "large",
  "Extra Large (>1B rows/events)"  = "xlarge"
)

LATENCY_REQS <- c(
  "Real-time (<10ms)"        = "realtime",
  "Near-real-time (<1 sec)"  = "nearrealtime",
  "Batch (minutes/hours)"    = "batch",
  "Streaming (continuous)"   = "streaming"
)

SERVING_MODES <- c(
  "Online API (request/response)" = "online",
  "Batch pipeline (scheduled)"    = "batch",
  "Streaming (event-driven)"      = "streaming",
  "Edge / On-device"              = "edge"
)

INTERPRETABILITY <- c(
  "Full interpretability required (regulatory/compliance)" = "full",
  "Partial (SHAP/LIME acceptable)"                        = "partial",
  "Black-box acceptable"                                  = "blackbox"
)

TEAM_MATURITY <- c(
  "Beginner (start simple)"          = "beginner",
  "Intermediate (standard MLOps)"   = "intermediate",
  "Advanced (custom infrastructure)" = "advanced"
)

STREAMING_FIT_COLOUR <- function(fit) {
  switch(fit,
    "excellent" = "#27ae60",
    "good"      = "#2980b9",
    "moderate"  = "#e67e22",
    "poor"      = "#c0392b",
    "#546e7a"
  )
}

GROUPS_META <- list(
  g1  = list(label="Supervised — Classical",                 colour="#1877F2"),
  g2  = list(label="Supervised DL — Vision & Sequence",      colour="#16a34a"),
  g3  = list(label="Supervised DL — Graph, Tabular & Multi", colour="#7c3aed"),
  g4  = list(label="GenAI & Foundation Models",              colour="#d97706"),
  g5  = list(label="Unsupervised & Self-Supervised",         colour="#dc2626"),
  g6  = list(label="Reinforcement Learning",                 colour="#0ea5e9"),
  g7  = list(label="Classical Time Series",                  colour="#2c5364"),
  g8  = list(label="Bayesian & Probabilistic",               colour="#db2777"),
  g9  = list(label="Recommender Systems",                    colour="#0d9488"),
  g10 = list(label="Causal Inference & Uplift",              colour="#65a30d"),
  g11 = list(label="Online Learning & Bandits",              colour="#ea580c"),
  g12 = list(label="Physics-Informed & Simulation",          colour="#6366f1")
)

source("data/design_patterns.R")

PATTERN_PRIORITIES <- c(
  "Data consistency & train-serve skew prevention" = "skew",
  "Scaling to billions of candidates / items"      = "scale",
  "Regulatory compliance & explainability"         = "compliance",
  "Handling class imbalance / rare events"         = "imbalance",
  "Reproducible experiments & data splits"         = "reproduce",
  "Automated retraining & drift monitoring"        = "drift",
  "Efficient training (large models / datasets)"   = "training",
  "Serving latency optimisation"                   = "latency_opt",
  "Schema / feature evolution"                     = "schema"
)

RETRAINING_TRIGGERS <- c(
  "Scheduled (time-based)"          = "scheduled",
  "Performance-based (metric drop)" = "performance",
  "Drift-based (PSI threshold)"     = "drift",
  "Continuous / online"             = "continuous",
  "Manual / ad-hoc"                 = "manual"
)
