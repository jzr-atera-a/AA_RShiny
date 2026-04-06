# modules/chapter_diagrams.R
# 24 static SVG diagrams, B&W, 2 per chapter, 12 chapters
# Uses sprintf() for all SVG — no quote escaping issues

chapter_diagrams_ui <- function(id) {
  ns <- NS(id)

  q <- '"'  # double-quote character for SVG attributes

  # SVG wrapper
  wo <- function(h) paste0('<svg viewBox="0 0 580 ', h, '" xmlns="http://www.w3.org/2000/svg" style="font-family:Arial,sans-serif;background:#fff;width:100%;height:auto;"><defs><marker id="a" markerWidth="8" markerHeight="6" refX="8" refY="3" orient="auto"><polygon points="0 0,8 3,0 6" fill="#333"/></marker><marker id="ad" markerWidth="8" markerHeight="6" refX="8" refY="3" orient="auto"><polygon points="0 0,8 3,0 6" fill="#999"/></marker></defs>')
  wc <- '</svg>'

  # Primitives using sprintf
  R  <- function(x,y,w,h,f="#eee",s="#333",sw=1.5,rx=3) sprintf('<rect x="%s" y="%s" width="%s" height="%s" rx="%s" fill="%s" stroke="%s" stroke-width="%s"/>',x,y,w,h,rx,f,s,sw)
  Tx <- function(x,y,t,sz=10,a="middle",fw="normal",col="#000") sprintf('<text x="%s" y="%s" text-anchor="%s" font-size="%s" font-weight="%s" fill="%s">%s</text>',x,y,a,sz,fw,col,t)
  Ar <- function(x1,y1,x2,y2,dash=FALSE) sprintf('<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="1.5"%s marker-end="url(#%s)" fill="none"/>',x1,y1,x2,y2,if(dash)"#999"else"#333",if(dash)' stroke-dasharray="5,3"'else"",if(dash)"ad"else"a")
  Li <- function(x1,y1,x2,y2,col="#ccc",sw=1) sprintf('<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s"/>',x1,y1,x2,y2,col,sw)
  El <- function(cx,cy,rx,ry,f="#eee",s="#333") sprintf('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s" stroke="%s" stroke-width="1.5"/>',cx,cy,rx,ry,f,s)
  Di <- function(cx,cy,w,h,f="#eee",s="#333") { hw<-w/2;hh<-h/2; sprintf('<polygon points="%s,%s %s,%s %s,%s %s,%s" fill="%s" stroke="%s" stroke-width="1.5"/>',cx,cy-hh,cx+hw,cy,cx,cy+hh,cx-hw,cy,f,s) }
  Pl <- function(pts,s="#333",sw=2) sprintf('<polyline points="%s" fill="none" stroke="%s" stroke-width="%s"/>',pts,s,sw)
  Pg <- function(pts,f="#eee",s="#333",sw=1.5) sprintf('<polygon points="%s" fill="%s" stroke="%s" stroke-width="%s"/>',pts,f,s,sw)
  P  <- function(...) paste0(...)

  # ── CH1-A: ML System Stack ────────────────────────────────────────────────
  ch1a <- P(wo(275),
    R(10,10,560,252,"#fafafa","#555",2,8),
    Tx(290,33,"ML SYSTEM",14,"middle","bold"),
    R(25,44,530,36,"#bbb","#444",1.5), Tx(290,67,"Deployment / Monitoring / Updating [Ch.7,8,9]",10,"middle","bold"),
    R(25,88,166,54,"#ddd","#444",1.5), Tx(108,112,"Feature Engineering",10,"middle","bold"), Tx(108,128,"[Ch.5]",9,"middle","normal","#666"),
    R(201,88,166,54,"#ddd","#444",1.5), Tx(284,112,"ML Algorithms",10,"middle","bold"), Tx(284,128,"[Ch.6]",9,"middle","normal","#666"),
    R(377,88,178,54,"#ddd","#444",1.5), Tx(466,112,"Evaluation",10,"middle","bold"), Tx(466,128,"[Ch.6]",9,"middle","normal","#666"),
    R(25,151,530,36,"#aaa","#444",1.5), Tx(290,174,"Data   [Ch.3 & 4]",10,"middle","bold","#000"),
    R(25,196,530,26,"#888","#444",1.5), Tx(290,213,"Infrastructure   [Ch.10]",10,"middle","bold","#fff"),
    R(10,46,115,26,"#fff","#666",1), Tx(67,63,"Users [Ch.11]",9,"middle","normal","#333"), Ar(125,59,160,60),
    R(10,100,115,26,"#fff","#666",1), Tx(67,117,"Biz Reqs [Ch.1]",9,"middle","normal","#333"), Ar(125,113,160,113),
    R(10,165,115,26,"#fff","#666",1), Tx(67,182,"ML Devs (all)",9,"middle","normal","#333"), Ar(125,178,160,178),
  wc)

  # ── CH1-B: Business to ML Objective ──────────────────────────────────────
  ch1b <- P(wo(248),
    R(10,26,178,54,"#eee","#333",1.5), Tx(99,50,"Business Goal",12,"middle","bold"),
    Tx(99,67,"Increase Revenue",9,"middle","normal","#666"),
    Ar(188,53,248,53), Tx(218,47,"TRANSLATE",8,"middle","normal","#999"),
    R(248,26,178,54,"#ddd","#333",1.5), Tx(337,50,"ML Objective",12,"middle","bold"),
    Tx(337,67,"Maximise click-through",9,"middle","normal","#666"),
    Ar(337,80,337,118),
    R(248,118,178,44,"#ccc","#333",1.5), Tx(337,137,"ML Metric",12,"middle","bold"),
    Tx(337,152,"AUC-ROC / NDCG@10",9,"middle","normal","#666"),
    Li(10,112,570,112,"#bbb",1),
    Tx(14,108,"Constraints (from business, not data):",10,"start","bold"),
    Tx(14,132,"Latency SLO  p99 < 100ms",10,"start"),
    Tx(14,148,"Interpretability required?",10,"start"),
    Tx(14,164,"Fairness / regulatory",10,"start"),
    Tx(14,180,"Training cost budget",10,"start"),
    R(10,198,560,24,"#f0f0f0","#aaa",1),
    Tx(14,215,"Misaligned objective = building the wrong system entirely",9,"start","normal","#555"),
  wc)

  # ── CH2-A: 6-Step Cycle ──────────────────────────────────────────────────
  ch2a <- P(wo(318),
    El(290,44,110,28,"#ddd"), Tx(290,38,"1. Project Scope",10,"middle","bold"), Tx(290,52,"[Ch.1-2]",9,"middle","normal","#888"),
    El(458,118,98,26,"#ddd"), Tx(458,122,"2. Data Engineering",10,"middle","bold"),
    El(458,218,98,26,"#ddd"), Tx(458,222,"3. Model Development",10,"middle","bold"),
    El(290,282,110,24,"#ddd"), Tx(290,286,"4. Deployment",10,"middle","bold"),
    El(112,218,98,26,"#ddd"), Tx(112,214,"5. Monitoring &",9,"middle","bold"), Tx(112,228,"Cont. Learning",9,"middle","bold"),
    El(112,118,98,26,"#ddd"), Tx(112,122,"6. Biz Analysis",10,"middle","bold"),
    Ar(375,55,370,100), Ar(458,144,458,192), Ar(388,234,372,270),
    Ar(238,282,222,252), Ar(112,192,112,144), Ar(182,106,198,66),
    Ar(358,118,210,118,TRUE), Ar(210,218,360,218,TRUE),
    Tx(290,162,"Non-linear: any step can return to any prior step",9,"middle","normal","#888"),
  wc)

  # ── CH2-B: Hierarchy of Needs ────────────────────────────────────────────
  ch2b <- P(wo(308),
    Pg("290,16 548,266 32,266","#f0f0f0","#333",2),
    Li(66,216,514,216,"#555",1), Li(94,168,486,168,"#555",1),
    Li(128,120,452,120,"#555",1), Li(170,74,410,74,"#555",1),
    Tx(290,256,"COLLECT — logging, sensors, events",9,"middle"),
    Tx(290,206,"MOVE/STORE — pipelines, ETL, storage",9,"middle"),
    Tx(290,158,"EXPLORE — cleaning, anomaly detection",9,"middle"),
    Tx(290,110,"AGGREGATE — features, training data",9,"middle"),
    Tx(290,64,"LEARN — A/B testing, ML",9,"middle"),
    Tx(290,30,"AI",10,"middle","bold"),
    Tx(290,290,"Most orgs rush to AI before fixing layers 1-3 — the #1 production failure",8,"middle","normal","#555"),
  wc)

  # ── CH3-A: Row vs Columnar ───────────────────────────────────────────────
  ch3a <- P(wo(180),
    Tx(14,18,"ROW-ORIENTED (CSV, JSON)",11,"start","bold"),
    Tx(14,32,"Fast writes. Slow analytics.",9,"start","normal","#666"),
    R(14,40,258,24,"#ddd","#555",1), Tx(16,57,"user_id | age | city | purchase",9,"start","normal","#333"),
    R(14,64,258,18,"#fff","#aaa",1), Tx(16,77,"001 | 28 | NYC | 49.99",9,"start"),
    R(14,82,258,18,"#f5f5f5","#aaa",1), Tx(16,95,"002 | 34 | LA  | 12.50",9,"start"),
    R(14,100,258,18,"#fff","#aaa",1), Tx(16,113,"003 | 22 | SF  | 87.00",9,"start"),
    Li(284,10,284,145,"#ccc",1),
    Tx(298,18,"COLUMNAR (Parquet, ORC)",11,"start","bold"),
    Tx(298,32,"Fast analytics. Read only columns needed.",9,"start","normal","#666"),
    R(298,40,54,88,"#ddd","#555",1), Tx(325,58,"uid",9,"middle","bold"),
    Tx(325,75,"001",8,"middle"), Tx(325,90,"002",8,"middle"), Tx(325,106,"003",8,"middle"),
    R(354,40,46,88,"#eee","#555",1), Tx(377,58,"age",9,"middle","bold"),
    Tx(377,75,"28",8,"middle"), Tx(377,90,"34",8,"middle"), Tx(377,106,"22",8,"middle"),
    R(402,40,50,88,"#ddd","#555",1), Tx(427,58,"city",9,"middle","bold"),
    Tx(427,75,"NYC",8,"middle"), Tx(427,90,"LA",8,"middle"), Tx(427,106,"SF",8,"middle"),
    R(454,40,62,88,"#eee","#555",1), Tx(485,58,"purch.",9,"middle","bold"),
    Tx(485,75,"49.99",8,"middle"), Tx(485,90,"12.50",8,"middle"), Tx(485,106,"87.00",8,"middle"),
    Tx(14,160,"Default for ML: Parquet. Read only columns needed — 10-100x faster.",9,"start"),
  wc)

  # ── CH3-B: Batch vs Streaming ─────────────────────────────────────────────
  ch3b <- P(wo(215),
    Tx(14,18,"BATCH PIPELINE",12,"start","bold"),
    R(14,28,90,32,"#eee","#333",1.5), Tx(59,48,"Data Store",9,"middle"),
    Ar(104,44,140,44), R(140,28,90,32,"#ddd","#333",1.5), Tx(185,48,"Batch ETL",9,"middle"),
    Ar(230,44,266,44), R(266,28,90,32,"#eee","#333",1.5), Tx(311,48,"Features",9,"middle"),
    Ar(356,44,392,44), R(392,28,76,32,"#ddd","#333",1.5), Tx(430,48,"Model",9,"middle"),
    Tx(14,80,"Latency: hours. High throughput. Low cost per record.",9,"start","normal","#666"),
    Li(10,94,570,94,"#ccc",1),
    Tx(14,110,"STREAMING PIPELINE",12,"start","bold"),
    El(65,138,52,20,"#eee"), Tx(65,142,"Live Events",9,"middle"),
    Ar(117,138,148,138), R(148,126,96,24,"#ddd","#333",1.5), Tx(196,143,"Kafka/Kinesis",9,"middle"),
    Ar(244,138,278,138), R(278,126,96,24,"#eee","#333",1.5), Tx(326,143,"Flink/Spark",9,"middle"),
    Ar(374,138,408,138), R(408,126,76,24,"#ddd","#333",1.5), Tx(446,143,"Model",9,"middle"),
    Tx(14,178,"Latency: ms-seconds. Real-time features. Higher cost.",9,"start","normal","#666"),
    Tx(14,196,"Rule: batch for training data; streaming for serving features.",9,"start","normal","#333"),
  wc)

  # ── CH4-A: Labelling Strategies ───────────────────────────────────────────
  ch4a <- P(wo(210),
    Tx(290,18,"LABELLING STRATEGIES",12,"middle","bold"),
    R(14,26,162,80,"#eee","#333",1.5), Tx(95,46,"Hand Labels",11,"middle","bold"),
    Tx(18,63,"High quality",9,"start"), Tx(18,78,"Slow and expensive",9,"start"), Tx(18,93,"Annotator bias",9,"start"),
    R(186,26,162,80,"#e8e8e8","#333",1.5), Tx(267,46,"Natural Labels",11,"middle","bold"),
    Tx(190,63,"Free and scalable",9,"start"), Tx(190,78,"Noisy and delayed",9,"start"), Tx(190,93,"e.g. clicks, ratings",8,"start","normal","#777"),
    R(358,26,208,80,"#e0e0e0","#333",1.5), Tx(462,46,"Programmatic",11,"middle","bold"),
    Tx(362,63,"Scalable and cheap",9,"start"), Tx(362,78,"Noisy output",9,"start"), Tx(362,93,"Snorkel LF + LM",8,"start","normal","#777"),
    Tx(14,128,"Label quality: inter-annotator agreement — Cohen kappa > 0.7 acceptable",9,"start"),
    Tx(14,144,"Label delay: clicks (1hr) | purchases (2wks) | fraud (30+ days)",9,"start"),
    R(14,158,550,22,"#f0f0f0","#aaa",1),
    Tx(16,174,"Longer delay = slower retraining = model stays stale longer",9,"start","normal","#555"),
  wc)

  # ── CH4-B: Class Imbalance ────────────────────────────────────────────────
  ch4b <- P(wo(250),
    Tx(14,18,"CLASS IMBALANCE  (e.g. fraud: 99% neg / 1% pos)",12,"start","bold"),
    R(14,26,550,22,"#e8e8e8","#555",1),
    Tx(16,41,"Original:  [####################################oo]  99/1 split",9,"start"),
    Tx(14,68,"STRATEGY 1 — Oversampling (SMOTE: synthesise minority)",10,"start","bold"),
    R(14,76,550,20,"#f5f5f5","#aaa",1),
    Tx(16,90,"[####################ooooooooooooooooo]  ~50/50",9,"start"),
    Tx(14,112,"STRATEGY 2 — Undersampling (remove majority examples)",10,"start","bold"),
    R(14,120,550,20,"#f5f5f5","#aaa",1),
    Tx(16,134,"[########ooooooooooooooooooooooooooooo]  fewer total",9,"start"),
    Tx(14,156,"STRATEGY 3 — Focal Loss   FL = -(1-pt)^y * log(pt)   y=2 default",10,"start","bold"),
    Tx(14,176,"STRATEGY 4 — Class Weights   weight = 1 / class_frequency",10,"start","bold"),
    R(14,192,550,22,"#f0f0f0","#aaa",1),
    Tx(16,208,"Never use Accuracy on imbalanced data. Use F1, AUC-ROC, PR-AUC.",9,"start","normal","#333"),
  wc)

  # ── CH5-A: Feature Store ──────────────────────────────────────────────────
  ch5a <- P(wo(238),
    Tx(290,18,"FEATURE STORE ARCHITECTURE",12,"middle","bold"),
    R(14,30,106,44,"#eee","#333",1.5), Tx(67,49,"Raw Data",10,"middle","bold"), Tx(67,63,"(events/logs)",8,"middle","normal","#777"),
    Ar(120,52,166,52),
    R(166,30,116,44,"#ddd","#333",1.5), Tx(224,49,"Feature",10,"middle","bold"), Tx(224,63,"Pipelines",10,"middle","bold"),
    Ar(282,52,328,52),
    R(328,10,230,96,"#f5f5f5","#333",2,6), Tx(443,28,"FEATURE STORE",10,"middle","bold"),
    R(338,36,210,26,"#ddd","#555",1), Tx(443,54,"Offline Store (S3 / DWH)",9,"middle"),
    R(338,66,210,26,"#ccc","#555",1), Tx(443,84,"Online Store (Redis)",9,"middle"),
    Ar(358,106,302,148), Ar(458,106,458,148),
    R(244,148,120,38,"#eee","#333",1.5), Tx(304,164,"Training Job",10,"middle","bold"), Tx(304,178,"(offline store)",8,"middle","normal","#777"),
    R(382,148,120,38,"#eee","#333",1.5), Tx(442,164,"Prediction Svc",10,"middle","bold"), Tx(442,178,"(online store)",8,"middle","normal","#777"),
    Tx(14,218,"Same feature code path = same output = NO train-serve skew",9,"start","normal","#333"),
  wc)

  # ── CH5-B: Train-Serve Skew ───────────────────────────────────────────────
  ch5b <- P(wo(295),
    Tx(290,18,"TRAIN-SERVE SKEW — Huyen #1 production failure",12,"middle","bold"),
    R(14,28,228,84,"#f5f5f5","#333",1.5), Tx(128,50,"TRAINING",12,"middle","bold"),
    Tx(18,68,"feature_X = log(raw + 1)",10,"start"),
    Tx(18,84,"(log transform applied)",9,"start","normal","#777"),
    Tx(255,74,"NOT EQUAL",11,"middle","bold","#c00"),
    R(318,28,228,84,"#f5f5f5","#333",1.5), Tx(432,50,"SERVING",12,"middle","bold"),
    Tx(322,68,"feature_X = raw_value",10,"start"),
    Tx(322,84,"(transform omitted!)",9,"start","normal","#c00"),
    R(14,126,550,22,"#fff0f0","#c00",1),
    Tx(16,141,"Result: model receives different distribution at serving = silent accuracy collapse",8,"start","normal","#c00"),
    Tx(14,172,"SOLUTION: Feature Store — same transformation code used in BOTH paths",10,"start","bold"),
    Ar(100,188,228,216), Ar(398,188,296,216),
    R(228,216,120,32,"#ddd","#333",1.5), Tx(288,236,"Feature Store",10,"middle","bold"),
    Tx(14,268,"Also: point-in-time joins prevent temporal leakage.",9,"start","normal","#555"),
  wc)

  # ── CH6-A: ROC and PR Curves ──────────────────────────────────────────────
  ch6a <- P(wo(268),
    Tx(135,16,"ROC CURVE",11,"middle","bold"),
    Li(28,208,252,208,"#333",1), Li(28,208,28,28,"#333",1),
    Ar(28,208,252,208), Ar(28,208,28,28),
    Tx(140,226,"FPR (1-Specificity)",9,"middle"),
    Tx(8,118,"TPR",9,"middle"),
    Pl("28,208 50,174 72,138 106,96 143,68 182,50 218,38 250,30","#000",2),
    Li(28,208,250,30,"#aaa",1),
    Tx(54,52,"AUC~0.92",9,"start"),
    Tx(128,152,"Random",8,"middle","normal","#aaa"),
    Tx(140,245,"AUC=1 perfect | 0.5 random",8,"middle","normal","#666"),
    Tx(400,16,"PRECISION-RECALL",11,"middle","bold"),
    Li(292,208,526,208,"#333",1), Li(292,208,292,28,"#333",1),
    Ar(292,208,526,208), Ar(292,208,292,28),
    Tx(409,226,"Recall",9,"middle"), Tx(272,118,"Prec",9,"middle"),
    Pl("292,42 315,44 345,50 375,63 405,86 432,120 458,156 490,190 524,208","#000",2),
    Tx(296,40,"high prec",8,"start","normal","#777"),
    Tx(409,245,"PR-AUC better for imbalanced data (fraud, medical)",8,"middle","normal","#666"),
  wc)

  # ── CH6-B: Baseline Hierarchy ─────────────────────────────────────────────
  ch6b <- P(wo(268),
    Tx(290,18,"HUYEN BASELINE HIERARCHY",12,"middle","bold"),
    R(14,26,550,40,"#ccc","#333",1.5),
    Tx(18,44,"Tier 1 — Random / Constant (predict majority class always)",10,"start","bold"),
    Tx(18,60,"Shows why accuracy fails on imbalanced data. Sets the absolute floor.",9,"start","normal","#444"),
    R(14,72,550,40,"#d5d5d5","#333",1.5),
    Tx(18,90,"Tier 2 — Human / Rule-Based Heuristic (domain expert rules)",10,"start","bold"),
    Tx(18,106,"Real production floor. Model < heuristic = NOT production-ready.",9,"start","normal","#444"),
    R(14,118,550,40,"#e0e0e0","#333",1.5),
    Tx(18,136,"Tier 3 — Simple ML (Logistic Regression / Decision Tree)",10,"start","bold"),
    Tx(18,152,"Fast, interpretable, competitive on structured data.",9,"start","normal","#444"),
    R(14,164,550,40,"#ebebeb","#333",1.5),
    Tx(18,182,"Tier 4 — SotA / Published Reference",10,"start","bold"),
    Tx(18,198,"Best known result on this task type. Sets the upper bound.",9,"start","normal","#444"),
    R(14,210,550,22,"#f5f5f5","#aaa",1),
    Tx(16,226,"Never skip Tier 2. Model < heuristic = not production-ready. Full stop.",9,"start","normal","#333"),
  wc)

  # ── CH7-A: Batch vs Online ────────────────────────────────────────────────
  ch7a <- P(wo(230),
    Tx(14,18,"BATCH PREDICTION",12,"start","bold"),
    R(14,28,100,32,"#eee","#333",1.5), Tx(64,48,"User Features",9,"middle"),
    Ar(114,44,150,44), R(150,28,88,32,"#ddd","#333",1.5), Tx(194,48,"ML Model",9,"middle"),
    Ar(238,44,276,44), R(276,28,112,32,"#eee","#333",1.5), Tx(332,44,"Predictions",9,"middle"),
    Tx(332,58,"(cached)",8,"middle","normal","#777"),
    Tx(14,80,"Latency: hours. High throughput. Pre-compute top-k per user.",9,"start","normal","#666"),
    Li(10,94,570,94,"#ccc",1),
    Tx(14,110,"ONLINE PREDICTION (streaming)",12,"start","bold"),
    El(64,138,52,20,"#eee"), Tx(64,142,"User Request",9,"middle"),
    Ar(116,138,154,138), R(154,126,112,24,"#ddd","#333",1.5), Tx(210,143,"Feature Lookup",9,"middle"),
    Ar(266,138,304,138), R(304,126,88,24,"#ddd","#333",1.5), Tx(348,143,"ML Model",9,"middle"),
    Ar(392,138,430,138), El(472,138,42,20,"#eee"), Tx(472,142,"Response",9,"middle"),
    Tx(14,178,"Latency: ms. Real-time features. Higher infra cost.",9,"start","normal","#666"),
    R(14,192,550,22,"#f5f5f5","#aaa",1),
    Tx(16,208,"Latency SLO < 200ms = online. Latency-tolerant = batch.",9,"start","normal","#333"),
  wc)

  # ── CH7-B: Online Prediction Architecture ────────────────────────────────
  ch7b <- P(wo(280),
    R(10,10,560,258,"#fafafa","#555",1.5,8),
    Tx(290,30,"ONLINE PREDICTION ARCHITECTURE (Fig 7-6)",10,"middle","bold"),
    R(22,44,110,46,"#e8e8e8","#333",1.5), Tx(77,72,"App",13,"middle","bold"),
    El(72,158,56,26,"#e0e0e0"), Tx(72,152,"Real-time",9,"middle","bold"), Tx(72,166,"Transport",9,"middle","bold"),
    El(248,188,82,26,"#ddd"), Tx(248,184,"Data Warehouse",9,"middle","bold"),
    Tx(248,198,"(batch features)",8,"middle","normal","#777"),
    R(412,44,138,78,"#ccc","#333",2), Tx(481,80,"Prediction",12,"middle","bold"), Tx(481,98,"Service",12,"middle","bold"),
    Ar(132,62,412,72), Tx(256,58,"1 Request",8,"middle","normal","#666"),
    Ar(412,92,132,86), Tx(256,80,"3 Prediction",8,"middle","normal","#666"),
    Ar(86,90,86,132), Tx(90,115,"logs",8,"start","normal","#999"),
    Ar(128,164,412,108), Tx(258,135,"streaming features",8,"middle","normal","#666"),
    Ar(330,192,412,122,TRUE), Tx(356,168,"2 batch features",8,"middle","normal","#999"),
    Tx(20,244,"Streaming features + batch features both feed the prediction service.",8,"start","normal","#666"),
  wc)

  # ── CH8-A: Three Types of Drift ───────────────────────────────────────────
  ch8a <- P(wo(232),
    Tx(290,18,"THREE TYPES OF DISTRIBUTION SHIFT",12,"middle","bold"),
    R(10,26,172,94,"#eee","#333",1.5), Tx(96,46,"COVARIATE SHIFT",10,"middle","bold"),
    Tx(14,62,"P(X) changes.",9,"start"), Tx(14,77,"P(Y|X) same.",9,"start"),
    Tx(14,92,"e.g. user demographics",8,"start","normal","#777"),
    R(194,26,172,94,"#e4e4e4","#333",1.5), Tx(280,46,"LABEL SHIFT",10,"middle","bold"),
    Tx(198,62,"P(Y) changes.",9,"start"), Tx(198,77,"e.g. seasonality",9,"start"),
    Tx(198,92,"shifts class balance",8,"start","normal","#777"),
    R(378,26,186,94,"#d8d8d8","#333",1.5), Tx(471,46,"CONCEPT DRIFT",10,"middle","bold"),
    Tx(382,62,"P(Y|X) changes.",9,"start"), Tx(382,77,"Relationship changes.",9,"start"),
    Tx(382,92,"Hardest to detect!",8,"start","normal","#c00"),
    Tx(14,142,"DETECTION: KS-Test (continuous) | Chi-square (categorical)",10,"start","bold"),
    Tx(14,160,"PSI: < 0.10 stable  |  0.10-0.20 warn  |  > 0.20 retrain",9,"start"),
    Tx(14,178,"Monitor prediction distribution (early signal, no labels needed)",9,"start"),
  wc)

  # ── CH8-B: PSI ────────────────────────────────────────────────────────────
  ch8b <- P(wo(252),
    Tx(290,18,"PSI — Population Stability Index",12,"middle","bold"),
    Tx(14,34,"PSI = sum( (Actual% - Expected%) x ln(Actual% / Expected%) )",10,"start"),
    Li(10,46,570,46,"#ccc",1),
    R(10,54,158,46,"#e8e8e8","#333",1.5), Tx(89,74,"PSI < 0.10",11,"middle","bold"), Tx(89,90,"STABLE",10,"middle"),
    R(178,54,174,46,"#d8d8d8","#333",1.5), Tx(265,74,"PSI 0.10-0.20",11,"middle","bold"), Tx(265,90,"INVESTIGATE",10,"middle"),
    R(362,54,200,46,"#c8c8c8","#333",1.5), Tx(462,74,"PSI > 0.20",11,"middle","bold"), Tx(462,90,"RETRAIN",10,"middle"),
    Tx(14,120,"Training (baseline):",10,"start","bold"),
    R(14,128,76,34,"#aaa","#333",1), Tx(52,150,"30%",10,"middle","bold","#fff"),
    R(94,140,76,22,"#aaa","#333",1), Tx(132,155,"25%",9,"middle","normal","#fff"),
    R(174,134,76,28,"#aaa","#333",1), Tx(212,152,"28%",9,"middle","normal","#fff"),
    R(254,146,76,16,"#aaa","#333",1), Tx(292,157,"17%",9,"middle","normal","#fff"),
    Tx(14,186,"Serving (today):",10,"start","bold"),
    R(14,194,76,16,"#555","#333",1), Tx(52,206,"18%",8,"middle","normal","#fff"),
    R(94,194,76,34,"#555","#333",1), Tx(132,215,"38%",9,"middle","normal","#fff"),
    R(174,194,76,14,"#555","#333",1), Tx(212,204,"15%",8,"middle","normal","#fff"),
    R(254,194,76,24,"#555","#333",1), Tx(292,210,"29%",8,"middle","normal","#fff"),
    Tx(360,226,"PSI = 0.28 — RETRAIN",11,"start","bold"),
  wc)

  # ── CH9-A: Stateless vs Stateful ─────────────────────────────────────────
  ch9a <- P(wo(265),
    Tx(290,18,"STATELESS vs STATEFUL RETRAINING",12,"middle","bold"),
    R(10,28,256,128,"#f0f0f0","#333",1.5), Tx(138,48,"STATELESS",11,"middle","bold"),
    Tx(14,65,"Train from scratch on fresh data.",9,"start"),
    Tx(14,81,"No catastrophic forgetting",9,"start"),
    Tx(14,96,"Clean slate",9,"start"),
    Tx(14,111,"Expensive (full train each time)",9,"start"),
    Tx(14,148,"Default for most organisations.",8,"start","normal","#777"),
    R(296,28,256,128,"#e4e4e4","#333",1.5), Tx(424,48,"STATEFUL",11,"middle","bold"),
    Tx(300,65,"Fine-tune on new data only.",9,"start"),
    Tx(300,81,"Much cheaper",9,"start"),
    Tx(300,96,"Faster convergence",9,"start"),
    Tx(300,111,"Catastrophic forgetting risk",9,"start"),
    Tx(300,148,"Good for large NNs / LLMs.",8,"start","normal","#777"),
    Tx(14,178,"RETRAINING TRIGGERS:",10,"start","bold"),
    Tx(14,194,"Time-based — every 24h / 7d",9,"start"),
    Tx(14,210,"Performance-based — metric drops below threshold",9,"start"),
    Tx(14,226,"Drift-based — PSI > 0.20 on key features",9,"start"),
    Tx(14,242,"Volume-based — N new labelled examples available",9,"start"),
  wc)

  # ── CH9-B: Champion Challenger ────────────────────────────────────────────
  ch9b <- P(wo(240),
    Tx(290,18,"CHAMPION-CHALLENGER ROLLOUT",12,"middle","bold"),
    R(10,28,108,34,"#eee","#333",1.5), Tx(64,49,"All Traffic",10,"middle"),
    Ar(118,45,168,45), Di(206,45,84,34,"#ddd"), Tx(206,49,"Route?",9,"middle"),
    Ar(206,28,256,14), Tx(224,12,"95%",8,"middle","normal","#999"),
    Ar(248,60,290,78), Tx(255,74,"5%",8,"middle","normal","#999"),
    R(256,4,138,26,"#ddd","#333",1.5), Tx(325,21,"Champion v1",9,"middle","bold"),
    R(290,70,138,26,"#ccc","#333",1.5), Tx(359,86,"Challenger v2",9,"middle","bold"),
    Ar(394,17,434,48), Ar(428,83,434,64),
    R(434,38,118,34,"#e8e8e8","#333",1.5), Tx(493,53,"Compare KPI",9,"middle"),
    Tx(493,67,"(stat. test)",8,"middle","normal","#777"),
    Tx(14,120,"STRATEGIES:",10,"start","bold"),
    Tx(14,138,"Shadow   — challenger runs, logs only (safe, no user exposure)",9,"start"),
    Tx(14,154,"Canary   — 1-5% live traffic to challenger",9,"start"),
    Tx(14,170,"A/B Test — controlled 50/50 split with statistical test",9,"start"),
    Tx(14,186,"Blue-Green — instant full swap, old version on standby",9,"start"),
    R(14,202,550,22,"#f5f5f5","#aaa",1),
    Tx(16,218,"Guardrail: violate latency SLO or error rate = auto rollback",9,"start","normal","#333"),
  wc)

  # ── CH10-A: ML Platform Stack ─────────────────────────────────────────────
  ch10a <- P(wo(258),
    Tx(290,18,"ML PLATFORM STACK",12,"middle","bold"),
    R(14,24,550,26,"#bbb","#333",1.5), Tx(290,42,"ML Applications / Products",10,"middle","bold"),
    R(14,56,550,26,"#c8c8c8","#333",1.5), Tx(290,74,"Model Serving / Prediction Service  (Triton, TorchServe, vLLM)",10,"middle","bold"),
    R(14,88,266,26,"#d5d5d5","#333",1.5), Tx(147,106,"Model Registry  (MLflow, Vertex)",9,"middle"),
    R(286,88,278,26,"#d5d5d5","#333",1.5), Tx(425,106,"Experiment Tracking  (W&B, MLflow)",9,"middle"),
    R(14,120,266,26,"#e0e0e0","#333",1.5), Tx(147,138,"Feature Store  (Feast, Tecton)",9,"middle"),
    R(286,120,278,26,"#e0e0e0","#333",1.5), Tx(425,138,"Orchestration  (Airflow, Kubeflow)",9,"middle"),
    R(14,152,550,26,"#e8e8e8","#333",1.5), Tx(290,170,"Data Lake (S3/GCS)  +  Data Warehouse (BigQuery / Redshift)",10,"middle"),
    R(14,184,550,26,"#f0f0f0","#333",1.5), Tx(290,202,"Compute:  GPUs / TPUs / Cloud (GCP, AWS, Azure)",10,"middle"),
    Tx(14,232,"Build vs Buy: build when core differentiator; buy commodity infra.",9,"start","normal","#555"),
  wc)

  # ── CH10-B: Feature Store Online vs Offline ───────────────────────────────
  ch10b <- P(wo(295),
    Tx(290,18,"FEATURE STORE — Online vs Offline",12,"middle","bold"),
    R(10,28,252,156,"#f0f0f0","#333",1.5), Tx(136,48,"OFFLINE STORE",11,"middle","bold"),
    Tx(14,65,"Technology: S3, BigQuery",9,"start"), Tx(14,80,"Latency: seconds - hours",9,"start"),
    Tx(14,95,"Used for: TRAINING",10,"start","bold"), Tx(14,110,"Stores: historical values",9,"start"),
    Tx(14,125,"Point-in-time joins = temporal correctness",8,"start","normal","#777"),
    R(294,28,252,156,"#e4e4e4","#333",1.5), Tx(420,48,"ONLINE STORE",11,"middle","bold"),
    Tx(298,65,"Technology: Redis, DynamoDB",9,"start"), Tx(298,80,"Latency: < 10ms",9,"start"),
    Tx(298,95,"Used for: SERVING",10,"start","bold"), Tx(298,110,"Stores: latest values",9,"start"),
    Tx(298,125,"Keyed by entity_id",8,"start","normal","#777"),
    Ar(136,184,136,218), Ar(420,184,420,218),
    R(88,218,390,32,"#ddd","#333",2),
    Tx(290,238,"Feature Store  (Feast / Tecton / Hopsworks)",10,"middle","bold"),
    Tx(14,272,"Same feature definitions = no train-serve skew across both paths.",9,"start","normal","#555"),
  wc)

  # ── CH11-A: Feedback Loop ─────────────────────────────────────────────────
  ch11a <- P(wo(268),
    Tx(290,18,"FEEDBACK LOOP AND NATURAL LABELS",12,"middle","bold"),
    R(208,32,142,40,"#e8e8e8","#333",1.5), Tx(279,56,"ML Model",11,"middle","bold"),
    Ar(350,52,406,52), R(406,32,128,40,"#ddd","#333",1.5), Tx(470,56,"Predictions",11,"middle","bold"),
    Ar(470,72,470,126),
    R(406,126,128,40,"#ddd","#333",1.5), Tx(470,150,"User Action",11,"middle","bold"),
    Tx(410,188,"click / purchase / skip",8,"start","normal","#777"),
    Ar(406,146,248,146), Tx(302,140,"= Natural Labels",9,"middle","bold"),
    R(92,126,154,40,"#e4e4e4","#333",1.5), Tx(169,150,"Training Data",11,"middle","bold"),
    Ar(169,126,248,72),
    Tx(14,218,"Label delay: clicks (1hr) | purchases (2wks) | fraud (30+ days)",9,"start"),
    Tx(14,234,"Risk: model biases future data (popularity bias)",9,"start"),
    Tx(14,250,"Fix: holdout groups, exploration (epsilon-greedy, Thompson sampling)",9,"start"),
  wc)

  # ── CH11-B: A/B Test Design ───────────────────────────────────────────────
  ch11b <- P(wo(252),
    Tx(290,18,"A/B TEST DESIGN",12,"middle","bold"),
    R(10,28,108,34,"#eee","#333",1.5), Tx(64,49,"All Traffic",10,"middle"),
    Ar(118,45,168,45), Di(206,45,84,34,"#ddd"), Tx(206,49,"Split",10,"middle"),
    Ar(206,28,254,12), Tx(224,10,"50%",8,"middle","normal","#999"),
    Ar(248,60,290,78), Tx(256,74,"50%",8,"middle","normal","#999"),
    R(290,2,128,26,"#ddd","#333",1.5), Tx(354,18,"Control (A)",9,"middle","bold"),
    R(290,68,128,26,"#ccc","#333",1.5), Tx(354,84,"Treatment (B)",9,"middle","bold"),
    Ar(418,15,455,46), Ar(418,81,455,64),
    R(455,34,98,34,"#e8e8e8","#333",1.5), Tx(504,49,"Compare",9,"middle"), Tx(504,62,"KPI",9,"middle"),
    Tx(14,118,"REQUIREMENTS FOR VALID A/B TEST:",10,"start","bold"),
    Tx(14,135,"Power analysis BEFORE running — determine sample size needed",9,"start"),
    Tx(14,151,"MDE (min detectable effect) — what delta is business-meaningful?",9,"start"),
    Tx(14,167,"alpha = 0.05 (false positive)   beta = 0.20 = power 80%",9,"start"),
    Tx(14,183,"Guardrail metrics — secondary KPIs that must NOT regress",9,"start"),
    Tx(14,199,"No peeking — decide duration in advance, do not stop early",9,"start"),
    R(14,214,550,22,"#f5f5f5","#aaa",1),
    Tx(16,230,"Novelty effect: run for 2+ weeks to let curiosity boost decay.",9,"start","normal","#555"),
  wc)

  # ── CH12-A: E2E System Map ────────────────────────────────────────────────
  ch12a <- P(wo(272),
    Tx(290,18,"END-TO-END ML SYSTEM",12,"middle","bold"),
    El(58,44,50,20,"#eee"), Tx(58,38,"Data",9,"middle","bold"), Tx(58,52,"Sources",9,"middle","bold"),
    Ar(108,44,146,44), R(146,32,104,24,"#e4e4e4","#333",1.5), Tx(198,48,"Data Pipeline",9,"middle","bold"),
    Ar(250,44,290,44), R(290,32,104,24,"#ddd","#333",1.5),
    Tx(342,40,"Feature",9,"middle","bold"), Tx(342,52,"Engineering",9,"middle","bold"),
    Ar(394,44,432,44), R(432,32,98,24,"#ccc","#333",2), Tx(481,48,"Model",10,"middle","bold"),
    Ar(481,56,481,92),
    R(416,92,130,32,"#ddd","#333",1.5), Tx(481,112,"Eval / Registry",9,"middle","bold"),
    Ar(416,108,378,108), R(268,92,120,32,"#e4e4e4","#333",1.5), Tx(328,112,"Serving / API",9,"middle","bold"),
    Ar(268,108,214,108), R(88,92,128,32,"#eee","#333",1.5), Tx(152,112,"Application",9,"middle","bold"),
    Ar(102,124,70,166),
    El(52,178,48,20,"#eee"), Tx(52,172,"User",9,"middle","bold"), Tx(52,186,"Feedback",9,"middle","bold"),
    Ar(52,166,52,64,TRUE),
    Tx(14,232,"Monitoring: data drift, prediction drift, business KPI dashboards",9,"start"),
    Tx(14,248,"Retraining: PSI-triggered or scheduled = stateless or stateful",9,"start"),
  wc)

  # ── CH12-B: Interview Framework ───────────────────────────────────────────
  ch12b <- P(wo(316),
    Tx(290,18,"ML DESIGN INTERVIEW FRAMEWORK",12,"middle","bold"),
    R(14,26,550,26,"#bbb","#333",1.5), Tx(18,44,"0-5m   SCOPE:  clarify goal, users, scale, latency SLO, success metrics",10,"start","bold"),
    R(14,58,550,26,"#c8c8c8","#333",1.5), Tx(18,76,"5-15m  DATA:  sources, labelling, format, batch vs streaming, class imbalance",10,"start","bold"),
    R(14,90,550,26,"#d5d5d5","#333",1.5), Tx(18,108,"15-30m FEATURES:  feature engineering, feature store, point-in-time joins",10,"start","bold"),
    R(14,122,550,26,"#ddd","#333",1.5), Tx(18,140,"15-30m MODEL:  baseline then selection then loss fn then HPO then ensemble",10,"start","bold"),
    R(14,154,550,26,"#e4e4e4","#333",1.5), Tx(18,172,"30-40m EVAL:  offline metrics, sliced evaluation, calibration, A/B design",10,"start","bold"),
    R(14,186,550,26,"#ebebeb","#333",1.5), Tx(18,204,"40-45m DEPLOY+OPS:  serving, compression, drift detection, retraining",10,"start","bold"),
    Li(14,220,564,220,"#bbb",1),
    Tx(14,236,"ALWAYS: name baselines. Justify metric. Define train-serve skew mitigation.",9,"start"),
    Tx(14,252,"ALWAYS: sliced eval as release gate. PSI + prediction dist for monitoring.",9,"start"),
    R(14,266,550,22,"#f5f5f5","#aaa",1),
    Tx(16,282,"Start with the simplest model that could possibly work.",9,"start","bold","#000"),
  wc)

  # ── Box and row builders ──────────────────────────────────────────────────
  box <- function(num, title, svg_html) {
    div(style="background:#fff;border-radius:10px;overflow:hidden;box-shadow:0 4px 18px rgba(0,44,60,0.14);",
      div(style="background:linear-gradient(90deg,#002C3C,#008A82);padding:8px 14px;display:flex;align-items:center;gap:10px;",
        tags$span(style="background:rgba(255,255,255,0.18);border:1px solid rgba(255,255,255,0.3);color:#fff;border-radius:5px;padding:2px 8px;font-size:10px;font-weight:800;", num),
        tags$span(style="color:#fff;font-size:12px;font-weight:700;", title)
      ),
      div(style="padding:10px;background:#fff;", HTML(svg_html))
    )
  }

  row <- function(num, heading, t1, s1, t2, s2) {
    tagList(
      div(style="margin:22px 0 10px;padding:8px 16px;background:linear-gradient(90deg,#002C3C,#008A82);border-radius:8px;color:#fff;font-weight:700;font-size:13px;",
        tags$span(style="opacity:0.7;margin-right:10px;", num), heading),
      fluidRow(column(6, box(num, t1, s1)), column(6, box(num, t2, s2)))
    )
  }

  tagList(
    div(class="meta-hero",
      tags$h1("Teaching Whiteboard Diagrams"),
      tags$h2("24 B&W diagrams — screenshot and paste into any whiteboard app"),
      div(span(class="hero-badge","12 Chapters"), span(class="hero-badge","24 Diagrams"),
          span(class="hero-badge","Screenshot Ready"), span(class="hero-badge","B&W")),
      tags$p(style="color:rgba(255,255,255,0.7);font-size:12px;margin-top:10px;",
        "Right-click any diagram to save as image, or screenshot and paste into your whiteboard.")
    ),
    row("Ch.1","ML Systems in Production","The Full ML System Stack",ch1a,"Business to ML Objective",ch1b),
    row("Ch.2","ML System Design Process","The 6-Step Iterative Dev Cycle",ch2a,"Data Science Hierarchy of Needs",ch2b),
    row("Ch.3","Data Engineering Fundamentals","Row vs Columnar Storage",ch3a,"Batch vs Streaming Pipeline",ch3b),
    row("Ch.4","Training Data","Labelling Strategies Comparison",ch4a,"Class Imbalance and Resampling",ch4b),
    row("Ch.5","Feature Engineering","Feature Store Architecture",ch5a,"Train-Serve Skew Diagram",ch5b),
    row("Ch.6","Model Development and Evaluation","ROC and Precision-Recall Curves",ch6a,"Baseline Hierarchy",ch6b),
    row("Ch.7","Model Deployment and Prediction","Batch vs Online Prediction",ch7a,"Online Prediction Architecture",ch7b),
    row("Ch.8","Data Distribution Shifts","Three Types of Distribution Shift",ch8a,"PSI Drift Detection",ch8b),
    row("Ch.9","Continual Learning","Stateless vs Stateful Retraining",ch9a,"Champion-Challenger Rollout",ch9b),
    row("Ch.10","Infrastructure and Tooling","ML Platform Stack",ch10a,"Feature Store Online vs Offline",ch10b),
    row("Ch.11","The Human Side of ML","Feedback Loop and Natural Labels",ch11a,"A/B Test Design",ch11b),
    row("Ch.12","System Design Summary","End-to-End ML System Map",ch12a,"Interview Answer Framework",ch12b)
  )
}

chapter_diagrams_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    prep_manager$update_progress("chapter_diagrams", 50)
  })
}
