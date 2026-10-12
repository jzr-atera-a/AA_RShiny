# R/utils_techdesign_catalog.R
# ============================================================
# TECHNICAL DESIGNS - catalog, prompt, text format
# ============================================================
# One table (technical_designs), ONE ROW PER DESIGN VERSION. The rows hold
# plain filterable columns plus JSON text columns (components, connections,
# flow steps, trade-offs, references). Adding a new architecture or pattern
# later = adding one entry to TD_CATALOG below (or using "Custom design" in
# the UI, which needs no code at all). No schema change, ever.

TD_GROUPS <- c("ml_genai", "data_processing", "software_patterns")
TD_GROUP_LABELS <- c(
  ml_genai = "Machine Learning / GenAI Architectures",
  data_processing = "Data Processing Architectures",
  software_patterns = "Software Design Patterns"
)
# Which renderer draws each group by default: swimlane architecture or UML class diagram.
TD_GROUP_DIAGRAM_KIND <- c(ml_genai = "layered", data_processing = "layered", software_patterns = "class")

TD_CUSTOM_VALUE <- "__custom_design__"

TD_EDGE_TYPES_LAYERED <- c("data", "control", "event", "feedback")
TD_EDGE_TYPES_CLASS <- c("inherit", "implements", "composition", "aggregation", "uses", "creates", "notifies")
TD_NODE_KINDS_LAYERED <- c("actor", "service", "process", "store", "queue", "model", "gateway", "cache", "external", "monitor")
TD_NODE_KINDS_CLASS <- c("class", "abstract", "interface", "actor")

# ---- Catalog: group -> list of designs (id, label, guidance) -----------
TD_CATALOG <- list(

  ml_genai = list(
    rag = list(label = "Retrieval-Augmented Generation (RAG)", guidance = r"---(
DESIGN = Retrieval-Augmented Generation. Show BOTH paths: the offline INDEXING path and the online QUERY path.
Suggested lanes, left to right: "Client" (User[actor], Application API / Gateway[gateway]); "Query Pipeline" (Query Rewriter / Router[process], Query Embedding Model[model], Hybrid Retriever[service], Reranker[model]); "Knowledge Stores" (Vector Database[store], Keyword / Metadata Index[store], Document Store[store]); "Generation" (Prompt and Context Builder[process], LLM[model], Guardrails and Citation Check[process]); "Ingestion (offline)" (Data Sources[external], Parser and Chunker[process], Embedding Model[model]); "Ops" (Semantic Cache[cache], Feedback and Eval Store[store], Monitoring[monitor]).
Connections: ingestion data flow into the stores; the query path User -> API -> Rewriter -> Retriever -> stores -> Reranker -> Context Builder -> LLM -> Guardrails -> API -> User; cache lookups as control; user feedback and eval results as feedback edges.
Flow steps: first the indexing steps, then the numbered online query steps.
)---"),
    agentic_llm = list(label = "Agentic / Tool-Using LLM System", guidance = r"---(
DESIGN = Agentic LLM system with a plan-act-observe loop.
Suggested lanes: "Interface" (User[actor], Agent API[gateway]); "Orchestration" (Planner / Router[process], Agent Loop Executor[process], Reflection / Critic[process]); "Reasoning" (LLM[model], System Prompt and Policy[store]); "Tools and Actions" (Tool Registry[service], Search / RAG Tool[service], Code Interpreter Sandbox[service], External APIs[external], Specialist Sub-agents[service]); "Memory and State" (Short-term Context[cache], Long-term Memory Vector Store[store], Task State Store[store]); "Safety and Observability" (Guardrails[process], Human Approval[actor], Tracing and Evaluation[monitor]).
Connections: user goal -> planner -> LLM; executor calls tools (control) and receives observations (data); observations flow back to the loop (feedback); memory reads and writes; guardrails and human approval gate risky actions.
Flow steps: the numbered iterations of the loop from goal to final answer.
)---"),
    realtime_ml_pipeline = list(label = "Real-Time ML Pipeline with Feature Store", guidance = r"---(
DESIGN = Production real-time ML system: data, feature store, training, registry, online serving, monitoring and retraining loop.
Suggested lanes: "Data Sources" (Event Streams[queue], Operational Databases[store], Data Warehouse[store]); "Feature Engineering" (Stream Feature Pipeline[process], Batch Feature Pipeline[process]); "Feature Store" (Offline Store[store], Online Store[store]); "Training and Registry" (Training Job[process], Experiment Tracking[service], Model Registry[store]); "Online Serving" (Client App[actor], Inference Gateway[gateway], Model Server[model], Prediction Cache[cache]); "Monitoring and Feedback" (Drift and Quality Monitor[monitor], Prediction and Label Logs[store], Retrain Trigger[process]).
Connections: both feature pipelines write to both stores; training reads the offline store; the registry feeds the model server; the model server reads the online store; logs feed the monitor; the retrain trigger closes the loop to training (feedback).
)---"),
    batch_ml_pipeline = list(label = "Batch ML Pipeline (MLOps training and scoring)", guidance = r"---(
DESIGN = Scheduled batch MLOps pipeline for training and bulk scoring.
Suggested lanes: "Sources" (Operational Databases[store], Files and Logs[store], Third-party Data[external]); "Data Preparation" (Ingestion Job[process], Data Validation[process], Transformation and Feature Generation[process]); "Training" (Training Job[process], Hyperparameter Tuning[process], Evaluation and Validation[process]); "Registry and Governance" (Model Registry[store], Approval Gate[actor]); "Batch Scoring" (Orchestrator and Scheduler[service], Batch Inference Job[model], Predictions Store[store]); "Consumers and Monitoring" (BI and Reports[external], Downstream Applications[external], Data and Model Drift Monitor[monitor]).
Connections: linear data flow left to right; the orchestrator triggers jobs (control); the monitor feeds back to the orchestrator to trigger retraining (feedback).
)---")
  ),

  data_processing = list(
    lambda_architecture = list(label = "Lambda Architecture", guidance = r"---(
DESIGN = Lambda Architecture: batch layer + speed layer merged by a serving layer.
Suggested lanes: "Data Sources" (Applications and Services[external], Event Producers[external]); "Ingestion" (Message Broker[queue], Batch Loader[process]); "Batch Layer" (Immutable Master Dataset / Data Lake[store], Batch Processing Engine[process], Batch Views[store]); "Speed Layer" (Stream Processor[process], Real-time Views[store]); "Serving Layer" (Query Merge Service[service], Serving Database[store]); "Consumers" (Dashboards[external], APIs and Applications[external]).
Connections: the broker feeds BOTH the lake and the stream processor; batch views and real-time views both feed the merge service; batch recomputation corrects the speed layer (feedback).
)---"),
    kappa_architecture = list(label = "Kappa Architecture", guidance = r"---(
DESIGN = Kappa Architecture: a single streaming pipeline over an immutable, replayable log.
Suggested lanes: "Sources" (Applications[external], IoT and Devices[external], Databases via CDC[store]); "Event Log" (Distributed Log with Retention[queue], Schema Registry[service]); "Stream Processing" (Stream Processing Job v1[process], Reprocessing Job v2[process], State Store[store]); "Serving" (Materialized Views[store], Serving Database[store], Query API[gateway]); "Consumers" (Dashboards[external], Microservices[external], ML Features[external]).
Connections: sources -> log -> processing jobs -> serving; REPLAY from the log into the v2 job (feedback) and the cutover from v1 to v2 (control).
)---"),
    medallion_lakehouse = list(label = "Medallion Lakehouse (Bronze / Silver / Gold)", guidance = r"---(
DESIGN = Medallion lakehouse architecture on object storage with table formats.
Suggested lanes: "Sources" (SaaS and APIs[external], Operational Databases[store], Event Streams[queue], Files[external]); "Ingestion" (Batch Ingestion[process], CDC Connector[process], Streaming Ingestion[process]); "Bronze (raw)" (Raw Tables[store]); "Silver (cleaned)" (Cleansed and Conformed Tables[store], Data Quality Checks[process]); "Gold (curated)" (Business Aggregates[store], Data Marts[store], Feature Tables[store]); "Consumption" (BI and SQL[external], ML Training[external], Applications and APIs[external]); "Governance" (Data Catalog and Lineage[service], Orchestrator[service], Access Control[service]).
Connections: strict left-to-right promotion between layers; governance components connect to layers with control edges.
)---"),
    cdc_event_driven = list(label = "Event-Driven / Change Data Capture Pipeline", guidance = r"---(
DESIGN = Event-driven pipeline built on change data capture.
Suggested lanes: "Source Systems" (Operational Database A[store], Operational Database B[store], Transaction Log[queue]); "Capture" (CDC Connector[process], Outbox Table[store]); "Event Backbone" (Message Broker Topics[queue], Schema Registry[service], Dead Letter Queue[queue]); "Stream Processing" (Enrichment and Join Processor[process], Aggregation Processor[process]); "Sinks" (Data Warehouse[store], Search Index[store], Cache[cache], Downstream Microservices[service]); "Operations" (Monitoring and Lag Alerts[monitor], Replay and Backfill Tool[process]).
Connections: log -> connector -> topics -> processors -> sinks; failures to the DLQ (event); replay from topics (feedback).
)---")
  ),

  software_patterns = list(
    factory_pattern = list(label = "Factory (Factory Method / Abstract Factory)", guidance = r"---(
DESIGN = Factory Method pattern (mention Abstract Factory in the summary as the related family variant).
Class diagram. Tiers (rows) top to bottom: "Client" (Client[class]); "Abstractions" (Creator[abstract] with factoryMethod() and operation(); Product[interface] with operate()); "Concrete Classes" (ConcreteCreatorA[class], ConcreteCreatorB[class], ConcreteProductA[class], ConcreteProductB[class]).
Connections: Client uses Creator and Product; ConcreteCreator inherits Creator; ConcreteProduct implements Product; each ConcreteCreator creates its ConcreteProduct (creates).
Give the classes realistic attributes and methods.
)---"),
    strategy_pattern = list(label = "Strategy", guidance = r"---(
DESIGN = Strategy pattern.
Class diagram. Tiers top to bottom: "Client" (Client[class]); "Context" (Context[class] holding a strategy reference with setStrategy() and execute()); "Strategy Abstraction" (Strategy[interface] with algorithm()); "Concrete Strategies" (ConcreteStrategyA, ConcreteStrategyB, ConcreteStrategyC [class]).
Connections: Client uses Context; Context aggregates Strategy; each ConcreteStrategy implements Strategy.
Use a realistic running example (for example payment, routing or pricing) in the method names.
)---"),
    observer_pattern = list(label = "Observer (Publish / Subscribe)", guidance = r"---(
DESIGN = Observer pattern.
Class diagram. Tiers top to bottom: "Abstractions" (Subject[interface] with attach(), detach(), notify(); Observer[interface] with update()); "Concrete Classes" (ConcreteSubject[class] with state; ConcreteObserverA[class]; ConcreteObserverB[class]); "Client" (Client[class]).
Connections: ConcreteSubject implements Subject; ConcreteObservers implement Observer; Subject aggregates Observer (a list of observers); ConcreteSubject notifies ConcreteObservers (notifies); Client uses Subject.
The flow steps describe the notification sequence.
)---"),
    adapter_facade_pattern = list(label = "Adapter and Facade", guidance = r"---(
DESIGN = Adapter and Facade shown together as the two main structural wrappers.
Class diagram. Tiers top to bottom: "Client" (Client[class]); "Targets" (Target[interface] with request(); Facade[class] with simpleOperation()); "Wrappers" (Adapter[class] with request() that delegates; SubsystemA[class]; SubsystemB[class]; SubsystemC[class]); "Wrapped Code" (Adaptee[class] legacy or third-party API with specificRequest()).
Connections: Client uses Target and Facade; Adapter implements Target; Adapter composes Adaptee; Facade uses each Subsystem.
In the summary explain the difference: Adapter changes an interface, Facade simplifies a subsystem.
)---")
  )
)

td_catalog_choices <- function(group) {
  items <- TD_CATALOG[[group]]
  if (is.null(items)) return(character(0))
  setNames(names(items), vapply(items, function(x) x$label, character(1)))
}
td_catalog_entry <- function(group, design_type) {
  TD_CATALOG[[group]][[design_type]]
}
td_slug <- function(x) {
  s <- tolower(gsub("[^a-zA-Z0-9]+", "_", trimws(x)))
  s <- gsub("^_+|_+$", "", s)
  if (nchar(s) == 0) s <- "custom_design"
  substr(s, 1, 50)
}
generate_new_design_id <- function(design_type) {
  paste0(td_slug(design_type), "-", format(Sys.time(), "%Y%m%d%H%M%S"), "-", sample(100:999, 1))
}

# ---- Prompt ---------------------------------------------------------
generate_techdesign_prompt <- function(group, design_type, design_label, guidance = "",
                                       context = "", constraints = "", reference = "",
                                       detail = 2, custom = FALSE) {
  kind <- TD_GROUP_DIAGRAM_KIND[[group]]
  size <- switch(as.character(detail),
                 "1" = if (kind == "class") "5-6 classes" else "8-10 components",
                 "3" = if (kind == "class") "8-10 classes" else "16-22 components",
                 if (kind == "class") "6-8 classes" else "12-16 components")

  node_kinds <- if (kind == "class") TD_NODE_KINDS_CLASS else TD_NODE_KINDS_LAYERED
  edge_types <- if (kind == "class") TD_EDGE_TYPES_CLASS else TD_EDGE_TYPES_LAYERED

  fmt <- paste0(
    "OUTPUT FORMAT (plain text, no markdown, no code fences, no commentary). Header lines first, then blocks. ",
    "Every value is on ONE line. Never use square brackets, double quotes, backslashes or the dollar sign in any value.\n\n",
    "design_group: ", group, "\n",
    "design_type: ", design_type, "\n",
    "title: <specific title for this design>\n",
    "variant: <short variant name, or N/A>\n",
    "summary: <2-4 sentences explaining what this design is and the problem it solves>\n",
    "when_to_use: <1-3 sentences>\n",
    "when_not_to_use: <1-3 sentences>\n",
    "complexity: <Low|Medium|High>\n",
    "tags: <comma separated tags>\n\n",
    "Then ", size, " as blocks, each starting with a line containing only @component:\n",
    "@component\n",
    "id: <C1, C2, C3 ... unique>\n",
    "label: <short name, max 5 words>\n",
    "lane: <",
    if (kind == "class") "the tier (row) this class sits in, top to bottom" else "the swimlane (column) this component sits in, left to right",
    ">\n",
    "kind: <one of: ", paste(node_kinds, collapse = ", "), ">\n",
    "description: <1-2 sentences: what it is and its responsibility>\n",
    if (kind == "class") paste0(
      "attributes: <semicolon separated, for example: - items: List; - name: String; N/A if none>\n",
      "methods: <semicolon separated, for example: + notify(): void; + attach(o: Observer): void>\n"
    ) else paste0(
      "technologies: <2-4 example products or technologies, comma separated>\n"
    ),
    "\nThen the connections, each a block starting with @connection:\n",
    "@connection\nfrom: <component id>\nto: <component id>\n",
    "label: <2-4 words describing what flows or what the relationship means>\n",
    "type: <one of: ", paste(edge_types, collapse = ", "), ">\n",
    if (kind == "class") paste0(
      "Relationship semantics: inherit = class extends parent (from=child, to=parent); implements = from implements interface to; ",
      "composition / aggregation = from is the WHOLE that owns or holds to; uses = from depends on to; creates = from instantiates to; notifies = from calls back to.\n"
    ) else paste0(
      "Edge semantics: data = data or payload flows from -> to; control = triggers, orchestrates or configures; ",
      "event = asynchronous event or message; feedback = a loop that returns to an EARLIER stage (retraining, replay, reflection, user feedback).\n"
    ),
    "\nThen 5-9 numbered flow steps, each a block starting with @step:\n",
    "@step\norder: <1, 2, 3 ...>\ntext: <one sentence describing what happens at this step>\n",
    "components: <comma separated component ids involved in this step>\n",
    "\nThen 4-8 trade-offs, each a block starting with @tradeoff:\n",
    "@tradeoff\nkind: <pro|con|risk|cost|scaling>\ntext: <one sentence>\n",
    "\nThen 2-5 references, each a block starting with @reference:\n",
    "@reference\ntitle: <real book, paper or documentation title>\nauthor: <author or organisation, or N/A>\n",
    "url: <only a URL you are certain exists, otherwise N/A>\n"
  )

  paste0(
    "You are a principal engineer documenting a technical design for a diagramming tool. You output DATA only: ",
    "the tool computes the layout and draws the boxes and arrows itself, so never describe positions or coordinates.\n\n",
    "Design to document: ", design_label, " (", TD_GROUP_LABELS[[group]], ")\n",
    if (isTRUE(custom)) paste0("This is a custom design chosen by the user. Decide the most informative set of ",
                               if (kind == "class") "tiers and classes" else "swimlanes and components",
                               " yourself.\n") else "",
    if (nchar(trimws(guidance)) > 0) paste0("\nSTRUCTURE GUIDANCE (adapt it to the use case; keep the spirit and the key entities):", guidance, "\n") else "",
    if (nchar(trimws(context)) > 0) paste0("\nUse case / context to tailor the design to: ", trimws(context), "\n") else "",
    if (nchar(trimws(constraints)) > 0) paste0("Constraints, preferred stack or cloud: ", trimws(constraints), "\n") else "",
    if (nchar(trimws(reference)) > 0) paste0("Follow the principles of this reference resource and cite it in the references: ", trimws(reference),
                                             ". Do not invent quotes or page numbers.\n") else "",
    "\nRULES: every connection must use component ids that exist; every component must appear in at least one connection; ",
    "the diagram must be complete and correct for this design, with specific labels instead of generic placeholders; ",
    "never invent URLs.\n\n",
    fmt,
    "\nBegin now with the header lines."
  )
}
