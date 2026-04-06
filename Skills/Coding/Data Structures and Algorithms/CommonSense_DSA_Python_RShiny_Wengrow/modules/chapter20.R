# modules/chapter20.R — Techniques for Code Optimisation

CH20_FILES <- list(
  list(
    name = "books_authors1.py",
    description = "<strong>books_authors1.py</strong> — O(N·M) nested loops to join books with authors. The naive baseline — works, but slow for large datasets.",
    code = 'def connect_books_with_authors(books, authors):
    books_with_authors = []
    for book in books:
        for author in authors:
            if book["author_id"] == author["author_id"]:
                books_with_authors.append({
                    "title":  book["title"],
                    "author": author["name"]
                })
    return books_with_authors',
    demo = 'authors = [
    {"author_id": 1, "name": "Virginia Woolf"},
    {"author_id": 2, "name": "Leo Tolstoy"},
    {"author_id": 3, "name": "Dr. Seuss"}
]
books = [
    {"author_id": 3, "title": "Hop on Pop"},
    {"author_id": 1, "title": "Mrs. Dalloway"},
    {"author_id": 2, "title": "Anna Karenina"}
]
for b in connect_books_with_authors(books, authors):
    print(f"  {b[\"title\"]} — {b[\"author\"]}")'
  ),
  list(
    name = "books_authors2.py",
    description = "<strong>books_authors2.py</strong> — O(N+M) hash-table join. Load authors into a dict (O(M)), then look up each book's author in O(1). Same result, dramatically faster at scale.",
    code = 'def connect_books_with_authors(books, authors):
    books_with_authors = []
    author_hash_table  = {}

    for author in authors:
        author_hash_table[author["author_id"]] = author["name"]

    for book in books:
        books_with_authors.append({
            "title":  book["title"],
            "author": author_hash_table[book["author_id"]]
        })
    return books_with_authors',
    demo = 'authors = [
    {"author_id": 1, "name": "Virginia Woolf"},
    {"author_id": 2, "name": "Leo Tolstoy"},
    {"author_id": 3, "name": "Dr. Seuss"}
]
books = [
    {"author_id": 3, "title": "Hop on Pop"},
    {"author_id": 1, "title": "Mrs. Dalloway"},
    {"author_id": 2, "title": "Anna Karenina"}
]
for b in connect_books_with_authors(books, authors):
    print(f"  {b[\"title\"]} — {b[\"author\"]}")'
  ),
  list(
    name = "two_sum2.py",
    description = "<strong>two_sum2.py</strong> — O(N) two-sum using a hash table. For each number, checks if its complement (10 - value) was seen before. Single pass — no nested loop.",
    code = 'def two_sum(array):
    hash_table = {}

    for value in array:
        if hash_table.get(10 - value):   # Is the complement already seen?
            return True
        else:
            hash_table[value] = True     # Mark this value as seen

    return False',
    demo = 'print(f"two_sum([2,0,4,1,7,9]) = {two_sum([2,0,4,1,7,9])}  # 1+9=10")
print(f"two_sum([2,0,4,5,3,9]) = {two_sum([2,0,4,5,3,9])}  # no pair")
print(f"two_sum([5,5])         = {two_sum([5,5])}   # 5+5=10")'
  ),
  list(
    name = "largest_subsection.py",
    description = "<strong>largest_subsection.py</strong> — Kadane's Algorithm. Finds the maximum subarray sum in O(N) time, O(1) space. Resets the running sum when it goes negative.",
    code = 'def max_sum(array):
    current_sum  = 0
    greatest_sum = 0

    for num in array:
        if current_sum + num < 0:
            current_sum = 0          # Reset — negative prefix hurts us
        else:
            current_sum += num
            if current_sum > greatest_sum:
                greatest_sum = current_sum

    return greatest_sum',
    demo = 'cases = [
    ([3, -4, 4, -3, 5, -9],   6),
    ([1, 1, 0, -3, 5],         5),
    ([5, -2, 3, -8, 4],        6),
    ([2, -3, 1, 2, -1],        3),
]
for arr, expected in cases:
    result = max_sum(arr)
    mark   = "OK" if result == expected else "FAIL"
    print(f"  max_sum({arr}) = {result}  [{mark}]")'
  ),
  list(
    name = "stocks.py",
    description = "<strong>stocks.py</strong> — Detects an increasing triplet in O(N) time, O(1) space. Tracks the lowest and middle price seen so far; the first price above middle confirms the triplet.",
    code = 'def is_increasing_triplet(array):
    lowest_price = array[0]
    middle_price = float("inf")

    for price in array:
        if price <= lowest_price:
            lowest_price = price          # New lowest found
        elif price <= middle_price:
            middle_price = price          # New middle found
        else:
            return True                   # Found a value above middle!

    return False',
    demo = 'cases = [
    ([22, 25, 21, 18, 19.6, 17, 16, 20.5], True),
    ([5, 2, 8, 4, 3, 7],                   True),
    ([50, 51.25, 48.4, 49, 47.2, 48, 46.9], False),
]
for arr, expected in cases:
    result = is_increasing_triplet(arr)
    mark   = "OK" if result == expected else "FAIL"
    print(f"  is_increasing_triplet -> {result}  [{mark}]")'
  ),
  list(
    name = "anagrams2.py",
    description = "<strong>anagrams2.py</strong> — O(N+M) anagram check using two hash tables. Count character frequencies in each string, then compare the two dicts.",
    code = 'def are_anagrams(first_string, second_string):
    first_hash  = {}
    second_hash = {}

    for char in first_string:
        first_hash[char] = first_hash.get(char, 0) + 1

    for char in second_string:
        second_hash[char] = second_hash.get(char, 0) + 1

    return first_hash == second_hash',
    demo = 'pairs = [
    ("enraged", "angered", True),
    ("night",   "thing",   True),
    ("think",   "thing",   False),
    ("nigh",    "thing",   False),
]
for a, b, expected in pairs:
    result = are_anagrams(a, b)
    mark   = "OK" if result == expected else "FAIL"
    print(f"  are_anagrams({a!r}, {b!r}) = {result}  [{mark}]")'
  ),
  list(
    name = "solution3.py",
    description = "<strong>solution3.py</strong> — O(N) maximum stock profit. Tracks the lowest buy price seen so far; for each new price computes potential profit, updating the greatest profit found.",
    code = 'def find_greatest_profit(array):
    buy_price       = array[0]
    greatest_profit = 0

    for price in array:
        potential_profit = price - buy_price

        if price < buy_price:
            buy_price = price                           # Better buy opportunity
        elif potential_profit > greatest_profit:
            greatest_profit = potential_profit          # Better profit found

    return greatest_profit',
    demo = 'print(f"find_greatest_profit([10,7,5,8,11,2,6]) = {find_greatest_profit([10,7,5,8,11,2,6])}")
print(f"find_greatest_profit([5,4,3,2,1])       = {find_greatest_profit([5,4,3,2,1])}")'
  ),
  list(
    name = "solution4.py",
    description = "<strong>solution4.py</strong> — O(N) greatest product of two numbers. Tracks the two largest AND two smallest (for negative * negative) in a single pass — handles negative numbers correctly.",
    code = 'def greatest_product(array):
    greatest       = float("-inf")
    second_greatest= float("-inf")
    lowest         = float("inf")
    second_lowest  = float("inf")

    for number in array:
        if number >= greatest:
            second_greatest = greatest
            greatest        = number
        elif number > second_greatest:
            second_greatest = number

        if number <= lowest:
            second_lowest = lowest
            lowest        = number
        elif number < second_lowest:
            second_lowest = number

    from_top    = greatest * second_greatest
    from_bottom = lowest   * second_lowest

    return from_top if from_top > from_bottom else from_bottom',
    demo = 'print(f"greatest_product([5,-10,-6,9,4]) = {greatest_product([5,-10,-6,9,4])}")
print(f"greatest_product([1,2,3,4])      = {greatest_product([1,2,3,4])}")'
  ),
  list(
    name = "solution5.py",
    description = "<strong>solution5.py</strong> — O(N) temperature sort (a form of counting sort). Because temperatures are bounded 95–105°F, uses a hash table as frequency counter then reconstructs the sorted list.",
    code = 'def sort_temperatures(array):
    hash_table = {}

    for temperature in array:
        hash_table[temperature] = hash_table.get(temperature, 0) + 1

    sorted_temperatures = []
    temperature = 95

    while temperature <= 105:
        if temperature in hash_table:
            for _ in range(hash_table[temperature]):
                sorted_temperatures.append(temperature)
        temperature += 1

    return sorted_temperatures',
    demo = 'temps = [98, 99, 95, 105, 104, 98, 101, 99, 100, 97]
print(f"Input:  {temps}")
print(f"Sorted: {sort_temperatures(temps)}")'
  ),
  list(
    name = "solution6.py",
    description = "<strong>solution6.py</strong> — O(N) longest consecutive sequence using a hash set. Load all values; for each number that is a sequence START (no n-1 in set), walk the sequence forward counting length.",
    code = 'def longest_sequence_length(array):
    hash_table             = {}
    greatest_seq_length    = 0

    for number in array:
        hash_table[number] = True

    for number in array:
        if not hash_table.get(number - 1):       # Start of a sequence
            current_seq_length = 1
            current_number     = number

            while hash_table.get(current_number + 1):
                current_number     += 1
                current_seq_length += 1

            if current_seq_length > greatest_seq_length:
                greatest_seq_length = current_seq_length

    return greatest_seq_length',
    demo = 'print(f"longest_sequence_length([10,5,12,3,55,30,4,11,2]) = {longest_sequence_length([10,5,12,3,55,30,4,11,2])}")
print(f"longest_sequence_length([19,13,15,12,18,14,17,11])  = {longest_sequence_length([19,13,15,12,18,14,17,11])}")'
  ),
  list(
    name = "sum_swap.py",
    description = "<strong>sum_swap.py</strong> — O(N+M) array sum equaliser. Finds a pair of values (one from each array) to swap so both arrays have equal sums. Uses hash table for O(1) complement lookup.",
    code = 'def sum_swap(array_1, array_2):
    hash_table = {}
    sum_1 = sum_2 = 0

    for index, num in enumerate(array_1):
        sum_1 += num
        hash_table[num] = index

    for num in array_2:
        sum_2 += num

    if (sum_1 - sum_2) % 2 == 1:
        return None

    shift_amount = (sum_1 - sum_2) // 2

    for index, num in enumerate(array_2):
        if num + shift_amount in hash_table:
            return [hash_table[num + shift_amount], index]

    return None',
    demo = 'print(f"sum_swap([5,3,2,9,1],[1,12,5]) = {sum_swap([5,3,2,9,1],[1,12,5])}")
print(f"sum_swap([1,2,3,4,5],[6,7,8])   = {sum_swap([1,2,3,4,5],[6,7,8])}")
print(f"sum_swap([10],[5])              = {sum_swap([10],[5])}")'
  )
)

chapter20_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(20, "🏆", "Techniques for Code Optimisation",
      "The capstone chapter. Every optimisation in this book flows from five patterns: imagining the best-case Big O, recognising hash table opportunities, patterns for two-pointer walks, greedy algorithms, and changing data representation. These are applied to 10 real interview-style problems.",
      c("Hash Table Pattern", "Greedy Algorithms", "Two-Pointer", "Counting Sort", "O(N) Mastery")),
    stats_row(
      list("O(N)",   "books_authors2"),
      list("O(N)",   "Kadane's Algorithm"),
      list("O(N)",   "Longest Sequence"),
      list("5",      "Optimisation Patterns")
    ),
    fluidRow(
      tabBox(width = 12, id = ns("tabs"),
        tabPanel(title = tagList(icon("book"), " Theory"),
          fluidRow(
            box(title = "🏆 The Five Optimisation Patterns", status = "info", solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("1. Imagine the best-case Big O"),
                    tags$p("Ask: what is the theoretical minimum number of steps to solve this?
                            If you need to read every element, O(N) is the floor. Design toward it.")),
                div(class = "framework-card",
                    tags$h5("2. Hash table for O(1) lookup"),
                    tags$p("Any time you have a nested search ('find X in Y'), ask: can I load
                            one set into a hash table and look up the other in O(1)? This converts
                            O(N²) → O(N+M) for join-style problems.")),
                div(class = "framework-card",
                    tags$h5("3. Two-pointer / sliding window"),
                    tags$p("For sorted arrays or contiguous sub-problems, two pointers marching
                            inward (or a window sliding right) avoid the nested-loop trap.")),
                div(class = "framework-card",
                    tags$h5("4. Greedy — track running best"),
                    tags$p("Keep track of the best value seen so far (min, max, profit, sum).
                            Many O(N²) 'compare all pairs' problems collapse to O(N) this way.")),
                div(class = "framework-card",
                    tags$h5("5. Change the data representation"),
                    tags$p("Sorting, grouping by hash, or counting frequencies can make previously
                            hard operations trivially fast."))
            ),
            box(title = "📊 Problems & Their Optimal Solutions", status = "warning", solidHeader = TRUE, width = 6,
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(tags$th("Problem"), tags$th("Naïve"), tags$th("Optimal"), tags$th("Pattern"))),
                  tags$tbody(
                    tags$tr(tags$td("books_authors join"),    tags$td("O(N·M)"),   tags$td("O(N+M)"),   tags$td("Hash table")),
                    tags$tr(tags$td("two_sum"),               tags$td("O(N²)"),    tags$td("O(N)"),     tags$td("Hash complement")),
                    tags$tr(tags$td("max subarray sum"),      tags$td("O(N²)"),    tags$td("O(N)"),     tags$td("Kadane's greedy")),
                    tags$tr(tags$td("increasing triplet"),    tags$td("O(N³)"),    tags$td("O(N)"),     tags$td("Track lo/mid")),
                    tags$tr(tags$td("anagram check"),         tags$td("O(N·M)"),   tags$td("O(N+M)"),   tags$td("Freq hash tables")),
                    tags$tr(tags$td("max stock profit"),      tags$td("O(N²)"),    tags$td("O(N)"),     tags$td("Running min buy")),
                    tags$tr(tags$td("greatest product ×2"),   tags$td("O(N²)"),    tags$td("O(N)"),     tags$td("Track top/bottom 2")),
                    tags$tr(tags$td("sort temperatures"),     tags$td("O(N log N)"),tags$td("O(N)"),    tags$td("Counting sort")),
                    tags$tr(tags$td("longest sequence"),      tags$td("O(N²)"),    tags$td("O(N)"),     tags$td("Hash + only start"))
                  )
                )
            )
          ),
          fluidRow(
            box(title = "🌟 Kadane's Algorithm — Maximum Subarray", status = "success", solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("The problem"),
                    tags$p("Given an array, find the contiguous subarray with the largest sum.
                            Naïve: check every (i,j) pair = O(N²). Kadane's: O(N)."),
                    tags$p(tags$strong("Key insight:"), " if the running sum goes negative, discard it —
                            a negative prefix can never help any future subarray.")
                ),
                div(class = "info-box-plain",
                    HTML("<strong>ℹ Example:</strong> [3, -4, 4, -3, 5, -9]<br>
                          Running sum: 3, 0(reset), 4, 1, 6, 0(reset) → best = 6"))
            ),
            box(title = "🔢 Counting Sort — O(N) for bounded ranges", status = "danger", solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("The idea"),
                    tags$p("If values are from a", tags$strong("bounded integer range"),
                           "(e.g. temperatures 95–105°F), count frequency in a hash table,
                           then emit each value its count times in order."),
                    tags$p("This achieves O(N) sort — beating the O(N log N) comparison-sort lower bound!"),
                    div(class = "warn-box",
                        HTML("<strong>⚠ Limitation:</strong> Only works when the range of values is
                              small and known. For arbitrary inputs, O(N log N) is still the best
                              general sort."))
                )
            )
          )
        ),
        tabPanel(title = tagList(icon("code"), " Code Lab"),
          code_lab_header(
            "Chapter 20 — Advanced Optimisation Techniques",
            "10 classic problems each solved optimally: hash-table joins, O(N) two-sum, Kadane's max-subarray, increasing triplet, anagram check, max stock profit, greatest product, counting sort, longest sequence, and sum swap."
          ),
          file_pills_ui(ns, CH20_FILES),
          py_code_display(ns),
          terminal_ui(ns)
        )
      )
    )
  )
}

chapter20_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    code_lab_server(input, output, session, CH20_FILES)
  })
}
