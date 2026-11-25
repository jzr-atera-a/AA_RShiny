# Practice bank — arrays, strings and hashing.
# Field reference: see build_bank.py. Statements are Markdown.

PROBLEMS = [
dict(
    id="lc1", num=1, title="Two Sum", slug="two-sum", difficulty="Easy", topic="hashing",
    pattern="Hash map complement", companies=["Meta", "Google"],
    kind="function", cls="Solution", method="twoSum",
    params=[{"name": "nums", "type": "int[]"}, {"name": "target", "type": "int"}], returns="int[]",
    compare="custom",
    statement="""Given an integer array `nums` and an integer `target`, return the **indices of two different elements** whose values add up to `target`.

Each input has at least one valid pair. Any valid pair is accepted, in either order.""",
    constraints=["2 ≤ nums.length ≤ 10⁵", "−10⁹ ≤ nums[i], target ≤ 10⁹", "At least one valid answer exists."],
    examples=[
        dict(args=[[2, 7, 11, 15], 9], expected=[0, 1], explanation="nums[0] + nums[1] = 2 + 7 = 9."),
        dict(args=[[3, 2, 4], 6], expected=[1, 2]),
        dict(args=[[3, 3], 6], expected=[0, 1]),
    ],
    hidden=[dict(args=[[-3, 4, 3, 90], 0]), dict(args=[[0, 4, 3, 0], 0]), dict(args=[[1, 5], 6])],
    starter='''class Solution:
    def twoSum(self, nums: List[int], target: int) -> List[int]:
        pass
''',
    reference='''class Solution:
    def twoSum(self, nums, target):
        seen = {}
        for i, x in enumerate(nums):
            if target - x in seen:
                return [seen[target - x], i]
            seen[x] = i

def check(args, got, expected):
    nums, target = args
    if not isinstance(got, list) or len(got) != 2:
        return False
    i, j = got
    if not all(isinstance(v, int) and not isinstance(v, bool) for v in (i, j)):
        return False
    return i != j and 0 <= i < len(nums) and 0 <= j < len(nums) and nums[i] + nums[j] == target
''',
    brute='''class Solution:
    def twoSum(self, nums, target):
        for i in range(len(nums)):
            for j in range(i + 1, len(nums)):
                if nums[i] + nums[j] == target:
                    return [i, j]
''',
    small_gen='''def gen(rng):
    n = rng.randint(2, 8)
    nums = [rng.randint(-10, 10) for _ in range(n)]
    i, j = rng.sample(range(n), 2)
    return [nums, nums[i] + nums[j]]
''',
    gens=[dict(name="Large input (n = 100,000)", code='''def gen(rng):
    n = 100000
    nums = rng.sample(range(-10**9, 10**9), n)
    i, j = n - 2, n - 1
    return [nums, nums[i] + nums[j]]
''')],
    hints=["A brute force checks every pair: O(n²). Which inner loop can you remove?",
           "For each x you need target − x. Can you look that up in O(1)?",
           "Check the map before inserting x, so an element is never paired with itself."],
    approach="""**Hash map of values seen so far.** Walk the array once. For each `x` at index `i`, the partner you need is `target − x`. If it is already in the map, return both indices; otherwise record `x ↦ i`.

Checking before inserting guarantees the two indices differ.""",
    complexity="O(n) time · O(n) space",
    followups=["What if the array is sorted? (Two pointers, O(1) space.)",
               "What if the numbers arrive as a stream and you must answer 'is there a pair for target T?' many times?",
               "Return every pair that sums to the target, without duplicates."],
),

dict(
    id="lc680", num=680, title="Valid Palindrome II", slug="valid-palindrome-ii", difficulty="Easy", topic="arrays",
    pattern="Two pointers with one skip", companies=["Meta"],
    kind="function", cls="Solution", method="validPalindrome",
    params=[{"name": "s", "type": "str"}], returns="bool",
    statement="""Given a string `s`, return `true` if it can become a palindrome after deleting **at most one** character.""",
    constraints=["1 ≤ s.length ≤ 10⁵", "s consists of lowercase English letters."],
    examples=[
        dict(args=["aba"], expected=True),
        dict(args=["abca"], expected=True, explanation="Delete 'c' (or 'b')."),
        dict(args=["abc"], expected=False),
    ],
    hidden=[dict(args=["a"]), dict(args=["deeee"]), dict(args=["eeccccbebaeeabebccceea"]), dict(args=["cbbcc"]), dict(args=["ab"])],
    starter='''class Solution:
    def validPalindrome(self, s: str) -> bool:
        pass
''',
    reference='''class Solution:
    def validPalindrome(self, s):
        def is_pal(i, j):
            while i < j:
                if s[i] != s[j]:
                    return False
                i += 1; j -= 1
            return True
        i, j = 0, len(s) - 1
        while i < j:
            if s[i] != s[j]:
                return is_pal(i + 1, j) or is_pal(i, j - 1)
            i += 1; j -= 1
        return True
''',
    brute='''class Solution:
    def validPalindrome(self, s):
        if s == s[::-1]:
            return True
        for k in range(len(s)):
            t = s[:k] + s[k + 1:]
            if t == t[::-1]:
                return True
        return False
''',
    small_gen='''def gen(rng):
    n = rng.randint(1, 9)
    half = "".join(rng.choice("ab") for _ in range(n // 2))
    s = half + (rng.choice("ab") if n % 2 else "") + half[::-1]
    if rng.random() < 0.7 and s:
        k = rng.randrange(len(s) + 1)
        s = s[:k] + rng.choice("abc") + s[k:]
    if rng.random() < 0.3:
        s = "".join(rng.choice("abc") for _ in range(n))
    return [s or "a"]
''',
    gens=[dict(name="Long string with one extra character", code='''def gen(rng):
    half = "".join(rng.choice("ab") for _ in range(50000))
    s = half + half[::-1]
    k = 70000
    return [s[:k] + "z" + s[k:]]
''')],
    hints=["Compare characters from both ends with two pointers.",
           "At the first mismatch you have exactly two choices: skip the left character or skip the right one.",
           "After that one skip, the rest must be a plain palindrome — no more skips allowed."],
    approach="""Move two pointers inwards while characters match. At the **first mismatch** `s[i] ≠ s[j]`, the deleted character must be one of these two, so check whether `s[i+1..j]` or `s[i..j−1]` is a palindrome.

Trying every deletion is O(n²); this needs at most two extra linear scans.""",
    complexity="O(n) time · O(1) space",
    followups=["Allow up to k deletions (Valid Palindrome III — becomes DP on the longest palindromic subsequence).",
               "Return the index to delete instead of true / false.",
               "Ignore non-alphanumeric characters and case, as in Valid Palindrome (#125)."],
),

dict(
    id="lc408", num=408, title="Valid Word Abbreviation", slug="valid-word-abbreviation", difficulty="Easy", topic="arrays",
    pattern="Two pointers / parsing", companies=["Meta"],
    kind="function", cls="Solution", method="validWordAbbreviation",
    params=[{"name": "word", "type": "str"}, {"name": "abbr", "type": "str"}], returns="bool",
    statement="""A string can be abbreviated by replacing any number of **non-adjacent, non-empty** substrings with their lengths. Lengths must not have leading zeros.

For example `"substitution"` can be written `"s10n"`, `"sub4u4"` or `"12"`, but not `"s010n"` (leading zero) or `"s0ubstitution"` (empty replacement).

Given `word` and `abbr`, return `true` if `abbr` is a valid abbreviation of `word`.""",
    constraints=["1 ≤ word.length ≤ 10⁵", "1 ≤ abbr.length ≤ 10⁵", "word is lowercase letters; abbr is lowercase letters and digits."],
    examples=[
        dict(args=["internationalization", "i12iz4n"], expected=True),
        dict(args=["apple", "a2e"], expected=False, explanation="'a' + 2 letters lands on 'l', not 'e'."),
    ],
    hidden=[dict(args=["substitution", "s010n"], expected=False), dict(args=["a", "01"], expected=False),
            dict(args=["word", "4"], expected=True), dict(args=["word", "5"], expected=False),
            dict(args=["hi", "2i"], expected=False), dict(args=["a", "2"], expected=False),
            dict(args=["abbreviation", "a10n"], expected=True), dict(args=["abc", "abc"], expected=True)],
    starter='''class Solution:
    def validWordAbbreviation(self, word: str, abbr: str) -> bool:
        pass
''',
    reference='''class Solution:
    def validWordAbbreviation(self, word, abbr):
        i = j = 0
        while i < len(word) and j < len(abbr):
            if abbr[j].isdigit():
                if abbr[j] == "0":
                    return False
                num = 0
                while j < len(abbr) and abbr[j].isdigit():
                    num = num * 10 + int(abbr[j])
                    j += 1
                i += num
            else:
                if word[i] != abbr[j]:
                    return False
                i += 1; j += 1
        return i == len(word) and j == len(abbr)
''',
    brute='''import re
class Solution:
    def validWordAbbreviation(self, word, abbr):
        tokens = re.findall(r"[a-z]|[0-9]+", abbr)
        pattern = ""
        for t in tokens:
            if t.isdigit():
                if t[0] == "0":
                    return False
                pattern += "." * int(t)
            else:
                pattern += t
        return len(pattern) == len(word) and re.fullmatch(pattern, word) is not None
''',
    small_gen='''def gen(rng):
    n = rng.randint(1, 8)
    word = "".join(rng.choice("ab") for _ in range(n))
    out, i = "", 0
    while i < n:
        if rng.random() < 0.4 and (not out or not out[-1].isdigit()):
            k = rng.randint(1, n - i)
            out += str(k); i += k
        else:
            out += word[i]; i += 1
    r = rng.random()
    if r < 0.15:
        out = out.replace("1", "01", 1)
    elif r < 0.3 and out:
        k = rng.randrange(len(out))
        out = out[:k] + rng.choice("ab12") + out[k + 1:]
    elif r < 0.4:
        out = "".join(rng.choice("ab123") for _ in range(rng.randint(1, 5)))
    return [word, out]
''',
    hints=["Walk both strings with two pointers.",
           "When you meet a digit in abbr, read the whole number, then jump the word pointer forward by that many.",
           "Reject a number that starts with '0'. At the end, both pointers must be exactly at the ends."],
    approach="""Two pointers: `i` over `word`, `j` over `abbr`. Letters must match one-for-one. A run of digits is parsed into a number `k` (rejecting a leading `0`) and moves `i` forward by `k`. The abbreviation is valid only if both pointers finish exactly at the end of their strings.""",
    complexity="O(len(abbr)) time · O(1) space",
    followups=["What if uppercase letters in abbr may match any letter (wildcards)?",
               "Generate every valid abbreviation of a word (Generalized Abbreviation, #320).",
               "Check one abbreviation against a dictionary of words efficiently."],
),

dict(
    id="lc3", num=3, title="Longest Substring Without Repeating Characters", slug="longest-substring-without-repeating-characters",
    difficulty="Medium", topic="arrays", pattern="Sliding window", companies=["Meta", "Google"],
    kind="function", cls="Solution", method="lengthOfLongestSubstring",
    params=[{"name": "s", "type": "str"}], returns="int",
    statement="""Given a string `s`, return the length of the longest **substring** (contiguous) that contains no repeated characters.""",
    constraints=["0 ≤ s.length ≤ 5 · 10⁴", "s may contain letters, digits, symbols and spaces."],
    examples=[
        dict(args=["abcabcbb"], expected=3, explanation="'abc'"),
        dict(args=["bbbbb"], expected=1),
        dict(args=["pwwkew"], expected=3, explanation="'wke'. Note 'pwke' is a subsequence, not a substring."),
    ],
    hidden=[dict(args=[""]), dict(args=[" "]), dict(args=["dvdf"]), dict(args=["abba"]), dict(args=["tmmzuxt"])],
    starter='''class Solution:
    def lengthOfLongestSubstring(self, s: str) -> int:
        pass
''',
    reference='''class Solution:
    def lengthOfLongestSubstring(self, s):
        last = {}
        left = best = 0
        for right, ch in enumerate(s):
            if ch in last and last[ch] >= left:
                left = last[ch] + 1
            last[ch] = right
            best = max(best, right - left + 1)
        return best
''',
    brute='''class Solution:
    def lengthOfLongestSubstring(self, s):
        best = 0
        for i in range(len(s)):
            for j in range(i, len(s)):
                if len(set(s[i:j + 1])) == j - i + 1:
                    best = max(best, j - i + 1)
        return best
''',
    small_gen='''def gen(rng):
    return ["".join(rng.choice("abcd ") for _ in range(rng.randint(0, 10)))]
''',
    gens=[dict(name="Long string, large alphabet", code='''def gen(rng):
    alphabet = [chr(c) for c in range(32, 127)]
    return ["".join(rng.choice(alphabet) for _ in range(50000))]
''')],
    hints=["Keep a window [left, right] that never contains a repeat.",
           "When s[right] is already inside the window, move left just past its previous position.",
           "Store the last index of each character so the jump is O(1)."],
    approach="""**Variable-size sliding window.** Extend `right` one step at a time. If the new character was last seen at an index ≥ `left`, it is inside the window, so jump `left` to one past that index. The window is always repeat-free; track the largest width.

Each index enters and leaves the window at most once.""",
    complexity="O(n) time · O(min(n, alphabet)) space",
    followups=["At most k distinct characters (#340).", "At most two repeats of any character.",
               "Return the substring itself, and all substrings of maximal length."],
),

dict(
    id="lc76", num=76, title="Minimum Window Substring", slug="minimum-window-substring", difficulty="Hard", topic="arrays",
    pattern="Sliding window with counts", companies=["Meta", "Google"],
    kind="function", cls="Solution", method="minWindow",
    params=[{"name": "s", "type": "str"}, {"name": "t", "type": "str"}], returns="str", compare="custom",
    statement="""Given strings `s` and `t`, return the **shortest substring of `s`** that contains every character of `t`, including duplicates. If no such substring exists, return `""`.

If several windows share the minimum length, any of them is accepted.""",
    constraints=["1 ≤ s.length, t.length ≤ 10⁵", "s and t consist of English letters."],
    examples=[
        dict(args=["ADOBECODEBANC", "ABC"], expected="BANC"),
        dict(args=["a", "a"], expected="a"),
        dict(args=["a", "aa"], expected="", explanation="t needs two 'a's; s has one."),
    ],
    hidden=[dict(args=["ab", "b"]), dict(args=["bba", "ab"]), dict(args=["aaflslflsldkalskaaa", "aaa"]), dict(args=["abc", "d"])],
    starter='''class Solution:
    def minWindow(self, s: str, t: str) -> str:
        pass
''',
    reference='''class Solution:
    def minWindow(self, s, t):
        need = Counter(t)
        missing = len(t)
        left = 0
        best = (0, float("inf"))
        for right, ch in enumerate(s):
            if need[ch] > 0:
                missing -= 1
            need[ch] -= 1
            if missing == 0:
                while need[s[left]] < 0:
                    need[s[left]] += 1
                    left += 1
                if right - left < best[1] - best[0]:
                    best = (left, right)
                need[s[left]] += 1
                missing += 1
                left += 1
        return "" if best[1] == float("inf") else s[best[0]:best[1] + 1]

def check(args, got, expected):
    s, t = args
    if not isinstance(got, str):
        return False
    if expected == "":
        return got == ""
    if len(got) != len(expected) or got not in s:
        return False
    c = Counter(got)
    return all(c[ch] >= k for ch, k in Counter(t).items())
''',
    brute='''class Solution:
    def minWindow(self, s, t):
        need = Counter(t)
        best = ""
        for i in range(len(s)):
            for j in range(i + 1, len(s) + 1):
                c = Counter(s[i:j])
                if all(c[ch] >= k for ch, k in need.items()):
                    if best == "" or j - i < len(best):
                        best = s[i:j]
                    break
        return best
''',
    small_gen='''def gen(rng):
    s = "".join(rng.choice("abc") for _ in range(rng.randint(1, 9)))
    t = "".join(rng.choice("abc") for _ in range(rng.randint(1, 3)))
    return [s, t]
''',
    gens=[dict(name="Long string", code='''def gen(rng):
    s = "".join(rng.choice("ABCDEFGHIJ") for _ in range(100000))
    t = "".join(rng.choice("ABCDEFGHIJ") for _ in range(40))
    return [s, t]
''')],
    hints=["Expand the right edge until the window covers t; then shrink the left edge as far as possible.",
           "Track how many required characters are still missing, so 'is the window valid?' is O(1).",
           "A count map that goes negative means the window has surplus of that character — safe to drop from the left."],
    approach="""**Expand / contract sliding window.** `need[c]` counts how many more of `c` the window requires; `missing` is the total still required.

* Move `right`: decrement `need[s[right]]`; if it was positive, one fewer character is missing.
* When `missing == 0` the window is valid: advance `left` past surplus characters (`need < 0`), record the window, then give up `s[left]` to look for a shorter one.

Every index is added once and removed once.""",
    complexity="O(|s| + |t|) time · O(alphabet) space",
    followups=["Return the shortest window containing t as a subsequence (#727).",
               "s is a huge stream and t is small — what can you keep in memory?",
               "Find all windows of the minimum length."],
),

dict(
    id="lc238", num=238, title="Product of Array Except Self", slug="product-of-array-except-self", difficulty="Medium",
    topic="arrays", pattern="Prefix / suffix products", companies=["Meta", "Google"],
    kind="function", cls="Solution", method="productExceptSelf",
    params=[{"name": "nums", "type": "int[]"}], returns="int[]",
    statement="""Return an array `answer` where `answer[i]` is the product of every element of `nums` **except** `nums[i]`.

Solve it in O(n) time **without using division**.""",
    constraints=["2 ≤ nums.length ≤ 10⁵", "−30 ≤ nums[i] ≤ 30", "Every prefix and suffix product fits in a 32-bit integer."],
    examples=[
        dict(args=[[1, 2, 3, 4]], expected=[24, 12, 8, 6]),
        dict(args=[[-1, 1, 0, -3, 3]], expected=[0, 0, 9, 0, 0]),
    ],
    hidden=[dict(args=[[0, 0]]), dict(args=[[2, 3]]), dict(args=[[0, 4, 0]]), dict(args=[[1, 0]])],
    starter='''class Solution:
    def productExceptSelf(self, nums: List[int]) -> List[int]:
        pass
''',
    reference='''class Solution:
    def productExceptSelf(self, nums):
        n = len(nums)
        ans = [1] * n
        p = 1
        for i in range(n):
            ans[i] = p
            p *= nums[i]
        p = 1
        for i in range(n - 1, -1, -1):
            ans[i] *= p
            p *= nums[i]
        return ans
''',
    brute='''class Solution:
    def productExceptSelf(self, nums):
        out = []
        for i in range(len(nums)):
            p = 1
            for j in range(len(nums)):
                if i != j:
                    p *= nums[j]
            out.append(p)
        return out
''',
    small_gen='''def gen(rng):
    return [[rng.randint(-3, 3) for _ in range(rng.randint(2, 7))]]
''',
    gens=[dict(name="Large input (n = 100,000)", code='''def gen(rng):
    nums = [rng.choice((1, -1)) for _ in range(100000)]
    for k in rng.sample(range(100000), 12):
        nums[k] = rng.choice((2, 3, -2))
    return [nums]
''')],
    hints=["answer[i] = (product of everything left of i) × (product of everything right of i).",
           "Compute left products in one pass and right products in a second pass.",
           "You can store the left products in the output array and multiply in the right products on the way back: O(1) extra space."],
    approach="""`answer[i]` is the **prefix product** before `i` times the **suffix product** after `i`. Fill `answer` with prefix products left-to-right, then sweep right-to-left with a running suffix product, multiplying it in.

Division fails when the array contains zeros and is ruled out by the problem anyway.""",
    complexity="O(n) time · O(1) extra space (output excluded)",
    followups=["Handle the case where products overflow 32 bits.", "Answer many range-product queries quickly.",
               "Why does the division approach break with one zero? With two?"],
),

dict(
    id="lc560", num=560, title="Subarray Sum Equals K", slug="subarray-sum-equals-k", difficulty="Medium", topic="arrays",
    pattern="Prefix sum + hash map", companies=["Meta", "Google"],
    kind="function", cls="Solution", method="subarraySum",
    params=[{"name": "nums", "type": "int[]"}, {"name": "k", "type": "int"}], returns="int",
    statement="""Return the number of **contiguous, non-empty** subarrays of `nums` whose elements sum to `k`.

Values may be negative, so a sliding window does not work.""",
    constraints=["1 ≤ nums.length ≤ 2 · 10⁴", "−1000 ≤ nums[i] ≤ 1000", "−10⁷ ≤ k ≤ 10⁷"],
    examples=[
        dict(args=[[1, 1, 1], 2], expected=2),
        dict(args=[[1, 2, 3], 3], expected=2, explanation="[1, 2] and [3]."),
    ],
    hidden=[dict(args=[[1], 0]), dict(args=[[0, 0, 0], 0]), dict(args=[[1, -1, 0], 0]), dict(args=[[-1, -1, 1], 0])],
    starter='''class Solution:
    def subarraySum(self, nums: List[int], k: int) -> int:
        pass
''',
    reference='''class Solution:
    def subarraySum(self, nums, k):
        seen = defaultdict(int)
        seen[0] = 1
        prefix = count = 0
        for x in nums:
            prefix += x
            count += seen[prefix - k]
            seen[prefix] += 1
        return count
''',
    brute='''class Solution:
    def subarraySum(self, nums, k):
        c = 0
        for i in range(len(nums)):
            s = 0
            for j in range(i, len(nums)):
                s += nums[j]
                c += s == k
        return c
''',
    small_gen='''def gen(rng):
    return [[rng.randint(-3, 3) for _ in range(rng.randint(1, 9))], rng.randint(-3, 3)]
''',
    gens=[dict(name="Large input (n = 20,000)", code='''def gen(rng):
    return [[rng.randint(-5, 5) for _ in range(20000)], rng.randint(-10, 10)]
''')],
    hints=["sum(i..j) = prefix[j+1] − prefix[i].",
           "So you want, for each j, the number of earlier prefixes equal to prefix − k.",
           "Count prefixes in a hash map as you go. Seed it with {0: 1} for subarrays starting at index 0."],
    approach="""A subarray ending at `j` sums to `k` exactly when some earlier prefix equals `prefix_j − k`. Keep a hash map from prefix value to how many times it has occurred; for each new prefix add `seen[prefix − k]` to the answer, then record the prefix.

Seeding `seen[0] = 1` counts subarrays that start at index 0.""",
    complexity="O(n) time · O(n) space",
    followups=["If all numbers are positive, can you use O(1) space? (Sliding window.)",
               "Return the longest such subarray (#325).", "Count subarrays whose sum is divisible by k (#974)."],
),

dict(
    id="lc88", num=88, title="Merge Sorted Array", slug="merge-sorted-array", difficulty="Easy", topic="sorting",
    pattern="Two pointers from the end", companies=["Meta"],
    kind="function", cls="Solution", method="merge",
    params=[{"name": "nums1", "type": "int[]"}, {"name": "m", "type": "int"}, {"name": "nums2", "type": "int[]"}, {"name": "n", "type": "int"}],
    returns="void", inplace=0,
    statement="""`nums1` has length `m + n`: its first `m` values are sorted and the last `n` slots are placeholders (0). `nums2` holds `n` sorted values.

Merge `nums2` into `nums1` **in place** so that `nums1` is sorted. Do not return anything — the judge reads `nums1` after your method runs.""",
    constraints=["nums1.length == m + n", "0 ≤ m, n ≤ 200", "−10⁹ ≤ values ≤ 10⁹"],
    examples=[
        dict(args=[[1, 2, 3, 0, 0, 0], 3, [2, 5, 6], 3], expected=[1, 2, 2, 3, 5, 6]),
        dict(args=[[1], 1, [], 0], expected=[1]),
        dict(args=[[0], 0, [1], 1], expected=[1]),
    ],
    hidden=[dict(args=[[4, 5, 6, 0, 0, 0], 3, [1, 2, 3], 3]), dict(args=[[2, 0], 1, [1], 1]), dict(args=[[-1, 0, 0, 0], 1, [-3, -2, 5], 3])],
    starter='''class Solution:
    def merge(self, nums1: List[int], m: int, nums2: List[int], n: int) -> None:
        """
        Do not return anything, modify nums1 in-place instead.
        """
        pass
''',
    reference='''class Solution:
    def merge(self, nums1, m, nums2, n):
        i, j, k = m - 1, n - 1, m + n - 1
        while j >= 0:
            if i >= 0 and nums1[i] > nums2[j]:
                nums1[k] = nums1[i]; i -= 1
            else:
                nums1[k] = nums2[j]; j -= 1
            k -= 1
''',
    brute='''class Solution:
    def merge(self, nums1, m, nums2, n):
        nums1[:] = sorted(nums1[:m] + nums2)
''',
    small_gen='''def gen(rng):
    m, n = rng.randint(0, 5), rng.randint(0, 5)
    a = sorted(rng.randint(-5, 5) for _ in range(m))
    b = sorted(rng.randint(-5, 5) for _ in range(n))
    return [a + [0] * n, m, b, n]
''',
    hints=["Filling from the front would overwrite values of nums1 you still need.",
           "The free space is at the end — fill nums1 from the back, largest first.",
           "Stop when nums2 is exhausted; whatever remains of nums1 is already in place."],
    approach="""Merge **from the back**. Pointers `i` (end of the real values of `nums1`), `j` (end of `nums2`) and `k` (last slot). Place the larger of `nums1[i]` and `nums2[j]` at `k` and step back. Writes never overtake unread values because there are exactly `n` free slots ahead of `i`.""",
    complexity="O(m + n) time · O(1) space",
    followups=["Merge k sorted arrays.", "What if nums1 had no spare space?", "Merge two sorted linked lists (#21)."],
),

dict(
    id="lc1762", num=1762, title="Buildings With an Ocean View", slug="buildings-with-an-ocean-view", difficulty="Medium",
    topic="stacks", pattern="Scan from the right with a running maximum", companies=["Meta"],
    kind="function", cls="Solution", method="findBuildings",
    params=[{"name": "heights", "type": "int[]"}], returns="int[]",
    statement="""`heights[i]` is the height of building `i` in a row. The ocean is to the **right** of the last building. A building has an ocean view if **every** building to its right is strictly shorter.

Return the indices of buildings with an ocean view, in increasing order.""",
    constraints=["1 ≤ heights.length ≤ 10⁵", "1 ≤ heights[i] ≤ 10⁹"],
    examples=[
        dict(args=[[4, 2, 3, 1]], expected=[0, 2, 3], explanation="Building 1 is blocked by building 2 (height 3)."),
        dict(args=[[4, 3, 2, 1]], expected=[0, 1, 2, 3]),
        dict(args=[[1, 3, 2, 4]], expected=[3]),
    ],
    hidden=[dict(args=[[2, 2, 2, 2]], expected=[3]), dict(args=[[5]], expected=[0])],
    starter='''class Solution:
    def findBuildings(self, heights: List[int]) -> List[int]:
        pass
''',
    reference='''class Solution:
    def findBuildings(self, heights):
        out, tallest = [], 0
        for i in range(len(heights) - 1, -1, -1):
            if heights[i] > tallest:
                out.append(i)
                tallest = heights[i]
        return out[::-1]
''',
    brute='''class Solution:
    def findBuildings(self, heights):
        return [i for i in range(len(heights)) if all(heights[j] < heights[i] for j in range(i + 1, len(heights)))]
''',
    small_gen='''def gen(rng):
    return [[rng.randint(1, 5) for _ in range(rng.randint(1, 8))]]
''',
    gens=[dict(name="Large input, all buildings visible", code='''def gen(rng):
    return [list(range(100000, 0, -1))]
''')],
    hints=["Whether building i can see the ocean depends only on the tallest building to its right.",
           "Scan from right to left keeping the maximum height seen so far.",
           "Collect indices on the way and reverse at the end (or use a monotonic stack from the left)."],
    approach="""Scan **right to left** with `tallest`, the maximum height seen so far. Building `i` has a view exactly when `heights[i] > tallest`. Reverse the collected indices to get increasing order.

Scanning left to right with a monotonic decreasing stack also works: each new building pops every shorter-or-equal building it blocks.""",
    complexity="O(n) time · O(1) extra space (output excluded)",
    followups=["The ocean is on the left instead.", "Ocean on both sides — return buildings that see either.",
               "Heights arrive as a stream from left to right; maintain the answer online (monotonic stack)."],
),

dict(
    id="lc791", num=791, title="Custom Sort String", slug="custom-sort-string", difficulty="Medium", topic="hashing",
    pattern="Counting sort by custom order", companies=["Meta"],
    kind="function", cls="Solution", method="customSortString",
    params=[{"name": "order", "type": "str"}, {"name": "s", "type": "str"}], returns="str", compare="custom",
    statement="""All characters of `order` are distinct and were sorted in some custom order. Permute the characters of `s` so that they respect that order: if `x` comes before `y` in `order`, every `x` must appear before every `y` in the result.

Characters of `s` that are not in `order` may go anywhere. Any valid permutation is accepted.""",
    constraints=["1 ≤ order.length ≤ 26", "1 ≤ s.length ≤ 10⁵", "Lowercase English letters only."],
    examples=[
        dict(args=["cba", "abcd"], expected="cbad", explanation="'d' is not in order, so 'dcba', 'cdba' … are also accepted."),
        dict(args=["bcafg", "abcd"], expected="bcad"),
    ],
    hidden=[dict(args=["kqep", "pekeq"]), dict(args=["a", "bbbb"]), dict(args=["xyz", "zzyyxx"])],
    starter='''class Solution:
    def customSortString(self, order: str, s: str) -> str:
        pass
''',
    reference='''class Solution:
    def customSortString(self, order, s):
        count = Counter(s)
        out = []
        for ch in order:
            out.append(ch * count.pop(ch, 0))
        for ch, k in count.items():
            out.append(ch * k)
        return "".join(out)

def check(args, got, expected):
    order, s = args
    if not isinstance(got, str) or sorted(got) != sorted(s):
        return False
    rank = {c: i for i, c in enumerate(order)}
    ranked = [rank[c] for c in got if c in rank]
    return ranked == sorted(ranked)
''',
    brute='''class Solution:
    def customSortString(self, order, s):
        rank = {c: i for i, c in enumerate(order)}
        return "".join(sorted(s, key=lambda c: rank.get(c, 26)))
''',
    small_gen='''def gen(rng):
    order = "".join(rng.sample("abcdef", rng.randint(1, 6)))
    s = "".join(rng.choice("abcdefg") for _ in range(rng.randint(1, 10)))
    return [order, s]
''',
    hints=["Sorting with a custom key works in O(n log n).",
           "Can you avoid sorting? Count each character of s first.",
           "Emit characters in the given order using the counts, then append the rest."],
    approach="""**Counting sort.** Count the characters of `s`. Walk `order` and emit each character as many times as it occurs, removing it from the counter; finally emit the characters that were not in `order`.

Sorting by `rank.get(c, 26)` is a fine first answer (O(n log n)); counting is linear.""",
    complexity="O(|s| + |order|) time · O(1) space (26 letters)",
    followups=["Verify an alien dictionary order (#953).", "Derive the order from a sorted list of words (Alien Dictionary, #269)."],
),

dict(
    id="lc42", num=42, title="Trapping Rain Water", slug="trapping-rain-water", difficulty="Hard", topic="arrays",
    pattern="Two pointers with running maxima", companies=["Meta", "Google"],
    kind="function", cls="Solution", method="trap",
    params=[{"name": "height", "type": "int[]"}], returns="int",
    statement="""`height[i]` is the height of a bar of width 1. After it rains, how many units of water are trapped between the bars?""",
    constraints=["1 ≤ height.length ≤ 2 · 10⁴", "0 ≤ height[i] ≤ 10⁵"],
    examples=[
        dict(args=[[0, 1, 0, 2, 1, 0, 1, 3, 2, 1, 2, 1]], expected=6),
        dict(args=[[4, 2, 0, 3, 2, 5]], expected=9),
    ],
    hidden=[dict(args=[[1]]), dict(args=[[2, 0, 2]]), dict(args=[[5, 4, 3, 2, 1]]), dict(args=[[0, 0, 0]])],
    starter='''class Solution:
    def trap(self, height: List[int]) -> int:
        pass
''',
    reference='''class Solution:
    def trap(self, height):
        l, r = 0, len(height) - 1
        lmax = rmax = water = 0
        while l < r:
            if height[l] < height[r]:
                lmax = max(lmax, height[l])
                water += lmax - height[l]
                l += 1
            else:
                rmax = max(rmax, height[r])
                water += rmax - height[r]
                r -= 1
        return water
''',
    brute='''class Solution:
    def trap(self, height):
        w = 0
        for i in range(len(height)):
            w += min(max(height[:i + 1]), max(height[i:])) - height[i]
        return w
''',
    small_gen='''def gen(rng):
    return [[rng.randint(0, 5) for _ in range(rng.randint(1, 10))]]
''',
    gens=[dict(name="Large input (n = 20,000)", code='''def gen(rng):
    return [[rng.randint(0, 100000) for _ in range(20000)]]
''')],
    hints=["Water above bar i = min(highest bar to its left, highest bar to its right) − height[i].",
           "Precomputing left-max and right-max arrays gives O(n) time and O(n) space.",
           "With two pointers, the side with the smaller current bar is bounded by its own running max — process that side."],
    approach="""Water above `i` is `min(maxLeft, maxRight) − height[i]`.

**Two pointers.** Keep `lmax` and `rmax`. If `height[l] < height[r]`, the right side already has a bar at least as tall as anything that limits `l`, so the water at `l` is decided by `lmax` alone: add `lmax − height[l]` and move `l`. Symmetrically for the right.""",
    complexity="O(n) time · O(1) space",
    followups=["Trapping Rain Water II: a 2D elevation map (#407, heap + BFS).",
               "Bars arrive one at a time — can you update the answer incrementally?", "Solve it with a monotonic stack."],
),

dict(
    id="lc49", num=49, title="Group Anagrams", slug="group-anagrams", difficulty="Medium", topic="hashing",
    pattern="Canonical key", companies=["Meta", "Google"],
    kind="function", cls="Solution", method="groupAnagrams",
    params=[{"name": "strs", "type": "str[]"}], returns="str[][]", compare="unordered_nested",
    statement="""Group the strings in `strs` that are anagrams of one another. Return the groups in any order; the strings inside a group may also be in any order.""",
    constraints=["1 ≤ strs.length ≤ 10⁴", "0 ≤ strs[i].length ≤ 100", "Lowercase English letters."],
    examples=[
        dict(args=[["eat", "tea", "tan", "ate", "nat", "bat"]], expected=[["bat"], ["nat", "tan"], ["ate", "eat", "tea"]]),
        dict(args=[[""]], expected=[[""]]),
        dict(args=[["a"]], expected=[["a"]]),
    ],
    hidden=[dict(args=[["", "", "b"]]), dict(args=[["abc", "bca", "cab", "xyz", "zyx", "q"]])],
    starter='''class Solution:
    def groupAnagrams(self, strs: List[str]) -> List[List[str]]:
        pass
''',
    reference='''class Solution:
    def groupAnagrams(self, strs):
        groups = defaultdict(list)
        for s in strs:
            groups["".join(sorted(s))].append(s)
        return list(groups.values())
''',
    brute='''class Solution:
    def groupAnagrams(self, strs):
        out, used = [], [False] * len(strs)
        for i, s in enumerate(strs):
            if used[i]:
                continue
            g = [s]; used[i] = True
            for j in range(i + 1, len(strs)):
                if not used[j] and sorted(strs[j]) == sorted(s):
                    g.append(strs[j]); used[j] = True
            out.append(g)
        return out
''',
    small_gen='''def gen(rng):
    return [["".join(rng.choice("abc") for _ in range(rng.randint(0, 3))) for _ in range(rng.randint(1, 8))]]
''',
    gens=[dict(name="10,000 strings", code='''def gen(rng):
    base = ["".join(rng.choice("abcdefghij") for _ in range(8)) for _ in range(500)]
    out = []
    for _ in range(10000):
        w = list(rng.choice(base)); rng.shuffle(w); out.append("".join(w))
    return [out]
''')],
    hints=["Two words are anagrams exactly when their letters, sorted, are equal.",
           "Use that sorted form as a dictionary key.",
           "A 26-length count tuple also works as a key and avoids the sort."],
    approach="""Map every string to a **canonical key** shared by all its anagrams — its sorted letters (or a tuple of 26 letter counts) — and append it to the list for that key. The dictionary's values are the groups.""",
    complexity="O(n · k log k) time with sorting, O(n · k) with counts · O(n · k) space",
    followups=["Strings are very long — which key is cheaper?", "Group strings that are rotations / shifts of each other (#249)."],
),

dict(
    id="lc128", num=128, title="Longest Consecutive Sequence", slug="longest-consecutive-sequence", difficulty="Medium",
    topic="hashing", pattern="Hash set, start only at sequence heads", companies=["Google", "Meta"],
    kind="function", cls="Solution", method="longestConsecutive",
    params=[{"name": "nums", "type": "int[]"}], returns="int",
    statement="""Given an unsorted array `nums`, return the length of the longest run of **consecutive integers** (x, x+1, x+2, …) that all appear in `nums`. Order in the array does not matter.

Aim for O(n) time.""",
    constraints=["0 ≤ nums.length ≤ 10⁵", "−10⁹ ≤ nums[i] ≤ 10⁹"],
    examples=[
        dict(args=[[100, 4, 200, 1, 3, 2]], expected=4, explanation="1, 2, 3, 4"),
        dict(args=[[0, 3, 7, 2, 5, 8, 4, 6, 0, 1]], expected=9),
    ],
    hidden=[dict(args=[[]]), dict(args=[[1, 2, 0, 1]]), dict(args=[[9, 1, -3, 2, 4, 8, 3, -1, 6, -2, -4, 7]])],
    starter='''class Solution:
    def longestConsecutive(self, nums: List[int]) -> int:
        pass
''',
    reference='''class Solution:
    def longestConsecutive(self, nums):
        s = set(nums)
        best = 0
        for x in s:
            if x - 1 not in s:
                y = x
                while y + 1 in s:
                    y += 1
                best = max(best, y - x + 1)
        return best
''',
    brute='''class Solution:
    def longestConsecutive(self, nums):
        best = 0
        for x in nums:
            k = 0
            while x + k in nums:
                k += 1
            best = max(best, k)
        return best
''',
    small_gen='''def gen(rng):
    return [[rng.randint(-5, 5) for _ in range(rng.randint(0, 9))]]
''',
    gens=[dict(name="One long run of 100,000", code='''def gen(rng):
    a = list(range(-50000, 50000)); rng.shuffle(a); return [a]
''')],
    hints=["Sorting gives O(n log n). For O(n), put everything in a set.",
           "Only start counting from x if x − 1 is not in the set — x is the head of a run.",
           "Each number is then visited at most twice."],
    approach="""Put the numbers in a hash set. A value `x` starts a run only if `x − 1` is absent; from each such head, walk `x+1, x+2, …` while present. Because inner walks only start at heads, every number is examined a constant number of times.""",
    complexity="O(n) time · O(n) space",
    followups=["Numbers arrive as a stream; report the longest run after each insertion (Union-Find).",
               "Return the run itself.", "Why is the brute force (start a walk from every x) O(n²)?"],
),
]
