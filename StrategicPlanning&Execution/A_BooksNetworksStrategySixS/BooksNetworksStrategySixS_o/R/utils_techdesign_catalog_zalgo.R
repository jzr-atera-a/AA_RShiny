# R/utils_techdesign_catalog_zalgo.R
# ============================================================
# TECHNICAL DESIGNS - Algorithms group (LeetCode topic groups, Meta interview)
# Sorts after utils_techdesign_catalog.R (Shiny autoload is alphabetical).
# Same table, same parser, same renderer: an algorithm is drawn as a swimlane
# network of boxes (input -> data structures -> steps -> worked example -> output)
# with hover highlighting, click-for-details and a step-by-step trace player.
# ============================================================

TD_ALGO_COMMON <- paste0(
  "\nDESIGN = an ALGORITHM / data-structure design for a coding or software-design interview question, drawn as a network of boxes.",
  "\nSuggested lanes, left to right: \"Input\" (the problem input, actor or external); \"Data Structures\" (the structures the solution needs: hash map, stack, heap, queue, array, tree ... kind store, queue or cache); ",
  "\"Algorithm Steps\" (each key step of the algorithm as a process box, in order); \"Worked Example\" (a SMALL concrete example network, 5-7 nodes with real values such as node 0, node 1 ... or array cells, kind process, and the edges showing how the algorithm walks over it); ",
  "\"Result\" (the output and the complexity box, kind monitor, label Time and Space with the Big-O in the description).",
  "\nConnections: data = values passed; control = decision or branch; event = push / pop / visit / enqueue; feedback = the loop that goes back to an earlier step.",
  "\nFlow steps: a numbered TRACE of the algorithm on the worked example, one step per iteration, each naming the boxes involved.",
  "\nTrade-offs: time complexity, space complexity, edge cases, common pitfalls, and the brute-force alternative (pro / con / risk / cost / scaling).",
  "\nIn the summary state the pattern, the key insight and the Big-O. In when_to_use give the signals in a problem statement that point to this pattern.\n")

TD_ALGO_ITEMS <- list(
  array_hashing = c("Arrays and Hashing", "Hash map / hash set lookups to trade space for time: duplicates, two-sum, frequency counts, grouping anagrams, prefix sums."),
  two_pointers = c("Two Pointers", "Two indices moving through a sorted array or string: pair sums, palindromes, container with most water, partitioning in place."),
  sliding_window = c("Sliding Window", "A window that grows and shrinks over an array or string: longest substring without repeats, minimum window, max sum of size k."),
  stack_monotonic = c("Stack and Monotonic Stack", "A stack for matching, undo and next-greater problems: valid parentheses, daily temperatures, largest rectangle in histogram."),
  binary_search = c("Binary Search", "Halve the search space on a sorted or monotonic condition: search in rotated array, minimise the maximum, koko eating bananas."),
  linked_list = c("Linked List", "Pointer manipulation: reverse list, fast and slow pointers for cycles, merge lists, LRU cache with a doubly linked list."),
  trees_dfs_bfs = c("Binary Trees (DFS / BFS)", "Recursive depth-first traversals and level-order breadth-first traversal: depth, LCA, serialise, validate BST, right-side view."),
  tries = c("Tries (Prefix Tree)", "Prefix tree for word search, autocomplete and dictionary problems: implement trie, word search II, replace words."),
  heap_priority_queue = c("Heap / Priority Queue", "Top-K, k-way merge and streaming median with min-heaps and max-heaps: kth largest, merge k sorted lists, task scheduler."),
  backtracking = c("Backtracking", "Build candidates, recurse, undo the choice: subsets, permutations, combination sum, N-queens, word search."),
  graph_traversal = c("Graphs: BFS / DFS / Connected Components", "Grid and graph traversal: number of islands, clone graph, shortest path in an unweighted graph, rotting oranges."),
  topological_sort = c("Topological Sort (Course Schedule)", "Order tasks with dependencies in a directed acyclic graph using Kahn's algorithm or DFS: course schedule, alien dictionary."),
  union_find = c("Union-Find (Disjoint Set)", "Merge and query connected groups with path compression: redundant connection, accounts merge, number of provinces."),
  dijkstra_shortest_path = c("Dijkstra / Shortest Path", "Weighted shortest paths with a priority queue: network delay time, cheapest flights within k stops, path with minimum effort."),
  minimum_spanning_tree = c("Minimum Spanning Tree (Kruskal / Prim)", "Connect all nodes at minimum total weight: min cost to connect points, optimise water distribution."),
  dp_1d = c("Dynamic Programming 1-D", "A table over one index: climbing stairs, house robber, coin change, longest increasing subsequence, word break."),
  dp_2d = c("Dynamic Programming 2-D", "A grid or two-sequence table: unique paths, longest common subsequence, edit distance, knapsack, interleaving string."),
  greedy = c("Greedy", "Make the locally best choice and prove it is globally safe: jump game, gas station, partition labels, merge triplets."),
  intervals = c("Intervals", "Sort and sweep ranges: merge intervals, insert interval, meeting rooms II, minimum arrows to burst balloons."),
  math_geometry = c("Math and Geometry", "Matrix rotation, spiral order, number theory and cycle detection: rotate image, happy number, pow(x, n), multiply strings."),
  bit_manipulation = c("Bit Manipulation", "XOR tricks, masks and shifts: single number, counting bits, reverse bits, missing number, sum of two integers."),
  design_cache_lru = c("Design: LRU / LFU Cache", "Hash map plus doubly linked list for O(1) get and put with eviction; LFU adds frequency buckets."),
  design_feed_ratelimiter = c("Design: News Feed, Rate Limiter, Top-K Stream", "Data-structure design questions: merge k timelines with a heap, token bucket and sliding-window rate limiters, heavy hitters.")
)

TD_CATALOG$algorithms <- lapply(TD_ALGO_ITEMS, function(x) list(label = x[1], guidance = paste0(TD_ALGO_COMMON, "PATTERN: ", x[1], ". ", x[2], "\n")))

# The list given to Claude when it must CHOOSE the pattern
td_algo_listing <- function() paste(sprintf("- %s | %s | %s", names(TD_ALGO_ITEMS), vapply(TD_ALGO_ITEMS, `[`, "", 1), vapply(TD_ALGO_ITEMS, `[`, "", 2)), collapse = "\n")

# One call: Claude picks the best pattern for the question AND returns the full design in the standard text format.
generate_algo_prompt <- function(question, language = "", detail = 2) {
  base <- generate_techdesign_prompt(
    group = "algorithms", design_type = "<snake_case id of the pattern you chose, taken from the list above when it fits>",
    design_label = "the algorithm you recommend for the question below", detail = detail, custom = TRUE,
    guidance = paste0(TD_ALGO_COMMON,
      "\nSTEP 1 - CHOOSE: from the LeetCode topic groups below pick the ONE pattern that best solves the question (use the id given; if the best answer is a combination, use the main pattern as design_type and name the others in tags). ",
      "If none fits, invent a short snake_case id.\n", td_algo_listing(), "\n",
      "STEP 2 - DESIGN: document the chosen algorithm as the network of boxes described above. ",
      "In the title name the question in a few words. In the summary begin with 'Recommended: <pattern name>.' then give the key insight, the Big-O time and space, and why the other obvious approaches are worse. ",
      "Tags: the LeetCode topic group names involved, and 2-3 similar LeetCode problem names. ",
      if (nzchar(trimws(language))) paste0("Where code-level detail helps (methods, attributes), use ", trimws(language), " naming.\n") else "\n"),
    context = paste0("INTERVIEW QUESTION (Meta software-design / algorithm interview): ", trimws(question)))
  base
}
