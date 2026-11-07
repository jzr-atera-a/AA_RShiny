# R/utils_techdesign_algo_handbook.R
# Intro and handbook of the 23 LeetCode pattern groups (the first, left-most sub-tab of the Algorithms hub).
# Written in plain words; problem names are the public LeetCode titles.

ALGO_CATEGORIES <- list(
  list(label = "ARRAYS, STRINGS AND SEARCH", text = "The workhorses of the interview: scan once, shrink the search space, or trade memory for time.", ids = c("array_hashing", "two_pointers", "sliding_window", "binary_search", "intervals")),
  list(label = "STACKS, LISTS AND HEAPS", text = "Structures that give you the next item to process: last in, neighbour by pointer, or best by priority.", ids = c("stack_monotonic", "linked_list", "heap_priority_queue")),
  list(label = "TREES AND TRIES", text = "Hierarchies: recurse over children, walk level by level, or share prefixes.", ids = c("trees_dfs_bfs", "tries")),
  list(label = "GRAPHS", text = "Networks of nodes and edges: traverse, order, group, route and connect them.", ids = c("graph_traversal", "topological_sort", "union_find", "dijkstra_shortest_path", "minimum_spanning_tree")),
  list(label = "SEARCH AND OPTIMISATION", text = "Explore choices, reuse sub-answers, or commit to the best local choice.", ids = c("backtracking", "dp_1d", "dp_2d", "greedy")),
  list(label = "MATH, BITS AND DESIGN QUESTIONS", text = "Arithmetic tricks and the data-structure design questions that appear in software-design rounds.", ids = c("math_geometry", "bit_manipulation", "design_cache_lru", "design_feed_ratelimiter")))

# signals (what in the question points to it) | typical problems | time | space | sample question
ALGO_INFO <- list(
  array_hashing = list(sig = "Find a pair, duplicate, count or group; need O(1) lookup of what was seen before.", pr = "Two Sum; Contains Duplicate; Group Anagrams; Top K Frequent Elements; Subarray Sum Equals K", t = "O(n)", s = "O(n)", q = "Given an array of integers and a target, return the indices of two numbers that add up to the target."),
  two_pointers = list(sig = "Sorted array or string; a pair or triple with a property; compare from both ends; partition in place.", pr = "Two Sum II; 3Sum; Container With Most Water; Valid Palindrome; Trapping Rain Water", t = "O(n)", s = "O(1)", q = "Given a sorted array, find all unique triplets that sum to zero."),
  sliding_window = list(sig = "Longest or shortest contiguous subarray or substring under a constraint; fixed window of size k.", pr = "Longest Substring Without Repeating Characters; Minimum Window Substring; Permutation in String; Best Time to Buy and Sell Stock", t = "O(n)", s = "O(k)", q = "Find the length of the longest substring without repeating characters."),
  binary_search = list(sig = "Sorted or rotated input; a yes/no condition that flips once; minimise the maximum or maximise the minimum.", pr = "Search in Rotated Sorted Array; Find Minimum in Rotated Sorted Array; Koko Eating Bananas; Median of Two Sorted Arrays", t = "O(log n)", s = "O(1)", q = "A rotated sorted array has no duplicates: find a target in O(log n)."),
  intervals = list(sig = "Ranges with start and end; overlaps, merging, rooms or resources over time.", pr = "Merge Intervals; Insert Interval; Meeting Rooms II; Non-overlapping Intervals", t = "O(n log n)", s = "O(n)", q = "Given meeting time intervals, find the minimum number of rooms required."),
  stack_monotonic = list(sig = "Matching brackets, undo, nearest greater or smaller element, histogram areas.", pr = "Valid Parentheses; Min Stack; Daily Temperatures; Largest Rectangle in Histogram", t = "O(n)", s = "O(n)", q = "For each day, how many days until a warmer temperature?"),
  linked_list = list(sig = "Pointers and in-place changes; cycles; the middle or the k-th from the end; merging lists.", pr = "Reverse Linked List; Linked List Cycle; Merge Two Sorted Lists; Reorder List; LRU Cache", t = "O(n)", s = "O(1)", q = "Detect whether a linked list has a cycle and find where it starts."),
  heap_priority_queue = list(sig = "Top-K, k-th largest, merge k sorted streams, running median, always process the best next.", pr = "Kth Largest Element in an Array; Merge k Sorted Lists; Find Median from Data Stream; Task Scheduler", t = "O(n log k)", s = "O(k)", q = "Return the 10 most recent posts from the accounts a user follows."),
  trees_dfs_bfs = list(sig = "Binary tree or hierarchy; depth, ancestors, paths, levels, validation.", pr = "Maximum Depth of Binary Tree; Lowest Common Ancestor; Binary Tree Level Order Traversal; Validate BST; Serialize and Deserialize Binary Tree", t = "O(n)", s = "O(h)", q = "Find the lowest common ancestor of two nodes in a binary tree."),
  tries = list(sig = "Many words sharing prefixes; autocomplete; dictionary lookup by prefix; search on a board.", pr = "Implement Trie; Design Add and Search Words Data Structure; Word Search II", t = "O(L) per word", s = "O(total letters)", q = "Design an autocomplete that returns words starting with a typed prefix."),
  graph_traversal = list(sig = "Grid or network; connected regions; shortest path with equal edge cost; spreading over time.", pr = "Number of Islands; Clone Graph; Rotting Oranges; Pacific Atlantic Water Flow; Word Ladder", t = "O(V + E)", s = "O(V)", q = "Count the number of islands in a grid of land and water."),
  topological_sort = list(sig = "Tasks with prerequisites; build order; detect a cycle in a directed graph.", pr = "Course Schedule; Course Schedule II; Alien Dictionary", t = "O(V + E)", s = "O(V + E)", q = "Given courses and prerequisites, can you finish all of them, and in what order?"),
  union_find = list(sig = "Group items into components as links arrive; are two items connected; merge accounts.", pr = "Number of Provinces; Redundant Connection; Accounts Merge; Number of Connected Components in an Undirected Graph", t = "O(n a(n))", s = "O(n)", q = "Given friendships as pairs, how many friend circles are there?"),
  dijkstra_shortest_path = list(sig = "Weighted graph; cheapest or fastest route; non-negative costs.", pr = "Network Delay Time; Cheapest Flights Within K Stops; Path With Minimum Effort", t = "O(E log V)", s = "O(V)", q = "How long until a signal sent from node k reaches every node in a weighted network?"),
  minimum_spanning_tree = list(sig = "Connect every node at the lowest total cost; cables, roads, pipes.", pr = "Min Cost to Connect All Points; Optimize Water Distribution in a Village", t = "O(E log E)", s = "O(V)", q = "Connect all points on a plane with the minimum total Manhattan distance."),
  backtracking = list(sig = "Generate all subsets, permutations or combinations; place items under constraints; try, recurse, undo.", pr = "Subsets; Permutations; Combination Sum; N-Queens; Word Search", t = "O(2^n) to O(n!)", s = "O(n)", q = "Return all unique combinations of candidates that sum to a target."),
  dp_1d = list(sig = "Best or count for the first i items; the answer for i depends on a few earlier answers.", pr = "Climbing Stairs; House Robber; Coin Change; Longest Increasing Subsequence; Word Break", t = "O(n) to O(n^2)", s = "O(n)", q = "What is the fewest coins needed to make a given amount?"),
  dp_2d = list(sig = "Two sequences or a grid; the answer depends on the neighbours above, left and diagonal.", pr = "Unique Paths; Longest Common Subsequence; Edit Distance; Partition Equal Subset Sum; Interleaving String", t = "O(m n)", s = "O(m n)", q = "What is the minimum number of edits to turn one word into another?"),
  greedy = list(sig = "A local best choice that is provably safe; scheduling, covering, jumping.", pr = "Jump Game; Gas Station; Partition Labels; Maximum Subarray", t = "O(n) to O(n log n)", s = "O(1)", q = "Can you reach the last index if each value is the maximum jump length?"),
  math_geometry = list(sig = "Matrices, number properties, cycles in sequences, fast exponentiation.", pr = "Rotate Image; Spiral Matrix; Happy Number; Pow(x, n); Multiply Strings", t = "varies", s = "O(1)", q = "Rotate an n by n matrix by 90 degrees in place."),
  bit_manipulation = list(sig = "Pairs that cancel, flags in an integer, powers of two, no extra memory.", pr = "Single Number; Number of 1 Bits; Counting Bits; Missing Number; Sum of Two Integers", t = "O(n)", s = "O(1)", q = "Every number appears twice except one: find it using constant extra space."),
  design_cache_lru = list(sig = "Fixed capacity, O(1) get and put, evict the least recently or least frequently used.", pr = "LRU Cache; LFU Cache", t = "O(1) per op", s = "O(capacity)", q = "Design a cache with get and put in constant time that evicts the least recently used item."),
  design_feed_ratelimiter = list(sig = "Streams, timelines, counters per window, fairness across users.", pr = "Design Twitter; Find Median from Data Stream; Design Hit Counter; Logger Rate Limiter", t = "per design", s = "per design", q = "Design a rate limiter that allows at most 100 requests per user per minute."))

algo_handbook_ui <- function(id) {
  ns <- NS(id)
  card <- function(pid) {
    it <- TD_ALGO_ITEMS[[pid]]; info <- ALGO_INFO[[pid]]
    box(title = it[1], status = "primary", solidHeader = TRUE, width = 6, class = "hb-card",
        p(it[2]),
        p(tags$strong("Signals in the question: "), info$sig),
        p(tags$strong("Typical LeetCode problems: "), info$pr),
        p(tags$strong("Time / space: "), info$t, " / ", info$s),
        div(class = "example-box", h4("Try asking for it like this:"), p(tags$em(info$q))),
        actionButton(ns(paste0("use_", pid)), "Use in the selector", icon = icon("magic"), class = "btn-primary btn-sm"))
  }
  tagList(
    fluidRow(box(title = "Algorithm patterns for the Meta software-design interview", status = "primary", solidHeader = TRUE, width = 12,
      p("Most interview questions are variations of a small number of ", tags$strong("patterns"), ". This handbook lists the 23 pattern groups of the LeetCode topic list, with the signals that point to each, the classic problems, the usual complexity and a sample question. ",
        "Open the next tab, paste your question, and the Editing Tool recommends the right pattern and draws it as a network of boxes with a worked example, a step-by-step trace, trade-offs and references; you can then save it to BigQuery and download it as HTML, PDF, PPTX or an image."),
      fluidRow(
        column(6, h4("A 5-step routine for the interview"), tags$ol(
          tags$li(tags$strong("Clarify"), ": restate the problem, ask about input size, duplicates, empty input and ordering."),
          tags$li(tags$strong("Match the pattern"), ": look for the signals below; say the brute force first, then the improvement."),
          tags$li(tags$strong("Design"), ": name the data structures and the loop invariant before writing code."),
          tags$li(tags$strong("Trace"), ": walk a small example, including an edge case, out loud."),
          tags$li(tags$strong("Analyse"), ": state time and space, and what you would change under tighter limits."))),
        column(6, h4("How the tabs work together"), tags$ol(
          tags$li("Pick a pattern here to preselect it, or go straight to the selector."),
          tags$li("Select, Generate and Visualise: paste the question, press Recommend and Design."),
          tags$li("Hover and click the boxes; press Play to run the trace."),
          tags$li("Save to BigQuery (Technical Designs table) and download the diagram."))))
    )),
    do.call(tagList, lapply(ALGO_CATEGORIES, function(cat) tagList(
      div(class = "hb-phase", h4(cat$label), p(cat$text)),
      do.call(fluidRow, lapply(cat$ids, card))))),
    fluidRow(box(title = "Sources and notes", status = "warning", solidHeader = TRUE, width = 12, collapsible = TRUE, collapsed = TRUE,
      p("The grouping follows the public LeetCode topic list and the commonly taught NeetCode-style roadmap; problem names are the public LeetCode titles. Complexities are typical values for the standard solution. The text is written in my own words; no problem statements are copied.")))
  )
}

algo_handbook_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    lapply(names(ALGO_INFO), function(pid) {
      observeEvent(input[[paste0("use_", pid)]], {
        api_manager$set_pending_techdesign_selection(list(group = "algorithms", design_type = pid, context = ALGO_INFO[[pid]]$q))
        td_nav(session, "techdesign_algorithm")
        showNotification(sprintf("%s selected: its sample question is in the selector's question box (edit it to your own).", TD_ALGO_ITEMS[[pid]][1]), type = "message", duration = 6)
      })
    })
    session$onSessionEnded(function() {})
  })
}
