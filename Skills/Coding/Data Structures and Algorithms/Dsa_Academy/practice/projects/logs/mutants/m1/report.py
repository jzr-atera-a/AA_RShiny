from collections import Counter
from logparse import parse_line


def top_users(lines, k):
    if k <= 0:
        return []
    counts = Counter(r["user"] for r in map(parse_line, lines) if r)
    return [u for u, _ in counts.most_common(k)]
