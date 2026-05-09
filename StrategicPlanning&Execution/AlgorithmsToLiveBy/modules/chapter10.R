# Chapter 10: Networking — How We Connect

chapter10_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(10,"\U0001f310","Networking",
      "The protocols that govern the internet were designed to solve fundamental problems of communication: how to reliably share a channel, how to recover from failure, how to avoid congestion. The solutions — exponential backoff, TCP's AIMD, buffer management — are elegant and deeply applicable to human communication.",
      c("TCP/IP","Exponential Backoff","AIMD","Flow Control","Buffer Bloat","Packet Switching")),
    stats_row(list("3","TCP handshake steps"), list("2\u00d7","Backoff multiplier"), list("AIMD","Congestion control"), list("Minimal","Ideal buffer size")),

    fluidRow(tabBox(width=12, id=ns("tabs"),
      tabPanel(title=tagList(icon("book")," Core Concepts"),
        fluidRow(
          box(title="\U0001f4e1 How the Internet Works", status="info", solidHeader=TRUE, width=6,
              div(class="framework-card", tags$h5("Packet Switching"),
                  tags$p("Data is broken into packets, each routed independently. Packets may take
                          different paths and arrive out of order. TCP reassembles them."),
                  tags$p("The alternative (circuit switching, used by old phone networks) reserves
                          a dedicated channel. Packet switching is vastly more efficient because
                          channels are shared and idle capacity is reused.")),
              div(class="framework-card", tags$h5("The TCP Handshake"),
                  timeline_strip(
                    list("SYN","Client: 'I want to talk'"),
                    list("SYN-ACK","Server: 'I'm ready'"),
                    list("ACK","Client: 'Great, let's go'"),
                    list("Data","Bidirectional exchange begins")
                  )),
              div(class="framework-card", tags$h5("Acknowledgement & Retransmission"),
                  tags$p("TCP requires acknowledgement (ACK) for every packet. If no ACK arrives within
                          a timeout, the packet is retransmitted. This guarantees reliable delivery over
                          an unreliable physical layer."))),
          box(title="\u23f0 Exponential Backoff", status="warning", solidHeader=TRUE, width=6,
              div(class="framework-card", tags$h5("The Problem: Collision"),
                  tags$p("When multiple devices transmit simultaneously, packets collide and are lost.
                          Both devices retransmit at the same time \u2014 and collide again.")),
              div(class="framework-card", tags$h5("The Solution: Exponential Backoff"),
                  tags$p("After k collisions, wait a random time in [0, 2^k - 1] slots before retransmitting:"),
                  algo_table(c("Collision #","Wait range","Expected wait"),
                    list(list("1st","0-1 slots","0.5 slots"),
                         list("2nd","0-3 slots","1.5 slots"),
                         list("3rd","0-7 slots","3.5 slots"),
                         list("4th","0-15 slots","7.5 slots"),
                         list("5th","0-31 slots","15.5 slots"),
                         list("10th","0-1023 slots","511.5 slots")))),
              div(class="tip-box", HTML("<strong>\U0001f4a1 The genius:</strong> Each collision doubles the expected wait,
                exponentially reducing the probability of another collision. The system self-regulates
                without any central coordinator.")))
        ),
        fluidRow(
          box(title="\U0001f4c8 AIMD: Additive Increase, Multiplicative Decrease", status="success", solidHeader=TRUE, width=12,
              fluidRow(
                column(4, div(class="framework-card", tags$h5("TCP Congestion Control"),
                    tags$p("TCP adjusts its sending rate using AIMD:"),
                    tags$ul(tags$li(tags$strong("Additive Increase:")," when no congestion detected, increase send rate by 1 packet per round trip"),
                            tags$li(tags$strong("Multiplicative Decrease:")," when congestion detected (packet loss), halve the send rate")),
                    tags$p("This creates the characteristic 'sawtooth' pattern of TCP throughput."))),
                column(4, div(class="framework-card", tags$h5("Why AIMD Works"),
                    tags$ul(tags$li("AI ensures utilisation increases gradually (probing for available bandwidth)"),
                            tags$li("MD ensures rapid recovery from congestion (halving beats additive decrease)"),
                            tags$li("Multiple TCP connections sharing a link converge to equal fair shares"),
                            tags$li("AIMD is provably fair and efficient in steady state"))),
                  div(class="info-box-plain", HTML("<strong>\u2139 Game theory result:</strong> AIMD is also a Nash equilibrium \u2014
                    no individual sender can improve their throughput by defecting from the protocol."))),
                column(4, div(class="insight-box",
                    tags$p(class="ib-title","BUFFER BLOAT"),
                    tags$p("Adding more buffer (memory) to routers seems helpful but causes",tags$strong("buffer bloat"),": packets are delayed in queues instead of dropped, so TCP never gets the 'congestion' signal it needs."),
                    tags$p("Result: low loss rate, but very high latency. Your downloads are fast but your video call stutters."),
                    tags$p("Lesson: don't buffer everything. Let failures signal real problems.")))
              )
          )
        )
      ),
      tabPanel(title=tagList(icon("users")," Human Applications"),
        fluidRow(
          box(title="\U0001f4ac Human Communication Protocols", status="danger", solidHeader=TRUE, width=6,
              div(class="framework-card", tags$h5("Conversation as TCP"),
                  tags$p("A conversation requires acknowledgement: nods, 'uh-huh', laughter, and questions
                          are all ACKs. Without them, the speaker doesn't know if the message was received."),
                  tags$p("Good listeners send frequent ACKs. Poor listeners send none \u2014 leaving the speaker
                          uncertain whether their message is getting through.")),
              div(class="framework-card", tags$h5("The Three-Way Handshake in Life"),
                  algo_table(c("Protocol","TCP equivalent","Human equivalent"),
                    list(list("SYN","I want to talk","'Do you have a minute?'"),
                         list("SYN-ACK","I'm ready","'Sure, what's up?'"),
                         list("ACK","Great","'OK so here's the thing...'")))),
              div(class="framework-card", tags$h5("Backoff in Social Situations"),
                  tags$p("You send a message and get no reply. You send again. Still nothing.
                          The protocol says: increase your wait before each retry."),
                  tags$p("People who ignore exponential backoff are spam; they clog the channel.
                          Those who wait too long may never reconnect."))),
          box(title="\U0001f4f6 Networking Lessons for Organisations", status="success", solidHeader=TRUE, width=6,
              div(class="framework-card", tags$h5("Meetings as Congestion"),
                  tags$p("Too many concurrent meetings = packet collisions. Each person is trying to broadcast
                          simultaneously, and the messages collide in people's attention channels.")),
              div(class="framework-card", tags$h5("Email Overload"),
                  tags$p("Email is an unreliable protocol (no guaranteed read ACK). CC-ing everyone
                          is broadcast, not unicast. Reply-all is a multicast storm.")),
              div(class="framework-card", tags$h5("The Buffer Bloat Lesson for Organisations"),
                  tags$p("'Never say no, always queue it' \u2014 organisations that buffer everything have
                          high queue lengths, long wait times, and no feedback signal for overload."),
                  tags$p(tags$strong("Better:"), " let some things fail fast, signal overload clearly,
                          and shed load gracefully.")),
              pull_quote("Buffer bloat teaches us that sometimes the kindest thing is to reject a request promptly rather than queue it indefinitely.",
                         "Christian & Griffiths"))
        )
      ),
      tabPanel(title=tagList(icon("lightbulb")," Key Insights"),
        fluidRow(
          box(title="\U0001f4a1 Core Takeaways", status="warning", solidHeader=TRUE, width=6,
              div(class="insight-box", tags$p(class="ib-title","EXPONENTIAL BACKOFF IS WISDOM"),
                  tags$p("When you fail, don't immediately retry at full speed. Double your wait.
                          This is the internet's self-regulating mechanism, and it applies to human
                          persistence too: escalating too fast creates more congestion.")),
              div(class="insight-box", tags$p(class="ib-title","ACK OR DIE"),
                  tags$p("Reliable communication requires acknowledgement. Without ACKs, the sender
                          doesn't know their message was received. In human communication,
                          unacknowledged messages are often re-sent repeatedly (nagging).")),
              div(class="insight-box", tags$p(class="ib-title","DON'T BUFFER EVERYTHING"),
                  tags$p("Queueing everything to avoid saying no creates high latency and hides the
                          true capacity of the system. Saying 'I'm overloaded right now' is healthier
                          than quietly falling further behind."))),
          box(title="\u2705 Communication Protocols for Life", status="success", solidHeader=TRUE, width=6,
              algo_table(c("Network concept","Human equivalent","Application"),
                list(list("Packet switching","Multitasking in attention","Switch contexts between people efficiently"),
                     list("TCP handshake","Establishing communication","Set context before diving in"),
                     list("ACK","Active listening signals","Nod, paraphrase, respond promptly"),
                     list("Timeout & retransmit","Follow up if no response","Wait, then nudge once"),
                     list("Exponential backoff","Escalating patience","Double wait after each non-response"),
                     list("Flow control","Manage information rate","Check comprehension before continuing"),
                     list("Buffer bloat","Over-promising","Say no promptly rather than queue indefinitely"),
                     list("AIMD","Resource fairness","Take less when others are competing; take more when available"))))
        )
      )
    ))
  )
}
chapter10_server <- function(id) moduleServer(id, function(input,output,session){})
