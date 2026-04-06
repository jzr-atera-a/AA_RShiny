# modules/chapter22.R — Reinforcement Learning for Algorithmic Trading

chapter22_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(22, "🎮", "Reinforcement Learning",
      "Learning Optimal Trading Strategies - Q-learning, policy gradients, and deep RL for order execution, portfolio management, and market making.",
      c("RL", "Q-Learning", "Policy Gradient", "DQN", "PPO", "Actor-Critic")),

    stats_row(
      list("Agent", "Decision Maker"),
      list("Environment", "Market"), 
      list("Reward", "PnL/Sharpe"),
      list("Policy π", "Strategy")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),
        tabPanel(title = tagList(icon("book"), " Theory & Concepts"),
          fluidRow(
            box(title = "🎮 RL Framework: MDP", status = "info", solidHeader = TRUE, width = 12,
                framework_card("Markov Decision Process",
                  tagList(
                    tags$p("Agent interacts with environment to maximize cumulative reward:"),
                    tags$ul(
                      tags$li(tags$strong("State (s):"), " Market conditions, positions, portfolio"),
                      tags$li(tags$strong("Action (a):"), " Buy, sell, hold, quantities"),
                      tags$li(tags$strong("Reward (r):"), " PnL, risk-adjusted return, Sharpe ratio"),
                      tags$li(tags$strong("Policy (π):"), " Strategy: π(s) → a"),
                      tags$li(tags$strong("Value Function V(s):"), " Expected future return from state s"),
                      tags$li(tags$strong("Goal:"), " Learn optimal policy π* that maximizes Σ γ^t r_t")
                    )
                  )
                ),
                plotlyOutput(ns("mdp_cycle"), height = "200px")
            )
          ),
          
          fluidRow(
            box(title = "📊 Key RL Algorithms", status = "warning", solidHeader = TRUE, width = 12,
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(
                    tags$th("Algorithm"), 
                    tags$th("Type"), 
                    tags$th("Learning"),
                    tags$th("Action Space"),
                    tags$th("Trading Use")
                  )),
                  tags$tbody(
                    tags$tr(
                      tags$td(tags$strong("Q-Learning")),
                      tags$td("Value-based"),
                      tags$td("Off-policy"),
                      tags$td("Discrete"),
                      tags$td("Simple buy/sell/hold decisions")
                    ),
                    tags$tr(
                      tags$td(tags$strong("DQN")),
                      tags$td("Deep Q-Network"),
                      tags$td("Experience replay"),
                      tags$td("Discrete"),
                      tags$td("Complex state spaces")
                    ),
                    tags$tr(
                      tags$td(tags$strong("REINFORCE")),
                      tags$td("Policy gradient"),
                      tags$td("On-policy"),
                      tags$td("Continuous"),
                      tags$td("Position sizing")
                    ),
                    tags$tr(
                      tags$td(tags$strong("A2C/A3C")),
                      tags$td("Actor-Critic"),
                      tags$td("Asynchronous"),
                      tags$td("Both"),
                      tags$td("Portfolio management")
                    ),
                    tags$tr(
                      tags$td(tags$strong("PPO")),
                      tags$td("Proximal Policy Opt"),
                      tags$td("Stable training"),
                      tags$td("Continuous"),
                      tags$td("Optimal execution")
                    ),
                    tags$tr(
                      tags$td(tags$strong("DDPG")),
                      tags$td("Deep Deterministic PG"),
                      tags$td("Continuous control"),
                      tags$td("Continuous"),
                      tags$td("Market making")
                    )
                  )
                )
            )
          ),
          
          fluidRow(
            box(title = "🎯 Q-Learning", status = "success", solidHeader = TRUE, width = 6,
                framework_card("Update Rule",
                  tagList(
                    tags$p(tags$strong("Q(s,a) ← Q(s,a) + α[r + γ max Q(s',a') - Q(s,a)]")),
                    tags$ul(
                      tags$li(tags$strong("α:"), " Learning rate (0.1-0.01)"),
                      tags$li(tags$strong("γ:"), " Discount factor (0.9-0.99)"),
                      tags$li(tags$strong("ε-greedy:"), " Explore vs exploit"),
                      tags$li(tags$strong("Convergence:"), " Proven for tabular case")
                    )
                  )
                ),
                plotlyOutput(ns("q_learning_progress"), height = "200px")
            ),
            
            box(title = "🧠 Deep Q-Network (DQN)", status = "info", solidHeader = TRUE, width = 6,
                framework_card("Key Innovations",
                  tagList(
                    tags$ul(
                      tags$li(tags$strong("Neural Network:"), " Approximate Q(s,a) for large state spaces"),
                      tags$li(tags$strong("Experience Replay:"), " Store (s,a,r,s') tuples, sample randomly"),
                      tags$li(tags$strong("Target Network:"), " Separate Q' for stable updates"),
                      tags$li(tags$strong("Breaks Correlation:"), " Random sampling from buffer"),
                      tags$li(tags$strong("Result:"), " Superhuman performance on Atari games")
                    )
                  )
                )
            )
          ),
          
          fluidRow(
            box(title = "📈 Trading Applications", status = "success", solidHeader = TRUE, width = 12,
                framework_card("Practical Use Cases",
                  tagList(
                    tags$ul(
                      tags$li(tags$strong("Optimal Execution:"), " VWAP/TWAP beating via RL - minimize market impact"),
                      tags$li(tags$strong("Portfolio Allocation:"), " Dynamic rebalancing based on market conditions"),
                      tags$li(tags$strong("Market Making:"), " Bid-ask spread optimization, inventory management"),
                      tags$li(tags$strong("Options Hedging:"), " Delta hedging under transaction costs"),
                      tags$li(tags$strong("Order Routing:"), " Select best exchange/venue for execution"),
                      tags$li(tags$strong("Pairs Trading:"), " Entry/exit timing optimization")
                    )
                  )
                ),
                plotlyOutput(ns("rl_performance"), height = "300px")
            )
          ),
          
          fluidRow(
            box(title = "⚙️ Reward Engineering", status = "warning", solidHeader = TRUE, width = 6,
                framework_card("Designing Rewards",
                  tagList(
                    tags$p("Critical: Reward function determines learned behavior"),
                    tags$ul(
                      tags$li(tags$strong("PnL:"), " Simple but encourages risk-taking"),
                      tags$li(tags$strong("Sharpe Ratio:"), " Risk-adjusted, but sparse signal"),
                      tags$li(tags$strong("Incremental PnL:"), " Dense rewards, faster learning"),
                      tags$li(tags$strong("Penalties:"), " Transaction costs, drawdown, volatility"),
                      tags$li(tags$strong("Shaping:"), " Intermediate rewards to guide learning")
                    )
                  )
                )
            ),
            
            box(title = "🎲 Exploration vs Exploitation", status = "info", solidHeader = TRUE, width = 6,
                framework_card("Balancing Trade-off",
                  tagList(
                    tags$ul(
                      tags$li(tags$strong("ε-greedy:"), " Random action with probability ε (0.1-0.01)"),
                      tags$li(tags$strong("Boltzmann:"), " Sample from softmax(Q/T)"),
                      tags$li(tags$strong("UCB:"), " Upper confidence bound"),
                      tags$li(tags$strong("Decay:"), " Start high ε, decay over episodes"),
                      tags$li(tags$strong("Trading:"), " Higher exploration in train, low in test")
                    )
                  )
                ),
                plotlyOutput(ns("exploration_decay"), height = "200px")
            )
          )
        ),
        tabPanel(title = tagList(icon("code"), " Python Code"),
          python_code_tab()
        )
      )
    )
  )
}

chapter22_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    output$mdp_cycle <- renderPlotly({
      components <- c("State", "Policy\nπ(s)", "Action", "Environment", "Reward")
      x_pos <- c(1, 2.5, 4, 5.5, 4)
      y_pos <- c(1, 1, 1, 1, 0.3)
      
      plot_ly(x = x_pos, y = y_pos, text = components, mode = "markers+text",
              marker = list(size = 50, color = generate_palette(5), line = list(color = "white", width = 2)),
              textposition = "middle center", textfont = list(size = 10, color = "white"),
              hoverinfo = "none") %>%
        layout(
          title = list(text = "RL: Agent-Environment Interaction Loop", font = list(color = "#E6EDF3")),
          xaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE),
          yaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE),
          plot_bgcolor = 'rgba(0,0,0,0)', paper_bgcolor = 'rgba(0,0,0,0)', font = list(color = "#E6EDF3")
        )
    })
    
    output$q_learning_progress <- renderPlotly({
      episodes <- 1:500
      cumulative_reward <- 100 * (1 - exp(-episodes/100)) + rnorm(500, 0, 5)
      
      plot_ly(x = episodes, y = cumulative_reward, type = "scatter", mode = "lines",
              line = list(color = ml_colors$primary, width = 2)) %>%
        layout(
          title = list(text = "Q-Learning: Cumulative Reward", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Episode", color = "#8B949E", gridcolor = "#30363D"),
          yaxis = list(title = "Cumulative Reward", color = "#8B949E", gridcolor = "#30363D"),
          plot_bgcolor = 'rgba(0,0,0,0)', paper_bgcolor = 'rgba(0,0,0,0)', font = list(color = "#E6EDF3")
        )
    })
    
    output$rl_performance <- renderPlotly({
      dates <- seq(as.Date("2020-01-01"), as.Date("2023-12-31"), by = "day")
      baseline <- cumprod(1 + rnorm(length(dates), 0.0002, 0.012))
      rl_strategy <- cumprod(1 + rnorm(length(dates), 0.0004, 0.011))
      
      plot_ly() %>%
        add_trace(x = dates, y = baseline, name = "TWAP Baseline", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$secondary, width = 2)) %>%
        add_trace(x = dates, y = rl_strategy, name = "RL Optimal Execution", type = "scatter", mode = "lines",
                  line = list(color = ml_colors$primary, width = 2)) %>%
        layout(
          title = list(text = "RL vs Baseline: Cumulative Execution Cost Savings", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Date", color = "#8B949E"),
          yaxis = list(title = "Cumulative PnL", color = "#8B949E", gridcolor = "#30363D"),
          plot_bgcolor = 'rgba(0,0,0,0)', paper_bgcolor = 'rgba(0,0,0,0)', font = list(color = "#E6EDF3"),
          legend = list(font = list(color = "#E6EDF3"), bgcolor = "rgba(28, 33, 40, 0.8)")
        )
    })
    
    output$exploration_decay <- renderPlotly({
      episodes <- 1:1000
      epsilon <- pmax(0.01, 1.0 * exp(-episodes/200))
      
      plot_ly(x = episodes, y = epsilon, type = "scatter", mode = "lines",
              fill = "tozeroy", line = list(color = ml_colors$primary, width = 2)) %>%
        layout(
          title = list(text = "ε-Greedy Exploration Decay", font = list(color = "#E6EDF3")),
          xaxis = list(title = "Episode", color = "#8B949E", gridcolor = "#30363D"),
          yaxis = list(title = "ε (Exploration Rate)", color = "#8B949E", gridcolor = "#30363D"),
          plot_bgcolor = 'rgba(0,0,0,0)', paper_bgcolor = 'rgba(0,0,0,0)', font = list(color = "#E6EDF3")
        )
    })
    
  })
}
