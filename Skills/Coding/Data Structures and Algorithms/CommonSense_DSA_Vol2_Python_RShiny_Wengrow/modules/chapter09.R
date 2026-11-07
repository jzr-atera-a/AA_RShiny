# modules/chapter09.R — Monte Carlo Algorithms

CH09_FILES <- list(

  list(
    name = "prime1.py",
    description = "<strong>prime1.py</strong> — Naive primality test: trial division from 2 to N-1. O(N) per call. Correct but extremely slow for large numbers.",
    code = 'def is_prime(number):
    for i in range(2, number):
        if number % i == 0:
            return False
    return True',
    demo = 'import time
for n in [2, 17, 563, 7919, 104729]:
    t = time.time()
    result = is_prime(n)
    ms = (time.time() - t) * 1000
    print(f"is_prime({n:7}) = {result}  ({ms:.3f} ms)")'
  ),

  list(
    name = "prime2.py",
    description = "<strong>prime2.py</strong> — Improved: skip even numbers after checking 2, then trial-divide only odd numbers. Roughly 2x faster than prime1 — still O(N).",
    code = 'def is_prime(number):
    if number == 2:
        return True
    if number % 2 == 0:
        return False
    i = 3
    while i < number:
        if number % i == 0:
            return False
        i += 2
    return True',
    demo = 'import time
for n in [2, 17, 563, 7919, 104729]:
    t = time.time()
    result = is_prime(n)
    ms = (time.time() - t) * 1000
    print(f"is_prime({n:7}) = {result}  ({ms:.3f} ms)")'
  ),

  list(
    name = "prime3.py",
    description = "<strong>prime3.py</strong> — O(sqrt(N)) primality test: only test divisors up to sqrt(N). If N has a factor larger than sqrt(N), its partner is smaller. Vastly faster than prime1/prime2.",
    code = 'import math

def is_prime(number):
    if number == 2:
        return True
    if number % 2 == 0:
        return False
    i = 3
    while i <= math.sqrt(number):
        if number % i == 0:
            return False
        i += 2
    return True',
    demo = 'import math, time
for n in [2, 17, 563, 7919, 104729, 2147480219]:
    t = time.time()
    result = is_prime(n)
    ms = (time.time() - t) * 1000
    print(f"is_prime({n:12}) = {result}  ({ms:.4f} ms)")'
  ),

  list(
    name = "fpt.py",
    description = "<strong>fpt.py</strong> — Fermat's Primality Test (Monte Carlo algorithm). Uses Fermat's Little Theorem: if N is prime, a^(N-1) mod N = 1 for all a. Runs 100 random trials. O(log N) per trial via modular exponentiation. Can have false positives (Carmichael numbers) but probability is astronomically small.",
    code = 'import random

def is_prime(number):
    for _ in range(100):
        a = random.randint(1, number - 1)
        if pow(a, number - 1, number) != 1:
            return False
    return True',
    demo = 'import time

# Test small known primes and composites
tests = [(2,True),(17,True),(563,True),(2147480219,True),(4,False),(100,False),(561,True)]
print("Fermat Primality Test results:")
for n, expected in tests:
    result = is_prime(n)
    status = "OK" if result == expected else "NOTE: Carmichael number!"
    print(f"  is_prime({n:12}) = {result}  [{status}]")

# Speed comparison vs sqrt method
import math
def sqrt_prime(n):
    if n == 2: return True
    if n % 2 == 0: return False
    i = 3
    while i <= math.sqrt(n):
        if n % i == 0: return False
        i += 2
    return True

large = 2147480219
t = time.time()
for _ in range(100): sqrt_prime(large)
t1 = (time.time()-t)*1000
t = time.time()
for _ in range(100): is_prime(large)
t2 = (time.time()-t)*1000
print(f"\nFor N={large} (100 trials each):")
print(f"  sqrt method:   {t1:.2f} ms")
print(f"  Fermat (FPT):  {t2:.2f} ms")'
  ),

  list(
    name = "rs_mean.py",
    description = "<strong>rs_mean.py</strong> — Monte Carlo random sampling to estimate the mean of a large shuffled array. Instead of summing all 1,000,001 elements, sample 500 random elements and average them.",
    code = 'import random

array = list(range(1000001))
random.shuffle(array)

random_sample_size = 500
total = 0

for _ in range(random_sample_size):
    random_index = random.randint(0, 1000000)
    total += array[random_index]

estimated_mean = total // random_sample_size
print(f"Estimated mean (sample={random_sample_size}): {estimated_mean}")
print(f"True mean: {1000000 // 2}")
print(f"Error: {abs(estimated_mean - 500000)}")',
    demo = ''
  ),

  list(
    name = "rs_median.py",
    description = "<strong>rs_median.py</strong> — Monte Carlo random sampling to estimate the median. Sample 501 random elements, sort the sample, and take the middle. O(k log k) where k is sample size, vs O(N log N) for the exact answer.",
    code = 'import random

array = list(range(1000001))
random.shuffle(array)

random_sample_size = 501
random_sample = []

for _ in range(random_sample_size):
    random_index = random.randint(0, 1000000)
    random_sample.append(array[random_index])

random_sample.sort()
estimated_median = random_sample[random_sample_size // 2]

print(f"Estimated median (sample={random_sample_size}): {estimated_median}")
print(f"True median: 500000")
print(f"Error: {abs(estimated_median - 500000)}")',
    demo = ''
  )
)

chapter9_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(9, "\U0001f3b0", "Counting on Monte Carlo Algorithms",
      "Monte Carlo algorithms trade certainty for speed: they produce correct answers with high probability, not guaranteed correctness. Fermat's Primality Test can check a 300-digit number for primality in milliseconds \u2014 something deterministic O(sqrt(N)) methods could never achieve.",
      c("Monte Carlo vs Las Vegas", "Fermat's Little Theorem", "Primality Testing", "Random Sampling", "O(log N) per trial")),

    stats_row(
      list("O(log N)",  "FPT per trial"),
      list("100",       "Trials used"),
      list("~2^-100",   "Error probability"),
      list("Las Vegas", "Always correct")
    ),

    fluidRow(tabBox(width = 12, id = ns("tabs"),

      tabPanel(title = tagList(icon("book"), " Theory"),
        fluidRow(
          box(title = "\U0001f3b2 Monte Carlo vs Las Vegas Algorithms", status = "info", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                  tags$h5("Monte Carlo Algorithms"),
                  tags$p("Always fast, but may produce incorrect results with some (small) probability."),
                  tags$ul(
                    tags$li("Run time is", tags$strong("bounded"), "(always fast)"),
                    tags$li("Correctness is", tags$strong("probabilistic"), "(usually right)")
                  ),
                  tags$p(tags$strong("Examples:"), " Fermat's Primality Test, randomized hashing, random sampling")),
              div(class = "framework-card",
                  tags$h5("Las Vegas Algorithms"),
                  tags$p("Always produce the correct answer, but run time may vary."),
                  tags$ul(
                    tags$li("Correctness is", tags$strong("guaranteed"), "(always correct)"),
                    tags$li("Run time is", tags$strong("probabilistic"), "(usually fast)")
                  ),
                  tags$p(tags$strong("Examples:"), " Randomized Quicksort, randomized BST insertion")),
              div(class = "tip-box",
                  HTML("<strong>\U0001f4a1 Key insight:</strong> For problems where being wrong is catastrophic
                        (e.g. cryptography), use Las Vegas. For estimation problems where approximate
                        answers are fine (e.g. database statistics), Monte Carlo is ideal."))
          ),
          box(title = "\U0001f9ea Primality Testing Evolution", status = "warning", solidHeader = TRUE, width = 6,
              tags$table(class = "algo-table",
                tags$thead(tags$tr(tags$th("Algorithm"), tags$th("Time"), tags$th("Correct?"))),
                tags$tbody(
                  tags$tr(tags$td("prime1: trial 2..N"),    tags$td("O(N)"),      tags$td("Always \u2705")),
                  tags$tr(tags$td("prime2: odd trial"),     tags$td("O(N/2)"),    tags$td("Always \u2705")),
                  tags$tr(tags$td("prime3: up to sqrt(N)"), tags$td("O(\u221aN)"), tags$td("Always \u2705")),
                  tags$tr(tags$td("FPT: Fermat 100x"),      tags$td("O(k log N)"),tags$td("Prob. \u2705"))
                )
              ),
              div(class = "info-box-plain",
                  HTML("<strong>\u2139 Why FPT wins for large N:</strong><br>
                        For a 300-digit prime: sqrt(N) \u2248 10^150 steps (universe age in nanoseconds!)<br>
                        Fermat: 100 \u00d7 300 multiplications = microseconds.")),
              div(class = "framework-card",
                  tags$h5("Fermat's Little Theorem"),
                  tags$p("If N is prime, then for any a where 1 \u2264 a < N:"),
                  tags$p(tags$code("a^(N-1) mod N = 1")),
                  tags$p("So we pick 100 random values of a and verify this holds.
                          If any check fails, N is definitely composite.
                          If all 100 pass, N is prime with probability 1 \u2212 2^\u2212100."))
          )
        ),
        fluidRow(
          box(title = "\U0001f4ca Obtaining Averages Through Random Sampling", status = "success", solidHeader = TRUE, width = 12,
              fluidRow(
                column(6,
                  div(class = "framework-card",
                      tags$h5("rs_mean.py \u2014 Estimate the mean"),
                      tags$p("Instead of summing 1,000,001 elements (O(N)), sample 500 random elements
                              and average them. By the Law of Large Numbers, the sample mean converges
                              to the true mean."),
                      tags$p("Accuracy improves with sample size as O(1/\u221ak)."))),
                column(6,
                  div(class = "framework-card",
                      tags$h5("rs_median.py \u2014 Estimate the median"),
                      tags$p("Sample 501 random elements, sort the sample O(k log k), and take the middle.
                              For a 1M element array, this is ~100x faster than exact median with
                              only a small estimation error.")))
              ),
              div(class = "success-box",
                  HTML("<strong>\u2705 Real-world use:</strong> Database query planners (PostgreSQL, MySQL)
                        use random sampling to estimate statistics (cardinality, histograms) without
                        full-table scans. This is why EXPLAIN ANALYZE shows 'rows=...' estimates."))
          )
        )
      ),

      tabPanel(title = tagList(icon("code"), " Code Lab"),
        code_lab_header("Chapter 9 \u2014 Monte Carlo Algorithms",
          "Three deterministic primality algorithms (O(N), O(N/2), O(sqrt(N))), Fermat's Probabilistic Primality Test, and Monte Carlo random sampling for mean and median estimation."),
        file_pills_ui(ns, CH09_FILES),
        py_code_display(ns),
        terminal_ui(ns)
      )
    ))
  )
}

chapter9_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    code_lab_server(input, output, session, CH09_FILES)
  })
}
