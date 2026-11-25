from collections import Counter
from logparse import parse_line


def top_users(lines, k):
    counts = Counter(r["user"] for r in map(parse_line, lines) if r)
    ranked = sorted(counts, key=lambda u: (-counts[u], u))
    return ranked[:k] if k > 0 else ranked
