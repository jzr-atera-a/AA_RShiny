/* dg_data.js — 24 B&W sketch diagram object arrays
   Chip Huyen 'Designing ML Systems' — 2 diagrams per chapter, Ch.1–12
   Format: canvas objects compatible with dg_engine.js drawObj()
   All B&W: stroke #000/#333/#555, fill #fff/#eee/#ddd/#ccc
*/
var DIAGRAMS = {};

/* ════════════════════════════════════════════════════════
   CH1 — ML Systems in Production
════════════════════════════════════════════════════════ */
DIAGRAMS['ch1_stack'] = [
  {type:'rect',x:10,y:10,w:560,h:250,stroke:'#333',fill:'#fafafa',sw:2},
  {type:'txt',x:230,y:36,text:'ML SYSTEM',stroke:'#000',fill:'none',sw:1,fs:14,ff:'Arial'},
  {type:'rect',x:25,y:50,w:530,h:38,stroke:'#333',fill:'#ccc',sw:2},
  {type:'txt',x:80,y:74,text:'Deployment  /  Monitoring  /  Updating of Logics     [Ch.7, 8, 9]',stroke:'#000',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'rect',x:25,y:97,w:168,h:56,stroke:'#333',fill:'#ddd',sw:2},
  {type:'txt',x:55,y:122,text:'Feature Eng.',stroke:'#000',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'txt',x:65,y:142,text:'[Ch.5]',stroke:'#555',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'rect',x:203,y:97,w:168,h:56,stroke:'#333',fill:'#ddd',sw:2},
  {type:'txt',x:220,y:122,text:'ML Algorithms',stroke:'#000',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'txt',x:238,y:142,text:'[Ch.6]',stroke:'#555',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'rect',x:381,y:97,w:174,h:56,stroke:'#333',fill:'#ddd',sw:2},
  {type:'txt',x:398,y:122,text:'Evaluation',stroke:'#000',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'txt',x:405,y:142,text:'[Ch.6]',stroke:'#555',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'rect',x:25,y:162,w:530,h:40,stroke:'#333',fill:'#bbb',sw:2},
  {type:'txt',x:220,y:187,text:'Data     [Ch.3 & 4]',stroke:'#000',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'rect',x:25,y:210,w:530,h:30,stroke:'#333',fill:'#aaa',sw:2},
  {type:'txt',x:205,y:230,text:'Infrastructure     [Ch.10]',stroke:'#000',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'rect',x:10,y:52,w:115,h:30,stroke:'#555',fill:'#fff',sw:1},
  {type:'txt',x:15,y:72,text:'Users  [Ch.11]',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'arr',x:125,y:67,x2:165,y2:69,stroke:'#333',fill:'#333',sw:2},
  {type:'rect',x:10,y:108,w:120,h:28,stroke:'#555',fill:'#fff',sw:1},
  {type:'txt',x:15,y:126,text:'Biz Reqs [Ch.1]',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'arr',x:130,y:122,x2:165,y2:122,stroke:'#333',fill:'#333',sw:2},
  {type:'rect',x:10,y:180,w:120,h:28,stroke:'#555',fill:'#fff',sw:1},
  {type:'txt',x:15,y:198,text:'ML Devs (all)',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'arr',x:130,y:194,x2:165,y2:194,stroke:'#333',fill:'#333',sw:2}
];

DIAGRAMS['ch1_objectives'] = [
  {type:'rect',x:20,y:30,w:185,h:58,stroke:'#333',fill:'#eee',sw:2},
  {type:'txt',x:30,y:55,text:'Business Goal',stroke:'#000',fill:'none',sw:1,fs:13,ff:'Arial'},
  {type:'txt',x:30,y:78,text:'Increase Revenue',stroke:'#555',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'arr',x:205,y:59,x2:280,y2:59,stroke:'#000',fill:'#000',sw:2},
  {type:'txt',x:210,y:52,text:'TRANSLATE',stroke:'#555',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'rect',x:280,y:30,w:185,h:58,stroke:'#333',fill:'#e0e0e0',sw:2},
  {type:'txt',x:292,y:55,text:'ML Objective',stroke:'#000',fill:'none',sw:1,fs:13,ff:'Arial'},
  {type:'txt',x:292,y:78,text:'Maximise click-through',stroke:'#555',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'arr',x:372,y:88,x2:372,y2:130,stroke:'#000',fill:'#000',sw:2},
  {type:'rect',x:280,y:130,w:185,h:50,stroke:'#333',fill:'#ddd',sw:2},
  {type:'txt',x:290,y:152,text:'ML Metric',stroke:'#000',fill:'none',sw:1,fs:12,ff:'Arial'},
  {type:'txt',x:290,y:172,text:'AUC / NDCG@10',stroke:'#555',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'line',x:20,y:120,x2:560,y2:120,stroke:'#ccc',fill:'#ccc',sw:1},
  {type:'txt',x:20,y:116,text:'Constraints (come from business, not data):',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:20,y:148,text:'• Latency SLO  p99 < 100ms',stroke:'#444',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:20,y:165,text:'• Interpretability required?',stroke:'#444',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:20,y:182,text:'• Fairness / regulatory',stroke:'#444',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:20,y:199,text:'• Training cost budget',stroke:'#444',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'rect',x:20,y:215,w:550,h:26,stroke:'#888',fill:'#f5f5f5',sw:1},
  {type:'txt',x:28,y:233,text:'⚠  Misaligned objective = building the wrong system entirely',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'}
];

/* ════════════════════════════════════════════════════════
   CH2 — ML System Design Process
════════════════════════════════════════════════════════ */
DIAGRAMS['ch2_cycle'] = [
  {type:'ell',x:195,y:8,w:150,h:48,stroke:'#333',fill:'#e0e0e0',sw:2},
  {type:'txt',x:218,y:38,text:'1. Project Scope',stroke:'#000',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'ell',x:390,y:85,w:150,h:48,stroke:'#333',fill:'#e0e0e0',sw:2},
  {type:'txt',x:408,y:115,text:'2. Data Eng.',stroke:'#000',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'ell',x:390,y:200,w:150,h:48,stroke:'#333',fill:'#e0e0e0',sw:2},
  {type:'txt',x:405,y:230,text:'3. Model Dev.',stroke:'#000',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'ell',x:195,y:270,w:150,h:48,stroke:'#333',fill:'#e0e0e0',sw:2},
  {type:'txt',x:215,y:300,text:'4. Deployment',stroke:'#000',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'ell',x:8,y:200,w:150,h:48,stroke:'#333',fill:'#e0e0e0',sw:2},
  {type:'txt',x:14,y:222,text:'5. Monitoring &',stroke:'#000',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:18,y:238,text:'Cont. Learning',stroke:'#000',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'ell',x:8,y:85,w:150,h:48,stroke:'#333',fill:'#e0e0e0',sw:2},
  {type:'txt',x:20,y:115,text:'6. Biz Analysis',stroke:'#000',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'arr',x:270,y:32,x2:395,y2:100,stroke:'#333',fill:'#333',sw:2},
  {type:'arr',x:465,y:133,x2:465,y2:200,stroke:'#333',fill:'#333',sw:2},
  {type:'arr',x:390,y:235,x2:345,y2:285,stroke:'#333',fill:'#333',sw:2},
  {type:'arr',x:255,y:294,x2:170,y2:285,stroke:'#333',fill:'#333',sw:2},
  {type:'arr',x:83,y:248,x2:83,y2:133,stroke:'#333',fill:'#333',sw:2},
  {type:'arr',x:158,y:100,x2:218,y2:40,stroke:'#333',fill:'#333',sw:2},
  {type:'txt',x:200,y:165,text:'Non-linear!',stroke:'#666',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:175,y:182,text:'Any step → prior step',stroke:'#666',fill:'none',sw:1,fs:9,ff:'Arial'}
];

DIAGRAMS['ch2_pyramid'] = [
  {type:'pen',pts:[[290,15],[540,268],[40,268],[290,15]],stroke:'#333',fill:'none',sw:2},
  {type:'line',x:90,y:218,x2:490,y2:218,stroke:'#555',fill:'#555',sw:1},
  {type:'line',x:120,y:168,x2:460,y2:168,stroke:'#555',fill:'#555',sw:1},
  {type:'line',x:155,y:120,x2:425,y2:120,stroke:'#555',fill:'#555',sw:1},
  {type:'line',x:198,y:72,x2:382,y2:72,stroke:'#555',fill:'#555',sw:1},
  {type:'txt',x:190,y:256,text:'① COLLECT — logging, sensors, events',stroke:'#000',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'txt',x:165,y:207,text:'② MOVE/STORE — pipelines, ETL, data storage',stroke:'#000',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'txt',x:152,y:158,text:'③ EXPLORE — cleaning, anomaly detection',stroke:'#000',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'txt',x:165,y:110,text:'④ AGGREGATE — features, training data',stroke:'#000',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'txt',x:205,y:62,text:'⑤ LEARN — A/B, ML',stroke:'#000',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'txt',x:270,y:28,text:'AI',stroke:'#000',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:20,y:295,text:'⚠  Most orgs rush to AI (apex) before fixing layers 1-3. This is the #1 production failure.',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'}
];

/* ════════════════════════════════════════════════════════
   CH3 — Data Engineering Fundamentals
════════════════════════════════════════════════════════ */
DIAGRAMS['ch3_storage'] = [
  {type:'txt',x:20,y:20,text:'ROW-ORIENTED  (CSV, JSON)',stroke:'#000',fill:'none',sw:1,fs:12,ff:'Arial'},
  {type:'txt',x:20,y:38,text:'Fast writes. Slow analytics. Read entire row for any query.',stroke:'#555',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'rect',x:20,y:50,w:255,h:28,stroke:'#333',fill:'#ddd',sw:1},
  {type:'txt',x:26,y:69,text:'user_id  |  age  |  city  |  purchase_amt',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'rect',x:20,y:78,w:255,h:22,stroke:'#999',fill:'#fff',sw:1},
  {type:'txt',x:26,y:94,text:'001  |  28  |  NYC  |  49.99',stroke:'#444',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'rect',x:20,y:100,w:255,h:22,stroke:'#999',fill:'#f5f5f5',sw:1},
  {type:'txt',x:26,y:116,text:'002  |  34  |  LA   |  12.50',stroke:'#444',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'rect',x:20,y:122,w:255,h:22,stroke:'#999',fill:'#fff',sw:1},
  {type:'txt',x:26,y:138,text:'003  |  22  |  SF   |  87.00',stroke:'#444',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:300,y:20,text:'COLUMNAR  (Parquet, ORC)',stroke:'#000',fill:'none',sw:1,fs:12,ff:'Arial'},
  {type:'txt',x:300,y:38,text:'Slow writes. Fast analytics. Read only columns needed.',stroke:'#555',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'rect',x:300,y:50,w:58,h:94,stroke:'#333',fill:'#ddd',sw:1},
  {type:'txt',x:312,y:70,text:'uid',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:308,y:90,text:'001',stroke:'#444',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'txt',x:308,y:108,text:'002',stroke:'#444',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'txt',x:308,y:126,text:'003',stroke:'#444',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'rect',x:362,y:50,w:50,h:94,stroke:'#333',fill:'#eee',sw:1},
  {type:'txt',x:371,y:70,text:'age',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:372,y:90,text:'28',stroke:'#444',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'txt',x:372,y:108,text:'34',stroke:'#444',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'txt',x:372,y:126,text:'22',stroke:'#444',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'rect',x:416,y:50,w:55,h:94,stroke:'#333',fill:'#ddd',sw:1},
  {type:'txt',x:422,y:70,text:'city',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:420,y:90,text:'NYC',stroke:'#444',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'txt',x:423,y:108,text:'LA',stroke:'#444',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'txt',x:423,y:126,text:'SF',stroke:'#444',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'rect',x:475,y:50,w:70,h:94,stroke:'#333',fill:'#eee',sw:1},
  {type:'txt',x:480,y:70,text:'purchase',stroke:'#333',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'txt',x:488,y:90,text:'49.99',stroke:'#444',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'txt',x:488,y:108,text:'12.50',stroke:'#444',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'txt',x:488,y:126,text:'87.00',stroke:'#444',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'txt',x:20,y:165,text:'Default for ML: Parquet. Columnar = read only the columns your model needs → 10-100x faster.',stroke:'#000',fill:'none',sw:1,fs:10,ff:'Arial'}
];

DIAGRAMS['ch3_pipeline'] = [
  {type:'txt',x:20,y:18,text:'BATCH PIPELINE',stroke:'#000',fill:'none',sw:1,fs:13,ff:'Arial'},
  {type:'rect',x:20,y:35,w:100,h:36,stroke:'#333',fill:'#eee',sw:2},
  {type:'txt',x:28,y:58,text:'Data Store',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'arr',x:120,y:53,x2:172,y2:53,stroke:'#333',fill:'#333',sw:2},
  {type:'rect',x:172,y:35,w:100,h:36,stroke:'#333',fill:'#ddd',sw:2},
  {type:'txt',x:182,y:58,text:'Batch ETL',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'arr',x:272,y:53,x2:326,y2:53,stroke:'#333',fill:'#333',sw:2},
  {type:'rect',x:326,y:35,w:100,h:36,stroke:'#333',fill:'#eee',sw:2},
  {type:'txt',x:336,y:58,text:'Features',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'arr',x:426,y:53,x2:478,y2:53,stroke:'#333',fill:'#333',sw:2},
  {type:'rect',x:478,y:35,w:80,h:36,stroke:'#333',fill:'#ddd',sw:2},
  {type:'txt',x:488,y:58,text:'Model',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:20,y:88,text:'Latency: hours–days. Throughput: high. Cost: low per record.',stroke:'#555',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'line',x:10,y:106,x2:570,y2:106,stroke:'#ccc',fill:'#ccc',sw:1},
  {type:'txt',x:20,y:124,text:'STREAMING PIPELINE',stroke:'#000',fill:'none',sw:1,fs:13,ff:'Arial'},
  {type:'ell',x:20,y:138,w:105,h:36,stroke:'#333',fill:'#eee',sw:2},
  {type:'txt',x:27,y:161,text:'Live Events',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'arr',x:125,y:156,x2:172,y2:156,stroke:'#333',fill:'#333',sw:2},
  {type:'rect',x:172,y:138,w:105,h:36,stroke:'#333',fill:'#ddd',sw:2},
  {type:'txt',x:178,y:158,text:'Kafka/Kinesis',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'arr',x:277,y:156,x2:326,y2:156,stroke:'#333',fill:'#333',sw:2},
  {type:'rect',x:326,y:138,w:105,h:36,stroke:'#333',fill:'#eee',sw:2},
  {type:'txt',x:334,y:158,text:'Flink/Spark',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'arr',x:431,y:156,x2:478,y2:156,stroke:'#333',fill:'#333',sw:2},
  {type:'rect',x:478,y:138,w:80,h:36,stroke:'#333',fill:'#ddd',sw:2},
  {type:'txt',x:485,y:160,text:'Model',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:20,y:194,text:'Latency: ms–seconds. Enables real-time features. Higher cost.',stroke:'#555',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:20,y:212,text:'Decision: use batch for training data; streaming for serving features.',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'}
];

/* ════════════════════════════════════════════════════════
   CH4 — Training Data
════════════════════════════════════════════════════════ */
DIAGRAMS['ch4_labelling'] = [
  {type:'txt',x:20,y:18,text:'LABELLING STRATEGIES',stroke:'#000',fill:'none',sw:1,fs:13,ff:'Arial'},
  {type:'rect',x:20,y:36,w:165,h:85,stroke:'#333',fill:'#f0f0f0',sw:2},
  {type:'txt',x:55,y:58,text:'Hand Labels',stroke:'#000',fill:'none',sw:1,fs:12,ff:'Arial'},
  {type:'txt',x:28,y:76,text:'✓ High quality',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:28,y:93,text:'✗ Slow & expensive',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:28,y:110,text:'✗ Annotator bias',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'rect',x:198,y:36,w:165,h:85,stroke:'#333',fill:'#e8e8e8',sw:2},
  {type:'txt',x:222,y:58,text:'Natural Labels',stroke:'#000',fill:'none',sw:1,fs:12,ff:'Arial'},
  {type:'txt',x:205,y:76,text:'✓ Free & scalable',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:205,y:93,text:'✗ Noisy & delayed',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:205,y:110,text:'e.g. clicks, ratings',stroke:'#555',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'rect',x:376,y:36,w:175,h:85,stroke:'#333',fill:'#e0e0e0',sw:2},
  {type:'txt',x:398,y:58,text:'Programmatic',stroke:'#000',fill:'none',sw:1,fs:12,ff:'Arial'},
  {type:'txt',x:383,y:76,text:'✓ Scalable & cheap',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:383,y:93,text:'✗ Noisy output',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:383,y:110,text:'Snorkel — LF + LM',stroke:'#555',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'txt',x:20,y:142,text:'LABEL QUALITY:  Inter-annotator agreement — Cohen\'s kappa > 0.7 acceptable',stroke:'#000',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:20,y:160,text:'Low kappa → task is ambiguous, not just noisy annotators',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:20,y:178,text:'LABEL DELAY:  clicks (1h) | purchases (2 wks) | fraud (30+ days)',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'rect',x:20,y:194,w:545,h:24,stroke:'#888',fill:'#f5f5f5',sw:1},
  {type:'txt',x:28,y:211,text:'Longer delay = slower retraining cycle = model stays stale longer',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'}
];

DIAGRAMS['ch4_imbalance'] = [
  {type:'txt',x:20,y:18,text:'CLASS IMBALANCE  (e.g. fraud: 99% neg / 1% pos)',stroke:'#000',fill:'none',sw:1,fs:12,ff:'Arial'},
  {type:'rect',x:20,y:36,w:540,h:26,stroke:'#555',fill:'#e8e8e8',sw:1},
  {type:'txt',x:26,y:54,text:'Original: [████████████████████████████████████░░] 99/1 split',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:20,y:80,text:'STRATEGY 1 — Oversampling  (SMOTE: synthesise minority)',stroke:'#000',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'rect',x:20,y:92,w:540,h:22,stroke:'#555',fill:'#f5f5f5',sw:1},
  {type:'txt',x:26,y:108,text:'[████████████████████░░░░░░░░░░░░░░░░░░░░]  ~50/50',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:20,y:130,text:'STRATEGY 2 — Undersampling  (remove majority)',stroke:'#000',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'rect',x:20,y:142,w:540,h:22,stroke:'#555',fill:'#f5f5f5',sw:1},
  {type:'txt',x:26,y:158,text:'[████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░]  fewer total',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:20,y:182,text:'STRATEGY 3 — Focal Loss   FL = -(1-pt)^γ × log(pt)   γ=2 default',stroke:'#000',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'txt',x:20,y:200,text:'STRATEGY 4 — Class Weights   weight = 1 / class_frequency',stroke:'#000',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'rect',x:20,y:218,w:540,h:24,stroke:'#888',fill:'#f0f0f0',sw:1},
  {type:'txt',x:26,y:235,text:'⚠  Never use Accuracy on imbalanced data.  Use F1, AUC-ROC, PR-AUC per class.',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'}
];

/* ════════════════════════════════════════════════════════
   CH5 — Feature Engineering
════════════════════════════════════════════════════════ */
DIAGRAMS['ch5_featurestore'] = [
  {type:'txt',x:20,y:16,text:'FEATURE STORE ARCHITECTURE',stroke:'#000',fill:'none',sw:1,fs:13,ff:'Arial'},
  {type:'rect',x:20,y:36,w:115,h:50,stroke:'#333',fill:'#eee',sw:2},
  {type:'txt',x:25,y:58,text:'Raw Data',stroke:'#333',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'txt',x:25,y:76,text:'(events/logs)',stroke:'#555',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'arr',x:135,y:61,x2:188,y2:61,stroke:'#333',fill:'#333',sw:2},
  {type:'rect',x:188,y:36,w:135,h:50,stroke:'#333',fill:'#ddd',sw:2},
  {type:'txt',x:196,y:58,text:'Feature Pipelines',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:196,y:76,text:'(transform)',stroke:'#555',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'arr',x:323,y:61,x2:375,y2:61,stroke:'#333',fill:'#333',sw:2},
  {type:'rect',x:375,y:16,w:185,h:102,stroke:'#333',fill:'#f0f0f0',sw:2},
  {type:'txt',x:415,y:40,text:'FEATURE STORE',stroke:'#000',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'rect',x:385,y:50,w:165,h:28,stroke:'#555',fill:'#e0e0e0',sw:1},
  {type:'txt',x:392,y:68,text:'Offline Store (S3 / DWH)',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'rect',x:385,y:82,w:165,h:28,stroke:'#555',fill:'#d0d0d0',sw:1},
  {type:'txt',x:392,y:100,text:'Online Store (Redis)',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'arr',x:375,y:130,x2:315,y2:165,stroke:'#333',fill:'#333',sw:2},
  {type:'arr',x:468,y:118,x2:468,y2:165,stroke:'#333',fill:'#333',sw:2},
  {type:'rect',x:255,y:165,w:130,h:44,stroke:'#333',fill:'#eee',sw:2},
  {type:'txt',x:266,y:182,text:'Training Job',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:266,y:200,text:'(offline store)',stroke:'#555',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'rect',x:403,y:165,w:130,h:44,stroke:'#333',fill:'#eee',sw:2},
  {type:'txt',x:413,y:182,text:'Prediction Svc',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:413,y:200,text:'(online store)',stroke:'#555',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'txt',x:20,y:228,text:'Same feature code path → same output → NO train-serve skew',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'}
];

DIAGRAMS['ch5_skew'] = [
  {type:'txt',x:20,y:18,text:'TRAIN-SERVE SKEW  — Huyen\'s #1 production failure mode',stroke:'#000',fill:'none',sw:1,fs:12,ff:'Arial'},
  {type:'rect',x:20,y:40,w:230,h:90,stroke:'#333',fill:'#f5f5f5',sw:2},
  {type:'txt',x:75,y:62,text:'TRAINING',stroke:'#000',fill:'none',sw:1,fs:13,ff:'Arial'},
  {type:'txt',x:28,y:82,text:'feature_X =',stroke:'#333',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'txt',x:28,y:100,text:'log(raw_value + 1)',stroke:'#444',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'txt',x:28,y:118,text:'(log transform applied)',stroke:'#666',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'rect',x:320,y:40,w:230,h:90,stroke:'#333',fill:'#f5f5f5',sw:2},
  {type:'txt',x:380,y:62,text:'SERVING',stroke:'#000',fill:'none',sw:1,fs:13,ff:'Arial'},
  {type:'txt',x:328,y:82,text:'feature_X =',stroke:'#333',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'txt',x:328,y:100,text:'raw_value',stroke:'#444',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'txt',x:328,y:118,text:'(transform omitted!)',stroke:'#666',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:262,y:78,text:'≠',stroke:'#000',fill:'none',sw:1,fs:30,ff:'Arial'},
  {type:'rect',x:20,y:148,w:530,h:26,stroke:'#c00',fill:'#fff0f0',sw:1},
  {type:'txt',x:28,y:166,text:'Result: model receives a completely different distribution at serving → silent accuracy collapse',stroke:'#c00',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'txt',x:20,y:196,text:'SOLUTION:  Feature Store — same transformation code used in BOTH training and serving.',stroke:'#000',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'arr',x:100,y:212,x2:235,y2:240,stroke:'#333',fill:'#333',sw:2},
  {type:'arr',x:390,y:212,x2:295,y2:240,stroke:'#333',fill:'#333',sw:2},
  {type:'rect',x:235,y:240,w:130,h:36,stroke:'#333',fill:'#ddd',sw:2},
  {type:'txt',x:245,y:262,text:'Feature Store',stroke:'#000',fill:'none',sw:1,fs:12,ff:'Arial'},
  {type:'txt',x:20,y:298,text:'Also fix: point-in-time joins to prevent temporal leakage in training data.',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'}
];

/* ════════════════════════════════════════════════════════
   CH6 — Model Development & Evaluation
════════════════════════════════════════════════════════ */
DIAGRAMS['ch6_roc'] = [
  {type:'txt',x:20,y:16,text:'ROC CURVE',stroke:'#000',fill:'none',sw:1,fs:12,ff:'Arial'},
  {type:'line',x:30,y:225,x2:255,y2:225,stroke:'#333',fill:'#333',sw:1},
  {type:'line',x:30,y:225,x2:30,y2:28,stroke:'#333',fill:'#333',sw:1},
  {type:'arr',x:30,y:225,x2:255,y2:225,stroke:'#333',fill:'#333',sw:1},
  {type:'arr',x:30,y:225,x2:30,y2:28,stroke:'#333',fill:'#333',sw:1},
  {type:'txt',x:85,y:242,text:'FPR (1-Specificity)',stroke:'#555',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'txt',x:2,y:130,text:'TPR',stroke:'#555',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'pen',pts:[[30,225],[52,178],[75,132],[108,90],[145,62],[185,44],[220,36],[252,30]],stroke:'#000',fill:'none',sw:2},
  {type:'pen',pts:[[30,225],[252,30]],stroke:'#999',fill:'none',sw:1},
  {type:'txt',x:35,y:52,text:'AUC ≈ 0.92',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:135,y:158,text:'Random',stroke:'#999',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'txt',x:18,y:235,text:'0',stroke:'#555',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'txt',x:240,y:235,text:'1',stroke:'#555',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'txt',x:14,y:32,text:'1',stroke:'#555',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'txt',x:20,y:268,text:'AUC=1.0 perfect | AUC=0.5 random | <0.5 worse than random',stroke:'#444',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'txt',x:285,y:16,text:'PRECISION-RECALL CURVE',stroke:'#000',fill:'none',sw:1,fs:12,ff:'Arial'},
  {type:'line',x:295,y:225,x2:555,y2:225,stroke:'#333',fill:'#333',sw:1},
  {type:'line',x:295,y:225,x2:295,y2:28,stroke:'#333',fill:'#333',sw:1},
  {type:'arr',x:295,y:225,x2:555,y2:225,stroke:'#333',fill:'#333',sw:1},
  {type:'arr',x:295,y:225,x2:295,y2:28,stroke:'#333',fill:'#333',sw:1},
  {type:'txt',x:385,y:242,text:'Recall',stroke:'#555',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'txt',x:262,y:130,text:'Prec',stroke:'#555',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'pen',pts:[[295,48],[318,50],[348,56],[378,68],[408,88],[438,118],[465,160],[492,192],[540,222]],stroke:'#000',fill:'none',sw:2},
  {type:'txt',x:298,y:44,text:'↑ high prec',stroke:'#555',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'txt',x:450,y:215,text:'high recall →',stroke:'#555',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'txt',x:285,y:275,text:'Use PR-AUC for imbalanced datasets (fraud, medical). ROC optimistic on skewed data.',stroke:'#333',fill:'none',sw:1,fs:9,ff:'Arial'}
];

DIAGRAMS['ch6_baselines'] = [
  {type:'txt',x:20,y:16,text:'HUYEN\'S BASELINE HIERARCHY',stroke:'#000',fill:'none',sw:1,fs:13,ff:'Arial'},
  {type:'rect',x:20,y:36,w:540,h:44,stroke:'#333',fill:'#e8e8e8',sw:2},
  {type:'txt',x:28,y:56,text:'Tier 1 — Random / Constant  (predict majority class always)',stroke:'#000',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'txt',x:28,y:73,text:'Shows why accuracy fails on imbalanced data. Sets the absolute floor.',stroke:'#555',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'rect',x:20,y:88,w:540,h:44,stroke:'#333',fill:'#ddd',sw:2},
  {type:'txt',x:28,y:108,text:'Tier 2 — Human / Rule-Based Heuristic  (domain expert rules)',stroke:'#000',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'txt',x:28,y:125,text:'The real production floor. If model < heuristic → not production-ready.',stroke:'#555',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'rect',x:20,y:140,w:540,h:44,stroke:'#333',fill:'#d0d0d0',sw:2},
  {type:'txt',x:28,y:160,text:'Tier 3 — Simple ML  (Logistic Regression / Decision Tree)',stroke:'#000',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'txt',x:28,y:177,text:'Fast, interpretable, often competitive on structured data.',stroke:'#555',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'rect',x:20,y:192,w:540,h:44,stroke:'#333',fill:'#c8c8c8',sw:2},
  {type:'txt',x:28,y:212,text:'Tier 4 — SotA / Published Reference',stroke:'#000',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'txt',x:28,y:229,text:'Best known result on this task type. Sets the upper bound.',stroke:'#555',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'rect',x:20,y:252,w:540,h:24,stroke:'#888',fill:'#f5f5f5',sw:1},
  {type:'txt',x:28,y:269,text:'Start with the simplest model that could possibly work. — wins interviews every time',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'}
];

/* ════════════════════════════════════════════════════════
   CH7 — Deployment & Prediction Service
════════════════════════════════════════════════════════ */
DIAGRAMS['ch7_batchonline'] = [
  {type:'txt',x:20,y:18,text:'BATCH PREDICTION',stroke:'#000',fill:'none',sw:1,fs:13,ff:'Arial'},
  {type:'rect',x:20,y:36,w:110,h:38,stroke:'#333',fill:'#eee',sw:2},
  {type:'txt',x:28,y:60,text:'All Users\'',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:28,y:74,text:'Features',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'arr',x:130,y:55,x2:182,y2:55,stroke:'#333',fill:'#333',sw:2},
  {type:'rect',x:182,y:36,w:90,h:38,stroke:'#333',fill:'#ddd',sw:2},
  {type:'txt',x:192,y:60,text:'ML Model',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'arr',x:272,y:55,x2:325,y2:55,stroke:'#333',fill:'#333',sw:2},
  {type:'rect',x:325,y:36,w:120,h:38,stroke:'#333',fill:'#eee',sw:2},
  {type:'txt',x:333,y:55,text:'Predictions',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:333,y:70,text:'(cached/stored)',stroke:'#666',fill:'none',sw:1,fs:8,ff:'Arial'},
  {type:'txt',x:20,y:92,text:'Latency: hours.  Throughput: very high.  Pre-compute top-k per user.',stroke:'#555',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'line',x:10,y:108,x2:560,y2:108,stroke:'#ccc',fill:'#ccc',sw:1},
  {type:'txt',x:20,y:126,text:'ONLINE PREDICTION  (streaming)',stroke:'#000',fill:'none',sw:1,fs:13,ff:'Arial'},
  {type:'ell',x:20,y:140,w:100,h:36,stroke:'#333',fill:'#eee',sw:2},
  {type:'txt',x:25,y:163,text:'User Request',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'arr',x:120,y:158,x2:172,y2:158,stroke:'#333',fill:'#333',sw:2},
  {type:'rect',x:172,y:140,w:120,h:36,stroke:'#333',fill:'#ddd',sw:2},
  {type:'txt',x:178,y:155,text:'Feature Lookup',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:178,y:170,text:'(online store)',stroke:'#666',fill:'none',sw:1,fs:8,ff:'Arial'},
  {type:'arr',x:292,y:158,x2:345,y2:158,stroke:'#333',fill:'#333',sw:2},
  {type:'rect',x:345,y:140,w:90,h:36,stroke:'#333',fill:'#ddd',sw:2},
  {type:'txt',x:355,y:162,text:'ML Model',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'arr',x:435,y:158,x2:485,y2:158,stroke:'#333',fill:'#333',sw:2},
  {type:'ell',x:485,y:140,w:80,h:36,stroke:'#333',fill:'#eee',sw:2},
  {type:'txt',x:492,y:163,text:'Response',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:20,y:198,text:'Latency: ms.  Real-time features.  Higher infra cost.',stroke:'#555',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'rect',x:20,y:214,w:540,h:24,stroke:'#888',fill:'#f5f5f5',sw:1},
  {type:'txt',x:28,y:231,text:'Decision rule: latency SLO < 200ms → online.  Latency-tolerant → batch.',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'}
];

DIAGRAMS['ch7_onlinearch'] = [
  {type:'rect',x:10,y:10,w:565,h:265,stroke:'#333',fill:'#fafafa',sw:1},
  {type:'txt',x:155,y:32,text:'ONLINE PREDICTION ARCHITECTURE (Fig 7-6)',stroke:'#000',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'rect',x:25,y:48,w:115,h:52,stroke:'#333',fill:'#e8e8e8',sw:2},
  {type:'txt',x:57,y:78,text:'App',stroke:'#000',fill:'none',sw:1,fs:14,ff:'Arial'},
  {type:'ell',x:22,y:155,w:130,h:50,stroke:'#333',fill:'#e0e0e0',sw:2},
  {type:'txt',x:30,y:175,text:'Real-time',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:30,y:192,text:'Transport',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'ell',x:198,y:182,w:155,h:52,stroke:'#333',fill:'#ddd',sw:2},
  {type:'txt',x:222,y:206,text:'Data Warehouse',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:232,y:222,text:'(batch features)',stroke:'#666',fill:'none',sw:1,fs:8,ff:'Arial'},
  {type:'rect',x:418,y:48,w:148,h:80,stroke:'#333',fill:'#ccc',sw:2},
  {type:'txt',x:445,y:82,text:'Prediction',stroke:'#000',fill:'none',sw:1,fs:13,ff:'Arial'},
  {type:'txt',x:450,y:102,text:'Service',stroke:'#000',fill:'none',sw:1,fs:13,ff:'Arial'},
  {type:'arr',x:140,y:68,x2:418,y2:76,stroke:'#333',fill:'#333',sw:1},
  {type:'txt',x:218,y:62,text:'① Request',stroke:'#555',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'arr',x:418,y:100,x2:140,y2:90,stroke:'#333',fill:'#333',sw:1},
  {type:'txt',x:218,y:86,text:'③ Prediction',stroke:'#555',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'arr',x:82,y:100,x2:82,y2:155,stroke:'#333',fill:'#333',sw:1},
  {type:'txt',x:86,y:133,text:'logs',stroke:'#555',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'arr',x:152,y:178,x2:418,y2:112,stroke:'#333',fill:'#333',sw:1},
  {type:'txt',x:248,y:142,text:'streaming features',stroke:'#555',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'arr',x:355,y:208,x2:418,y2:125,stroke:'#999',fill:'#999',sw:1},
  {type:'txt',x:360,y:175,text:'② batch feats',stroke:'#999',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'txt',x:22,y:248,text:'Both streaming features + batch features converge at the prediction service.',stroke:'#333',fill:'none',sw:1,fs:9,ff:'Arial'}
];

/* ════════════════════════════════════════════════════════
   CH8 — Data Distribution Shifts
════════════════════════════════════════════════════════ */
DIAGRAMS['ch8_drifttypes'] = [
  {type:'txt',x:20,y:16,text:'THREE TYPES OF DISTRIBUTION SHIFT',stroke:'#000',fill:'none',sw:1,fs:12,ff:'Arial'},
  {type:'rect',x:20,y:36,w:168,h:100,stroke:'#333',fill:'#f0f0f0',sw:2},
  {type:'txt',x:48,y:58,text:'COVARIATE',stroke:'#000',fill:'none',sw:1,fs:12,ff:'Arial'},
  {type:'txt',x:60,y:76,text:'SHIFT',stroke:'#000',fill:'none',sw:1,fs:12,ff:'Arial'},
  {type:'txt',x:28,y:96,text:'P(X) changes.',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:28,y:113,text:'P(Y|X) same.',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:28,y:128,text:'e.g. user demographics',stroke:'#555',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'rect',x:200,y:36,w:168,h:100,stroke:'#333',fill:'#e4e4e4',sw:2},
  {type:'txt',x:242,y:58,text:'LABEL',stroke:'#000',fill:'none',sw:1,fs:12,ff:'Arial'},
  {type:'txt',x:245,y:76,text:'SHIFT',stroke:'#000',fill:'none',sw:1,fs:12,ff:'Arial'},
  {type:'txt',x:208,y:96,text:'P(Y) changes.',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:208,y:113,text:'e.g. seasonality',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:208,y:128,text:'shifts class balance',stroke:'#555',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'rect',x:380,y:36,w:185,h:100,stroke:'#333',fill:'#d8d8d8',sw:2},
  {type:'txt',x:412,y:58,text:'CONCEPT',stroke:'#000',fill:'none',sw:1,fs:12,ff:'Arial'},
  {type:'txt',x:420,y:76,text:'DRIFT',stroke:'#000',fill:'none',sw:1,fs:12,ff:'Arial'},
  {type:'txt',x:388,y:96,text:'P(Y|X) changes.',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:388,y:113,text:'Relationship changes.',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:388,y:128,text:'Hardest to detect!',stroke:'#555',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'txt',x:20,y:158,text:'DETECTION:',stroke:'#000',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'txt',x:20,y:176,text:'• KS-Test — continuous features',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:20,y:193,text:'• PSI — <0.10 stable / 0.10-0.20 warn / >0.20 retrain',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:20,y:210,text:'• Chi-square — categorical features',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:20,y:227,text:'• Monitor prediction distribution (early signal, no labels needed)',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'}
];

DIAGRAMS['ch8_psi'] = [
  {type:'txt',x:20,y:16,text:'PSI — Population Stability Index',stroke:'#000',fill:'none',sw:1,fs:13,ff:'Arial'},
  {type:'txt',x:20,y:38,text:'PSI = Σ (Actual% − Expected%) × ln(Actual% / Expected%)',stroke:'#333',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'line',x:20,y:55,x2:560,y2:55,stroke:'#ccc',fill:'#ccc',sw:1},
  {type:'rect',x:20,y:64,w:155,h:50,stroke:'#333',fill:'#e8e8e8',sw:2},
  {type:'txt',x:28,y:85,text:'PSI < 0.10',stroke:'#000',fill:'none',sw:1,fs:12,ff:'Arial'},
  {type:'txt',x:28,y:103,text:'✓ STABLE',stroke:'#333',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'rect',x:188,y:64,w:175,h:50,stroke:'#333',fill:'#d8d8d8',sw:2},
  {type:'txt',x:196,y:85,text:'PSI 0.10 – 0.20',stroke:'#000',fill:'none',sw:1,fs:12,ff:'Arial'},
  {type:'txt',x:196,y:103,text:'⚠  INVESTIGATE',stroke:'#333',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'rect',x:376,y:64,w:175,h:50,stroke:'#333',fill:'#c8c8c8',sw:2},
  {type:'txt',x:384,y:85,text:'PSI > 0.20',stroke:'#000',fill:'none',sw:1,fs:12,ff:'Arial'},
  {type:'txt',x:384,y:103,text:'✗ RETRAIN NOW',stroke:'#333',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'txt',x:20,y:135,text:'Training distribution (baseline):',stroke:'#000',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'rect',x:20,y:148,w:80,h:38,stroke:'#333',fill:'#aaa',sw:1},
  {type:'txt',x:30,y:173,text:'30%',stroke:'#fff',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'rect',x:105,y:162,w:80,h:24,stroke:'#333',fill:'#aaa',sw:1},
  {type:'txt',x:115,y:179,text:'25%',stroke:'#fff',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'rect',x:190,y:155,w:80,h:31,stroke:'#333',fill:'#aaa',sw:1},
  {type:'txt',x:200,y:175,text:'28%',stroke:'#fff',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'rect',x:275,y:169,w:80,h:17,stroke:'#333',fill:'#aaa',sw:1},
  {type:'txt',x:285,y:182,text:'17%',stroke:'#fff',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:20,y:208,text:'Serving distribution (today):',stroke:'#000',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'rect',x:20,y:220,w:80,h:18,stroke:'#333',fill:'#555',sw:1},
  {type:'txt',x:28,y:234,text:'18%',stroke:'#fff',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'rect',x:105,y:220,w:80,h:36,stroke:'#333',fill:'#555',sw:1},
  {type:'txt',x:115,y:242,text:'38%',stroke:'#fff',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'rect',x:190,y:220,w:80,h:16,stroke:'#333',fill:'#555',sw:1},
  {type:'txt',x:200,y:233,text:'15%',stroke:'#fff',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'rect',x:275,y:220,w:80,h:26,stroke:'#333',fill:'#555',sw:1},
  {type:'txt',x:285,y:237,text:'29%',stroke:'#fff',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:380,y:255,text:'PSI ≈ 0.28 → RETRAIN',stroke:'#000',fill:'none',sw:1,fs:12,ff:'Arial'}
];

/* ════════════════════════════════════════════════════════
   CH9 — Continual Learning
════════════════════════════════════════════════════════ */
DIAGRAMS['ch9_retraining'] = [
  {type:'txt',x:20,y:16,text:'STATELESS vs STATEFUL RETRAINING',stroke:'#000',fill:'none',sw:1,fs:13,ff:'Arial'},
  {type:'rect',x:20,y:36,w:255,h:135,stroke:'#333',fill:'#f0f0f0',sw:2},
  {type:'txt',x:48,y:58,text:'STATELESS',stroke:'#000',fill:'none',sw:1,fs:12,ff:'Arial'},
  {type:'txt',x:28,y:78,text:'Train from scratch on fresh data.',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:28,y:96,text:'✓ No catastrophic forgetting',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:28,y:113,text:'✓ Clean slate',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:28,y:130,text:'✗ Expensive (full train every time)',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:28,y:162,text:'Default for most orgs.',stroke:'#555',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'rect',x:295,y:36,w:255,h:135,stroke:'#333',fill:'#e4e4e4',sw:2},
  {type:'txt',x:338,y:58,text:'STATEFUL',stroke:'#000',fill:'none',sw:1,fs:12,ff:'Arial'},
  {type:'txt',x:303,y:78,text:'Fine-tune on new data only.',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:303,y:96,text:'✓ Much cheaper',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:303,y:113,text:'✓ Faster convergence',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:303,y:130,text:'✗ Catastrophic forgetting risk',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:303,y:162,text:'Good for large NNs / LLMs.',stroke:'#555',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'txt',x:20,y:188,text:'RETRAINING TRIGGERS:',stroke:'#000',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'txt',x:20,y:206,text:'• Time-based  — every 24h / 7d',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:20,y:223,text:'• Performance-based  — metric drops below threshold',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:20,y:240,text:'• Drift-based  — PSI > 0.20 on key features',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:20,y:257,text:'• Volume-based  — N new labelled examples available',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'}
];

DIAGRAMS['ch9_champion'] = [
  {type:'txt',x:20,y:16,text:'CHAMPION-CHALLENGER ROLLOUT',stroke:'#000',fill:'none',sw:1,fs:13,ff:'Arial'},
  {type:'rect',x:20,y:36,w:115,h:40,stroke:'#333',fill:'#eee',sw:2},
  {type:'txt',x:32,y:61,text:'All Traffic',stroke:'#333',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'arr',x:135,y:56,x2:192,y2:56,stroke:'#333',fill:'#333',sw:2},
  {type:'dia',x:192,y:38,w:85,h:38,stroke:'#333',fill:'#ddd',sw:2},
  {type:'txt',x:208,y:62,text:'Route',stroke:'#000',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'arr',x:234,y:38,x2:295,y2:20,stroke:'#333',fill:'#333',sw:1},
  {type:'arr',x:277,y:68,x2:295,y2:88,stroke:'#333',fill:'#333',sw:1},
  {type:'txt',x:248,y:16,text:'95%',stroke:'#555',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'txt',x:278,y:83,text:'5%',stroke:'#555',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'rect',x:295,y:5,w:120,h:32,stroke:'#333',fill:'#ddd',sw:2},
  {type:'txt',x:310,y:26,text:'Champion v1',stroke:'#000',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'rect',x:295,y:75,w:125,h:32,stroke:'#333',fill:'#ccc',sw:2},
  {type:'txt',x:308,y:96,text:'Challenger v2',stroke:'#000',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'arr',x:420,y:21,x2:460,y2:60,stroke:'#333',fill:'#333',sw:1},
  {type:'arr',x:420,y:91,x2:460,y2:72,stroke:'#333',fill:'#333',sw:1},
  {type:'rect',x:460,y:40,w:115,h:38,stroke:'#333',fill:'#e8e8e8',sw:2},
  {type:'txt',x:468,y:58,text:'Compare KPI',stroke:'#000',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:468,y:73,text:'(stat test)',stroke:'#555',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'txt',x:20,y:130,text:'DEPLOYMENT STRATEGIES:',stroke:'#000',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'txt',x:20,y:148,text:'Shadow   — challenger runs, logs only (safe, no user exposure)',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:20,y:165,text:'Canary   — 1–5% live traffic to challenger',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:20,y:182,text:'A/B Test — controlled 50/50 split with stats test',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:20,y:199,text:'Blue-Green — instant full swap, old version on standby for rollback',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'rect',x:20,y:215,w:550,h:24,stroke:'#888',fill:'#f5f5f5',sw:1},
  {type:'txt',x:28,y:233,text:'Guardrail: if challenger violates latency SLO or error rate → auto rollback',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'}
];

/* ════════════════════════════════════════════════════════
   CH10 — Infrastructure & Tooling
════════════════════════════════════════════════════════ */
DIAGRAMS['ch10_platform'] = [
  {type:'txt',x:20,y:16,text:'ML PLATFORM STACK',stroke:'#000',fill:'none',sw:1,fs:13,ff:'Arial'},
  {type:'rect',x:20,y:35,w:540,h:30,stroke:'#333',fill:'#bbb',sw:2},
  {type:'txt',x:205,y:55,text:'ML Applications / Products',stroke:'#000',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'rect',x:20,y:73,w:540,h:30,stroke:'#333',fill:'#c8c8c8',sw:2},
  {type:'txt',x:145,y:93,text:'Model Serving / Prediction Service   (Triton, TorchServe, vLLM)',stroke:'#000',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'rect',x:20,y:111,w:262,h:30,stroke:'#333',fill:'#d5d5d5',sw:2},
  {type:'txt',x:32,y:131,text:'Model Registry  (MLflow, Vertex)',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'rect',x:290,y:111,w:270,h:30,stroke:'#333',fill:'#d5d5d5',sw:2},
  {type:'txt',x:300,y:131,text:'Experiment Tracking  (W&B, MLflow)',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'rect',x:20,y:149,w:262,h:30,stroke:'#333',fill:'#e0e0e0',sw:2},
  {type:'txt',x:32,y:169,text:'Feature Store  (Feast, Tecton)',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'rect',x:290,y:149,w:270,h:30,stroke:'#333',fill:'#e0e0e0',sw:2},
  {type:'txt',x:300,y:169,text:'Orchestration  (Airflow, Kubeflow)',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'rect',x:20,y:187,w:540,h:30,stroke:'#333',fill:'#e8e8e8',sw:2},
  {type:'txt',x:118,y:207,text:'Data Lake (S3/GCS)  +  Data Warehouse (BigQuery / Redshift)',stroke:'#000',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'rect',x:20,y:225,w:540,h:28,stroke:'#333',fill:'#f0f0f0',sw:2},
  {type:'txt',x:155,y:245,text:'Compute:  GPUs / TPUs / Cloud (GCP, AWS, Azure)',stroke:'#000',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'txt',x:20,y:272,text:'Build vs Buy:  build when core differentiator;  buy commodity infra.',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'}
];

DIAGRAMS['ch10_featstore'] = [
  {type:'txt',x:20,y:16,text:'FEATURE STORE — Online vs Offline',stroke:'#000',fill:'none',sw:1,fs:13,ff:'Arial'},
  {type:'rect',x:20,y:36,w:255,h:162,stroke:'#333',fill:'#f0f0f0',sw:2},
  {type:'txt',x:68,y:60,text:'OFFLINE STORE',stroke:'#000',fill:'none',sw:1,fs:12,ff:'Arial'},
  {type:'txt',x:28,y:80,text:'Technology: S3, BigQuery',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:28,y:97,text:'Latency: seconds – hours',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:28,y:114,text:'Used for:  TRAINING',stroke:'#000',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'txt',x:28,y:131,text:'Stores: historical values',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:28,y:148,text:'Point-in-time joins →',stroke:'#555',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'txt',x:28,y:188,text:'temporal correctness',stroke:'#555',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'rect',x:295,y:36,w:255,h:162,stroke:'#333',fill:'#e4e4e4',sw:2},
  {type:'txt',x:348,y:60,text:'ONLINE STORE',stroke:'#000',fill:'none',sw:1,fs:12,ff:'Arial'},
  {type:'txt',x:303,y:80,text:'Technology: Redis, DynamoDB',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:303,y:97,text:'Latency: < 10ms',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:303,y:114,text:'Used for:  SERVING',stroke:'#000',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'txt',x:303,y:131,text:'Stores: latest values',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:303,y:148,text:'Keyed by entity_id',stroke:'#555',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'arr',x:148,y:198,x2:148,y2:238,stroke:'#333',fill:'#333',sw:2},
  {type:'arr',x:422,y:198,x2:422,y2:238,stroke:'#333',fill:'#333',sw:2},
  {type:'rect',x:88,y:238,w:400,h:36,stroke:'#333',fill:'#ddd',sw:2},
  {type:'txt',x:178,y:261,text:'Feature Store  (Feast / Tecton)',stroke:'#000',fill:'none',sw:1,fs:12,ff:'Arial'},
  {type:'txt',x:20,y:294,text:'Same feature definitions → no train-serve skew across both paths.',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'}
];

/* ════════════════════════════════════════════════════════
   CH11 — The Human Side of ML
════════════════════════════════════════════════════════ */
DIAGRAMS['ch11_feedback'] = [
  {type:'txt',x:20,y:16,text:'FEEDBACK LOOP & NATURAL LABELS',stroke:'#000',fill:'none',sw:1,fs:13,ff:'Arial'},
  {type:'rect',x:215,y:38,w:145,h:44,stroke:'#333',fill:'#e8e8e8',sw:2},
  {type:'txt',x:252,y:65,text:'ML Model',stroke:'#000',fill:'none',sw:1,fs:12,ff:'Arial'},
  {type:'arr',x:360,y:60,x2:418,y2:60,stroke:'#333',fill:'#333',sw:2},
  {type:'rect',x:418,y:38,w:130,h:44,stroke:'#333',fill:'#ddd',sw:2},
  {type:'txt',x:440,y:65,text:'Predictions',stroke:'#000',fill:'none',sw:1,fs:12,ff:'Arial'},
  {type:'arr',x:483,y:82,x2:483,y2:142,stroke:'#333',fill:'#333',sw:2},
  {type:'rect',x:418,y:142,w:130,h:44,stroke:'#333',fill:'#ddd',sw:2},
  {type:'txt',x:435,y:169,text:'User Action',stroke:'#000',fill:'none',sw:1,fs:12,ff:'Arial'},
  {type:'txt',x:424,y:202,text:'click/purchase/skip',stroke:'#555',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'arr',x:418,y:164,x2:248,y2:164,stroke:'#333',fill:'#333',sw:2},
  {type:'txt',x:292,y:157,text:'= Natural Labels',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'rect',x:100,y:142,w:148,h:44,stroke:'#333',fill:'#e4e4e4',sw:2},
  {type:'txt',x:112,y:169,text:'Training Data',stroke:'#000',fill:'none',sw:1,fs:12,ff:'Arial'},
  {type:'arr',x:174,y:142,x2:260,y2:82,stroke:'#333',fill:'#333',sw:2},
  {type:'txt',x:20,y:232,text:'Label delay:  clicks (1hr) | purchases (2wks) | fraud (30+ days)',stroke:'#000',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:20,y:250,text:'Feedback loop risk: model biases future data (popularity bias)',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:20,y:268,text:'Mitigation: holdout groups, exploration (epsilon-greedy, Thompson sampling)',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'}
];

DIAGRAMS['ch11_abtest'] = [
  {type:'txt',x:20,y:16,text:'A/B TEST DESIGN',stroke:'#000',fill:'none',sw:1,fs:13,ff:'Arial'},
  {type:'rect',x:20,y:36,w:110,h:38,stroke:'#333',fill:'#eee',sw:2},
  {type:'txt',x:32,y:60,text:'All Traffic',stroke:'#333',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'arr',x:130,y:55,x2:186,y2:55,stroke:'#333',fill:'#333',sw:2},
  {type:'dia',x:186,y:36,w:85,h:38,stroke:'#333',fill:'#ddd',sw:2},
  {type:'txt',x:202,y:60,text:'Split',stroke:'#000',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'arr',x:228,y:36,x2:290,y2:16,stroke:'#333',fill:'#333',sw:2},
  {type:'arr',x:271,y:68,x2:290,y2:86,stroke:'#333',fill:'#333',sw:2},
  {type:'txt',x:246,y:13,text:'50%',stroke:'#555',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'txt',x:274,y:82,text:'50%',stroke:'#555',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'rect',x:290,y:4,w:120,h:32,stroke:'#333',fill:'#ddd',sw:2},
  {type:'txt',x:307,y:25,text:'Control (A)',stroke:'#000',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'rect',x:290,y:72,w:125,h:32,stroke:'#333',fill:'#ccc',sw:2},
  {type:'txt',x:300,y:93,text:'Treatment (B)',stroke:'#000',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'arr',x:410,y:20,x2:455,y2:52,stroke:'#333',fill:'#333',sw:2},
  {type:'arr',x:415,y:88,x2:455,y2:68,stroke:'#333',fill:'#333',sw:2},
  {type:'rect',x:455,y:38,w:115,h:38,stroke:'#333',fill:'#e8e8e8',sw:2},
  {type:'txt',x:462,y:57,text:'Compare KPI',stroke:'#000',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:468,y:72,text:'(stat. test)',stroke:'#555',fill:'none',sw:1,fs:9,ff:'Arial'},
  {type:'txt',x:20,y:128,text:'REQUIREMENTS FOR VALID A/B:',stroke:'#000',fill:'none',sw:1,fs:11,ff:'Arial'},
  {type:'txt',x:20,y:146,text:'• Power analysis BEFORE running — determine sample size needed',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:20,y:163,text:'• MDE (min detectable effect) — what Δ is business-meaningful?',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:20,y:180,text:'• α = 0.05  (false positive)   β = 0.20  → power = 80%',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:20,y:197,text:'• Guardrail metrics — secondary KPIs that must NOT regress',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:20,y:214,text:'• No peeking — decide duration in advance, do not stop early',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'rect',x:20,y:228,w:550,h:24,stroke:'#888',fill:'#f5f5f5',sw:1},
  {type:'txt',x:28,y:246,text:'Novelty effect: run for ≥ 2 weeks to let initial curiosity boost decay.',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'}
];

/* ════════════════════════════════════════════════════════
   CH12 — Summary & Interview Framework
════════════════════════════════════════════════════════ */
DIAGRAMS['ch12_e2e'] = [
  {type:'txt',x:20,y:16,text:'END-TO-END ML SYSTEM  (interview overview)',stroke:'#000',fill:'none',sw:1,fs:13,ff:'Arial'},
  {type:'ell',x:20,y:36,w:115,h:36,stroke:'#333',fill:'#eee',sw:2},
  {type:'txt',x:32,y:59,text:'Data Sources',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'arr',x:135,y:54,x2:185,y2:54,stroke:'#333',fill:'#333',sw:2},
  {type:'rect',x:185,y:36,w:110,h:36,stroke:'#333',fill:'#e4e4e4',sw:2},
  {type:'txt',x:195,y:59,text:'Data Pipeline',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'arr',x:295,y:54,x2:345,y2:54,stroke:'#333',fill:'#333',sw:2},
  {type:'rect',x:345,y:36,w:110,h:36,stroke:'#333',fill:'#ddd',sw:2},
  {type:'txt',x:353,y:54,text:'Feature',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:353,y:68,text:'Engineering',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'arr',x:455,y:54,x2:508,y2:54,stroke:'#333',fill:'#333',sw:2},
  {type:'rect',x:508,y:36,w:65,h:36,stroke:'#333',fill:'#ccc',sw:2},
  {type:'txt',x:516,y:59,text:'Model',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'arr',x:540,y:72,x2:540,y2:112,stroke:'#333',fill:'#333',sw:2},
  {type:'rect',x:478,y:112,w:130,h:36,stroke:'#333',fill:'#ddd',sw:2},
  {type:'txt',x:490,y:135,text:'Eval / Registry',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'arr',x:478,y:130,x2:418,y2:130,stroke:'#333',fill:'#333',sw:2},
  {type:'rect',x:295,y:112,w:123,h:36,stroke:'#333',fill:'#e4e4e4',sw:2},
  {type:'txt',x:302,y:130,text:'Serving / API',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:302,y:144,text:'(Triton/ONNX)',stroke:'#555',fill:'none',sw:1,fs:8,ff:'Arial'},
  {type:'arr',x:295,y:130,x2:225,y2:130,stroke:'#333',fill:'#333',sw:2},
  {type:'rect',x:90,y:112,w:135,h:36,stroke:'#333',fill:'#eee',sw:2},
  {type:'txt',x:98,y:135,text:'Application / UX',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'arr',x:100,y:148,x2:60,y2:185,stroke:'#333',fill:'#333',sw:2},
  {type:'ell',x:20,y:185,w:130,h:36,stroke:'#333',fill:'#eee',sw:2},
  {type:'txt',x:30,y:208,text:'User Feedback',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'arr',x:60,y:185,x2:60,y2:54,stroke:'#999',fill:'#999',sw:1},
  {type:'txt',x:20,y:248,text:'Monitoring: data drift, prediction drift, business KPI dashboards',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:20,y:266,text:'Retraining: PSI-triggered or scheduled → stateless or stateful',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'}
];

DIAGRAMS['ch12_framework'] = [
  {type:'txt',x:20,y:16,text:'ML SYSTEM DESIGN INTERVIEW FRAMEWORK',stroke:'#000',fill:'none',sw:1,fs:12,ff:'Arial'},
  {type:'rect',x:20,y:35,w:545,h:30,stroke:'#333',fill:'#bbb',sw:2},
  {type:'txt',x:28,y:55,text:'0–5m   ① SCOPE:  clarify goal, users, scale, latency SLO, success metrics',stroke:'#000',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'rect',x:20,y:69,w:545,h:30,stroke:'#333',fill:'#c8c8c8',sw:2},
  {type:'txt',x:28,y:89,text:'5–15m  ② DATA:  sources, labelling, format, batch vs streaming, class imbalance',stroke:'#000',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'rect',x:20,y:103,w:545,h:30,stroke:'#333',fill:'#d5d5d5',sw:2},
  {type:'txt',x:28,y:123,text:'15–30m ③ FEATURES:  feature engineering, feature store, point-in-time joins',stroke:'#000',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'rect',x:20,y:137,w:545,h:30,stroke:'#333',fill:'#ddd',sw:2},
  {type:'txt',x:28,y:157,text:'15–30m ④ MODEL:  baseline → selection → loss fn → HPO → ensemble',stroke:'#000',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'rect',x:20,y:171,w:545,h:30,stroke:'#333',fill:'#e4e4e4',sw:2},
  {type:'txt',x:28,y:191,text:'30–40m ⑤ EVAL:  offline metrics, sliced evaluation, calibration, A/B design',stroke:'#000',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'rect',x:20,y:205,w:545,h:30,stroke:'#333',fill:'#ebebeb',sw:2},
  {type:'txt',x:28,y:225,text:'40–45m ⑥ DEPLOY+OPS:  serving, compression, drift detection, retraining',stroke:'#000',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'line',x:20,y:242,x2:565,y2:242,stroke:'#bbb',fill:'#bbb',sw:1},
  {type:'txt',x:20,y:259,text:'ALWAYS: name your baselines.  Justify your metric.  Define train-serve skew mitigation.',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'txt',x:20,y:276,text:'ALWAYS: sliced evaluation as release gate.  PSI + prediction distribution for monitoring.',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'},
  {type:'rect',x:20,y:292,w:545,h:22,stroke:'#888',fill:'#f5f5f5',sw:1},
  {type:'txt',x:28,y:309,text:'I would start with the simplest model that could possibly work. — the sentence that wins',stroke:'#333',fill:'none',sw:1,fs:10,ff:'Arial'}
];
