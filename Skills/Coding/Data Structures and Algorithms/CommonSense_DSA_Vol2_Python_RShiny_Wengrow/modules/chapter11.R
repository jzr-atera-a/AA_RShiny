# modules/chapter11.R — Rabin-Karp Substring Search

CH11_FILES <- list(

  list(
    name = "brute_force_substring_search.py",
    description = "<strong>brute_force_substring_search.py</strong> — O(N*M) brute-force substring search. For every position in the haystack, compare all M characters of the needle. Simple but slow: worst case checks N*M character pairs.",
    code = 'def find_needle(haystack, needle):
    for haystack_index in range(len(haystack) - len(needle) + 1):
        for needle_index in range(len(needle)):
            if needle[needle_index] != haystack[haystack_index + needle_index]:
                break
            if needle_index == len(needle) - 1:
                return haystack_index
    return None',
    demo = 'tests = [
    ("flibbertigib",    "be",  4),
    ("flibbertigibbet", "bet", 12),
    ("flibbertigibbet", "fla", None),
    ("abcdef",          "a",   0),
]
for haystack, needle, expected in tests:
    result = find_needle(haystack, needle)
    status = "OK" if result == expected else "FAIL"
    print(f"  [{status}] find_needle({haystack!r}, {needle!r}) = {result}")'
  ),

  list(
    name = "sliding_window.py",
    description = "<strong>sliding_window.py</strong> — Sliding window technique: compute the sum of the first window of 4 integers, then slide one step at a time \u2014 add the new element, drop the old one. O(N) instead of O(N*W) for the naive approach.",
    code = 'def max_sum_of_four_integers(array):
    current_window_sum = sum(array[:4])
    max_sum_so_far     = current_window_sum

    for i in range(4, len(array)):
        current_window_sum += array[i]
        current_window_sum -= array[i - 4]
        max_sum_so_far = max(max_sum_so_far, current_window_sum)

    return max_sum_so_far',
    demo = 'arr = [3, 2, 7, 4, 6, 3, 5, 8]
print(f"Array: {arr}")
print(f"Max sum of 4 consecutive: {max_sum_of_four_integers(arr)}")
print("Windows: [3,2,7,4]=16  [2,7,4,6]=19  [7,4,6,3]=20  [4,6,3,5]=18  [6,3,5,8]=22")
print("Answer: 22 (last window [6,3,5,8])")'
  ),

  list(
    name = "rabin_karp_1.py",
    description = "<strong>rabin_karp_1.py</strong> — Rabin-Karp v1 using base-10 rolling hash. Converts each character to a digit (a=0, b=1 ...) and hashes the window as a polynomial in base 10. Rolling hash updates in O(1): drop old char, shift, add new char.",
    code = 'def find_needle(haystack, needle):
    needle_hash  = initial_hash(needle)
    window_hash  = initial_hash(haystack[:len(needle)])

    if needle_hash == window_hash:
        return 0

    for i in range(1, len(haystack) - len(needle) + 1):
        window_hash = rolling_hash(window_hash, len(needle),
                                   haystack[i - 1],
                                   haystack[i - 1 + len(needle)])
        if needle_hash == window_hash:
            return i
    return None


def initial_hash(string):
    power  = 0
    result = 0
    for char in reversed(string):
        result += character_hash_code(char) * 10**power
        power  += 1
    return result


def rolling_hash(hash_code, window_length, drop_character, new_character):
    drop_number  = character_hash_code(drop_character) * 10**(window_length - 1)
    result       = hash_code - drop_number
    result      *= 10
    result      += character_hash_code(new_character)
    return result


def character_hash_code(char):
    return ord(char) - 97',
    demo = 'tests = [
    ("flibbertigib",    "be",  4),
    ("flibbertigibbet", "bet", 12),
    ("flibbertigibbet", "fla", None),
]
for haystack, needle, expected in tests:
    result = find_needle(haystack, needle)
    status = "OK" if result == expected else "FAIL"
    print(f"  [{status}] find_needle({haystack!r}, {needle!r}) = {result}")'
  ),

  list(
    name = "rabin_karp_2.py",
    description = "<strong>rabin_karp_2.py</strong> — Rabin-Karp v2 using base-26 (one slot per letter). Reduces hash collisions vs base-10. Still uses large intermediate numbers \u2014 the next version fixes this with modular arithmetic.",
    code = 'base = 26

def find_needle(haystack, needle):
    needle_hash = initial_hash(needle)
    window_hash = initial_hash(haystack[:len(needle)])

    if needle_hash == window_hash:
        return 0

    for i in range(1, len(haystack) - len(needle) + 1):
        window_hash = rolling_hash(window_hash, len(needle),
                                   haystack[i - 1],
                                   haystack[i - 1 + len(needle)])
        if needle_hash == window_hash:
            return i
    return None


def initial_hash(string):
    power  = 0
    result = 0
    for char in reversed(string):
        result += character_hash_code(char) * base**power
        power  += 1
    return result


def rolling_hash(hash_code, window_length, drop_character, new_character):
    drop_number  = character_hash_code(drop_character) * base**(window_length - 1)
    result       = hash_code - drop_number
    result      *= base
    result      += character_hash_code(new_character)
    return result


def character_hash_code(char):
    return ord(char) - 97',
    demo = 'tests = [
    ("heyhowsitgoingsweet", "go",  9),
    ("heyhowsitgoingsweet", "hey", 0),
    ("heyhowsitgoingsweet", "eet", 16),
    ("heyhowsitgoingsweet", "fla", None),
]
for haystack, needle, expected in tests:
    result = find_needle(haystack, needle)
    status = "OK" if result == expected else "FAIL"
    print(f"  [{status}] find_needle(..., {needle!r}) = {result}")'
  ),

  list(
    name = "rabin_karp_3.py",
    description = "<strong>rabin_karp_3.py</strong> — Rabin-Karp v3: final production version. Uses modular arithmetic (prime=613) to keep hash values small, preventing integer overflow. Includes a Las Vegas sanity check: when hashes match, verify the actual substring to eliminate false positives.",
    code = 'base  = 26
prime = 613

def find_needle(haystack, needle):
    needle_hash = initial_hash(needle)
    window_hash = initial_hash(haystack[:len(needle)])

    if needle_hash == window_hash:
        return 0

    # Precompute drop_place_remainder = base^(len-1) % prime
    drop_place_remainder = 1
    for _ in range(len(needle) - 1):
        drop_place_remainder = (drop_place_remainder * base) % prime

    for i in range(1, len(haystack) - len(needle) + 1):
        window_hash = rolling_hash(window_hash,
                                   haystack[i - 1],
                                   haystack[i - 1 + len(needle)],
                                   drop_place_remainder)
        if needle_hash == window_hash:
            # Las Vegas check: confirm actual match to rule out false positives
            if needle == haystack[i:(i + len(needle))]:
                return i
    return None


def initial_hash(string):
    result = character_hash_code(string[0]) % prime
    for i in range(1, len(string)):
        result = (result * base + character_hash_code(string[i])) % prime
    return result


def rolling_hash(hash_code, drop_character, new_character, drop_place_remainder):
    result = ((hash_code + prime
               - character_hash_code(drop_character) * drop_place_remainder)
              * base + character_hash_code(new_character)) % prime
    return result


def character_hash_code(char):
    return ord(char) - 97',
    demo = 'import time

tests = [
    ("heyhowsitgoingsweet", "go",  9),
    ("heyhowsitgoingsweet", "hey", 0),
    ("heyhowsitgoingsweet", "eet", 16),
    ("lklklklklklk",        "ma",  None),
]
for haystack, needle, expected in tests:
    result = find_needle(haystack, needle)
    status = "OK" if result == expected else "FAIL"
    print(f"  [{status}] find_needle(..., {needle!r}) = {result}")

# Performance on a longer string
import random, string
big = "".join(random.choices(string.ascii_lowercase, k=100000))
needle = "xyz"
t = time.time()
find_needle(big, needle)
ms = (time.time()-t)*1000
print(f"\nSearch for {needle!r} in 100k-char string: {ms:.2f} ms")'
  ),

  list(
    name = "solution_3.py",
    description = "<strong>solution_3.py</strong> — Sliding window solution: find the length of the longest substring without repeating characters. Maintains a variable-size window using left/right pointers and a set of current chars. O(N) time, O(min(N,alphabet)) space.",
    code = 'def length_of_longest_substring(string):
    if not string:
        return 0

    left  = 0
    right = 0
    max_distance_so_far = 0
    current_window_chars = {}

    while right < len(string):
        if string[right] not in current_window_chars:
            current_window_chars[string[right]] = True
            max_distance_so_far = max(max_distance_so_far, right - left)
            right += 1
        else:
            del current_window_chars[string[left]]
            left += 1

    return max_distance_so_far + 1',
    demo = 'tests = [("abcabcbb", 3), ("bbbbb", 1), ("pwwkew", 3), ("", 0), ("abcdef", 6)]
for s, expected in tests:
    result = length_of_longest_substring(s)
    status = "OK" if result == expected else "FAIL"
    print(f"  [{status}] longest_no_repeat({s!r}) = {result}  (expected {expected})")'
  )
)

chapter11_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(11, "\U0001f50d", "Keeping Your Text Search Sharp with Rabin-Karp",
      "Substring search appears in every text editor, search engine, and DNA sequencer. The Rabin-Karp algorithm uses a rolling hash to slide a window across the haystack in O(N+M) time, turning O(M) comparisons per position into O(1) hash comparisons.",
      c("Brute-Force O(N*M)", "Sliding Window", "Rolling Hash", "Rabin-Karp O(N+M)", "Las Vegas Verification", "Base-26 + Modular")),

    stats_row(
      list("O(N*M)", "Brute force"),
      list("O(N+M)", "Rabin-Karp"),
      list("O(1)",   "Rolling hash update"),
      list("613",    "Prime modulus")
    ),

    fluidRow(tabBox(width = 12, id = ns("tabs"),

      tabPanel(title = tagList(icon("book"), " Theory"),
        fluidRow(
          box(title = "\U0001f50d Substring Search", status = "info", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                  tags$h5("The Problem"),
                  tags$p("Find the first occurrence of a", tags$strong("needle"), "(pattern) in a",
                         tags$strong("haystack"), "(text). N = |haystack|, M = |needle|.")),
              div(class = "framework-card",
                  tags$h5("Brute-Force: O(N*M)"),
                  tags$p("For every position i in the haystack (N positions), compare the needle
                          character-by-character (M comparisons each). Worst case: 'aaaaa...b' needle
                          in 'aaaaa...a' haystack \u2014 N*M comparisons.")),
              div(class = "framework-card",
                  tags$h5("Sliding Window Technique"),
                  tags$p("Instead of recomputing from scratch at each position, maintain a running
                          aggregate (sum, hash) as the window slides. Add new element, drop old element.
                          Each slide is O(1) instead of O(M)."))),

          box(title = "\U0001f500 The Rolling Hash", status = "warning", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                  tags$h5("Key insight: hash in O(1) per slide"),
                  tags$p("Represent each window as a polynomial:"),
                  tags$p(tags$code("hash('abc') = a*26^2 + b*26^1 + c*26^0")),
                  tags$p("When sliding one position right (dropping 'a', adding 'd'):"),
                  tags$p(tags$code("new_hash = (old_hash - a*26^(M-1)) * 26 + d")),
                  tags$p("This is O(1) \u2014 no matter how long the needle.")),
              div(class = "success-box",
                  HTML("<strong>\u2705 Result:</strong> N windows \u00d7 O(1) hash update = O(N) total.
                        Plus O(M) for the initial hash = O(N+M) overall.")),
              div(class = "tip-box",
                  HTML("<strong>\U0001f4a1 Why modular arithmetic?</strong> Without it, hash values for
                        long needles become astronomically large (26^100 has 140 digits!).
                        Taking mod a prime keeps values bounded while preserving distribution.")))
        ),
        fluidRow(
          box(title = "\U0001f9ea Rabin-Karp v3: The Complete Algorithm", status = "success", solidHeader = TRUE, width = 12,
              fluidRow(
                column(6,
                  div(class = "framework-card",
                      tags$h5("Three improvements from v1 to v3"),
                      tags$ol(
                        tags$li(tags$strong("Base 10 \u2192 Base 26:"), " one slot per letter, fewer collisions"),
                        tags$li(tags$strong("Add modular arithmetic:"), " mod prime 613 prevents overflow"),
                        tags$li(tags$strong("Las Vegas check:"), " on hash match, verify actual substring to eliminate false positives")
                      ))),
                column(6,
                  div(class = "framework-card",
                      tags$h5("False Positive Problem"),
                      tags$p("Two different substrings can share the same hash (collision). Without verification,
                              Rabin-Karp would report false matches."),
                      tags$p("The Las Vegas fix: when hashes match, do an O(M) character-by-character check.
                              This only costs O(M) on the", tags$em("true"), "match position, not everywhere.")),
                  div(class = "info-box-plain",
                      HTML("<strong>\u2139 Real-world use:</strong> Rabin-Karp shines for multi-pattern search
                            (grep -F) \u2014 hash all needles into a set, then check each window hash against the set
                            in O(1). Python's built-in <code>str.find()</code> uses a similar approach.")))
              )
          )
        )
      ),

      tabPanel(title = tagList(icon("code"), " Code Lab"),
        code_lab_header("Chapter 11 \u2014 Rabin-Karp Substring Search",
          "Brute-force search, sliding window technique, Rabin-Karp v1 (base 10), v2 (base 26), v3 (modular + Las Vegas), and longest non-repeating substring."),
        file_pills_ui(ns, CH11_FILES),
        py_code_display(ns),
        terminal_ui(ns)
      )
    ))
  )
}

chapter11_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    code_lab_server(input, output, session, CH11_FILES)
  })
}
