# modules/behavior_trees.R — Chapter 6: Behavior Trees

behavior_trees_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class="meta-hero",
        tags$h1("Behavior Trees"),
        tags$h2("Chapter 6 — Structured Agent Decision-Making with py_trees"),
        div(span(class="hero-badge","py_trees"), span(class="hero-badge","Blackboard"),
            span(class="hero-badge","Composites"), span(class="hero-badge","Conditions & Actions"))
    ),
    fluidRow(
      box(title="🌲 What is a Behavior Tree?", status="primary", solidHeader=TRUE, width=6,
          div(class="success-box", HTML("<strong>Core insight:</strong> A Behavior Tree (BT) separates <em>what an agent can do</em> (actions/conditions as leaf nodes) from <em>how it decides what to do</em> (the tree structure). This makes complex agent logic composable, readable, and testable independently of the LLM.")),
          br(),
          framework_card("Sequence node (→)", "Executes children left-to-right. Stops and FAILS if any child fails. Like AND logic — all must succeed."),
          framework_card("Selector node (?)", "Tries children left-to-right. Stops and SUCCEEDS if any child succeeds. Like OR logic — first success wins."),
          framework_card("Parallel node (⇉)", "Runs all children simultaneously. Configurable success threshold (1-of-N or N-of-N)."),
          framework_card("Condition leaf", "Checks a state (e.g. 'Is battery > 20%?'). Returns SUCCESS or FAILURE instantly — no side effects."),
          framework_card("Action leaf", "Does something (e.g. 'Ask the LLM', 'Move to waypoint'). Returns RUNNING while executing, then SUCCESS or FAILURE.")
      ),
      box(title="🗂️ The Blackboard — Shared Agent Memory", status="info", solidHeader=TRUE, width=6,
          div(class="success-box", HTML("<strong>The Blackboard</strong> is py_trees' shared key-value store. All nodes in a tree can read/write to it. This is how an action node passes results to a subsequent condition node — without tight coupling.")),
          br(),
          div(class="code-box", HTML(
            '<span style="color:#C4B5FD">import</span> py_trees<br><br>
             <span style="color:#6B7280"># Behaviour (note British spelling in library)</span><br>
             <span style="color:#C4B5FD">class</span> <span style="color:#FCD34D">AskLLM</span>(py_trees.behaviour.Behaviour):<br>
             &nbsp;&nbsp;<span style="color:#C4B5FD">def</span> <span style="color:#FCD34D">__init__</span>(self, name):<br>
             &nbsp;&nbsp;&nbsp;&nbsp;super().__init__(name)<br>
             &nbsp;&nbsp;&nbsp;&nbsp;self.blackboard = self.attach_blackboard_client()<br>
             &nbsp;&nbsp;&nbsp;&nbsp;self.blackboard.register_key(<span style="color:#FCD34D">"llm_response"</span>, access=py_trees.common.Access.WRITE)<br><br>
             &nbsp;&nbsp;<span style="color:#C4B5FD">def</span> <span style="color:#FCD34D">update</span>(self):<br>
             &nbsp;&nbsp;&nbsp;&nbsp;response = call_openai(<span style="color:#FCD34D">"Your prompt here"</span>)<br>
             &nbsp;&nbsp;&nbsp;&nbsp;self.blackboard.llm_response = response<br>
             &nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#C4B5FD">return</span> py_trees.common.Status.SUCCESS<br><br>
             <span style="color:#6B7280"># Build tree: condition → sequence → action</span><br>
             root = py_trees.composites.Sequence(<span style="color:#FCD34D">"Root"</span>, memory=<span style="color:#A5F3FC">False</span>)<br>
             root.add_children([CheckBattery(<span style="color:#FCD34D">"Battery OK?"</span>), AskLLM(<span style="color:#FCD34D">"Ask"</span>)])'
          )),
          div(class="warn-box", HTML("<strong>⚠️ memory=False vs memory=True:</strong> With memory=True, a Sequence remembers where it left off if a child returns RUNNING. With memory=False, it always restarts from the first child. Chapter 6's examples use memory=False — the simpler default."))
      )
    ),
    fluidRow(
      box(title="💡 Why Behavior Trees for AI Agents?", status="warning", solidHeader=TRUE, width=12,
          fluidRow(
            column(4, framework_card("Composability", "Subtrees can be re-used across different agent configurations. A 'check internet connectivity' subtree works in any agent that needs it.")),
            column(4, framework_card("Testability", "Each leaf node can be unit-tested in isolation. You can test conditions and actions without running the full agent loop.")),
            column(4, framework_card("Transparency", "The tree structure is human-readable. You can diagram the agent's decision logic and show it to non-engineers. Unlike pure LLM reasoning, BT logic is deterministic and inspectable."))
          ),
          br(),
          fluidRow(
            column(6, textAreaInput(ns("notes"), "Study notes:", value="", rows=3, placeholder="Notes on py_trees, Blackboard, composites...")),
            column(3, sliderInput(ns("progress"), "Chapter 6 readiness:", 0, 100, 0, step=5)),
            column(3, br(), actionButton(ns("save_progress"), "Save Progress", class="btn-primary"))
          )
      )
    )
  )
}

behavior_trees_server <- function(id, study_mgr) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_progress, {
      study_mgr$save_note("behavior_trees", input$notes)
      study_mgr$update_progress("behavior_trees", input$progress)
      showNotification("Chapter 6 progress saved!", type="message", duration=3)
    })
  })
}
