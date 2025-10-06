
library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(shinycssloaders)
library(shinyWidgets)
library(visNetwork)
library(dplyr)
library(ggplot2)
library(wordcloud2)
library(htmlwidgets)

# Define colour palette for consistent styling
primary_colour <- "#667eea"
secondary_colour <- "#764ba2"
accent_colour <- "#f39c12"
success_colour <- "#27AE60"
warning_colour <- "#F39C12"
info_colour <- "#4f46e5"

# Custom CSS styling - maintaining original configuration
# Custom CSS styling - maintaining original configuration
custom_css <- "
  .skin-blue .main-header .navbar { 
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; 
    border: none !important; 
    box-shadow: 0 2px 10px rgba(0,0,0,0.1) !important;
  }
  .skin-blue .main-header .logo { 
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
    color: white !important; 
    font-weight: 700 !important; 
    font-size: 18px !important;
    border-right: none !important;
  }
  .skin-blue .main-header .logo:hover {
    background: linear-gradient(135deg, #764ba2 0%, #667eea 100%) !important;
  }
  .skin-blue .main-sidebar { 
    background: linear-gradient(180deg, #2c3e50 0%, #34495e 100%) !important; 
  }
  .skin-blue .sidebar-menu > li > a { 
    color: #ecf0f1 !important; 
    border-left: 3px solid transparent !important; 
    transition: all 0.3s ease !important;
    font-weight: 500 !important;
  }
  .skin-blue .sidebar-menu > li.active > a,
  .skin-blue .sidebar-menu > li.menu-open > a { 
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; 
    border-left: 3px solid #f39c12 !important; 
    color: white !important; 
    box-shadow: inset 0 0 10px rgba(0,0,0,0.2) !important;
  }
  .skin-blue .sidebar-menu > li > a:hover { 
    background-colour: #3e5771 !important; 
    color: white !important; 
  }
  .content-wrapper,
  .right-side { 
    background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%) !important; 
  }
  .box { 
    border: none !important; 
    border-radius: 12px !important; 
    box-shadow: 0 4px 20px rgba(0,0,0,0.08) !important;
    background: white !important;
    margin-bottom: 20px !important;
  }
  .box-header { 
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; 
    color: white !important;
    border-radius: 12px 12px 0 0 !important; 
    font-weight: 600 !important;
    border-bottom: none !important;
  }
  .box.box-solid.box-primary > .box-header,
  .box.box-solid.box-info > .box-header,
  .box.box-solid.box-success > .box-header,
  .box.box-solid.box-warning > .box-header {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
    color: white !important;
  }
  .references {
    background: linear-gradient(135deg, #f8f9ff 0%, #ffffff 100%) !important;
    border: 1px solid #e3e8ff !important;
    border-left: 5px solid #4f46e5 !important;
    padding: 20px !important;
    margin-top: 25px !important;
    border-radius: 12px !important;
    box-shadow: 0 2px 10px rgba(79, 70, 229, 0.1) !important;
  }
  .references h5 {
    color: #4f46e5 !important;
    font-weight: 600 !important;
    margin-bottom: 15px !important;
    border-bottom: 2px solid #4f46e5 !important;
    padding-bottom: 5px !important;
  }
  .reference-item {
    margin-bottom: 12px !important;
    line-height: 1.5 !important;
    padding-left: 10px !important;
    border-left: 3px solid #e3e8ff !important;
  }
  .small-box { 
    border-radius: 12px !important; 
    box-shadow: 0 4px 15px rgba(0,0,0,0.1) !important;
  }
  .bg-blue,
  .bg-green,
  .bg-yellow,
  .bg-red {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
  }
  .small-box .icon { 
    opacity: 0.8 !important; 
  }
  .academic-content {
    background: white;
    padding: 20px;
    border-radius: 8px;
    line-height: 1.6;
    font-size: 14px;
    color: #2c3e50;
    margin-bottom: 15px;
  }
  .academic-content h5 {
    color: #4f46e5;
    font-weight: 600;
    margin-bottom: 10px;
  }
  .concept-highlight {
    background: linear-gradient(135deg, #f8f9ff 0%, #ffffff 100%);
    border-left: 4px solid #667eea;
    padding: 15px;
    margin: 10px 0;
    border-radius: 5px;
  }
  .code-example {
    background: #2d2d2d;
    color: #f8f8f2;
    padding: 15px;
    border-radius: 8px;
    font-family: Courier New, monospace;
    font-size: 13px;
    overflow-x: auto;
    margin: 10px 0;
    border-left: 4px solid #667eea;
  }
  .complexity-box {
    background: linear-gradient(135deg, #fff5e6 0%, #ffffff 100%);
    border-left: 4px solid #f39c12;
    padding: 12px;
    margin: 10px 0;
    border-radius: 5px;
    font-weight: 500;
  }
  .difficulty-easy {
    background: #d4edda;
    color: #155724;
    padding: 5px 10px;
    border-radius: 5px;
    font-weight: 600;
    display: inline-block;
  }
  .difficulty-medium {
    background: #fff3cd;
    color: #856404;
    padding: 5px 10px;
    border-radius: 5px;
    font-weight: 600;
    display: inline-block;
  }
  .difficulty-hard {
    background: #f8d7da;
    color: #721c24;
    padding: 5px 10px;
    border-radius: 5px;
    font-weight: 600;
    display: inline-block;
  }
  .btn-primary { 
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; 
    border: none !important; 
    border-radius: 8px !important;
    font-weight: 600 !important;
  }
  .btn-success {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; 
    border: none !important; 
    border-radius: 8px !important;
    font-weight: 600 !important;
  }
  .form-control {
    border-radius: 8px !important;
    border: 1px solid #e3e8ff !important;
  }
  h4 { 
    color: #2c3e50 !important; 
    font-weight: 600 !important; 
  }
  .problem-list {
    background: #f8f9fa;
    padding: 15px;
    border-radius: 8px;
    margin: 10px 0;
  }
  .problem-item {
    padding: 8px;
    margin: 5px 0;
    background: white;
    border-radius: 5px;
    border-left: 3px solid #667eea;
  }
"

# UI Definition
ui <- dashboardPage(
  dashboardHeader(title = "FAANG Interview Prep Academy"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Arrays & Strings", tabName = "arrays", icon = icon("list")),
      menuItem("Linked Lists", tabName = "linkedlists", icon = icon("link")),
      menuItem("Stacks & Queues", tabName = "stacks", icon = icon("layer-group")),
      menuItem("Trees & Binary Search Trees", tabName = "trees", icon = icon("tree")),
      menuItem("Graphs & BFS/DFS", tabName = "graphs", icon = icon("project-diagram")),
      menuItem("Dynamic Programming", tabName = "dp", icon = icon("chart-line")),
      menuItem("Sorting & Searching", tabName = "sorting", icon = icon("sort")),
      menuItem("Hash Tables & Sets", tabName = "hashing", icon = icon("hashtag")),
      menuItem("Heaps & Priority Queues", tabName = "heaps", icon = icon("mountain")),
      menuItem("Recursion & Backtracking", tabName = "recursion", icon = icon("redo")),
      menuItem("Greedy Algorithms", tabName = "greedy", icon = icon("coins")),
      menuItem("Bit Manipulation", tabName = "bits", icon = icon("microchip")),
      menuItem("System Design Basics", tabName = "systemdesign", icon = icon("server"))
    )
  ),
  dashboardBody(
    tags$head(tags$style(HTML(custom_css))),
    
    tabItems(
      # Arrays & Strings Tab
      tabItem(tabName = "arrays",
        fluidRow(
          box(width = 12, status = "primary", solidHeader = TRUE,
              title = "Arrays & Strings - Core Data Structures",
              div(class = "academic-content",
                h5("Fundamental Concepts"),
                p("Arrays and strings are the most fundamental data structures in computer science and form the basis of many Google and Meta interview questions. Mastery requires understanding contiguous memory allocation, indexing, iteration patterns, and string manipulation techniques."),
                
                div(class = "concept-highlight",
                  h5("Key Topics:"),
                  tags$ul(
                    tags$li("Two-pointer technique and sliding window"),
                    tags$li("Array manipulation and in-place algorithms"),
                    tags$li("String processing and pattern matching"),
                    tags$li("Prefix sums and difference arrays"),
                    tags$li("Subarray and substring problems")
                  )
                ),
                
                h5("Essential Algorithms"),
                
                div(class = "complexity-box",
                  strong("Time Complexity: "), "Access O(1), Search O(n), Insert/Delete O(n)"
                ),
                
                div(class = "code-example",
                  "# Two Pointer Technique - Remove Duplicates from Sorted Array",
                  tags$br(),
                  "def removeDuplicates(nums):",
                  tags$br(),
                  "    if not nums: return 0",
                  tags$br(),
                  "    i = 0",
                  tags$br(),
                  "    for j in range(1, len(nums)):",
                  tags$br(),
                  "        if nums[j] != nums[i]:",
                  tags$br(),
                  "            i += 1",
                  tags$br(),
                  "            nums[i] = nums[j]",
                  tags$br(),
                  "    return i + 1"
                ),
                
                h5("Common Interview Problems"),
                div(class = "problem-list",
                  div(class = "problem-item",
                    span(class = "difficulty-easy", "EASY"), " - Two Sum (LeetCode #1)"
                  ),
                  div(class = "problem-item",
                    span(class = "difficulty-medium", "MEDIUM"), " - Longest Substring Without Repeating Characters (LeetCode #3)"
                  ),
                  div(class = "problem-item",
                    span(class = "difficulty-medium", "MEDIUM"), " - Container With Most Water (LeetCode #11)"
                  ),
                  div(class = "problem-item",
                    span(class = "difficulty-hard", "HARD"), " - Trapping Rain Water (LeetCode #42)"
                  ),
                  div(class = "problem-item",
                    span(class = "difficulty-medium", "MEDIUM"), " - Product of Array Except Self (LeetCode #238)"
                  )
                ),
                
                h5("Interview Tips"),
                div(class = "concept-highlight",
                  tags$ul(
                    tags$li("Always clarify if the array is sorted"),
                    tags$li("Ask about duplicates and edge cases (empty, single element)"),
                    tags$li("Consider space-time tradeoffs"),
                    tags$li("Think about in-place vs. auxiliary space solutions"),
                    tags$li("Master the two-pointer and sliding window patterns")
                  )
                )
              ),
              
              div(class = "references",
                h5("References"),
                div(class = "reference-item", "Aziz, A., Lee, T. H., & Prakash, A. (2018). Elements of programming interviews in Python: The insiders' guide. CreateSpace Independent Publishing Platform."),
                div(class = "reference-item", "Cormen, T. H., Leiserson, C. E., Rivest, R. L., & Stein, C. (2009). Introduction to algorithms (3rd ed.). MIT Press."),
                div(class = "reference-item", "Laakmann McDowell, G. (2015). Cracking the coding interview (6th ed.). CareerCup."),
                div(class = "reference-item", "LeetCode. (2024). Array problems. Retrieved from https://leetcode.com/problemset/algorithms/")
              )
          )
        )
      ),
      
      # Linked Lists Tab
      tabItem(tabName = "linkedlists",
        fluidRow(
          box(width = 12, status = "primary", solidHeader = TRUE,
              title = "Linked Lists - Dynamic Memory Structures",
              div(class = "academic-content",
                h5("Understanding Linked Lists"),
                p("Linked lists are fundamental dynamic data structures frequently tested in FAANG interviews. They consist of nodes containing data and pointers, enabling efficient insertions and deletions. Mastery requires understanding pointer manipulation, cycle detection, and various list manipulation techniques."),
                
                div(class = "concept-highlight",
                  h5("Core Concepts:"),
                  tags$ul(
                    tags$li("Singly vs. doubly linked lists"),
                    tags$li("Fast and slow pointer technique (Floyd's algorithm)"),
                    tags$li("Reverse linked list (iterative and recursive)"),
                    tags$li("Merge sorted lists"),
                    tags$li("Cycle detection and removal")
                  )
                ),
                
                h5("Critical Algorithms"),
                
                div(class = "complexity-box",
                  strong("Time Complexity: "), "Access O(n), Insert/Delete O(1) at pointer, Search O(n)"
                ),
                
                div(class = "code-example",
                  "# Reverse Linked List - Iterative Approach",
                  tags$br(),
                  "def reverseList(head):",
                  tags$br(),
                  "    prev = None",
                  tags$br(),
                  "    current = head",
                  tags$br(),
                  "    while current:",
                  tags$br(),
                  "        next_temp = current.next",
                  tags$br(),
                  "        current.next = prev",
                  tags$br(),
                  "        prev = current",
                  tags$br(),
                  "        current = next_temp",
                  tags$br(),
                  "    return prev",
                  tags$br(),
                  tags$br(),
                  "# Detect Cycle - Floyd's Tortoise and Hare",
                  tags$br(),
                  "def hasCycle(head):",
                  tags$br(),
                  "    slow = fast = head",
                  tags$br(),
                  "    while fast and fast.next:",
                  tags$br(),
                  "        slow = slow.next",
                  tags$br(),
                  "        fast = fast.next.next",
                  tags$br(),
                  "        if slow == fast: return True",
                  tags$br(),
                  "    return False"
                ),
                
                h5("Common Interview Problems"),
                div(class = "problem-list",
                  div(class = "problem-item",
                    span(class = "difficulty-easy", "EASY"), " - Reverse Linked List (LeetCode #206)"
                    ),
                    div(class = "problem-item",
                        span(class = "difficulty-easy", "EASY"), " - Merge Two Sorted Lists (LeetCode #21)"
                    ),
                    div(class = "problem-item",
                        span(class = "difficulty-medium", "MEDIUM"), " - Add Two Numbers (LeetCode #2)"
                    ),
                    div(class = "problem-item",
                        span(class = "difficulty-medium", "MEDIUM"), " - Remove Nth Node From End (LeetCode #19)"
                    ),
                    div(class = "problem-item",
                        span(class = "difficulty-hard", "HARD"), " - Merge k Sorted Lists (LeetCode #23)"
                    )
                    ),

h5("Interview Strategy"),
div(class = "concept-highlight",
    tags$ul(
      tags$li("Always handle null/empty list cases"),
      tags$li("Draw diagrams to visualize pointer movements"),
      tags$li("Consider using dummy head node to simplify edge cases"),
      tags$li("Think about whether you need to maintain previous pointer"),
      tags$li("Practice both iterative and recursive approaches")
    )
)
),

div(class = "references",
    h5("References"),
    div(class = "reference-item", "Skiena, S. S. (2020). The algorithm design manual (3rd ed.). Springer."),
    div(class = "reference-item", "Laakmann McDowell, G. (2015). Cracking the coding interview (6th ed.). CareerCup."),
    div(class = "reference-item", "Knuth, D. E. (1997). The art of computer programming, Vol. 1: Fundamental algorithms (3rd ed.). Addison-Wesley."),
    div(class = "reference-item", "Sedgewick, R., & Wayne, K. (2011). Algorithms (4th ed.). Addison-Wesley Professional.")
)
)
)
),

# Stacks & Queues Tab
tabItem(tabName = "stacks",
        fluidRow(
          box(width = 12, status = "primary", solidHeader = TRUE,
              title = "Stacks & Queues - LIFO and FIFO Structures",
              div(class = "academic-content",
                  h5("Stack and Queue Fundamentals"),
                  p("Stacks (Last-In-First-Out) and Queues (First-In-First-Out) are essential abstract data types frequently appearing in Google and Meta interviews. They're fundamental to parsing, expression evaluation, BFS/DFS implementations, and many system design scenarios."),
                  
                  div(class = "concept-highlight",
                      h5("Key Applications:"),
                      tags$ul(
                        tags$li("Expression parsing and evaluation"),
                        tags$li("Balanced parentheses checking"),
                        tags$li("Next greater/smaller element problems"),
                        tags$li("Level-order tree traversal (BFS)"),
                        tags$li("Monotonic stack/queue patterns")
                      )
                  ),
                  
                  h5("Core Operations"),
                  
                  div(class = "complexity-box",
                      strong("Time Complexity: "), "Push/Pop/Peek O(1) for both structures"
                  ),
                  
                  div(class = "code-example",
                      "# Valid Parentheses using Stack",
                      tags$br(),
                      "def isValid(s):",
                      tags$br(),
                      "    stack = []",
                      tags$br(),
                      "    mapping = {')': '(', '}': '{', ']': '['}",
                      tags$br(),
                      "    for char in s:",
                      tags$br(),
                      "        if char in mapping:",
                      tags$br(),
                      "            top = stack.pop() if stack else '#'",
                      tags$br(),
                      "            if mapping[char] != top: return False",
                      tags$br(),
                      "        else:",
                      tags$br(),
                      "            stack.append(char)",
                      tags$br(),
                      "    return not stack",
                      tags$br(),
                      tags$br(),
                      "# Sliding Window Maximum using Deque",
                      tags$br(),
                      "from collections import deque",
                      tags$br(),
                      "def maxSlidingWindow(nums, k):",
                      tags$br(),
                      "    dq = deque()",
                      tags$br(),
                      "    result = []",
                      tags$br(),
                      "    for i, num in enumerate(nums):",
                      tags$br(),
                      "        while dq and nums[dq[-1]] < num:",
                      tags$br(),
                      "            dq.pop()",
                      tags$br(),
                      "        dq.append(i)",
                      tags$br(),
                      "        if dq[0] == i - k: dq.popleft()",
                      tags$br(),
                      "        if i >= k - 1: result.append(nums[dq[0]])",
                      tags$br(),
                      "    return result"
                  ),
                  
                  h5("Common Interview Problems"),
                  div(class = "problem-list",
                      div(class = "problem-item",
                          span(class = "difficulty-easy", "EASY"), " - Valid Parentheses (LeetCode #20)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-medium", "MEDIUM"), " - Min Stack (LeetCode #155)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-medium", "MEDIUM"), " - Daily Temperatures (LeetCode #739)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-hard", "HARD"), " - Largest Rectangle in Histogram (LeetCode #84)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-hard", "HARD"), " - Sliding Window Maximum (LeetCode #239)"
                      )
                  ),
                  
                  h5("Pro Tips"),
                  div(class = "concept-highlight",
                      tags$ul(
                        tags$li("Monotonic stacks are powerful for next greater/smaller problems"),
                        tags$li("Deques (double-ended queues) offer more flexibility"),
                        tags$li("Consider implementing min/max stack with O(1) operations"),
                        tags$li("Queue implementations: array with circular buffer or linked list"),
                        tags$li("Think about whether you need to track indices vs. values")
                      )
                  )
              ),
              
              div(class = "references",
                  h5("References"),
                  div(class = "reference-item", "Cormen, T. H., Leiserson, C. E., Rivest, R. L., & Stein, C. (2009). Introduction to algorithms (3rd ed.). MIT Press."),
                  div(class = "reference-item", "Sedgewick, R., & Wayne, K. (2011). Algorithms (4th ed.). Addison-Wesley Professional."),
                  div(class = "reference-item", "Weiss, M. A. (2011). Data structures and algorithm analysis in Java (3rd ed.). Pearson."),
                  div(class = "reference-item", "Aziz, A., Lee, T. H., & Prakash, A. (2018). Elements of programming interviews in Python. CreateSpace Independent Publishing Platform.")
              )
          )
        )
),

# Trees & BST Tab
tabItem(tabName = "trees",
        fluidRow(
          box(width = 12, status = "primary", solidHeader = TRUE,
              title = "Trees & Binary Search Trees",
              div(class = "academic-content",
                  h5("Tree Structures and Operations"),
                  p("Trees, especially Binary Search Trees (BST), are among the most frequently tested topics in FAANG interviews. They represent hierarchical relationships and enable efficient searching, insertion, and deletion operations when balanced."),
                  
                  div(class = "concept-highlight",
                      h5("Essential Concepts:"),
                      tags$ul(
                        tags$li("Tree traversals: inorder, preorder, postorder, level-order"),
                        tags$li("Binary Search Tree properties and operations"),
                        tags$li("Tree height, depth, and balancing"),
                        tags$li("Lowest Common Ancestor (LCA)"),
                        tags$li("Path sum and subtree problems")
                      )
                  ),
                  
                  h5("Critical Algorithms"),
                  
                  div(class = "complexity-box",
                      strong("BST Operations: "), "Search/Insert/Delete O(log n) average, O(n) worst case"
                  ),
                  
                  div(class = "code-example",
                      "# Inorder Traversal (Iterative)",
                      tags$br(),
                      "def inorderTraversal(root):",
                      tags$br(),
                      "    result, stack = [], []",
                      tags$br(),
                      "    current = root",
                      tags$br(),
                      "    while current or stack:",
                      tags$br(),
                      "        while current:",
                      tags$br(),
                      "            stack.append(current)",
                      tags$br(),
                      "            current = current.left",
                      tags$br(),
                      "        current = stack.pop()",
                      tags$br(),
                      "        result.append(current.val)",
                      tags$br(),
                      "        current = current.right",
                      tags$br(),
                      "    return result",
                      tags$br(),
                      tags$br(),
                      "# Validate BST",
                      tags$br(),
                      "def isValidBST(root):",
                      tags$br(),
                      "    def validate(node, low=float('-inf'), high=float('inf')):",
                      tags$br(),
                      "        if not node: return True",
                      tags$br(),
                      "        if node.val <= low or node.val >= high:",
                      tags$br(),
                      "            return False",
                      tags$br(),
                      "        return (validate(node.left, low, node.val) and",
                      tags$br(),
                      "                validate(node.right, node.val, high))",
                      tags$br(),
                      "    return validate(root)"
                  ),
                  
                  h5("Common Interview Problems"),
                  div(class = "problem-list",
                      div(class = "problem-item",
                          span(class = "difficulty-easy", "EASY"), " - Maximum Depth of Binary Tree (LeetCode #104)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-medium", "MEDIUM"), " - Validate Binary Search Tree (LeetCode #98)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-medium", "MEDIUM"), " - Lowest Common Ancestor of BST (LeetCode #235)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-medium", "MEDIUM"), " - Binary Tree Level Order Traversal (LeetCode #102)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-hard", "HARD"), " - Serialize and Deserialize Binary Tree (LeetCode #297)"
                      )
                  ),
                  
                  h5("Mastery Tips"),
                  div(class = "concept-highlight",
                      tags$ul(
                        tags$li("Master both recursive and iterative traversal approaches"),
                        tags$li("Understand the relationship between inorder traversal and sorted order in BST"),
                        tags$li("Practice identifying when to use DFS vs BFS"),
                        tags$li("Learn balanced tree variants: AVL, Red-Black, B-trees"),
                        tags$li("Always consider null/empty tree edge cases")
                      )
                  )
              ),
              
              div(class = "references",
                  h5("References"),
                  div(class = "reference-item", "Cormen, T. H., Leiserson, C. E., Rivest, R. L., & Stein, C. (2009). Introduction to algorithms (3rd ed.). MIT Press."),
                  div(class = "reference-item", "Knuth, D. E. (1998). The art of computer programming, Vol. 3: Sorting and searching (2nd ed.). Addison-Wesley."),
                  div(class = "reference-item", "Skiena, S. S. (2020). The algorithm design manual (3rd ed.). Springer."),
                  div(class = "reference-item", "Laakmann McDowell, G. (2015). Cracking the coding interview (6th ed.). CareerCup.")
              )
          )
        )
),

# Graphs Tab
tabItem(tabName = "graphs",
        fluidRow(
          box(width = 12, status = "primary", solidHeader = TRUE,
              title = "Graphs - BFS & DFS Algorithms",
              div(class = "academic-content",
                  h5("Graph Theory and Traversal"),
                  p("Graph problems are extremely common in FAANG interviews, testing both algorithmic thinking and problem-solving skills. Graphs model relationships and networks, making them applicable to social networks, maps, dependencies, and countless real-world scenarios."),
                  
                  div(class = "concept-highlight",
                      h5("Core Topics:"),
                      tags$ul(
                        tags$li("Graph representations: adjacency list vs. matrix"),
                        tags$li("Breadth-First Search (BFS) for shortest paths"),
                        tags$li("Depth-First Search (DFS) for connectivity and cycles"),
                        tags$li("Topological sorting for DAGs"),
                        tags$li("Dijkstra's algorithm for weighted shortest paths"),
                        tags$li("Union-Find for connected components")
                      )
                  ),
                  
                  h5("Essential Graph Algorithms"),
                  
                  div(class = "complexity-box",
                      strong("Time Complexity: "), "BFS/DFS O(V + E), Dijkstra O((V + E) log V)"
                  ),
                  
                  div(class = "code-example",
                      "# BFS - Shortest Path in Unweighted Graph",
                      tags$br(),
                      "from collections import deque",
                      tags$br(),
                      "def bfs(graph, start):",
                      tags$br(),
                      "    visited = set([start])",
                      tags$br(),
                      "    queue = deque([start])",
                      tags$br(),
                      "    while queue:",
                      tags$br(),
                      "        vertex = queue.popleft()",
                      tags$br(),
                      "        for neighbor in graph[vertex]:",
                      tags$br(),
                      "            if neighbor not in visited:",
                      tags$br(),
                      "                visited.add(neighbor)",
                      tags$br(),
                      "                queue.append(neighbor)",
                      tags$br(),
                      "    return visited",
                      tags$br(),
                      tags$br(),
                      "# DFS - Cycle Detection",
                      tags$br(),
                      "def hasCycle(graph):",
                      tags$br(),
                      "    visited = set()",
                      tags$br(),
                      "    rec_stack = set()",
                      tags$br(),
                      "    def dfs(node):",
                      tags$br(),
                      "        visited.add(node)",
                      tags$br(),
                      "        rec_stack.add(node)",
                      tags$br(),
                      "        for neighbor in graph[node]:",
                      tags$br(),
                      "            if neighbor not in visited:",
                      tags$br(),
                      "                if dfs(neighbor): return True",
                      tags$br(),
                      "            elif neighbor in rec_stack:",
                      tags$br(),
                      "                return True",
                      tags$br(),
                      "        rec_stack.remove(node)",
                      tags$br(),
                      "        return False",
                      tags$br(),
                      "    return any(dfs(node) for node in graph if node not in visited)"
                  ),
                  
                  h5("Common Interview Problems"),
                  div(class = "problem-list",
                      div(class = "problem-item",
                          span(class = "difficulty-medium", "MEDIUM"), " - Number of Islands (LeetCode #200)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-medium", "MEDIUM"), " - Clone Graph (LeetCode #133)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-medium", "MEDIUM"), " - Course Schedule (LeetCode #207)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-medium", "MEDIUM"), " - Pacific Atlantic Water Flow (LeetCode #417)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-hard", "HARD"), " - Word Ladder (LeetCode #127)"
                      )
                  ),
                  
                  h5("Interview Strategy"),
                  div(class = "concept-highlight",
                      tags$ul(
                        tags$li("Choose BFS for shortest path, DFS for full exploration"),
                        tags$li("Always ask about graph properties: directed/undirected, weighted, cyclic"),
                        tags$li("Consider using visited set to avoid infinite loops"),
                        tags$li("Think about implicit vs explicit graph representation"),
                        tags$li("Master Union-Find for dynamic connectivity problems")
                      )
                  )
              ),
              
              div(class = "references",
                  h5("References"),
                  div(class = "reference-item", "Cormen, T. H., Leiserson, C. E., Rivest, R. L., & Stein, C. (2009). Introduction to algorithms (3rd ed.). MIT Press."),
                  div(class = "reference-item", "Skiena, S. S. (2020). The algorithm design manual (3rd ed.). Springer."),
                  div(class = "reference-item", "Sedgewick, R., & Wayne, K. (2011). Algorithms (4th ed.). Addison-Wesley Professional."),
                  div(class = "reference-item", "Kleinberg, J., & Tardos, E. (2005). Algorithm design. Pearson.")
              )
          )
        )
),

# Dynamic Programming Tab
tabItem(tabName = "dp",
        fluidRow(
          box(width = 12, status = "primary", solidHeader = TRUE,
              title = "Dynamic Programming - Optimization Problems",
              div(class = "academic-content",
                  h5("Dynamic Programming Mastery"),
                  p("Dynamic Programming (DP) is one of the most challenging and frequently tested topics in Google and Meta interviews. It requires identifying overlapping subproblems and optimal substructure, then building solutions bottom-up or with memoization."),
                  
                  div(class = "concept-highlight",
                      h5("Key Patterns:"),
                      tags$ul(
                        tags$li("1D DP: Fibonacci, climbing stairs, house robber"),
                        tags$li("2D DP: Longest common subsequence, edit distance"),
                        tags$li("Knapsack problems: 0/1, unbounded, fractional"),
                        tags$li("String DP: palindromes, subsequences, pattern matching"),
                        tags$li("Grid DP: unique paths, minimum path sum"),
                        tags$li("State machine DP: stock trading problems")
                      )
                  ),
                  
                  h5("DP Problem-Solving Framework"),
                  
                  div(class = "complexity-box",
                      strong("General Approach: "), "1) Define state, 2) Find recurrence, 3) Base cases, 4) Compute order"
                  ),
                  
                  div(class = "code-example",
                      "# Longest Increasing Subsequence - O(n log n)",
                      tags$br(),
                      "from bisect import bisect_left",
                      tags$br(),
                      "def lengthOfLIS(nums):",
                      tags$br(),
                      "    sub = []",
                      tags$br(),
                      "    for num in nums:",
                      tags$br(),
                      "        pos = bisect_left(sub, num)",
                      tags$br(),
                      "        if pos == len(sub):",
                      tags$br(),
                      "            sub.append(num)",
                      tags$br(),
                      "        else:",
                      tags$br(),
                      "            sub[pos] = num",
                      tags$br(),
                      "    return len(sub)",
                      tags$br(),
                      tags$br(),
                      "# Coin Change - Classic DP",
                      tags$br(),
                      "def coinChange(coins, amount):",
                      tags$br(),
                      "    dp = [float('inf')] * (amount + 1)",
                      tags$br(),
                      "    dp[0] = 0",
                      tags$br(),
                      "    for i in range(1, amount + 1):",
                      tags$br(),
                      "        for coin in coins:",
                      tags$br(),
                      "            if coin <= i:",
                      tags$br(),
                      "                dp[i] = min(dp[i], dp[i - coin] + 1)",
                      tags$br(),
                      "    return dp[amount] if dp[amount] != float('inf') else -1"
                  ),
                  
                  h5("Common Interview Problems"),
                  div(class = "problem-list",
                      div(class = "problem-item",
                          span(class = "difficulty-easy", "EASY"), " - Climbing Stairs (LeetCode #70)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-medium", "MEDIUM"), " - Coin Change (LeetCode #322)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-medium", "MEDIUM"), " - Longest Increasing Subsequence (LeetCode #300)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-medium", "MEDIUM"), " - Unique Paths (LeetCode #62)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-hard", "HARD"), " - Edit Distance (LeetCode #72)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-hard", "HARD"), " - Regular Expression Matching (LeetCode #10)"
                      )
                  ),
                  
                  h5("DP Mastery Tips"),
                  div(class = "concept-highlight",
                      tags$ul(
                        tags$li("Start by solving recursively with memoization (top-down)"),
                        tags$li("Convert to iterative DP (bottom-up) for better performance"),
                        tags$li("Identify if you can optimize space complexity"),
                        tags$li("Practice identifying DP patterns in problem statements"),
                        tags$li("Draw state transition diagrams to visualize solutions")
                      )
                  )
              ),
              
              div(class = "references",
                  h5("References"),
                  div(class = "reference-item", "Bellman, R. (1957). Dynamic programming. Princeton University Press."),
                  div(class = "reference-item", "Cormen, T. H., Leiserson, C. E., Rivest, R. L., & Stein, C. (2009). Introduction to algorithms (3rd ed.). MIT Press."),
                  div(class = "reference-item", "Kleinberg, J., & Tardos, E. (2005). Algorithm design. Pearson."),
                  div(class = "reference-item", "Skiena, S. S. (2020). The algorithm design manual (3rd ed.). Springer.")
              )
          )
        )
),

# Sorting & Searching Tab
tabItem(tabName = "sorting",
        fluidRow(
          box(width = 12, status = "primary", solidHeader = TRUE,
              title = "Sorting & Searching Algorithms",
              div(class = "academic-content",
                  h5("Fundamental Sorting and Searching"),
                  p("Sorting and searching are foundational algorithmic concepts. While built-in functions are typically used in practice, understanding their implementations and complexities is crucial for FAANG interviews, especially for optimization problems and understanding performance characteristics."),
                  
                  div(class = "concept-highlight",
                      h5("Essential Algorithms:"),
                      tags$ul(
                        tags$li("Comparison sorts: QuickSort, MergeSort, HeapSort"),
                        tags$li("Non-comparison sorts: Counting Sort, Radix Sort, Bucket Sort"),
                        tags$li("Binary Search and its variations"),
                        tags$li("Search in rotated arrays"),
                        tags$li("Finding kth largest/smallest element")
                      )
                  ),
                  
                  h5("Key Implementations"),
                  
                  div(class = "complexity-box",
                      strong("Complexities: "), "QuickSort O(n log n) avg, MergeSort O(n log n) guaranteed, Binary Search O(log n)"
                  ),
                  
                  div(class = "code-example",
                      "# Binary Search - Template",
                      tags$br(),
                      "def binarySearch(nums, target):",
                      tags$br(),
                      "    left, right = 0, len(nums) - 1",
                      tags$br(),
                      "    while left <= right:",
                      tags$br(),
                      "        mid = left + (right - left) // 2",
                      tags$br(),
                      "        if nums[mid] == target:",
                      tags$br(),
                      "            return mid",
                      tags$br(),
                      "        elif nums[mid] < target:",
                      tags$br(),
                      "            left = mid + 1",
                      tags$br(),
                      "        else:",
                      tags$br(),
                      "            right = mid - 1",
                      tags$br(),
                      "    return -1",
                      tags$br(),
                      tags$br(),
                      "# QuickSelect - Find Kth Largest",
                      tags$br(),
                      "import random",
                      tags$br(),
                      "def findKthLargest(nums, k):",
                      tags$br(),
                      "    def partition(left, right, pivot_idx):",
                      tags$br(),
                      "        pivot = nums[pivot_idx]",
                      tags$br(),
                      "        nums[pivot_idx], nums[right] = nums[right], nums[pivot_idx]",
                      tags$br(),
                      "        store_idx = left",
                      tags$br(),
                      "        for i in range(left, right):",
                      tags$br(),
                      "            if nums[i] < pivot:",
                      tags$br(),
                      "                nums[store_idx], nums[i] = nums[i], nums[store_idx]",
                      tags$br(),
                      "                store_idx += 1",
                      tags$br(),
                      "        nums[right], nums[store_idx] = nums[store_idx], nums[right]",
                      tags$br(),
                      "        return store_idx",
                      tags$br(),
                      "    def select(left, right, k_smallest):",
                      tags$br(),
                      "        if left == right: return nums[left]",
                      tags$br(),
                      "        pivot_idx = random.randint(left, right)",
                      tags$br(),
                      "        pivot_idx = partition(left, right, pivot_idx)",
                      tags$br(),
                      "        if k_smallest == pivot_idx:",
                      tags$br(),
                      "            return nums[k_smallest]",
                      tags$br(),
                      "        elif k_smallest < pivot_idx:",
                      tags$br(),
                      "            return select(left, pivot_idx - 1, k_smallest)",
                      tags$br(),
                      "        return select(pivot_idx + 1, right, k_smallest)",
                      tags$br(),
                      "    return select(0, len(nums) - 1, len(nums) - k)"
                  ),
                  
                  h5("Common Interview Problems"),
                  div(class = "problem-list",
                      div(class = "problem-item",
                          span(class = "difficulty-easy", "EASY"), " - Binary Search (LeetCode #704)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-medium", "MEDIUM"), " - Search in Rotated Sorted Array (LeetCode #33)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-medium", "MEDIUM"), " - Kth Largest Element (LeetCode #215)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-medium", "MEDIUM"), " - Merge Intervals (LeetCode #56)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-hard", "HARD"), " - Median of Two Sorted Arrays (LeetCode #4)"
                      )
                  ),
                  
                  h5("Pro Tips"),
                  div(class = "concept-highlight",
                      tags$ul(
                        tags$li("Binary search can solve more than just search problems"),
                        tags$li("Consider stability requirements when choosing sort algorithms"),
                        tags$li("QuickSelect gives O(n) average for selection problems"),
                        tags$li("Master binary search variants: leftmost, rightmost positions"),
                        tags$li("Think about custom comparators for complex sorting needs")
                      )
                  )
              ),
              
              div(class = "references",
                  h5("References"),
                  div(class = "reference-item", "Knuth, D. E. (1998). The art of computer programming, Vol. 3: Sorting and searching (2nd ed.). Addison-Wesley."),
                  div(class = "reference-item", "Cormen, T. H., Leiserson, C. E., Rivest, R. L., & Stein, C. (2009). Introduction to algorithms (3rd ed.). MIT Press."),
                  div(class = "reference-item", "Sedgewick, R., & Wayne, K. (2011). Algorithms (4th ed.). Addison-Wesley Professional."),
                  div(class = "reference-item", "Hoare, C. A. R. (1962). Quicksort. The Computer Journal, 5(1), 10-16.")
              )
          )
        )
),

# Hash Tables Tab
tabItem(tabName = "hashing",
        fluidRow(
          box(width = 12, status = "primary", solidHeader = TRUE,
              title = "Hash Tables & Hash Sets",
              div(class = "academic-content",
                  h5("Hashing Fundamentals"),
                  p("Hash tables provide O(1) average-case lookups, making them essential for optimizing algorithms. Understanding hash functions, collision resolution, and when to use hash-based data structures is crucial for technical interviews at Google and Meta."),
                  
                  div(class = "concept-highlight",
                      h5("Core Concepts:"),
                      tags$ul(
                        tags$li("Hash function design and properties"),
                        tags$li("Collision resolution: chaining vs. open addressing"),
                        tags$li("Load factor and dynamic resizing"),
                        tags$li("HashMap vs. HashSet applications"),
                        tags$li("Custom hash functions for complex keys")
                      )
                  ),
                  
                  h5("Common Patterns"),
                  
                  div(class = "complexity-box",
                      strong("Time Complexity: "), "Insert/Delete/Search O(1) average, O(n) worst case"
                  ),
                  
                  div(class = "code-example",
                      "# Two Sum using Hash Map",
                      tags$br(),
                      "def twoSum(nums, target):",
                      tags$br(),
                      "    seen = {}",
                      tags$br(),
                      "    for i, num in enumerate(nums):",
                      tags$br(),
                      "        complement = target - num",
                      tags$br(),
                      "        if complement in seen:",
                      tags$br(),
                      "            return [seen[complement], i]",
                      tags$br(),
                      "        seen[num] = i",
                      tags$br(),
                      "    return []",
                      tags$br(),
                      tags$br(),
                      "# Group Anagrams",
                      tags$br(),
                      "from collections import defaultdict",
                      tags$br(),
                      "def groupAnagrams(strs):",
                      tags$br(),
                      "    anagram_map = defaultdict(list)",
                      tags$br(),
                      "    for word in strs:",
                      tags$br(),
                      "        sorted_word = ''.join(sorted(word))",
                      tags$br(),
                      "        anagram_map[sorted_word].append(word)",
                      tags$br(),
                      "    return list(anagram_map.values())",
                      tags$br(),
                      tags$br(),
                      "# LRU Cache Implementation",
                      tags$br(),
                      "class LRUCache:",
                      tags$br(),
                      "    def __init__(self, capacity):",
                      tags$br(),
                      "        self.cache = OrderedDict()",
                      tags$br(),
                      "        self.capacity = capacity",
                      tags$br(),
                      "    def get(self, key):",
                      tags$br(),
                      "        if key not in self.cache: return -1",
                      tags$br(),
                      "        self.cache.move_to_end(key)",
                      tags$br(),
                      "        return self.cache[key]",
                      tags$br(),
                      "    def put(self, key, value):",
                      tags$br(),
                      "        if key in self.cache:",
                      tags$br(),
                      "            self.cache.move_to_end(key)",
                      tags$br(),
                      "        self.cache[key] = value",
                      tags$br(),
                      "        if len(self.cache) > self.capacity:",
                      tags$br(),
                      "            self.cache.popitem(last=False)"
                  ),
                  
                  h5("Common Interview Problems"),
                  div(class = "problem-list",
                      div(class = "problem-item",
                          span(class = "difficulty-easy", "EASY"), " - Two Sum (LeetCode #1)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-medium", "MEDIUM"), " - Group Anagrams (LeetCode #49)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-medium", "MEDIUM"), " - Subarray Sum Equals K (LeetCode #560)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-medium", "MEDIUM"), " - Top K Frequent Elements (LeetCode #347)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-hard", "HARD"), " - LRU Cache (LeetCode #146)"
                      )
                  ),
                  
                  h5("Interview Strategy"),
                  div(class = "concept-highlight",
                      tags$ul(
                        tags$li("Use hash maps to trade space for time efficiency"),
                        tags$li("Consider OrderedDict when insertion order matters"),
                        tags$li("Use Counter for frequency-based problems"),
                        tags$li("Remember that sets are implemented as hash tables"),
                        tags$li("Think about thread-safety in system design contexts")
                      )
                  )
              ),
              
              div(class = "references",
                  h5("References"),
                  div(class = "reference-item", "Cormen, T. H., Leiserson, C. E., Rivest, R. L., & Stein, C. (2009). Introduction to algorithms (3rd ed.). MIT Press."),
                  div(class = "reference-item", "Knuth, D. E. (1998). The art of computer programming, Vol. 3: Sorting and searching (2nd ed.). Addison-Wesley."),
                  div(class = "reference-item", "Sedgewick, R., & Wayne, K. (2011). Algorithms (4th ed.). Addison-Wesley Professional."),
                  div(class = "reference-item", "Goodrich, M. T., Tamassia, R., & Goldwasser, M. H. (2013). Data structures and algorithms in Python. Wiley.")
              )
          )
        )
),

# Heaps Tab
tabItem(tabName = "heaps",
        fluidRow(
          box(width = 12, status = "primary", solidHeader = TRUE,
              title = "Heaps & Priority Queues",
              div(class = "academic-content",
                  h5("Priority Queue Operations"),
                  p("Heaps are specialized tree-based structures that maintain a partial ordering, making them perfect for priority queue implementations. They're essential for problems involving top-k elements, scheduling, and median finding in Google and Meta interviews."),
                  
                  div(class = "concept-highlight",
                      h5("Key Concepts:"),
                      tags$ul(
                        tags$li("Min-heap and max-heap properties"),
                        tags$li("Heapify operations and complexity"),
                        tags$li("Priority queue applications"),
                        tags$li("Top-k problems and heap usage"),
                        tags$li("Median finding with two heaps"),
                        tags$li("Merge k sorted lists/arrays")
                      )
                  ),
                  
                  h5("Core Operations"),
                  
                  div(class = "complexity-box",
                      strong("Time Complexity: "), "Insert O(log n), Extract-Min/Max O(log n), Peek O(1), Heapify O(n)"
                  ),
                  
                  div(class = "code-example",
                      "# Find K Closest Points using Heap",
                      tags$br(),
                      "import heapq",
                      tags$br(),
                      "def kClosest(points, k):",
                      tags$br(),
                      "    heap = []",
                      tags$br(),
                      "    for x, y in points:",
                      tags$br(),
                      "        dist = -(x*x + y*y)  # Negative for max heap",
                      tags$br(),
                      "        if len(heap) < k:",
                      tags$br(),
                      "            heapq.heappush(heap, (dist, x, y))",
                      tags$br(),
                      "        else:",
                      tags$br(),
                      "            heapq.heappushpop(heap, (dist, x, y))",
                      tags$br(),
                      "    return [[x, y] for (_, x, y) in heap]",
                      tags$br(),
                      tags$br(),
                      "# Median Finder with Two Heaps",
                      tags$br(),
                      "class MedianFinder:",
                      tags$br(),
                      "    def __init__(self):",
                      tags$br(),
                      "        self.small = []  # max heap (inverted)",
                      tags$br(),
                      "        self.large = []  # min heap",
                      tags$br(),
                      "    def addNum(self, num):",
                      tags$br(),
                      "        heapq.heappush(self.small, -num)",
                      tags$br(),
                      "        heapq.heappush(self.large, -heapq.heappop(self.small))",
                      tags$br(),
                      "        if len(self.small) < len(self.large):",
                      tags$br(),
                      "            heapq.heappush(self.small, -heapq.heappop(self.large))",
                      tags$br(),
                      "    def findMedian(self):",
                      tags$br(),
                      "        if len(self.small) > len(self.large):",
                      tags$br(),
                      "            return -self.small[0]",
                      tags$br(),
                      "        return (-self.small[0] + self.large[0]) / 2.0"
                  ),
                  
                  h5("Common Interview Problems"),
                  div(class = "problem-list",
                      div(class = "problem-item",
                          span(class = "difficulty-easy", "EASY"), " - Kth Largest Element in Stream (LeetCode #703)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-medium", "MEDIUM"), " - Top K Frequent Elements (LeetCode #347)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-medium", "MEDIUM"), " - K Closest Points to Origin (LeetCode #973)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-hard", "HARD"), " - Find Median from Data Stream (LeetCode #295)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-hard", "HARD"), " - Merge K Sorted Lists (LeetCode #23)"
                      )
                  ),
                  
                  h5("Heap Mastery Tips"),
                  div(class = "concept-highlight",
                      tags$ul(
                        tags$li("Python's heapq only supports min-heap (negate for max-heap)"),
                        tags$li("For top-k problems, use opposite heap type (max-heap for k smallest)"),
                        tags$li("Two-heap technique is powerful for streaming median"),
                        tags$li("Consider heap when you need repeated min/max operations"),
                        tags$li("Heapify is O(n), faster than n insertions")
                      )
                  )
              ),
              
              div(class = "references",
                  h5("References"),
                  div(class = "reference-item", "Williams, J. W. J. (1964). Algorithm 232: Heapsort. Communications of the ACM, 7(6), 347-348."),
                  div(class = "reference-item", "Cormen, T. H., Leiserson, C. E., Rivest, R. L., & Stein, C. (2009). Introduction to algorithms (3rd ed.). MIT Press."),
                  div(class = "reference-item", "Sedgewick, R., & Wayne, K. (2011). Algorithms (4th ed.). Addison-Wesley Professional."),
                  div(class = "reference-item", "Skiena, S. S. (2020). The algorithm design manual (3rd ed.). Springer.")
              )
          )
        )
),

# Recursion & Backtracking Tab
tabItem(tabName = "recursion",
        fluidRow(
          box(width = 12, status = "primary", solidHeader = TRUE,
              title = "Recursion & Backtracking",
              div(class = "academic-content",
                  h5("Recursive Problem Solving"),
                  p("Recursion and backtracking are powerful techniques for exploring solution spaces. Backtracking systematically searches for solutions by trying possibilities and abandoning them when they fail. These techniques are common in constraint satisfaction and combinatorial problems at FAANG companies."),
                  
                  div(class = "concept-highlight",
                      h5("Core Patterns:"),
                      tags$ul(
                        tags$li("Base case and recursive case identification"),
                        tags$li("Backtracking template and pruning"),
                        tags$li("Combination and permutation generation"),
                        tags$li("Constraint satisfaction problems"),
                        tags$li("State space tree exploration"),
                        tags$li("Memoization for optimization")
                      )
                  ),
                  
                  h5("Backtracking Template"),
                  
                  div(class = "complexity-box",
                      strong("Time Complexity: "), "Often exponential O(b^d) where b=branching factor, d=depth"
                  ),
                  
                  div(class = "code-example",
                      "# Backtracking Template",
                      tags$br(),
                      "def backtrack(path, options):",
                      tags$br(),
                      "    if is_solution(path):",
                      tags$br(),
                      "        result.append(path.copy())",
                      tags$br(),
                      "        return",
                      tags$br(),
                      "    for option in options:",
                      tags$br(),
                      "        if is_valid(option):",
                      tags$br(),
                      "            path.append(option)",
                      tags$br(),
                      "            backtrack(path, next_options)",
                      tags$br(),
                      "            path.pop()  # Backtrack",
                      tags$br(),
                      tags$br(),
                      "# Subsets - Power Set Generation",
                      tags$br(),
                      "def subsets(nums):",
                      tags$br(),
                      "    result = []",
                      tags$br(),
                      "    def backtrack(start, path):",
                      tags$br(),
                      "        result.append(path[:])",
                      tags$br(),
                      "        for i in range(start, len(nums)):",
                      tags$br(),
                      "            path.append(nums[i])",
                      tags$br(),
                      "            backtrack(i + 1, path)",
                      "            path.pop()",
                      tags$br(),
                      "    backtrack(0, [])",
                      tags$br(),
                      "    return result",
                      tags$br(),
                      tags$br(),
                      "# N-Queens Problem",
                      tags$br(),
                      "def solveNQueens(n):",
                      tags$br(),
                      "    result = []",
                      tags$br(),
                      "    board = [['.'] * n for _ in range(n)]",
                      tags$br(),
                      "    def is_valid(row, col):",
                      tags$br(),
                      "        for i in range(row):",
                      tags$br(),
                      "            if board[i][col] == 'Q': return False",
                      tags$br(),
                      "        i, j = row - 1, col - 1",
                      tags$br(),
                      "        while i >= 0 and j >= 0:",
                      tags$br(),
                      "            if board[i][j] == 'Q': return False",
                      tags$br(),
                      "            i, j = i - 1, j - 1",
                      tags$br(),
                      "        i, j = row - 1, col + 1",
                      tags$br(),
                      "        while i >= 0 and j < n:",
                      tags$br(),
                      "            if board[i][j] == 'Q': return False",
                      tags$br(),
                      "            i, j = i - 1, j + 1",
                      tags$br(),
                      "        return True",
                      tags$br(),
                      "    def backtrack(row):",
                      tags$br(),
                      "        if row == n:",
                      tags$br(),
                      "            result.append([''.join(r) for r in board])",
                      tags$br(),
                      "            return",
                      tags$br(),
                      "        for col in range(n):",
                      tags$br(),
                      "            if is_valid(row, col):",
                      tags$br(),
                      "                board[row][col] = 'Q'",
                      tags$br(),
                      "                backtrack(row + 1)",
                      tags$br(),
                      "                board[row][col] = '.'",
                      tags$br(),
                      "    backtrack(0)",
                      tags$br(),
                      "    return result"
                  ),
                  
                  h5("Common Interview Problems"),
                  div(class = "problem-list",
                      div(class = "problem-item",
                          span(class = "difficulty-medium", "MEDIUM"), " - Permutations (LeetCode #46)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-medium", "MEDIUM"), " - Subsets (LeetCode #78)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-medium", "MEDIUM"), " - Combination Sum (LeetCode #39)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-medium", "MEDIUM"), " - Word Search (LeetCode #79)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-hard", "HARD"), " - N-Queens (LeetCode #51)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-hard", "HARD"), " - Sudoku Solver (LeetCode #37)"
                      )
                  ),
                  
                  h5("Optimization Techniques"),
                  div(class = "concept-highlight",
                      tags$ul(
                        tags$li("Prune branches early to reduce search space"),
                        tags$li("Use memoization to cache repeated subproblems"),
                        tags$li("Sort input when order doesn't matter for better pruning"),
                        tags$li("Track visited states to avoid redundant work"),
                        tags$li("Consider iterative approaches for tail recursion")
                      )
                  )
              ),
              
              div(class = "references",
                  h5("References"),
                  div(class = "reference-item", "Sedgewick, R., & Wayne, K. (2011). Algorithms (4th ed.). Addison-Wesley Professional."),
                  div(class = "reference-item", "Skiena, S. S. (2020). The algorithm design manual (3rd ed.). Springer."),
                  div(class = "reference-item", "Cormen, T. H., Leiserson, C. E., Rivest, R. L., & Stein, C. (2009). Introduction to algorithms (3rd ed.). MIT Press."),
                  div(class = "reference-item", "Russell, S., & Norvig, P. (2020). Artificial intelligence: A modern approach (4th ed.). Pearson.")
              )
          )
        )
),

# Greedy Algorithms Tab
tabItem(tabName = "greedy",
        fluidRow(
          box(width = 12, status = "primary", solidHeader = TRUE,
              title = "Greedy Algorithms",
              div(class = "academic-content",
                  h5("Greedy Algorithm Design"),
                  p("Greedy algorithms make locally optimal choices at each step, hoping to find a global optimum. While they don't always work, when applicable they provide elegant and efficient solutions. Understanding when greedy works is crucial for FAANG interviews."),
                  
                  div(class = "concept-highlight",
                      h5("Key Concepts:"),
                      tags$ul(
                        tags$li("Greedy choice property"),
                        tags$li("Optimal substructure"),
                        tags$li("Activity selection and scheduling"),
                        tags$li("Interval problems and overlaps"),
                        tags$li("Huffman coding and compression"),
                        tags$li("Minimum spanning trees (Kruskal, Prim)")
                      )
                  ),
                  
                  h5("Classic Greedy Algorithms"),
                  
                  div(class = "complexity-box",
                      strong("Advantage: "), "Often O(n log n) or better, simpler than DP when applicable"
                  ),
                  
                  div(class = "code-example",
                      "# Jump Game - Greedy Approach",
                      tags$br(),
                      "def canJump(nums):",
                      tags$br(),
                      "    max_reach = 0",
                      tags$br(),
                      "    for i in range(len(nums)):",
                      tags$br(),
                      "        if i > max_reach:",
                      tags$br(),
                      "            return False",
                      tags$br(),
                      "        max_reach = max(max_reach, i + nums[i])",
                      tags$br(),
                      "        if max_reach >= len(nums) - 1:",
                      tags$br(),
                      "            return True",
                      tags$br(),
                      "    return True",
                      tags$br(),
                      tags$br(),
                      "# Meeting Rooms II - Minimum Rooms",
                      tags$br(),
                      "import heapq",
                      tags$br(),
                      "def minMeetingRooms(intervals):",
                      tags$br(),
                      "    if not intervals: return 0",
                      tags$br(),
                      "    intervals.sort(key=lambda x: x[0])",
                      tags$br(),
                      "    heap = []",
                      tags$br(),
                      "    heapq.heappush(heap, intervals[0][1])",
                      tags$br(),
                      "    for i in range(1, len(intervals)):",
                      tags$br(),
                      "        if intervals[i][0] >= heap[0]:",
                      tags$br(),
                      "            heapq.heappop(heap)",
                      tags$br(),
                      "        heapq.heappush(heap, intervals[i][1])",
                      tags$br(),
                      "    return len(heap)",
                      tags$br(),
                      tags$br(),
                      "# Gas Station - Circular Array",
                      tags$br(),
                      "def canCompleteCircuit(gas, cost):",
                      tags$br(),
                      "    if sum(gas) < sum(cost): return -1",
                      tags$br(),
                      "    tank = start = 0",
                      tags$br(),
                      "    for i in range(len(gas)):",
                      tags$br(),
                      "        tank += gas[i] - cost[i]",
                      tags$br(),
                      "        if tank < 0:",
                      tags$br(),
                      "            start = i + 1",
                      tags$br(),
                      "            tank = 0",
                      tags$br(),
                      "    return start"
                  ),
                  
                  h5("Common Interview Problems"),
                  div(class = "problem-list",
                      div(class = "problem-item",
                          span(class = "difficulty-easy", "EASY"), " - Best Time to Buy and Sell Stock II (LeetCode #122)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-medium", "MEDIUM"), " - Jump Game (LeetCode #55)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-medium", "MEDIUM"), " - Gas Station (LeetCode #134)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-medium", "MEDIUM"), " - Non-overlapping Intervals (LeetCode #435)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-hard", "HARD"), " - Minimum Number of Taps (LeetCode #1326)"
                      )
                  ),
                  
                  h5("When to Use Greedy"),
                  div(class = "concept-highlight",
                      tags$ul(
                        tags$li("Problem exhibits optimal substructure"),
                        tags$li("Local optimal choices lead to global optimum"),
                        tags$li("Can prove correctness (exchange argument, staying ahead)"),
                        tags$li("Sorting often precedes greedy choices"),
                        tags$li("If greedy fails, consider DP or other approaches")
                      )
                  )
              ),
              
              div(class = "references",
                  h5("References"),
                  div(class = "reference-item", "Cormen, T. H., Leiserson, C. E., Rivest, R. L., & Stein, C. (2009). Introduction to algorithms (3rd ed.). MIT Press."),
                  div(class = "reference-item", "Kleinberg, J., & Tardos, E. (2005). Algorithm design. Pearson."),
                  div(class = "reference-item", "Skiena, S. S. (2020). The algorithm design manual (3rd ed.). Springer."),
                  div(class = "reference-item", "Dasgupta, S., Papadimitriou, C. H., & Vazirani, U. V. (2008). Algorithms. McGraw-Hill.")
              )
          )
        )
),

# Bit Manipulation Tab
tabItem(tabName = "bits",
        fluidRow(
          box(width = 12, status = "primary", solidHeader = TRUE,
              title = "Bit Manipulation Techniques",
              div(class = "academic-content",
                  h5("Binary Operations Mastery"),
                  p("Bit manipulation involves directly operating on binary representations of numbers. These techniques are crucial for optimization, space efficiency, and solving specific problem types. Google and Meta often test understanding of low-level operations and clever bit tricks."),
                  
                  div(class = "concept-highlight",
                      h5("Fundamental Operations:"),
                      tags$ul(
                        tags$li("Bitwise operators: AND, OR, XOR, NOT, shifts"),
                        tags$li("Bit masks and flag operations"),
                        tags$li("Setting, clearing, toggling, and checking bits"),
                        tags$li("Two's complement representation"),
                        tags$li("Bit counting and manipulation tricks")
                      )
                  ),
                  
                  h5("Common Bit Tricks"),
                  
                  div(class = "complexity-box",
                      strong("Key Properties: "), "x ^ x = 0, x ^ 0 = x, x & (x-1) clears lowest set bit"
                  ),
                  
                  div(class = "code-example",
                      "# Common Bit Manipulation Operations",
                      tags$br(),
                      "# Check if kth bit is set",
                      tags$br(),
                      "def is_bit_set(num, k):",
                      tags$br(),
                      "    return (num & (1 << k)) != 0",
                      tags$br(),
                      tags$br(),
                      "# Set kth bit",
                      tags$br(),
                      "def set_bit(num, k):",
                      tags$br(),
                      "    return num | (1 << k)",
                      tags$br(),
                      tags$br(),
                      "# Clear kth bit",
                      tags$br(),
                      "def clear_bit(num, k):",
                      tags$br(),
                      "    return num & ~(1 << k)",
                      tags$br(),
                      tags$br(),
                      "# Toggle kth bit",
                      tags$br(),
                      "def toggle_bit(num, k):",
                      tags$br(),
                      "    return num ^ (1 << k)",
                      tags$br(),
                      tags$br(),
                      "# Count set bits (Brian Kernighan's Algorithm)",
                      tags$br(),
                      "def count_bits(n):",
                      tags$br(),
                      "    count = 0",
                      tags$br(),
                      "    while n:",
                      tags$br(),
                      "        n &= n - 1  # Clear lowest set bit",
                      tags$br(),
                      "        count += 1",
                      tags$br(),
                      "    return count",
                      tags$br(),
                      tags$br(),
                      "# Single Number (XOR trick)",
                      tags$br(),
                      "def singleNumber(nums):",
                      tags$br(),
                      "    result = 0",
                      tags$br(),
                      "    for num in nums:",
                      tags$br(),
                      "        result ^= num",
                      tags$br(),
                      "    return result",
                      tags$br(),
                      tags$br(),
                      "# Power of Two Check",
                      tags$br(),
                      "def isPowerOfTwo(n):",
                      tags$br(),
                      "    return n > 0 and (n & (n - 1)) == 0",
                      tags$br(),
                      tags$br(),
                      "# Reverse Bits",
                      tags$br(),
                      "def reverseBits(n):",
                      tags$br(),
                      "    result = 0",
                      tags$br(),
                      "    for i in range(32):",
                      tags$br(),
                      "        result = (result << 1) | (n & 1)",
                      tags$br(),
                      "        n >>= 1",
                      tags$br(),
                      "    return result"
                  ),
                  
                  h5("Common Interview Problems"),
                  div(class = "problem-list",
                      div(class = "problem-item",
                          span(class = "difficulty-easy", "EASY"), " - Number of 1 Bits (LeetCode #191)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-easy", "EASY"), " - Single Number (LeetCode #136)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-medium", "MEDIUM"), " - Counting Bits (LeetCode #338)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-medium", "MEDIUM"), " - Sum of Two Integers (LeetCode #371)"
                      ),
                      div(class = "problem-item",
                          span(class = "difficulty-hard", "HARD"), " - Maximum XOR of Two Numbers (LeetCode #421)"
                      )
                  ),
                  
                  h5("Pro Tips"),
                  div(class = "concept-highlight",
                      tags$ul(
                        tags$li("XOR has useful properties: self-inverse, associative, commutative"),
                        tags$li("x & (x - 1) trick removes the rightmost set bit"),
                        tags$li("Bit shifts multiply/divide by powers of 2"),
                        tags$li("Masks isolate specific bits or ranges"),
                        tags$li("Understand signed vs unsigned and overflow behavior")
                      )
                  )
              ),
              
              div(class = "references",
                  h5("References"),
                  div(class = "reference-item", "Warren, H. S. (2012). Hacker's delight (2nd ed.). Addison-Wesley Professional."),
                  div(class = "reference-item", "Cormen, T. H., Leiserson, C. E., Rivest, R. L., & Stein, C. (2009). Introduction to algorithms (3rd ed.). MIT Press."),
                  div(class = "reference-item", "Knuth, D. E. (1997). The art of computer programming, Vol. 2: Seminumerical algorithms (3rd ed.). Addison-Wesley."),
                  div(class = "reference-item", "Aziz, A., Lee, T. H., & Prakash, A. (2018). Elements of programming interviews in Python. CreateSpace Independent Publishing Platform.")
              )
          )
        )
),

# System Design Tab
tabItem(tabName = "systemdesign",
        fluidRow(
          box(width = 12, status = "primary", solidHeader = TRUE,
              title = "System Design Basics",
              div(class = "academic-content",
                  h5("Scalable System Architecture"),
                  p("System design interviews at Google and Meta assess your ability to design large-scale distributed systems. While this tab covers fundamentals, senior positions require deep expertise in scalability, reliability, and performance optimization."),
                  
                  div(class = "concept-highlight",
                      h5("Core Concepts:"),
                      tags$ul(
                        tags$li("Scalability: vertical vs horizontal scaling"),
                        tags$li("Load balancing and distribution strategies"),
                        tags$li("Caching layers: CDN, application, database"),
                        tags$li("Database design: SQL vs NoSQL, sharding, replication"),
                        tags$li("Microservices vs monolithic architecture"),
                        tags$li("CAP theorem: consistency, availability, partition tolerance")
                      )
                  ),
                  
                  h5("Design Framework (RADIO)"),
                  
                  div(class = "complexity-box",
                      strong("Interview Approach: "), "Requirements → Architecture → Data → Interface → Optimization"
                  ),
                  
                  div(class = "concept-highlight",
                      h5("System Design Process:"),
                      tags$ol(
                        tags$li(strong("Requirements: "), "Functional and non-functional requirements, scale estimation"),
                        tags$li(strong("Architecture: "), "High-level components, services, data flow"),
                        tags$li(strong("Data: "), "Schema design, storage choice, data partitioning"),
                        tags$li(strong("Interface: "), "API design, protocols, contracts"),
                        tags$li(strong("Optimization: "), "Bottlenecks, caching, scaling strategies")
                      )
                  ),
                  
                  h5("Common Design Patterns"),
                  div(class = "problem-list",
                      div(class = "problem-item",
                          strong("Rate Limiter: "), "Token bucket, sliding window, distributed rate limiting"
                      ),
                      div(class = "problem-item",
                          strong("URL Shortener: "), "Hash generation, base62 encoding, collision handling"
                      ),
                      div(class = "problem-item",
                          strong("News Feed: "), "Fan-out on write vs read, timeline generation, ranking"
                      ),
                      div(class = "problem-item",
                          strong("Chat System: "), "WebSockets, message queues, presence service"
                      ),
                      div(class = "problem-item",
                          strong("Search Engine: "), "Crawling, indexing, ranking, distributed search"
                      )
                  ),
                  
                  h5("Key Technologies"),
                  div(class = "concept-highlight",
                      tags$ul(
                        tags$li(strong("Databases: "), "PostgreSQL, MySQL, MongoDB, Cassandra, Redis"),
                        tags$li(strong("Caching: "), "Redis, Memcached, CDNs (CloudFlare, Akamai)"),
                        tags$li(strong("Message Queues: "), "Kafka, RabbitMQ, Amazon SQS"),
                        tags$li(strong("Load Balancers: "), "Nginx, HAProxy, AWS ELB"),
                        tags$li(strong("Monitoring: "), "Prometheus, Grafana, ELK Stack")
                      )
                  ),
                  
                  h5("Trade-offs and Considerations"),
                  div(class = "concept-highlight",
                      tags$ul(
                        tags$li("Consistency vs Availability: Choose based on use case"),
                        tags$li("Latency vs Throughput: Optimize for user experience"),
                        tags$li("Cost vs Performance: Balance budget with requirements"),
                        tags$li("Complexity vs Maintainability: Simple solutions often win"),
                        tags$li("Security: Authentication, authorization, encryption, rate limiting")
                      )
                  ),
                  
                  h5("Scale Estimation Example"),
                  div(class = "concept-highlight",
                      tags$ul(
                        tags$li("Daily Active Users (DAU): 10 million"),
                        tags$li("Requests per user: 50/day → 500M requests/day"),
                        tags$li("QPS (Queries Per Second): 500M / 86400 ≈ 5800 QPS"),
                        tags$li("Peak QPS: ~2x average = 11,600 QPS"),
                        tags$li("Storage: Estimate data per user × users × retention period")
                      )
                  )
              ),
              
              div(class = "references",
                  h5("References"),
                  div(class = "reference-item", "Kleppmann, M. (2017). Designing data-intensive applications: The big ideas behind reliable, scalable, and maintainable systems. O'Reilly Media."),
                  div(class = "reference-item", "Xu, A. (2020). System design interview: An insider's guide (Volume 1). Independently published."),
                  div(class = "reference-item", "Newman, S. (2021). Building microservices: Designing fine-grained systems (2nd ed.). O'Reilly Media."),
                  div(class = "reference-item", "Nygard, M. T. (2018). Release it!: Design and deploy production-ready software (2nd ed.). Pragmatic Bookshelf.")
              )
          )
        )
)
)
)
)

# Server Logic
server <- function(input, output, session) {
  # Server logic can be added here for interactive elements
  # Currently focused on content presentation
  
  # Potential additions:
  # - Progress tracking across topics
  # - Code execution playground
  # - Problem difficulty filters
  # - Study plan generator
  # - Spaced repetition scheduler
}

# Run the application
shinyApp(ui = ui, server = server)
                        