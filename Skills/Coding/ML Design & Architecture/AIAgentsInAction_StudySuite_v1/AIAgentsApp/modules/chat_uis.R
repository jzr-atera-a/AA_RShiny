# modules/chat_uis.R — Chapter 7: Chat UIs with Streamlit

chat_uis_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class="meta-hero",
        tags$h1("Chat UIs — Streamlit"),
        tags$h2("Chapter 7 — Building Production Chat Interfaces with Streamlit"),
        div(span(class="hero-badge","Streamlit"), span(class="hero-badge","session_state"),
            span(class="hero-badge","Streaming"), span(class="hero-badge","Multi-turn"))
    ),
    fluidRow(
      box(title="🖥️ Streamlit Chat Pattern — The Three Primitives", status="primary", solidHeader=TRUE, width=6,
          div(class="success-box", HTML("<strong>Three things you need:</strong> <code>st.chat_message()</code> for rendering bubbles, <code>st.chat_input()</code> for the input field, and <code>st.session_state.messages</code> for persisting the history across Streamlit reruns.")),
          br(),
          div(class="code-box", HTML(
            '<span style="color:#C4B5FD">import</span> streamlit <span style="color:#C4B5FD">as</span> st<br>
             <span style="color:#C4B5FD">from</span> openai <span style="color:#C4B5FD">import</span> OpenAI<br><br>
             client = OpenAI()<br><br>
             <span style="color:#6B7280"># Initialise message history</span><br>
             <span style="color:#C4B5FD">if</span> <span style="color:#FCD34D">"messages"</span> <span style="color:#C4B5FD">not in</span> st.session_state:<br>
             &nbsp;&nbsp;st.session_state.messages = []<br><br>
             <span style="color:#6B7280"># Render existing messages</span><br>
             <span style="color:#C4B5FD">for</span> msg <span style="color:#C4B5FD">in</span> st.session_state.messages:<br>
             &nbsp;&nbsp;<span style="color:#C4B5FD">with</span> st.chat_message(msg[<span style="color:#FCD34D">"role"</span>]):<br>
             &nbsp;&nbsp;&nbsp;&nbsp;st.markdown(msg[<span style="color:#FCD34D">"content"</span>])<br><br>
             <span style="color:#6B7280"># Handle new input</span><br>
             <span style="color:#C4B5FD">if</span> prompt := st.chat_input(<span style="color:#FCD34D">"Message..."</span>):<br>
             &nbsp;&nbsp;st.session_state.messages.append({<span style="color:#FCD34D">"role"</span>:<span style="color:#FCD34D">"user"</span>,<span style="color:#FCD34D">"content"</span>:prompt})<br>
             &nbsp;&nbsp;<span style="color:#C4B5FD">with</span> st.chat_message(<span style="color:#FCD34D">"user"</span>): st.markdown(prompt)<br>
             &nbsp;&nbsp;<span style="color:#C4B5FD">with</span> st.chat_message(<span style="color:#FCD34D">"assistant"</span>):<br>
             &nbsp;&nbsp;&nbsp;&nbsp;reply = st.write_stream(get_stream(st.session_state.messages))<br>
             &nbsp;&nbsp;st.session_state.messages.append({<span style="color:#FCD34D">"role"</span>:<span style="color:#FCD34D">"assistant"</span>,<span style="color:#FCD34D">"content"</span>:reply})'
          ))
      ),
      box(title="⚡ Streaming with st.write_stream()", status="info", solidHeader=TRUE, width=6,
          div(class="success-box", HTML("<strong>Key pattern:</strong> <code>st.write_stream()</code> accepts any generator that yields strings. Pass the OpenAI streaming response through a generator that extracts delta content, and Streamlit handles the progressive rendering.")),
          br(),
          div(class="code-box", HTML(
            '<span style="color:#C4B5FD">def</span> <span style="color:#FCD34D">get_stream</span>(messages):<br>
             &nbsp;&nbsp;<span style="color:#FCD34D">"""Generator that yields token deltas from OpenAI stream."""</span><br>
             &nbsp;&nbsp;stream = client.chat.completions.create(<br>
             &nbsp;&nbsp;&nbsp;&nbsp;model=<span style="color:#FCD34D">"gpt-4o-mini"</span>,<br>
             &nbsp;&nbsp;&nbsp;&nbsp;messages=messages,<br>
             &nbsp;&nbsp;&nbsp;&nbsp;stream=<span style="color:#A5F3FC">True</span><br>
             &nbsp;&nbsp;)<br>
             &nbsp;&nbsp;<span style="color:#C4B5FD">for</span> chunk <span style="color:#C4B5FD">in</span> stream:<br>
             &nbsp;&nbsp;&nbsp;&nbsp;text = chunk.choices[0].delta.content<br>
             &nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#C4B5FD">if</span> text <span style="color:#C4B5FD">is not</span> <span style="color:#A5F3FC">None</span>:<br>
             &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#C4B5FD">yield</span> text'
          )),
          div(class="warn-box", HTML("<strong>⚠️ Model fix:</strong> The book uses <code>gpt-4-1106-preview</code>. This is retired. Replace with <code>gpt-4o-mini</code> in both <code>chatgpt_clone_response.py</code> and <code>chatgpt_clone_streaming.py</code>.")),
          br(),
          div(class="section-heading-dark", "Streamlit session_state — the critical concept"),
          tags$p("Streamlit reruns the entire Python script on every user interaction. Without", tags$code("st.session_state"), ", you'd lose the conversation history on every message. Everything that must persist across reruns lives in session_state.")
      )
    ),
    fluidRow(
      box(title="✍️ Study Notes", status="success", solidHeader=TRUE, width=12,
          fluidRow(
            column(6, textAreaInput(ns("notes"), "Study notes:", value="", rows=3, placeholder="Notes on Streamlit chat patterns, session_state...")),
            column(3, sliderInput(ns("progress"), "Chapter 7 readiness:", 0, 100, 0, step=5)),
            column(3, br(), actionButton(ns("save_progress"), "Save Progress", class="btn-primary"))
          )
      )
    )
  )
}

chat_uis_server <- function(id, study_mgr) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_progress, {
      study_mgr$save_note("chat_uis", input$notes)
      study_mgr$update_progress("chat_uis", input$progress)
      showNotification("Chapter 7 progress saved!", type="message", duration=3)
    })
  })
}
