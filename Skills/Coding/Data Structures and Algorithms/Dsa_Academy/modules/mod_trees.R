# modules/mod_trees.R — Trees & BSTs

trees_ui <- function(id) {
  ns <- NS(id)
  tagList(
    topic_hero("🌳", "Trees & Binary Search Trees",
      "Hierarchical structures. Master all traversals, BST properties, and recursive/iterative patterns.",
      c("Inorder", "Preorder", "Postorder", "BFS", "BST", "LCA")),

    fluidRow(
      box(title = "BST Insert & Traversal", status = "primary", solidHeader = TRUE, width = 4,
        tags$p("Build a BST by inserting values, then choose a traversal to see the visit order.", style="font-size:12px; color:#555;"),
        textInput(ns("bst_vals"), "Insert values (comma-separated):", value = "8,3,10,1,6,14,4,7,13"),
        radioButtons(ns("traversal"), "Traversal order:",
          choices = c("Inorder (L→Root→R)"    = "inorder",
                      "Preorder (Root→L→R)"   = "preorder",
                      "Postorder (L→R→Root)"  = "postorder",
                      "Level-order (BFS)"     = "levelorder"),
          selected = "inorder"),
        actionButton(ns("btn_traverse"), "Run Traversal", class = "btn btn-dsa")
      ),
      box(title = "Traversal Result", status = "info", solidHeader = TRUE, width = 8,
        uiOutput(ns("viz_traversal")),
        uiOutput(ns("traversal_explain"))
      )
    ),

    fluidRow(
      box(title = "BST Complexity Reference", status = "info", solidHeader = TRUE, width = 4,
        cplx_table(data.frame(
          Operation = c("Search", "Insert", "Delete", "Min/Max", "Traversal"),
          Average   = c("O(log n)", "O(log n)", "O(log n)", "O(log n)", "O(n)"),
          Worst     = c("O(n)", "O(n)", "O(n)", "O(n)", "O(n)"),
          stringsAsFactors = FALSE
        )),
        tags$br(),
        callout("Worst case O(n) occurs when the BST degenerates into a linked list (sorted input). Use AVL or Red-Black trees for guaranteed O(log n).", "warn")
      ),
      box(title = "Key Algorithms (Python)", status = "primary", solidHeader = TRUE, width = 5,
        tags$p(tags$strong("Iterative Inorder — O(n)"), style="font-size:12px;"),
        dsa_code(
'def inorderTraversal(root):
    res, stack, cur = [], [], root
    while cur or stack:
        while cur:
            stack.append(cur)
            cur = cur.left
        cur = stack.pop()
        res.append(cur.val)
        cur = cur.right
    return res'),
        tags$p(tags$strong("Validate BST — O(n)"), style="font-size:12px; margin-top:10px;"),
        dsa_code(
'def isValidBST(root):
    def check(node, lo, hi):
        if not node: return True
        if node.val <= lo or node.val >= hi:
            return False
        return (check(node.left,  lo, node.val) and
                check(node.right, node.val, hi))
    return check(root, float("-inf"), float("inf"))')
      ),
      box(title = "Quick Quiz", status = "warning", solidHeader = TRUE, width = 3,
        uiOutput(ns("quiz_ui"))
      )
    ),

    fluidRow(
      box(title = "LeetCode Problems", status = "success", solidHeader = TRUE, width = 6,
        fluidRow(
          column(6,
            prob_row(104, "Maximum Depth",              "Easy",   "https://leetcode.com/problems/maximum-depth-of-binary-tree/"),
            prob_row(226, "Invert Binary Tree",         "Easy",   "https://leetcode.com/problems/invert-binary-tree/"),
            prob_row(543, "Diameter of Binary Tree",    "Easy",   "https://leetcode.com/problems/diameter-of-binary-tree/"),
            prob_row(98,  "Validate BST",               "Medium", "https://leetcode.com/problems/validate-binary-search-tree/")
          ),
          column(6,
            prob_row(102, "Level Order Traversal",      "Medium", "https://leetcode.com/problems/binary-tree-level-order-traversal/"),
            prob_row(235, "LCA of BST",                 "Medium", "https://leetcode.com/problems/lowest-common-ancestor-of-a-binary-search-tree/"),
            prob_row(105, "Build from Pre+Inorder",     "Medium", "https://leetcode.com/problems/construct-binary-tree-from-preorder-and-inorder-traversal/"),
            prob_row(297, "Serialize/Deserialize",      "Hard",   "https://leetcode.com/problems/serialize-and-deserialize-binary-tree/")
          )
        )
      ),
      box(title = "Traversal Memory Aid", status = "info", solidHeader = TRUE, width = 6,
        callout("<strong>Inorder (L→Root→R):</strong> visits BST nodes in sorted ascending order. Use to validate or extract sorted sequence.", "tip"),
        callout("<strong>Preorder (Root→L→R):</strong> root comes first — useful for copying/serialising a tree.", "info"),
        callout("<strong>Postorder (L→R→Root):</strong> children before parent — useful for deletion and evaluating expression trees.", "info"),
        callout("<strong>Level-order (BFS):</strong> processes level by level using a queue — used for min-depth, zigzag, right-side view.", "info")
      )
    ),

    ref_block(
      "Cormen et al. (2009). Introduction to Algorithms (3rd ed.). MIT Press.",
      "Knuth, D. E. (1998). The Art of Computer Programming, Vol. 3: Sorting and Searching.",
      "Laakmann McDowell (2015). Cracking the Coding Interview (6th ed.)."
    )
  )
}

trees_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # ── Simple BST in R ───────────────────────────────────────────────────────
    bst_insert <- function(tree, val) {
      if (is.null(tree)) return(list(val=val, left=NULL, right=NULL))
      if (val < tree$val) tree$left  <- bst_insert(tree$left, val)
      else                tree$right <- bst_insert(tree$right, val)
      tree
    }
    inorder   <- function(t) if(is.null(t)) c() else c(inorder(t$left),   t$val, inorder(t$right))
    preorder  <- function(t) if(is.null(t)) c() else c(t$val, preorder(t$left),  preorder(t$right))
    postorder <- function(t) if(is.null(t)) c() else c(postorder(t$left), postorder(t$right), t$val)
    levelorder <- function(t) {
      if (is.null(t)) return(c())
      queue <- list(t); res <- c()
      while (length(queue) > 0) {
        node <- queue[[1]]; queue <- queue[-1]
        res <- c(res, node$val)
        if (!is.null(node$left))  queue <- c(queue, list(node$left))
        if (!is.null(node$right)) queue <- c(queue, list(node$right))
      }
      res
    }

    traversal_result <- eventReactive(input$btn_traverse, {
      vals <- suppressWarnings(as.integer(trimws(strsplit(input$bst_vals,",")[[1]])))
      vals <- vals[!is.na(vals)]
      req(length(vals) > 0)
      tree <- NULL
      for (v in vals) tree <- bst_insert(tree, v)
      switch(input$traversal,
        inorder    = list(order = inorder(tree),    desc = "Left → Root → Right: produces sorted output"),
        preorder   = list(order = preorder(tree),   desc = "Root → Left → Right: root always first"),
        postorder  = list(order = postorder(tree),  desc = "Left → Right → Root: root always last"),
        levelorder = list(order = levelorder(tree), desc = "Level by level using a queue (BFS)")
      )
    }, ignoreNULL = FALSE)

    output$viz_traversal <- renderUI({
      res <- traversal_result(); req(!is.null(res))
      nodes <- lapply(seq_along(res$order), function(i)
        tagList(tags$div(class = "vnode visited", style = paste0("animation-delay:", i*0.05, "s"), res$order[i]),
                if(i < length(res$order)) tags$span(class="varrow","→"))
      )
      tags$div(class="viz-canvas", style="flex-wrap:wrap;", nodes)
    })

    output$traversal_explain <- renderUI({
      res <- traversal_result()
      if (is.null(res)) return(tags$div(class="viz-explain","Press 'Run Traversal' to see the visit order."))
      tags$div(class="viz-explain",
        paste0(toupper(input$traversal), ": [", paste(res$order, collapse=", "), "] — ", res$desc))
    })

    # ── Quiz ─────────────────────────────────────────────────────────────────
    q_ans <- reactiveVal(NULL)
    output$quiz_ui <- renderUI({
      ans <- q_ans()
      tagList(
        tags$p(class="quiz-q","Inorder traversal of a valid BST always produces values in what order?"),
        tags$button(class=paste("qopt",if(!is.null(ans)&&ans=="a")"wrong" else ""),
          "Random order", onclick=sprintf("Shiny.setInputValue('%s','a',{priority:'event'})",ns("qa"))),
        tags$button(class=paste("qopt",if(!is.null(ans)&&ans=="b")"wrong" else ""),
          "Descending order", onclick=sprintf("Shiny.setInputValue('%s','b',{priority:'event'})",ns("qa"))),
        tags$button(class=paste("qopt",if(!is.null(ans)&&ans=="c")"right" else ""),
          "Ascending (sorted) order", onclick=sprintf("Shiny.setInputValue('%s','c',{priority:'event'})",ns("qa"))),
        if(!is.null(ans)){
          if(ans=="c") tags$div(class="qfeedback right","✅ Correct! BST property: left < root < right, so inorder always yields ascending sorted sequence.")
          else tags$div(class="qfeedback wrong","❌ BST property guarantees inorder = ascending sorted order. This is the key insight for BST validation.")
        }
      )
    })
    observeEvent(input$qa, q_ans(input$qa))
  })
}
