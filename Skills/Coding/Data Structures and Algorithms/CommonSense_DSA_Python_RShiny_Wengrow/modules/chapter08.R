# modules/chapter08.R  — Blazing Fast Lookup with Hash Tables

CH08_FILES <- list(
  list(
    name = "status_codes1.py",
    description = "<strong>status_codes1.py</strong> — HTTP status code lookup using if/elif chain. O(N) worst case — must check each condition.",
    code = 'def status_code_meaning(number):\n    if number == 200:\n        return "OK"\n    elif number == 301:\n        return "Moved Permanently"\n    elif number == 401:\n        return "Unauthorized"\n    elif number == 404:\n        return "Not Found"\n    elif number == 500:\n        return "Internal Server Error"',
    demo = 'for code in [200, 301, 401, 404, 500, 999]:\n    print(f"status_code_meaning({code}) = {status_code_meaning(code)}")'
  ),
  list(
    name = "status_codes2.py",
    description = "<strong>status_codes2.py</strong> — Same lookup via a hash table (Python dict). O(1) — direct key lookup regardless of table size.",
    code = 'status_codes = {200: "OK", 301: "Moved Permanently",\n                401: "Unauthorized", 404: "Not Found",\n                500: "Internal Server Error"}\n\ndef status_code_meaning(number):\n    return status_codes.get(number)',
    demo = 'for code in [200, 301, 401, 404, 500, 999]:\n    print(f"status_code_meaning({code}) = {status_code_meaning(code)}")'
  ),
  list(
    name = "subset1.py",
    description = "<strong>subset1.py</strong> — Checks if smaller array is a subset of larger. O(N·M) — nested loops.",
    code = 'def is_subset(array1, array2):\n    if len(array1) > len(array2):\n        larger_array = array1\n        smaller_array = array2\n    else:\n        larger_array = array2\n        smaller_array = array1\n    for i in smaller_array:\n        found_match = False\n        for j in larger_array:\n            if i == j:\n                found_match = True\n                break\n        if not found_match:\n            return False\n    return True',
    demo = 'a1 = ["a","b","c","d","e","f"]\na2 = ["b","d","f"]\nprint(f"is_subset(a1, a2=[b,d,f]) = {is_subset(a1, a2)}")\na3 = ["b","d","h"]\nprint(f"is_subset(a1, a2=[b,d,h]) = {is_subset(a1, a3)}")'
  ),
  list(
    name = "subset2.py",
    description = "<strong>subset2.py</strong> — O(N) subset check using a hash table. Loads larger array into dict, then checks each element of smaller array in O(1).",
    code = 'def is_subset(array1, array2):\n    hash_table = {}\n    if len(array1) > len(array2):\n        larger_array = array1\n        smaller_array = array2\n    else:\n        larger_array = array2\n        smaller_array = array1\n    for value in larger_array:\n        hash_table[value] = True\n    for value in smaller_array:\n        if not hash_table.get(value):\n            return False\n    return True',
    demo = 'a1 = ["a","b","c","d","e","f"]\na2 = ["b","d","f"]\nprint(f"is_subset(a1, a2=[b,d,f]) = {is_subset(a1, a2)}")\na3 = ["b","d","h"]\nprint(f"is_subset(a1, a2=[b,d,h]) = {is_subset(a1, a3)}")'
  ),
  list(
    name = "solution1.py",
    description = "<strong>solution1.py</strong> — Array intersection using hash table. O(N+M) — two linear passes instead of nested loops.",
    code = 'def get_intersection(array1, array2):\n    intersection = []\n    hash_table = {}\n    for value in array1:\n        hash_table[value] = True\n    for value in array2:\n        if hash_table.get(value):\n            intersection.append(value)\n    return intersection',
    demo = 'print(f"get_intersection([1,2,3,4,5],[0,2,4,6,8]) = {get_intersection([1,2,3,4,5],[0,2,4,6,8])}")\nprint(f"get_intersection([],[]) = {get_intersection([],[])}")'
  ),
  list(
    name = "solution2.py",
    description = "<strong>solution2.py</strong> — Finds the first duplicate in an array using a hash table. O(N) — single pass.",
    code = 'def find_duplicate(array):\n    hash_table = {}\n    for value in array:\n        if hash_table.get(value):\n            return value\n        else:\n            hash_table[value] = True\n    return None',
    demo = 'print(f"find_duplicate([a,b,c,d,c,e,f]) = {find_duplicate([\"a\",\"b\",\"c\",\"d\",\"c\",\"e\",\"f\"])}")\nprint(f"find_duplicate([a,b,c,d,e,f])   = {find_duplicate([\"a\",\"b\",\"c\",\"d\",\"e\",\"f\"])}")'
  ),
  list(
    name = "solution4.py",
    description = "<strong>solution4.py</strong> — Finds the first non-duplicate character in a string. Two-pass O(N): count chars, then find first with count 1.",
    code = 'def first_non_duplicate(string):\n    hash_table = {}\n    for char in string:\n        if hash_table.get(char):\n            hash_table[char] += 1\n        else:\n            hash_table[char] = 1\n    for char in string:\n        if hash_table.get(char) == 1:\n            return char\n    return None',
    demo = 'print(f"first_non_duplicate(\\"minimum\\") = {first_non_duplicate(\"minimum\")}")\nprint(f"first_non_duplicate(\\"llamma\\")  = {first_non_duplicate(\"llamma\")}")\nprint(f"first_non_duplicate(\\"abcabc\\") = {first_non_duplicate(\"abcabc\")}")'
  )
)

chapter8_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(8, "#️⃣", "Blazing Fast Lookup with Hash Tables",
      "Hash tables provide O(1) lookups by mapping keys to memory addresses via a hash function. They transform many O(N) or O(N²) problems into O(N) solutions.",
      c("Hash Tables", "O(1) Lookup", "Collision Handling", "Sets", "Two-Pass Technique")),
    stats_row(list("O(1)","Hash Lookup"), list("O(N)","Hash Insert"),
              list("O(N)","Array→Hash"), list("~1","Load Factor Goal")),
    fluidRow(tabBox(width = 12, id = ns("tabs"),
      tabPanel(title = tagList(icon("book"), " Theory"),
        fluidRow(
          box(title = "#️⃣ How Hash Tables Work", status = "info", solidHeader = TRUE, width = 6,
              div(class = "framework-card", tags$h5("The Core Mechanism"),
                  tags$p("A hash function converts a key into an array index. The value is stored at that index. Lookup is O(1) because we compute the index directly."),
                  tags$ol(tags$li("key -> hash_function(key) -> integer"),
                          tags$li("integer % array_size -> index"),
                          tags$li("Store value at array[index]"))),
              div(class = "tip-box", HTML("<strong>💡 Collision:</strong> Two keys may hash to the same index. Solutions include <em>separate chaining</em> (linked list per slot) and <em>open addressing</em> (probe for next open slot)."))
          ),
          box(title = "🚀 if/elif vs Hash Table", status = "warning", solidHeader = TRUE, width = 6,
              tags$table(class = "algo-table",
                tags$thead(tags$tr(tags$th("Approach"), tags$th("Lookup Time"), tags$th("Add New Entry"))),
                tags$tbody(
                  tags$tr(tags$td("status_codes1 (if/elif)"), tags$td("O(N) worst case"), tags$td("Edit code")),
                  tags$tr(tags$td("status_codes2 (dict)"),    tags$td("O(1)"),            tags$td("dict[key] = val"))
                )
              ),
              div(class = "success-box", HTML("<strong>✅ Rule:</strong> Whenever you find yourself writing a long if/elif chain to look up values, consider replacing it with a hash table (Python dict)."))
          )
        ),
        fluidRow(
          box(title = "⚡ Hash Table Optimisation Pattern", status = "success", solidHeader = TRUE, width = 12,
              fluidRow(
                column(4, div(class = "framework-card", tags$h5("Step 1 — Load"),
                              tags$p("Iterate over the first array once, storing each value in a hash table. O(N)."))),
                column(4, div(class = "framework-card", tags$h5("Step 2 — Check"),
                              tags$p("Iterate over the second array once, checking hash table for each value. O(M)."))),
                column(4, div(class = "framework-card", tags$h5("Result — O(N+M)"),
                              tags$p("Two separate linear passes beats one nested O(N·M) loop every time for large data.")))
              ),
              div(class = "info-box-plain", HTML("<strong>ℹ Examples in code:</strong> subset2, solution1 (intersection), solution2 (find_duplicate), solution4 (first_non_duplicate) — all use this two-pass hash table pattern."))
          )
        )
      ),
      tabPanel(title = tagList(icon("code"), " Code Lab"),
        code_lab_header("Chapter 8 Code Files", "Hash table implementations: status codes, subset checking, intersection, duplicate finding, and missing letter detection."),
        file_pills_ui(ns, CH08_FILES),
        py_code_display(ns),
        terminal_ui(ns)
      )
    ))
  )
}

chapter8_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    code_lab_server(input, output, session, CH08_FILES)
  })
}
