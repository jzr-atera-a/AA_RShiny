# modules/memory_rag.R — Chapter 8: Memory & RAG

memory_rag_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class="meta-hero",
        tags$h1("Memory & RAG"),
        tags$h2("Chapter 8 — Semantic Kernel Memory, Vector Search & LangChain Retrieval"),
        div(span(class="hero-badge","SemanticTextMemory"), span(class="hero-badge","ChromaDB"),
            span(class="hero-badge","LangChain 1.x"), span(class="hero-badge","Embeddings"))
    ),
    fluidRow(
      box(title="🧠 Semantic Kernel Memory — Full API Migration (Ch.8)", status="primary", solidHeader=TRUE, width=6,
          div(class="warn-box", HTML("<strong>All 5 SK memory files needed rewriting.</strong> The memory API changed completely between 0.x and 1.43.1. The old VolatileMemoryStore was restructured; kernel.memory is gone; async method names changed.")),
          br(),
          tags$table(class="table table-hover",
            tags$thead(tags$tr(tags$th("Old (book)"), tags$th("New (1.43.1)"))),
            tags$tbody(
              tags$tr(tags$td(tags$code("sk.memory.VolatileMemoryStore"), style="color:#dc2626;font-family:'JetBrains Mono',monospace;font-size:11px;"), tags$td(tags$code("from semantic_kernel.memory.volatile_memory_store import VolatileMemoryStore"), style="color:#16a34a;font-weight:600;font-family:'JetBrains Mono',monospace;font-size:11px;")),
              tags$tr(tags$td(tags$code("kernel.memory"), style="color:#dc2626;font-family:'JetBrains Mono',monospace;font-size:11px;"), tags$td("Explicit SemanticTextMemory(storage=, embeddings_generator=)", style="color:#16a34a;font-weight:600;font-size:12px;")),
              tags$tr(tags$td(tags$code("sk.core_skills.TextMemorySkill"), style="color:#dc2626;font-family:'JetBrains Mono',monospace;font-size:11px;"), tags$td(tags$code("TextMemoryPlugin(memory)"), style="color:#16a34a;font-weight:600;font-family:'JetBrains Mono',monospace;font-size:11px;")),
              tags$tr(tags$td(tags$code("save_information_async()"), style="color:#dc2626;font-family:'JetBrains Mono',monospace;font-size:11px;"), tags$td(tags$code("save_information() (no _async suffix)"), style="color:#16a34a;font-weight:600;font-family:'JetBrains Mono',monospace;font-size:11px;")),
              tags$tr(tags$td(tags$code("TextMemorySkill.COLLECTION_PARAM"), style="color:#dc2626;font-family:'JetBrains Mono',monospace;font-size:11px;"), tags$td(tags$code('arguments["collection"]'), style="color:#16a34a;font-weight:600;font-family:'JetBrains Mono',monospace;font-size:11px;"))
            )
          ),
          br(),
          div(class="code-box", HTML(
            '<span style="color:#6B7280"># Modern SK memory setup</span><br>
             <span style="color:#C4B5FD">from</span> semantic_kernel.memory.volatile_memory_store <span style="color:#C4B5FD">import</span> VolatileMemoryStore<br>
             <span style="color:#C4B5FD">from</span> semantic_kernel.memory.semantic_text_memory <span style="color:#C4B5FD">import</span> SemanticTextMemory<br>
             <span style="color:#C4B5FD">from</span> semantic_kernel.connectors.memory.chroma <span style="color:#C4B5FD">import</span> ChromaMemoryStore<br><br>
             memory = SemanticTextMemory(<br>
             &nbsp;&nbsp;storage=VolatileMemoryStore(),<br>
             &nbsp;&nbsp;embeddings_generator=embeddings_service<br>
             )<br>
             <span style="color:#C4B5FD">await</span> memory.save_information(<span style="color:#FCD34D">"my_collection"</span>, id=<span style="color:#FCD34D">"1"</span>, text=<span style="color:#FCD34D">"..."</span>)'
          ))
      ),
      box(title="🔗 LangChain 1.x Import Migration (Ch.8)", status="info", solidHeader=TRUE, width=6,
          div(class="success-box", HTML("<strong>LangChain 1.0</strong> split its monolithic package into smaller focused packages. Every old import path changed.")),
          br(),
          tags$table(class="table table-hover",
            tags$thead(tags$tr(tags$th("Old import (book)"), tags$th("New import"))),
            tags$tbody(
              tags$tr(tags$td(tags$code("langchain.document_loaders"), style="color:#dc2626;font-family:'JetBrains Mono',monospace;font-size:11px;"), tags$td(tags$code("langchain_community.document_loaders"), style="color:#16a34a;font-weight:600;font-family:'JetBrains Mono',monospace;font-size:11px;")),
              tags$tr(tags$td(tags$code("langchain.text_splitter"), style="color:#dc2626;font-family:'JetBrains Mono',monospace;font-size:11px;"), tags$td(tags$code("langchain_text_splitters"), style="color:#16a34a;font-weight:600;font-family:'JetBrains Mono',monospace;font-size:11px;")),
              tags$tr(tags$td(tags$code("langchain.embeddings"), style="color:#dc2626;font-family:'JetBrains Mono',monospace;font-size:11px;"), tags$td(tags$code("langchain_openai"), style="color:#16a34a;font-weight:600;font-family:'JetBrains Mono',monospace;font-size:11px;")),
              tags$tr(tags$td(tags$code("langchain.vectorstores"), style="color:#dc2626;font-family:'JetBrains Mono',monospace;font-size:11px;"), tags$td(tags$code("langchain_chroma"), style="color:#16a34a;font-weight:600;font-family:'JetBrains Mono',monospace;font-size:11px;")),
              tags$tr(tags$td(tags$code(".get_relevant_documents()"), style="color:#dc2626;font-family:'JetBrains Mono',monospace;font-size:11px;"), tags$td(tags$code(".invoke()"), style="color:#16a34a;font-weight:600;font-family:'JetBrains Mono',monospace;font-size:11px;"))
            )
          ),
          br(),
          div(class="section-heading-dark", "How RAG works — the pipeline"),
          timeline_entry("1", "Load documents", "PDFs, markdown, web pages via DocumentLoaders into a list of Document objects."),
          timeline_entry("2", "Chunk", "TextSplitter breaks large documents into overlapping chunks (e.g. 1000 chars, 200 overlap)."),
          timeline_entry("3", "Embed & store", "Each chunk is embedded via OpenAI or HuggingFace, then stored in ChromaDB with metadata."),
          timeline_entry("4", "Retrieve", "On each user query, embed the query → cosine similarity search → top-k chunks returned."),
          timeline_entry("5", "Augment & generate", "Chunks are injected into the prompt as context. The LLM answers using retrieved facts.")
      )
    ),
    fluidRow(
      box(title="✍️ Study Notes", status="success", solidHeader=TRUE, width=12,
          fluidRow(
            column(6, textAreaInput(ns("notes"), "Study notes:", value="", rows=3, placeholder="Notes on SK memory, LangChain RAG pipeline...")),
            column(3, sliderInput(ns("progress"), "Chapter 8 readiness:", 0, 100, 0, step=5)),
            column(3, br(), actionButton(ns("save_progress"), "Save Progress", class="btn-primary"))
          )
      )
    )
  )
}

memory_rag_server <- function(id, study_mgr) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_progress, {
      study_mgr$save_note("memory_rag", input$notes)
      study_mgr$update_progress("memory_rag", input$progress)
      showNotification("Chapter 8 progress saved!", type="message", duration=3)
    })
  })
}
